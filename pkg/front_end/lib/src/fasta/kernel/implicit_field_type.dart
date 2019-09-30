// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Nullability, Visitor;

import '../../scanner/token.dart' show Token;

import '../problems.dart' show unsupported;

import 'kernel_builder.dart' show MemberBuilder;

class ImplicitFieldType extends DartType {
  final MemberBuilder member;
  Token initializerToken;
  bool isStarted = false;

  ImplicitFieldType(this.member, this.initializerToken);

  Nullability get nullability =>
      unsupported("nullability", member.charOffset, member.fileUri);

  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported("accept", member.charOffset, member.fileUri);
  }

  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported("accept1", member.charOffset, member.fileUri);
  }

  visitChildren(Visitor<Object> v) {
    unsupported("visitChildren", member.charOffset, member.fileUri);
  }

  ImplicitFieldType withNullability(Nullability nullability) {
    return unsupported("withNullability", member.charOffset, member.fileUri);
  }
}
