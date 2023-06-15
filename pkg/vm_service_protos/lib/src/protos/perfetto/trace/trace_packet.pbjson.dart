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

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use tracePacketDescriptor instead')
const TracePacket$json = {
  '1': 'TracePacket',
  '2': [
    {'1': 'timestamp', '3': 8, '4': 1, '5': 4, '10': 'timestamp'},
    {
      '1': 'timestamp_clock_id',
      '3': 58,
      '4': 1,
      '5': 13,
      '10': 'timestampClockId'
    },
    {
      '1': 'clock_snapshot',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.ClockSnapshot',
      '9': 0,
      '10': 'clockSnapshot'
    },
    {
      '1': 'track_event',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.TrackEvent',
      '9': 0,
      '10': 'trackEvent'
    },
    {
      '1': 'track_descriptor',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.TrackDescriptor',
      '9': 0,
      '10': 'trackDescriptor'
    },
    {
      '1': 'perf_sample',
      '3': 66,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.PerfSample',
      '9': 0,
      '10': 'perfSample'
    },
    {
      '1': 'trusted_packet_sequence_id',
      '3': 10,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'trustedPacketSequenceId'
    },
    {
      '1': 'interned_data',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.InternedData',
      '10': 'internedData'
    },
    {'1': 'sequence_flags', '3': 13, '4': 1, '5': 13, '10': 'sequenceFlags'},
  ],
  '4': [TracePacket_SequenceFlags$json],
  '8': [
    {'1': 'data'},
    {'1': 'optional_trusted_packet_sequence_id'},
  ],
};

@$core.Deprecated('Use tracePacketDescriptor instead')
const TracePacket_SequenceFlags$json = {
  '1': 'SequenceFlags',
  '2': [
    {'1': 'SEQ_UNSPECIFIED', '2': 0},
    {'1': 'SEQ_INCREMENTAL_STATE_CLEARED', '2': 1},
    {'1': 'SEQ_NEEDS_INCREMENTAL_STATE', '2': 2},
  ],
};

/// Descriptor for `TracePacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tracePacketDescriptor = $convert.base64Decode(
    'CgtUcmFjZVBhY2tldBIcCgl0aW1lc3RhbXAYCCABKARSCXRpbWVzdGFtcBIsChJ0aW1lc3RhbX'
    'BfY2xvY2tfaWQYOiABKA1SEHRpbWVzdGFtcENsb2NrSWQSRwoOY2xvY2tfc25hcHNob3QYBiAB'
    'KAsyHi5wZXJmZXR0by5wcm90b3MuQ2xvY2tTbmFwc2hvdEgAUg1jbG9ja1NuYXBzaG90Ej4KC3'
    'RyYWNrX2V2ZW50GAsgASgLMhsucGVyZmV0dG8ucHJvdG9zLlRyYWNrRXZlbnRIAFIKdHJhY2tF'
    'dmVudBJNChB0cmFja19kZXNjcmlwdG9yGDwgASgLMiAucGVyZmV0dG8ucHJvdG9zLlRyYWNrRG'
    'VzY3JpcHRvckgAUg90cmFja0Rlc2NyaXB0b3ISPgoLcGVyZl9zYW1wbGUYQiABKAsyGy5wZXJm'
    'ZXR0by5wcm90b3MuUGVyZlNhbXBsZUgAUgpwZXJmU2FtcGxlEj0KGnRydXN0ZWRfcGFja2V0X3'
    'NlcXVlbmNlX2lkGAogASgNSAFSF3RydXN0ZWRQYWNrZXRTZXF1ZW5jZUlkEkIKDWludGVybmVk'
    'X2RhdGEYDCABKAsyHS5wZXJmZXR0by5wcm90b3MuSW50ZXJuZWREYXRhUgxpbnRlcm5lZERhdG'
    'ESJQoOc2VxdWVuY2VfZmxhZ3MYDSABKA1SDXNlcXVlbmNlRmxhZ3MiaAoNU2VxdWVuY2VGbGFn'
    'cxITCg9TRVFfVU5TUEVDSUZJRUQQABIhCh1TRVFfSU5DUkVNRU5UQUxfU1RBVEVfQ0xFQVJFRB'
    'ABEh8KG1NFUV9ORUVEU19JTkNSRU1FTlRBTF9TVEFURRACQgYKBGRhdGFCJQojb3B0aW9uYWxf'
    'dHJ1c3RlZF9wYWNrZXRfc2VxdWVuY2VfaWQ=');
