// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_extension_builder.dart';
import 'dill_member_builder.dart';

abstract class DillExtensionMemberBuilder extends DillMemberBuilder {
  final ExtensionMemberDescriptor _descriptor;

  DillExtensionMemberBuilder(this._descriptor, super.libraryBuilder,
      DillExtensionBuilder super.declarationBuilder);

  @override
  bool get isStatic => _descriptor.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  String get name => _descriptor.name.text;
}

class DillExtensionFieldBuilder extends DillExtensionMemberBuilder
    with DillFieldBuilderMixin
    implements PropertyBuilder {
  final Field field;

  DillExtensionFieldBuilder(this.field, super.descriptor, super.libraryBuilder,
      super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
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

class DillExtensionSetterBuilder extends DillExtensionMemberBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  final Procedure procedure;

  DillExtensionSetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Setter);

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
}

class DillExtensionGetterBuilder extends DillExtensionMemberBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  final Procedure procedure;

  DillExtensionGetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Getter);

  @override
  // Coverage-ignore(suite): Not run.
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
  SetterQuality get setterQuality => SetterQuality.Absent;
}

class DillExtensionOperatorBuilder extends DillExtensionMemberBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  DillExtensionOperatorBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Operator);

  @override
  // Coverage-ignore(suite): Not run.
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

class DillExtensionStaticMethodBuilder extends DillExtensionMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  DillExtensionStaticMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
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

class DillExtensionInstanceMethodBuilder extends DillExtensionMemberBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  final Procedure procedure;

  final Procedure _extensionTearOff;

  DillExtensionInstanceMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder, this._extensionTearOff)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(!descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
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
