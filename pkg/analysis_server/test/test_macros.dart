// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Getters and methods that will return the declarations of macros that are
/// useful for testing.
///
/// The macros do not include imports. They are designed to be passed into
/// [PubPackageAnalysisServerTest.addMacros], which will add the necessary
/// imports automatically.
mixin TestMacros {
  /// Return the declaration of a macro that will add an empty method named
  /// [name] to a class.
  String addMethodMacro({String name = 'm0'}) {
    return '''
macro class AddMethod implements ClassDeclarationsMacro {
  const AddMethod();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromParts(['  void $name() {}' ]));
  }
}
''';
  }
}
