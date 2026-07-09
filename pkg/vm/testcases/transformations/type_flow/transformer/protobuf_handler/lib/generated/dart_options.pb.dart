// This is a generated file - do not edit.
//
// Generated from dart_options.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// A mixin that can be used in the 'with' clause of the generated Dart class
/// for a proto message.
class DartMixin extends $pb.GeneratedMessage {
  factory DartMixin() => create();

  DartMixin._();

  factory DartMixin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DartMixin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DartMixin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dart_options'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'importFrom')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DartMixin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DartMixin copyWith(void Function(DartMixin) updates) =>
      super.copyWith((message) => updates(message as DartMixin)) as DartMixin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DartMixin create() => DartMixin._();
  @$core.override
  DartMixin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DartMixin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DartMixin>(create);
  static DartMixin? _defaultInstance;

  /// The name of the mixin class.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// A URI pointing to the Dart library that defines the mixin.
  /// The generated Dart code will use this in an import statement.
  @$pb.TagNumber(2)
  $core.String get importFrom => $_getSZ(1);
  @$pb.TagNumber(2)
  set importFrom($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasImportFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearImportFrom() => $_clearField(2);
}

/// Defines additional Dart imports to be used with messages in this file.
class Imports extends $pb.GeneratedMessage {
  factory Imports() => create();

  Imports._();

  factory Imports.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Imports.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Imports',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dart_options'),
      createEmptyInstance: create)
    ..pPM<DartMixin>(1, _omitFieldNames ? '' : 'mixins',
        subBuilder: DartMixin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Imports clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Imports copyWith(void Function(Imports) updates) =>
      super.copyWith((message) => updates(message as Imports)) as Imports;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Imports create() => Imports._();
  @$core.override
  Imports createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Imports getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Imports>(create);
  static Imports? _defaultInstance;

  /// Mixins to be used on messages in this file.
  /// These mixins are in addition to internally defined mixins (e.g PbMapMixin)
  /// and may override them.
  ///
  /// Warning: mixins are experimental. The protoc Dart plugin doesn't check
  /// for name conflicts between mixin class members and generated class members,
  /// so the generated code may contain errors. Therefore, running dartanalyzer
  /// on the generated file is a good idea.
  @$pb.TagNumber(1)
  $pb.PbList<DartMixin> get mixins => $_getList(0);
}

class Dart_options {
  static final imports = $pb.Extension<Imports>(
      _omitMessageNames ? '' : 'google.protobuf.FileOptions',
      _omitFieldNames ? '' : 'imports',
      28125061,
      $pb.PbFieldType.OM,
      defaultOrMaker: Imports.getDefault,
      subBuilder: Imports.create);
  static final mixin = $pb.Extension<$core.String>(
      _omitMessageNames ? '' : 'google.protobuf.MessageOptions',
      _omitFieldNames ? '' : 'mixin',
      96128839,
      $pb.PbFieldType.OS);
  static void registerAllExtensions($pb.ExtensionRegistry registry) {
    registry.add(imports);
    registry.add(mixin);
  }
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
