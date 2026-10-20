// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';

/// An indication of the kind of context in which a super reference was found.
class SuperContext {
  /// An indication that the super reference is in a context in which it is
  /// invalid because it is in an annotation.
  static const SuperContext annotation = SuperContext._('annotation');

  /// An indication that the super reference is in a context in which it is
  /// invalid because it is in an instance member of an extension.
  static const SuperContext extension = SuperContext._('extension');

  /// An indication that the super reference is in a context in which it is
  /// invalid because it is in an instance member of an extension type.
  static const SuperContext extensionType = SuperContext._('extensionType');

  /// An indication that the super reference is in a context in which it is
  /// invalid because `this` is not available there, such as outside an
  /// instance member, in a constructor initializer, or in a default value of
  /// a member.
  static const SuperContext static = SuperContext._('static');

  /// An indication that the super reference is in a context in which it is
  /// invalid because it is in the body of a parameterless anonymous method.
  static const SuperContext anonymousMethod = SuperContext._('anonymousMethod');

  /// An indication that the super reference is in a context in which it is
  /// valid.
  static const SuperContext valid = SuperContext._('valid');

  /// The name of the context.
  final String name;

  /// Return an indication of the context in which the super [reference] is
  /// being used.
  factory of(SuperReference reference) {
    var inDefaultValue = false;
    for (AstNode? node = reference; node != null; node = node.parent2) {
      if (node is Annotation) {
        return SuperContext.annotation;
      } else if (node case AnonymousMethodBody(
        parent2: AnonymousMethodInvocation(parameters: null),
      )) {
        return SuperContext.anonymousMethod;
      } else if (node is AnonymousMethodInvocation ||
          node is FunctionExpression ||
          node is LocalFunctionDeclaration) {
        inDefaultValue = false;
      } else if (node is ClassDeclaration ||
          node is EnumDeclaration2 ||
          node is MixinDeclaration) {
        return inDefaultValue ? SuperContext.static : SuperContext.valid;
      } else if (node is CompilationUnit) {
        return SuperContext.static;
      } else if (node is ConstructorDeclaration2) {
        if (node.factoryKeyword != null) {
          return SuperContext.static;
        }
      } else if (node is ConstructorInitializer) {
        return SuperContext.static;
      } else if (node is ExtensionDeclaration) {
        return SuperContext.extension;
      } else if (node is ExtensionTypeDeclaration) {
        return SuperContext.extensionType;
      } else if (node is FieldsDeclaration) {
        if (node.staticKeyword != null) {
          return SuperContext.static;
        }
        if (node.lateKeyword == null) {
          return SuperContext.static;
        }
      } else if (node is FormalParameterDefaultClause) {
        inDefaultValue = true;
      } else if (node is MethodDeclarationV1OriginImpl) {
        if (node.staticKeyword != null) {
          return SuperContext.static;
        }
      }
    }
    return SuperContext.static;
  }

  const new _(this.name);
}
