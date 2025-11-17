// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Avoid using private types in public APIs.';

class LibraryPrivateTypesInPublicApi extends AnalysisRule {
  LibraryPrivateTypesInPublicApi()
    : super(
        name: LintNames.library_private_types_in_public_api,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.libraryPrivateTypesInPublicApi;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class Validator extends SimpleAstVisitor<void> {
  AnalysisRule rule;

  Validator(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (Identifier.isPrivateName(node.namePart.typeName.lexeme)) {
      return;
    }
    node.namePart.typeParameters?.accept(this);
    if (node.body case BlockClassBody body) {
      body.members.accept(this);
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.superclass.accept(this);
    node.typeParameters?.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var name = node.name;
    if (name != null && Identifier.isPrivateName(name.lexeme)) {
      return;
    }

    var parent = node.parent?.parent;

    // Enum constructors are effectively private so don't visit their params.
    if (parent is EnumDeclaration) return;

    // Select modified class types are also effectively private.
    if (parent != null && parent.isEffectivelyPrivate) return;

    node.parameters.accept(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (Identifier.isPrivateName(node.namePart.typeName.lexeme)) {
      return;
    }
    node.namePart.typeParameters?.accept(this);
    node.body.members.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var name = node.name;
    if (name == null || Identifier.isPrivateName(name.lexeme)) {
      return;
    }
    node.typeParameters?.accept(this);
    node.onClause?.extendedType.accept(this);
    node.body.members.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (Identifier.isPrivateName(node.primaryConstructor.typeName.lexeme)) {
      return;
    }
    node.primaryConstructor.typeParameters?.accept(this);

    for (var formalParameter
        in node.primaryConstructor.formalParameters.parameters) {
      if (formalParameter is SimpleFormalParameter) {
        var name = formalParameter.name;
        if (name != null && !Identifier.isPrivateName(name.lexeme)) {
          formalParameter.type!.accept(this);
        }
      }
    }

    if (node.body case BlockClassBody body) {
      body.members.accept(this);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isInvalidExtensionTypeField) return;
    if (node.fields.variables.any(
      (field) => !Identifier.isPrivateName(field.name.lexeme),
    )) {
      node.fields.type?.accept(this);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    // Check for a declared type.
    var type = node.type;
    if (type != null) {
      type.accept(this);
      return;
    }

    // Check implicit type.
    var element = node.declaredFragment?.element;
    if (element is FieldFormalParameterElement) {
      var type = element.type;
      if (type is InterfaceType && isPrivateName(type.element.name)) {
        rule.reportAtToken(node.name);
      }
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.returnType?.accept(this);
    node.functionExpression.typeParameters?.accept(this);
    node.functionExpression.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }
    node.onClause?.superclassConstraints.accept(this);
    node.typeParameters?.accept(this);
    node.body.members.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.element;
    if (element != null && isPrivate(element)) {
      rule.reportAtToken(node.name);
    }
    node.typeArguments?.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var name = node.name;
    if (name != null && node.isNamed && Identifier.isPrivateName(name.lexeme)) {
      return;
    }
    node.type?.accept(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.name.lexeme)) {
      return;
    }

    // Check for a declared type.
    var type = node.type;
    if (type != null) {
      type.accept(this);
      return;
    }

    // Check implicit type.
    var element = node.declaredFragment?.element;
    if (element is SuperFormalParameterElement) {
      var type = element.type;
      if (type is InterfaceType && isPrivateName(type.element.name)) {
        rule.reportAtToken(node.name);
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.variables.any(
      (field) => !Identifier.isPrivateName(field.name.lexeme),
    )) {
      node.variables.type?.accept(this);
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.bound?.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  /// Return `true` if the given [element] is private or is defined in a private
  /// library.
  static bool isPrivate(Element element) => isPrivateName(element.name);

  static bool isPrivateName(String? name) =>
      name != null && Identifier.isPrivateName(name);
}

class Visitor extends SimpleAstVisitor<void> {
  AnalysisRule rule;

  Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var element = node.declaredFragment?.element;
    if (element != null && !Validator.isPrivate(element)) {
      var validator = Validator(rule);
      node.declarations.accept(validator);
    }
  }
}
