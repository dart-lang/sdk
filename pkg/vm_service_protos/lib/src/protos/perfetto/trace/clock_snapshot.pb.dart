// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/clock_snapshot.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

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
    final $result = create();
    if (clockId != null) {
      $result.clockId = clockId;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    return $result;
  }
  ClockSnapshot_Clock._() : super();
  factory ClockSnapshot_Clock.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClockSnapshot_Clock.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClockSnapshot.Clock',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'clockId', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClockSnapshot_Clock clone() => ClockSnapshot_Clock()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClockSnapshot_Clock copyWith(void Function(ClockSnapshot_Clock) updates) =>
      super.copyWith((message) => updates(message as ClockSnapshot_Clock))
          as ClockSnapshot_Clock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClockSnapshot_Clock create() => ClockSnapshot_Clock._();
  ClockSnapshot_Clock createEmptyInstance() => create();
  static $pb.PbList<ClockSnapshot_Clock> createRepeated() =>
      $pb.PbList<ClockSnapshot_Clock>();
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
  set clockId($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasClockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClockId() => $_clearField(1);

  /// Absolute timestamp. Unit is ns unless specified otherwise by the
  /// unit_multiplier_ns field below.
  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

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
    final $result = create();
    if (clocks != null) {
      $result.clocks.addAll(clocks);
    }
    if (primaryTraceClock != null) {
      $result.primaryTraceClock = primaryTraceClock;
    }
    return $result;
  }
  ClockSnapshot._() : super();
  factory ClockSnapshot.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ClockSnapshot.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClockSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..pc<ClockSnapshot_Clock>(
        1, _omitFieldNames ? '' : 'clocks', $pb.PbFieldType.PM,
        subBuilder: ClockSnapshot_Clock.create)
    ..e<$0.BuiltinClock>(
        2, _omitFieldNames ? '' : 'primaryTraceClock', $pb.PbFieldType.OE,
        defaultOrMaker: $0.BuiltinClock.BUILTIN_CLOCK_MONOTONIC,
        valueOf: $0.BuiltinClock.valueOf,
        enumValues: $0.BuiltinClock.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ClockSnapshot clone() => ClockSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ClockSnapshot copyWith(void Function(ClockSnapshot) updates) =>
      super.copyWith((message) => updates(message as ClockSnapshot))
          as ClockSnapshot;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClockSnapshot create() => ClockSnapshot._();
  ClockSnapshot createEmptyInstance() => create();
  static $pb.PbList<ClockSnapshot> createRepeated() =>
      $pb.PbList<ClockSnapshot>();
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
  set primaryTraceClock($0.BuiltinClock v) {
    $_setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPrimaryTraceClock() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrimaryTraceClock() => $_clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
