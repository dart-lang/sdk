// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/debug_annotation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use debugAnnotationDescriptor instead')
const DebugAnnotation$json = {
  '1': 'DebugAnnotation',
  '2': [
    {'1': 'name', '3': 10, '4': 1, '5': 9, '9': 0, '10': 'name'},
    {'1': 'string_value', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'stringValue'},
    {
      '1': 'legacy_json_value',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'legacyJsonValue'
    },
  ],
  '8': [
    {'1': 'name_field'},
    {'1': 'value'},
  ],
};

/// Descriptor for `DebugAnnotation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugAnnotationDescriptor = $convert.base64Decode(
    'Cg9EZWJ1Z0Fubm90YXRpb24SFAoEbmFtZRgKIAEoCUgAUgRuYW1lEiMKDHN0cmluZ192YWx1ZR'
    'gGIAEoCUgBUgtzdHJpbmdWYWx1ZRIsChFsZWdhY3lfanNvbl92YWx1ZRgJIAEoCUgBUg9sZWdh'
    'Y3lKc29uVmFsdWVCDAoKbmFtZV9maWVsZEIHCgV2YWx1ZQ==');
