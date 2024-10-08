//
//  Generated code. Do not modify.
//  source: profile.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use profileDescriptor instead')
const Profile$json = {
  '1': 'Profile',
  '2': [
    {
      '1': 'sample_type',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.ValueType',
      '10': 'sampleType'
    },
    {
      '1': 'sample',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Sample',
      '10': 'sample'
    },
    {
      '1': 'mapping',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Mapping',
      '10': 'mapping'
    },
    {
      '1': 'location',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Location',
      '10': 'location'
    },
    {
      '1': 'function',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Function',
      '10': 'function'
    },
    {'1': 'string_table', '3': 6, '4': 3, '5': 9, '10': 'stringTable'},
    {'1': 'drop_frames', '3': 7, '4': 1, '5': 3, '10': 'dropFrames'},
    {'1': 'keep_frames', '3': 8, '4': 1, '5': 3, '10': 'keepFrames'},
    {'1': 'time_nanos', '3': 9, '4': 1, '5': 3, '10': 'timeNanos'},
    {'1': 'duration_nanos', '3': 10, '4': 1, '5': 3, '10': 'durationNanos'},
    {
      '1': 'period_type',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.ValueType',
      '10': 'periodType'
    },
    {'1': 'period', '3': 12, '4': 1, '5': 3, '10': 'period'},
    {'1': 'comment', '3': 13, '4': 3, '5': 3, '10': 'comment'},
    {
      '1': 'default_sample_type',
      '3': 14,
      '4': 1,
      '5': 3,
      '10': 'defaultSampleType'
    },
  ],
};

/// Descriptor for `Profile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List profileDescriptor = $convert.base64Decode(
    'CgdQcm9maWxlElMKC3NhbXBsZV90eXBlGAEgAygLMjIucGVyZmV0dG8udGhpcmRfcGFydHkucG'
    'VyZnRvb2xzLnByb2ZpbGVzLlZhbHVlVHlwZVIKc2FtcGxlVHlwZRJHCgZzYW1wbGUYAiADKAsy'
    'Ly5wZXJmZXR0by50aGlyZF9wYXJ0eS5wZXJmdG9vbHMucHJvZmlsZXMuU2FtcGxlUgZzYW1wbG'
    'USSgoHbWFwcGluZxgDIAMoCzIwLnBlcmZldHRvLnRoaXJkX3BhcnR5LnBlcmZ0b29scy5wcm9m'
    'aWxlcy5NYXBwaW5nUgdtYXBwaW5nEk0KCGxvY2F0aW9uGAQgAygLMjEucGVyZmV0dG8udGhpcm'
    'RfcGFydHkucGVyZnRvb2xzLnByb2ZpbGVzLkxvY2F0aW9uUghsb2NhdGlvbhJNCghmdW5jdGlv'
    'bhgFIAMoCzIxLnBlcmZldHRvLnRoaXJkX3BhcnR5LnBlcmZ0b29scy5wcm9maWxlcy5GdW5jdG'
    'lvblIIZnVuY3Rpb24SIQoMc3RyaW5nX3RhYmxlGAYgAygJUgtzdHJpbmdUYWJsZRIfCgtkcm9w'
    'X2ZyYW1lcxgHIAEoA1IKZHJvcEZyYW1lcxIfCgtrZWVwX2ZyYW1lcxgIIAEoA1IKa2VlcEZyYW'
    '1lcxIdCgp0aW1lX25hbm9zGAkgASgDUgl0aW1lTmFub3MSJQoOZHVyYXRpb25fbmFub3MYCiAB'
    'KANSDWR1cmF0aW9uTmFub3MSUwoLcGVyaW9kX3R5cGUYCyABKAsyMi5wZXJmZXR0by50aGlyZF'
    '9wYXJ0eS5wZXJmdG9vbHMucHJvZmlsZXMuVmFsdWVUeXBlUgpwZXJpb2RUeXBlEhYKBnBlcmlv'
    'ZBgMIAEoA1IGcGVyaW9kEhgKB2NvbW1lbnQYDSADKANSB2NvbW1lbnQSLgoTZGVmYXVsdF9zYW'
    '1wbGVfdHlwZRgOIAEoA1IRZGVmYXVsdFNhbXBsZVR5cGU=');

