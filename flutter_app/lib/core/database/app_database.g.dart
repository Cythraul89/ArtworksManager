// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ArtworksTable extends Artworks with TableInfo<$ArtworksTable, Artwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _mediumMeta = const VerificationMeta('medium');
  @override
  late final GeneratedColumn<String> medium = GeneratedColumn<String>(
      'medium', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _widthCmMeta =
      const VerificationMeta('widthCm');
  @override
  late final GeneratedColumn<double> widthCm = GeneratedColumn<double>(
      'width_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _depthCmMeta =
      const VerificationMeta('depthCm');
  @override
  late final GeneratedColumn<double> depthCm = GeneratedColumn<double>(
      'depth_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _acquisitionDateMeta =
      const VerificationMeta('acquisitionDate');
  @override
  late final GeneratedColumn<int> acquisitionDate = GeneratedColumn<int>(
      'acquisition_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _purchasePriceMeta =
      const VerificationMeta('purchasePrice');
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
      'purchase_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _conditionMeta =
      const VerificationMeta('condition');
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
      'condition', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _provenanceMeta =
      const VerificationMeta('provenance');
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
      'provenance', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _certificatePathMeta =
      const VerificationMeta('certificatePath');
  @override
  late final GeneratedColumn<String> certificatePath = GeneratedColumn<String>(
      'certificate_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: () => DateTime.now().millisecondsSinceEpoch);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        artist,
        year,
        type,
        medium,
        heightCm,
        widthCm,
        depthCm,
        location,
        acquisitionDate,
        currency,
        purchasePrice,
        description,
        condition,
        provenance,
        photoPath,
        certificatePath,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artworks';
  @override
  VerificationContext validateIntegrity(Insertable<Artwork> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('medium')) {
      context.handle(_mediumMeta,
          medium.isAcceptableOrUnknown(data['medium']!, _mediumMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('width_cm')) {
      context.handle(_widthCmMeta,
          widthCm.isAcceptableOrUnknown(data['width_cm']!, _widthCmMeta));
    }
    if (data.containsKey('depth_cm')) {
      context.handle(_depthCmMeta,
          depthCm.isAcceptableOrUnknown(data['depth_cm']!, _depthCmMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('acquisition_date')) {
      context.handle(
          _acquisitionDateMeta,
          acquisitionDate.isAcceptableOrUnknown(
              data['acquisition_date']!, _acquisitionDateMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
          _purchasePriceMeta,
          purchasePrice.isAcceptableOrUnknown(
              data['purchase_price']!, _purchasePriceMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('condition')) {
      context.handle(_conditionMeta,
          condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta));
    }
    if (data.containsKey('provenance')) {
      context.handle(
          _provenanceMeta,
          provenance.isAcceptableOrUnknown(
              data['provenance']!, _provenanceMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('certificate_path')) {
      context.handle(
          _certificatePathMeta,
          certificatePath.isAcceptableOrUnknown(
              data['certificate_path']!, _certificatePathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artwork(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      medium: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}medium'])!,
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm']),
      widthCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}width_cm']),
      depthCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}depth_cm']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      acquisitionDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acquisition_date']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      purchasePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}purchase_price']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      condition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}condition'])!,
      provenance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provenance'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      certificatePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}certificate_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ArtworksTable createAlias(String alias) {
    return $ArtworksTable(attachedDatabase, alias);
  }
}

class Artwork extends DataClass implements Insertable<Artwork> {
  final int id;
  final String title;
  final String artist;
  final int? year;
  final String type;
  final String medium;
  final double? heightCm;
  final double? widthCm;
  final double? depthCm;
  final String location;
  final int? acquisitionDate;
  final String currency;
  final double? purchasePrice;
  final String description;
  final String condition;
  final String provenance;
  final String photoPath;
  final String certificatePath;
  final int createdAt;
  const Artwork(
      {required this.id,
      required this.title,
      required this.artist,
      this.year,
      required this.type,
      required this.medium,
      this.heightCm,
      this.widthCm,
      this.depthCm,
      required this.location,
      this.acquisitionDate,
      required this.currency,
      this.purchasePrice,
      required this.description,
      required this.condition,
      required this.provenance,
      required this.photoPath,
      required this.certificatePath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['type'] = Variable<String>(type);
    map['medium'] = Variable<String>(medium);
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || widthCm != null) {
      map['width_cm'] = Variable<double>(widthCm);
    }
    if (!nullToAbsent || depthCm != null) {
      map['depth_cm'] = Variable<double>(depthCm);
    }
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || acquisitionDate != null) {
      map['acquisition_date'] = Variable<int>(acquisitionDate);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    map['description'] = Variable<String>(description);
    map['condition'] = Variable<String>(condition);
    map['provenance'] = Variable<String>(provenance);
    map['photo_path'] = Variable<String>(photoPath);
    map['certificate_path'] = Variable<String>(certificatePath);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ArtworksCompanion toCompanion(bool nullToAbsent) {
    return ArtworksCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      type: Value(type),
      medium: Value(medium),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      widthCm: widthCm == null && nullToAbsent
          ? const Value.absent()
          : Value(widthCm),
      depthCm: depthCm == null && nullToAbsent
          ? const Value.absent()
          : Value(depthCm),
      location: Value(location),
      acquisitionDate: acquisitionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(acquisitionDate),
      currency: Value(currency),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      description: Value(description),
      condition: Value(condition),
      provenance: Value(provenance),
      photoPath: Value(photoPath),
      certificatePath: Value(certificatePath),
      createdAt: Value(createdAt),
    );
  }

  factory Artwork.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artwork(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      year: serializer.fromJson<int?>(json['year']),
      type: serializer.fromJson<String>(json['type']),
      medium: serializer.fromJson<String>(json['medium']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      widthCm: serializer.fromJson<double?>(json['widthCm']),
      depthCm: serializer.fromJson<double?>(json['depthCm']),
      location: serializer.fromJson<String>(json['location']),
      acquisitionDate: serializer.fromJson<int?>(json['acquisitionDate']),
      currency: serializer.fromJson<String>(json['currency']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      description: serializer.fromJson<String>(json['description']),
      condition: serializer.fromJson<String>(json['condition']),
      provenance: serializer.fromJson<String>(json['provenance']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      certificatePath: serializer.fromJson<String>(json['certificatePath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'year': serializer.toJson<int?>(year),
      'type': serializer.toJson<String>(type),
      'medium': serializer.toJson<String>(medium),
      'heightCm': serializer.toJson<double?>(heightCm),
      'widthCm': serializer.toJson<double?>(widthCm),
      'depthCm': serializer.toJson<double?>(depthCm),
      'location': serializer.toJson<String>(location),
      'acquisitionDate': serializer.toJson<int?>(acquisitionDate),
      'currency': serializer.toJson<String>(currency),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'description': serializer.toJson<String>(description),
      'condition': serializer.toJson<String>(condition),
      'provenance': serializer.toJson<String>(provenance),
      'photoPath': serializer.toJson<String>(photoPath),
      'certificatePath': serializer.toJson<String>(certificatePath),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Artwork copyWith(
          {int? id,
          String? title,
          String? artist,
          Value<int?> year = const Value.absent(),
          String? type,
          String? medium,
          Value<double?> heightCm = const Value.absent(),
          Value<double?> widthCm = const Value.absent(),
          Value<double?> depthCm = const Value.absent(),
          String? location,
          Value<int?> acquisitionDate = const Value.absent(),
          String? currency,
          Value<double?> purchasePrice = const Value.absent(),
          String? description,
          String? condition,
          String? provenance,
          String? photoPath,
          String? certificatePath,
          int? createdAt}) =>
      Artwork(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        year: year.present ? year.value : this.year,
        type: type ?? this.type,
        medium: medium ?? this.medium,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        widthCm: widthCm.present ? widthCm.value : this.widthCm,
        depthCm: depthCm.present ? depthCm.value : this.depthCm,
        location: location ?? this.location,
        acquisitionDate: acquisitionDate.present
            ? acquisitionDate.value
            : this.acquisitionDate,
        currency: currency ?? this.currency,
        purchasePrice:
            purchasePrice.present ? purchasePrice.value : this.purchasePrice,
        description: description ?? this.description,
        condition: condition ?? this.condition,
        provenance: provenance ?? this.provenance,
        photoPath: photoPath ?? this.photoPath,
        certificatePath: certificatePath ?? this.certificatePath,
        createdAt: createdAt ?? this.createdAt,
      );
  Artwork copyWithCompanion(ArtworksCompanion data) {
    return Artwork(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      year: data.year.present ? data.year.value : this.year,
      type: data.type.present ? data.type.value : this.type,
      medium: data.medium.present ? data.medium.value : this.medium,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      widthCm: data.widthCm.present ? data.widthCm.value : this.widthCm,
      depthCm: data.depthCm.present ? data.depthCm.value : this.depthCm,
      location: data.location.present ? data.location.value : this.location,
      acquisitionDate: data.acquisitionDate.present
          ? data.acquisitionDate.value
          : this.acquisitionDate,
      currency: data.currency.present ? data.currency.value : this.currency,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      description:
          data.description.present ? data.description.value : this.description,
      condition: data.condition.present ? data.condition.value : this.condition,
      provenance:
          data.provenance.present ? data.provenance.value : this.provenance,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      certificatePath: data.certificatePath.present
          ? data.certificatePath.value
          : this.certificatePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artwork(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('medium: $medium, ')
          ..write('heightCm: $heightCm, ')
          ..write('widthCm: $widthCm, ')
          ..write('depthCm: $depthCm, ')
          ..write('location: $location, ')
          ..write('acquisitionDate: $acquisitionDate, ')
          ..write('currency: $currency, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('provenance: $provenance, ')
          ..write('photoPath: $photoPath, ')
          ..write('certificatePath: $certificatePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      artist,
      year,
      type,
      medium,
      heightCm,
      widthCm,
      depthCm,
      location,
      acquisitionDate,
      currency,
      purchasePrice,
      description,
      condition,
      provenance,
      photoPath,
      certificatePath,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artwork &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.year == this.year &&
          other.type == this.type &&
          other.medium == this.medium &&
          other.heightCm == this.heightCm &&
          other.widthCm == this.widthCm &&
          other.depthCm == this.depthCm &&
          other.location == this.location &&
          other.acquisitionDate == this.acquisitionDate &&
          other.currency == this.currency &&
          other.purchasePrice == this.purchasePrice &&
          other.description == this.description &&
          other.condition == this.condition &&
          other.provenance == this.provenance &&
          other.photoPath == this.photoPath &&
          other.certificatePath == this.certificatePath &&
          other.createdAt == this.createdAt);
}

class ArtworksCompanion extends UpdateCompanion<Artwork> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<int?> year;
  final Value<String> type;
  final Value<String> medium;
  final Value<double?> heightCm;
  final Value<double?> widthCm;
  final Value<double?> depthCm;
  final Value<String> location;
  final Value<int?> acquisitionDate;
  final Value<String> currency;
  final Value<double?> purchasePrice;
  final Value<String> description;
  final Value<String> condition;
  final Value<String> provenance;
  final Value<String> photoPath;
  final Value<String> certificatePath;
  final Value<int> createdAt;
  const ArtworksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.year = const Value.absent(),
    this.type = const Value.absent(),
    this.medium = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.widthCm = const Value.absent(),
    this.depthCm = const Value.absent(),
    this.location = const Value.absent(),
    this.acquisitionDate = const Value.absent(),
    this.currency = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.provenance = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.certificatePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ArtworksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.artist = const Value.absent(),
    this.year = const Value.absent(),
    this.type = const Value.absent(),
    this.medium = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.widthCm = const Value.absent(),
    this.depthCm = const Value.absent(),
    this.location = const Value.absent(),
    this.acquisitionDate = const Value.absent(),
    this.currency = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.description = const Value.absent(),
    this.condition = const Value.absent(),
    this.provenance = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.certificatePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Artwork> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? year,
    Expression<String>? type,
    Expression<String>? medium,
    Expression<double>? heightCm,
    Expression<double>? widthCm,
    Expression<double>? depthCm,
    Expression<String>? location,
    Expression<int>? acquisitionDate,
    Expression<String>? currency,
    Expression<double>? purchasePrice,
    Expression<String>? description,
    Expression<String>? condition,
    Expression<String>? provenance,
    Expression<String>? photoPath,
    Expression<String>? certificatePath,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (year != null) 'year': year,
      if (type != null) 'type': type,
      if (medium != null) 'medium': medium,
      if (heightCm != null) 'height_cm': heightCm,
      if (widthCm != null) 'width_cm': widthCm,
      if (depthCm != null) 'depth_cm': depthCm,
      if (location != null) 'location': location,
      if (acquisitionDate != null) 'acquisition_date': acquisitionDate,
      if (currency != null) 'currency': currency,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (description != null) 'description': description,
      if (condition != null) 'condition': condition,
      if (provenance != null) 'provenance': provenance,
      if (photoPath != null) 'photo_path': photoPath,
      if (certificatePath != null) 'certificate_path': certificatePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ArtworksCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? artist,
      Value<int?>? year,
      Value<String>? type,
      Value<String>? medium,
      Value<double?>? heightCm,
      Value<double?>? widthCm,
      Value<double?>? depthCm,
      Value<String>? location,
      Value<int?>? acquisitionDate,
      Value<String>? currency,
      Value<double?>? purchasePrice,
      Value<String>? description,
      Value<String>? condition,
      Value<String>? provenance,
      Value<String>? photoPath,
      Value<String>? certificatePath,
      Value<int>? createdAt}) {
    return ArtworksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      year: year ?? this.year,
      type: type ?? this.type,
      medium: medium ?? this.medium,
      heightCm: heightCm ?? this.heightCm,
      widthCm: widthCm ?? this.widthCm,
      depthCm: depthCm ?? this.depthCm,
      location: location ?? this.location,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      currency: currency ?? this.currency,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      provenance: provenance ?? this.provenance,
      photoPath: photoPath ?? this.photoPath,
      certificatePath: certificatePath ?? this.certificatePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (medium.present) {
      map['medium'] = Variable<String>(medium.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (widthCm.present) {
      map['width_cm'] = Variable<double>(widthCm.value);
    }
    if (depthCm.present) {
      map['depth_cm'] = Variable<double>(depthCm.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (acquisitionDate.present) {
      map['acquisition_date'] = Variable<int>(acquisitionDate.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (certificatePath.present) {
      map['certificate_path'] = Variable<String>(certificatePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('medium: $medium, ')
          ..write('heightCm: $heightCm, ')
          ..write('widthCm: $widthCm, ')
          ..write('depthCm: $depthCm, ')
          ..write('location: $location, ')
          ..write('acquisitionDate: $acquisitionDate, ')
          ..write('currency: $currency, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('description: $description, ')
          ..write('condition: $condition, ')
          ..write('provenance: $provenance, ')
          ..write('photoPath: $photoPath, ')
          ..write('certificatePath: $certificatePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ArtworkPhotosTable extends ArtworkPhotos
    with TableInfo<$ArtworkPhotosTable, ArtworkPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworkPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _artworkIdMeta =
      const VerificationMeta('artworkId');
  @override
  late final GeneratedColumn<int> artworkId = GeneratedColumn<int>(
      'artwork_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES artworks (id) ON DELETE CASCADE'));
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, artworkId, photoPath, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artwork_photos';
  @override
  VerificationContext validateIntegrity(Insertable<ArtworkPhoto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('artwork_id')) {
      context.handle(_artworkIdMeta,
          artworkId.isAcceptableOrUnknown(data['artwork_id']!, _artworkIdMeta));
    } else if (isInserting) {
      context.missing(_artworkIdMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArtworkPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtworkPhoto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      artworkId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}artwork_id'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ArtworkPhotosTable createAlias(String alias) {
    return $ArtworkPhotosTable(attachedDatabase, alias);
  }
}

class ArtworkPhoto extends DataClass implements Insertable<ArtworkPhoto> {
  final int id;
  final int artworkId;
  final String photoPath;
  final int sortOrder;
  const ArtworkPhoto(
      {required this.id,
      required this.artworkId,
      required this.photoPath,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['artwork_id'] = Variable<int>(artworkId);
    map['photo_path'] = Variable<String>(photoPath);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ArtworkPhotosCompanion toCompanion(bool nullToAbsent) {
    return ArtworkPhotosCompanion(
      id: Value(id),
      artworkId: Value(artworkId),
      photoPath: Value(photoPath),
      sortOrder: Value(sortOrder),
    );
  }

  factory ArtworkPhoto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtworkPhoto(
      id: serializer.fromJson<int>(json['id']),
      artworkId: serializer.fromJson<int>(json['artworkId']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'artworkId': serializer.toJson<int>(artworkId),
      'photoPath': serializer.toJson<String>(photoPath),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ArtworkPhoto copyWith(
          {int? id, int? artworkId, String? photoPath, int? sortOrder}) =>
      ArtworkPhoto(
        id: id ?? this.id,
        artworkId: artworkId ?? this.artworkId,
        photoPath: photoPath ?? this.photoPath,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ArtworkPhoto copyWithCompanion(ArtworkPhotosCompanion data) {
    return ArtworkPhoto(
      id: data.id.present ? data.id.value : this.id,
      artworkId: data.artworkId.present ? data.artworkId.value : this.artworkId,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkPhoto(')
          ..write('id: $id, ')
          ..write('artworkId: $artworkId, ')
          ..write('photoPath: $photoPath, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, artworkId, photoPath, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtworkPhoto &&
          other.id == this.id &&
          other.artworkId == this.artworkId &&
          other.photoPath == this.photoPath &&
          other.sortOrder == this.sortOrder);
}

class ArtworkPhotosCompanion extends UpdateCompanion<ArtworkPhoto> {
  final Value<int> id;
  final Value<int> artworkId;
  final Value<String> photoPath;
  final Value<int> sortOrder;
  const ArtworkPhotosCompanion({
    this.id = const Value.absent(),
    this.artworkId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ArtworkPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int artworkId,
    required String photoPath,
    this.sortOrder = const Value.absent(),
  })  : artworkId = Value(artworkId),
        photoPath = Value(photoPath);
  static Insertable<ArtworkPhoto> custom({
    Expression<int>? id,
    Expression<int>? artworkId,
    Expression<String>? photoPath,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (artworkId != null) 'artwork_id': artworkId,
      if (photoPath != null) 'photo_path': photoPath,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ArtworkPhotosCompanion copyWith(
      {Value<int>? id,
      Value<int>? artworkId,
      Value<String>? photoPath,
      Value<int>? sortOrder}) {
    return ArtworkPhotosCompanion(
      id: id ?? this.id,
      artworkId: artworkId ?? this.artworkId,
      photoPath: photoPath ?? this.photoPath,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (artworkId.present) {
      map['artwork_id'] = Variable<int>(artworkId.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkPhotosCompanion(')
          ..write('id: $id, ')
          ..write('artworkId: $artworkId, ')
          ..write('photoPath: $photoPath, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('EUR'));
  static const VerificationMeta _nextcloudUrlMeta =
      const VerificationMeta('nextcloudUrl');
  @override
  late final GeneratedColumn<String> nextcloudUrl = GeneratedColumn<String>(
      'nextcloud_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _nextcloudUsernameMeta =
      const VerificationMeta('nextcloudUsername');
  @override
  late final GeneratedColumn<String> nextcloudUsername =
      GeneratedColumn<String>('nextcloud_username', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _nextcloudPathMeta =
      const VerificationMeta('nextcloudPath');
  @override
  late final GeneratedColumn<String> nextcloudPath = GeneratedColumn<String>(
      'nextcloud_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('AWoMa'));
  static const VerificationMeta _nextcloudCertFingerprintMeta =
      const VerificationMeta('nextcloudCertFingerprint');
  @override
  late final GeneratedColumn<String> nextcloudCertFingerprint =
      GeneratedColumn<String>('nextcloud_cert_fingerprint', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _nextcloudKeepExportsMeta =
      const VerificationMeta('nextcloudKeepExports');
  @override
  late final GeneratedColumn<int> nextcloudKeepExports = GeneratedColumn<int>(
      'nextcloud_keep_exports', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncErrorMeta =
      const VerificationMeta('lastSyncError');
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
      'last_sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _autoSyncEnabledMeta =
      const VerificationMeta('autoSyncEnabled');
  @override
  late final GeneratedColumn<bool> autoSyncEnabled = GeneratedColumn<bool>(
      'auto_sync_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_sync_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _autoSyncIntervalHoursMeta =
      const VerificationMeta('autoSyncIntervalHours');
  @override
  late final GeneratedColumn<int> autoSyncIntervalHours = GeneratedColumn<int>(
      'auto_sync_interval_hours', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(24));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        currency,
        nextcloudUrl,
        nextcloudUsername,
        nextcloudPath,
        nextcloudCertFingerprint,
        nextcloudKeepExports,
        lastSyncAt,
        lastSyncError,
        autoSyncEnabled,
        autoSyncIntervalHours
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('nextcloud_url')) {
      context.handle(
          _nextcloudUrlMeta,
          nextcloudUrl.isAcceptableOrUnknown(
              data['nextcloud_url']!, _nextcloudUrlMeta));
    }
    if (data.containsKey('nextcloud_username')) {
      context.handle(
          _nextcloudUsernameMeta,
          nextcloudUsername.isAcceptableOrUnknown(
              data['nextcloud_username']!, _nextcloudUsernameMeta));
    }
    if (data.containsKey('nextcloud_path')) {
      context.handle(
          _nextcloudPathMeta,
          nextcloudPath.isAcceptableOrUnknown(
              data['nextcloud_path']!, _nextcloudPathMeta));
    }
    if (data.containsKey('nextcloud_cert_fingerprint')) {
      context.handle(
          _nextcloudCertFingerprintMeta,
          nextcloudCertFingerprint.isAcceptableOrUnknown(
              data['nextcloud_cert_fingerprint']!,
              _nextcloudCertFingerprintMeta));
    }
    if (data.containsKey('nextcloud_keep_exports')) {
      context.handle(
          _nextcloudKeepExportsMeta,
          nextcloudKeepExports.isAcceptableOrUnknown(
              data['nextcloud_keep_exports']!, _nextcloudKeepExportsMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
          _lastSyncErrorMeta,
          lastSyncError.isAcceptableOrUnknown(
              data['last_sync_error']!, _lastSyncErrorMeta));
    }
    if (data.containsKey('auto_sync_enabled')) {
      context.handle(
          _autoSyncEnabledMeta,
          autoSyncEnabled.isAcceptableOrUnknown(
              data['auto_sync_enabled']!, _autoSyncEnabledMeta));
    }
    if (data.containsKey('auto_sync_interval_hours')) {
      context.handle(
          _autoSyncIntervalHoursMeta,
          autoSyncIntervalHours.isAcceptableOrUnknown(
              data['auto_sync_interval_hours']!, _autoSyncIntervalHoursMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      nextcloudUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nextcloud_url'])!,
      nextcloudUsername: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}nextcloud_username'])!,
      nextcloudPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nextcloud_path'])!,
      nextcloudCertFingerprint: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}nextcloud_cert_fingerprint'])!,
      nextcloudKeepExports: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}nextcloud_keep_exports'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_sync_at']),
      lastSyncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_sync_error']),
      autoSyncEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}auto_sync_enabled'])!,
      autoSyncIntervalHours: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}auto_sync_interval_hours'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String currency;
  final String nextcloudUrl;
  final String nextcloudUsername;
  final String nextcloudPath;
  final String nextcloudCertFingerprint;
  final int nextcloudKeepExports;
  final int? lastSyncAt;
  final String? lastSyncError;
  final bool autoSyncEnabled;
  final int autoSyncIntervalHours;
  const Setting(
      {required this.id,
      required this.currency,
      required this.nextcloudUrl,
      required this.nextcloudUsername,
      required this.nextcloudPath,
      required this.nextcloudCertFingerprint,
      required this.nextcloudKeepExports,
      this.lastSyncAt,
      this.lastSyncError,
      required this.autoSyncEnabled,
      required this.autoSyncIntervalHours});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency'] = Variable<String>(currency);
    map['nextcloud_url'] = Variable<String>(nextcloudUrl);
    map['nextcloud_username'] = Variable<String>(nextcloudUsername);
    map['nextcloud_path'] = Variable<String>(nextcloudPath);
    map['nextcloud_cert_fingerprint'] =
        Variable<String>(nextcloudCertFingerprint);
    map['nextcloud_keep_exports'] = Variable<int>(nextcloudKeepExports);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled);
    map['auto_sync_interval_hours'] = Variable<int>(autoSyncIntervalHours);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      currency: Value(currency),
      nextcloudUrl: Value(nextcloudUrl),
      nextcloudUsername: Value(nextcloudUsername),
      nextcloudPath: Value(nextcloudPath),
      nextcloudCertFingerprint: Value(nextcloudCertFingerprint),
      nextcloudKeepExports: Value(nextcloudKeepExports),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      autoSyncEnabled: Value(autoSyncEnabled),
      autoSyncIntervalHours: Value(autoSyncIntervalHours),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      currency: serializer.fromJson<String>(json['currency']),
      nextcloudUrl: serializer.fromJson<String>(json['nextcloudUrl']),
      nextcloudUsername: serializer.fromJson<String>(json['nextcloudUsername']),
      nextcloudPath: serializer.fromJson<String>(json['nextcloudPath']),
      nextcloudCertFingerprint:
          serializer.fromJson<String>(json['nextcloudCertFingerprint']),
      nextcloudKeepExports:
          serializer.fromJson<int>(json['nextcloudKeepExports']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      autoSyncEnabled: serializer.fromJson<bool>(json['autoSyncEnabled']),
      autoSyncIntervalHours:
          serializer.fromJson<int>(json['autoSyncIntervalHours']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currency': serializer.toJson<String>(currency),
      'nextcloudUrl': serializer.toJson<String>(nextcloudUrl),
      'nextcloudUsername': serializer.toJson<String>(nextcloudUsername),
      'nextcloudPath': serializer.toJson<String>(nextcloudPath),
      'nextcloudCertFingerprint':
          serializer.toJson<String>(nextcloudCertFingerprint),
      'nextcloudKeepExports': serializer.toJson<int>(nextcloudKeepExports),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'autoSyncEnabled': serializer.toJson<bool>(autoSyncEnabled),
      'autoSyncIntervalHours': serializer.toJson<int>(autoSyncIntervalHours),
    };
  }

  Setting copyWith(
          {int? id,
          String? currency,
          String? nextcloudUrl,
          String? nextcloudUsername,
          String? nextcloudPath,
          String? nextcloudCertFingerprint,
          int? nextcloudKeepExports,
          Value<int?> lastSyncAt = const Value.absent(),
          Value<String?> lastSyncError = const Value.absent(),
          bool? autoSyncEnabled,
          int? autoSyncIntervalHours}) =>
      Setting(
        id: id ?? this.id,
        currency: currency ?? this.currency,
        nextcloudUrl: nextcloudUrl ?? this.nextcloudUrl,
        nextcloudUsername: nextcloudUsername ?? this.nextcloudUsername,
        nextcloudPath: nextcloudPath ?? this.nextcloudPath,
        nextcloudCertFingerprint:
            nextcloudCertFingerprint ?? this.nextcloudCertFingerprint,
        nextcloudKeepExports: nextcloudKeepExports ?? this.nextcloudKeepExports,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
        lastSyncError:
            lastSyncError.present ? lastSyncError.value : this.lastSyncError,
        autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
        autoSyncIntervalHours:
            autoSyncIntervalHours ?? this.autoSyncIntervalHours,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      currency: data.currency.present ? data.currency.value : this.currency,
      nextcloudUrl: data.nextcloudUrl.present
          ? data.nextcloudUrl.value
          : this.nextcloudUrl,
      nextcloudUsername: data.nextcloudUsername.present
          ? data.nextcloudUsername.value
          : this.nextcloudUsername,
      nextcloudPath: data.nextcloudPath.present
          ? data.nextcloudPath.value
          : this.nextcloudPath,
      nextcloudCertFingerprint: data.nextcloudCertFingerprint.present
          ? data.nextcloudCertFingerprint.value
          : this.nextcloudCertFingerprint,
      nextcloudKeepExports: data.nextcloudKeepExports.present
          ? data.nextcloudKeepExports.value
          : this.nextcloudKeepExports,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      autoSyncEnabled: data.autoSyncEnabled.present
          ? data.autoSyncEnabled.value
          : this.autoSyncEnabled,
      autoSyncIntervalHours: data.autoSyncIntervalHours.present
          ? data.autoSyncIntervalHours.value
          : this.autoSyncIntervalHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('nextcloudUrl: $nextcloudUrl, ')
          ..write('nextcloudUsername: $nextcloudUsername, ')
          ..write('nextcloudPath: $nextcloudPath, ')
          ..write('nextcloudCertFingerprint: $nextcloudCertFingerprint, ')
          ..write('nextcloudKeepExports: $nextcloudKeepExports, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('autoSyncIntervalHours: $autoSyncIntervalHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      currency,
      nextcloudUrl,
      nextcloudUsername,
      nextcloudPath,
      nextcloudCertFingerprint,
      nextcloudKeepExports,
      lastSyncAt,
      lastSyncError,
      autoSyncEnabled,
      autoSyncIntervalHours);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.currency == this.currency &&
          other.nextcloudUrl == this.nextcloudUrl &&
          other.nextcloudUsername == this.nextcloudUsername &&
          other.nextcloudPath == this.nextcloudPath &&
          other.nextcloudCertFingerprint == this.nextcloudCertFingerprint &&
          other.nextcloudKeepExports == this.nextcloudKeepExports &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.autoSyncEnabled == this.autoSyncEnabled &&
          other.autoSyncIntervalHours == this.autoSyncIntervalHours);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> currency;
  final Value<String> nextcloudUrl;
  final Value<String> nextcloudUsername;
  final Value<String> nextcloudPath;
  final Value<String> nextcloudCertFingerprint;
  final Value<int> nextcloudKeepExports;
  final Value<int?> lastSyncAt;
  final Value<String?> lastSyncError;
  final Value<bool> autoSyncEnabled;
  final Value<int> autoSyncIntervalHours;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.currency = const Value.absent(),
    this.nextcloudUrl = const Value.absent(),
    this.nextcloudUsername = const Value.absent(),
    this.nextcloudPath = const Value.absent(),
    this.nextcloudCertFingerprint = const Value.absent(),
    this.nextcloudKeepExports = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.autoSyncEnabled = const Value.absent(),
    this.autoSyncIntervalHours = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.currency = const Value.absent(),
    this.nextcloudUrl = const Value.absent(),
    this.nextcloudUsername = const Value.absent(),
    this.nextcloudPath = const Value.absent(),
    this.nextcloudCertFingerprint = const Value.absent(),
    this.nextcloudKeepExports = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.autoSyncEnabled = const Value.absent(),
    this.autoSyncIntervalHours = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? currency,
    Expression<String>? nextcloudUrl,
    Expression<String>? nextcloudUsername,
    Expression<String>? nextcloudPath,
    Expression<String>? nextcloudCertFingerprint,
    Expression<int>? nextcloudKeepExports,
    Expression<int>? lastSyncAt,
    Expression<String>? lastSyncError,
    Expression<bool>? autoSyncEnabled,
    Expression<int>? autoSyncIntervalHours,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currency != null) 'currency': currency,
      if (nextcloudUrl != null) 'nextcloud_url': nextcloudUrl,
      if (nextcloudUsername != null) 'nextcloud_username': nextcloudUsername,
      if (nextcloudPath != null) 'nextcloud_path': nextcloudPath,
      if (nextcloudCertFingerprint != null)
        'nextcloud_cert_fingerprint': nextcloudCertFingerprint,
      if (nextcloudKeepExports != null)
        'nextcloud_keep_exports': nextcloudKeepExports,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (autoSyncEnabled != null) 'auto_sync_enabled': autoSyncEnabled,
      if (autoSyncIntervalHours != null)
        'auto_sync_interval_hours': autoSyncIntervalHours,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? currency,
      Value<String>? nextcloudUrl,
      Value<String>? nextcloudUsername,
      Value<String>? nextcloudPath,
      Value<String>? nextcloudCertFingerprint,
      Value<int>? nextcloudKeepExports,
      Value<int?>? lastSyncAt,
      Value<String?>? lastSyncError,
      Value<bool>? autoSyncEnabled,
      Value<int>? autoSyncIntervalHours}) {
    return SettingsCompanion(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      nextcloudUrl: nextcloudUrl ?? this.nextcloudUrl,
      nextcloudUsername: nextcloudUsername ?? this.nextcloudUsername,
      nextcloudPath: nextcloudPath ?? this.nextcloudPath,
      nextcloudCertFingerprint:
          nextcloudCertFingerprint ?? this.nextcloudCertFingerprint,
      nextcloudKeepExports: nextcloudKeepExports ?? this.nextcloudKeepExports,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      autoSyncIntervalHours:
          autoSyncIntervalHours ?? this.autoSyncIntervalHours,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (nextcloudUrl.present) {
      map['nextcloud_url'] = Variable<String>(nextcloudUrl.value);
    }
    if (nextcloudUsername.present) {
      map['nextcloud_username'] = Variable<String>(nextcloudUsername.value);
    }
    if (nextcloudPath.present) {
      map['nextcloud_path'] = Variable<String>(nextcloudPath.value);
    }
    if (nextcloudCertFingerprint.present) {
      map['nextcloud_cert_fingerprint'] =
          Variable<String>(nextcloudCertFingerprint.value);
    }
    if (nextcloudKeepExports.present) {
      map['nextcloud_keep_exports'] = Variable<int>(nextcloudKeepExports.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (autoSyncEnabled.present) {
      map['auto_sync_enabled'] = Variable<bool>(autoSyncEnabled.value);
    }
    if (autoSyncIntervalHours.present) {
      map['auto_sync_interval_hours'] =
          Variable<int>(autoSyncIntervalHours.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('nextcloudUrl: $nextcloudUrl, ')
          ..write('nextcloudUsername: $nextcloudUsername, ')
          ..write('nextcloudPath: $nextcloudPath, ')
          ..write('nextcloudCertFingerprint: $nextcloudCertFingerprint, ')
          ..write('nextcloudKeepExports: $nextcloudKeepExports, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('autoSyncEnabled: $autoSyncEnabled, ')
          ..write('autoSyncIntervalHours: $autoSyncIntervalHours')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArtworksTable artworks = $ArtworksTable(this);
  late final $ArtworkPhotosTable artworkPhotos = $ArtworkPhotosTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final ArtworksDao artworksDao = ArtworksDao(this as AppDatabase);
  late final PhotosDao photosDao = PhotosDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [artworks, artworkPhotos, settings];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('artworks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('artwork_photos', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ArtworksTableCreateCompanionBuilder = ArtworksCompanion Function({
  Value<int> id,
  required String title,
  Value<String> artist,
  Value<int?> year,
  Value<String> type,
  Value<String> medium,
  Value<double?> heightCm,
  Value<double?> widthCm,
  Value<double?> depthCm,
  Value<String> location,
  Value<int?> acquisitionDate,
  Value<String> currency,
  Value<double?> purchasePrice,
  Value<String> description,
  Value<String> condition,
  Value<String> provenance,
  Value<String> photoPath,
  Value<String> certificatePath,
  Value<int> createdAt,
});
typedef $$ArtworksTableUpdateCompanionBuilder = ArtworksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> artist,
  Value<int?> year,
  Value<String> type,
  Value<String> medium,
  Value<double?> heightCm,
  Value<double?> widthCm,
  Value<double?> depthCm,
  Value<String> location,
  Value<int?> acquisitionDate,
  Value<String> currency,
  Value<double?> purchasePrice,
  Value<String> description,
  Value<String> condition,
  Value<String> provenance,
  Value<String> photoPath,
  Value<String> certificatePath,
  Value<int> createdAt,
});

final class $$ArtworksTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworksTable, Artwork> {
  $$ArtworksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ArtworkPhotosTable, List<ArtworkPhoto>>
      _artworkPhotosRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.artworkPhotos,
              aliasName: $_aliasNameGenerator(
                  db.artworks.id, db.artworkPhotos.artworkId));

  $$ArtworkPhotosTableProcessedTableManager get artworkPhotosRefs {
    final manager = $$ArtworkPhotosTableTableManager($_db, $_db.artworkPhotos)
        .filter((f) => f.artworkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_artworkPhotosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ArtworksTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get medium => $composableBuilder(
      column: $table.medium, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get widthCm => $composableBuilder(
      column: $table.widthCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get depthCm => $composableBuilder(
      column: $table.depthCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acquisitionDate => $composableBuilder(
      column: $table.acquisitionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get purchasePrice => $composableBuilder(
      column: $table.purchasePrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get condition => $composableBuilder(
      column: $table.condition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get certificatePath => $composableBuilder(
      column: $table.certificatePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> artworkPhotosRefs(
      Expression<bool> Function($$ArtworkPhotosTableFilterComposer f) f) {
    final $$ArtworkPhotosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.artworkPhotos,
        getReferencedColumn: (t) => t.artworkId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworkPhotosTableFilterComposer(
              $db: $db,
              $table: $db.artworkPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ArtworksTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get medium => $composableBuilder(
      column: $table.medium, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get widthCm => $composableBuilder(
      column: $table.widthCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get depthCm => $composableBuilder(
      column: $table.depthCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acquisitionDate => $composableBuilder(
      column: $table.acquisitionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
      column: $table.purchasePrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get condition => $composableBuilder(
      column: $table.condition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get certificatePath => $composableBuilder(
      column: $table.certificatePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ArtworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworksTable> {
  $$ArtworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get medium =>
      $composableBuilder(column: $table.medium, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get widthCm =>
      $composableBuilder(column: $table.widthCm, builder: (column) => column);

  GeneratedColumn<double> get depthCm =>
      $composableBuilder(column: $table.depthCm, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get acquisitionDate => $composableBuilder(
      column: $table.acquisitionDate, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
      column: $table.purchasePrice, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
      column: $table.provenance, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get certificatePath => $composableBuilder(
      column: $table.certificatePath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> artworkPhotosRefs<T extends Object>(
      Expression<T> Function($$ArtworkPhotosTableAnnotationComposer a) f) {
    final $$ArtworkPhotosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.artworkPhotos,
        getReferencedColumn: (t) => t.artworkId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworkPhotosTableAnnotationComposer(
              $db: $db,
              $table: $db.artworkPhotos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ArtworksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArtworksTable,
    Artwork,
    $$ArtworksTableFilterComposer,
    $$ArtworksTableOrderingComposer,
    $$ArtworksTableAnnotationComposer,
    $$ArtworksTableCreateCompanionBuilder,
    $$ArtworksTableUpdateCompanionBuilder,
    (Artwork, $$ArtworksTableReferences),
    Artwork,
    PrefetchHooks Function({bool artworkPhotosRefs})> {
  $$ArtworksTableTableManager(_$AppDatabase db, $ArtworksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> artist = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> medium = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<double?> widthCm = const Value.absent(),
            Value<double?> depthCm = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<int?> acquisitionDate = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double?> purchasePrice = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> condition = const Value.absent(),
            Value<String> provenance = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String> certificatePath = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              ArtworksCompanion(
            id: id,
            title: title,
            artist: artist,
            year: year,
            type: type,
            medium: medium,
            heightCm: heightCm,
            widthCm: widthCm,
            depthCm: depthCm,
            location: location,
            acquisitionDate: acquisitionDate,
            currency: currency,
            purchasePrice: purchasePrice,
            description: description,
            condition: condition,
            provenance: provenance,
            photoPath: photoPath,
            certificatePath: certificatePath,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> artist = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> medium = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<double?> widthCm = const Value.absent(),
            Value<double?> depthCm = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<int?> acquisitionDate = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double?> purchasePrice = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> condition = const Value.absent(),
            Value<String> provenance = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<String> certificatePath = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              ArtworksCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            year: year,
            type: type,
            medium: medium,
            heightCm: heightCm,
            widthCm: widthCm,
            depthCm: depthCm,
            location: location,
            acquisitionDate: acquisitionDate,
            currency: currency,
            purchasePrice: purchasePrice,
            description: description,
            condition: condition,
            provenance: provenance,
            photoPath: photoPath,
            certificatePath: certificatePath,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ArtworksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({artworkPhotosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (artworkPhotosRefs) db.artworkPhotos
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (artworkPhotosRefs)
                    await $_getPrefetchedData<Artwork, $ArtworksTable,
                            ArtworkPhoto>(
                        currentTable: table,
                        referencedTable: $$ArtworksTableReferences
                            ._artworkPhotosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ArtworksTableReferences(db, table, p0)
                                .artworkPhotosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.artworkId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ArtworksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArtworksTable,
    Artwork,
    $$ArtworksTableFilterComposer,
    $$ArtworksTableOrderingComposer,
    $$ArtworksTableAnnotationComposer,
    $$ArtworksTableCreateCompanionBuilder,
    $$ArtworksTableUpdateCompanionBuilder,
    (Artwork, $$ArtworksTableReferences),
    Artwork,
    PrefetchHooks Function({bool artworkPhotosRefs})>;
typedef $$ArtworkPhotosTableCreateCompanionBuilder = ArtworkPhotosCompanion
    Function({
  Value<int> id,
  required int artworkId,
  required String photoPath,
  Value<int> sortOrder,
});
typedef $$ArtworkPhotosTableUpdateCompanionBuilder = ArtworkPhotosCompanion
    Function({
  Value<int> id,
  Value<int> artworkId,
  Value<String> photoPath,
  Value<int> sortOrder,
});

final class $$ArtworkPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $ArtworkPhotosTable, ArtworkPhoto> {
  $$ArtworkPhotosTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ArtworksTable _artworkIdTable(_$AppDatabase db) =>
      db.artworks.createAlias(
          $_aliasNameGenerator(db.artworkPhotos.artworkId, db.artworks.id));

  $$ArtworksTableProcessedTableManager get artworkId {
    final $_column = $_itemColumn<int>('artwork_id')!;

    final manager = $$ArtworksTableTableManager($_db, $_db.artworks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artworkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ArtworkPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ArtworkPhotosTable> {
  $$ArtworkPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$ArtworksTableFilterComposer get artworkId {
    final $$ArtworksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.artworkId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableFilterComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArtworkPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtworkPhotosTable> {
  $$ArtworkPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$ArtworksTableOrderingComposer get artworkId {
    final $$ArtworksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.artworkId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableOrderingComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArtworkPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtworkPhotosTable> {
  $$ArtworkPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ArtworksTableAnnotationComposer get artworkId {
    final $$ArtworksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.artworkId,
        referencedTable: $db.artworks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArtworksTableAnnotationComposer(
              $db: $db,
              $table: $db.artworks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArtworkPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArtworkPhotosTable,
    ArtworkPhoto,
    $$ArtworkPhotosTableFilterComposer,
    $$ArtworkPhotosTableOrderingComposer,
    $$ArtworkPhotosTableAnnotationComposer,
    $$ArtworkPhotosTableCreateCompanionBuilder,
    $$ArtworkPhotosTableUpdateCompanionBuilder,
    (ArtworkPhoto, $$ArtworkPhotosTableReferences),
    ArtworkPhoto,
    PrefetchHooks Function({bool artworkId})> {
  $$ArtworkPhotosTableTableManager(_$AppDatabase db, $ArtworkPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworkPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworkPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworkPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> artworkId = const Value.absent(),
            Value<String> photoPath = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ArtworkPhotosCompanion(
            id: id,
            artworkId: artworkId,
            photoPath: photoPath,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int artworkId,
            required String photoPath,
            Value<int> sortOrder = const Value.absent(),
          }) =>
              ArtworkPhotosCompanion.insert(
            id: id,
            artworkId: artworkId,
            photoPath: photoPath,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ArtworkPhotosTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({artworkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (artworkId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.artworkId,
                    referencedTable:
                        $$ArtworkPhotosTableReferences._artworkIdTable(db),
                    referencedColumn:
                        $$ArtworkPhotosTableReferences._artworkIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ArtworkPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArtworkPhotosTable,
    ArtworkPhoto,
    $$ArtworkPhotosTableFilterComposer,
    $$ArtworkPhotosTableOrderingComposer,
    $$ArtworkPhotosTableAnnotationComposer,
    $$ArtworkPhotosTableCreateCompanionBuilder,
    $$ArtworkPhotosTableUpdateCompanionBuilder,
    (ArtworkPhoto, $$ArtworkPhotosTableReferences),
    ArtworkPhoto,
    PrefetchHooks Function({bool artworkId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> currency,
  Value<String> nextcloudUrl,
  Value<String> nextcloudUsername,
  Value<String> nextcloudPath,
  Value<String> nextcloudCertFingerprint,
  Value<int> nextcloudKeepExports,
  Value<int?> lastSyncAt,
  Value<String?> lastSyncError,
  Value<bool> autoSyncEnabled,
  Value<int> autoSyncIntervalHours,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String> currency,
  Value<String> nextcloudUrl,
  Value<String> nextcloudUsername,
  Value<String> nextcloudPath,
  Value<String> nextcloudCertFingerprint,
  Value<int> nextcloudKeepExports,
  Value<int?> lastSyncAt,
  Value<String?> lastSyncError,
  Value<bool> autoSyncEnabled,
  Value<int> autoSyncIntervalHours,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextcloudUrl => $composableBuilder(
      column: $table.nextcloudUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextcloudUsername => $composableBuilder(
      column: $table.nextcloudUsername,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextcloudPath => $composableBuilder(
      column: $table.nextcloudPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextcloudCertFingerprint => $composableBuilder(
      column: $table.nextcloudCertFingerprint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextcloudKeepExports => $composableBuilder(
      column: $table.nextcloudKeepExports,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoSyncEnabled => $composableBuilder(
      column: $table.autoSyncEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get autoSyncIntervalHours => $composableBuilder(
      column: $table.autoSyncIntervalHours,
      builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextcloudUrl => $composableBuilder(
      column: $table.nextcloudUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextcloudUsername => $composableBuilder(
      column: $table.nextcloudUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextcloudPath => $composableBuilder(
      column: $table.nextcloudPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextcloudCertFingerprint => $composableBuilder(
      column: $table.nextcloudCertFingerprint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextcloudKeepExports => $composableBuilder(
      column: $table.nextcloudKeepExports,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoSyncEnabled => $composableBuilder(
      column: $table.autoSyncEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get autoSyncIntervalHours => $composableBuilder(
      column: $table.autoSyncIntervalHours,
      builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get nextcloudUrl => $composableBuilder(
      column: $table.nextcloudUrl, builder: (column) => column);

  GeneratedColumn<String> get nextcloudUsername => $composableBuilder(
      column: $table.nextcloudUsername, builder: (column) => column);

  GeneratedColumn<String> get nextcloudPath => $composableBuilder(
      column: $table.nextcloudPath, builder: (column) => column);

  GeneratedColumn<String> get nextcloudCertFingerprint => $composableBuilder(
      column: $table.nextcloudCertFingerprint, builder: (column) => column);

  GeneratedColumn<int> get nextcloudKeepExports => $composableBuilder(
      column: $table.nextcloudKeepExports, builder: (column) => column);

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError, builder: (column) => column);

  GeneratedColumn<bool> get autoSyncEnabled => $composableBuilder(
      column: $table.autoSyncEnabled, builder: (column) => column);

  GeneratedColumn<int> get autoSyncIntervalHours => $composableBuilder(
      column: $table.autoSyncIntervalHours, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> nextcloudUrl = const Value.absent(),
            Value<String> nextcloudUsername = const Value.absent(),
            Value<String> nextcloudPath = const Value.absent(),
            Value<String> nextcloudCertFingerprint = const Value.absent(),
            Value<int> nextcloudKeepExports = const Value.absent(),
            Value<int?> lastSyncAt = const Value.absent(),
            Value<String?> lastSyncError = const Value.absent(),
            Value<bool> autoSyncEnabled = const Value.absent(),
            Value<int> autoSyncIntervalHours = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            currency: currency,
            nextcloudUrl: nextcloudUrl,
            nextcloudUsername: nextcloudUsername,
            nextcloudPath: nextcloudPath,
            nextcloudCertFingerprint: nextcloudCertFingerprint,
            nextcloudKeepExports: nextcloudKeepExports,
            lastSyncAt: lastSyncAt,
            lastSyncError: lastSyncError,
            autoSyncEnabled: autoSyncEnabled,
            autoSyncIntervalHours: autoSyncIntervalHours,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> nextcloudUrl = const Value.absent(),
            Value<String> nextcloudUsername = const Value.absent(),
            Value<String> nextcloudPath = const Value.absent(),
            Value<String> nextcloudCertFingerprint = const Value.absent(),
            Value<int> nextcloudKeepExports = const Value.absent(),
            Value<int?> lastSyncAt = const Value.absent(),
            Value<String?> lastSyncError = const Value.absent(),
            Value<bool> autoSyncEnabled = const Value.absent(),
            Value<int> autoSyncIntervalHours = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            id: id,
            currency: currency,
            nextcloudUrl: nextcloudUrl,
            nextcloudUsername: nextcloudUsername,
            nextcloudPath: nextcloudPath,
            nextcloudCertFingerprint: nextcloudCertFingerprint,
            nextcloudKeepExports: nextcloudKeepExports,
            lastSyncAt: lastSyncAt,
            lastSyncError: lastSyncError,
            autoSyncEnabled: autoSyncEnabled,
            autoSyncIntervalHours: autoSyncIntervalHours,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArtworksTableTableManager get artworks =>
      $$ArtworksTableTableManager(_db, _db.artworks);
  $$ArtworkPhotosTableTableManager get artworkPhotos =>
      $$ArtworkPhotosTableTableManager(_db, _db.artworkPhotos);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
