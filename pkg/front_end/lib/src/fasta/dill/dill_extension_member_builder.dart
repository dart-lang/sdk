// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../builder/declaration.dart';

import '../problems.dart';

import 'dill_member_builder.dart';

class DillExtensionMemberBuilder extends DillMemberBuilder {
  final ExtensionMemberDescriptor _descriptor;

  @override
  final Member extensionTearOff;

  DillExtensionMemberBuilder(Member member, this._descriptor, Builder parent,
      [this.extensionTearOff])
      : super(member, parent);

  @override
  bool get isStatic => _descriptor.isStatic;

  @override
  bool get isExternal => member.isExternal;

  @override
  Procedure get procedure {
    switch (_descriptor.kind) {
      case ExtensionMemberKind.Method:
      case ExtensionMemberKind.Getter:
      case ExtensionMemberKind.Operator:
      case ExtensionMemberKind.Setter:
        return member;
      case ExtensionMemberKind.TearOff:
      case ExtensionMemberKind.Field:
    }
    return unsupported("procedure", charOffset, fileUri);
  }

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
