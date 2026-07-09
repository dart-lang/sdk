// This is a generated file - do not edit.
//
// Generated from name_mangling.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AKeep extends $pb.GeneratedMessage {
  factory AKeep() => create();

  AKeep._();

  factory AKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AKeep',
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AKeep copyWith(void Function(AKeep) updates) =>
      super.copyWith((message) => updates(message as AKeep)) as AKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AKeep create() => AKeep._();
  @$core.override
  AKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AKeep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AKeep>(create);
  static AKeep? _defaultInstance;
}

class NameManglingKeep extends $pb.GeneratedMessage {
  factory NameManglingKeep() => create();

  NameManglingKeep._();

  factory NameManglingKeep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NameManglingKeep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NameManglingKeep',
      createEmptyInstance: create)
    ..aOM<AKeep>(10, _omitFieldNames ? '' : 'clone', subBuilder: AKeep.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NameManglingKeep clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NameManglingKeep copyWith(void Function(NameManglingKeep) updates) =>
      super.copyWith((message) => updates(message as NameManglingKeep))
          as NameManglingKeep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NameManglingKeep create() => NameManglingKeep._();
  @$core.override
  NameManglingKeep createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NameManglingKeep getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NameManglingKeep>(create);
  static NameManglingKeep? _defaultInstance;

  /// the name `clone` is mangled by the protoc_plugin to not conflict with
  /// `GeneratedMessage.clone`.
  /// Still we should be able to detect usages of this field.
  @$pb.TagNumber(10)
  AKeep get clone_10 => $_getN(0);
  @$pb.TagNumber(10)
  set clone_10(AKeep value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasClone_10() => $_has(0);
  @$pb.TagNumber(10)
  void clearClone_10() => $_clearField(10);
  @$pb.TagNumber(10)
  AKeep ensureClone_10() => $_ensure(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
