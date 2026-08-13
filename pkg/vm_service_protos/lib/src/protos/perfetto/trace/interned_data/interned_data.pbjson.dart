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
      '1': 'build_ids',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.perfetto.protos.InternedString',
      '10': 'buildIds'
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
    'ZGVidWdBbm5vdGF0aW9uTmFtZXMSPAoJYnVpbGRfaWRzGBAgAygLMh8ucGVyZmV0dG8ucHJvdG'
    '9zLkludGVybmVkU3RyaW5nUghidWlsZElkcxJECg1tYXBwaW5nX3BhdGhzGBEgAygLMh8ucGVy'
    'ZmV0dG8ucHJvdG9zLkludGVybmVkU3RyaW5nUgxtYXBwaW5nUGF0aHMSRgoOZnVuY3Rpb25fbm'
    'FtZXMYBSADKAsyHy5wZXJmZXR0by5wcm90b3MuSW50ZXJuZWRTdHJpbmdSDWZ1bmN0aW9uTmFt'
    'ZXMSNAoIbWFwcGluZ3MYEyADKAsyGC5wZXJmZXR0by5wcm90b3MuTWFwcGluZ1IIbWFwcGluZ3'
    'MSLgoGZnJhbWVzGAYgAygLMhYucGVyZmV0dG8ucHJvdG9zLkZyYW1lUgZmcmFtZXMSOgoKY2Fs'
    'bHN0YWNrcxgHIAMoCzIaLnBlcmZldHRvLnByb3Rvcy5DYWxsc3RhY2tSCmNhbGxzdGFja3MSZA'
    'oeZGVidWdfYW5ub3RhdGlvbl9zdHJpbmdfdmFsdWVzGB0gAygLMh8ucGVyZmV0dG8ucHJvdG9z'
    'LkludGVybmVkU3RyaW5nUhtkZWJ1Z0Fubm90YXRpb25TdHJpbmdWYWx1ZXM=');
