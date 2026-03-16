// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/interned_data/interned_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../profiling/profile_common.pb.dart' as $2;
import '../track_event/debug_annotation.pb.dart' as $1;
import '../track_event/track_event.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Message that contains new entries for the interning indices of a packet
/// sequence.
///
/// The writer will usually emit new entries in the same TracePacket that first
/// refers to them (since the last reset of interning state). They may also be
/// emitted proactively in advance of referring to them in later packets.
///
/// Next reserved id: 8 (up to 15).
/// Next id: 29.
class InternedData extends $pb.GeneratedMessage {
  factory InternedData({
    $core.Iterable<$0.EventCategory>? eventCategories,
    $core.Iterable<$0.EventName>? eventNames,
    $core.Iterable<$1.DebugAnnotationName>? debugAnnotationNames,
    $core.Iterable<$2.InternedString>? functionNames,
    $core.Iterable<$2.Frame>? frames,
    $core.Iterable<$2.Callstack>? callstacks,
    $core.Iterable<$2.InternedString>? buildIds,
    $core.Iterable<$2.InternedString>? mappingPaths,
    $core.Iterable<$2.Mapping>? mappings,
    $core.Iterable<$2.InternedString>? debugAnnotationStringValues,
  }) {
    final result = create();
    if (eventCategories != null) result.eventCategories.addAll(eventCategories);
    if (eventNames != null) result.eventNames.addAll(eventNames);
    if (debugAnnotationNames != null)
      result.debugAnnotationNames.addAll(debugAnnotationNames);
    if (functionNames != null) result.functionNames.addAll(functionNames);
    if (frames != null) result.frames.addAll(frames);
    if (callstacks != null) result.callstacks.addAll(callstacks);
    if (buildIds != null) result.buildIds.addAll(buildIds);
    if (mappingPaths != null) result.mappingPaths.addAll(mappingPaths);
    if (mappings != null) result.mappings.addAll(mappings);
    if (debugAnnotationStringValues != null)
      result.debugAnnotationStringValues.addAll(debugAnnotationStringValues);
    return result;
  }

  InternedData._();

  factory InternedData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InternedData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InternedData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..pPM<$0.EventCategory>(1, _omitFieldNames ? '' : 'eventCategories',
        subBuilder: $0.EventCategory.create)
    ..pPM<$0.EventName>(2, _omitFieldNames ? '' : 'eventNames',
        subBuilder: $0.EventName.create)
    ..pPM<$1.DebugAnnotationName>(
        3, _omitFieldNames ? '' : 'debugAnnotationNames',
        subBuilder: $1.DebugAnnotationName.create)
    ..pPM<$2.InternedString>(5, _omitFieldNames ? '' : 'functionNames',
        subBuilder: $2.InternedString.create)
    ..pPM<$2.Frame>(6, _omitFieldNames ? '' : 'frames',
        subBuilder: $2.Frame.create)
    ..pPM<$2.Callstack>(7, _omitFieldNames ? '' : 'callstacks',
        subBuilder: $2.Callstack.create)
    ..pPM<$2.InternedString>(16, _omitFieldNames ? '' : 'buildIds',
        subBuilder: $2.InternedString.create)
    ..pPM<$2.InternedString>(17, _omitFieldNames ? '' : 'mappingPaths',
        subBuilder: $2.InternedString.create)
    ..pPM<$2.Mapping>(19, _omitFieldNames ? '' : 'mappings',
        subBuilder: $2.Mapping.create)
    ..pPM<$2.InternedString>(
        29, _omitFieldNames ? '' : 'debugAnnotationStringValues',
        subBuilder: $2.InternedString.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InternedData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InternedData copyWith(void Function(InternedData) updates) =>
      super.copyWith((message) => updates(message as InternedData))
          as InternedData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InternedData create() => InternedData._();
  @$core.override
  InternedData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InternedData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InternedData>(create);
  static InternedData? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.EventCategory> get eventCategories => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$0.EventName> get eventNames => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$1.DebugAnnotationName> get debugAnnotationNames => $_getList(2);

  /// Names of functions used in frames below.
  @$pb.TagNumber(5)
  $pb.PbList<$2.InternedString> get functionNames => $_getList(3);

  /// Frames of callstacks of a program.
  @$pb.TagNumber(6)
  $pb.PbList<$2.Frame> get frames => $_getList(4);

  /// A callstack of a program.
  @$pb.TagNumber(7)
  $pb.PbList<$2.Callstack> get callstacks => $_getList(5);

  /// Build IDs of exectuable files.
  @$pb.TagNumber(16)
  $pb.PbList<$2.InternedString> get buildIds => $_getList(6);

  /// Paths to executable files.
  @$pb.TagNumber(17)
  $pb.PbList<$2.InternedString> get mappingPaths => $_getList(7);

  /// Executable files mapped into processes.
  @$pb.TagNumber(19)
  $pb.PbList<$2.Mapping> get mappings => $_getList(8);

  /// Interned string values in the DebugAnnotation proto.
  @$pb.TagNumber(29)
  $pb.PbList<$2.InternedString> get debugAnnotationStringValues => $_getList(9);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
