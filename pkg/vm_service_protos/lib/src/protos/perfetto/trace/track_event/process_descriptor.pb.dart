// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/process_descriptor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Describes a process's attributes. Emitted as part of a TrackDescriptor,
/// usually by the process's main thread.
///
/// Next id: 9.
class ProcessDescriptor extends $pb.GeneratedMessage {
  factory ProcessDescriptor({
    $core.int? pid,
    $core.String? processName,
  }) {
    final result = create();
    if (pid != null) result.pid = pid;
    if (processName != null) result.processName = processName;
    return result;
  }

  ProcessDescriptor._();

  factory ProcessDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProcessDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'pid')
    ..aOS(6, _omitFieldNames ? '' : 'processName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProcessDescriptor copyWith(void Function(ProcessDescriptor) updates) =>
      super.copyWith((message) => updates(message as ProcessDescriptor))
          as ProcessDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessDescriptor create() => ProcessDescriptor._();
  @$core.override
  ProcessDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProcessDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessDescriptor>(create);
  static ProcessDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pid => $_getIZ(0);
  @$pb.TagNumber(1)
  set pid($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPid() => $_has(0);
  @$pb.TagNumber(1)
  void clearPid() => $_clearField(1);

  @$pb.TagNumber(6)
  $core.String get processName => $_getSZ(1);
  @$pb.TagNumber(6)
  set processName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(6)
  $core.bool hasProcessName() => $_has(1);
  @$pb.TagNumber(6)
  void clearProcessName() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
