// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/interned_data/interned_data.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../profiling/profile_common.pb.dart' as $3;
import '../track_event/debug_annotation.pb.dart' as $1;
import '../track_event/track_event.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///  Message that contains new entries for the interning indices of a packet
///  sequence.
///
///  The writer will usually emit new entries in the same TracePacket that first
///  refers to them (since the last reset of interning state). They may also be
///  emitted proactively in advance of referring to them in later packets.
///
///  Next reserved id: 8 (up to 15).
///  Next id: 29.
class InternedData extends $pb.GeneratedMessage {
  factory InternedData({
    $core.Iterable<$2.EventCategory>? eventCategories,
    $core.Iterable<$2.EventName>? eventNames,
    $core.Iterable<$1.DebugAnnotationName>? debugAnnotationNames,
    $core.Iterable<$3.InternedString>? functionNames,
    $core.Iterable<$3.Frame>? frames,
    $core.Iterable<$3.Callstack>? callstacks,
    $core.Iterable<$3.InternedString>? mappingPaths,
    $core.Iterable<$3.Mapping>? mappings,
    $core.Iterable<$3.InternedString>? debugAnnotationStringValues,
  }) {
    final $result = create();
    if (eventCategories != null) {
      $result.eventCategories.addAll(eventCategories);
    }
    if (eventNames != null) {
      $result.eventNames.addAll(eventNames);
    }
    if (debugAnnotationNames != null) {
      $result.debugAnnotationNames.addAll(debugAnnotationNames);
    }
    if (functionNames != null) {
      $result.functionNames.addAll(functionNames);
    }
    if (frames != null) {
      $result.frames.addAll(frames);
    }
    if (callstacks != null) {
      $result.callstacks.addAll(callstacks);
    }
    if (mappingPaths != null) {
      $result.mappingPaths.addAll(mappingPaths);
    }
    if (mappings != null) {
      $result.mappings.addAll(mappings);
    }
    if (debugAnnotationStringValues != null) {
      $result.debugAnnotationStringValues.addAll(debugAnnotationStringValues);
    }
    return $result;
  }
  InternedData._() : super();
  factory InternedData.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InternedData.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InternedData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..pc<$2.EventCategory>(
        1, _omitFieldNames ? '' : 'eventCategories', $pb.PbFieldType.PM,
        subBuilder: $2.EventCategory.create)
    ..pc<$2.EventName>(
        2, _omitFieldNames ? '' : 'eventNames', $pb.PbFieldType.PM,
        subBuilder: $2.EventName.create)
    ..pc<$1.DebugAnnotationName>(
        3, _omitFieldNames ? '' : 'debugAnnotationNames', $pb.PbFieldType.PM,
        subBuilder: $1.DebugAnnotationName.create)
    ..pc<$3.InternedString>(
        5, _omitFieldNames ? '' : 'functionNames', $pb.PbFieldType.PM,
        subBuilder: $3.InternedString.create)
    ..pc<$3.Frame>(6, _omitFieldNames ? '' : 'frames', $pb.PbFieldType.PM,
        subBuilder: $3.Frame.create)
    ..pc<$3.Callstack>(
        7, _omitFieldNames ? '' : 'callstacks', $pb.PbFieldType.PM,
        subBuilder: $3.Callstack.create)
    ..pc<$3.InternedString>(
        17, _omitFieldNames ? '' : 'mappingPaths', $pb.PbFieldType.PM,
        subBuilder: $3.InternedString.create)
    ..pc<$3.Mapping>(19, _omitFieldNames ? '' : 'mappings', $pb.PbFieldType.PM,
        subBuilder: $3.Mapping.create)
    ..pc<$3.InternedString>(
        29,
        _omitFieldNames ? '' : 'debugAnnotationStringValues',
        $pb.PbFieldType.PM,
        subBuilder: $3.InternedString.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InternedData clone() => InternedData()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InternedData copyWith(void Function(InternedData) updates) =>
      super.copyWith((message) => updates(message as InternedData))
          as InternedData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InternedData create() => InternedData._();
  InternedData createEmptyInstance() => create();
  static $pb.PbList<InternedData> createRepeated() =>
      $pb.PbList<InternedData>();
  @$core.pragma('dart2js:noInline')
  static InternedData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InternedData>(create);
  static InternedData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$2.EventCategory> get eventCategories => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$2.EventName> get eventNames => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$1.DebugAnnotationName> get debugAnnotationNames => $_getList(2);

  /// Names of functions used in frames below.
  @$pb.TagNumber(5)
  $pb.PbList<$3.InternedString> get functionNames => $_getList(3);

  /// Frames of callstacks of a program.
  @$pb.TagNumber(6)
  $pb.PbList<$3.Frame> get frames => $_getList(4);

  /// A callstack of a program.
  @$pb.TagNumber(7)
  $pb.PbList<$3.Callstack> get callstacks => $_getList(5);

  /// Paths to executable files.
  @$pb.TagNumber(17)
  $pb.PbList<$3.InternedString> get mappingPaths => $_getList(6);

  /// Executable files mapped into processes.
  @$pb.TagNumber(19)
  $pb.PbList<$3.Mapping> get mappings => $_getList(7);

  /// Interned string values in the DebugAnnotation proto.
  @$pb.TagNumber(29)
  $pb.PbList<$3.InternedString> get debugAnnotationStringValues => $_getList(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
