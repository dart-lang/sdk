// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Nullability, Visitor;

import '../builder/member_builder.dart';

import '../problems.dart' show unsupported;

class ImplicitFieldType extends DartType {
  final MemberBuilder memberBuilder;
  Token initializerToken;
  bool isStarted = false;

  ImplicitFieldType(this.memberBuilder, this.initializerToken);

  Nullability get nullability => unsupported(
      "nullability", memberBuilder.charOffset, memberBuilder.fileUri);

  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported(
        "accept", memberBuilder.charOffset, memberBuilder.fileUri);
  }

  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported(
        "accept1", memberBuilder.charOffset, memberBuilder.fileUri);
  }

  visitChildren(Visitor<Object> v) {
    unsupported(
        "visitChildren", memberBuilder.charOffset, memberBuilder.fileUri);
  }

  ImplicitFieldType withNullability(Nullability nullability) {
    return unsupported(
        "withNullability", memberBuilder.charOffset, memberBuilder.fileUri);
  }
}
