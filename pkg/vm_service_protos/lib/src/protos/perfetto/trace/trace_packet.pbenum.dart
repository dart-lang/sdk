// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/trace_packet.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TracePacket_SequenceFlags extends $pb.ProtobufEnum {
  static const TracePacket_SequenceFlags SEQ_UNSPECIFIED =
      TracePacket_SequenceFlags._(0, _omitEnumNames ? '' : 'SEQ_UNSPECIFIED');

  /// Set by the writer to indicate that it will re-emit any incremental data
  /// for the packet's sequence before referring to it again. This includes
  /// interned data as well as periodically emitted data like
  /// Process/ThreadDescriptors. This flag only affects the current packet
  /// sequence (see |trusted_packet_sequence_id|).
  ///
  /// When set, this TracePacket and subsequent TracePackets on the same
  /// sequence will not refer to any incremental data emitted before this
  /// TracePacket. For example, previously emitted interned data will be
  /// re-emitted if it is referred to again.
  ///
  /// When the reader detects packet loss (|previous_packet_dropped|), it needs
  /// to skip packets in the sequence until the next one with this flag set, to
  /// ensure intact incremental data.
  static const TracePacket_SequenceFlags SEQ_INCREMENTAL_STATE_CLEARED =
      TracePacket_SequenceFlags._(
          1, _omitEnumNames ? '' : 'SEQ_INCREMENTAL_STATE_CLEARED');

  /// This packet requires incremental state, such as TracePacketDefaults or
  /// InternedData, to be parsed correctly. The trace reader should skip this
  /// packet if incremental state is not valid on this sequence, i.e. if no
  /// packet with the SEQ_INCREMENTAL_STATE_CLEARED flag has been seen on the
  /// current |trusted_packet_sequence_id|.
  static const TracePacket_SequenceFlags SEQ_NEEDS_INCREMENTAL_STATE =
      TracePacket_SequenceFlags._(
          2, _omitEnumNames ? '' : 'SEQ_NEEDS_INCREMENTAL_STATE');

  static const $core.List<TracePacket_SequenceFlags> values =
      <TracePacket_SequenceFlags>[
    SEQ_UNSPECIFIED,
    SEQ_INCREMENTAL_STATE_CLEARED,
    SEQ_NEEDS_INCREMENTAL_STATE,
  ];

  static final $core.List<TracePacket_SequenceFlags?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static TracePacket_SequenceFlags? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TracePacket_SequenceFlags._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
