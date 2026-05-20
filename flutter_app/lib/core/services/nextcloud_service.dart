import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Result type for Nextcloud operations.
sealed class NcResult<T> {
  const NcResult();
}

class NcSuccess<T> extends NcResult<T> {
  final T value;
  const NcSuccess(this.value);
}

class NcFailure<T> extends NcResult<T> {
  final String message;
  const NcFailure(this.message);
}

/// Transient network error — caller should retry.
class NcTransient<T> extends NcResult<T> {
  const NcTransient();
}

class CertificateInfo {
  const CertificateInfo({
    required this.fingerprint,
    required this.subject,
    required this.issuer,
    required this.validUntil,
  });
  final String fingerprint;
  final String subject;
  final String issuer;
  final DateTime validUntil;
}

class BackupInfo {
  const BackupInfo({required this.remotePath, required this.backupDate});
  final String remotePath;
  final DateTime backupDate;
}

/// Thin WebDAV client for Nextcloud.
/// All methods are stateless; callers supply and persist credentials/fingerprint.
class NextcloudService {
  static const _timeoutConnect = Duration(seconds: 15);
  static const _timeoutReceive = Duration(seconds: 60);

  Dio _buildDio(String username, String password, {String? pinnedFingerprint}) {
    final dio = Dio(BaseOptions(
      connectTimeout: _timeoutConnect,
      receiveTimeout: _timeoutReceive,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        'OCS-APIRequest': 'true',
      },
    ));

