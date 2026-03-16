// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/track_descriptor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'process_descriptor.pb.dart' as $0;
import 'thread_descriptor.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Defines a track for TrackEvents. Slices and instant events on the same track
/// will be nested based on their timestamps, see TrackEvent::Type.
///
/// A TrackDescriptor only needs to be emitted by one trace writer / producer and
/// is valid for the entirety of the trace. To ensure the descriptor isn't lost
/// when the ring buffer wraps, it should be reemitted whenever incremental state
/// is cleared.
///
/// As a fallback, TrackEvents emitted without an explicit track association will
/// be associated with an implicit trace-global track (uuid = 0), see also
/// |TrackEvent::track_uuid|. It is possible but not necessary to emit a
/// TrackDescriptor for this implicit track.
///
/// Next id: 9.
class TrackDescriptor extends $pb.GeneratedMessage {
  factory TrackDescriptor({
    $fixnum.Int64? uuid,
    $core.String? name,
    $0.ProcessDescriptor? process,
    $1.ThreadDescriptor? thread,
    $fixnum.Int64? parentUuid,
  }) {
    final result = create();
    if (uuid != null) result.uuid = uuid;
    if (name != null) result.name = name;
    if (process != null) result.process = process;
    if (thread != null) result.thread = thread;
    if (parentUuid != null) result.parentUuid = parentUuid;
    return result;
  }

  TrackDescriptor._();

  factory TrackDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrackDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'uuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.ProcessDescriptor>(3, _omitFieldNames ? '' : 'process',
        subBuilder: $0.ProcessDescriptor.create)
    ..aOM<$1.ThreadDescriptor>(4, _omitFieldNames ? '' : 'thread',
        subBuilder: $1.ThreadDescriptor.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'parentUuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackDescriptor copyWith(void Function(TrackDescriptor) updates) =>
      super.copyWith((message) => updates(message as TrackDescriptor))
          as TrackDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrackDescriptor create() => TrackDescriptor._();
  @$core.override
  TrackDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrackDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackDescriptor>(create);
  static TrackDescriptor? _defaultInstance;

  /// Unique ID that identifies this track. This ID is global to the whole trace.
  /// Producers should ensure that it is unlikely to clash with IDs emitted by
  /// other producers. A value of 0 denotes the implicit trace-global track.
  ///
  /// For example, legacy TRACE_EVENT macros may use a hash involving the async
  /// event id + id_scope, pid, and/or tid to compute this ID.
  @$pb.TagNumber(1)
  $fixnum.Int64 get uuid => $_getI64(0);
  @$pb.TagNumber(1)
  set uuid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => $_clearField(1);

  /// Name of the track. Optional - if unspecified, it may be derived from the
  /// process/thread name (process/thread tracks), the first event's name (async
  /// tracks), or counter name (counter tracks).
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Associate the track with a process, making it the process-global track.
  /// There should only be one such track per process (usually for instant
  /// events; trace processor uses this fact to detect pid reuse). If you need
  /// more (e.g. for asynchronous events), create child tracks using parent_uuid.
  ///
  /// Trace processor will merge events on a process track with slice-type events
  /// from other sources (e.g. ftrace) for the same process into a single
  /// timeline view.
  @$pb.TagNumber(3)
  $0.ProcessDescriptor get process => $_getN(2);
  @$pb.TagNumber(3)
  set process($0.ProcessDescriptor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProcess() => $_has(2);
  @$pb.TagNumber(3)
  void clearProcess() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.ProcessDescriptor ensureProcess() => $_ensure(2);

  /// Associate the track with a thread, indicating that the track's events
  /// describe synchronous code execution on the thread. There should only be one
  /// such track per thread (trace processor uses this fact to detect tid reuse).
  ///
  /// Trace processor will merge events on a thread track with slice-type events
  /// from other sources (e.g. ftrace) for the same thread into a single timeline
  /// view.
  @$pb.TagNumber(4)
  $1.ThreadDescriptor get thread => $_getN(3);
  @$pb.TagNumber(4)
  set thread($1.ThreadDescriptor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasThread() => $_has(3);
  @$pb.TagNumber(4)
  void clearThread() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.ThreadDescriptor ensureThread() => $_ensure(3);

  /// A parent track reference can be used to describe relationships between
  /// tracks. For example, to define an asynchronous track which is scoped to a
  /// specific process, specify the uuid for that process's process track here.
  /// Similarly, to associate a COUNTER_THREAD_TIME_NS counter track with a
  /// thread, specify the uuid for that thread's thread track here.
  @$pb.TagNumber(5)
  $fixnum.Int64 get parentUuid => $_getI64(4);
  @$pb.TagNumber(5)
  set parentUuid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasParentUuid() => $_has(4);
  @$pb.TagNumber(5)
  void clearParentUuid() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
