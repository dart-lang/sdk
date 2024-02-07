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
  /// Return the declaration of a macro that will add a member to a library.
  ///
  /// The text of the member is provided as an argument to the macro.
  String declareInLibraryMacro() {
    return '''
macro class DeclareInLibrary
    implements ClassDeclarationsMacro, FunctionDeclarationsMacro {
  final String code;

  const DeclareInLibrary(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declare(builder);
  }

  @override
  buildDeclarationsForFunction(clazz, builder) async {
    await _declare(builder);
  }

  Future<void> _declare(DeclarationBuilder builder) async {
    builder.declareInLibrary(
      DeclarationCode.fromString(code),
    );
  }
}
''';
  }

  /// Return the declaration of a macro that will add a member to a type.
  ///
  /// The text of the member is provided as an argument to the macro.
  String declareInTypeMacro() {
    return '''
macro class DeclareInType
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        FieldDeclarationsMacro,
        MethodDeclarationsMacro {
  final String code;

  const DeclareInType(this.code);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    _declare(builder);
  }

  @override
  buildDeclarationsForConstructor(constructor, builder) async {
    _declare(builder);
  }

  @override
  buildDeclarationsForField(field, builder) async {
    _declare(builder);
  }

  @override
  buildDeclarationsForMethod(method, builder) async {
    _declare(builder);
  }

  void _declare(MemberDeclarationBuilder builder) {
    builder.declareInType(
      DeclarationCode.fromString(code),
    );
  }
}
''';
  }
}
