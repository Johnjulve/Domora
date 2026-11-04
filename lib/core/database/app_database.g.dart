// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspaceEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceTypeMeta = const VerificationMeta(
    'workspaceType',
  );
  @override
  late final GeneratedColumn<String> workspaceType = GeneratedColumn<String>(
    'workspace_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('personal'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    workspaceType,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('workspace_type')) {
      context.handle(
        _workspaceTypeMeta,
        workspaceType.isAcceptableOrUnknown(
          data['workspace_type']!,
          _workspaceTypeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      workspaceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class WorkspaceEntity extends DataClass implements Insertable<WorkspaceEntity> {
  final String id;
  final String name;
  final String workspaceType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.workspaceType,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['workspace_type'] = Variable<String>(workspaceType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      workspaceType: Value(workspaceType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkspaceEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      workspaceType: serializer.fromJson<String>(json['workspaceType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'workspaceType': serializer.toJson<String>(workspaceType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  WorkspaceEntity copyWith({
    String? id,
    String? name,
    String? workspaceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => WorkspaceEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    workspaceType: workspaceType ?? this.workspaceType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkspaceEntity copyWithCompanion(WorkspacesCompanion data) {
    return WorkspaceEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      workspaceType: data.workspaceType.present
          ? data.workspaceType.value
          : this.workspaceType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('workspaceType: $workspaceType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    workspaceType,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.workspaceType == this.workspaceType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspaceEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> workspaceType;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.workspaceType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    this.workspaceType = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkspaceEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? workspaceType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (workspaceType != null) 'workspace_type': workspaceType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? workspaceType,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceType: workspaceType ?? this.workspaceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (workspaceType.present) {
      map['workspace_type'] = Variable<String>(workspaceType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('workspaceType: $workspaceType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    iconKey,
    colorHex,
    isSystem,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryEntity extends DataClass implements Insertable<CategoryEntity> {
  final String id;
  final String workspaceId;
  final String name;
  final String? iconKey;
  final String? colorHex;
  final bool isSystem;
  final DateTime createdAt;
  const CategoryEntity({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.iconKey,
    this.colorHex,
    required this.isSystem,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isSystem: Value(isSystem),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryEntity(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String?>(iconKey),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isSystem': serializer.toJson<bool>(isSystem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryEntity copyWith({
    String? id,
    String? workspaceId,
    String? name,
    Value<String?> iconKey = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    bool? isSystem,
    DateTime? createdAt,
  }) => CategoryEntity(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    isSystem: isSystem ?? this.isSystem,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryEntity copyWithCompanion(CategoriesCompanion data) {
    return CategoryEntity(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntity(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    iconKey,
    colorHex,
    isSystem,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntity &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorHex == this.colorHex &&
          other.isSystem == this.isSystem &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryEntity> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> iconKey;
  final Value<String?> colorHex;
  final Value<bool> isSystem;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    this.iconKey = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CategoryEntity> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<String>? colorHex,
    Expression<bool>? isSystem,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorHex != null) 'color_hex': colorHex,
      if (isSystem != null) 'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String?>? iconKey,
    Value<String?>? colorHex,
    Value<bool>? isSystem,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records
    with TableInfo<$RecordsTable, RecordEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _recordTypeMeta = const VerificationMeta(
    'recordType',
  );
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
    'record_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    categoryId,
    recordType,
    title,
    description,
    status,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('record_type')) {
      context.handle(
        _recordTypeMeta,
        recordType.isAcceptableOrUnknown(data['record_type']!, _recordTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      recordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }
}

class RecordEntity extends DataClass implements Insertable<RecordEntity> {
  final String id;
  final String workspaceId;
  final String? categoryId;
  final String recordType;
  final String title;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  const RecordEntity({
    required this.id,
    required this.workspaceId,
    this.categoryId,
    required this.recordType,
    required this.title,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['record_type'] = Variable<String>(recordType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      recordType: Value(recordType),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RecordEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordEntity(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      recordType: serializer.fromJson<String>(json['recordType']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'recordType': serializer.toJson<String>(recordType),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  RecordEntity copyWith({
    String? id,
    String? workspaceId,
    Value<String?> categoryId = const Value.absent(),
    String? recordType,
    String? title,
    Value<String?> description = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => RecordEntity(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    recordType: recordType ?? this.recordType,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RecordEntity copyWithCompanion(RecordsCompanion data) {
    return RecordEntity(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordEntity(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('categoryId: $categoryId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    categoryId,
    recordType,
    title,
    description,
    status,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordEntity &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.categoryId == this.categoryId &&
          other.recordType == this.recordType &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt);
}

class RecordsCompanion extends UpdateCompanion<RecordEntity> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String?> categoryId;
  final Value<String> recordType;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.recordType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordsCompanion.insert({
    required String id,
    required String workspaceId,
    this.categoryId = const Value.absent(),
    required String recordType,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       recordType = Value(recordType),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecordEntity> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? categoryId,
    Expression<String>? recordType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (categoryId != null) 'category_id': categoryId,
      if (recordType != null) 'record_type': recordType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String?>? categoryId,
    Value<String>? recordType,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return RecordsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      categoryId: categoryId ?? this.categoryId,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('categoryId: $categoryId, ')
          ..write('recordType: $recordType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, AssetEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseAmountMinorMeta =
      const VerificationMeta('purchaseAmountMinor');
  @override
  late final GeneratedColumn<int> purchaseAmountMinor = GeneratedColumn<int>(
    'purchase_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseCurrencyMeta = const VerificationMeta(
    'purchaseCurrency',
  );
  @override
  late final GeneratedColumn<String> purchaseCurrency = GeneratedColumn<String>(
    'purchase_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PHP'),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationDescriptionMeta =
      const VerificationMeta('locationDescription');
  @override
  late final GeneratedColumn<String> locationDescription =
      GeneratedColumn<String>(
        'location_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _acquiredFromMeta = const VerificationMeta(
    'acquiredFrom',
  );
  @override
  late final GeneratedColumn<String> acquiredFrom = GeneratedColumn<String>(
    'acquired_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disposedAtMeta = const VerificationMeta(
    'disposedAt',
  );
  @override
  late final GeneratedColumn<DateTime> disposedAt = GeneratedColumn<DateTime>(
    'disposed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    purchaseDate,
    purchaseAmountMinor,
    purchaseCurrency,
    brand,
    model,
    serialNumber,
    condition,
    locationDescription,
    acquiredFrom,
    disposedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('purchase_amount_minor')) {
      context.handle(
        _purchaseAmountMinorMeta,
        purchaseAmountMinor.isAcceptableOrUnknown(
          data['purchase_amount_minor']!,
          _purchaseAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('purchase_currency')) {
      context.handle(
        _purchaseCurrencyMeta,
        purchaseCurrency.isAcceptableOrUnknown(
          data['purchase_currency']!,
          _purchaseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('location_description')) {
      context.handle(
        _locationDescriptionMeta,
        locationDescription.isAcceptableOrUnknown(
          data['location_description']!,
          _locationDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('acquired_from')) {
      context.handle(
        _acquiredFromMeta,
        acquiredFrom.isAcceptableOrUnknown(
          data['acquired_from']!,
          _acquiredFromMeta,
        ),
      );
    }
    if (data.containsKey('disposed_at')) {
      context.handle(
        _disposedAtMeta,
        disposedAt.isAcceptableOrUnknown(data['disposed_at']!, _disposedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  AssetEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetEntity(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      purchaseAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_amount_minor'],
      ),
      purchaseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_currency'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      locationDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_description'],
      ),
      acquiredFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acquired_from'],
      ),
      disposedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}disposed_at'],
      ),
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class AssetEntity extends DataClass implements Insertable<AssetEntity> {
  final String recordId;
  final DateTime? purchaseDate;
  final int? purchaseAmountMinor;
  final String? purchaseCurrency;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? condition;
  final String? locationDescription;
  final String? acquiredFrom;
  final DateTime? disposedAt;
  const AssetEntity({
    required this.recordId,
    this.purchaseDate,
    this.purchaseAmountMinor,
    this.purchaseCurrency,
    this.brand,
    this.model,
    this.serialNumber,
    this.condition,
    this.locationDescription,
    this.acquiredFrom,
    this.disposedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || purchaseAmountMinor != null) {
      map['purchase_amount_minor'] = Variable<int>(purchaseAmountMinor);
    }
    if (!nullToAbsent || purchaseCurrency != null) {
      map['purchase_currency'] = Variable<String>(purchaseCurrency);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || locationDescription != null) {
      map['location_description'] = Variable<String>(locationDescription);
    }
    if (!nullToAbsent || acquiredFrom != null) {
      map['acquired_from'] = Variable<String>(acquiredFrom);
    }
    if (!nullToAbsent || disposedAt != null) {
      map['disposed_at'] = Variable<DateTime>(disposedAt);
    }
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      recordId: Value(recordId),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      purchaseAmountMinor: purchaseAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseAmountMinor),
      purchaseCurrency: purchaseCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseCurrency),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      locationDescription: locationDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(locationDescription),
      acquiredFrom: acquiredFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredFrom),
      disposedAt: disposedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disposedAt),
    );
  }

  factory AssetEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetEntity(
      recordId: serializer.fromJson<String>(json['recordId']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      purchaseAmountMinor: serializer.fromJson<int?>(
        json['purchaseAmountMinor'],
      ),
      purchaseCurrency: serializer.fromJson<String?>(json['purchaseCurrency']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      condition: serializer.fromJson<String?>(json['condition']),
      locationDescription: serializer.fromJson<String?>(
        json['locationDescription'],
      ),
      acquiredFrom: serializer.fromJson<String?>(json['acquiredFrom']),
      disposedAt: serializer.fromJson<DateTime?>(json['disposedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'purchaseAmountMinor': serializer.toJson<int?>(purchaseAmountMinor),
      'purchaseCurrency': serializer.toJson<String?>(purchaseCurrency),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'condition': serializer.toJson<String?>(condition),
      'locationDescription': serializer.toJson<String?>(locationDescription),
      'acquiredFrom': serializer.toJson<String?>(acquiredFrom),
      'disposedAt': serializer.toJson<DateTime?>(disposedAt),
    };
  }

  AssetEntity copyWith({
    String? recordId,
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<int?> purchaseAmountMinor = const Value.absent(),
    Value<String?> purchaseCurrency = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> locationDescription = const Value.absent(),
    Value<String?> acquiredFrom = const Value.absent(),
    Value<DateTime?> disposedAt = const Value.absent(),
  }) => AssetEntity(
    recordId: recordId ?? this.recordId,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    purchaseAmountMinor: purchaseAmountMinor.present
        ? purchaseAmountMinor.value
        : this.purchaseAmountMinor,
    purchaseCurrency: purchaseCurrency.present
        ? purchaseCurrency.value
        : this.purchaseCurrency,
    brand: brand.present ? brand.value : this.brand,
    model: model.present ? model.value : this.model,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    condition: condition.present ? condition.value : this.condition,
    locationDescription: locationDescription.present
        ? locationDescription.value
        : this.locationDescription,
    acquiredFrom: acquiredFrom.present ? acquiredFrom.value : this.acquiredFrom,
    disposedAt: disposedAt.present ? disposedAt.value : this.disposedAt,
  );
  AssetEntity copyWithCompanion(AssetsCompanion data) {
    return AssetEntity(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      purchaseAmountMinor: data.purchaseAmountMinor.present
          ? data.purchaseAmountMinor.value
          : this.purchaseAmountMinor,
      purchaseCurrency: data.purchaseCurrency.present
          ? data.purchaseCurrency.value
          : this.purchaseCurrency,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      condition: data.condition.present ? data.condition.value : this.condition,
      locationDescription: data.locationDescription.present
          ? data.locationDescription.value
          : this.locationDescription,
      acquiredFrom: data.acquiredFrom.present
          ? data.acquiredFrom.value
          : this.acquiredFrom,
      disposedAt: data.disposedAt.present
          ? data.disposedAt.value
          : this.disposedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetEntity(')
          ..write('recordId: $recordId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchaseAmountMinor: $purchaseAmountMinor, ')
          ..write('purchaseCurrency: $purchaseCurrency, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('condition: $condition, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('acquiredFrom: $acquiredFrom, ')
          ..write('disposedAt: $disposedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    purchaseDate,
    purchaseAmountMinor,
    purchaseCurrency,
    brand,
    model,
    serialNumber,
    condition,
    locationDescription,
    acquiredFrom,
    disposedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetEntity &&
          other.recordId == this.recordId &&
          other.purchaseDate == this.purchaseDate &&
          other.purchaseAmountMinor == this.purchaseAmountMinor &&
          other.purchaseCurrency == this.purchaseCurrency &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.serialNumber == this.serialNumber &&
          other.condition == this.condition &&
          other.locationDescription == this.locationDescription &&
          other.acquiredFrom == this.acquiredFrom &&
          other.disposedAt == this.disposedAt);
}

class AssetsCompanion extends UpdateCompanion<AssetEntity> {
  final Value<String> recordId;
  final Value<DateTime?> purchaseDate;
  final Value<int?> purchaseAmountMinor;
  final Value<String?> purchaseCurrency;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<String?> serialNumber;
  final Value<String?> condition;
  final Value<String?> locationDescription;
  final Value<String?> acquiredFrom;
  final Value<DateTime?> disposedAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.recordId = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchaseAmountMinor = const Value.absent(),
    this.purchaseCurrency = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.condition = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.acquiredFrom = const Value.absent(),
    this.disposedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String recordId,
    this.purchaseDate = const Value.absent(),
    this.purchaseAmountMinor = const Value.absent(),
    this.purchaseCurrency = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.condition = const Value.absent(),
    this.locationDescription = const Value.absent(),
    this.acquiredFrom = const Value.absent(),
    this.disposedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId);
  static Insertable<AssetEntity> custom({
    Expression<String>? recordId,
    Expression<DateTime>? purchaseDate,
    Expression<int>? purchaseAmountMinor,
    Expression<String>? purchaseCurrency,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? serialNumber,
    Expression<String>? condition,
    Expression<String>? locationDescription,
    Expression<String>? acquiredFrom,
    Expression<DateTime>? disposedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchaseAmountMinor != null)
        'purchase_amount_minor': purchaseAmountMinor,
      if (purchaseCurrency != null) 'purchase_currency': purchaseCurrency,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (condition != null) 'condition': condition,
      if (locationDescription != null)
        'location_description': locationDescription,
      if (acquiredFrom != null) 'acquired_from': acquiredFrom,
      if (disposedAt != null) 'disposed_at': disposedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? recordId,
    Value<DateTime?>? purchaseDate,
    Value<int?>? purchaseAmountMinor,
    Value<String?>? purchaseCurrency,
    Value<String?>? brand,
    Value<String?>? model,
    Value<String?>? serialNumber,
    Value<String?>? condition,
    Value<String?>? locationDescription,
    Value<String?>? acquiredFrom,
    Value<DateTime?>? disposedAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      recordId: recordId ?? this.recordId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseAmountMinor: purchaseAmountMinor ?? this.purchaseAmountMinor,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      condition: condition ?? this.condition,
      locationDescription: locationDescription ?? this.locationDescription,
      acquiredFrom: acquiredFrom ?? this.acquiredFrom,
      disposedAt: disposedAt ?? this.disposedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (purchaseAmountMinor.present) {
      map['purchase_amount_minor'] = Variable<int>(purchaseAmountMinor.value);
    }
    if (purchaseCurrency.present) {
      map['purchase_currency'] = Variable<String>(purchaseCurrency.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (locationDescription.present) {
      map['location_description'] = Variable<String>(locationDescription.value);
    }
    if (acquiredFrom.present) {
      map['acquired_from'] = Variable<String>(acquiredFrom.value);
    }
    if (disposedAt.present) {
      map['disposed_at'] = Variable<DateTime>(disposedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchaseAmountMinor: $purchaseAmountMinor, ')
          ..write('purchaseCurrency: $purchaseCurrency, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('condition: $condition, ')
          ..write('locationDescription: $locationDescription, ')
          ..write('acquiredFrom: $acquiredFrom, ')
          ..write('disposedAt: $disposedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetRecordIdMeta = const VerificationMeta(
    'assetRecordId',
  );
  @override
  late final GeneratedColumn<String> assetRecordId = GeneratedColumn<String>(
    'asset_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    dueDate,
    priority,
    status,
    completedAt,
    recurrenceRule,
    assetRecordId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('asset_record_id')) {
      context.handle(
        _assetRecordIdMeta,
        assetRecordId.isAcceptableOrUnknown(
          data['asset_record_id']!,
          _assetRecordIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  TaskEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntity(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      assetRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_record_id'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskEntity extends DataClass implements Insertable<TaskEntity> {
  final String recordId;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final DateTime? completedAt;
  final String? recurrenceRule;
  final String? assetRecordId;
  const TaskEntity({
    required this.recordId,
    this.dueDate,
    required this.priority,
    required this.status,
    this.completedAt,
    this.recurrenceRule,
    this.assetRecordId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || assetRecordId != null) {
      map['asset_record_id'] = Variable<String>(assetRecordId);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      recordId: Value(recordId),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      priority: Value(priority),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      assetRecordId: assetRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetRecordId),
    );
  }

  factory TaskEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntity(
      recordId: serializer.fromJson<String>(json['recordId']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      assetRecordId: serializer.fromJson<String?>(json['assetRecordId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'assetRecordId': serializer.toJson<String?>(assetRecordId),
    };
  }

  TaskEntity copyWith({
    String? recordId,
    Value<DateTime?> dueDate = const Value.absent(),
    String? priority,
    String? status,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<String?> assetRecordId = const Value.absent(),
  }) => TaskEntity(
    recordId: recordId ?? this.recordId,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    assetRecordId: assetRecordId.present
        ? assetRecordId.value
        : this.assetRecordId,
  );
  TaskEntity copyWithCompanion(TasksCompanion data) {
    return TaskEntity(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      assetRecordId: data.assetRecordId.present
          ? data.assetRecordId.value
          : this.assetRecordId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntity(')
          ..write('recordId: $recordId, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('assetRecordId: $assetRecordId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    dueDate,
    priority,
    status,
    completedAt,
    recurrenceRule,
    assetRecordId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntity &&
          other.recordId == this.recordId &&
          other.dueDate == this.dueDate &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.recurrenceRule == this.recurrenceRule &&
          other.assetRecordId == this.assetRecordId);
}

class TasksCompanion extends UpdateCompanion<TaskEntity> {
  final Value<String> recordId;
  final Value<DateTime?> dueDate;
  final Value<String> priority;
  final Value<String> status;
  final Value<DateTime?> completedAt;
  final Value<String?> recurrenceRule;
  final Value<String?> assetRecordId;
  final Value<int> rowid;
  const TasksCompanion({
    this.recordId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.assetRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String recordId,
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.assetRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId);
  static Insertable<TaskEntity> custom({
    Expression<String>? recordId,
    Expression<DateTime>? dueDate,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<DateTime>? completedAt,
    Expression<String>? recurrenceRule,
    Expression<String>? assetRecordId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (dueDate != null) 'due_date': dueDate,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (assetRecordId != null) 'asset_record_id': assetRecordId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? recordId,
    Value<DateTime?>? dueDate,
    Value<String>? priority,
    Value<String>? status,
    Value<DateTime?>? completedAt,
    Value<String?>? recurrenceRule,
    Value<String?>? assetRecordId,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      recordId: recordId ?? this.recordId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      assetRecordId: assetRecordId ?? this.assetRecordId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (assetRecordId.present) {
      map['asset_record_id'] = Variable<String>(assetRecordId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('recordId: $recordId, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('assetRecordId: $assetRecordId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<String> documentType = GeneratedColumn<String>(
    'document_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAssetRecordIdMeta =
      const VerificationMeta('linkedAssetRecordId');
  @override
  late final GeneratedColumn<String> linkedAssetRecordId =
      GeneratedColumn<String>(
        'linked_asset_record_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES records (id) ON DELETE SET NULL',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    fileName,
    filePath,
    documentType,
    fileSizeBytes,
    mimeType,
    linkedAssetRecordId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('linked_asset_record_id')) {
      context.handle(
        _linkedAssetRecordIdMeta,
        linkedAssetRecordId.isAcceptableOrUnknown(
          data['linked_asset_record_id']!,
          _linkedAssetRecordIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  DocumentEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentEntity(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_type'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      linkedAssetRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_asset_record_id'],
      ),
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentEntity extends DataClass implements Insertable<DocumentEntity> {
  final String recordId;
  final String fileName;
  final String? filePath;
  final String documentType;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? linkedAssetRecordId;
  const DocumentEntity({
    required this.recordId,
    required this.fileName,
    this.filePath,
    required this.documentType,
    this.fileSizeBytes,
    this.mimeType,
    this.linkedAssetRecordId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['document_type'] = Variable<String>(documentType);
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || linkedAssetRecordId != null) {
      map['linked_asset_record_id'] = Variable<String>(linkedAssetRecordId);
    }
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      recordId: Value(recordId),
      fileName: Value(fileName),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      documentType: Value(documentType),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      linkedAssetRecordId: linkedAssetRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAssetRecordId),
    );
  }

  factory DocumentEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentEntity(
      recordId: serializer.fromJson<String>(json['recordId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      documentType: serializer.fromJson<String>(json['documentType']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      linkedAssetRecordId: serializer.fromJson<String?>(
        json['linkedAssetRecordId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String?>(filePath),
      'documentType': serializer.toJson<String>(documentType),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'mimeType': serializer.toJson<String?>(mimeType),
      'linkedAssetRecordId': serializer.toJson<String?>(linkedAssetRecordId),
    };
  }

  DocumentEntity copyWith({
    String? recordId,
    String? fileName,
    Value<String?> filePath = const Value.absent(),
    String? documentType,
    Value<int?> fileSizeBytes = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<String?> linkedAssetRecordId = const Value.absent(),
  }) => DocumentEntity(
    recordId: recordId ?? this.recordId,
    fileName: fileName ?? this.fileName,
    filePath: filePath.present ? filePath.value : this.filePath,
    documentType: documentType ?? this.documentType,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    linkedAssetRecordId: linkedAssetRecordId.present
        ? linkedAssetRecordId.value
        : this.linkedAssetRecordId,
  );
  DocumentEntity copyWithCompanion(DocumentsCompanion data) {
    return DocumentEntity(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      linkedAssetRecordId: data.linkedAssetRecordId.present
          ? data.linkedAssetRecordId.value
          : this.linkedAssetRecordId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentEntity(')
          ..write('recordId: $recordId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('documentType: $documentType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('linkedAssetRecordId: $linkedAssetRecordId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    fileName,
    filePath,
    documentType,
    fileSizeBytes,
    mimeType,
    linkedAssetRecordId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentEntity &&
          other.recordId == this.recordId &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.documentType == this.documentType &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.linkedAssetRecordId == this.linkedAssetRecordId);
}

class DocumentsCompanion extends UpdateCompanion<DocumentEntity> {
  final Value<String> recordId;
  final Value<String> fileName;
  final Value<String?> filePath;
  final Value<String> documentType;
  final Value<int?> fileSizeBytes;
  final Value<String?> mimeType;
  final Value<String?> linkedAssetRecordId;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.recordId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.documentType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.linkedAssetRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String recordId,
    required String fileName,
    this.filePath = const Value.absent(),
    this.documentType = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.linkedAssetRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       fileName = Value(fileName);
  static Insertable<DocumentEntity> custom({
    Expression<String>? recordId,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<String>? documentType,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? linkedAssetRecordId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (documentType != null) 'document_type': documentType,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (linkedAssetRecordId != null)
        'linked_asset_record_id': linkedAssetRecordId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? recordId,
    Value<String>? fileName,
    Value<String?>? filePath,
    Value<String>? documentType,
    Value<int?>? fileSizeBytes,
    Value<String?>? mimeType,
    Value<String?>? linkedAssetRecordId,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      recordId: recordId ?? this.recordId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      documentType: documentType ?? this.documentType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      linkedAssetRecordId: linkedAssetRecordId ?? this.linkedAssetRecordId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<String>(documentType.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (linkedAssetRecordId.present) {
      map['linked_asset_record_id'] = Variable<String>(
        linkedAssetRecordId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('documentType: $documentType, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('linkedAssetRecordId: $linkedAssetRecordId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final Index recordsWorkspaceDeletedIdx = Index(
    'records_workspace_deleted_idx',
    'CREATE INDEX records_workspace_deleted_idx ON records (workspace_id, deleted_at)',
  );
  late final Index recordsCategoryIdx = Index(
    'records_category_idx',
    'CREATE INDEX records_category_idx ON records (category_id)',
  );
  late final Index tasksStatusDueIdx = Index(
    'tasks_status_due_idx',
    'CREATE INDEX tasks_status_due_idx ON tasks (status, due_date)',
  );
  late final Index documentsLinkedAssetIdx = Index(
    'documents_linked_asset_idx',
    'CREATE INDEX documents_linked_asset_idx ON documents (linked_asset_record_id)',
  );
  late final Index documentsTypeIdx = Index(
    'documents_type_idx',
    'CREATE INDEX documents_type_idx ON documents (document_type)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    categories,
    records,
    assets,
    tasks,
    documents,
    recordsWorkspaceDeletedIdx,
    recordsCategoryIdx,
    tasksStatusDueIdx,
    documentsLinkedAssetIdx,
    documentsTypeIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('records', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('documents', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$WorkspacesTableCreateCompanionBuilder =
    WorkspacesCompanion Function({
      required String id,
      required String name,
      Value<String> workspaceType,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkspacesTableUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> workspaceType,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$WorkspacesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceEntity> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<CategoryEntity>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'workspaces__id__categories__workspace_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecordsTable, List<RecordEntity>>
  _recordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.records,
    aliasName: 'workspaces__id__records__workspace_id',
  );

  $$RecordsTableProcessedTableManager get recordsRefs {
    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceType => $composableBuilder(
    column: $table.workspaceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordsRefs(
    Expression<bool> Function($$RecordsTableFilterComposer f) f,
  ) {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceType => $composableBuilder(
    column: $table.workspaceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get workspaceType => $composableBuilder(
    column: $table.workspaceType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordsRefs<T extends Object>(
    Expression<T> Function($$RecordsTableAnnotationComposer a) f,
  ) {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          WorkspaceEntity,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (WorkspaceEntity, $$WorkspacesTableReferences),
          WorkspaceEntity,
          PrefetchHooks Function({bool categoriesRefs, bool recordsRefs})
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> workspaceType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                workspaceType: workspaceType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> workspaceType = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                workspaceType: workspaceType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTable, WorkspaceEntity>(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoriesRefs = false, recordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoriesRefs) db.categories,
                    if (recordsRefs) db.records,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntity,
                          $WorkspacesTable,
                          CategoryEntity,
                          $CategoriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (recordsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntity,
                          $WorkspacesTable,
                          RecordEntity,
                          $RecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._recordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).recordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      WorkspaceEntity,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (WorkspaceEntity, $$WorkspacesTableReferences),
      WorkspaceEntity,
      PrefetchHooks Function({bool categoriesRefs, bool recordsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String workspaceId,
      required String name,
      Value<String?> iconKey,
      Value<String?> colorHex,
      Value<bool> isSystem,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> name,
      Value<String?> iconKey,
      Value<String?> colorHex,
      Value<bool> isSystem,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryEntity> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('categories__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RecordsTable, List<RecordEntity>>
  _recordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.records,
    aliasName: 'categories__id__records__category_id',
  );

  $$RecordsTableProcessedTableManager get recordsRefs {
    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> recordsRefs(
    Expression<bool> Function($$RecordsTableFilterComposer f) f,
  ) {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> recordsRefs<T extends Object>(
    Expression<T> Function($$RecordsTableAnnotationComposer a) f,
  ) {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryEntity,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryEntity, $$CategoriesTableReferences),
          CategoryEntity,
          PrefetchHooks Function({bool workspaceId, bool recordsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                iconKey: iconKey,
                colorHex: colorHex,
                isSystem: isSystem,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                Value<String?> iconKey = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                iconKey: iconKey,
                colorHex: colorHex,
                isSystem: isSystem,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryEntity>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, recordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recordsRefs) db.records],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable: $$CategoriesTableReferences
                                    ._workspaceIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._workspaceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recordsRefs)
                    await $_getPrefetchedDataByColumns<
                      CategoryEntity,
                      $CategoriesTable,
                      RecordEntity,
                      $RecordsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._recordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).recordsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryEntity,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryEntity, $$CategoriesTableReferences),
      CategoryEntity,
      PrefetchHooks Function({bool workspaceId, bool recordsRefs})
    >;
typedef $$RecordsTableCreateCompanionBuilder =
    RecordsCompanion Function({
      required String id,
      required String workspaceId,
      Value<String?> categoryId,
      required String recordType,
      required String title,
      Value<String?> description,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$RecordsTableUpdateCompanionBuilder =
    RecordsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String?> categoryId,
      Value<String> recordType,
      Value<String> title,
      Value<String?> description,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$RecordsTableReferences
    extends BaseReferences<_$AppDatabase, $RecordsTable, RecordEntity> {
  $$RecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('records__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('records__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<AssetEntity>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: 'records__id__assets__record_id',
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntity>> _taskRecordTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'records__id__tasks__record_id',
  );

  $$TasksTableProcessedTableManager get taskRecord {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRecordTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntity>> _tasksForAssetTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'records__id__tasks__asset_record_id',
  );

  $$TasksTableProcessedTableManager get tasksForAsset {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.assetRecordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksForAssetTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DocumentsTable, List<DocumentEntity>>
  _documentRecordTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documents,
    aliasName: 'records__id__documents__record_id',
  );

  $$DocumentsTableProcessedTableManager get documentRecord {
    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentRecordTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DocumentsTable, List<DocumentEntity>>
  _documentsForAssetTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documents,
    aliasName: 'records__id__documents__linked_asset_record_id',
  );

  $$DocumentsTableProcessedTableManager get documentsForAsset {
    final manager = $$DocumentsTableTableManager($_db, $_db.documents).filter(
      (f) => f.linkedAssetRecordId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_documentsForAssetTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskRecord(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksForAsset(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.assetRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> documentRecord(
    Expression<bool> Function($$DocumentsTableFilterComposer f) f,
  ) {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> documentsForAsset(
    Expression<bool> Function($$DocumentsTableFilterComposer f) f,
  ) {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.linkedAssetRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskRecord<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksForAsset<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.assetRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> documentRecord<T extends Object>(
    Expression<T> Function($$DocumentsTableAnnotationComposer a) f,
  ) {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> documentsForAsset<T extends Object>(
    Expression<T> Function($$DocumentsTableAnnotationComposer a) f,
  ) {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.linkedAssetRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordsTable,
          RecordEntity,
          $$RecordsTableFilterComposer,
          $$RecordsTableOrderingComposer,
          $$RecordsTableAnnotationComposer,
          $$RecordsTableCreateCompanionBuilder,
          $$RecordsTableUpdateCompanionBuilder,
          (RecordEntity, $$RecordsTableReferences),
          RecordEntity,
          PrefetchHooks Function({
            bool workspaceId,
            bool categoryId,
            bool assetsRefs,
            bool taskRecord,
            bool tasksForAsset,
            bool documentRecord,
            bool documentsForAsset,
          })
        > {
  $$RecordsTableTableManager(_$AppDatabase db, $RecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> recordType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordsCompanion(
                id: id,
                workspaceId: workspaceId,
                categoryId: categoryId,
                recordType: recordType,
                title: title,
                description: description,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String?> categoryId = const Value.absent(),
                required String recordType,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                categoryId: categoryId,
                recordType: recordType,
                title: title,
                description: description,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordsTable, RecordEntity>(table),
                  $$RecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                categoryId = false,
                assetsRefs = false,
                taskRecord = false,
                tasksForAsset = false,
                documentRecord = false,
                documentsForAsset = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetsRefs) db.assets,
                    if (taskRecord) db.tasks,
                    if (tasksForAsset) db.tasks,
                    if (documentRecord) db.documents,
                    if (documentsForAsset) db.documents,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$RecordsTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$RecordsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$RecordsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$RecordsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetsRefs)
                        await $_getPrefetchedDataByColumns<
                          RecordEntity,
                          $RecordsTable,
                          AssetEntity,
                          $AssetsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'record_id',
                          typedResults: items,
                        ),
                      if (taskRecord)
                        await $_getPrefetchedDataByColumns<
                          RecordEntity,
                          $RecordsTable,
                          TaskEntity,
                          $TasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._taskRecordTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRecord,
                          currentColumn: 'id',
                          referencedColumn: 'record_id',
                          typedResults: items,
                        ),
                      if (tasksForAsset)
                        await $_getPrefetchedDataByColumns<
                          RecordEntity,
                          $RecordsTable,
                          TaskEntity,
                          $TasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._tasksForAssetTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksForAsset,
                          currentColumn: 'id',
                          referencedColumn: 'asset_record_id',
                          typedResults: items,
                        ),
                      if (documentRecord)
                        await $_getPrefetchedDataByColumns<
                          RecordEntity,
                          $RecordsTable,
                          DocumentEntity,
                          $DocumentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._documentRecordTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).documentRecord,
                          currentColumn: 'id',
                          referencedColumn: 'record_id',
                          typedResults: items,
                        ),
                      if (documentsForAsset)
                        await $_getPrefetchedDataByColumns<
                          RecordEntity,
                          $RecordsTable,
                          DocumentEntity,
                          $DocumentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._documentsForAssetTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).documentsForAsset,
                          currentColumn: 'id',
                          referencedColumn: 'linked_asset_record_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordsTable,
      RecordEntity,
      $$RecordsTableFilterComposer,
      $$RecordsTableOrderingComposer,
      $$RecordsTableAnnotationComposer,
      $$RecordsTableCreateCompanionBuilder,
      $$RecordsTableUpdateCompanionBuilder,
      (RecordEntity, $$RecordsTableReferences),
      RecordEntity,
      PrefetchHooks Function({
        bool workspaceId,
        bool categoryId,
        bool assetsRefs,
        bool taskRecord,
        bool tasksForAsset,
        bool documentRecord,
        bool documentsForAsset,
      })
    >;
typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String recordId,
      Value<DateTime?> purchaseDate,
      Value<int?> purchaseAmountMinor,
      Value<String?> purchaseCurrency,
      Value<String?> brand,
      Value<String?> model,
      Value<String?> serialNumber,
      Value<String?> condition,
      Value<String?> locationDescription,
      Value<String?> acquiredFrom,
      Value<DateTime?> disposedAt,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> recordId,
      Value<DateTime?> purchaseDate,
      Value<int?> purchaseAmountMinor,
      Value<String?> purchaseCurrency,
      Value<String?> brand,
      Value<String?> model,
      Value<String?> serialNumber,
      Value<String?> condition,
      Value<String?> locationDescription,
      Value<String?> acquiredFrom,
      Value<DateTime?> disposedAt,
      Value<int> rowid,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, AssetEntity> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordsTable _recordIdTable(_$AppDatabase db) =>
      db.records.createAlias('assets__record_id__records__id');

  $$RecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<String>('record_id')!;

    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchaseAmountMinor => $composableBuilder(
    column: $table.purchaseAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acquiredFrom => $composableBuilder(
    column: $table.acquiredFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get disposedAt => $composableBuilder(
    column: $table.disposedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordsTableFilterComposer get recordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchaseAmountMinor => $composableBuilder(
    column: $table.purchaseAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acquiredFrom => $composableBuilder(
    column: $table.acquiredFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get disposedAt => $composableBuilder(
    column: $table.disposedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordsTableOrderingComposer get recordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchaseAmountMinor => $composableBuilder(
    column: $table.purchaseAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseCurrency => $composableBuilder(
    column: $table.purchaseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get locationDescription => $composableBuilder(
    column: $table.locationDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acquiredFrom => $composableBuilder(
    column: $table.acquiredFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get disposedAt => $composableBuilder(
    column: $table.disposedAt,
    builder: (column) => column,
  );

  $$RecordsTableAnnotationComposer get recordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          AssetEntity,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (AssetEntity, $$AssetsTableReferences),
          AssetEntity,
          PrefetchHooks Function({bool recordId})
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<int?> purchaseAmountMinor = const Value.absent(),
                Value<String?> purchaseCurrency = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<String?> acquiredFrom = const Value.absent(),
                Value<DateTime?> disposedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                recordId: recordId,
                purchaseDate: purchaseDate,
                purchaseAmountMinor: purchaseAmountMinor,
                purchaseCurrency: purchaseCurrency,
                brand: brand,
                model: model,
                serialNumber: serialNumber,
                condition: condition,
                locationDescription: locationDescription,
                acquiredFrom: acquiredFrom,
                disposedAt: disposedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<int?> purchaseAmountMinor = const Value.absent(),
                Value<String?> purchaseCurrency = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> locationDescription = const Value.absent(),
                Value<String?> acquiredFrom = const Value.absent(),
                Value<DateTime?> disposedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                recordId: recordId,
                purchaseDate: purchaseDate,
                purchaseAmountMinor: purchaseAmountMinor,
                purchaseCurrency: purchaseCurrency,
                brand: brand,
                model: model,
                serialNumber: serialNumber,
                condition: condition,
                locationDescription: locationDescription,
                acquiredFrom: acquiredFrom,
                disposedAt: disposedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetsTable, AssetEntity>(table),
                  $$AssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable: $$AssetsTableReferences
                                    ._recordIdTable(db),
                                referencedColumn: $$AssetsTableReferences
                                    ._recordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      AssetEntity,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (AssetEntity, $$AssetsTableReferences),
      AssetEntity,
      PrefetchHooks Function({bool recordId})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String recordId,
      Value<DateTime?> dueDate,
      Value<String> priority,
      Value<String> status,
      Value<DateTime?> completedAt,
      Value<String?> recurrenceRule,
      Value<String?> assetRecordId,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> recordId,
      Value<DateTime?> dueDate,
      Value<String> priority,
      Value<String> status,
      Value<DateTime?> completedAt,
      Value<String?> recurrenceRule,
      Value<String?> assetRecordId,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskEntity> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordsTable _recordIdTable(_$AppDatabase db) =>
      db.records.createAlias('tasks__record_id__records__id');

  $$RecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<String>('record_id')!;

    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecordsTable _assetRecordIdTable(_$AppDatabase db) =>
      db.records.createAlias('tasks__asset_record_id__records__id');

  $$RecordsTableProcessedTableManager? get assetRecordId {
    final $_column = $_itemColumn<String>('asset_record_id');
    if ($_column == null) return null;
    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordsTableFilterComposer get recordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableFilterComposer get assetRecordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordsTableOrderingComposer get recordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableOrderingComposer get assetRecordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  $$RecordsTableAnnotationComposer get recordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableAnnotationComposer get assetRecordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskEntity,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskEntity, $$TasksTableReferences),
          TaskEntity,
          PrefetchHooks Function({bool recordId, bool assetRecordId})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> assetRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                recordId: recordId,
                dueDate: dueDate,
                priority: priority,
                status: status,
                completedAt: completedAt,
                recurrenceRule: recurrenceRule,
                assetRecordId: assetRecordId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> assetRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                recordId: recordId,
                dueDate: dueDate,
                priority: priority,
                status: status,
                completedAt: completedAt,
                recurrenceRule: recurrenceRule,
                assetRecordId: assetRecordId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskEntity>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false, assetRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable: $$TasksTableReferences
                                    ._recordIdTable(db),
                                referencedColumn: $$TasksTableReferences
                                    ._recordIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (assetRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetRecordId,
                                referencedTable: $$TasksTableReferences
                                    ._assetRecordIdTable(db),
                                referencedColumn: $$TasksTableReferences
                                    ._assetRecordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskEntity,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskEntity, $$TasksTableReferences),
      TaskEntity,
      PrefetchHooks Function({bool recordId, bool assetRecordId})
    >;
typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String recordId,
      required String fileName,
      Value<String?> filePath,
      Value<String> documentType,
      Value<int?> fileSizeBytes,
      Value<String?> mimeType,
      Value<String?> linkedAssetRecordId,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> recordId,
      Value<String> fileName,
      Value<String?> filePath,
      Value<String> documentType,
      Value<int?> fileSizeBytes,
      Value<String?> mimeType,
      Value<String?> linkedAssetRecordId,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentEntity> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordsTable _recordIdTable(_$AppDatabase db) =>
      db.records.createAlias('documents__record_id__records__id');

  $$RecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<String>('record_id')!;

    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecordsTable _linkedAssetRecordIdTable(_$AppDatabase db) =>
      db.records.createAlias('documents__linked_asset_record_id__records__id');

  $$RecordsTableProcessedTableManager? get linkedAssetRecordId {
    final $_column = $_itemColumn<String>('linked_asset_record_id');
    if ($_column == null) return null;
    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedAssetRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordsTableFilterComposer get recordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableFilterComposer get linkedAssetRecordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAssetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordsTableOrderingComposer get recordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableOrderingComposer get linkedAssetRecordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAssetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  $$RecordsTableAnnotationComposer get recordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecordsTableAnnotationComposer get linkedAssetRecordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAssetRecordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentEntity,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentEntity, $$DocumentsTableReferences),
          DocumentEntity,
          PrefetchHooks Function({bool recordId, bool linkedAssetRecordId})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> linkedAssetRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                recordId: recordId,
                fileName: fileName,
                filePath: filePath,
                documentType: documentType,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                linkedAssetRecordId: linkedAssetRecordId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String fileName,
                Value<String?> filePath = const Value.absent(),
                Value<String> documentType = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String?> linkedAssetRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                recordId: recordId,
                fileName: fileName,
                filePath: filePath,
                documentType: documentType,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                linkedAssetRecordId: linkedAssetRecordId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentEntity>(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({recordId = false, linkedAssetRecordId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (recordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recordId,
                                    referencedTable: $$DocumentsTableReferences
                                        ._recordIdTable(db),
                                    referencedColumn: $$DocumentsTableReferences
                                        ._recordIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (linkedAssetRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.linkedAssetRecordId,
                                    referencedTable: $$DocumentsTableReferences
                                        ._linkedAssetRecordIdTable(db),
                                    referencedColumn: $$DocumentsTableReferences
                                        ._linkedAssetRecordIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentEntity,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentEntity, $$DocumentsTableReferences),
      DocumentEntity,
      PrefetchHooks Function({bool recordId, bool linkedAssetRecordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
}
