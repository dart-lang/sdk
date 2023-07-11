// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/track_descriptor.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'process_descriptor.pb.dart' as $3;
import 'thread_descriptor.pb.dart' as $4;

class TrackDescriptor extends $pb.GeneratedMessage {
  factory TrackDescriptor() => create();
  TrackDescriptor._() : super();
  factory TrackDescriptor.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackDescriptor.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackDescriptor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'uuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$3.ProcessDescriptor>(3, _omitFieldNames ? '' : 'process',
        subBuilder: $3.ProcessDescriptor.create)
    ..aOM<$4.ThreadDescriptor>(4, _omitFieldNames ? '' : 'thread',
        subBuilder: $4.ThreadDescriptor.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'parentUuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackDescriptor clone() => TrackDescriptor()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackDescriptor copyWith(void Function(TrackDescriptor) updates) =>
      super.copyWith((message) => updates(message as TrackDescriptor))
          as TrackDescriptor;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrackDescriptor create() => TrackDescriptor._();
  TrackDescriptor createEmptyInstance() => create();
  static $pb.PbList<TrackDescriptor> createRepeated() =>
      $pb.PbList<TrackDescriptor>();
  @$core.pragma('dart2js:noInline')
  static TrackDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackDescriptor>(create);
  static TrackDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get uuid => $_getI64(0);
  @$pb.TagNumber(1)
  set uuid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $3.ProcessDescriptor get process => $_getN(2);
  @$pb.TagNumber(3)
  set process($3.ProcessDescriptor v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasProcess() => $_has(2);
  @$pb.TagNumber(3)
  void clearProcess() => clearField(3);
  @$pb.TagNumber(3)
  $3.ProcessDescriptor ensureProcess() => $_ensure(2);

  @$pb.TagNumber(4)
  $4.ThreadDescriptor get thread => $_getN(3);
  @$pb.TagNumber(4)
  set thread($4.ThreadDescriptor v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasThread() => $_has(3);
  @$pb.TagNumber(4)
  void clearThread() => clearField(4);
  @$pb.TagNumber(4)
  $4.ThreadDescriptor ensureThread() => $_ensure(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get parentUuid => $_getI64(4);
  @$pb.TagNumber(5)
  set parentUuid($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasParentUuid() => $_has(4);
  @$pb.TagNumber(5)
  void clearParentUuid() => clearField(5);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
