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

import 'package:protobuf/protobuf.dart' as $pb;

/// Type of the TrackEvent (required if |phase| in LegacyEvent is not set).
class TrackEvent_Type extends $pb.ProtobufEnum {
  static const TrackEvent_Type TYPE_UNSPECIFIED =
      TrackEvent_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');

  /// Slice events are events that have a begin and end timestamp, i.e. a
  /// duration. They can be nested similar to a callstack: If, on the same
  /// track, event B begins after event A, but before A ends, B is a child
  /// event of A and will be drawn as a nested event underneath A in the UI.
  /// Note that child events should always end before their parents (e.g. B
  /// before A).
  ///
  /// Each slice event is formed by a pair of BEGIN + END events. The END event
  /// does not need to repeat any TrackEvent fields it has in common with its
  /// corresponding BEGIN event. Arguments and debug annotations of the BEGIN +
  /// END pair will be merged during trace import.
  ///
  /// Note that we deliberately chose not to support COMPLETE events (which
  /// would specify a duration directly) since clients would need to delay
  /// writing them until the slice is completed, which can result in reordered
  /// events in the trace and loss of unfinished events at the end of a trace.
  static const TrackEvent_Type TYPE_SLICE_BEGIN =
      TrackEvent_Type._(1, _omitEnumNames ? '' : 'TYPE_SLICE_BEGIN');
  static const TrackEvent_Type TYPE_SLICE_END =
      TrackEvent_Type._(2, _omitEnumNames ? '' : 'TYPE_SLICE_END');

  /// Instant events are nestable events without duration. They can be children
  /// of slice events on the same track.
  static const TrackEvent_Type TYPE_INSTANT =
      TrackEvent_Type._(3, _omitEnumNames ? '' : 'TYPE_INSTANT');

  static const $core.List<TrackEvent_Type> values = <TrackEvent_Type>[
    TYPE_UNSPECIFIED,
    TYPE_SLICE_BEGIN,
    TYPE_SLICE_END,
    TYPE_INSTANT,
  ];

  static final $core.List<TrackEvent_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TrackEvent_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TrackEvent_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
