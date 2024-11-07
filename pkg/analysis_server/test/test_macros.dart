// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

import 'support/configuration_files.dart';

/// Getters and methods that will return the declarations of macros that are
/// useful for testing.
///
/// The macros do not include imports. They are designed to be passed into
/// [addMacros], which will add the necessary imports automatically.
mixin TestMacros on ConfigurationFilesMixin {
  /// Adds support for macros to the `package_config.json` file and creates a
  /// `macros.dart` file that defines the given [macros]. The macros should not
  /// include imports, the imports for macros will be added automatically.
  void addMacros(List<String> macros, {bool isFlutter = false}) {
    writeTestPackageConfig(flutter: isFlutter, macro: true);

    newFile(
      '$testPackageRootPath/lib/macros.dart',
      [
        '''
// There is no public API exposed yet, the in-progress API lives here.
import 'package:macros/macros.dart';
''',
        ...macros,
      ].join('\n'),
    );
  }

  /// Return the declaration of a macro that will add a member to a library.
  ///
  /// The text of the member to be declared is provided as an argument to the
  /// macro that is returned. For example, the following can be used to generate
  /// a top level function in the library containing the class `C`:
  /// ```dart
  /// @DeclareInLibrary('void generatedTopLevelFunction() {}')
  /// class C {}
  /// ```
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
  /// The text of the member to be declared is provided as an argument to the
  /// macro that is returned. For example, the following can be used to generate
  /// a method in the class `C`:
  /// ```dart
  /// @DeclareInType('  void generatedMethod() {}')
  /// class C {}
  /// ```
  /// (Adding the indent makes the content of the generated code look nicer, but
  /// isn't required.)
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

  String declareTypesPhaseMacro() {
    return '''
macro class DeclareTypesPhase
    implements ClassTypesMacro, FunctionTypesMacro {
  final String typeName;
  final String code;

  const DeclareTypesPhase(this.typeName, this.code);

  @override
  buildTypesForClass(clazz, builder) async {
    await _declare(builder);
  }

  @override
  buildTypesForFunction(clazz, builder) async {
    await _declare(builder);
  }

  Future<void> _declare(TypeBuilder builder) async {
    builder.declareType(
      typeName,
      DeclarationCode.fromString(code),
    );
  }
}
''';
  }

  File newFile(String path, String content);
}
