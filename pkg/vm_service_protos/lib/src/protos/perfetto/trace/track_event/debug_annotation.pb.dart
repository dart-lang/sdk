// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/debug_annotation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum DebugAnnotation_NameField { name, notSet }

enum DebugAnnotation_Value { stringValue, legacyJsonValue, notSet }

class DebugAnnotation extends $pb.GeneratedMessage {
  factory DebugAnnotation() => create();
  DebugAnnotation._() : super();
  factory DebugAnnotation.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DebugAnnotation.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, DebugAnnotation_NameField>
      _DebugAnnotation_NameFieldByTag = {
    10: DebugAnnotation_NameField.name,
    0: DebugAnnotation_NameField.notSet
  };
  static const $core.Map<$core.int, DebugAnnotation_Value>
      _DebugAnnotation_ValueByTag = {
    6: DebugAnnotation_Value.stringValue,
    9: DebugAnnotation_Value.legacyJsonValue,
    0: DebugAnnotation_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugAnnotation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..oo(0, [10])
    ..oo(1, [6, 9])
    ..aOS(6, _omitFieldNames ? '' : 'stringValue')
    ..aOS(9, _omitFieldNames ? '' : 'legacyJsonValue')
    ..aOS(10, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DebugAnnotation clone() => DebugAnnotation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DebugAnnotation copyWith(void Function(DebugAnnotation) updates) =>
      super.copyWith((message) => updates(message as DebugAnnotation))
          as DebugAnnotation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DebugAnnotation create() => DebugAnnotation._();
  DebugAnnotation createEmptyInstance() => create();
  static $pb.PbList<DebugAnnotation> createRepeated() =>
      $pb.PbList<DebugAnnotation>();
  @$core.pragma('dart2js:noInline')
  static DebugAnnotation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DebugAnnotation>(create);
  static DebugAnnotation? _defaultInstance;

  DebugAnnotation_NameField whichNameField() =>
      _DebugAnnotation_NameFieldByTag[$_whichOneof(0)]!;
  void clearNameField() => clearField($_whichOneof(0));

  DebugAnnotation_Value whichValue() =>
      _DebugAnnotation_ValueByTag[$_whichOneof(1)]!;
  void clearValue() => clearField($_whichOneof(1));

  @$pb.TagNumber(6)
  $core.String get stringValue => $_getSZ(0);
  @$pb.TagNumber(6)
  set stringValue($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasStringValue() => $_has(0);
  @$pb.TagNumber(6)
  void clearStringValue() => clearField(6);

  @$pb.TagNumber(9)
  $core.String get legacyJsonValue => $_getSZ(1);
  @$pb.TagNumber(9)
  set legacyJsonValue($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasLegacyJsonValue() => $_has(1);
  @$pb.TagNumber(9)
  void clearLegacyJsonValue() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(10)
  set name($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(10)
  void clearName() => clearField(10);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
