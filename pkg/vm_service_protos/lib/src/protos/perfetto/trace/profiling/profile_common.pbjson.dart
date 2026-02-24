// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/profiling/profile_common.proto.

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

@$core.Deprecated('Use internedStringDescriptor instead')
const InternedString$json = {
  '1': 'InternedString',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'str', '3': 2, '4': 1, '5': 12, '10': 'str'},
  ],
};

/// Descriptor for `InternedString`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List internedStringDescriptor = $convert.base64Decode(
    'Cg5JbnRlcm5lZFN0cmluZxIQCgNpaWQYASABKARSA2lpZBIQCgNzdHIYAiABKAxSA3N0cg==');

@$core.Deprecated('Use mappingDescriptor instead')
const Mapping$json = {
  '1': 'Mapping',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'start_offset', '3': 3, '4': 1, '5': 4, '10': 'startOffset'},
    {'1': 'start', '3': 4, '4': 1, '5': 4, '10': 'start'},
    {'1': 'end', '3': 5, '4': 1, '5': 4, '10': 'end'},
    {'1': 'path_string_ids', '3': 7, '4': 3, '5': 4, '10': 'pathStringIds'},
  ],
};

/// Descriptor for `Mapping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mappingDescriptor = $convert.base64Decode(
    'CgdNYXBwaW5nEhAKA2lpZBgBIAEoBFIDaWlkEiEKDHN0YXJ0X29mZnNldBgDIAEoBFILc3Rhcn'
    'RPZmZzZXQSFAoFc3RhcnQYBCABKARSBXN0YXJ0EhAKA2VuZBgFIAEoBFIDZW5kEiYKD3BhdGhf'
    'c3RyaW5nX2lkcxgHIAMoBFINcGF0aFN0cmluZ0lkcw==');

@$core.Deprecated('Use frameDescriptor instead')
const Frame$json = {
  '1': 'Frame',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'function_name_id', '3': 2, '4': 1, '5': 4, '10': 'functionNameId'},
    {'1': 'mapping_id', '3': 3, '4': 1, '5': 4, '10': 'mappingId'},
    {'1': 'rel_pc', '3': 4, '4': 1, '5': 4, '10': 'relPc'},
  ],
};

/// Descriptor for `Frame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List frameDescriptor = $convert.base64Decode(
    'CgVGcmFtZRIQCgNpaWQYASABKARSA2lpZBIoChBmdW5jdGlvbl9uYW1lX2lkGAIgASgEUg5mdW'
    '5jdGlvbk5hbWVJZBIdCgptYXBwaW5nX2lkGAMgASgEUgltYXBwaW5nSWQSFQoGcmVsX3BjGAQg'
    'ASgEUgVyZWxQYw==');

@$core.Deprecated('Use callstackDescriptor instead')
const Callstack$json = {
  '1': 'Callstack',
  '2': [
    {'1': 'iid', '3': 1, '4': 1, '5': 4, '10': 'iid'},
    {'1': 'frame_ids', '3': 2, '4': 3, '5': 4, '10': 'frameIds'},
  ],
};

/// Descriptor for `Callstack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callstackDescriptor = $convert.base64Decode(
    'CglDYWxsc3RhY2sSEAoDaWlkGAEgASgEUgNpaWQSGwoJZnJhbWVfaWRzGAIgAygEUghmcmFtZU'
    'lkcw==');
