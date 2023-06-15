// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/common/builtin_clock.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

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
