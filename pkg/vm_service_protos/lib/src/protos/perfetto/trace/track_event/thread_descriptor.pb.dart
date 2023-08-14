// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/thread_descriptor.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ThreadDescriptor extends $pb.GeneratedMessage {
  factory ThreadDescriptor() => create();
  ThreadDescriptor._() : super();
  factory ThreadDescriptor.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ThreadDescriptor.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThreadDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'pid', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'tid', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'threadName')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ThreadDescriptor clone() => ThreadDescriptor()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ThreadDescriptor copyWith(void Function(ThreadDescriptor) updates) =>
      super.copyWith((message) => updates(message as ThreadDescriptor))
          as ThreadDescriptor;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThreadDescriptor create() => ThreadDescriptor._();
  ThreadDescriptor createEmptyInstance() => create();
  static $pb.PbList<ThreadDescriptor> createRepeated() =>
      $pb.PbList<ThreadDescriptor>();
  @$core.pragma('dart2js:noInline')
  static ThreadDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThreadDescriptor>(create);
  static ThreadDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get pid => $_getIZ(0);
  @$pb.TagNumber(1)
  set pid($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPid() => $_has(0);
  @$pb.TagNumber(1)
  void clearPid() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get tid => $_getIZ(1);
  @$pb.TagNumber(2)
  set tid($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTid() => $_has(1);
  @$pb.TagNumber(2)
  void clearTid() => clearField(2);

  @$pb.TagNumber(5)
  $core.String get threadName => $_getSZ(2);
  @$pb.TagNumber(5)
  set threadName($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasThreadName() => $_has(2);
  @$pb.TagNumber(5)
  void clearThreadName() => clearField(5);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