@$core.Deprecated('Use valueTypeDescriptor instead')
const ValueType$json = {
  '1': 'ValueType',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 3, '10': 'type'},
    {'1': 'unit', '3': 2, '4': 1, '5': 3, '10': 'unit'},
  ],
};

/// Descriptor for `ValueType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueTypeDescriptor = $convert.base64Decode(
    'CglWYWx1ZVR5cGUSEgoEdHlwZRgBIAEoA1IEdHlwZRISCgR1bml0GAIgASgDUgR1bml0');

@$core.Deprecated('Use sampleDescriptor instead')
const Sample$json = {
  '1': 'Sample',
  '2': [
    {'1': 'location_id', '3': 1, '4': 3, '5': 4, '10': 'locationId'},
    {'1': 'value', '3': 2, '4': 3, '5': 3, '10': 'value'},
    {
      '1': 'label',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Label',
      '10': 'label'
    },
  ],
};

/// Descriptor for `Sample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sampleDescriptor = $convert.base64Decode(
    'CgZTYW1wbGUSHwoLbG9jYXRpb25faWQYASADKARSCmxvY2F0aW9uSWQSFAoFdmFsdWUYAiADKA'
    'NSBXZhbHVlEkQKBWxhYmVsGAMgAygLMi4ucGVyZmV0dG8udGhpcmRfcGFydHkucGVyZnRvb2xz'
    'LnByb2ZpbGVzLkxhYmVsUgVsYWJlbA==');

@$core.Deprecated('Use labelDescriptor instead')
const Label$json = {
  '1': 'Label',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 3, '10': 'key'},
    {'1': 'str', '3': 2, '4': 1, '5': 3, '10': 'str'},
    {'1': 'num', '3': 3, '4': 1, '5': 3, '10': 'num'},
    {'1': 'num_unit', '3': 4, '4': 1, '5': 3, '10': 'numUnit'},
  ],
};

/// Descriptor for `Label`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List labelDescriptor = $convert.base64Decode(
    'CgVMYWJlbBIQCgNrZXkYASABKANSA2tleRIQCgNzdHIYAiABKANSA3N0chIQCgNudW0YAyABKA'
    'NSA251bRIZCghudW1fdW5pdBgEIAEoA1IHbnVtVW5pdA==');

@$core.Deprecated('Use mappingDescriptor instead')
const Mapping$json = {
  '1': 'Mapping',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'memory_start', '3': 2, '4': 1, '5': 4, '10': 'memoryStart'},
    {'1': 'memory_limit', '3': 3, '4': 1, '5': 4, '10': 'memoryLimit'},
    {'1': 'file_offset', '3': 4, '4': 1, '5': 4, '10': 'fileOffset'},
    {'1': 'filename', '3': 5, '4': 1, '5': 3, '10': 'filename'},
    {'1': 'build_id', '3': 6, '4': 1, '5': 3, '10': 'buildId'},
    {'1': 'has_functions', '3': 7, '4': 1, '5': 8, '10': 'hasFunctions'},
    {'1': 'has_filenames', '3': 8, '4': 1, '5': 8, '10': 'hasFilenames'},
    {'1': 'has_line_numbers', '3': 9, '4': 1, '5': 8, '10': 'hasLineNumbers'},
    {
      '1': 'has_inline_frames',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'hasInlineFrames'
    },
  ],
};

