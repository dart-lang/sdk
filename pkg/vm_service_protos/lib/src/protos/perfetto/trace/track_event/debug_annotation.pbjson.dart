// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/debug_annotation.proto.

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

@$core.Deprecated('Use debugAnnotationDescriptor instead')
const DebugAnnotation$json = {
  '1': 'DebugAnnotation',
  '2': [
    {'1': 'name_iid', '3': 1, '4': 1, '5': 4, '9': 0, '10': 'nameIid'},
    {'1': 'name', '3': 10, '4': 1, '5': 9, '9': 0, '10': 'name'},
    {
      '1': 'legacy_json_value',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'legacyJsonValue'
    },
    {'1': 'string_value', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'stringValue'},
    {
      '1': 'string_value_iid',
      '3': 17,
      '4': 1,
      '5': 4,
      '9': 1,
      '10': 'stringValueIid'
    },
  ],
  '8': [
    {'1': 'name_field'},
    {'1': 'value'},
  ],
};

/// Descriptor for `DebugAnnotation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugAnnotationDescriptor = $convert.base64Decode(
    'Cg9EZWJ1Z0Fubm90YXRpb24SGwoIbmFtZV9paWQYASABKARIAFIHbmFtZUlpZBIUCgRuYW1lGA'
    'ogASgJSABSBG5hbWUSLAoRbGVnYWN5X2pzb25fdmFsdWUYCSABKAlIAVIPbGVnYWN5SnNvblZh'
    'bHVlEiMKDHN0cmluZ192YWx1ZRgGIAEoCUgBUgtzdHJpbmdWYWx1ZRIqChBzdHJpbmdfdmFsdW'
    'VfaWlkGBEgASgESAFSDnN0cmluZ1ZhbHVlSWlkQgwKCm5hbWVfZmllbGRCBwoFdmFsdWU=');

@$core.Deprecated('Use debugAnnotationNameDescriptor instead')
const DebugAnnotationName$json = {
  '1': 'DebugAnnotationName',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DebugAnnotationName`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugAnnotationNameDescriptor = $convert.base64Decode(
    'ChNEZWJ1Z0Fubm90YXRpb25OYW1lEhAKA2lpZBgBIAEoBFIDaWlkEhIKBG5hbWUYAiABKAlSBG'
    '5hbWU=');
