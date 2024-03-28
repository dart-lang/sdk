// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

import 'impl.dart';

macro class ClassTypesDeclareType implements ClassTypesMacro {
  final String name;
  final String code;

  const ClassTypesDeclareType({required this.name, required this.code});

  @override
  Future<void> buildTypesForClass(
      ClassDeclaration clazz, ClassTypeBuilder builder) async {
    builder.declareType(name, await builder.code(code));
  }
}
