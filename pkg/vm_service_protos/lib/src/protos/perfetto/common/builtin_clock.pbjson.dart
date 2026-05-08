// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/common/builtin_clock.proto.

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

@$core.Deprecated('Use builtinClockDescriptor instead')
const BuiltinClock$json = {
  '1': 'BuiltinClock',
  '2': [
    {'1': 'BUILTIN_CLOCK_MONOTONIC', '2': 3},
  ],
};

/// Descriptor for `BuiltinClock`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List builtinClockDescriptor = $convert.base64Decode(
    'CgxCdWlsdGluQ2xvY2sSGwoXQlVJTFRJTl9DTE9DS19NT05PVE9OSUMQAw==');
