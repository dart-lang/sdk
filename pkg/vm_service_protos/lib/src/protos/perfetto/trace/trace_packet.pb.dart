// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/trace_packet.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'clock_snapshot.pb.dart' as $6;
import 'interned_data/interned_data.pb.dart' as $7;
import 'profiling/profile_packet.pb.dart' as $9;
import 'track_event/track_descriptor.pb.dart' as $8;
import 'track_event/track_event.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'trace_packet.pbenum.dart';

enum TracePacket_Data {
  clockSnapshot,
  trackEvent,
  trackDescriptor,
  perfSample,
  notSet
}

enum TracePacket_OptionalTrustedPacketSequenceId {
  trustedPacketSequenceId,
  notSet
}

///  TracePacket is the root object of a Perfetto trace.
///  A Perfetto trace is a linear sequence of TracePacket(s).
///
///  The tracing service guarantees that all TracePacket(s) written by a given
///  TraceWriter are seen in-order, without gaps or duplicates. If, for any
///  reason, a TraceWriter sequence becomes invalid, no more packets are returned
///  to the Consumer (or written into the trace file).
///  TracePacket(s) written by different TraceWriter(s), hence even different
///  data sources, can be seen in arbitrary order.
///  The consumer can re-establish a total order, if interested, using the packet
///  timestamps, after having synchronized the different clocks onto a global
///  clock.
///
///  The tracing service is agnostic of the content of TracePacket, with the
///  exception of few fields (e.g.. trusted_*, trace_config) that are written by
///  the service itself.
///
///  See the [Buffers and Dataflow](/docs/concepts/buffers.md) doc for details.
///
///  Next reserved id: 14 (up to 15).
///  Next id: 88.
class TracePacket extends $pb.GeneratedMessage {
  factory TracePacket({
    $6.ClockSnapshot? clockSnapshot,
    $fixnum.Int64? timestamp,
    $core.int? trustedPacketSequenceId,
    $2.TrackEvent? trackEvent,
    $7.InternedData? internedData,
    $core.int? sequenceFlags,
    $core.int? timestampClockId,
    $8.TrackDescriptor? trackDescriptor,
    $9.PerfSample? perfSample,
  }) {
    final $result = create();
    if (clockSnapshot != null) {
      $result.clockSnapshot = clockSnapshot;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (trustedPacketSequenceId != null) {
      $result.trustedPacketSequenceId = trustedPacketSequenceId;
    }
    if (trackEvent != null) {
      $result.trackEvent = trackEvent;
    }
    if (internedData != null) {
      $result.internedData = internedData;
    }
    if (sequenceFlags != null) {
      $result.sequenceFlags = sequenceFlags;
    }
    if (timestampClockId != null) {
      $result.timestampClockId = timestampClockId;
    }
    if (trackDescriptor != null) {
      $result.trackDescriptor = trackDescriptor;
    }
    if (perfSample != null) {
      $result.perfSample = perfSample;
    }
    return $result;
  }
  TracePacket._() : super();
  factory TracePacket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TracePacket.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, TracePacket_Data> _TracePacket_DataByTag = {
    6: TracePacket_Data.clockSnapshot,
    11: TracePacket_Data.trackEvent,
    60: TracePacket_Data.trackDescriptor,
    66: TracePacket_Data.perfSample,
    0: TracePacket_Data.notSet
  };
  static const $core.Map<$core.int, TracePacket_OptionalTrustedPacketSequenceId>
      _TracePacket_OptionalTrustedPacketSequenceIdByTag = {
    10: TracePacket_OptionalTrustedPacketSequenceId.trustedPacketSequenceId,
    0: TracePacket_OptionalTrustedPacketSequenceId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TracePacket',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..oo(0, [6, 11, 60, 66])
    ..oo(1, [10])
    ..aOM<$6.ClockSnapshot>(6, _omitFieldNames ? '' : 'clockSnapshot',
        subBuilder: $6.ClockSnapshot.create)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'trustedPacketSequenceId',
        $pb.PbFieldType.OU3)
    ..aOM<$2.TrackEvent>(11, _omitFieldNames ? '' : 'trackEvent',
        subBuilder: $2.TrackEvent.create)
    ..aOM<$7.InternedData>(12, _omitFieldNames ? '' : 'internedData',
        subBuilder: $7.InternedData.create)
    ..a<$core.int>(
        13, _omitFieldNames ? '' : 'sequenceFlags', $pb.PbFieldType.OU3)
    ..a<$core.int>(
        58, _omitFieldNames ? '' : 'timestampClockId', $pb.PbFieldType.OU3)
    ..aOM<$8.TrackDescriptor>(60, _omitFieldNames ? '' : 'trackDescriptor',
        subBuilder: $8.TrackDescriptor.create)
    ..aOM<$9.PerfSample>(66, _omitFieldNames ? '' : 'perfSample',
        subBuilder: $9.PerfSample.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TracePacket clone() => TracePacket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TracePacket copyWith(void Function(TracePacket) updates) =>
      super.copyWith((message) => updates(message as TracePacket))
          as TracePacket;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TracePacket create() => TracePacket._();
  TracePacket createEmptyInstance() => create();
  static $pb.PbList<TracePacket> createRepeated() => $pb.PbList<TracePacket>();
  @$core.pragma('dart2js:noInline')
  static TracePacket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TracePacket>(create);
  static TracePacket? _defaultInstance;

  TracePacket_Data whichData() => _TracePacket_DataByTag[$_whichOneof(0)]!;
  void clearData() => $_clearField($_whichOneof(0));

  TracePacket_OptionalTrustedPacketSequenceId
      whichOptionalTrustedPacketSequenceId() =>
          _TracePacket_OptionalTrustedPacketSequenceIdByTag[$_whichOneof(1)]!;
  void clearOptionalTrustedPacketSequenceId() => $_clearField($_whichOneof(1));

  @$pb.TagNumber(6)
  $6.ClockSnapshot get clockSnapshot => $_getN(0);
  @$pb.TagNumber(6)
  set clockSnapshot($6.ClockSnapshot v) {
    $_setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasClockSnapshot() => $_has(0);
  @$pb.TagNumber(6)
  void clearClockSnapshot() => $_clearField(6);
  @$pb.TagNumber(6)
  $6.ClockSnapshot ensureClockSnapshot() => $_ensure(0);

  /// The timestamp of the TracePacket.
  /// By default this timestamps refers to the trace clock (CLOCK_BOOTTIME on
  /// Android). It can be overridden using a different timestamp_clock_id.
  /// The clock domain definition in ClockSnapshot can also override:
  /// - The unit (default: 1ns).
  /// - The absolute vs delta encoding (default: absolute timestamp).
  @$pb.TagNumber(8)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(8)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(8)
  void clearTimestamp() => $_clearField(8);

  @$pb.TagNumber(10)
  $core.int get trustedPacketSequenceId => $_getIZ(2);
  @$pb.TagNumber(10)
  set trustedPacketSequenceId($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasTrustedPacketSequenceId() => $_has(2);
  @$pb.TagNumber(10)
  void clearTrustedPacketSequenceId() => $_clearField(10);

  @$pb.TagNumber(11)
  $2.TrackEvent get trackEvent => $_getN(3);
  @$pb.TagNumber(11)
  set trackEvent($2.TrackEvent v) {
    $_setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasTrackEvent() => $_has(3);
  @$pb.TagNumber(11)
  void clearTrackEvent() => $_clearField(11);
  @$pb.TagNumber(11)
  $2.TrackEvent ensureTrackEvent() => $_ensure(3);

  /// Incrementally emitted interned data, valid only on the packet's sequence
  /// (packets with the same |trusted_packet_sequence_id|). The writer will
  /// usually emit new interned data in the same TracePacket that first refers to
  /// it (since the last reset of interning state). It may also be emitted
  /// proactively in advance of referring to them in later packets.
  @$pb.TagNumber(12)
  $7.InternedData get internedData => $_getN(4);
  @$pb.TagNumber(12)
  set internedData($7.InternedData v) {
    $_setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasInternedData() => $_has(4);
  @$pb.TagNumber(12)
  void clearInternedData() => $_clearField(12);
  @$pb.TagNumber(12)
  $7.InternedData ensureInternedData() => $_ensure(4);

  @$pb.TagNumber(13)
  $core.int get sequenceFlags => $_getIZ(5);
  @$pb.TagNumber(13)
  set sequenceFlags($core.int v) {
    $_setUnsignedInt32(5, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasSequenceFlags() => $_has(5);
  @$pb.TagNumber(13)
  void clearSequenceFlags() => $_clearField(13);

  /// Specifies the ID of the clock used for the TracePacket |timestamp|. Can be
  /// one of the built-in types from ClockSnapshot::BuiltinClocks, or a
  /// producer-defined clock id.
  /// If unspecified and if no default per-sequence value has been provided via
  /// TracePacketDefaults, it defaults to BuiltinClocks::BOOTTIME.
  @$pb.TagNumber(58)
  $core.int get timestampClockId => $_getIZ(6);
  @$pb.TagNumber(58)
  set timestampClockId($core.int v) {
    $_setUnsignedInt32(6, v);
  }

  @$pb.TagNumber(58)
  $core.bool hasTimestampClockId() => $_has(6);
  @$pb.TagNumber(58)
  void clearTimestampClockId() => $_clearField(58);

  /// Only used by TrackEvent.
  @$pb.TagNumber(60)
  $8.TrackDescriptor get trackDescriptor => $_getN(7);
  @$pb.TagNumber(60)
  set trackDescriptor($8.TrackDescriptor v) {
    $_setField(60, v);
  }

  @$pb.TagNumber(60)
  $core.bool hasTrackDescriptor() => $_has(7);
  @$pb.TagNumber(60)
  void clearTrackDescriptor() => $_clearField(60);
  @$pb.TagNumber(60)
  $8.TrackDescriptor ensureTrackDescriptor() => $_ensure(7);

  @$pb.TagNumber(66)
  $9.PerfSample get perfSample => $_getN(8);
  @$pb.TagNumber(66)
  set perfSample($9.PerfSample v) {
    $_setField(66, v);
  }

  @$pb.TagNumber(66)
  $core.bool hasPerfSample() => $_has(8);
  @$pb.TagNumber(66)
  void clearPerfSample() => $_clearField(66);
  @$pb.TagNumber(66)
  $9.PerfSample ensurePerfSample() => $_ensure(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
