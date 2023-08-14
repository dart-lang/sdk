// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/process_descriptor.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ProcessDescriptor extends $pb.GeneratedMessage {
  factory ProcessDescriptor() => create();
  ProcessDescriptor._() : super();
  factory ProcessDescriptor.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ProcessDescriptor.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProcessDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'pid', $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'processName')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ProcessDescriptor clone() => ProcessDescriptor()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ProcessDescriptor copyWith(void Function(ProcessDescriptor) updates) =>
      super.copyWith((message) => updates(message as ProcessDescriptor))
          as ProcessDescriptor;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProcessDescriptor create() => ProcessDescriptor._();
  ProcessDescriptor createEmptyInstance() => create();
  static $pb.PbList<ProcessDescriptor> createRepeated() =>
      $pb.PbList<ProcessDescriptor>();
  @$core.pragma('dart2js:noInline')
  static ProcessDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProcessDescriptor>(create);
  static ProcessDescriptor? _defaultInstance;

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

  @$pb.TagNumber(6)
  $core.String get processName => $_getSZ(1);
  @$pb.TagNumber(6)
  set processName($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasProcessName() => $_has(1);
  @$pb.TagNumber(6)
  void clearProcessName() => clearField(6);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
