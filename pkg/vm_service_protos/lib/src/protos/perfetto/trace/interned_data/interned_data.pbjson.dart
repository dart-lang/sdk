// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/interned_data/interned_data.proto.

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

@$core.Deprecated('Use internedDataDescriptor instead')
const InternedData$json = {
  '1': 'InternedData',
  '2': [
    {
      '1': 'event_categories',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.EventCategory',
      '10': 'eventCategories'
    },
    {
      '1': 'event_names',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.EventName',
      '10': 'eventNames'
    },
    {
      '1': 'debug_annotation_names',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.DebugAnnotationName',
      '10': 'debugAnnotationNames'
    },
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
    {
      '1': 'debug_annotation_string_values',
      '3': 29,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.InternedString',
      '10': 'debugAnnotationStringValues'
    },
  ],
};

/// Descriptor for `InternedData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List internedDataDescriptor = $convert.base64Decode(
    'CgxJbnRlcm5lZERhdGESSQoQZXZlbnRfY2F0ZWdvcmllcxgBIAMoCzIeLnBlcmZldHRvLnByb3'
    'Rvcy5FdmVudENhdGVnb3J5Ug9ldmVudENhdGVnb3JpZXMSOwoLZXZlbnRfbmFtZXMYAiADKAsy'
    'Gi5wZXJmZXR0by5wcm90b3MuRXZlbnROYW1lUgpldmVudE5hbWVzEloKFmRlYnVnX2Fubm90YX'
    'Rpb25fbmFtZXMYAyADKAsyJC5wZXJmZXR0by5wcm90b3MuRGVidWdBbm5vdGF0aW9uTmFtZVIU'
    'ZGVidWdBbm5vdGF0aW9uTmFtZXMSRAoNbWFwcGluZ19wYXRocxgRIAMoCzIfLnBlcmZldHRvLn'
    'Byb3Rvcy5JbnRlcm5lZFN0cmluZ1IMbWFwcGluZ1BhdGhzEkYKDmZ1bmN0aW9uX25hbWVzGAUg'
    'AygLMh8ucGVyZmV0dG8ucHJvdG9zLkludGVybmVkU3RyaW5nUg1mdW5jdGlvbk5hbWVzEjQKCG'
    '1hcHBpbmdzGBMgAygLMhgucGVyZmV0dG8ucHJvdG9zLk1hcHBpbmdSCG1hcHBpbmdzEi4KBmZy'
    'YW1lcxgGIAMoCzIWLnBlcmZldHRvLnByb3Rvcy5GcmFtZVIGZnJhbWVzEjoKCmNhbGxzdGFja3'
    'MYByADKAsyGi5wZXJmZXR0by5wcm90b3MuQ2FsbHN0YWNrUgpjYWxsc3RhY2tzEmQKHmRlYnVn'
    'X2Fubm90YXRpb25fc3RyaW5nX3ZhbHVlcxgdIAMoCzIfLnBlcmZldHRvLnByb3Rvcy5JbnRlcm'
    '5lZFN0cmluZ1IbZGVidWdBbm5vdGF0aW9uU3RyaW5nVmFsdWVz');
