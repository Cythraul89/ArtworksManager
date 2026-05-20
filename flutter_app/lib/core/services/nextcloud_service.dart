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

/// Thin WebDAV client for Nextcloud, mirroring StockManager's NextcloudService.
/// All methods must be called from a background isolate or async context.
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

    if (pinnedFingerprint != null && pinnedFingerprint.isNotEmpty) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          final actual = sha256.convert(cert.der).toString();
          assert(() {
            if (actual != pinnedFingerprint) {
              // ignore: avoid_print
              print('[ArtworksManager] cert-pin mismatch on $host: '
                  'expected $pinnedFingerprint, got $actual');
            }
            return true;
          }());
          return actual == pinnedFingerprint;
        };
        return client;
      };
    }
    return dio;
  }

  String _davBase(String serverUrl, String username) =>
      '${serverUrl.trimRight()}/remote.php/dav/files/$username';

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
        // Ensure parent directory exists (ignore errors — may already exist)
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
        // Extract hrefs from WebDAV XML response
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

  NcResult<T> _mapDioError<T>(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NcTransient();
    }
    // connectionError covers most unreachable-host cases; the SocketException
    // check catches DioExceptionType.unknown wrapping a SocketException, which
    // some Android versions raise instead of connectionError.
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return const NcTransient();
    }
    final code = e.response?.statusCode;
    if (code == 401) return NcFailure('Invalid credentials');
    if (code == 507) return NcFailure('Insufficient storage on server');
    return NcFailure(e.message ?? 'Unknown error');
  }
}
