// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// AST visitor that collects names that are referenced, but the target element
/// is not defined in the syntactic scope of the reference.  Resolution of
/// such names will change when the import scope of the library changes.
class NotSyntacticScopeReferencedNamesCollector
    extends GeneralizingAstVisitor<void> {
  /// The library that contains resolved AST(s) being visited.
  final LibraryElement enclosingLibraryElement;

  /// The names that we need to check.
  final Set<String> interestingNames;

  /// All the referenced unqualified names.
  final Set<String> referencedNames = Set<String>();

  /// The subset of [interestingNames] that are resolved to a top-level
  /// element that is not in the syntactic scope of the reference, and the
  /// library [Uri] is the value in the mapping.
  final Map<String, Uri> importedNames = {};

  /// The subset of [interestingNames] that are resolved to inherited names.
  final Set<String> inheritedNames = Set<String>();

  Element enclosingUnitMemberElement;

  NotSyntacticScopeReferencedNamesCollector(
    this.enclosingLibraryElement,
    this.interestingNames,
  );

  @override
  void visitCombinator(Combinator node) {}

  @override
  void visitCompilationUnitMember(CompilationUnitMember node) {
    enclosingUnitMemberElement = node.declaredElement;
    super.visitCompilationUnitMember(node);
    enclosingUnitMemberElement = null;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var name = node.name;
    referencedNames.add(name);

    if (node.isQualified) return;
    if (!interestingNames.contains(name)) return;

    var element = node.staticElement;
    if (element == null) return;

    if (_inSyntacticScope(element)) return;

    if (element.enclosingElement is CompilationUnitElement) {
      importedNames[name] = element.librarySource.uri;
    } else {
      inheritedNames.add(name);
    }
  }

  bool _inSyntacticScope(Element element) {
    if (element.enclosingElement is CompilationUnitElement &&
        element.enclosingElement.enclosingElement == enclosingLibraryElement) {
      return true;
    }

    while (element != null) {
      if (element == enclosingUnitMemberElement) return true;
      element = element.enclosingElement;
    }
    return false;
  }
}

/// AST visitor that collects syntactic scope names visible at the [offset].
///
/// The AST does not need to be resolved.
class SyntacticScopeNamesCollector extends RecursiveAstVisitor<void> {
  final Set<String> names;
  final int offset;

  SyntacticScopeNamesCollector(this.names, this.offset);

  @override
  void visitBlock(Block node) {
    if (!_isCoveredBy(node)) return;

    super.visitBlock(node);

    for (var statement in node.statements) {
      if (statement is FunctionDeclarationStatement) {
        _addName(statement.functionDeclaration.name);
      } else if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables);
      }
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    if (!_isCoveredBy(node)) return;

    if (node.exceptionParameter != null) {
      _addName(node.exceptionParameter);
    }

    if (node.stackTraceParameter != null) {
      _addName(node.stackTraceParameter);
    }

    node.body.accept(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);
    _visitClassOrMixinMembers(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (!_isCoveredBy(node)) return;
    _addTypeParameters(node.typeParameters);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!_isCoveredBy(node)) return;

    _addFormalParameters(node.parameters);

    node.body.accept(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    var variableList = node.fields;

    // `Foo^ Foo bar() {}` is recovered as `Foo Foo; bar() {}`, i.e. the
    // return type of `bar()` gets associated with a new variable declaration.
    if (node.semicolon.isSynthetic) {
      if (variableList.variables.length == 1) {
        var name = variableList.variables[0].name.name;
        names.remove(name);
      }
    }

    super.visitFieldDeclaration(node);
  }

  @override
  void visitForElement(ForElement node) {
    if (!_isCoveredBy(node)) return;

    _addForLoopParts(node.forLoopParts, node.body);

    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (!_isCoveredBy(node)) return;

    _addForLoopParts(node.forLoopParts, node.body);

    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_isCoveredBy(node)) return;

    var function = node.functionExpression;
    _addTypeParameters(function.typeParameters);

    if (function.parameters != null && offset > function.parameters.offset) {
      _addFormalParameters(function.parameters);
    }

    function.body.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);

    if (offset > node.parameters.offset) {
      _addFormalParameters(node.parameters);
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);

    if (offset > node.parameters.offset) {
      _addFormalParameters(node.parameters);
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);

    node.functionType.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);

    if (node.parameters != null && offset > node.parameters.offset) {
      _addFormalParameters(node.parameters);
    }

    node.body.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (!_isCoveredBy(node)) return;

    _addTypeParameters(node.typeParameters);
    _visitClassOrMixinMembers(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // `TypeName^` is recovered as `<noType> TypeName;`, remove the name.
    var variableList = node.variables;
    if (variableList.keyword == null && variableList.type == null) {
      for (var variable in variableList.variables) {
        names.remove(variable.name.name);
      }
      return;
    }

    // `Foo^ Foo bar() {}` is recovered as `Foo Foo; bar() {}`, i.e. the
    // return type of `bar()` gets associated with a new variable declaration.
    if (node.semicolon.isSynthetic) {
      if (variableList.variables.length == 1) {
        var name = variableList.variables[0].name.name;
        names.remove(name);
      }
    }

    super.visitTopLevelVariableDeclaration(node);
  }

  void _addForLoopParts(ForLoopParts forLoopParts, AstNode body) {
    if (forLoopParts is ForEachPartsWithDeclaration) {
      if (_isCoveredBy(body)) {
        _addName(forLoopParts.loopVariable.identifier);
      }
    } else if (forLoopParts is ForPartsWithDeclarations) {
      _addVariables(forLoopParts.variables);
    }
  }

  void _addFormalParameter(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      _addFormalParameter(parameter.parameter);
    } else if (parameter is FieldFormalParameter) {
      _addName(parameter.identifier);
    } else if (parameter is FunctionTypedFormalParameter) {
      _addName(parameter.identifier);
      var parameters = parameter.parameters;
      if (parameters != null && _isCoveredBy(parameters)) {
        _addFormalParameters(parameters);
      }
    } else if (parameter is SimpleFormalParameter) {
      _addName(parameter.identifier);
    } else {
      throw UnimplementedError('(${parameter.runtimeType}) $parameter');
    }
  }

  void _addFormalParameters(FormalParameterList parameterList) {
    for (var parameter in parameterList.parameters) {
      _addFormalParameter(parameter);
    }
  }

  void _addName(SimpleIdentifier node) {
    if (node == null) return;
    if (node.offset <= offset && offset <= node.end) return;

    names.add(node.name);
  }

  void _addTypeParameters(TypeParameterList typeParameterList) {
    if (typeParameterList == null) return;

    for (var typeParameter in typeParameterList.typeParameters) {
      _addName(typeParameter.name);
    }
  }

  void _addVariables(VariableDeclarationList variableList) {
    for (var field in variableList.variables) {
      _addName(field.name);
    }
  }

  bool _isCoveredBy(AstNode node) {
    return node.offset < offset && offset < node.end;
  }

  void _visitClassOrMixinMembers(ClassOrMixinDeclaration node) {
    if (offset < node.leftBracket.offset) return;

    for (var member in node.members) {
      if (member is FieldDeclaration) {
        _addVariables(member.fields);
      } else if (member is MethodDeclaration) {
        _addName(member.name);
      }
    }

    node.members.accept(this);
  }
}
