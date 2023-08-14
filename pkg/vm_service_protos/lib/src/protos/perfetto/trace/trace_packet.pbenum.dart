// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/trace_packet.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TracePacket_SequenceFlags extends $pb.ProtobufEnum {
  static const TracePacket_SequenceFlags SEQ_UNSPECIFIED =
      TracePacket_SequenceFlags._(0, _omitEnumNames ? '' : 'SEQ_UNSPECIFIED');
  static const TracePacket_SequenceFlags SEQ_INCREMENTAL_STATE_CLEARED =
      TracePacket_SequenceFlags._(
          1, _omitEnumNames ? '' : 'SEQ_INCREMENTAL_STATE_CLEARED');
  static const TracePacket_SequenceFlags SEQ_NEEDS_INCREMENTAL_STATE =
      TracePacket_SequenceFlags._(
          2, _omitEnumNames ? '' : 'SEQ_NEEDS_INCREMENTAL_STATE');

  static const $core.List<TracePacket_SequenceFlags> values =
      <TracePacket_SequenceFlags>[
    SEQ_UNSPECIFIED,
    SEQ_INCREMENTAL_STATE_CLEARED,
    SEQ_NEEDS_INCREMENTAL_STATE,
  ];

  static final $core.Map<$core.int, TracePacket_SequenceFlags> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TracePacket_SequenceFlags? valueOf($core.int value) => _byValue[value];

  const TracePacket_SequenceFlags._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
