// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/track_event.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'debug_annotation.pb.dart' as $0;
import 'track_event.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'track_event.pbenum.dart';

enum TrackEvent_NameField { nameIid, name, notSet }

/// Trace events emitted by client instrumentation library (TRACE_EVENT macros),
/// which describe activity on a track, such as a thread or asynchronous event
/// track. The track is specified using separate TrackDescriptor messages and
/// referred to via the track's UUID.
///
/// A simple TrackEvent packet specifies a timestamp, category, name and type:
/// ```protobuf
///   trace_packet {
///     timestamp: 1000
///     track_event {
///       categories: ["my_cat"]
///       name: "my_event"
///       type: TYPE_INSTANT
///      }
///    }
/// ```
///
/// To associate an event with a custom track (e.g. a thread), the track is
/// defined in a separate packet and referred to from the TrackEvent by its UUID:
/// ```protobuf
///   trace_packet {
///     track_descriptor {
///       track_uuid: 1234
///       name: "my_track"
///
///       // Optionally, associate the track with a thread.
///       thread_descriptor {
///         pid: 10
///         tid: 10
///         ..
///       }
///     }
///   }
/// ```
///
/// A pair of TYPE_SLICE_BEGIN and _END events form a slice on the track:
///
/// ```protobuf
///   trace_packet {
///     timestamp: 1200
///     track_event {
///       track_uuid: 1234
///       categories: ["my_cat"]
///       name: "my_slice"
///       type: TYPE_SLICE_BEGIN
///     }
///   }
///   trace_packet {
///     timestamp: 1400
///     track_event {
///       track_uuid: 1234
///       type: TYPE_SLICE_END
///     }
///   }
/// ```
/// TrackEvents also support optimizations to reduce data repetition and encoded
/// data size, e.g. through data interning (names, categories, ...) and delta
/// encoding of timestamps/counters. For details, see the InternedData message.
/// Further, default values for attributes of events on the same sequence (e.g.
/// their default track association) can be emitted as part of a
/// TrackEventDefaults message.
///
/// Next reserved id: 13 (up to 15). Next id: 50.
class TrackEvent extends $pb.GeneratedMessage {
  factory TrackEvent({
    $core.Iterable<$fixnum.Int64>? categoryIids,
    $core.Iterable<$0.DebugAnnotation>? debugAnnotations,
    TrackEvent_Type? type,
    $fixnum.Int64? nameIid,
    $fixnum.Int64? trackUuid,
    $core.Iterable<$core.String>? categories,
    $core.String? name,
    $core.Iterable<$fixnum.Int64>? flowIds,
    $core.Iterable<$fixnum.Int64>? terminatingFlowIds,
  }) {
    final result = create();
    if (categoryIids != null) result.categoryIids.addAll(categoryIids);
    if (debugAnnotations != null)
      result.debugAnnotations.addAll(debugAnnotations);
    if (type != null) result.type = type;
    if (nameIid != null) result.nameIid = nameIid;
    if (trackUuid != null) result.trackUuid = trackUuid;
    if (categories != null) result.categories.addAll(categories);
    if (name != null) result.name = name;
    if (flowIds != null) result.flowIds.addAll(flowIds);
    if (terminatingFlowIds != null)
      result.terminatingFlowIds.addAll(terminatingFlowIds);
    return result;
  }

  TrackEvent._();

  factory TrackEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrackEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, TrackEvent_NameField>
      _TrackEvent_NameFieldByTag = {
    10: TrackEvent_NameField.nameIid,
    23: TrackEvent_NameField.name,
    0: TrackEvent_NameField.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..oo(0, [10, 23])
    ..p<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'categoryIids', $pb.PbFieldType.PU6)
    ..pPM<$0.DebugAnnotation>(4, _omitFieldNames ? '' : 'debugAnnotations',
        subBuilder: $0.DebugAnnotation.create)
    ..aE<TrackEvent_Type>(9, _omitFieldNames ? '' : 'type',
        enumValues: TrackEvent_Type.values)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'nameIid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'trackUuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(22, _omitFieldNames ? '' : 'categories')
    ..aOS(23, _omitFieldNames ? '' : 'name')
    ..p<$fixnum.Int64>(
        47, _omitFieldNames ? '' : 'flowIds', $pb.PbFieldType.PF6)
    ..p<$fixnum.Int64>(
        48, _omitFieldNames ? '' : 'terminatingFlowIds', $pb.PbFieldType.PF6)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrackEvent copyWith(void Function(TrackEvent) updates) =>
      super.copyWith((message) => updates(message as TrackEvent)) as TrackEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrackEvent create() => TrackEvent._();
  @$core.override
  TrackEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrackEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackEvent>(create);
  static TrackEvent? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(23)
  TrackEvent_NameField whichNameField() =>
      _TrackEvent_NameFieldByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(23)
  void clearNameField() => $_clearField($_whichOneof(0));

