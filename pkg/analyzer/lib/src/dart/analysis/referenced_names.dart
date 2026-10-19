// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/analysis/analyzer_diagnostic_expectations.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// Compute the set of external names referenced in the [unit].
Set<String> computeReferencedNames(
  CompilationUnit unit, {
  bool includeAnalyzerDiagnosticExpectations = false,
}) {
  _ReferencedNamesComputer computer = _ReferencedNamesComputer(
    includeAnalyzerDiagnosticExpectations:
        includeAnalyzerDiagnosticExpectations,
  );
  unit.accept2(computer);
  return computer.names;
}

/// Compute the set of names which are used in `extends`, `with` or `implements`
/// clauses in the file. Import prefixes and type arguments are not included.
Set<String> computeSubtypedNames(CompilationUnit unit) {
  Set<String> subtypedNames = <String>{};

  void addSubtypedName(NamedType? type) {
    if (type != null) {
      subtypedNames.add(type.name.lexeme);
    }
  }

  void addSubtypedNames(List<NamedType>? types) {
    types?.forEach(addSubtypedName);
  }

  for (var declaration in unit.declarations2) {
    if (declaration is ClassDeclaration) {
      addSubtypedName(declaration.extendsClause?.superclass);
      addSubtypedNames(declaration.withClause?.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is ClassTypeAlias) {
      addSubtypedName(declaration.superclass);
      addSubtypedNames(declaration.withClause.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is EnumDeclaration) {
      addSubtypedNames(declaration.withClause?.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is ExtensionTypeDeclaration) {
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is MixinDeclaration) {
      addSubtypedNames(declaration.onClause?.superclassConstraints);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    }
  }

  return subtypedNames;
}

/// Chained set of local names, that hide corresponding external names.
class _LocalNameScope {
  final _LocalNameScope? enclosing;
  Set<String>? names;

  new(this.enclosing);

  factory forBlock(_LocalNameScope enclosing, Block node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    for (Statement statement in node.statements2) {
      if (statement is LocalFunctionDeclaration) {
        scope.add(statement.name);
      } else if (statement is LocalVariablesDeclarationStatement) {
        for (var variable in statement.declaration.variables) {
          scope.add(variable.name);
        }
      }
    }
    return scope;
  }

  factory forClass(_LocalNameScope enclosing, ClassDeclarationImpl node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.namePart.typeParameters);
    for (var member in node.body.members2) {
      if (member is FieldsDeclarationImpl) {
        for (var field in member.fields) {
          scope.add(field.name);
        }
      } else if (member is MethodDeclarationV1OriginImpl) {
        scope.add(member.nameToken);
      }
    }
    return scope;
  }

  factory forClassTypeAlias(_LocalNameScope enclosing, ClassTypeAlias node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    return scope;
  }

  factory forConstructor(
    _LocalNameScope enclosing,
    ConstructorDeclaration node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addFormalParameters(node.parameters);
    return scope;
  }

  factory forExtensionType(
    _LocalNameScope enclosing,
    ExtensionTypeDeclarationImpl node,
  ) {
    var scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.namePart.typeParameters);
    for (var member in node.body.members2) {
      if (member is FieldsDeclarationImpl) {
        for (var field in member.fields) {
          scope.add(field.name);
        }
      } else if (member is MethodDeclarationV1OriginImpl) {
        scope.add(member.nameToken);
      }
    }
    return scope;
  }

  factory forFunctionTypeAlias(
    _LocalNameScope enclosing,
    FunctionTypeAlias2 node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    return scope;
  }

  factory forLocalFunction(
    _LocalNameScope enclosing,
    LocalFunctionDeclaration node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    scope.addFormalParameters(node.formalParameters);
    return scope;
  }

  factory forMethod(
    _LocalNameScope enclosing,
    MethodDeclarationV1OriginImpl node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.writtenTypeParameters);
    scope.addFormalParameters(node.writtenFormalParameters);
    return scope;
  }

  factory forTopLevelFunction(
    _LocalNameScope enclosing,
    TopLevelFunctionDeclarationImpl node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    scope.addFormalParameters(node.formalParameters);
    return scope;
  }

  factory forTopLevelGetter(
    _LocalNameScope enclosing,
    TopLevelGetterDeclarationImpl node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addFormalParameters(node.recoveryFormalParameters);
    return scope;
  }

  factory forTopLevelSetter(
    _LocalNameScope enclosing,
    TopLevelSetterDeclarationImpl node,
  ) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addFormalParameters(node.formalParameters);
    return scope;
  }

  factory forUnit(CompilationUnitImpl node) {
    _LocalNameScope scope = _LocalNameScope(null);
    for (var declaration in node.declarations2) {
      switch (declaration) {
        case ClassDeclarationImpl():
          scope.add(declaration.namePart.typeName);
        case EnumDeclarationImpl():
          scope.add(declaration.namePart.typeName);
        case ExtensionDeclarationImpl():
          scope.add(declaration.name);
        case ExtensionTypeDeclarationImpl():
          scope.add(declaration.namePart.typeName);
        case MixinDeclarationImpl():
          scope.add(declaration.name);
        case TopLevelFunctionDeclarationImpl():
          scope.add(declaration.name);
        case TopLevelVariablesDeclarationImpl():
          for (var variable in declaration.variables) {
            scope.add(variable.name);
          }
        case TopLevelGetterDeclarationImpl():
          scope.add(declaration.name);
        case TopLevelSetterDeclarationImpl():
          scope.add(declaration.name);
        case ClassTypeAliasImpl():
          scope.add(declaration.name);
        case FunctionTypeAlias2Impl():
          scope.add(declaration.name);
        case GenericTypeAlias2Impl():
          scope.add(declaration.name);
      }
    }
    return scope;
  }

  void add(Token? token) {
    if (token != null) {
      (names ??= <String>{}).add(token.lexeme);
    }
  }

  void addFormalParameters(FormalParameterList? parameterList) {
    if (parameterList != null) {
      for (var p in parameterList.allFormalParameters) {
        add(p.name);
      }
    }
  }

  void addTypeParameters(TypeParameterList? typeParameterList) {
    if (typeParameterList != null) {
      typeParameterList.typeParameters.map((p) => p.name).forEach(add);
    }
  }

  bool contains(String name) {
    if (names != null && names!.contains(name)) {
      return true;
    }
    if (enclosing != null) {
      return enclosing!.contains(name);
    }
    return false;
  }
}

