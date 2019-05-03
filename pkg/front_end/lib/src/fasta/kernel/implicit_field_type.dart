// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Visitor;

import '../../scanner/token.dart' show Token;

import '../problems.dart' show unsupported;

import 'kernel_builder.dart' show MemberBuilder;

class ImplicitFieldType extends DartType {
  final MemberBuilder member;
  final Token initializerToken;

  const ImplicitFieldType(this.member, this.initializerToken);

  accept(DartTypeVisitor<Object> v) {
    unsupported("accept", member.charOffset, member.fileUri);
  }

  accept1(DartTypeVisitor1<Object, Object> v, arg) {
    unsupported("accept1", member.charOffset, member.fileUri);
  }

  visitChildren(Visitor<Object> v) {
    unsupported("visitChildren", member.charOffset, member.fileUri);
  }
}
