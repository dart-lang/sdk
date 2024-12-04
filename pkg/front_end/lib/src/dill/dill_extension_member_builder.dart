// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

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
  bool get isExternal => member.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  String get name => _descriptor.name.text;

  @override
  ProcedureKind? get kind {
    switch (_descriptor.kind) {
      case ExtensionMemberKind.Method:
        return ProcedureKind.Method;
      case ExtensionMemberKind.Getter:
        return ProcedureKind.Getter;
      case ExtensionMemberKind.Operator:
        return ProcedureKind.Operator;
      case ExtensionMemberKind.Setter:
        return ProcedureKind.Setter;
      case ExtensionMemberKind.Field:
    }
    return null;
  }
}

class DillExtensionFieldBuilder extends DillExtensionMemberBuilder {
  final Field field;

  DillExtensionFieldBuilder(this.field, super.descriptor, super.libraryBuilder,
      super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => field;

  @override
  Member get readTarget => field;

  @override
  Member? get writeTarget => isAssignable ? field : null;

  @override
  Member get invokeTarget => field;

  @override
  bool get isField => true;

  @override
  bool get isAssignable => field.hasSetter;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences =>
      [field.getterReference, if (field.hasSetter) field.setterReference!];
}

class DillExtensionSetterBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionSetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Setter);

  @override
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  Member get writeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get invokeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
}

class DillExtensionGetterBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionGetterBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Getter);

  @override
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
}

class DillExtensionOperatorBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionOperatorBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Operator);

  @override
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
}

class DillExtensionStaticMethodBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionStaticMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(descriptor.isStatic);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
}

class DillExtensionInstanceMethodBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  final Procedure _extensionTearOff;

  DillExtensionInstanceMethodBuilder(this.procedure, super.descriptor,
      super.libraryBuilder, super.declarationBuilder, this._extensionTearOff)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(!descriptor.isStatic);

  @override
  bool get isProperty => false;

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
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}
