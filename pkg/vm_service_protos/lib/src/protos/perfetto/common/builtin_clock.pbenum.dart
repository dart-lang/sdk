// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/common/builtin_clock.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class BuiltinClock extends $pb.ProtobufEnum {
  static const BuiltinClock BUILTIN_CLOCK_MONOTONIC =
      BuiltinClock._(3, _omitEnumNames ? '' : 'BUILTIN_CLOCK_MONOTONIC');

  static const $core.List<BuiltinClock> values = <BuiltinClock>[
    BUILTIN_CLOCK_MONOTONIC,
  ];

  static final $core.Map<$core.int, BuiltinClock> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static BuiltinClock? valueOf($core.int value) => _byValue[value];

  const BuiltinClock._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