class _ReferencedNamesComputer extends UnifyingAstVisitor2<void> {
  final bool includeAnalyzerDiagnosticExpectations;
  final Set<String> names = <String>{};
  final Set<String> importPrefixNames = <String>{};

  _LocalNameScope localScope = _LocalNameScope(null);

  new({required this.includeAnalyzerDiagnosticExpectations});

  @override
  void visitBlock(Block node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forBlock(localScope, node);
      super.visitBlock(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitCascadePropertyAssignmentTarget(
    CascadePropertyAssignmentTarget node,
  ) {
    names.add(node.name.lexeme);
  }

  @override
  void visitCascadePropertyExtraction(CascadePropertyExtraction node) {
    names.add(node.name.lexeme);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forClass(localScope, node);
      super.visitClassDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forClassTypeAlias(localScope, node);
      super.visitClassTypeAlias(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitCombinatorName(CombinatorName node) {
    names.add(node.name.lexeme);
  }

  @override
  void visitCommentReferenceComponent(CommentReferenceComponent node) {
    var name = node.name.lexeme;
    if (node.period != null ||
        !localScope.contains(name) && !importPrefixNames.contains(name)) {
      names.add(name);
    }
  }

  @override
  void visitCompilationUnit(covariant CompilationUnitImpl node) {
    localScope = _LocalNameScope.forUnit(node);
    super.visitCompilationUnit(node);
  }

  @override
  void visitCompoundAssignment(CompoundAssignment node) {
    _addCompoundAssignmentOperator(node.operator);
    super.visitCompoundAssignment(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forConstructor(localScope, node);
      super.visitConstructorDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    names.add(node.name2.lexeme);
  }

  @override
  void visitConstructorTypeReference(ConstructorTypeReference node) {
    if (node.importPrefix case var prefix?) {
      _addIfNotShadowed(prefix.name, hasImportPrefix: false);
    }
    _addIfNotShadowed(node.name, hasImportPrefix: node.importPrefix != null);
    node.typeArguments?.accept2(this);
  }

  @override
  void visitDotShorthandConstructorInvocation2(
    DotShorthandConstructorInvocation2 node,
  ) {
    names.add(node.name.lexeme);
    super.visitDotShorthandConstructorInvocation2(node);
  }

  @override
  void visitDotShorthandNameExpression(DotShorthandNameExpression node) {
    names.add(node.name.lexeme);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var outerScope = localScope;
    try {
      localScope = _LocalNameScope.forExtensionType(localScope, node);
      super.visitExtensionTypeDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitFunctionTypeAlias2(FunctionTypeAlias2 node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forFunctionTypeAlias(localScope, node);
      super.visitFunctionTypeAlias2(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitGetterDeclaration(covariant GetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitGetterDeclaration(node));
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var prefixName = node.prefixName;
    if (prefixName != null) {
      importPrefixNames.add(prefixName.lexeme);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitImportPrefixedAssignmentTarget(
    ImportPrefixedAssignmentTarget node,
  ) {
    names.add(node.name.lexeme);
    super.visitImportPrefixedAssignmentTarget(node);
  }

  @override
  void visitImportPrefixedNameExpression(ImportPrefixedNameExpression node) {
    names.add(node.name.lexeme);
    super.visitImportPrefixedNameExpression(node);
  }

  @override
  void visitIncrementOrDecrementExpression(
    IncrementOrDecrementExpression node,
  ) {
    names.add(switch (node.operation) {
      IncrementOrDecrementOperation.increment => '+',
      IncrementOrDecrementOperation.decrement => '-',
    });
    node.visitChildren2(this);
  }

  @override
  void visitLocalFunctionDeclaration(LocalFunctionDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forLocalFunction(localScope, node);
      super.visitLocalFunctionDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitMethodDeclaration2(covariant MethodDeclaration2Impl node) {
    _visitMethodDeclaration(node, () => super.visitMethodDeclaration2(node));
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    names.add(node.name.lexeme);
    super.visitNamedArgument(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.importPrefix case var prefix?) {
      // The parser doesn't know whether the prefix is an actual import prefix
      // or part of a qualified name (such as `const A.foo()`), so we always
      // add it too.
      _addIfNotShadowed(prefix.name, hasImportPrefix: false);
    }
    _addIfNotShadowed(node.name, hasImportPrefix: node.importPrefix != null);
    super.visitNamedType(node);
  }

  @override
  void visitOperatorDeclaration(covariant OperatorDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitOperatorDeclaration(node));
  }

  @override
  void visitParsedCascadeName(ParsedCascadeName node) {
    names.add(node.name.lexeme);
  }

  @override
  void visitParsedDotShorthandName(ParsedDotShorthandName node) {
    names.add(node.name.lexeme);
  }

  @override
  void visitParsedNameAccess(ParsedNameAccess node) {
    names.add(node.name.lexeme);
    super.visitParsedNameAccess(node);
  }

  @override
  void visitParsedNameAccessAssignmentTarget(
    ParsedNameAccessAssignmentTarget node,
  ) {
    names.add(node.name.lexeme);
    super.visitParsedNameAccessAssignmentTarget(node);
  }

  @override
  void visitParsedUnqualifiedName(ParsedUnqualifiedName node) {
    _addIfNotShadowed(node.name, hasImportPrefix: false);
  }

  @override
  void visitPatternField(PatternField node) {
    if (node.effectiveName case var name?) {
      names.add(name);
    }

    super.visitPatternField(node);
  }

  @override
  void visitReceiverPropertyAssignmentTarget(
    ReceiverPropertyAssignmentTarget node,
  ) {
    names.add(node.name.lexeme);
    super.visitReceiverPropertyAssignmentTarget(node);
  }

  @override
  void visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    names.add(node.name.lexeme);
    super.visitReceiverPropertyExtraction(node);
  }

  @override
  void visitSetterDeclaration(covariant SetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitSetterDeclaration(node));
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (includeAnalyzerDiagnosticExpectations) {
      var lexeme = node.literal.lexeme;
      for (var reference in analyzerDiagnosticExpectationReferences(lexeme)) {
        names.add(reference.name);
      }
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    names.add(node.name.lexeme);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitTopLevelFunctionDeclaration(
    covariant TopLevelFunctionDeclarationImpl node,
  ) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forTopLevelFunction(localScope, node);
      super.visitTopLevelFunctionDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitTopLevelGetterDeclaration(
    covariant TopLevelGetterDeclarationImpl node,
  ) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forTopLevelGetter(localScope, node);
      super.visitTopLevelGetterDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitTopLevelSetterDeclaration(
    covariant TopLevelSetterDeclarationImpl node,
  ) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forTopLevelSetter(localScope, node);
      super.visitTopLevelSetterDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitUnqualifiedNameAssignmentTarget(
    UnqualifiedNameAssignmentTarget node,
  ) {
    _addIfNotShadowed(node.name, hasImportPrefix: false);
  }

  @override
  void visitUnqualifiedNameExpression(UnqualifiedNameExpression node) {
    var name = node.name.lexeme;
    if (localScope.contains(name) || importPrefixNames.contains(name)) {
      return;
    }
    names.add(name);
  }

  void _addCompoundAssignmentOperator(Token operator) {
    var lexeme = operator.lexeme;
    if (lexeme != '=' && lexeme != '??=') {
      names.add(lexeme.substring(0, lexeme.length - 1));
    }
  }

  /// Adds [token] if it is not shadowed by a local element.
  void _addIfNotShadowed(Token token, {required bool hasImportPrefix}) {
    var name = token.lexeme;

    if (localScope.contains(name) && !hasImportPrefix) {
      return;
    }

    if (importPrefixNames.contains(name)) {
      return;
    }

    names.add(name);
  }

  void _visitMethodDeclaration(
    MethodDeclarationV1OriginImpl node,
    void Function() visitSuper,
  ) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forMethod(localScope, node);
      visitSuper();
    } finally {
      localScope = outerScope;
    }
  }
}