    if (pinnedFingerprint != null) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) =>
            _certFingerprint(cert.der) == pinnedFingerprint;
        return client;
      };
    }
    return dio;
  }

  String _davBase(String serverUrl, String username) =>
      '${serverUrl.trimRight()}/remote.php/dav/files/$username';

  /// Probes the server certificate. Returns:
  /// - `NcSuccess(null)` — cert is trusted by the OS (no action needed)
  /// - `NcSuccess(info)` — cert is untrusted; show [info] to the user for approval
  /// - `NcTransient` / `NcFailure` on network/parse errors
  Future<NcResult<CertificateInfo?>> fetchCertificateInfo(String serverUrl) async {
    CertificateInfo? untrustedInfo;
    final uri = Uri.parse(serverUrl);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (cert, host, port) {
        untrustedInfo = CertificateInfo(
          fingerprint: _certFingerprint(cert.der),
          subject: cert.subject,
          issuer: cert.issuer,
          validUntil: cert.endValidity,
        );
        return false;
      };
    try {
      final req = await client.getUrl(uri);
      await req.close();
      return const NcSuccess(null); // trusted by OS
    } catch (e) {
      if (untrustedInfo != null) return NcSuccess(untrustedInfo); // untrusted, needs review
      if (e is SocketException) return const NcTransient();
      return NcFailure(e.toString());
    } finally {
      client.close();
    }
  }

  /// Verifies credentials by calling the OCS user endpoint.
  Future<NcResult<void>> verifyCredentials(
    String serverUrl,
    String username,
    String password, {
    String? pinnedFingerprint,
  }) async {
    try {
      final dio = _buildDio(username, password, pinnedFingerprint: pinnedFingerprint);
      final resp = await dio.get('${serverUrl.trimRight()}/ocs/v2.php/cloud/user');
      if (resp.statusCode == 200) return const NcSuccess(null);
      return NcFailure('HTTP ${resp.statusCode}');
    } on DioException catch (e) {
      return _mapDioError(e);
    }
  }

  /// Uploads [bytes] to [remotePath] (relative to user's WebDAV root).
  /// Creates the parent directory via MKCOL if needed.
  Future<NcResult<void>> uploadBackup(
    String serverUrl,
    String username,
    String password,
    String remotePath,
    Uint8List bytes, {
    String? pinnedFingerprint,
  }) async {
    try {
      final dio = _buildDio(username, password, pinnedFingerprint: pinnedFingerprint);
      final base = _davBase(serverUrl, username);
      final dir = remotePath.contains('/')
          ? remotePath.substring(0, remotePath.lastIndexOf('/'))
          : null;

      if (dir != null) {
        await dio.request('$base/$dir',
            options: Options(method: 'MKCOL', validateStatus: (_) => true));
      }

      final resp = await dio.put(
        '$base/$remotePath',
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': 'application/zip',
            'Content-Length': bytes.length,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final code = resp.statusCode ?? 0;
      if (code == 200 || code == 201 || code == 204) return const NcSuccess(null);
      if (code == 401) return const NcFailure('Invalid credentials');
      if (code == 507) return const NcFailure('Insufficient storage on server');
      return NcFailure('Upload failed: HTTP $code');
    } on DioException catch (e) {
      return _mapDioError(e);
    }
  }

  /// Downloads the file at [remotePath] and returns its bytes.
  Future<NcResult<Uint8List>> downloadFile(
    String serverUrl,
    String username,
    String password,
    String remotePath, {
    String? pinnedFingerprint,
  }) async {
    try {
      final dio = _buildDio(username, password, pinnedFingerprint: pinnedFingerprint);
      final resp = await dio.get<List<int>>(
        '${_davBase(serverUrl, username)}/$remotePath',
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        return NcSuccess(Uint8List.fromList(resp.data!));
      }
      return NcFailure('Download failed: HTTP ${resp.statusCode}');
    } on DioException catch (e) {
      return _mapDioError(e);
    }
  }

  /// Lists files in [remoteDir] via PROPFIND Depth:1.
  Future<NcResult<List<String>>> listFiles(
    String serverUrl,
    String username,
    String password,
    String remoteDir, {
    String? pinnedFingerprint,
  }) async {
    try {
      final dio = _buildDio(username, password, pinnedFingerprint: pinnedFingerprint);
      final resp = await dio.request(
        '${_davBase(serverUrl, username)}/$remoteDir',
        options: Options(
          method: 'PROPFIND',
          headers: {'Depth': '1'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (resp.statusCode == 207) {
        final body = resp.data?.toString() ?? '';
        final matches = RegExp(r'<d:href>([^<]+)</d:href>').allMatches(body);
        final files = matches
            .map((m) => Uri.decodeFull(m.group(1) ?? ''))
            .where((href) => href.endsWith('.zip'))
            .toList();
        return NcSuccess(files);
      }
      return NcFailure('PROPFIND failed: HTTP ${resp.statusCode}');
    } on DioException catch (e) {
      return _mapDioError(e);
    }
  }

  /// Deletes a file at [remotePath].
  Future<NcResult<void>> deleteFile(
    String serverUrl,
    String username,
    String password,
    String remotePath, {
    String? pinnedFingerprint,
  }) async {
    try {
      final dio = _buildDio(username, password, pinnedFingerprint: pinnedFingerprint);
      await dio.delete('${_davBase(serverUrl, username)}/$remotePath');
      return const NcSuccess(null);
    } on DioException catch (e) {
      return _mapDioError(e);
    }
  }

  /// Finds the most recent AWoMa backup in [remoteDir].
  /// Returns `NcSuccess(null)` if the directory is empty or has no matching files.
  Future<NcResult<BackupInfo?>> findLatestBackup(
    String serverUrl,
    String username,
    String password,
    String remoteDir, {
    String? pinnedFingerprint,
  }) async {
    final result = await listFiles(serverUrl, username, password, remoteDir,
        pinnedFingerprint: pinnedFingerprint);
    if (result is! NcSuccess<List<String>>) return const NcSuccess(null);

    // backup filename pattern: artworks_YYYYMMDD_HHmmss.zip
    final pattern = RegExp(r'artworks_(\d{8})_(\d{6})\.zip$');
    DateTime? latestDate;
    String? latestHref;

    for (final href in result.value) {
      final match = pattern.firstMatch(href);
      if (match == null) continue;
      final date = DateTime.tryParse(
          '${match.group(1)!.substring(0, 4)}-${match.group(1)!.substring(4, 6)}-${match.group(1)!.substring(6, 8)}'
          'T${match.group(2)!.substring(0, 2)}:${match.group(2)!.substring(2, 4)}:${match.group(2)!.substring(4, 6)}');
      if (date == null) continue;
      if (latestDate == null || date.isAfter(latestDate)) {
        latestDate = date;
        latestHref = href;
      }
    }

    if (latestDate == null || latestHref == null) return const NcSuccess(null);
    return NcSuccess(BackupInfo(remotePath: latestHref, backupDate: latestDate));
  }

  NcResult<T> _mapDioError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NcTransient();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return const NcTransient();
    }
    if (e.type == DioExceptionType.badCertificate ||
        e.error is HandshakeException) {
      return const NcFailure(
          'SSL certificate not trusted — test the connection first to pin the certificate');
    }
    final code = e.response?.statusCode;
    if (code == 401) return NcFailure('Invalid credentials');
    if (code == 507) return NcFailure('Insufficient storage on server');
    final msg = (e.message?.isNotEmpty ?? false)
        ? e.message!
        : e.error?.toString() ?? 'Unknown error';
    return NcFailure(msg);
  }

  static String _certFingerprint(Uint8List derBytes) {
    final digest = sha256.convert(derBytes);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }
}
