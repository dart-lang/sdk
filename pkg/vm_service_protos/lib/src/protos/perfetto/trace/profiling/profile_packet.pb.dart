// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/profiling/profile_packet.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

///  Packet emitted by the traced_perf sampling performance profiler, which
///  gathers data via the perf_event_open syscall. Each packet contains an
///  individual sample with a counter value, and optionally a
///  callstack.
///
///  Timestamps are within the root packet. The config can specify the clock, or
///  the implementation will default to CLOCK_MONOTONIC_RAW. Within the Android R
///  timeframe, the default was CLOCK_BOOTTIME.
///
///  There are several distinct views of this message:
///  * indication of kernel buffer data loss (kernel_records_lost set)
///  * indication of skipped samples (sample_skipped_reason set)
///  * notable event in the sampling implementation (producer_event set)
///  * normal sample (timebase_count set, typically also callstack_iid)
class PerfSample extends $pb.GeneratedMessage {
  factory PerfSample({
    $core.int? cpu,
    $core.int? pid,
    $core.int? tid,
    $fixnum.Int64? callstackIid,
  }) {
    final $result = create();
    if (cpu != null) {
      $result.cpu = cpu;
    }
    if (pid != null) {
      $result.pid = pid;
    }
    if (tid != null) {
      $result.tid = tid;
    }
    if (callstackIid != null) {
      $result.callstackIid = callstackIid;
    }
    return $result;
  }
  PerfSample._() : super();
  factory PerfSample.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PerfSample.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PerfSample',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'cpu', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pid', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'tid', $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'callstackIid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PerfSample clone() => PerfSample()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PerfSample copyWith(void Function(PerfSample) updates) =>
      super.copyWith((message) => updates(message as PerfSample)) as PerfSample;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PerfSample create() => PerfSample._();
  PerfSample createEmptyInstance() => create();
  static $pb.PbList<PerfSample> createRepeated() => $pb.PbList<PerfSample>();
  @$core.pragma('dart2js:noInline')
  static PerfSample getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PerfSample>(create);
  static PerfSample? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cpu => $_getIZ(0);
  @$pb.TagNumber(1)
  set cpu($core.int v) {
    $_setUnsignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCpu() => $_has(0);
  @$pb.TagNumber(1)
  void clearCpu() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get pid => $_getIZ(1);
  @$pb.TagNumber(2)
  set pid($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPid() => $_has(1);
  @$pb.TagNumber(2)
  void clearPid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get tid => $_getIZ(2);
  @$pb.TagNumber(3)
  set tid($core.int v) {
    $_setUnsignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTid() => $_has(2);
  @$pb.TagNumber(3)
  void clearTid() => $_clearField(3);

  /// Unwound callstack. Might be partial, in which case a synthetic "error"
  /// frame is appended, and |unwind_error| is set accordingly.
  @$pb.TagNumber(4)
  $fixnum.Int64 get callstackIid => $_getI64(3);
  @$pb.TagNumber(4)
  set callstackIid($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCallstackIid() => $_has(3);
  @$pb.TagNumber(4)
  void clearCallstackIid() => $_clearField(4);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
