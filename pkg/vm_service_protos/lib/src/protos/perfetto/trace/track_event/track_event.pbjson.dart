// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/track_event.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use trackEventDescriptor instead')
const TrackEvent$json = {
  '1': 'TrackEvent',
  '2': [
    {'1': 'categories', '3': 22, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'name', '3': 23, '4': 1, '5': 9, '9': 0, '10': 'name'},
    {
      '1': 'type',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.perfetto.protos.TrackEvent.Type',
      '10': 'type'
    },
    {'1': 'track_uuid', '3': 11, '4': 1, '5': 4, '10': 'trackUuid'},
    {'1': 'flow_ids', '3': 47, '4': 3, '5': 6, '10': 'flowIds'},
    {
      '1': 'terminating_flow_ids',
      '3': 48,
      '4': 3,
      '5': 6,
      '10': 'terminatingFlowIds'
    },
    {
      '1': 'debug_annotations',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.DebugAnnotation',
      '10': 'debugAnnotations'
    },
  ],
  '4': [TrackEvent_Type$json],
  '8': [
    {'1': 'name_field'},
  ],
};

@$core.Deprecated('Use trackEventDescriptor instead')
const TrackEvent_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_SLICE_BEGIN', '2': 1},
    {'1': 'TYPE_SLICE_END', '2': 2},
    {'1': 'TYPE_INSTANT', '2': 3},
  ],
};

/// Descriptor for `TrackEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackEventDescriptor = $convert.base64Decode(
    'CgpUcmFja0V2ZW50Eh4KCmNhdGVnb3JpZXMYFiADKAlSCmNhdGVnb3JpZXMSFAoEbmFtZRgXIA'
    'EoCUgAUgRuYW1lEjQKBHR5cGUYCSABKA4yIC5wZXJmZXR0by5wcm90b3MuVHJhY2tFdmVudC5U'
    'eXBlUgR0eXBlEh0KCnRyYWNrX3V1aWQYCyABKARSCXRyYWNrVXVpZBIZCghmbG93X2lkcxgvIA'
    'MoBlIHZmxvd0lkcxIwChR0ZXJtaW5hdGluZ19mbG93X2lkcxgwIAMoBlISdGVybWluYXRpbmdG'
    'bG93SWRzEk0KEWRlYnVnX2Fubm90YXRpb25zGAQgAygLMiAucGVyZmV0dG8ucHJvdG9zLkRlYn'
    'VnQW5ub3RhdGlvblIQZGVidWdBbm5vdGF0aW9ucyJCCgRUeXBlEhQKEFRZUEVfU0xJQ0VfQkVH'
    'SU4QARISCg5UWVBFX1NMSUNFX0VORBACEhAKDFRZUEVfSU5TVEFOVBADQgwKCm5hbWVfZmllbG'
    'Q=');
