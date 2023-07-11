// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/clock_snapshot.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use clockSnapshotDescriptor instead')
const ClockSnapshot$json = {
  '1': 'ClockSnapshot',
  '2': [
    {
      '1': 'clocks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.ClockSnapshot.Clock',
      '10': 'clocks'
    },
    {
      '1': 'primary_trace_clock',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.perfetto.protos.BuiltinClock',
      '10': 'primaryTraceClock'
    },
  ],
  '3': [ClockSnapshot_Clock$json],
};

@$core.Deprecated('Use clockSnapshotDescriptor instead')
const ClockSnapshot_Clock$json = {
  '1': 'Clock',
  '2': [
    {'1': 'clock_id', '3': 1, '4': 1, '5': 13, '10': 'clockId'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 4, '10': 'timestamp'},
  ],
};

/// Descriptor for `ClockSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clockSnapshotDescriptor = $convert.base64Decode(
    'Cg1DbG9ja1NuYXBzaG90EjwKBmNsb2NrcxgBIAMoCzIkLnBlcmZldHRvLnByb3Rvcy5DbG9ja1'
    'NuYXBzaG90LkNsb2NrUgZjbG9ja3MSTQoTcHJpbWFyeV90cmFjZV9jbG9jaxgCIAEoDjIdLnBl'
    'cmZldHRvLnByb3Rvcy5CdWlsdGluQ2xvY2tSEXByaW1hcnlUcmFjZUNsb2NrGkAKBUNsb2NrEh'
    'kKCGNsb2NrX2lkGAEgASgNUgdjbG9ja0lkEhwKCXRpbWVzdGFtcBgCIAEoBFIJdGltZXN0YW1w');
