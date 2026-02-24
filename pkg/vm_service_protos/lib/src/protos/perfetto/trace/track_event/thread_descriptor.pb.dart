// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
// This is a generated file - do not edit.
//
// Generated from protos/perfetto/trace/track_event/thread_descriptor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Describes a thread's attributes. Emitted as part of a TrackDescriptor,
/// usually by the thread's trace writer.
///
/// Next id: 9.
class ThreadDescriptor extends $pb.GeneratedMessage {
  factory ThreadDescriptor({
    $core.int? pid,
    $core.int? tid,
    $core.String? threadName,
  }) {
    final result = create();
    if (pid != null) result.pid = pid;
    if (tid != null) result.tid = tid;
    if (threadName != null) result.threadName = threadName;
    return result;
  }

  ThreadDescriptor._();

  factory ThreadDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThreadDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThreadDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'pid')
    ..aI(2, _omitFieldNames ? '' : 'tid')
    ..aOS(5, _omitFieldNames ? '' : 'threadName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThreadDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThreadDescriptor copyWith(void Function(ThreadDescriptor) updates) =>
      super.copyWith((message) => updates(message as ThreadDescriptor))
          as ThreadDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThreadDescriptor create() => ThreadDescriptor._();
  @$core.override
  ThreadDescriptor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThreadDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThreadDescriptor>(create);
  static ThreadDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pid => $_getIZ(0);
  @$pb.TagNumber(1)
  set pid($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPid() => $_has(0);
  @$pb.TagNumber(1)
  void clearPid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get tid => $_getIZ(1);
  @$pb.TagNumber(2)
  set tid($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTid() => $_has(1);
  @$pb.TagNumber(2)
  void clearTid() => $_clearField(2);

  @$pb.TagNumber(5)
  $core.String get threadName => $_getSZ(2);
  @$pb.TagNumber(5)
  set threadName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(5)
  $core.bool hasThreadName() => $_has(2);
  @$pb.TagNumber(5)
  void clearThreadName() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
