// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/track_event.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TrackEvent_Type extends $pb.ProtobufEnum {
  static const TrackEvent_Type TYPE_SLICE_BEGIN =
      TrackEvent_Type._(1, _omitEnumNames ? '' : 'TYPE_SLICE_BEGIN');
  static const TrackEvent_Type TYPE_SLICE_END =
      TrackEvent_Type._(2, _omitEnumNames ? '' : 'TYPE_SLICE_END');
  static const TrackEvent_Type TYPE_INSTANT =
      TrackEvent_Type._(3, _omitEnumNames ? '' : 'TYPE_INSTANT');

  static const $core.List<TrackEvent_Type> values = <TrackEvent_Type>[
    TYPE_SLICE_BEGIN,
    TYPE_SLICE_END,
    TYPE_INSTANT,
  ];

  static final $core.Map<$core.int, TrackEvent_Type> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackEvent_Type? valueOf($core.int value) => _byValue[value];

  const TrackEvent_Type._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
