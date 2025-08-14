// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';

/// Helper for verifying the validity of @Preview(...) applications.
///
/// The Flutter Widget Previewer relies on code generation to import code from
/// a developer's project into a generated 'widget preview scaffold' that lives
/// in the project's '.dart_tool' directory. The nature of this implementation
/// means that any symbols referenced in the declaration of the preview (e.g.,
/// in the invocation of the `Preview(...)` constructor or the name of the
/// preview function) must be publicly accessible from outside the library in
/// which they are defined. One of the main uses for this verifier is to flag
/// usages of private symbols within preview declarations.
///
/// This verifier also ensures that the `@Preview(...)` annotation can only be
/// applied to a functions or constructors that:
///
///  - Are statically accessible (e.g., no instance methods)
///  - Have explicit implementations (e.g., not abstract or external)
class WidgetPreviewVerifier {
  final DiagnosticReporter _diagnosticReporter;

  WidgetPreviewVerifier(this._diagnosticReporter);

  /// Check is [node] is a Widget Preview application and verify its
  /// correctness.
  void checkAnnotation(Annotation node) {
    if (node.elementAnnotation?.isWidgetPreview ?? false) {
      _checkWidgetPreview(node);
    }
  }

  void _checkWidgetPreview(Annotation node) {
    if (node.arguments == null) {
      // This is an invalid annotation application since there's no constructor
      // invocation.
      return;
    }

    var parent = node.parent;
    bool isValidApplication = switch (parent) {
      // First, check that the preview application is happening in a supported
      // context.
      _ when !_isSupportedParent(node: parent) => false,
      ConstructorDeclaration() => _isValidConstructorPreviewApplication(
        declaration: parent,
      ),
      FunctionDeclaration() => _isValidFunctionPreviewApplication(
        declaration: parent,
      ),
      MethodDeclaration() => _isValidMethodPreviewApplication(
        declaration: parent,
      ),
      _ => false,
    };

    if (!isValidApplication) {
      _diagnosticReporter.atNode(
        node.name,
        WarningCode.invalidWidgetPreviewApplication,
      );
    }

    var visitor = _InvalidWidgetPreviewArgumentDetectorVisitor(
      errorReporter: _diagnosticReporter,
    );
    node.arguments!.accept(visitor);
  }

  bool _hasRequiredParameters(NodeList<FormalParameter> parameters) {
    return parameters.any((e) => e.isRequired);
  }

  /// Returns true if `name` is private or `node.parent` is a [ClassDeclaration]
  /// that has a private name.
  bool _isPrivateContext({required Token? name, required AstNode node}) {
    if (Identifier.isPrivateName(name?.lexeme ?? '')) {
      return true;
    }
    var parent = node.parent;
    if (parent == null) return false;

    return switch (parent) {
      ClassDeclaration(:var name) => Identifier.isPrivateName(name.lexeme),
      EnumDeclaration(:var name) => Identifier.isPrivateName(name.lexeme),
      ExtensionDeclaration(:var name) => Identifier.isPrivateName(
        name?.lexeme ?? '',
      ),
      ExtensionTypeDeclaration(:var name) => Identifier.isPrivateName(
        name.lexeme,
      ),
      MixinDeclaration(:var name) => Identifier.isPrivateName(name.lexeme),
      _ => false,
    };
  }

  /// Returns true if `node.parent` is a supported context for defining widget
  /// previews.
  ///
  /// Currently, this only includes previews defined within classes and at the
  /// top level of a compilation unit.
  bool _isSupportedParent({required AstNode node}) {
    return switch (node.parent) {
      ClassDeclaration() || CompilationUnit() => true,
      _ => false,
    };
  }

  /// Returns true if `declaration` is a valid constructor target for a widget
  /// preview application.
  ///
  /// Constructor preview applications are valid if:
  ///   - The class and constructor names are public
  ///   - The class is a subtype of Widget
  ///   - The class is not abstract or is a valid factory constructor
  ///   - The constructor is not external
  ///   - The constructor does not have any required arguments
  bool _isValidConstructorPreviewApplication({
    required ConstructorDeclaration declaration,
  }) {
    if (declaration case ConstructorDeclaration(
      :var name,
      :var externalKeyword,
      :var factoryKeyword,
      parent: ClassDeclaration(declaredFragment: ClassFragment(:var element)),
      parameters: FormalParameterList(:var parameters),
    )) {
      return !_isPrivateContext(name: name, node: declaration) &&
          element.isWidget &&
          !(element.isAbstract && factoryKeyword == null) &&
          externalKeyword == null &&
          !_hasRequiredParameters(parameters);
    }
    return false;
  }

  /// Returns true if `declaration` is a valid top-level function target for a
  /// widget preview application.
  ///
  /// Function preview applications are valid if:
  ///   - The function name is public
  ///   - The function is not a nested function
  ///   - The function is not external
  ///   - The function returns a subtype of `Widget` or `WidgetBuilder`
  ///   - The function does not have any required arguments
  bool _isValidFunctionPreviewApplication({
    required FunctionDeclaration declaration,
  }) {
    if (declaration case FunctionDeclaration(
      :var name,
      :var externalKeyword,
      :NamedType returnType,
      functionExpression: FunctionExpression(
        parameters: FormalParameterList(:var parameters),
      ),
    )) {
      return !_isPrivateContext(name: name, node: declaration) &&
          // Check for nested function.
          declaration.parent is! FunctionDeclarationStatement &&
          externalKeyword == null &&
          returnType.isValidWidgetPreviewReturnType &&
          !_hasRequiredParameters(parameters);
    }
    return false;
  }

  /// Returns true if `declaration` is a valid static class member target for a
  /// widget preview application.
  ///
  /// Class member preview applications are valid if:
  ///   - The function is static
  ///   - The function name is public
  ///   - The function is not external
  ///   - The function returns a subtype of `Widget` or `WidgetBuilder`
  ///   - The function does not have any required arguments
  bool _isValidMethodPreviewApplication({
    required MethodDeclaration declaration,
  }) {
    if (declaration case MethodDeclaration(
      :var isStatic,
      :var externalKeyword,
      :var name,
      :NamedType returnType,
      parameters: FormalParameterList(:var parameters),
    )) {
      return !_isPrivateContext(name: name, node: declaration) &&
          isStatic &&
          // Check for nested function.
          declaration.parent is! FunctionDeclarationStatement &&
          externalKeyword == null &&
          returnType.isValidWidgetPreviewReturnType &&
          !_hasRequiredParameters(parameters);
    }
    return false;
  }
}

class _InvalidWidgetPreviewArgumentDetectorVisitor extends RecursiveAstVisitor {
  final DiagnosticReporter errorReporter;

  NamedExpression? rootArgument;
  _InvalidWidgetPreviewArgumentDetectorVisitor({required this.errorReporter});

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      // All arguments to Preview(...) are named.
      if (argument is NamedExpression) {
        rootArgument = argument;
        visitNamedExpression(argument);
        rootArgument = null;
      }
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    super.visitNamedExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (Identifier.isPrivateName(node.name)) {
      errorReporter.atNode(
        rootArgument!,
        WarningCode.invalidWidgetPreviewPrivateArgument,
        arguments: [node.name, node.name.replaceFirst(RegExp('_*'), '')],
      );
    }
    super.visitSimpleIdentifier(node);
  }
}
