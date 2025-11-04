// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/track_event/debug_annotation.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum DebugAnnotation_NameField { nameIid, name, notSet }

enum DebugAnnotation_Value {
  stringValue,
  legacyJsonValue,
  stringValueIid,
  notSet
}

///  Proto representation of untyped key/value annotations provided in TRACE_EVENT
///  macros. Users of the Perfetto SDK should prefer to use the
///  perfetto::TracedValue API to fill these protos, rather than filling them
///  manually.
///
///  Debug annotations are intended for debug use and are not considered a stable
///  API of the trace contents. Trace-based metrics that use debug annotation
///  values are prone to breakage, so please rely on typed TrackEvent fields for
///  these instead.
///
///  DebugAnnotations support nested arrays and dictionaries. Each entry is
///  encoded as a single DebugAnnotation message. Only dictionary entries
///  set the "name" field. The TrackEvent message forms an implicit root
///  dictionary.
///
///  Example TrackEvent with nested annotations:
///    track_event {
///      debug_annotations {
///        name: "foo"
///        dict_entries {
///          name: "a"
///          bool_value: true
///        }
///        dict_entries {
///          name: "b"
///          int_value: 123
///        }
///      }
///      debug_annotations {
///        name: "bar"
///        array_values {
///          string_value: "hello"
///        }
///        array_values {
///          string_value: "world"
///        }
///      }
///    }
///
///  Next ID: 17.
///  Reserved ID: 15
class DebugAnnotation extends $pb.GeneratedMessage {
  factory DebugAnnotation({
    $fixnum.Int64? nameIid,
    $core.String? stringValue,
    $core.String? legacyJsonValue,
    $core.String? name,
    $fixnum.Int64? stringValueIid,
  }) {
    final $result = create();
    if (nameIid != null) {
      $result.nameIid = nameIid;
    }
    if (stringValue != null) {
      $result.stringValue = stringValue;
    }
    if (legacyJsonValue != null) {
      $result.legacyJsonValue = legacyJsonValue;
    }
    if (name != null) {
      $result.name = name;
    }
    if (stringValueIid != null) {
      $result.stringValueIid = stringValueIid;
    }
    return $result;
  }
  DebugAnnotation._() : super();
  factory DebugAnnotation.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DebugAnnotation.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, DebugAnnotation_NameField>
      _DebugAnnotation_NameFieldByTag = {
    1: DebugAnnotation_NameField.nameIid,
    10: DebugAnnotation_NameField.name,
    0: DebugAnnotation_NameField.notSet
  };
  static const $core.Map<$core.int, DebugAnnotation_Value>
      _DebugAnnotation_ValueByTag = {
    6: DebugAnnotation_Value.stringValue,
    9: DebugAnnotation_Value.legacyJsonValue,
    17: DebugAnnotation_Value.stringValueIid,
    0: DebugAnnotation_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugAnnotation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..oo(0, [1, 10])
    ..oo(1, [6, 9, 17])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'nameIid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'stringValue')
    ..aOS(9, _omitFieldNames ? '' : 'legacyJsonValue')
    ..aOS(10, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(
        17, _omitFieldNames ? '' : 'stringValueIid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
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
  void clearNameField() => $_clearField($_whichOneof(0));

  DebugAnnotation_Value whichValue() =>
      _DebugAnnotation_ValueByTag[$_whichOneof(1)]!;
  void clearValue() => $_clearField($_whichOneof(1));

  /// interned DebugAnnotationName.
  @$pb.TagNumber(1)
  $fixnum.Int64 get nameIid => $_getI64(0);
  @$pb.TagNumber(1)
  set nameIid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasNameIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearNameIid() => $_clearField(1);

  /// interned and non-interned variants of strings.
  @$pb.TagNumber(6)
  $core.String get stringValue => $_getSZ(1);
  @$pb.TagNumber(6)
  set stringValue($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasStringValue() => $_has(1);
  @$pb.TagNumber(6)
  void clearStringValue() => $_clearField(6);

  /// Legacy instrumentation may not support conversion of nested data to
  /// NestedValue yet.
  @$pb.TagNumber(9)
  $core.String get legacyJsonValue => $_getSZ(2);
  @$pb.TagNumber(9)
  set legacyJsonValue($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasLegacyJsonValue() => $_has(2);
  @$pb.TagNumber(9)
  void clearLegacyJsonValue() => $_clearField(9);

  /// non-interned variant.
  @$pb.TagNumber(10)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(10)
  set name($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(10)
  void clearName() => $_clearField(10);

  /// Corresponds to |debug_annotation_string_values| field in InternedData.
  @$pb.TagNumber(17)
  $fixnum.Int64 get stringValueIid => $_getI64(4);
  @$pb.TagNumber(17)
  set stringValueIid($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasStringValueIid() => $_has(4);
  @$pb.TagNumber(17)
  void clearStringValueIid() => $_clearField(17);
}

class DebugAnnotationName extends $pb.GeneratedMessage {
  factory DebugAnnotationName({
    $fixnum.Int64? iid,
    $core.String? name,
  }) {
    final $result = create();
    if (iid != null) {
      $result.iid = iid;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  DebugAnnotationName._() : super();
  factory DebugAnnotationName.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DebugAnnotationName.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugAnnotationName',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'iid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DebugAnnotationName clone() => DebugAnnotationName()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DebugAnnotationName copyWith(void Function(DebugAnnotationName) updates) =>
      super.copyWith((message) => updates(message as DebugAnnotationName))
          as DebugAnnotationName;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DebugAnnotationName create() => DebugAnnotationName._();
  DebugAnnotationName createEmptyInstance() => create();
  static $pb.PbList<DebugAnnotationName> createRepeated() =>
      $pb.PbList<DebugAnnotationName>();
  @$core.pragma('dart2js:noInline')
  static DebugAnnotationName getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DebugAnnotationName>(create);
  static DebugAnnotationName? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get iid => $_getI64(0);
  @$pb.TagNumber(1)
  set iid($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
