// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/thread_descriptor.proto.

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

@$core.Deprecated('Use threadDescriptorDescriptor instead')
const ThreadDescriptor$json = {
  '1': 'ThreadDescriptor',
  '2': [
    {'1': 'pid', '3': 1, '4': 1, '5': 5, '10': 'pid'},
    {'1': 'tid', '3': 2, '4': 1, '5': 5, '10': 'tid'},
    {'1': 'thread_name', '3': 5, '4': 1, '5': 9, '10': 'threadName'},
  ],
};

/// Descriptor for `ThreadDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List threadDescriptorDescriptor = $convert.base64Decode(
    'ChBUaHJlYWREZXNjcmlwdG9yEhAKA3BpZBgBIAEoBVIDcGlkEhAKA3RpZBgCIAEoBVIDdGlkEh'
    '8KC3RocmVhZF9uYW1lGAUgASgJUgp0aHJlYWROYW1l');
