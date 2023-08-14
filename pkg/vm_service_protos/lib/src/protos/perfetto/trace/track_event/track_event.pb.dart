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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'debug_annotation.pb.dart' as $1;
import 'track_event.pbenum.dart';

export 'track_event.pbenum.dart';

enum TrackEvent_NameField { name, notSet }

class TrackEvent extends $pb.GeneratedMessage {
  factory TrackEvent() => create();
  TrackEvent._() : super();
  factory TrackEvent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackEvent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, TrackEvent_NameField>
      _TrackEvent_NameFieldByTag = {
    23: TrackEvent_NameField.name,
    0: TrackEvent_NameField.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrackEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..oo(0, [23])
    ..pc<$1.DebugAnnotation>(
        4, _omitFieldNames ? '' : 'debugAnnotations', $pb.PbFieldType.PM,
        subBuilder: $1.DebugAnnotation.create)
    ..e<TrackEvent_Type>(9, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: TrackEvent_Type.TYPE_SLICE_BEGIN,
        valueOf: TrackEvent_Type.valueOf,
        enumValues: TrackEvent_Type.values)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'trackUuid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(22, _omitFieldNames ? '' : 'categories')
    ..aOS(23, _omitFieldNames ? '' : 'name')
    ..p<$fixnum.Int64>(
        47, _omitFieldNames ? '' : 'flowIds', $pb.PbFieldType.PF6)
    ..p<$fixnum.Int64>(
        48, _omitFieldNames ? '' : 'terminatingFlowIds', $pb.PbFieldType.PF6)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackEvent clone() => TrackEvent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackEvent copyWith(void Function(TrackEvent) updates) =>
      super.copyWith((message) => updates(message as TrackEvent)) as TrackEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrackEvent create() => TrackEvent._();
  TrackEvent createEmptyInstance() => create();
  static $pb.PbList<TrackEvent> createRepeated() => $pb.PbList<TrackEvent>();
  @$core.pragma('dart2js:noInline')
  static TrackEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackEvent>(create);
  static TrackEvent? _defaultInstance;

  TrackEvent_NameField whichNameField() =>
      _TrackEvent_NameFieldByTag[$_whichOneof(0)]!;
  void clearNameField() => clearField($_whichOneof(0));

  @$pb.TagNumber(4)
  $core.List<$1.DebugAnnotation> get debugAnnotations => $_getList(0);

  @$pb.TagNumber(9)
  TrackEvent_Type get type => $_getN(1);
  @$pb.TagNumber(9)
  set type(TrackEvent_Type v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(9)
  void clearType() => clearField(9);

  @$pb.TagNumber(11)
  $fixnum.Int64 get trackUuid => $_getI64(2);
  @$pb.TagNumber(11)
  set trackUuid($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasTrackUuid() => $_has(2);
  @$pb.TagNumber(11)
  void clearTrackUuid() => clearField(11);

  @$pb.TagNumber(22)
  $core.List<$core.String> get categories => $_getList(3);

  @$pb.TagNumber(23)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(23)
  set name($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(23)
  void clearName() => clearField(23);

  @$pb.TagNumber(47)
  $core.List<$fixnum.Int64> get flowIds => $_getList(5);

  @$pb.TagNumber(48)
  $core.List<$fixnum.Int64> get terminatingFlowIds => $_getList(6);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
