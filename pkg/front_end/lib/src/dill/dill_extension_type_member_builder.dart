// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';

import '../base/uri_offset.dart';
import '../builder/constructor_builder.dart';
import '../builder/factory_builder.dart';
import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_extension_type_declaration_builder.dart';
import 'dill_member_builder.dart';

abstract class DillExtensionTypeMemberBuilder extends DillMemberBuilder {
  final ExtensionTypeMemberDescriptor _descriptor;

  DillExtensionTypeMemberBuilder(this._descriptor, super.libraryBuilder,
      DillExtensionTypeDeclarationBuilder super.declarationBuilder);

  @override
  bool get isStatic => _descriptor.isStatic;

  @override
  String get name => _descriptor.name.text;

  @override
  Name get memberName => new Name(name, member.enclosingLibrary);
}

class DillExtensionTypeFieldBuilder extends DillExtensionTypeMemberBuilder
    with DillFieldBuilderMixin
    implements PropertyBuilder {
  final Field _field;

  DillExtensionTypeFieldBuilder(this._field, super.descriptor,
      super.libraryBuilder, super.declarationBuilder);

  @override
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
  Iterable<Reference> get exportedMemberReferences =>
      [_field.getterReference, if (_field.hasSetter) _field.setterReference!];

  @override
  // Coverage-ignore(suite): Not run.
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasConstField => _field.isConst;

  @override
  SetterQuality get setterQuality =>
      _field.hasSetter ? SetterQuality.Implicit : SetterQuality.Absent;

  @override
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);

  @override
  UriOffsetLength? get setterUriOffset => hasSetter
      ? new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length)
      : null;
}

class DillExtensionTypeSetterBuilder extends DillExtensionTypeMemberBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  final Procedure _procedure;

  DillExtensionTypeSetterBuilder(this._procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Setter);

  @override
  Member get member => _procedure;

  @override
  Member get writeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get writeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  // Coverage-ignore(suite): Not run.
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality =>
      _procedure.isExternal ? SetterQuality.External : SetterQuality.Concrete;

  @override
  UriOffsetLength get setterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionTypeGetterBuilder extends DillExtensionTypeMemberBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  final Procedure _procedure;

  DillExtensionTypeGetterBuilder(this._procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Getter);

  @override
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
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality =>
      _procedure.isExternal ? GetterQuality.External : GetterQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality => SetterQuality.Absent;

  @override
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionTypeOperatorBuilder extends DillExtensionTypeMemberBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  final Procedure _procedure;

  DillExtensionTypeOperatorBuilder(this._procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Operator);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
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
  UriOffsetLength get uriOffset => new UriOffsetLength(fileUri, fileOffset,
      _descriptor.name == unaryMinusName ? 1 : _descriptor.name.text.length);
}

class DillExtensionTypeStaticMethodBuilder
    extends DillExtensionTypeMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  DillExtensionTypeStaticMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Method),
        assert(descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => procedure.isAbstract;

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => procedure.reference;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];

  @override
  UriOffsetLength get uriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionTypeInstanceMethodBuilder
    extends DillExtensionTypeMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure _procedure;

  final Procedure _extensionTearOff;

  DillExtensionTypeInstanceMethodBuilder(this._procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder, this._extensionTearOff)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Method),
        assert(!descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
  Member get member => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences =>
      [_procedure.reference, _extensionTearOff.reference];

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
  UriOffsetLength get uriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _descriptor.name.text.length);
}

class DillExtensionTypeConstructorBuilder extends DillExtensionTypeMemberBuilder
    with DillConstructorBuilderMixin
    implements ConstructorBuilder {
  final Procedure constructor;
  final Procedure? _constructorTearOff;

  DillExtensionTypeConstructorBuilder(
      this.constructor,
      this._constructorTearOff,
      super.descriptor,
      super.libraryBuilder,
      super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => constructor.isConst;

  @override
  FunctionNode get function => constructor.function;

  @override
  // Coverage-ignore(suite): Not run.
  Procedure get member => constructor;

  @override
  Member get readTarget =>
      _constructorTearOff ?? // Coverage-ignore(suite): Not run.
      constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_constructorTearOff ?? constructor).reference;

  @override
  Procedure get invokeTarget => constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => constructor.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [constructor.reference];
}

class DillExtensionTypeFactoryBuilder extends DillExtensionTypeMemberBuilder
    with DillFactoryBuilderMixin
    implements FactoryBuilder {
  final Procedure _procedure;
  final Procedure? _factoryTearOff;

  DillExtensionTypeFactoryBuilder(this._procedure, this._factoryTearOff,
      super.descriptor, super.libraryBuilder, super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => _procedure;

  @override
  Member? get readTarget =>
      _factoryTearOff ?? // Coverage-ignore(suite): Not run.
      _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference =>
      (_factoryTearOff ?? _procedure).reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  FunctionNode get function => _procedure.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _procedure.isConst;
}