/// Descriptor for `Mapping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mappingDescriptor = $convert.base64Decode(
    'CgdNYXBwaW5nEg4KAmlkGAEgASgEUgJpZBIhCgxtZW1vcnlfc3RhcnQYAiABKARSC21lbW9yeV'
    'N0YXJ0EiEKDG1lbW9yeV9saW1pdBgDIAEoBFILbWVtb3J5TGltaXQSHwoLZmlsZV9vZmZzZXQY'
    'BCABKARSCmZpbGVPZmZzZXQSGgoIZmlsZW5hbWUYBSABKANSCGZpbGVuYW1lEhkKCGJ1aWxkX2'
    'lkGAYgASgDUgdidWlsZElkEiMKDWhhc19mdW5jdGlvbnMYByABKAhSDGhhc0Z1bmN0aW9ucxIj'
    'Cg1oYXNfZmlsZW5hbWVzGAggASgIUgxoYXNGaWxlbmFtZXMSKAoQaGFzX2xpbmVfbnVtYmVycx'
    'gJIAEoCFIOaGFzTGluZU51bWJlcnMSKgoRaGFzX2lubGluZV9mcmFtZXMYCiABKAhSD2hhc0lu'
    'bGluZUZyYW1lcw==');

@$core.Deprecated('Use locationDescriptor instead')
const Location$json = {
  '1': 'Location',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'mapping_id', '3': 2, '4': 1, '5': 4, '10': 'mappingId'},
    {'1': 'address', '3': 3, '4': 1, '5': 4, '10': 'address'},
    {
      '1': 'line',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.perfetto.third_party.perftools.profiles.Line',
      '10': 'line'
    },
    {'1': 'is_folded', '3': 5, '4': 1, '5': 8, '10': 'isFolded'},
  ],
};

/// Descriptor for `Location`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationDescriptor = $convert.base64Decode(
    'CghMb2NhdGlvbhIOCgJpZBgBIAEoBFICaWQSHQoKbWFwcGluZ19pZBgCIAEoBFIJbWFwcGluZ0'
    'lkEhgKB2FkZHJlc3MYAyABKARSB2FkZHJlc3MSQQoEbGluZRgEIAMoCzItLnBlcmZldHRvLnRo'
    'aXJkX3BhcnR5LnBlcmZ0b29scy5wcm9maWxlcy5MaW5lUgRsaW5lEhsKCWlzX2ZvbGRlZBgFIA'
    'EoCFIIaXNGb2xkZWQ=');

@$core.Deprecated('Use lineDescriptor instead')
const Line$json = {
  '1': 'Line',
  '2': [
    {'1': 'function_id', '3': 1, '4': 1, '5': 4, '10': 'functionId'},
    {'1': 'line', '3': 2, '4': 1, '5': 3, '10': 'line'},
  ],
};

/// Descriptor for `Line`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lineDescriptor = $convert.base64Decode(
    'CgRMaW5lEh8KC2Z1bmN0aW9uX2lkGAEgASgEUgpmdW5jdGlvbklkEhIKBGxpbmUYAiABKANSBG'
    'xpbmU=');

@$core.Deprecated('Use function_Descriptor instead')
const Function_$json = {
  '1': 'Function',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 3, '10': 'name'},
    {'1': 'system_name', '3': 3, '4': 1, '5': 3, '10': 'systemName'},
    {'1': 'filename', '3': 4, '4': 1, '5': 3, '10': 'filename'},
    {'1': 'start_line', '3': 5, '4': 1, '5': 3, '10': 'startLine'},
  ],
};

/// Descriptor for `Function`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List function_Descriptor = $convert.base64Decode(
    'CghGdW5jdGlvbhIOCgJpZBgBIAEoBFICaWQSEgoEbmFtZRgCIAEoA1IEbmFtZRIfCgtzeXN0ZW'
    '1fbmFtZRgDIAEoA1IKc3lzdGVtTmFtZRIaCghmaWxlbmFtZRgEIAEoA1IIZmlsZW5hbWUSHQoK'
    'c3RhcnRfbGluZRgFIAEoA1IJc3RhcnRMaW5l');
