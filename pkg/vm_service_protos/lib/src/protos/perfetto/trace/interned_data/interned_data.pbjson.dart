// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/interned_data/interned_data.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use internedDataDescriptor instead')
const InternedData$json = {
  '1': 'InternedData',
  '2': [
    {
      '1': 'mapping_paths',
      '3': 17,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.InternedString',
      '10': 'mappingPaths'
    },
    {
      '1': 'function_names',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.InternedString',
      '10': 'functionNames'
    },
    {
      '1': 'mappings',
      '3': 19,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.Mapping',
      '10': 'mappings'
    },
    {
      '1': 'frames',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.Frame',
      '10': 'frames'
    },
    {
      '1': 'callstacks',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.Callstack',
      '10': 'callstacks'
    },
  ],
};

/// Descriptor for `InternedData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List internedDataDescriptor = $convert.base64Decode(
    'CgxJbnRlcm5lZERhdGESRAoNbWFwcGluZ19wYXRocxgRIAMoCzIfLnBlcmZldHRvLnByb3Rvcy'
    '5JbnRlcm5lZFN0cmluZ1IMbWFwcGluZ1BhdGhzEkYKDmZ1bmN0aW9uX25hbWVzGAUgAygLMh8u'
    'cGVyZmV0dG8ucHJvdG9zLkludGVybmVkU3RyaW5nUg1mdW5jdGlvbk5hbWVzEjQKCG1hcHBpbm'
    'dzGBMgAygLMhgucGVyZmV0dG8ucHJvdG9zLk1hcHBpbmdSCG1hcHBpbmdzEi4KBmZyYW1lcxgG'
    'IAMoCzIWLnBlcmZldHRvLnByb3Rvcy5GcmFtZVIGZnJhbWVzEjoKCmNhbGxzdGFja3MYByADKA'
    'syGi5wZXJmZXR0by5wcm90b3MuQ2FsbHN0YWNrUgpjYWxsc3RhY2tz');
