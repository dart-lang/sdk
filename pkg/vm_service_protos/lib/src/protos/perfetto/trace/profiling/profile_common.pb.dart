// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/profiling/profile_common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

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
    final result = create();
    if (iid != null) result.iid = iid;
    if (str != null) result.str = str;
    return result;
  }

  InternedString._();

  factory InternedString.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InternedString.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InternedString clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InternedString copyWith(void Function(InternedString) updates) =>
      super.copyWith((message) => updates(message as InternedString))
          as InternedString;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InternedString create() => InternedString._();
  @$core.override
  InternedString createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InternedString getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InternedString>(create);
  static InternedString? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get str => $_getN(1);
  @$pb.TagNumber(2)
  set str($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStr() => $_has(1);
  @$pb.TagNumber(2)
  void clearStr() => $_clearField(2);
}

/// Source line info.
class Line extends $pb.GeneratedMessage {
  factory Line({
    $core.String? functionName,
    $core.String? sourceFileName,
    $core.int? lineNumber,
  }) {
    final result = create();
    if (functionName != null) result.functionName = functionName;
    if (sourceFileName != null) result.sourceFileName = sourceFileName;
    if (lineNumber != null) result.lineNumber = lineNumber;
    return result;
  }

  Line._();

  factory Line.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Line.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Line',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'functionName')
    ..aOS(2, _omitFieldNames ? '' : 'sourceFileName')
    ..aI(3, _omitFieldNames ? '' : 'lineNumber', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Line clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Line copyWith(void Function(Line) updates) =>
      super.copyWith((message) => updates(message as Line)) as Line;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Line create() => Line._();
  @$core.override
  Line createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Line getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Line>(create);
  static Line? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get functionName => $_getSZ(0);
  @$pb.TagNumber(1)
  set functionName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFunctionName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sourceFileName => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceFileName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceFileName() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceFileName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get lineNumber => $_getIZ(2);
  @$pb.TagNumber(3)
  set lineNumber($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLineNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearLineNumber() => $_clearField(3);
}

/// Symbols for a given address in a module.
class AddressSymbols extends $pb.GeneratedMessage {
  factory AddressSymbols({
    $fixnum.Int64? address,
    $core.Iterable<Line>? lines,
  }) {
    final result = create();
    if (address != null) result.address = address;
    if (lines != null) result.lines.addAll(lines);
    return result;
  }

  AddressSymbols._();

  factory AddressSymbols.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddressSymbols.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddressSymbols',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'address', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<Line>(2, _omitFieldNames ? '' : 'lines', subBuilder: Line.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddressSymbols clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddressSymbols copyWith(void Function(AddressSymbols) updates) =>
      super.copyWith((message) => updates(message as AddressSymbols))
          as AddressSymbols;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddressSymbols create() => AddressSymbols._();
  @$core.override
  AddressSymbols createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddressSymbols getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddressSymbols>(create);
  static AddressSymbols? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get address => $_getI64(0);
  @$pb.TagNumber(1)
  set address($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => $_clearField(1);

  /// Source lines that correspond to this address.
  ///
  /// These are repeated because when inlining happens, multiple functions'
  /// frames can be at a single address. Imagine function Foo calling the
  /// `std::vector<int>` constructor, which gets inlined at 0xf00. We then get
  /// both Foo and the `std::vector<int>` constructor when we symbolize the
  /// address.
  @$pb.TagNumber(2)
  $pb.PbList<Line> get lines => $_getList(1);
}

/// Symbols for addresses seen in a module.
/// Used in re-symbolisation of complete traces.
class ModuleSymbols extends $pb.GeneratedMessage {
  factory ModuleSymbols({
    $core.String? path,
    $core.String? buildId,
    $core.Iterable<AddressSymbols>? addressSymbols,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (buildId != null) result.buildId = buildId;
    if (addressSymbols != null) result.addressSymbols.addAll(addressSymbols);
    return result;
  }

  ModuleSymbols._();

  factory ModuleSymbols.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModuleSymbols.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModuleSymbols',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'buildId')
    ..pPM<AddressSymbols>(3, _omitFieldNames ? '' : 'addressSymbols',
        subBuilder: AddressSymbols.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleSymbols clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModuleSymbols copyWith(void Function(ModuleSymbols) updates) =>
      super.copyWith((message) => updates(message as ModuleSymbols))
          as ModuleSymbols;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModuleSymbols create() => ModuleSymbols._();
  @$core.override
  ModuleSymbols createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModuleSymbols getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModuleSymbols>(create);
  static ModuleSymbols? _defaultInstance;

  /// Fully qualified path to the mapping.
  /// E.g. /system/lib64/libc.so.
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// .note.gnu.build-id on Linux (not hex encoded).
  /// uuid on MacOS.
  /// Module GUID on Windows.
  @$pb.TagNumber(2)
  $core.String get buildId => $_getSZ(1);
  @$pb.TagNumber(2)
  set buildId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<AddressSymbols> get addressSymbols => $_getList(2);
}

class Mapping extends $pb.GeneratedMessage {
  factory Mapping({
    $fixnum.Int64? iid,
    $fixnum.Int64? buildId,
    $fixnum.Int64? startOffset,
    $fixnum.Int64? start,
    $fixnum.Int64? end,
    $core.Iterable<$fixnum.Int64>? pathStringIds,
  }) {
    final result = create();
    if (iid != null) result.iid = iid;
    if (buildId != null) result.buildId = buildId;
    if (startOffset != null) result.startOffset = startOffset;
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    if (pathStringIds != null) result.pathStringIds.addAll(pathStringIds);
    return result;
  }

  Mapping._();

  factory Mapping.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Mapping.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Mapping',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'buildId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'startOffset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'start', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'end', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'pathStringIds', $pb.PbFieldType.PU6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapping clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Mapping copyWith(void Function(Mapping) updates) =>
      super.copyWith((message) => updates(message as Mapping)) as Mapping;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Mapping create() => Mapping._();
  @$core.override
  Mapping createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Mapping getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Mapping>(create);
  static Mapping? _defaultInstance;

  /// Interning key.
  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// Interning key.
  /// Starts from 1, 0 is the same as "not set".
  @$pb.TagNumber(2)
  $fixnum.Int64 get buildId => $_getI64(1);
  @$pb.TagNumber(2)
  set buildId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get startOffset => $_getI64(2);
  @$pb.TagNumber(3)
  set startOffset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartOffset() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get start => $_getI64(3);
  @$pb.TagNumber(4)
  set start($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStart() => $_has(3);
  @$pb.TagNumber(4)
  void clearStart() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get end => $_getI64(4);
  @$pb.TagNumber(5)
  set end($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnd() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnd() => $_clearField(5);

  /// E.g. ["system", "lib64", "libc.so"]
  /// id of string.
  @$pb.TagNumber(7)
  $pb.PbList<$fixnum.Int64> get pathStringIds => $_getList(5);
}

class Frame extends $pb.GeneratedMessage {
  factory Frame({
    $fixnum.Int64? iid,
    $fixnum.Int64? functionNameId,
    $fixnum.Int64? mappingId,
    $fixnum.Int64? relPc,
  }) {
    final result = create();
    if (iid != null) result.iid = iid;
    if (functionNameId != null) result.functionNameId = functionNameId;
    if (mappingId != null) result.mappingId = mappingId;
    if (relPc != null) result.relPc = relPc;
    return result;
  }

  Frame._();

  factory Frame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Frame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Frame copyWith(void Function(Frame) updates) =>
      super.copyWith((message) => updates(message as Frame)) as Frame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Frame create() => Frame._();
  @$core.override
  Frame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Frame getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Frame>(create);
  static Frame? _defaultInstance;

  /// Interning key
  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// E.g. "fopen"
  /// id of string.
  @$pb.TagNumber(2)
  $fixnum.Int64 get functionNameId => $_getI64(1);
  @$pb.TagNumber(2)
  set functionNameId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFunctionNameId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFunctionNameId() => $_clearField(2);

  /// The mapping in which this frame's instruction pointer resides.
  /// iid of Mapping.iid.
  ///
  /// If set (non-zero), rel_pc MUST also be set. If mapping_id is 0 (not set),
  /// this frame has no associated memory mapping (e.g., symbolized frames
  /// without address information).
  ///
  /// Starts from 1, 0 is the same as "not set".
  @$pb.TagNumber(3)
  $fixnum.Int64 get mappingId => $_getI64(2);
  @$pb.TagNumber(3)
  set mappingId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMappingId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMappingId() => $_clearField(3);

  /// Instruction pointer relative to the start of the mapping.
  /// MUST be set if mapping_id is set (non-zero). Ignored if mapping_id is 0.
  @$pb.TagNumber(4)
  $fixnum.Int64 get relPc => $_getI64(3);
  @$pb.TagNumber(4)
  set relPc($fixnum.Int64 value) => $_setInt64(3, value);
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
    final result = create();
    if (iid != null) result.iid = iid;
    if (frameIds != null) result.frameIds.addAll(frameIds);
    return result;
  }

  Callstack._();

  factory Callstack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Callstack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

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

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Callstack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Callstack copyWith(void Function(Callstack) updates) =>
      super.copyWith((message) => updates(message as Callstack)) as Callstack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Callstack create() => Callstack._();
  @$core.override
  Callstack createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Callstack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Callstack>(create);
  static Callstack? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  /// Frames of this callstack. Bottom frame first.
  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get frameIds => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
