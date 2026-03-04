// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/trace_packet.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

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
      '1': 'module_symbols',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.ModuleSymbols',
      '9': 0,
      '10': 'moduleSymbols'
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
    'VzY3JpcHRvckgAUg90cmFja0Rlc2NyaXB0b3ISRwoObW9kdWxlX3N5bWJvbHMYPSABKAsyHi5w'
    'ZXJmZXR0by5wcm90b3MuTW9kdWxlU3ltYm9sc0gAUg1tb2R1bGVTeW1ib2xzEj4KC3BlcmZfc2'
    'FtcGxlGEIgASgLMhsucGVyZmV0dG8ucHJvdG9zLlBlcmZTYW1wbGVIAFIKcGVyZlNhbXBsZRI9'
    'Chp0cnVzdGVkX3BhY2tldF9zZXF1ZW5jZV9pZBgKIAEoDUgBUhd0cnVzdGVkUGFja2V0U2VxdW'
    'VuY2VJZBJCCg1pbnRlcm5lZF9kYXRhGAwgASgLMh0ucGVyZmV0dG8ucHJvdG9zLkludGVybmVk'
    'RGF0YVIMaW50ZXJuZWREYXRhEiUKDnNlcXVlbmNlX2ZsYWdzGA0gASgNUg1zZXF1ZW5jZUZsYW'
    'dzImgKDVNlcXVlbmNlRmxhZ3MSEwoPU0VRX1VOU1BFQ0lGSUVEEAASIQodU0VRX0lOQ1JFTUVO'
    'VEFMX1NUQVRFX0NMRUFSRUQQARIfChtTRVFfTkVFRFNfSU5DUkVNRU5UQUxfU1RBVEUQAkIGCg'
    'RkYXRhQiUKI29wdGlvbmFsX3RydXN0ZWRfcGFja2V0X3NlcXVlbmNlX2lk');
