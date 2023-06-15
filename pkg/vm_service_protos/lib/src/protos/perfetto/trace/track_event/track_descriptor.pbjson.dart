// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/track_descriptor.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use trackDescriptorDescriptor instead')
const TrackDescriptor$json = {
  '1': 'TrackDescriptor',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 4, '10': 'uuid'},
    {'1': 'parent_uuid', '3': 5, '4': 1, '5': 4, '10': 'parentUuid'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'process',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.ProcessDescriptor',
      '10': 'process'
    },
    {
      '1': 'thread',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.perfetto.protos.ThreadDescriptor',
      '10': 'thread'
    },
  ],
};

/// Descriptor for `TrackDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackDescriptorDescriptor = $convert.base64Decode(
    'Cg9UcmFja0Rlc2NyaXB0b3ISEgoEdXVpZBgBIAEoBFIEdXVpZBIfCgtwYXJlbnRfdXVpZBgFIA'
    'EoBFIKcGFyZW50VXVpZBISCgRuYW1lGAIgASgJUgRuYW1lEjwKB3Byb2Nlc3MYAyABKAsyIi5w'
    'ZXJmZXR0by5wcm90b3MuUHJvY2Vzc0Rlc2NyaXB0b3JSB3Byb2Nlc3MSOQoGdGhyZWFkGAQgAS'
    'gLMiEucGVyZmV0dG8ucHJvdG9zLlRocmVhZERlc2NyaXB0b3JSBnRocmVhZA==');
