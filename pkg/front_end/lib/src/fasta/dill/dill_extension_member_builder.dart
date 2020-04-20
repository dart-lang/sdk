// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../builder/builder.dart';

import '../problems.dart';

import 'dill_member_builder.dart';

class DillExtensionMemberBuilder extends DillMemberBuilder {
  final ExtensionMemberDescriptor _descriptor;

  final Member _extensionTearOff;

  DillExtensionMemberBuilder(Member member, this._descriptor, Builder parent,
      [this._extensionTearOff])
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

  @override
  Member get readTarget {
    if (isField) {
      return member;
    }
    switch (kind) {
      case ProcedureKind.Method:
        return _extensionTearOff ?? member;
      case ProcedureKind.Getter:
        return member;
      case ProcedureKind.Operator:
      case ProcedureKind.Setter:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get writeTarget {
    if (isField) {
      return isAssignable ? member : null;
    }
    switch (kind) {
      case ProcedureKind.Setter:
        return member;
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get invokeTarget {
    if (isField) {
      return member;
    }
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return member;
      case ProcedureKind.Setter:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  bool get isAssignable => member is Field && member.hasSetter;
}
