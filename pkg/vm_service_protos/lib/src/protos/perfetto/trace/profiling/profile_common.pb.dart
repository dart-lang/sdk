// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/profiling/profile_common.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// The interning fields in this file can refer to 2 different intern tables,
/// depending on the message they are used in. If the interned fields are present
/// in ProfilePacket proto, then the intern tables included in the ProfilePacket
/// should be used. If the intered fields are present in the
/// StreamingProfilePacket proto, then the intern tables included in all of the
/// previous InternedData message with same sequence ID should be used.
class InternedString extends $pb.GeneratedMessage {
  factory InternedString({
    $fixnum.Int64? iid,
    $core.List<$core.int>? str,
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (str != null) {
      $result.str = str;
    }
    return $result;
  }
  InternedString._() : super();
  factory InternedString.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InternedString.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InternedString',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'str', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InternedString clone() => InternedString()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InternedString copyWith(void Function(InternedString) updates) =>
      super.copyWith((message) => updates(message as InternedString))
          as InternedString;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InternedString create() => InternedString._();
  InternedString createEmptyInstance() => create();
  static $pb.PbList<InternedString> createRepeated() =>
      $pb.PbList<InternedString>();
  @$core.pragma('dart2js:noInline')
  static InternedString getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InternedString>(create);
  static InternedString? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get str => $_getN(1);
  @$pb.TagNumber(2)
  set str($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStr() => $_has(1);
  @$pb.TagNumber(2)
  void clearStr() => $_clearField(2);
}

class Mapping extends $pb.GeneratedMessage {
  factory Mapping({
    $fixnum.Int64? iid,
    $core.Iterable<$fixnum.Int64>? pathStringIds,
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (pathStringIds != null) {
      $result.pathStringIds.addAll(pathStringIds);
    }
    return $result;
  }
  Mapping._() : super();
  factory Mapping.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Mapping.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mapping',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'pathStringIds', $pb.PbFieldType.PU6)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Mapping clone() => Mapping()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Mapping copyWith(void Function(Mapping) updates) =>
      super.copyWith((message) => updates(message as Mapping)) as Mapping;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Mapping create() => Mapping._();
  Mapping createEmptyInstance() => create();
  static $pb.PbList<Mapping> createRepeated() => $pb.PbList<Mapping>();
  @$core.pragma('dart2js:noInline')
  static Mapping getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Mapping>(create);
  static Mapping? _defaultInstance;

  /// Interning key.
  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// E.g. ["system", "lib64", "libc.so"]
  /// id of string.
  @$pb.TagNumber(7)
  $pb.PbList<$fixnum.Int64> get pathStringIds => $_getList(1);
}

class Frame extends $pb.GeneratedMessage {
  factory Frame({
    $fixnum.Int64? iid,
    $fixnum.Int64? functionNameId,
    $fixnum.Int64? mappingId,
    $fixnum.Int64? relPc,
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (functionNameId != null) {
      $result.functionNameId = functionNameId;
    }
    if (mappingId != null) {
      $result.mappingId = mappingId;
    }
    if (relPc != null) {
      $result.relPc = relPc;
    }
    return $result;
  }
  Frame._() : super();
  factory Frame.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Frame.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Frame',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'functionNameId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'mappingId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'relPc', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Frame clone() => Frame()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Frame copyWith(void Function(Frame) updates) =>
      super.copyWith((message) => updates(message as Frame)) as Frame;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Frame create() => Frame._();
  Frame createEmptyInstance() => create();
  static $pb.PbList<Frame> createRepeated() => $pb.PbList<Frame>();
  @$core.pragma('dart2js:noInline')
  static Frame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Frame>(create);
  static Frame? _defaultInstance;

  /// Interning key
  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// E.g. "fopen"
  /// id of string.
  @$pb.TagNumber(2)
  $fixnum.Int64 get functionNameId => $_getI64(1);
  @$pb.TagNumber(2)
  set functionNameId($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFunctionNameId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFunctionNameId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get mappingId => $_getI64(2);
  @$pb.TagNumber(3)
  set mappingId($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMappingId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMappingId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get relPc => $_getI64(3);
  @$pb.TagNumber(4)
  set relPc($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRelPc() => $_has(3);
  @$pb.TagNumber(4)
  void clearRelPc() => $_clearField(4);
}

class Callstack extends $pb.GeneratedMessage {
  factory Callstack({
    $fixnum.Int64? iid,
    $core.Iterable<$fixnum.Int64>? frameIds,
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (frameIds != null) {
      $result.frameIds.addAll(frameIds);
    }
    return $result;
  }
  Callstack._() : super();
  factory Callstack.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Callstack.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Callstack',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'frameIds', $pb.PbFieldType.PU6)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Callstack clone() => Callstack()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Callstack copyWith(void Function(Callstack) updates) =>
      super.copyWith((message) => updates(message as Callstack)) as Callstack;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Callstack create() => Callstack._();
  Callstack createEmptyInstance() => create();
  static $pb.PbList<Callstack> createRepeated() => $pb.PbList<Callstack>();
  @$core.pragma('dart2js:noInline')
  static Callstack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Callstack>(create);
  static Callstack? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// Frames of this callstack. Bottom frame first.
  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get frameIds => $_getList(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
