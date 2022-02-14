// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid using private types in public APIs.';

const _details = r'''

**AVOID** using library private types in public APIs.

For the purposes of this lint, a public API is considered to be any top-level or
member declaration unless the declaration is library private or contained in a
declaration that's library private. The following uses of types are checked:

- the return type of a function or method,
- the type of any parameter of a function or method,
- the bound of a type parameter to any function, method, class, mixin,
  extension's extended type, or type alias,
- the type of any top level variable or field,
- any type used in the declaration of a type alias (for example
  `typedef F = _Private Function();`), or
- any type used in the `on` clause of an extension or a mixin

**GOOD:**
```dart
f(String s) { ... }
```

**BAD:**
```dart
f(_Private p) { ... }
class _Private {}
```

''';

class LibraryPrivateTypesInPublicAPI extends LintRule {
  LibraryPrivateTypesInPublicAPI()
      : super(
            name: 'library_private_types_in_public_api',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class Validator extends SimpleAstVisitor<void> {
  LintRule rule;

  Validator(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.superclass2.accept(this);
    node.typeParameters?.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var name = node.name;
    if (name != null && Identifier.isPrivateName(name.name)) {
      return;
    }
    node.parameters.accept(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var name = node.name;
    if (name == null || Identifier.isPrivateName(name.name)) {
      return;
    }
    node.extendedType.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.fields.variables
        .any((field) => !Identifier.isPrivateName(field.name.name))) {
      node.fields.type?.accept(this);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.identifier.name)) {
      return;
    }
    // Check for a declared type.
    var type = node.type;
    if (type != null) {
      type.accept(this);
      return;
    }

    // Check implicit type.
    var element = node.identifier.staticElement;
    if (element is FieldFormalParameterElement &&
        isPrivateName(element.type.element?.name)) {
      rule.reportLint(node.identifier);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.returnType?.accept(this);
    node.functionExpression.typeParameters?.accept(this);
    node.functionExpression.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.identifier.name)) {
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
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (Identifier.isPrivateName(node.name.name)) {
      return;
    }
    node.onClause?.superclassConstraints2.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.name.staticElement;
    if (element != null && isPrivate(element)) {
      rule.reportLint(node.name);
    }
    node.typeArguments?.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var name = node.identifier;
    if (name != null && node.isNamed && Identifier.isPrivateName(name.name)) {
      return;
    }
    node.type?.accept(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    if (node.isNamed && Identifier.isPrivateName(node.identifier.name)) {
      return;
    }

    // Check for a declared type.
    var type = node.type;
    if (type != null) {
      type.accept(this);
      return;
    }

    // Check implicit type.
    var element = node.identifier.staticElement;
    if (element is SuperFormalParameterElement &&
        isPrivateName(element.type.element?.name)) {
      rule.reportLint(node.identifier);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.variables
        .any((field) => !Identifier.isPrivateName(field.name.name))) {
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

class Visitor extends SimpleAstVisitor {
  LintRule rule;

  Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var element = node.declaredElement;
    if (element != null && !Validator.isPrivate(element)) {
      var validator = Validator(rule);
      node.declarations.accept(validator);
    }
  }
}
