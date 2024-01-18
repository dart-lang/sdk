// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin TestMacros {
  /// A macro that can be applied to a class to add a `foo()` method that calls
  /// a bar() method.
  final withFooMethodMacro = r'''
// There is no public API exposed yet, the in-progress API lives here.
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class WithFoo implements ClassDeclarationsMacro {
  const WithFoo();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    builder.declareInType(DeclarationCode.fromString('void foo() {bar();}'));
  }
}
''';
}
