// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';

import '../base/uri_offset.dart';
import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_extension_builder.dart';
import 'dill_member_builder.dart';

abstract class DillExtensionMemberBuilder extends DillMemberBuilder {
  final ExtensionMemberDescriptor _descriptor;

  DillExtensionMemberBuilder(
    this._descriptor,
    super.libraryBuilder,
    DillExtensionBuilder super.declarationBuilder,
  );

  @override
  bool get isStatic => _descriptor.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  String get name => _descriptor.name.text;
}

class DillExtensionFieldBuilder extends DillExtensionMemberBuilder
    with DillFieldBuilderMixin
    implements PropertyBuilder {
  final Field _field;

  DillExtensionFieldBuilder(
    this._field,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
  );

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _field;

  @override
  Member get readTarget => _field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _field.getterReference;

  @override
  Member? get writeTarget => _field.hasSetter ? _field : null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _field.setterReference;

  @override
  Member get invokeTarget => _field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _field.getterReference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => _field.isEnumElement;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [
    _field.getterReference,
    if (_field.hasSetter) _field.setterReference!,
  ];

  @override
  // Coverage-ignore(suite): Not run.
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength? get setterUriOffset => hasSetter
      ? new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length)
      : null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasConstField => _field.isConst;

  @override
  SetterQuality get setterQuality =>
      _field.hasSetter ? SetterQuality.Implicit : SetterQuality.Absent;
}

class DillExtensionSetterBuilder extends DillExtensionMemberBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  final Procedure procedure;

  DillExtensionSetterBuilder(
    this.procedure,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
  ) : assert(descriptor.kind == ExtensionMemberKind.Setter);

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => procedure;

  @override
  Member get writeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get writeTargetReference => procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Absent;

  @override
  SetterQuality get setterQuality =>
      procedure.isExternal ? SetterQuality.External : SetterQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get setterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionGetterBuilder extends DillExtensionMemberBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  final Procedure _procedure;

  DillExtensionGetterBuilder(
    this._procedure,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
  ) : assert(descriptor.kind == ExtensionMemberKind.Getter);

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality =>
      _procedure.isExternal ? GetterQuality.External : GetterQuality.Concrete;

  @override
  SetterQuality get setterQuality => SetterQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionOperatorBuilder extends DillExtensionMemberBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  final Procedure _procedure;

  DillExtensionOperatorBuilder(
    this._procedure,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
  ) : assert(descriptor.kind == ExtensionMemberKind.Operator);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => new UriOffsetLength(
    fileUri,
    fileOffset,
    _descriptor.name == unaryMinusName ? 1 : _descriptor.name.text.length,
  );
}

class DillExtensionStaticMethodBuilder extends DillExtensionMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure _procedure;

  DillExtensionStaticMethodBuilder(
    this._procedure,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
  ) : assert(descriptor.kind == ExtensionMemberKind.Method),
      assert(descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionInstanceMethodBuilder extends DillExtensionMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure _procedure;

  final Procedure _extensionTearOff;

  DillExtensionInstanceMethodBuilder(
    this._procedure,
    super.descriptor,
    super.libraryBuilder,
    super.declarationBuilder,
    this._extensionTearOff,
  ) : assert(descriptor.kind == ExtensionMemberKind.Method),
      assert(!descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [
    _procedure.reference,
    _extensionTearOff.reference,
  ];

  @override
  Member get readTarget => _extensionTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _extensionTearOff.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}
