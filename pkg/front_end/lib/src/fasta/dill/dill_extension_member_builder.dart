// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../builder/builder.dart';

import 'dill_member_builder.dart';

abstract class DillExtensionMemberBuilder extends DillMemberBuilder {
  final ExtensionMemberDescriptor _descriptor;

  DillExtensionMemberBuilder(Member member, this._descriptor, Builder parent)
      : super(member, parent);

  @override
  bool get isStatic => _descriptor.isStatic;

  bool get isExternal => member.isExternal;

  @override
  ProcedureKind get kind {
    switch (_descriptor.kind) {
      case ExtensionMemberKind.Method:
        return ProcedureKind.Method;
      case ExtensionMemberKind.Getter:
        return ProcedureKind.Getter;
      case ExtensionMemberKind.Operator:
        return ProcedureKind.Operator;
      case ExtensionMemberKind.Setter:
        return ProcedureKind.Setter;
      case ExtensionMemberKind.TearOff:
      case ExtensionMemberKind.Field:
    }
    return null;
  }
}

class DillExtensionFieldBuilder extends DillExtensionMemberBuilder {
  final Field field;

  DillExtensionFieldBuilder(
      this.field, ExtensionMemberDescriptor descriptor, Builder parent)
      : super(field, descriptor, parent);

  Member get member => field;

  @override
  Member get readTarget => field;

  @override
  Member get writeTarget => isAssignable ? field : null;

  @override
  Member get invokeTarget => field;

  @override
  bool get isField => true;

  @override
  bool get isAssignable => field.hasSetter;
}

class DillExtensionSetterBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionSetterBuilder(
      this.procedure, ExtensionMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionMemberKind.Setter),
        super(procedure, descriptor, parent);

  Member get member => procedure;

  @override
  Member get readTarget => null;

  @override
  Member get writeTarget => procedure;

  @override
  Member get invokeTarget => null;
}

class DillExtensionGetterBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionGetterBuilder(
      this.procedure, ExtensionMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionMemberKind.Getter),
        super(procedure, descriptor, parent);

  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionOperatorBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionOperatorBuilder(
      this.procedure, ExtensionMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionMemberKind.Operator),
        super(procedure, descriptor, parent);

  Member get member => procedure;

  @override
  Member get readTarget => null;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionStaticMethodBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  DillExtensionStaticMethodBuilder(
      this.procedure, ExtensionMemberDescriptor descriptor, Builder parent)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(descriptor.isStatic),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillExtensionInstanceMethodBuilder extends DillExtensionMemberBuilder {
  final Procedure procedure;

  final Procedure _extensionTearOff;

  DillExtensionInstanceMethodBuilder(
      this.procedure,
      ExtensionMemberDescriptor descriptor,
      Builder parent,
      this._extensionTearOff)
      : assert(descriptor.kind == ExtensionMemberKind.Method),
        assert(!descriptor.isStatic),
        super(procedure, descriptor, parent);

  @override
  Member get member => procedure;

  @override
  Iterable<Member> get exportedMembers => [procedure, _extensionTearOff];

  @override
  Member get readTarget => _extensionTearOff;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}
