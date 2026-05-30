// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _midMeta = const VerificationMeta('mid');
  @override
  late final GeneratedColumn<int> mid = GeneratedColumn<int>(
    'mid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<int> fromId = GeneratedColumn<int>(
    'from_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<int> toId = GeneratedColumn<int>(
    'to_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _msgTypeMeta = const VerificationMeta(
    'msgType',
  );
  @override
  late final GeneratedColumn<int> msgType = GeneratedColumn<int>(
    'msg_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _msgSeqMeta = const VerificationMeta('msgSeq');
  @override
  late final GeneratedColumn<int> msgSeq = GeneratedColumn<int>(
    'msg_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _replyMsgIdMeta = const VerificationMeta(
    'replyMsgId',
  );
  @override
  late final GeneratedColumn<int> replyMsgId = GeneratedColumn<int>(
    'reply_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atUserIdsMeta = const VerificationMeta(
    'atUserIds',
  );
  @override
  late final GeneratedColumn<String> atUserIds = GeneratedColumn<String>(
    'at_user_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readStatusMeta = const VerificationMeta(
    'readStatus',
  );
  @override
  late final GeneratedColumn<int> readStatus = GeneratedColumn<int>(
    'read_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mid,
    fromId,
    toId,
    groupId,
    content,
    msgType,
    status,
    timestamp,
    localPath,
    msgSeq,
    replyMsgId,
    atUserIds,
    extra,
    readStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mid')) {
      context.handle(
        _midMeta,
        mid.isAcceptableOrUnknown(data['mid']!, _midMeta),
      );
    }
    if (data.containsKey('from_id')) {
      context.handle(
        _fromIdMeta,
        fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
        _toIdMeta,
        toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('msg_type')) {
      context.handle(
        _msgTypeMeta,
        msgType.isAcceptableOrUnknown(data['msg_type']!, _msgTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_msgTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('msg_seq')) {
      context.handle(
        _msgSeqMeta,
        msgSeq.isAcceptableOrUnknown(data['msg_seq']!, _msgSeqMeta),
      );
    }
    if (data.containsKey('reply_msg_id')) {
      context.handle(
        _replyMsgIdMeta,
        replyMsgId.isAcceptableOrUnknown(
          data['reply_msg_id']!,
          _replyMsgIdMeta,
        ),
      );
    }
    if (data.containsKey('at_user_ids')) {
      context.handle(
        _atUserIdsMeta,
        atUserIds.isAcceptableOrUnknown(data['at_user_ids']!, _atUserIdsMeta),
      );
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('read_status')) {
      context.handle(
        _readStatusMeta,
        readStatus.isAcceptableOrUnknown(data['read_status']!, _readStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mid'],
      ),
      fromId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_id'],
      )!,
      toId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      msgType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      msgSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_seq'],
      )!,
      replyMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_msg_id'],
      ),
      atUserIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at_user_ids'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      ),
      readStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_status'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int? mid;
  final int fromId;
  final int toId;
  final int? groupId;
  final String content;
  final int msgType;
  final int status;
  final int timestamp;
  final String? localPath;
  final int msgSeq;
  final int? replyMsgId;
  final String atUserIds;
  final String? extra;
  final int readStatus;
  const Message({
    required this.id,
    this.mid,
    required this.fromId,
    required this.toId,
    this.groupId,
    required this.content,
    required this.msgType,
    required this.status,
    required this.timestamp,
    this.localPath,
    required this.msgSeq,
    this.replyMsgId,
    required this.atUserIds,
    this.extra,
    required this.readStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || mid != null) {
      map['mid'] = Variable<int>(mid);
    }
    map['from_id'] = Variable<int>(fromId);
    map['to_id'] = Variable<int>(toId);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['content'] = Variable<String>(content);
    map['msg_type'] = Variable<int>(msgType);
    map['status'] = Variable<int>(status);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['msg_seq'] = Variable<int>(msgSeq);
    if (!nullToAbsent || replyMsgId != null) {
      map['reply_msg_id'] = Variable<int>(replyMsgId);
    }
    map['at_user_ids'] = Variable<String>(atUserIds);
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String>(extra);
    }
    map['read_status'] = Variable<int>(readStatus);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      mid: mid == null && nullToAbsent ? const Value.absent() : Value(mid),
      fromId: Value(fromId),
      toId: Value(toId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      content: Value(content),
      msgType: Value(msgType),
      status: Value(status),
      timestamp: Value(timestamp),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      msgSeq: Value(msgSeq),
      replyMsgId: replyMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyMsgId),
      atUserIds: Value(atUserIds),
      extra: extra == null && nullToAbsent
          ? const Value.absent()
          : Value(extra),
      readStatus: Value(readStatus),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      mid: serializer.fromJson<int?>(json['mid']),
      fromId: serializer.fromJson<int>(json['fromId']),
      toId: serializer.fromJson<int>(json['toId']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      content: serializer.fromJson<String>(json['content']),
      msgType: serializer.fromJson<int>(json['msgType']),
      status: serializer.fromJson<int>(json['status']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      msgSeq: serializer.fromJson<int>(json['msgSeq']),
      replyMsgId: serializer.fromJson<int?>(json['replyMsgId']),
      atUserIds: serializer.fromJson<String>(json['atUserIds']),
      extra: serializer.fromJson<String?>(json['extra']),
      readStatus: serializer.fromJson<int>(json['readStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mid': serializer.toJson<int?>(mid),
      'fromId': serializer.toJson<int>(fromId),
      'toId': serializer.toJson<int>(toId),
      'groupId': serializer.toJson<int?>(groupId),
      'content': serializer.toJson<String>(content),
      'msgType': serializer.toJson<int>(msgType),
      'status': serializer.toJson<int>(status),
      'timestamp': serializer.toJson<int>(timestamp),
      'localPath': serializer.toJson<String?>(localPath),
      'msgSeq': serializer.toJson<int>(msgSeq),
      'replyMsgId': serializer.toJson<int?>(replyMsgId),
      'atUserIds': serializer.toJson<String>(atUserIds),
      'extra': serializer.toJson<String?>(extra),
      'readStatus': serializer.toJson<int>(readStatus),
    };
  }

  Message copyWith({
    int? id,
    Value<int?> mid = const Value.absent(),
    int? fromId,
    int? toId,
    Value<int?> groupId = const Value.absent(),
    String? content,
    int? msgType,
    int? status,
    int? timestamp,
    Value<String?> localPath = const Value.absent(),
    int? msgSeq,
    Value<int?> replyMsgId = const Value.absent(),
    String? atUserIds,
    Value<String?> extra = const Value.absent(),
    int? readStatus,
  }) => Message(
    id: id ?? this.id,
    mid: mid.present ? mid.value : this.mid,
    fromId: fromId ?? this.fromId,
    toId: toId ?? this.toId,
    groupId: groupId.present ? groupId.value : this.groupId,
    content: content ?? this.content,
    msgType: msgType ?? this.msgType,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    localPath: localPath.present ? localPath.value : this.localPath,
    msgSeq: msgSeq ?? this.msgSeq,
    replyMsgId: replyMsgId.present ? replyMsgId.value : this.replyMsgId,
    atUserIds: atUserIds ?? this.atUserIds,
    extra: extra.present ? extra.value : this.extra,
    readStatus: readStatus ?? this.readStatus,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      mid: data.mid.present ? data.mid.value : this.mid,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      content: data.content.present ? data.content.value : this.content,
      msgType: data.msgType.present ? data.msgType.value : this.msgType,
      status: data.status.present ? data.status.value : this.status,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      msgSeq: data.msgSeq.present ? data.msgSeq.value : this.msgSeq,
      replyMsgId: data.replyMsgId.present
          ? data.replyMsgId.value
          : this.replyMsgId,
      atUserIds: data.atUserIds.present ? data.atUserIds.value : this.atUserIds,
      extra: data.extra.present ? data.extra.value : this.extra,
      readStatus: data.readStatus.present
          ? data.readStatus.value
          : this.readStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('mid: $mid, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('groupId: $groupId, ')
          ..write('content: $content, ')
          ..write('msgType: $msgType, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('localPath: $localPath, ')
          ..write('msgSeq: $msgSeq, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUserIds: $atUserIds, ')
          ..write('extra: $extra, ')
          ..write('readStatus: $readStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mid,
    fromId,
    toId,
    groupId,
    content,
    msgType,
    status,
    timestamp,
    localPath,
    msgSeq,
    replyMsgId,
    atUserIds,
    extra,
    readStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.mid == this.mid &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.groupId == this.groupId &&
          other.content == this.content &&
          other.msgType == this.msgType &&
          other.status == this.status &&
          other.timestamp == this.timestamp &&
          other.localPath == this.localPath &&
          other.msgSeq == this.msgSeq &&
          other.replyMsgId == this.replyMsgId &&
          other.atUserIds == this.atUserIds &&
          other.extra == this.extra &&
          other.readStatus == this.readStatus);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int?> mid;
  final Value<int> fromId;
  final Value<int> toId;
  final Value<int?> groupId;
  final Value<String> content;
  final Value<int> msgType;
  final Value<int> status;
  final Value<int> timestamp;
  final Value<String?> localPath;
  final Value<int> msgSeq;
  final Value<int?> replyMsgId;
  final Value<String> atUserIds;
  final Value<String?> extra;
  final Value<int> readStatus;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.mid = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.content = const Value.absent(),
    this.msgType = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.localPath = const Value.absent(),
    this.msgSeq = const Value.absent(),
    this.replyMsgId = const Value.absent(),
    this.atUserIds = const Value.absent(),
    this.extra = const Value.absent(),
    this.readStatus = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    this.mid = const Value.absent(),
    required int fromId,
    required int toId,
    this.groupId = const Value.absent(),
    required String content,
    required int msgType,
    required int status,
    required int timestamp,
    this.localPath = const Value.absent(),
    this.msgSeq = const Value.absent(),
    this.replyMsgId = const Value.absent(),
    this.atUserIds = const Value.absent(),
    this.extra = const Value.absent(),
    this.readStatus = const Value.absent(),
  }) : fromId = Value(fromId),
       toId = Value(toId),
       content = Value(content),
       msgType = Value(msgType),
       status = Value(status),
       timestamp = Value(timestamp);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? mid,
    Expression<int>? fromId,
    Expression<int>? toId,
    Expression<int>? groupId,
    Expression<String>? content,
    Expression<int>? msgType,
    Expression<int>? status,
    Expression<int>? timestamp,
    Expression<String>? localPath,
    Expression<int>? msgSeq,
    Expression<int>? replyMsgId,
    Expression<String>? atUserIds,
    Expression<String>? extra,
    Expression<int>? readStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mid != null) 'mid': mid,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (groupId != null) 'group_id': groupId,
      if (content != null) 'content': content,
      if (msgType != null) 'msg_type': msgType,
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (localPath != null) 'local_path': localPath,
      if (msgSeq != null) 'msg_seq': msgSeq,
      if (replyMsgId != null) 'reply_msg_id': replyMsgId,
      if (atUserIds != null) 'at_user_ids': atUserIds,
      if (extra != null) 'extra': extra,
      if (readStatus != null) 'read_status': readStatus,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int?>? mid,
    Value<int>? fromId,
    Value<int>? toId,
    Value<int?>? groupId,
    Value<String>? content,
    Value<int>? msgType,
    Value<int>? status,
    Value<int>? timestamp,
    Value<String?>? localPath,
    Value<int>? msgSeq,
    Value<int?>? replyMsgId,
    Value<String>? atUserIds,
    Value<String?>? extra,
    Value<int>? readStatus,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      mid: mid ?? this.mid,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      msgType: msgType ?? this.msgType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      localPath: localPath ?? this.localPath,
      msgSeq: msgSeq ?? this.msgSeq,
      replyMsgId: replyMsgId ?? this.replyMsgId,
      atUserIds: atUserIds ?? this.atUserIds,
      extra: extra ?? this.extra,
      readStatus: readStatus ?? this.readStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mid.present) {
      map['mid'] = Variable<int>(mid.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<int>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<int>(toId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (msgType.present) {
      map['msg_type'] = Variable<int>(msgType.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (msgSeq.present) {
      map['msg_seq'] = Variable<int>(msgSeq.value);
    }
    if (replyMsgId.present) {
      map['reply_msg_id'] = Variable<int>(replyMsgId.value);
    }
    if (atUserIds.present) {
      map['at_user_ids'] = Variable<String>(atUserIds.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (readStatus.present) {
      map['read_status'] = Variable<int>(readStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('mid: $mid, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('groupId: $groupId, ')
          ..write('content: $content, ')
          ..write('msgType: $msgType, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('localPath: $localPath, ')
          ..write('msgSeq: $msgSeq, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUserIds: $atUserIds, ')
          ..write('extra: $extra, ')
          ..write('readStatus: $readStatus')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<int> targetType = GeneratedColumn<int>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updateTimeMeta = const VerificationMeta(
    'updateTime',
  );
  @override
  late final GeneratedColumn<int> updateTime = GeneratedColumn<int>(
    'update_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessageContentMeta =
      const VerificationMeta('lastMessageContent');
  @override
  late final GeneratedColumn<String> lastMessageContent =
      GeneratedColumn<String>(
        'last_message_content',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<int> lastMessageType = GeneratedColumn<int>(
    'last_message_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageStatusMeta = const VerificationMeta(
    'lastMessageStatus',
  );
  @override
  late final GeneratedColumn<int> lastMessageStatus = GeneratedColumn<int>(
    'last_message_status',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageTimestampMeta =
      const VerificationMeta('lastMessageTimestamp');
  @override
  late final GeneratedColumn<int> lastMessageTimestamp = GeneratedColumn<int>(
    'last_message_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageFromIdMeta = const VerificationMeta(
    'lastMessageFromId',
  );
  @override
  late final GeneratedColumn<int> lastMessageFromId = GeneratedColumn<int>(
    'last_message_from_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageToIdMeta = const VerificationMeta(
    'lastMessageToId',
  );
  @override
  late final GeneratedColumn<int> lastMessageToId = GeneratedColumn<int>(
    'last_message_to_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageGroupIdMeta =
      const VerificationMeta('lastMessageGroupId');
  @override
  late final GeneratedColumn<int> lastMessageGroupId = GeneratedColumn<int>(
    'last_message_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageLocalPathMeta =
      const VerificationMeta('lastMessageLocalPath');
  @override
  late final GeneratedColumn<String> lastMessageLocalPath =
      GeneratedColumn<String>(
        'last_message_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMsgIdMeta = const VerificationMeta(
    'lastMsgId',
  );
  @override
  late final GeneratedColumn<int> lastMsgId = GeneratedColumn<int>(
    'last_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<int> isTop = GeneratedColumn<int>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMuteMeta = const VerificationMeta('isMute');
  @override
  late final GeneratedColumn<int> isMute = GeneratedColumn<int>(
    'is_mute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _draftContentMeta = const VerificationMeta(
    'draftContent',
  );
  @override
  late final GeneratedColumn<String> draftContent = GeneratedColumn<String>(
    'draft_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    targetType,
    targetId,
    unreadCount,
    updateTime,
    lastMessageContent,
    lastMessageType,
    lastMessageStatus,
    lastMessageTimestamp,
    lastMessageFromId,
    lastMessageToId,
    lastMessageGroupId,
    lastMessageLocalPath,
    lastMsgId,
    isTop,
    isMute,
    isDeleted,
    draftContent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('update_time')) {
      context.handle(
        _updateTimeMeta,
        updateTime.isAcceptableOrUnknown(data['update_time']!, _updateTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_updateTimeMeta);
    }
    if (data.containsKey('last_message_content')) {
      context.handle(
        _lastMessageContentMeta,
        lastMessageContent.isAcceptableOrUnknown(
          data['last_message_content']!,
          _lastMessageContentMeta,
        ),
      );
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_status')) {
      context.handle(
        _lastMessageStatusMeta,
        lastMessageStatus.isAcceptableOrUnknown(
          data['last_message_status']!,
          _lastMessageStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_message_timestamp')) {
      context.handle(
        _lastMessageTimestampMeta,
        lastMessageTimestamp.isAcceptableOrUnknown(
          data['last_message_timestamp']!,
          _lastMessageTimestampMeta,
        ),
      );
    }
    if (data.containsKey('last_message_from_id')) {
      context.handle(
        _lastMessageFromIdMeta,
        lastMessageFromId.isAcceptableOrUnknown(
          data['last_message_from_id']!,
          _lastMessageFromIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_to_id')) {
      context.handle(
        _lastMessageToIdMeta,
        lastMessageToId.isAcceptableOrUnknown(
          data['last_message_to_id']!,
          _lastMessageToIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_group_id')) {
      context.handle(
        _lastMessageGroupIdMeta,
        lastMessageGroupId.isAcceptableOrUnknown(
          data['last_message_group_id']!,
          _lastMessageGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_local_path')) {
      context.handle(
        _lastMessageLocalPathMeta,
        lastMessageLocalPath.isAcceptableOrUnknown(
          data['last_message_local_path']!,
          _lastMessageLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_id')) {
      context.handle(
        _lastMsgIdMeta,
        lastMsgId.isAcceptableOrUnknown(data['last_msg_id']!, _lastMsgIdMeta),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('is_mute')) {
      context.handle(
        _isMuteMeta,
        isMute.isAcceptableOrUnknown(data['is_mute']!, _isMuteMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('draft_content')) {
      context.handle(
        _draftContentMeta,
        draftContent.isAcceptableOrUnknown(
          data['draft_content']!,
          _draftContentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, targetType, targetId},
  ];
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      updateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_time'],
      )!,
      lastMessageContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_content'],
      ),
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_type'],
      ),
      lastMessageStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_status'],
      ),
      lastMessageTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_timestamp'],
      ),
      lastMessageFromId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_from_id'],
      ),
      lastMessageToId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_to_id'],
      ),
      lastMessageGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_group_id'],
      ),
      lastMessageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_local_path'],
      ),
      lastMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_msg_id'],
      ),
      isTop: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_top'],
      )!,
      isMute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_mute'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      draftContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_content'],
      ),
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final int id;
  final int userId;
  final int targetType;
  final int targetId;
  final int unreadCount;
  final int updateTime;
  final String? lastMessageContent;
  final int? lastMessageType;
  final int? lastMessageStatus;
  final int? lastMessageTimestamp;
  final int? lastMessageFromId;
  final int? lastMessageToId;
  final int? lastMessageGroupId;
  final String? lastMessageLocalPath;
  final int? lastMsgId;
  final int isTop;
  final int isMute;
  final int isDeleted;
  final String? draftContent;
  const Conversation({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.unreadCount,
    required this.updateTime,
    this.lastMessageContent,
    this.lastMessageType,
    this.lastMessageStatus,
    this.lastMessageTimestamp,
    this.lastMessageFromId,
    this.lastMessageToId,
    this.lastMessageGroupId,
    this.lastMessageLocalPath,
    this.lastMsgId,
    required this.isTop,
    required this.isMute,
    required this.isDeleted,
    this.draftContent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['target_type'] = Variable<int>(targetType);
    map['target_id'] = Variable<int>(targetId);
    map['unread_count'] = Variable<int>(unreadCount);
    map['update_time'] = Variable<int>(updateTime);
    if (!nullToAbsent || lastMessageContent != null) {
      map['last_message_content'] = Variable<String>(lastMessageContent);
    }
    if (!nullToAbsent || lastMessageType != null) {
      map['last_message_type'] = Variable<int>(lastMessageType);
    }
    if (!nullToAbsent || lastMessageStatus != null) {
      map['last_message_status'] = Variable<int>(lastMessageStatus);
    }
    if (!nullToAbsent || lastMessageTimestamp != null) {
      map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp);
    }
    if (!nullToAbsent || lastMessageFromId != null) {
      map['last_message_from_id'] = Variable<int>(lastMessageFromId);
    }
    if (!nullToAbsent || lastMessageToId != null) {
      map['last_message_to_id'] = Variable<int>(lastMessageToId);
    }
    if (!nullToAbsent || lastMessageGroupId != null) {
      map['last_message_group_id'] = Variable<int>(lastMessageGroupId);
    }
    if (!nullToAbsent || lastMessageLocalPath != null) {
      map['last_message_local_path'] = Variable<String>(lastMessageLocalPath);
    }
    if (!nullToAbsent || lastMsgId != null) {
      map['last_msg_id'] = Variable<int>(lastMsgId);
    }
    map['is_top'] = Variable<int>(isTop);
    map['is_mute'] = Variable<int>(isMute);
    map['is_deleted'] = Variable<int>(isDeleted);
    if (!nullToAbsent || draftContent != null) {
      map['draft_content'] = Variable<String>(draftContent);
    }
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      userId: Value(userId),
      targetType: Value(targetType),
      targetId: Value(targetId),
      unreadCount: Value(unreadCount),
      updateTime: Value(updateTime),
      lastMessageContent: lastMessageContent == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageContent),
      lastMessageType: lastMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageType),
      lastMessageStatus: lastMessageStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageStatus),
      lastMessageTimestamp: lastMessageTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageTimestamp),
      lastMessageFromId: lastMessageFromId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageFromId),
      lastMessageToId: lastMessageToId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageToId),
      lastMessageGroupId: lastMessageGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageGroupId),
      lastMessageLocalPath: lastMessageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageLocalPath),
      lastMsgId: lastMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgId),
      isTop: Value(isTop),
      isMute: Value(isMute),
      isDeleted: Value(isDeleted),
      draftContent: draftContent == null && nullToAbsent
          ? const Value.absent()
          : Value(draftContent),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      targetType: serializer.fromJson<int>(json['targetType']),
      targetId: serializer.fromJson<int>(json['targetId']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      updateTime: serializer.fromJson<int>(json['updateTime']),
      lastMessageContent: serializer.fromJson<String?>(
        json['lastMessageContent'],
      ),
      lastMessageType: serializer.fromJson<int?>(json['lastMessageType']),
      lastMessageStatus: serializer.fromJson<int?>(json['lastMessageStatus']),
      lastMessageTimestamp: serializer.fromJson<int?>(
        json['lastMessageTimestamp'],
      ),
      lastMessageFromId: serializer.fromJson<int?>(json['lastMessageFromId']),
      lastMessageToId: serializer.fromJson<int?>(json['lastMessageToId']),
      lastMessageGroupId: serializer.fromJson<int?>(json['lastMessageGroupId']),
      lastMessageLocalPath: serializer.fromJson<String?>(
        json['lastMessageLocalPath'],
      ),
      lastMsgId: serializer.fromJson<int?>(json['lastMsgId']),
      isTop: serializer.fromJson<int>(json['isTop']),
      isMute: serializer.fromJson<int>(json['isMute']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      draftContent: serializer.fromJson<String?>(json['draftContent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'targetType': serializer.toJson<int>(targetType),
      'targetId': serializer.toJson<int>(targetId),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'updateTime': serializer.toJson<int>(updateTime),
      'lastMessageContent': serializer.toJson<String?>(lastMessageContent),
      'lastMessageType': serializer.toJson<int?>(lastMessageType),
      'lastMessageStatus': serializer.toJson<int?>(lastMessageStatus),
      'lastMessageTimestamp': serializer.toJson<int?>(lastMessageTimestamp),
      'lastMessageFromId': serializer.toJson<int?>(lastMessageFromId),
      'lastMessageToId': serializer.toJson<int?>(lastMessageToId),
      'lastMessageGroupId': serializer.toJson<int?>(lastMessageGroupId),
      'lastMessageLocalPath': serializer.toJson<String?>(lastMessageLocalPath),
      'lastMsgId': serializer.toJson<int?>(lastMsgId),
      'isTop': serializer.toJson<int>(isTop),
      'isMute': serializer.toJson<int>(isMute),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'draftContent': serializer.toJson<String?>(draftContent),
    };
  }

  Conversation copyWith({
    int? id,
    int? userId,
    int? targetType,
    int? targetId,
    int? unreadCount,
    int? updateTime,
    Value<String?> lastMessageContent = const Value.absent(),
    Value<int?> lastMessageType = const Value.absent(),
    Value<int?> lastMessageStatus = const Value.absent(),
    Value<int?> lastMessageTimestamp = const Value.absent(),
    Value<int?> lastMessageFromId = const Value.absent(),
    Value<int?> lastMessageToId = const Value.absent(),
    Value<int?> lastMessageGroupId = const Value.absent(),
    Value<String?> lastMessageLocalPath = const Value.absent(),
    Value<int?> lastMsgId = const Value.absent(),
    int? isTop,
    int? isMute,
    int? isDeleted,
    Value<String?> draftContent = const Value.absent(),
  }) => Conversation(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    unreadCount: unreadCount ?? this.unreadCount,
    updateTime: updateTime ?? this.updateTime,
    lastMessageContent: lastMessageContent.present
        ? lastMessageContent.value
        : this.lastMessageContent,
    lastMessageType: lastMessageType.present
        ? lastMessageType.value
        : this.lastMessageType,
    lastMessageStatus: lastMessageStatus.present
        ? lastMessageStatus.value
        : this.lastMessageStatus,
    lastMessageTimestamp: lastMessageTimestamp.present
        ? lastMessageTimestamp.value
        : this.lastMessageTimestamp,
    lastMessageFromId: lastMessageFromId.present
        ? lastMessageFromId.value
        : this.lastMessageFromId,
    lastMessageToId: lastMessageToId.present
        ? lastMessageToId.value
        : this.lastMessageToId,
    lastMessageGroupId: lastMessageGroupId.present
        ? lastMessageGroupId.value
        : this.lastMessageGroupId,
    lastMessageLocalPath: lastMessageLocalPath.present
        ? lastMessageLocalPath.value
        : this.lastMessageLocalPath,
    lastMsgId: lastMsgId.present ? lastMsgId.value : this.lastMsgId,
    isTop: isTop ?? this.isTop,
    isMute: isMute ?? this.isMute,
    isDeleted: isDeleted ?? this.isDeleted,
    draftContent: draftContent.present ? draftContent.value : this.draftContent,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
      lastMessageContent: data.lastMessageContent.present
          ? data.lastMessageContent.value
          : this.lastMessageContent,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageStatus: data.lastMessageStatus.present
          ? data.lastMessageStatus.value
          : this.lastMessageStatus,
      lastMessageTimestamp: data.lastMessageTimestamp.present
          ? data.lastMessageTimestamp.value
          : this.lastMessageTimestamp,
      lastMessageFromId: data.lastMessageFromId.present
          ? data.lastMessageFromId.value
          : this.lastMessageFromId,
      lastMessageToId: data.lastMessageToId.present
          ? data.lastMessageToId.value
          : this.lastMessageToId,
      lastMessageGroupId: data.lastMessageGroupId.present
          ? data.lastMessageGroupId.value
          : this.lastMessageGroupId,
      lastMessageLocalPath: data.lastMessageLocalPath.present
          ? data.lastMessageLocalPath.value
          : this.lastMessageLocalPath,
      lastMsgId: data.lastMsgId.present ? data.lastMsgId.value : this.lastMsgId,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      isMute: data.isMute.present ? data.isMute.value : this.isMute,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      draftContent: data.draftContent.present
          ? data.draftContent.value
          : this.draftContent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updateTime: $updateTime, ')
          ..write('lastMessageContent: $lastMessageContent, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageStatus: $lastMessageStatus, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('lastMessageFromId: $lastMessageFromId, ')
          ..write('lastMessageToId: $lastMessageToId, ')
          ..write('lastMessageGroupId: $lastMessageGroupId, ')
          ..write('lastMessageLocalPath: $lastMessageLocalPath, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('isTop: $isTop, ')
          ..write('isMute: $isMute, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('draftContent: $draftContent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    targetType,
    targetId,
    unreadCount,
    updateTime,
    lastMessageContent,
    lastMessageType,
    lastMessageStatus,
    lastMessageTimestamp,
    lastMessageFromId,
    lastMessageToId,
    lastMessageGroupId,
    lastMessageLocalPath,
    lastMsgId,
    isTop,
    isMute,
    isDeleted,
    draftContent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.unreadCount == this.unreadCount &&
          other.updateTime == this.updateTime &&
          other.lastMessageContent == this.lastMessageContent &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageStatus == this.lastMessageStatus &&
          other.lastMessageTimestamp == this.lastMessageTimestamp &&
          other.lastMessageFromId == this.lastMessageFromId &&
          other.lastMessageToId == this.lastMessageToId &&
          other.lastMessageGroupId == this.lastMessageGroupId &&
          other.lastMessageLocalPath == this.lastMessageLocalPath &&
          other.lastMsgId == this.lastMsgId &&
          other.isTop == this.isTop &&
          other.isMute == this.isMute &&
          other.isDeleted == this.isDeleted &&
          other.draftContent == this.draftContent);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> targetType;
  final Value<int> targetId;
  final Value<int> unreadCount;
  final Value<int> updateTime;
  final Value<String?> lastMessageContent;
  final Value<int?> lastMessageType;
  final Value<int?> lastMessageStatus;
  final Value<int?> lastMessageTimestamp;
  final Value<int?> lastMessageFromId;
  final Value<int?> lastMessageToId;
  final Value<int?> lastMessageGroupId;
  final Value<String?> lastMessageLocalPath;
  final Value<int?> lastMsgId;
  final Value<int> isTop;
  final Value<int> isMute;
  final Value<int> isDeleted;
  final Value<String?> draftContent;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.lastMessageContent = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageStatus = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.lastMessageFromId = const Value.absent(),
    this.lastMessageToId = const Value.absent(),
    this.lastMessageGroupId = const Value.absent(),
    this.lastMessageLocalPath = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.isTop = const Value.absent(),
    this.isMute = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.draftContent = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int targetType,
    required int targetId,
    this.unreadCount = const Value.absent(),
    required int updateTime,
    this.lastMessageContent = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageStatus = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.lastMessageFromId = const Value.absent(),
    this.lastMessageToId = const Value.absent(),
    this.lastMessageGroupId = const Value.absent(),
    this.lastMessageLocalPath = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.isTop = const Value.absent(),
    this.isMute = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.draftContent = const Value.absent(),
  }) : userId = Value(userId),
       targetType = Value(targetType),
       targetId = Value(targetId),
       updateTime = Value(updateTime);
  static Insertable<Conversation> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? targetType,
    Expression<int>? targetId,
    Expression<int>? unreadCount,
    Expression<int>? updateTime,
    Expression<String>? lastMessageContent,
    Expression<int>? lastMessageType,
    Expression<int>? lastMessageStatus,
    Expression<int>? lastMessageTimestamp,
    Expression<int>? lastMessageFromId,
    Expression<int>? lastMessageToId,
    Expression<int>? lastMessageGroupId,
    Expression<String>? lastMessageLocalPath,
    Expression<int>? lastMsgId,
    Expression<int>? isTop,
    Expression<int>? isMute,
    Expression<int>? isDeleted,
    Expression<String>? draftContent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (updateTime != null) 'update_time': updateTime,
      if (lastMessageContent != null)
        'last_message_content': lastMessageContent,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageStatus != null) 'last_message_status': lastMessageStatus,
      if (lastMessageTimestamp != null)
        'last_message_timestamp': lastMessageTimestamp,
      if (lastMessageFromId != null) 'last_message_from_id': lastMessageFromId,
      if (lastMessageToId != null) 'last_message_to_id': lastMessageToId,
      if (lastMessageGroupId != null)
        'last_message_group_id': lastMessageGroupId,
      if (lastMessageLocalPath != null)
        'last_message_local_path': lastMessageLocalPath,
      if (lastMsgId != null) 'last_msg_id': lastMsgId,
      if (isTop != null) 'is_top': isTop,
      if (isMute != null) 'is_mute': isMute,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (draftContent != null) 'draft_content': draftContent,
    });
  }

  ConversationsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? targetType,
    Value<int>? targetId,
    Value<int>? unreadCount,
    Value<int>? updateTime,
    Value<String?>? lastMessageContent,
    Value<int?>? lastMessageType,
    Value<int?>? lastMessageStatus,
    Value<int?>? lastMessageTimestamp,
    Value<int?>? lastMessageFromId,
    Value<int?>? lastMessageToId,
    Value<int?>? lastMessageGroupId,
    Value<String?>? lastMessageLocalPath,
    Value<int?>? lastMsgId,
    Value<int>? isTop,
    Value<int>? isMute,
    Value<int>? isDeleted,
    Value<String?>? draftContent,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      unreadCount: unreadCount ?? this.unreadCount,
      updateTime: updateTime ?? this.updateTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageFromId: lastMessageFromId ?? this.lastMessageFromId,
      lastMessageToId: lastMessageToId ?? this.lastMessageToId,
      lastMessageGroupId: lastMessageGroupId ?? this.lastMessageGroupId,
      lastMessageLocalPath: lastMessageLocalPath ?? this.lastMessageLocalPath,
      lastMsgId: lastMsgId ?? this.lastMsgId,
      isTop: isTop ?? this.isTop,
      isMute: isMute ?? this.isMute,
      isDeleted: isDeleted ?? this.isDeleted,
      draftContent: draftContent ?? this.draftContent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<int>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (updateTime.present) {
      map['update_time'] = Variable<int>(updateTime.value);
    }
    if (lastMessageContent.present) {
      map['last_message_content'] = Variable<String>(lastMessageContent.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<int>(lastMessageType.value);
    }
    if (lastMessageStatus.present) {
      map['last_message_status'] = Variable<int>(lastMessageStatus.value);
    }
    if (lastMessageTimestamp.present) {
      map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp.value);
    }
    if (lastMessageFromId.present) {
      map['last_message_from_id'] = Variable<int>(lastMessageFromId.value);
    }
    if (lastMessageToId.present) {
      map['last_message_to_id'] = Variable<int>(lastMessageToId.value);
    }
    if (lastMessageGroupId.present) {
      map['last_message_group_id'] = Variable<int>(lastMessageGroupId.value);
    }
    if (lastMessageLocalPath.present) {
      map['last_message_local_path'] = Variable<String>(
        lastMessageLocalPath.value,
      );
    }
    if (lastMsgId.present) {
      map['last_msg_id'] = Variable<int>(lastMsgId.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<int>(isTop.value);
    }
    if (isMute.present) {
      map['is_mute'] = Variable<int>(isMute.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (draftContent.present) {
      map['draft_content'] = Variable<String>(draftContent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updateTime: $updateTime, ')
          ..write('lastMessageContent: $lastMessageContent, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageStatus: $lastMessageStatus, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('lastMessageFromId: $lastMessageFromId, ')
          ..write('lastMessageToId: $lastMessageToId, ')
          ..write('lastMessageGroupId: $lastMessageGroupId, ')
          ..write('lastMessageLocalPath: $lastMessageLocalPath, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('isTop: $isTop, ')
          ..write('isMute: $isMute, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('draftContent: $draftContent')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<int> gender = GeneratedColumn<int>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _onlineStatusMeta = const VerificationMeta(
    'onlineStatus',
  );
  @override
  late final GeneratedColumn<int> onlineStatus = GeneratedColumn<int>(
    'online_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOnlineTimeMeta = const VerificationMeta(
    'lastOnlineTime',
  );
  @override
  late final GeneratedColumn<int> lastOnlineTime = GeneratedColumn<int>(
    'last_online_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<int> createTime = GeneratedColumn<int>(
    'create_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    nickname,
    avatar,
    signature,
    gender,
    location,
    onlineStatus,
    lastOnlineTime,
    remark,
    status,
    source,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('online_status')) {
      context.handle(
        _onlineStatusMeta,
        onlineStatus.isAcceptableOrUnknown(
          data['online_status']!,
          _onlineStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_online_time')) {
      context.handle(
        _lastOnlineTimeMeta,
        lastOnlineTime.isAcceptableOrUnknown(
          data['last_online_time']!,
          _lastOnlineTimeMeta,
        ),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_createTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gender'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      onlineStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}online_status'],
      )!,
      lastOnlineTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_online_time'],
      ),
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_time'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final String? signature;
  final int gender;
  final String location;
  final int onlineStatus;
  final int? lastOnlineTime;
  final String remark;
  final int status;
  final int source;
  final int createTime;
  const Contact({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    this.signature,
    required this.gender,
    required this.location,
    required this.onlineStatus,
    this.lastOnlineTime,
    required this.remark,
    required this.status,
    required this.source,
    required this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['nickname'] = Variable<String>(nickname);
    map['avatar'] = Variable<String>(avatar);
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    map['gender'] = Variable<int>(gender);
    map['location'] = Variable<String>(location);
    map['online_status'] = Variable<int>(onlineStatus);
    if (!nullToAbsent || lastOnlineTime != null) {
      map['last_online_time'] = Variable<int>(lastOnlineTime);
    }
    map['remark'] = Variable<String>(remark);
    map['status'] = Variable<int>(status);
    map['source'] = Variable<int>(source);
    map['create_time'] = Variable<int>(createTime);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      username: Value(username),
      nickname: Value(nickname),
      avatar: Value(avatar),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
      gender: Value(gender),
      location: Value(location),
      onlineStatus: Value(onlineStatus),
      lastOnlineTime: lastOnlineTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOnlineTime),
      remark: Value(remark),
      status: Value(status),
      source: Value(source),
      createTime: Value(createTime),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatar: serializer.fromJson<String>(json['avatar']),
      signature: serializer.fromJson<String?>(json['signature']),
      gender: serializer.fromJson<int>(json['gender']),
      location: serializer.fromJson<String>(json['location']),
      onlineStatus: serializer.fromJson<int>(json['onlineStatus']),
      lastOnlineTime: serializer.fromJson<int?>(json['lastOnlineTime']),
      remark: serializer.fromJson<String>(json['remark']),
      status: serializer.fromJson<int>(json['status']),
      source: serializer.fromJson<int>(json['source']),
      createTime: serializer.fromJson<int>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'nickname': serializer.toJson<String>(nickname),
      'avatar': serializer.toJson<String>(avatar),
      'signature': serializer.toJson<String?>(signature),
      'gender': serializer.toJson<int>(gender),
      'location': serializer.toJson<String>(location),
      'onlineStatus': serializer.toJson<int>(onlineStatus),
      'lastOnlineTime': serializer.toJson<int?>(lastOnlineTime),
      'remark': serializer.toJson<String>(remark),
      'status': serializer.toJson<int>(status),
      'source': serializer.toJson<int>(source),
      'createTime': serializer.toJson<int>(createTime),
    };
  }

  Contact copyWith({
    int? id,
    String? username,
    String? nickname,
    String? avatar,
    Value<String?> signature = const Value.absent(),
    int? gender,
    String? location,
    int? onlineStatus,
    Value<int?> lastOnlineTime = const Value.absent(),
    String? remark,
    int? status,
    int? source,
    int? createTime,
  }) => Contact(
    id: id ?? this.id,
    username: username ?? this.username,
    nickname: nickname ?? this.nickname,
    avatar: avatar ?? this.avatar,
    signature: signature.present ? signature.value : this.signature,
    gender: gender ?? this.gender,
    location: location ?? this.location,
    onlineStatus: onlineStatus ?? this.onlineStatus,
    lastOnlineTime: lastOnlineTime.present
        ? lastOnlineTime.value
        : this.lastOnlineTime,
    remark: remark ?? this.remark,
    status: status ?? this.status,
    source: source ?? this.source,
    createTime: createTime ?? this.createTime,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      signature: data.signature.present ? data.signature.value : this.signature,
      gender: data.gender.present ? data.gender.value : this.gender,
      location: data.location.present ? data.location.value : this.location,
      onlineStatus: data.onlineStatus.present
          ? data.onlineStatus.value
          : this.onlineStatus,
      lastOnlineTime: data.lastOnlineTime.present
          ? data.lastOnlineTime.value
          : this.lastOnlineTime,
      remark: data.remark.present ? data.remark.value : this.remark,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('signature: $signature, ')
          ..write('gender: $gender, ')
          ..write('location: $location, ')
          ..write('onlineStatus: $onlineStatus, ')
          ..write('lastOnlineTime: $lastOnlineTime, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    nickname,
    avatar,
    signature,
    gender,
    location,
    onlineStatus,
    lastOnlineTime,
    remark,
    status,
    source,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.username == this.username &&
          other.nickname == this.nickname &&
          other.avatar == this.avatar &&
          other.signature == this.signature &&
          other.gender == this.gender &&
          other.location == this.location &&
          other.onlineStatus == this.onlineStatus &&
          other.lastOnlineTime == this.lastOnlineTime &&
          other.remark == this.remark &&
          other.status == this.status &&
          other.source == this.source &&
          other.createTime == this.createTime);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> nickname;
  final Value<String> avatar;
  final Value<String?> signature;
  final Value<int> gender;
  final Value<String> location;
  final Value<int> onlineStatus;
  final Value<int?> lastOnlineTime;
  final Value<String> remark;
  final Value<int> status;
  final Value<int> source;
  final Value<int> createTime;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.signature = const Value.absent(),
    this.gender = const Value.absent(),
    this.location = const Value.absent(),
    this.onlineStatus = const Value.absent(),
    this.lastOnlineTime = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.signature = const Value.absent(),
    this.gender = const Value.absent(),
    this.location = const Value.absent(),
    this.onlineStatus = const Value.absent(),
    this.lastOnlineTime = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    required int createTime,
  }) : username = Value(username),
       createTime = Value(createTime);
  static Insertable<Contact> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? nickname,
    Expression<String>? avatar,
    Expression<String>? signature,
    Expression<int>? gender,
    Expression<String>? location,
    Expression<int>? onlineStatus,
    Expression<int>? lastOnlineTime,
    Expression<String>? remark,
    Expression<int>? status,
    Expression<int>? source,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (signature != null) 'signature': signature,
      if (gender != null) 'gender': gender,
      if (location != null) 'location': location,
      if (onlineStatus != null) 'online_status': onlineStatus,
      if (lastOnlineTime != null) 'last_online_time': lastOnlineTime,
      if (remark != null) 'remark': remark,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (createTime != null) 'create_time': createTime,
    });
  }

  ContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? nickname,
    Value<String>? avatar,
    Value<String?>? signature,
    Value<int>? gender,
    Value<String>? location,
    Value<int>? onlineStatus,
    Value<int?>? lastOnlineTime,
    Value<String>? remark,
    Value<int>? status,
    Value<int>? source,
    Value<int>? createTime,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      signature: signature ?? this.signature,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastOnlineTime: lastOnlineTime ?? this.lastOnlineTime,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      source: source ?? this.source,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (gender.present) {
      map['gender'] = Variable<int>(gender.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (onlineStatus.present) {
      map['online_status'] = Variable<int>(onlineStatus.value);
    }
    if (lastOnlineTime.present) {
      map['last_online_time'] = Variable<int>(lastOnlineTime.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(createTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('signature: $signature, ')
          ..write('gender: $gender, ')
          ..write('location: $location, ')
          ..write('onlineStatus: $onlineStatus, ')
          ..write('lastOnlineTime: $lastOnlineTime, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    conversations,
    contacts,
  ];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int?> mid,
      required int fromId,
      required int toId,
      Value<int?> groupId,
      required String content,
      required int msgType,
      required int status,
      required int timestamp,
      Value<String?> localPath,
      Value<int> msgSeq,
      Value<int?> replyMsgId,
      Value<String> atUserIds,
      Value<String?> extra,
      Value<int> readStatus,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int?> mid,
      Value<int> fromId,
      Value<int> toId,
      Value<int?> groupId,
      Value<String> content,
      Value<int> msgType,
      Value<int> status,
      Value<int> timestamp,
      Value<String?> localPath,
      Value<int> msgSeq,
      Value<int?> replyMsgId,
      Value<String> atUserIds,
      Value<String?> extra,
      Value<int> readStatus,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mid => $composableBuilder(
    column: $table.mid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgSeq => $composableBuilder(
    column: $table.msgSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyMsgId => $composableBuilder(
    column: $table.replyMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atUserIds => $composableBuilder(
    column: $table.atUserIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mid => $composableBuilder(
    column: $table.mid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgSeq => $composableBuilder(
    column: $table.msgSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyMsgId => $composableBuilder(
    column: $table.replyMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atUserIds => $composableBuilder(
    column: $table.atUserIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mid =>
      $composableBuilder(column: $table.mid, builder: (column) => column);

  GeneratedColumn<int> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<int> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get msgType =>
      $composableBuilder(column: $table.msgType, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get msgSeq =>
      $composableBuilder(column: $table.msgSeq, builder: (column) => column);

  GeneratedColumn<int> get replyMsgId => $composableBuilder(
    column: $table.replyMsgId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get atUserIds =>
      $composableBuilder(column: $table.atUserIds, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<int> get readStatus => $composableBuilder(
    column: $table.readStatus,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> mid = const Value.absent(),
                Value<int> fromId = const Value.absent(),
                Value<int> toId = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> msgType = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<int> msgSeq = const Value.absent(),
                Value<int?> replyMsgId = const Value.absent(),
                Value<String> atUserIds = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<int> readStatus = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                mid: mid,
                fromId: fromId,
                toId: toId,
                groupId: groupId,
                content: content,
                msgType: msgType,
                status: status,
                timestamp: timestamp,
                localPath: localPath,
                msgSeq: msgSeq,
                replyMsgId: replyMsgId,
                atUserIds: atUserIds,
                extra: extra,
                readStatus: readStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> mid = const Value.absent(),
                required int fromId,
                required int toId,
                Value<int?> groupId = const Value.absent(),
                required String content,
                required int msgType,
                required int status,
                required int timestamp,
                Value<String?> localPath = const Value.absent(),
                Value<int> msgSeq = const Value.absent(),
                Value<int?> replyMsgId = const Value.absent(),
                Value<String> atUserIds = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<int> readStatus = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                mid: mid,
                fromId: fromId,
                toId: toId,
                groupId: groupId,
                content: content,
                msgType: msgType,
                status: status,
                timestamp: timestamp,
                localPath: localPath,
                msgSeq: msgSeq,
                replyMsgId: replyMsgId,
                atUserIds: atUserIds,
                extra: extra,
                readStatus: readStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      required int userId,
      required int targetType,
      required int targetId,
      Value<int> unreadCount,
      required int updateTime,
      Value<String?> lastMessageContent,
      Value<int?> lastMessageType,
      Value<int?> lastMessageStatus,
      Value<int?> lastMessageTimestamp,
      Value<int?> lastMessageFromId,
      Value<int?> lastMessageToId,
      Value<int?> lastMessageGroupId,
      Value<String?> lastMessageLocalPath,
      Value<int?> lastMsgId,
      Value<int> isTop,
      Value<int> isMute,
      Value<int> isDeleted,
      Value<String?> draftContent,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> targetType,
      Value<int> targetId,
      Value<int> unreadCount,
      Value<int> updateTime,
      Value<String?> lastMessageContent,
      Value<int?> lastMessageType,
      Value<int?> lastMessageStatus,
      Value<int?> lastMessageTimestamp,
      Value<int?> lastMessageFromId,
      Value<int?> lastMessageToId,
      Value<int?> lastMessageGroupId,
      Value<String?> lastMessageLocalPath,
      Value<int?> lastMsgId,
      Value<int> isTop,
      Value<int> isMute,
      Value<int> isDeleted,
      Value<String?> draftContent,
    });

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageFromId => $composableBuilder(
    column: $table.lastMessageFromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageToId => $composableBuilder(
    column: $table.lastMessageToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageGroupId => $composableBuilder(
    column: $table.lastMessageGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageLocalPath => $composableBuilder(
    column: $table.lastMessageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isMute => $composableBuilder(
    column: $table.isMute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftContent => $composableBuilder(
    column: $table.draftContent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageFromId => $composableBuilder(
    column: $table.lastMessageFromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageToId => $composableBuilder(
    column: $table.lastMessageToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageGroupId => $composableBuilder(
    column: $table.lastMessageGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageLocalPath => $composableBuilder(
    column: $table.lastMessageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isMute => $composableBuilder(
    column: $table.isMute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftContent => $composableBuilder(
    column: $table.draftContent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageContent => $composableBuilder(
    column: $table.lastMessageContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageStatus => $composableBuilder(
    column: $table.lastMessageStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageFromId => $composableBuilder(
    column: $table.lastMessageFromId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageToId => $composableBuilder(
    column: $table.lastMessageToId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageGroupId => $composableBuilder(
    column: $table.lastMessageGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageLocalPath => $composableBuilder(
    column: $table.lastMessageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMsgId =>
      $composableBuilder(column: $table.lastMsgId, builder: (column) => column);

  GeneratedColumn<int> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<int> get isMute =>
      $composableBuilder(column: $table.isMute, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get draftContent => $composableBuilder(
    column: $table.draftContent,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (
            Conversation,
            BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
          ),
          Conversation,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> targetType = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> updateTime = const Value.absent(),
                Value<String?> lastMessageContent = const Value.absent(),
                Value<int?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageStatus = const Value.absent(),
                Value<int?> lastMessageTimestamp = const Value.absent(),
                Value<int?> lastMessageFromId = const Value.absent(),
                Value<int?> lastMessageToId = const Value.absent(),
                Value<int?> lastMessageGroupId = const Value.absent(),
                Value<String?> lastMessageLocalPath = const Value.absent(),
                Value<int?> lastMsgId = const Value.absent(),
                Value<int> isTop = const Value.absent(),
                Value<int> isMute = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<String?> draftContent = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                userId: userId,
                targetType: targetType,
                targetId: targetId,
                unreadCount: unreadCount,
                updateTime: updateTime,
                lastMessageContent: lastMessageContent,
                lastMessageType: lastMessageType,
                lastMessageStatus: lastMessageStatus,
                lastMessageTimestamp: lastMessageTimestamp,
                lastMessageFromId: lastMessageFromId,
                lastMessageToId: lastMessageToId,
                lastMessageGroupId: lastMessageGroupId,
                lastMessageLocalPath: lastMessageLocalPath,
                lastMsgId: lastMsgId,
                isTop: isTop,
                isMute: isMute,
                isDeleted: isDeleted,
                draftContent: draftContent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int targetType,
                required int targetId,
                Value<int> unreadCount = const Value.absent(),
                required int updateTime,
                Value<String?> lastMessageContent = const Value.absent(),
                Value<int?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageStatus = const Value.absent(),
                Value<int?> lastMessageTimestamp = const Value.absent(),
                Value<int?> lastMessageFromId = const Value.absent(),
                Value<int?> lastMessageToId = const Value.absent(),
                Value<int?> lastMessageGroupId = const Value.absent(),
                Value<String?> lastMessageLocalPath = const Value.absent(),
                Value<int?> lastMsgId = const Value.absent(),
                Value<int> isTop = const Value.absent(),
                Value<int> isMute = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<String?> draftContent = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                userId: userId,
                targetType: targetType,
                targetId: targetId,
                unreadCount: unreadCount,
                updateTime: updateTime,
                lastMessageContent: lastMessageContent,
                lastMessageType: lastMessageType,
                lastMessageStatus: lastMessageStatus,
                lastMessageTimestamp: lastMessageTimestamp,
                lastMessageFromId: lastMessageFromId,
                lastMessageToId: lastMessageToId,
                lastMessageGroupId: lastMessageGroupId,
                lastMessageLocalPath: lastMessageLocalPath,
                lastMsgId: lastMsgId,
                isTop: isTop,
                isMute: isMute,
                isDeleted: isDeleted,
                draftContent: draftContent,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (
        Conversation,
        BaseReferences<_$AppDatabase, $ConversationsTable, Conversation>,
      ),
      Conversation,
      PrefetchHooks Function()
    >;
typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      required String username,
      Value<String> nickname,
      Value<String> avatar,
      Value<String?> signature,
      Value<int> gender,
      Value<String> location,
      Value<int> onlineStatus,
      Value<int?> lastOnlineTime,
      Value<String> remark,
      Value<int> status,
      Value<int> source,
      required int createTime,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> nickname,
      Value<String> avatar,
      Value<String?> signature,
      Value<int> gender,
      Value<String> location,
      Value<int> onlineStatus,
      Value<int?> lastOnlineTime,
      Value<String> remark,
      Value<int> status,
      Value<int> source,
      Value<int> createTime,
    });

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOnlineTime => $composableBuilder(
    column: $table.lastOnlineTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOnlineTime => $composableBuilder(
    column: $table.lastOnlineTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<int> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get onlineStatus => $composableBuilder(
    column: $table.onlineStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastOnlineTime => $composableBuilder(
    column: $table.lastOnlineTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
          Contact,
          PrefetchHooks Function()
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<int> gender = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<int> onlineStatus = const Value.absent(),
                Value<int?> lastOnlineTime = const Value.absent(),
                Value<String> remark = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<int> createTime = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                username: username,
                nickname: nickname,
                avatar: avatar,
                signature: signature,
                gender: gender,
                location: location,
                onlineStatus: onlineStatus,
                lastOnlineTime: lastOnlineTime,
                remark: remark,
                status: status,
                source: source,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                Value<String> nickname = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<int> gender = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<int> onlineStatus = const Value.absent(),
                Value<int?> lastOnlineTime = const Value.absent(),
                Value<String> remark = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> source = const Value.absent(),
                required int createTime,
              }) => ContactsCompanion.insert(
                id: id,
                username: username,
                nickname: nickname,
                avatar: avatar,
                signature: signature,
                gender: gender,
                location: location,
                onlineStatus: onlineStatus,
                lastOnlineTime: lastOnlineTime,
                remark: remark,
                status: status,
                source: source,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, BaseReferences<_$AppDatabase, $ContactsTable, Contact>),
      Contact,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
}
