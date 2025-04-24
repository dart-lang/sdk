// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

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
  final Field field;

  DillExtensionTypeFieldBuilder(this.field, super.descriptor,
      super.libraryBuilder, super.declarationBuilder);

  @override
  Member get member => field;

  @override
  Member get readTarget => field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => field.getterReference;

  @override
  Member? get writeTarget => field.hasSetter ? field : null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => field.setterReference;

  @override
  Member get invokeTarget => field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => field.getterReference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => field.isEnumElement;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences =>
      [field.getterReference, if (field.hasSetter) field.setterReference!];

  @override
  // Coverage-ignore(suite): Not run.
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasConstField => field.isConst;

  @override
  SetterQuality get setterQuality =>
      field.hasSetter ? SetterQuality.Implicit : SetterQuality.Absent;
}

class DillExtensionTypeSetterBuilder extends DillExtensionTypeMemberBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  final Procedure procedure;

  DillExtensionTypeSetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Setter);

  @override
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
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality =>
      procedure.isExternal ? SetterQuality.External : SetterQuality.Concrete;
}

class DillExtensionTypeGetterBuilder extends DillExtensionTypeMemberBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  final Procedure procedure;

  DillExtensionTypeGetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Getter);

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
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality =>
      procedure.isExternal ? GetterQuality.External : GetterQuality.Concrete;

  @override
  // Coverage-ignore(suite): Not run.
  SetterQuality get setterQuality => SetterQuality.Absent;
}

class DillExtensionTypeOperatorBuilder extends DillExtensionTypeMemberBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  DillExtensionTypeOperatorBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Operator);

  @override
  Member get member => procedure;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
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
}

class DillExtensionTypeInstanceMethodBuilder
    extends DillExtensionTypeMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  final Procedure _extensionTearOff;

  DillExtensionTypeInstanceMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder, this._extensionTearOff)
      : assert(descriptor.kind == ExtensionTypeMemberKind.Method),
        assert(!descriptor.isStatic);

  @override
  Member get member => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences =>
      [procedure.reference, _extensionTearOff.reference];

  @override
  Member get readTarget => _extensionTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _extensionTearOff.reference;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => procedure.reference;
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
