// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/trace_packet.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'clock_snapshot.pb.dart' as $5;
import 'interned_data/interned_data.pb.dart' as $7;
import 'profiling/profile_packet.pb.dart' as $9;
import 'track_event/track_descriptor.pb.dart' as $8;
import 'track_event/track_event.pb.dart' as $6;

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

class TracePacket extends $pb.GeneratedMessage {
  factory TracePacket() => create();
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
    ..aOM<$5.ClockSnapshot>(6, _omitFieldNames ? '' : 'clockSnapshot',
        subBuilder: $5.ClockSnapshot.create)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'trustedPacketSequenceId',
        $pb.PbFieldType.OU3)
    ..aOM<$6.TrackEvent>(11, _omitFieldNames ? '' : 'trackEvent',
        subBuilder: $6.TrackEvent.create)
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
  void clearData() => clearField($_whichOneof(0));

  TracePacket_OptionalTrustedPacketSequenceId
      whichOptionalTrustedPacketSequenceId() =>
          _TracePacket_OptionalTrustedPacketSequenceIdByTag[$_whichOneof(1)]!;
  void clearOptionalTrustedPacketSequenceId() => clearField($_whichOneof(1));

  @$pb.TagNumber(6)
  $5.ClockSnapshot get clockSnapshot => $_getN(0);
  @$pb.TagNumber(6)
  set clockSnapshot($5.ClockSnapshot v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasClockSnapshot() => $_has(0);
  @$pb.TagNumber(6)
  void clearClockSnapshot() => clearField(6);
  @$pb.TagNumber(6)
  $5.ClockSnapshot ensureClockSnapshot() => $_ensure(0);

  @$pb.TagNumber(8)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(8)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(8)
  void clearTimestamp() => clearField(8);

  @$pb.TagNumber(10)
  $core.int get trustedPacketSequenceId => $_getIZ(2);
  @$pb.TagNumber(10)
  set trustedPacketSequenceId($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasTrustedPacketSequenceId() => $_has(2);
  @$pb.TagNumber(10)
  void clearTrustedPacketSequenceId() => clearField(10);

  @$pb.TagNumber(11)
  $6.TrackEvent get trackEvent => $_getN(3);
  @$pb.TagNumber(11)
  set trackEvent($6.TrackEvent v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasTrackEvent() => $_has(3);
  @$pb.TagNumber(11)
  void clearTrackEvent() => clearField(11);
  @$pb.TagNumber(11)
  $6.TrackEvent ensureTrackEvent() => $_ensure(3);

  @$pb.TagNumber(12)
  $7.InternedData get internedData => $_getN(4);
  @$pb.TagNumber(12)
  set internedData($7.InternedData v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasInternedData() => $_has(4);
  @$pb.TagNumber(12)
  void clearInternedData() => clearField(12);
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
  void clearSequenceFlags() => clearField(13);

  @$pb.TagNumber(58)
  $core.int get timestampClockId => $_getIZ(6);
  @$pb.TagNumber(58)
  set timestampClockId($core.int v) {
    $_setUnsignedInt32(6, v);
  }

  @$pb.TagNumber(58)
  $core.bool hasTimestampClockId() => $_has(6);
  @$pb.TagNumber(58)
  void clearTimestampClockId() => clearField(58);

  @$pb.TagNumber(60)
  $8.TrackDescriptor get trackDescriptor => $_getN(7);
  @$pb.TagNumber(60)
  set trackDescriptor($8.TrackDescriptor v) {
    setField(60, v);
  }

  @$pb.TagNumber(60)
  $core.bool hasTrackDescriptor() => $_has(7);
  @$pb.TagNumber(60)
  void clearTrackDescriptor() => clearField(60);
  @$pb.TagNumber(60)
  $8.TrackDescriptor ensureTrackDescriptor() => $_ensure(7);

  @$pb.TagNumber(66)
  $9.PerfSample get perfSample => $_getN(8);
  @$pb.TagNumber(66)
  set perfSample($9.PerfSample v) {
    setField(66, v);
  }

  @$pb.TagNumber(66)
  $core.bool hasPerfSample() => $_has(8);
  @$pb.TagNumber(66)
  void clearPerfSample() => clearField(66);
  @$pb.TagNumber(66)
  $9.PerfSample ensurePerfSample() => $_ensure(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
