// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/clock_snapshot.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../common/builtin_clock.pbenum.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ClockSnapshot_Clock extends $pb.GeneratedMessage {
  factory ClockSnapshot_Clock({
    $core.int? clockId,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (clockId != null) result.clockId = clockId;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  ClockSnapshot_Clock._();

  factory ClockSnapshot_Clock.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClockSnapshot_Clock.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClockSnapshot.Clock',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'clockId', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClockSnapshot_Clock clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClockSnapshot_Clock copyWith(void Function(ClockSnapshot_Clock) updates) =>
      super.copyWith((message) => updates(message as ClockSnapshot_Clock))
          as ClockSnapshot_Clock;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClockSnapshot_Clock create() => ClockSnapshot_Clock._();
  @$core.override
  ClockSnapshot_Clock createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClockSnapshot_Clock getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClockSnapshot_Clock>(create);
  static ClockSnapshot_Clock? _defaultInstance;

  /// Clock IDs have the following semantic:
  /// [1, 63]:    Builtin types, see BuiltinClock from
  ///             ../common/builtin_clock.proto.
  /// [64, 127]:  User-defined clocks. These clocks are sequence-scoped. They
  ///             are only valid within the same |trusted_packet_sequence_id|
  ///             (i.e. only for TracePacket(s) emitted by the same TraceWriter
  ///             that emitted the clock snapshot).
  /// [128, MAX]: Reserved for future use. The idea is to allow global clock
  ///             IDs and setting this ID to hash(full_clock_name) & ~127.
  @$pb.TagNumber(1)
  $core.int get clockId => $_getIZ(0);
  @$pb.TagNumber(1)
  set clockId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClockId() => $_clearField(1);

  /// Absolute timestamp. Unit is ns unless specified otherwise by the
  /// unit_multiplier_ns field below.
  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => $_clearField(2);
}

/// A snapshot of clock readings to allow for trace alignment.
class ClockSnapshot extends $pb.GeneratedMessage {
  factory ClockSnapshot({
    $core.Iterable<ClockSnapshot_Clock>? clocks,
    $0.BuiltinClock? primaryTraceClock,
  }) {
    final result = create();
    if (clocks != null) result.clocks.addAll(clocks);
    if (primaryTraceClock != null) result.primaryTraceClock = primaryTraceClock;
    return result;
  }

  ClockSnapshot._();

  factory ClockSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClockSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClockSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..pPM<ClockSnapshot_Clock>(1, _omitFieldNames ? '' : 'clocks',
        subBuilder: ClockSnapshot_Clock.create)
    ..aE<$0.BuiltinClock>(2, _omitFieldNames ? '' : 'primaryTraceClock',
        enumValues: $0.BuiltinClock.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClockSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClockSnapshot copyWith(void Function(ClockSnapshot) updates) =>
      super.copyWith((message) => updates(message as ClockSnapshot))
          as ClockSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClockSnapshot create() => ClockSnapshot._();
  @$core.override
  ClockSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClockSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClockSnapshot>(create);
  static ClockSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ClockSnapshot_Clock> get clocks => $_getList(0);

  /// The authoritative clock domain for the trace. Defaults to BOOTTIME, but can
  /// be overridden in TraceConfig's builtin_data_sources. Trace processor will
  /// attempt to translate packet/event timestamps from various data sources (and
  /// their chosen clock domains) to this domain during import.
  @$pb.TagNumber(2)
  $0.BuiltinClock get primaryTraceClock => $_getN(1);
  @$pb.TagNumber(2)
  set primaryTraceClock($0.BuiltinClock value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPrimaryTraceClock() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrimaryTraceClock() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
