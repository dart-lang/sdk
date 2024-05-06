// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: deprecated_member_use
import 'package:macros/macros.dart';

macro class ThrowOther implements ClassDeclarationsMacro {
  final Object other;

  const ThrowOther({required this.other});

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    throw other;
  }
}
