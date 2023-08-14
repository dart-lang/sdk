// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/trace.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use traceDescriptor instead')
const Trace$json = {
  '1': 'Trace',
  '2': [
    {
      '1': 'packet',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.TracePacket',
      '10': 'packet'
    },
  ],
};

/// Descriptor for `Trace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List traceDescriptor = $convert.base64Decode(
    'CgVUcmFjZRI0CgZwYWNrZXQYASADKAsyHC5wZXJmZXR0by5wcm90b3MuVHJhY2VQYWNrZXRSBn'
    'BhY2tldA==');
