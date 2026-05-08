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
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use trackEventDescriptor instead')
const TrackEvent$json = {
  '1': 'TrackEvent',
  '2': [
    {'1': 'category_iids', '3': 3, '4': 3, '5': 4, '10': 'categoryIids'},
    {'1': 'categories', '3': 22, '4': 3, '5': 9, '10': 'categories'},
    {'1': 'name_iid', '3': 10, '4': 1, '5': 4, '9': 0, '10': 'nameIid'},
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
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TYPE_SLICE_BEGIN', '2': 1},
    {'1': 'TYPE_SLICE_END', '2': 2},
    {'1': 'TYPE_INSTANT', '2': 3},
  ],
};

/// Descriptor for `TrackEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackEventDescriptor = $convert.base64Decode(
    'CgpUcmFja0V2ZW50EiMKDWNhdGVnb3J5X2lpZHMYAyADKARSDGNhdGVnb3J5SWlkcxIeCgpjYX'
    'RlZ29yaWVzGBYgAygJUgpjYXRlZ29yaWVzEhsKCG5hbWVfaWlkGAogASgESABSB25hbWVJaWQS'
    'FAoEbmFtZRgXIAEoCUgAUgRuYW1lEjQKBHR5cGUYCSABKA4yIC5wZXJmZXR0by5wcm90b3MuVH'
    'JhY2tFdmVudC5UeXBlUgR0eXBlEh0KCnRyYWNrX3V1aWQYCyABKARSCXRyYWNrVXVpZBIZCghm'
    'bG93X2lkcxgvIAMoBlIHZmxvd0lkcxIwChR0ZXJtaW5hdGluZ19mbG93X2lkcxgwIAMoBlISdG'
    'VybWluYXRpbmdGbG93SWRzEk0KEWRlYnVnX2Fubm90YXRpb25zGAQgAygLMiAucGVyZmV0dG8u'
    'cHJvdG9zLkRlYnVnQW5ub3RhdGlvblIQZGVidWdBbm5vdGF0aW9ucyJYCgRUeXBlEhQKEFRZUE'
    'VfVU5TUEVDSUZJRUQQABIUChBUWVBFX1NMSUNFX0JFR0lOEAESEgoOVFlQRV9TTElDRV9FTkQQ'
    'AhIQCgxUWVBFX0lOU1RBTlQQA0IMCgpuYW1lX2ZpZWxk');

@$core.Deprecated('Use eventCategoryDescriptor instead')
const EventCategory$json = {
  '1': 'EventCategory',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `EventCategory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventCategoryDescriptor = $convert.base64Decode(
    'Cg1FdmVudENhdGVnb3J5EhAKA2lpZBgBIAEoBFIDaWlkEhIKBG5hbWUYAiABKAlSBG5hbWU=');

@$core.Deprecated('Use eventNameDescriptor instead')
const EventName$json = {
  '1': 'EventName',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `EventName`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventNameDescriptor = $convert.base64Decode(
    'CglFdmVudE5hbWUSEAoDaWlkGAEgASgEUgNpaWQSEgoEbmFtZRgCIAEoCVIEbmFtZQ==');
