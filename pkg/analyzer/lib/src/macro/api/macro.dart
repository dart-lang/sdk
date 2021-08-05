// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/macro/api/code.dart';

/// The api used by [DeclarationMacro]s to contribute new declarations to the
/// current class.
///
/// Note that this is available to macros that run directly on classes, as well
/// as macros that run on any members of a class.
abstract class ClassDeclarationBuilder implements DeclarationBuilder {
  /// Adds a new declaration to the surrounding class.
  void addToClass(Declaration declaration);
}

/// The interface for [DeclarationMacro]s that can be applied to classes.
abstract class ClassDeclarationMacro implements DeclarationMacro {
  void visitClassDeclaration(
      ast.ClassDeclaration declaration, ClassDeclarationBuilder builder);
}

/// The api used by [DeclarationMacro]s to contribute new declarations to the
/// current library.
abstract class DeclarationBuilder {
  /// Adds a new regular declaration to the surrounding library.
  ///
  /// Note that type declarations are not supported.
  void addToLibrary(Declaration declaration);

  /// Return the [Code] of the [node].
  Code typeAnnotationCode(ast.TypeAnnotation node);
}

/// The marker interface for macros that are allowed to contribute new
/// declarations to the program, including both top level and class level
/// declarations.
///
/// These macros run after [TypeMacro] macros, but before [DefinitionMacro]
/// macros.
///
/// These macros can resolve type annotations to specific declarations, and
/// inspect type hierarchies, but they cannot inspect the declarations on those
/// type annotations, since new declarations could still be added in this phase.
abstract class DeclarationMacro implements Macro {}

/// The marker interface for macros that are only allowed to implement or wrap
/// existing declarations in the program. They cannot introduce any new
/// declarations that are visible to the program, but are allowed to add
/// declarations that only they can see.
///
/// These macros run after all other types of macros.
///
/// These macros can fully reflect on the program since the static shape is
/// fully defined by the time they run.
abstract class DefinitionMacro implements Macro {}

/// The interface for [DeclarationMacro]s that can be applied to fields.
abstract class FieldDeclarationMacro implements DeclarationMacro {
  void visitFieldDeclaration(
    ast.FieldDeclaration declaration,
    ClassDeclarationBuilder builder,
  );
}

/// The marker interface for all types of macros.
abstract class Macro {}

/// The marker interface for macros that are allowed to contribute new type
/// declarations into the program.
///
/// These macros run before all other types of macros.
///
/// In exchange for the power to add new type declarations, these macros have
/// limited introspections capabilities, since new types can be added in this
/// phase you cannot follow type references back to their declarations.
abstract class TypeMacro implements Macro {}
