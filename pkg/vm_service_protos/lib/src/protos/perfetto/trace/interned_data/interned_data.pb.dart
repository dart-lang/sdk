// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
//
//  Generated code. Do not modify.
//  source: protos/perfetto/trace/interned_data/interned_data.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../profiling/profile_common.pb.dart' as $2;

class InternedData extends $pb.GeneratedMessage {
  factory InternedData() => create();
  InternedData._() : super();
  factory InternedData.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InternedData.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InternedData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'perfetto.protos'),
      createEmptyInstance: create)
    ..pc<$2.InternedString>(
        5, _omitFieldNames ? '' : 'functionNames', $pb.PbFieldType.PM,
        subBuilder: $2.InternedString.create)
    ..pc<$2.Frame>(6, _omitFieldNames ? '' : 'frames', $pb.PbFieldType.PM,
        subBuilder: $2.Frame.create)
    ..pc<$2.Callstack>(
        7, _omitFieldNames ? '' : 'callstacks', $pb.PbFieldType.PM,
        subBuilder: $2.Callstack.create)
    ..pc<$2.InternedString>(
        17, _omitFieldNames ? '' : 'mappingPaths', $pb.PbFieldType.PM,
        subBuilder: $2.InternedString.create)
    ..pc<$2.Mapping>(19, _omitFieldNames ? '' : 'mappings', $pb.PbFieldType.PM,
        subBuilder: $2.Mapping.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InternedData clone() => InternedData()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InternedData copyWith(void Function(InternedData) updates) =>
      super.copyWith((message) => updates(message as InternedData))
          as InternedData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InternedData create() => InternedData._();
  InternedData createEmptyInstance() => create();
  static $pb.PbList<InternedData> createRepeated() =>
      $pb.PbList<InternedData>();
  @$core.pragma('dart2js:noInline')
  static InternedData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InternedData>(create);
  static InternedData? _defaultInstance;

  @$pb.TagNumber(5)
  $core.List<$2.InternedString> get functionNames => $_getList(0);

  @$pb.TagNumber(6)
  $core.List<$2.Frame> get frames => $_getList(1);

  @$pb.TagNumber(7)
  $core.List<$2.Callstack> get callstacks => $_getList(2);

  @$pb.TagNumber(17)
  $core.List<$2.InternedString> get mappingPaths => $_getList(3);

  @$pb.TagNumber(19)
  $core.List<$2.Mapping> get mappings => $_getList(4);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
