// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RewardDefinitionsTable extends RewardDefinitions
    with TableInfo<$RewardDefinitionsTable, RewardDbRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RewardDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
      'rarity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _titleKeyMeta =
      const VerificationMeta('titleKey');
  @override
  late final GeneratedColumn<String> titleKey = GeneratedColumn<String>(
      'title_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descKeyMeta =
      const VerificationMeta('descKey');
  @override
  late final GeneratedColumn<String> descKey = GeneratedColumn<String>(
      'desc_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('stat'));
  static const VerificationMeta _paramsJsonMeta =
      const VerificationMeta('paramsJson');
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
      'params_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        key,
        id,
        source,
        kind,
        rarity,
        weight,
        titleKey,
        descKey,
        iconKey,
        paramsJson,
        version
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reward_definitions';
  @override
  VerificationContext validateIntegrity(Insertable<RewardDbRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('rarity')) {
      context.handle(_rarityMeta,
          rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta));
    } else if (isInserting) {
      context.missing(_rarityMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('title_key')) {
      context.handle(_titleKeyMeta,
          titleKey.isAcceptableOrUnknown(data['title_key']!, _titleKeyMeta));
    } else if (isInserting) {
      context.missing(_titleKeyMeta);
    }
    if (data.containsKey('desc_key')) {
      context.handle(_descKeyMeta,
          descKey.isAcceptableOrUnknown(data['desc_key']!, _descKeyMeta));
    } else if (isInserting) {
      context.missing(_descKeyMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    }
    if (data.containsKey('params_json')) {
      context.handle(
          _paramsJsonMeta,
          paramsJson.isAcceptableOrUnknown(
              data['params_json']!, _paramsJsonMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  RewardDbRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RewardDbRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      titleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_key'])!,
      descKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}desc_key'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      paramsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}params_json'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $RewardDefinitionsTable createAlias(String alias) {
    return $RewardDefinitionsTable(attachedDatabase, alias);
  }
}

class RewardDbRow extends DataClass implements Insertable<RewardDbRow> {
  /// PK: "${source}_${id}_${rarity}"
  final String key;

  /// base id: "stat_hp", "buff_vampirism" ...
  final String id;

  /// "levelUp" | "chest" | "altar" | "vendor"
  final String source;

  /// "buff" | "ability" | "item" | "stat"
  final String kind;

  /// "common" | "rare" | "epic" | "legendary"
  final String rarity;
  final double weight;
  final String titleKey;
  final String descKey;
  final String iconKey;
  final String paramsJson;
  final int version;
  const RewardDbRow(
      {required this.key,
      required this.id,
      required this.source,
      required this.kind,
      required this.rarity,
      required this.weight,
      required this.titleKey,
      required this.descKey,
      required this.iconKey,
      required this.paramsJson,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['kind'] = Variable<String>(kind);
    map['rarity'] = Variable<String>(rarity);
    map['weight'] = Variable<double>(weight);
    map['title_key'] = Variable<String>(titleKey);
    map['desc_key'] = Variable<String>(descKey);
    map['icon_key'] = Variable<String>(iconKey);
    map['params_json'] = Variable<String>(paramsJson);
    map['version'] = Variable<int>(version);
    return map;
  }

  RewardDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return RewardDefinitionsCompanion(
      key: Value(key),
      id: Value(id),
      source: Value(source),
      kind: Value(kind),
      rarity: Value(rarity),
      weight: Value(weight),
      titleKey: Value(titleKey),
      descKey: Value(descKey),
      iconKey: Value(iconKey),
      paramsJson: Value(paramsJson),
      version: Value(version),
    );
  }

  factory RewardDbRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RewardDbRow(
      key: serializer.fromJson<String>(json['key']),
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      kind: serializer.fromJson<String>(json['kind']),
      rarity: serializer.fromJson<String>(json['rarity']),
      weight: serializer.fromJson<double>(json['weight']),
      titleKey: serializer.fromJson<String>(json['titleKey']),
      descKey: serializer.fromJson<String>(json['descKey']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'kind': serializer.toJson<String>(kind),
      'rarity': serializer.toJson<String>(rarity),
      'weight': serializer.toJson<double>(weight),
      'titleKey': serializer.toJson<String>(titleKey),
      'descKey': serializer.toJson<String>(descKey),
      'iconKey': serializer.toJson<String>(iconKey),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'version': serializer.toJson<int>(version),
    };
  }

  RewardDbRow copyWith(
          {String? key,
          String? id,
          String? source,
          String? kind,
          String? rarity,
          double? weight,
          String? titleKey,
          String? descKey,
          String? iconKey,
          String? paramsJson,
          int? version}) =>
      RewardDbRow(
        key: key ?? this.key,
        id: id ?? this.id,
        source: source ?? this.source,
        kind: kind ?? this.kind,
        rarity: rarity ?? this.rarity,
        weight: weight ?? this.weight,
        titleKey: titleKey ?? this.titleKey,
        descKey: descKey ?? this.descKey,
        iconKey: iconKey ?? this.iconKey,
        paramsJson: paramsJson ?? this.paramsJson,
        version: version ?? this.version,
      );
  RewardDbRow copyWithCompanion(RewardDefinitionsCompanion data) {
    return RewardDbRow(
      key: data.key.present ? data.key.value : this.key,
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      kind: data.kind.present ? data.kind.value : this.kind,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      weight: data.weight.present ? data.weight.value : this.weight,
      titleKey: data.titleKey.present ? data.titleKey.value : this.titleKey,
      descKey: data.descKey.present ? data.descKey.value : this.descKey,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      paramsJson:
          data.paramsJson.present ? data.paramsJson.value : this.paramsJson,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RewardDbRow(')
          ..write('key: $key, ')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('kind: $kind, ')
          ..write('rarity: $rarity, ')
          ..write('weight: $weight, ')
          ..write('titleKey: $titleKey, ')
          ..write('descKey: $descKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, id, source, kind, rarity, weight,
      titleKey, descKey, iconKey, paramsJson, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RewardDbRow &&
          other.key == this.key &&
          other.id == this.id &&
          other.source == this.source &&
          other.kind == this.kind &&
          other.rarity == this.rarity &&
          other.weight == this.weight &&
          other.titleKey == this.titleKey &&
          other.descKey == this.descKey &&
          other.iconKey == this.iconKey &&
          other.paramsJson == this.paramsJson &&
          other.version == this.version);
}

class RewardDefinitionsCompanion extends UpdateCompanion<RewardDbRow> {
  final Value<String> key;
  final Value<String> id;
  final Value<String> source;
  final Value<String> kind;
  final Value<String> rarity;
  final Value<double> weight;
  final Value<String> titleKey;
  final Value<String> descKey;
  final Value<String> iconKey;
  final Value<String> paramsJson;
  final Value<int> version;
  final Value<int> rowid;
  const RewardDefinitionsCompanion({
    this.key = const Value.absent(),
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.kind = const Value.absent(),
    this.rarity = const Value.absent(),
    this.weight = const Value.absent(),
    this.titleKey = const Value.absent(),
    this.descKey = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RewardDefinitionsCompanion.insert({
    required String key,
    required String id,
    required String source,
    required String kind,
    required String rarity,
    this.weight = const Value.absent(),
    required String titleKey,
    required String descKey,
    this.iconKey = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        id = Value(id),
        source = Value(source),
        kind = Value(kind),
        rarity = Value(rarity),
        titleKey = Value(titleKey),
        descKey = Value(descKey);
  static Insertable<RewardDbRow> custom({
    Expression<String>? key,
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? kind,
    Expression<String>? rarity,
    Expression<double>? weight,
    Expression<String>? titleKey,
    Expression<String>? descKey,
    Expression<String>? iconKey,
    Expression<String>? paramsJson,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (kind != null) 'kind': kind,
      if (rarity != null) 'rarity': rarity,
      if (weight != null) 'weight': weight,
      if (titleKey != null) 'title_key': titleKey,
      if (descKey != null) 'desc_key': descKey,
      if (iconKey != null) 'icon_key': iconKey,
      if (paramsJson != null) 'params_json': paramsJson,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RewardDefinitionsCompanion copyWith(
      {Value<String>? key,
      Value<String>? id,
      Value<String>? source,
      Value<String>? kind,
      Value<String>? rarity,
      Value<double>? weight,
      Value<String>? titleKey,
      Value<String>? descKey,
      Value<String>? iconKey,
      Value<String>? paramsJson,
      Value<int>? version,
      Value<int>? rowid}) {
    return RewardDefinitionsCompanion(
      key: key ?? this.key,
      id: id ?? this.id,
      source: source ?? this.source,
      kind: kind ?? this.kind,
      rarity: rarity ?? this.rarity,
      weight: weight ?? this.weight,
      titleKey: titleKey ?? this.titleKey,
      descKey: descKey ?? this.descKey,
      iconKey: iconKey ?? this.iconKey,
      paramsJson: paramsJson ?? this.paramsJson,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (titleKey.present) {
      map['title_key'] = Variable<String>(titleKey.value);
    }
    if (descKey.present) {
      map['desc_key'] = Variable<String>(descKey.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RewardDefinitionsCompanion(')
          ..write('key: $key, ')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('kind: $kind, ')
          ..write('rarity: $rarity, ')
          ..write('weight: $weight, ')
          ..write('titleKey: $titleKey, ')
          ..write('descKey: $descKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RewardDefinitionsTable rewardDefinitions =
      $RewardDefinitionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [rewardDefinitions];
}

typedef $$RewardDefinitionsTableCreateCompanionBuilder
    = RewardDefinitionsCompanion Function({
  required String key,
  required String id,
  required String source,
  required String kind,
  required String rarity,
  Value<double> weight,
  required String titleKey,
  required String descKey,
  Value<String> iconKey,
  Value<String> paramsJson,
  Value<int> version,
  Value<int> rowid,
});
typedef $$RewardDefinitionsTableUpdateCompanionBuilder
    = RewardDefinitionsCompanion Function({
  Value<String> key,
  Value<String> id,
  Value<String> source,
  Value<String> kind,
  Value<String> rarity,
  Value<double> weight,
  Value<String> titleKey,
  Value<String> descKey,
  Value<String> iconKey,
  Value<String> paramsJson,
  Value<int> version,
  Value<int> rowid,
});

class $$RewardDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $RewardDefinitionsTable> {
  $$RewardDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleKey => $composableBuilder(
      column: $table.titleKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descKey => $composableBuilder(
      column: $table.descKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));
}

class $$RewardDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RewardDefinitionsTable> {
  $$RewardDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleKey => $composableBuilder(
      column: $table.titleKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descKey => $composableBuilder(
      column: $table.descKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));
}

class $$RewardDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RewardDefinitionsTable> {
  $$RewardDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get titleKey =>
      $composableBuilder(column: $table.titleKey, builder: (column) => column);

  GeneratedColumn<String> get descKey =>
      $composableBuilder(column: $table.descKey, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$RewardDefinitionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RewardDefinitionsTable,
    RewardDbRow,
    $$RewardDefinitionsTableFilterComposer,
    $$RewardDefinitionsTableOrderingComposer,
    $$RewardDefinitionsTableAnnotationComposer,
    $$RewardDefinitionsTableCreateCompanionBuilder,
    $$RewardDefinitionsTableUpdateCompanionBuilder,
    (
      RewardDbRow,
      BaseReferences<_$AppDatabase, $RewardDefinitionsTable, RewardDbRow>
    ),
    RewardDbRow,
    PrefetchHooks Function()> {
  $$RewardDefinitionsTableTableManager(
      _$AppDatabase db, $RewardDefinitionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RewardDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RewardDefinitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RewardDefinitionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<String> titleKey = const Value.absent(),
            Value<String> descKey = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<String> paramsJson = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RewardDefinitionsCompanion(
            key: key,
            id: id,
            source: source,
            kind: kind,
            rarity: rarity,
            weight: weight,
            titleKey: titleKey,
            descKey: descKey,
            iconKey: iconKey,
            paramsJson: paramsJson,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String id,
            required String source,
            required String kind,
            required String rarity,
            Value<double> weight = const Value.absent(),
            required String titleKey,
            required String descKey,
            Value<String> iconKey = const Value.absent(),
            Value<String> paramsJson = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RewardDefinitionsCompanion.insert(
            key: key,
            id: id,
            source: source,
            kind: kind,
            rarity: rarity,
            weight: weight,
            titleKey: titleKey,
            descKey: descKey,
            iconKey: iconKey,
            paramsJson: paramsJson,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RewardDefinitionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RewardDefinitionsTable,
    RewardDbRow,
    $$RewardDefinitionsTableFilterComposer,
    $$RewardDefinitionsTableOrderingComposer,
    $$RewardDefinitionsTableAnnotationComposer,
    $$RewardDefinitionsTableCreateCompanionBuilder,
    $$RewardDefinitionsTableUpdateCompanionBuilder,
    (
      RewardDbRow,
      BaseReferences<_$AppDatabase, $RewardDefinitionsTable, RewardDbRow>
    ),
    RewardDbRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RewardDefinitionsTableTableManager get rewardDefinitions =>
      $$RewardDefinitionsTableTableManager(_db, _db.rewardDefinitions);
}