  /// Names of categories of the event. In the client library, categories are a
  /// way to turn groups of individual events on or off.
  /// interned EventCategoryName.
  @$pb.TagNumber(3)
  $pb.PbList<$fixnum.Int64> get categoryIids => $_getList(0);

  /// Unstable key/value annotations shown in the trace viewer but not intended
  /// for metrics use.
  @$pb.TagNumber(4)
  $pb.PbList<$0.DebugAnnotation> get debugAnnotations => $_getList(1);

  @$pb.TagNumber(9)
  TrackEvent_Type get type => $_getN(2);
  @$pb.TagNumber(9)
  set type(TrackEvent_Type value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(9)
  void clearType() => $_clearField(9);

  /// interned EventName.
  @$pb.TagNumber(10)
  $fixnum.Int64 get nameIid => $_getI64(3);
  @$pb.TagNumber(10)
  set nameIid($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(10)
  $core.bool hasNameIid() => $_has(3);
  @$pb.TagNumber(10)
  void clearNameIid() => $_clearField(10);

  /// Identifies the track of the event. The default value may be overridden
  /// using TrackEventDefaults, e.g., to specify the track of the TraceWriter's
  /// sequence (in most cases sequence = one thread). If no value is specified
  /// here or in TrackEventDefaults, the TrackEvent will be associated with an
  /// implicit trace-global track (uuid 0). See TrackDescriptor::uuid.
  @$pb.TagNumber(11)
  $fixnum.Int64 get trackUuid => $_getI64(4);
  @$pb.TagNumber(11)
  set trackUuid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(11)
  $core.bool hasTrackUuid() => $_has(4);
  @$pb.TagNumber(11)
  void clearTrackUuid() => $_clearField(11);

  /// non-interned variant.
  @$pb.TagNumber(22)
  $pb.PbList<$core.String> get categories => $_getList(5);

  /// non-interned variant.
  @$pb.TagNumber(23)
  $core.String get name => $_getSZ(6);
  @$pb.TagNumber(23)
  set name($core.String value) => $_setString(6, value);
  @$pb.TagNumber(23)
  $core.bool hasName() => $_has(6);
  @$pb.TagNumber(23)
  void clearName() => $_clearField(23);

  /// IDs of flows originating, passing through, or ending at this event.
  /// Flow IDs are global within a trace.
  ///
  /// A flow connects a sequence of TrackEvents within or across tracks, e.g.
  /// an input event may be handled on one thread but cause another event on
  /// a different thread - a flow between the two events can associate them.
  ///
  /// The direction of the flows between events is inferred from the events'
  /// timestamps. The earliest event with the same flow ID becomes the source
  /// of the flow. Any events thereafter are intermediate steps of the flow,
  /// until the flow terminates at the last event with the flow ID.
  ///
  /// Flows can also be explicitly terminated (see |terminating_flow_ids|), so
  /// that the same ID can later be reused for another flow.
  @$pb.TagNumber(47)
  $pb.PbList<$fixnum.Int64> get flowIds => $_getList(7);

  /// List of flow ids which should terminate on this event, otherwise same as
  /// |flow_ids|.
  /// Any one flow ID should be either listed as part of |flow_ids| OR
  /// |terminating_flow_ids|, not both.
  @$pb.TagNumber(48)
  $pb.PbList<$fixnum.Int64> get terminatingFlowIds => $_getList(8);
}

class EventCategory extends $pb.GeneratedMessage {
  factory EventCategory({
    $fixnum.Int64? iid,
    $core.String? name,
  }) {
    final result = create();
    if (iid != null) result.iid = iid;
    if (name != null) result.name = name;
    return result;
  }

  EventCategory._();

  factory EventCategory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventCategory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventCategory',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventCategory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventCategory copyWith(void Function(EventCategory) updates) =>
      super.copyWith((message) => updates(message as EventCategory))
          as EventCategory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventCategory create() => EventCategory._();
  @$core.override
  EventCategory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventCategory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventCategory>(create);
  static EventCategory? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class EventName extends $pb.GeneratedMessage {
  factory EventName({
    $fixnum.Int64? iid,
    $core.String? name,
  }) {
    final result = create();
    if (iid != null) result.iid = iid;
    if (name != null) result.name = name;
    return result;
  }

  EventName._();

  factory EventName.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventName.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventName',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventName clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventName copyWith(void Function(EventName) updates) =>
      super.copyWith((message) => updates(message as EventName)) as EventName;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventName create() => EventName._();
  @$core.override
  EventName createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventName getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventName>(create);
  static EventName? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
