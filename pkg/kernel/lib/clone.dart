// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.clone;

import 'ast.dart';
import 'type_algebra.dart';

/// Visitor that return a clone of a tree, maintaining references to cloned
/// objects.
///
/// This class does not clone members. For that, use the
/// [CloneVisitorWithMembers] and setup references properly.
class CloneVisitorNotMembers implements TreeVisitor<TreeNode> {
  final Map<VariableDeclaration, VariableDeclaration> _variables =
      <VariableDeclaration, VariableDeclaration>{};
  final Map<LabeledStatement, LabeledStatement> labels =
      <LabeledStatement, LabeledStatement>{};
  final Map<SwitchCase, SwitchCase> switchCases = <SwitchCase, SwitchCase>{};
  final Map<TypeParameter, DartType> typeSubstitution;
  final Map<TypeParameter, TypeParameter> typeParams;
  bool cloneAnnotations;

  /// Creates an instance of the cloning visitor for Kernel ASTs.
  ///
  /// The boolean value of [cloneAnnotations] tells if the annotations on the
  /// outline elements in the source AST should be cloned to the target AST. The
  /// annotations in procedure bodies are cloned unconditionally.
  CloneVisitorNotMembers(
      {Map<TypeParameter, DartType>? typeSubstitution,
      Map<TypeParameter, TypeParameter>? typeParams,
      this.cloneAnnotations = true})
      : this.typeSubstitution = ensureMutable(typeSubstitution),
        this.typeParams = typeParams ?? <TypeParameter, TypeParameter>{};

  static Map<TypeParameter, DartType> ensureMutable(
      Map<TypeParameter, DartType>? map) {
    // We need to mutate this map, so make sure we don't use a constant map.
    if (map == null || map.isEmpty) {
      return <TypeParameter, DartType>{};
    }
    return map;
  }

  /// Returns the clone of [variable] or `null` if no clone has been created
  /// for variable.
  VariableDeclaration? getVariableClone(VariableDeclaration variable) {
    return _variables[variable];
  }

  /// Registers [clone] as the clone for [variable].
  ///
  /// Returns the [clone].
  VariableDeclaration setVariableClone(
      VariableDeclaration variable, VariableDeclaration clone) {
    return _variables[variable] = clone;
  }

  @override
  TreeNode visitLibrary(Library node) {
    throw 'Cloning of libraries is not implemented';
  }

  @override
  TreeNode visitClass(Class node) {
    throw 'Cloning of classes is not implemented';
  }

  @override
  TreeNode visitExtension(Extension node) {
    throw 'Cloning of extensions is not implemented';
  }

  @override
  TreeNode visitConstructor(Constructor node) {
    throw 'Cloning of constructors is not implemented here';
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    throw 'Cloning of procedures is not implemented here';
  }

  @override
  TreeNode visitField(Field node) {
    throw 'Cloning of fields is not implemented here';
  }

  @override
  TreeNode visitRedirectingFactory(RedirectingFactory node) {
    throw 'Cloning of redirecting factory constructors is not implemented here';
  }

  // The currently active file uri where we are cloning [TreeNode]s from.  If
  // this is set to `null` we cannot clone file offsets to newly created nodes.
  // The [_cloneFileOffset] helper function will ensure this.
  Uri? _activeFileUri;

  // If we don't know the file uri we are cloning elements from, it's not safe
  // to clone file offsets either.
  int _cloneFileOffset(int fileOffset) {
    return _activeFileUri == null ? TreeNode.noOffset : fileOffset;
  }

  T clone<T extends TreeNode>(T node) {
    final Uri? activeFileUriSaved = _activeFileUri;
    if (node is FileUriNode) {
      _activeFileUri = node.fileUri;
    }
    final TreeNode result = node.accept(this)
      ..fileOffset = _cloneFileOffset(node.fileOffset);
    _activeFileUri = activeFileUriSaved;
    return result as T;
  }

  T? cloneOptional<T extends TreeNode>(T? node) {
    if (node == null) return null;
    final Uri? activeFileUriSaved = _activeFileUri;
    if (node is FileUriNode) {
      _activeFileUri = node.fileUri;
    }
    TreeNode? result = node.accept(this);
    if (result != null) result.fileOffset = _cloneFileOffset(node.fileOffset);
    _activeFileUri = activeFileUriSaved;
    return result as T?;
  }

  /// Root entry point for cloning a subtree within the same context where the
  /// file offsets are valid.
  T cloneInContext<T extends TreeNode>(T node) {
    assert(_activeFileUri == null);
    _activeFileUri = _activeFileUriFromContext(node);
    final TreeNode result = clone<T>(node);
    _activeFileUri = null;
    return result as T;
  }

  Uri? _activeFileUriFromContext(TreeNode? node) {
    while (node != null) {
      if (node is FileUriNode) {
        return node.fileUri;
      }
      node = node.parent;
    }
    return null;
  }

  DartType visitType(DartType type) {
    return substitute(type, typeSubstitution);
  }

  Constant visitConstant(Constant constant) {
    return constant;
  }

  DartType? visitOptionalType(DartType? type) {
    return type == null ? null : substitute(type, typeSubstitution);
  }

  @override
  visitInvalidExpression(InvalidExpression node) {
    return new InvalidExpression(
        node.message, node.expression != null ? clone(node.expression!) : null);
  }

  @override
  visitVariableGet(VariableGet node) {
    return new VariableGet(
        getVariableClone(node.variable)!, visitOptionalType(node.promotedType));
  }

  @override
  visitVariableSet(VariableSet node) {
    return new VariableSet(getVariableClone(node.variable)!, clone(node.value));
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    return new SuperPropertyGet.byReference(
        node.name, node.interfaceTargetReference);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    return new SuperPropertySet.byReference(
        node.name, clone(node.value), node.interfaceTargetReference);
  }

  @override
  visitStaticGet(StaticGet node) {
    return new StaticGet.byReference(node.targetReference);
  }

  @override
  visitStaticSet(StaticSet node) {
    return new StaticSet.byReference(node.targetReference, clone(node.value));
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    return new SuperMethodInvocation.byReference(
        node.name, clone(node.arguments), node.interfaceTargetReference);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    return new StaticInvocation.byReference(
        node.targetReference, clone(node.arguments),
        isConst: node.isConst);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    return new ConstructorInvocation.byReference(
        node.targetReference, clone(node.arguments),
        isConst: node.isConst);
  }

  @override
  visitNot(Not node) {
    return new Not(clone(node.operand));
  }

  @override
  visitNullCheck(NullCheck node) {
    return new NullCheck(clone(node.operand));
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    return new LogicalExpression(
        clone(node.left), node.operatorEnum, clone(node.right));
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return new ConditionalExpression(clone(node.condition), clone(node.then),
        clone(node.otherwise), visitType(node.staticType));
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    return new StringConcatenation(node.expressions.map(clone).toList());
  }

  @override
  visitListConcatenation(ListConcatenation node) {
    return new ListConcatenation(node.lists.map(clone).toList(),
        typeArgument: visitType(node.typeArgument));
  }

  @override
  visitSetConcatenation(SetConcatenation node) {
    return new SetConcatenation(node.sets.map(clone).toList(),
        typeArgument: visitType(node.typeArgument));
  }

  @override
  visitMapConcatenation(MapConcatenation node) {
    return new MapConcatenation(node.maps.map(clone).toList(),
        keyType: visitType(node.keyType), valueType: visitType(node.valueType));
  }

  @override
  visitInstanceCreation(InstanceCreation node) {
    final Map<Reference, Expression> fieldValues = <Reference, Expression>{};
    node.fieldValues.forEach((Reference fieldRef, Expression value) {
      fieldValues[fieldRef] = clone(value);
    });
    return new InstanceCreation(
        node.classReference,
        node.typeArguments.map(visitType).toList(),
        fieldValues,
        node.asserts.map(clone).toList(),
        node.unusedArguments.map(clone).toList());
  }

  @override
  visitFileUriExpression(FileUriExpression node) {
    return new FileUriExpression(clone(node.expression), _activeFileUri!);
  }

  @override
  visitIsExpression(IsExpression node) {
    return new IsExpression(clone(node.operand), visitType(node.type))
      ..flags = node.flags;
  }

  @override
  visitAsExpression(AsExpression node) {
    return new AsExpression(clone(node.operand), visitType(node.type))
      ..flags = node.flags;
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    return new SymbolLiteral(node.value);
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    return new TypeLiteral(visitType(node.type));
  }

  @override
  visitThisExpression(ThisExpression node) {
    return new ThisExpression();
  }

  @override
  visitRethrow(Rethrow node) {
    return new Rethrow();
  }

  @override
  visitThrow(Throw node) {
    return new Throw(clone(node.expression));
  }

  @override
  visitListLiteral(ListLiteral node) {
    return new ListLiteral(node.expressions.map(clone).toList(),
        typeArgument: visitType(node.typeArgument), isConst: node.isConst);
  }

  @override
  visitSetLiteral(SetLiteral node) {
    return new SetLiteral(node.expressions.map(clone).toList(),
        typeArgument: visitType(node.typeArgument), isConst: node.isConst);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    return new MapLiteral(node.entries.map(clone).toList(),
        keyType: visitType(node.keyType),
        valueType: visitType(node.valueType),
        isConst: node.isConst);
  }

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    return new MapLiteralEntry(clone(node.key), clone(node.value));
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    return new AwaitExpression(clone(node.operand));
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    return new FunctionExpression(clone(node.function));
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    return new ConstantExpression(
        visitConstant(node.constant), visitType(node.type));
  }

  @override
  visitStringLiteral(StringLiteral node) {
    return new StringLiteral(node.value);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    return new IntLiteral(node.value);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    return new DoubleLiteral(node.value);
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    return new BoolLiteral(node.value);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    return new NullLiteral();
  }

  @override
  visitLet(Let node) {
    VariableDeclaration newVariable = clone(node.variable);
    return new Let(newVariable, clone(node.body));
  }

  @override
  visitBlockExpression(BlockExpression node) {
    return new BlockExpression(clone(node.body), clone(node.value));
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    return new ExpressionStatement(clone(node.expression));
  }

  @override
  visitBlock(Block node) {
    return new Block(node.statements.map(clone).toList())
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset);
  }

  @override
  visitAssertBlock(AssertBlock node) {
    return new AssertBlock(node.statements.map(clone).toList());
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
    return new EmptyStatement();
  }

  @override
  visitAssertStatement(AssertStatement node) {
    return new AssertStatement(clone(node.condition),
        conditionStartOffset: node.conditionStartOffset,
        conditionEndOffset: node.conditionEndOffset,
        message: cloneOptional(node.message));
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    LabeledStatement newNode = new LabeledStatement(null);
    labels[node] = newNode;
    newNode.body = clone(node.body)..parent = newNode;
    return newNode;
  }

  @override
  visitBreakStatement(BreakStatement node) {
    return new BreakStatement(labels[node.target]!);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    return new WhileStatement(clone(node.condition), clone(node.body));
  }

  @override
  visitDoStatement(DoStatement node) {
    return new DoStatement(clone(node.body), clone(node.condition));
  }

  @override
  visitForStatement(ForStatement node) {
    List<VariableDeclaration> variables = node.variables.map(clone).toList();
    return new ForStatement(variables, cloneOptional(node.condition),
        node.updates.map(clone).toList(), clone(node.body));
  }

  @override
  visitForInStatement(ForInStatement node) {
    VariableDeclaration newVariable = clone(node.variable);
    return new ForInStatement(
        newVariable, clone(node.iterable), clone(node.body),
        isAsync: node.isAsync)
      ..bodyOffset = node.bodyOffset;
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase switchCase in node.cases) {
      switchCases[switchCase] = new SwitchCase(
          switchCase.expressions.map(clone).toList(),
          new List<int>.from(switchCase.expressionOffsets),
          dummyStatement,
          isDefault: switchCase.isDefault);
    }
    return new SwitchStatement(
        clone(node.expression), node.cases.map(clone).toList());
  }

  @override
  visitSwitchCase(SwitchCase node) {
    SwitchCase switchCase = switchCases[node]!;
    switchCase.body = clone(node.body)..parent = switchCase;
    return switchCase;
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    return new ContinueSwitchStatement(switchCases[node.target]!);
  }

  @override
  visitIfStatement(IfStatement node) {
    return new IfStatement(
        clone(node.condition), clone(node.then), cloneOptional(node.otherwise));
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    return new ReturnStatement(cloneOptional(node.expression));
  }

  @override
  visitTryCatch(TryCatch node) {
    return new TryCatch(clone(node.body), node.catches.map(clone).toList(),
        isSynthetic: node.isSynthetic);
  }

  @override
  visitCatch(Catch node) {
    VariableDeclaration? newException = cloneOptional(node.exception);
    VariableDeclaration? newStackTrace = cloneOptional(node.stackTrace);
    return new Catch(newException, clone(node.body),
        stackTrace: newStackTrace, guard: visitType(node.guard));
  }

  @override
  visitTryFinally(TryFinally node) {
    return new TryFinally(clone(node.body), clone(node.finalizer));
  }

  @override
  visitYieldStatement(YieldStatement node) {
    return new YieldStatement(clone(node.expression))..flags = node.flags;
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    return setVariableClone(
        node,
        new VariableDeclaration(node.name,
            initializer: cloneOptional(node.initializer),
            type: visitType(node.type))
          ..annotations = cloneAnnotations && !node.annotations.isEmpty
              ? node.annotations.map(clone).toList()
              : const <Expression>[]
          ..flags = node.flags
          ..fileEqualsOffset = _cloneFileOffset(node.fileEqualsOffset));
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    VariableDeclaration newVariable = clone(node.variable);
    // Create the declaration before cloning the body to support recursive
    // [LocalFunctionInvocation] nodes.
    FunctionDeclaration declaration =
        new FunctionDeclaration(newVariable, dummyFunctionNode);
    FunctionNode functionNode = clone(node.function);
    declaration.function = functionNode..parent = declaration;
    return declaration;
  }

  void prepareTypeParameters(List<TypeParameter> typeParameters) {
    for (TypeParameter node in typeParameters) {
      TypeParameter? newNode = typeParams[node];
      if (newNode == null) {
        newNode = new TypeParameter(node.name);
        typeParams[node] = newNode;
        typeSubstitution[node] =
            new TypeParameterType.forAlphaRenaming(node, newNode);
      }
    }
  }

  @override
  TypeParameter visitTypeParameter(TypeParameter node) {
    TypeParameter newNode = typeParams[node]!;
    newNode.bound = visitType(node.bound);
    // ignore: unnecessary_null_comparison
    if (node.defaultType != null) {
      newNode.defaultType = visitType(node.defaultType);
    }
    return newNode
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(clone).toList()
          : const <Expression>[]
      ..flags = node.flags;
  }

  Statement? cloneFunctionNodeBody(FunctionNode node) {
    bool savedCloneAnnotations = this.cloneAnnotations;
    try {
      this.cloneAnnotations = true;
      return cloneOptional(node.body);
    } finally {
      this.cloneAnnotations = savedCloneAnnotations;
    }
  }

  @override
  visitFunctionNode(FunctionNode node) {
    prepareTypeParameters(node.typeParameters);
    List<TypeParameter> typeParameters =
        node.typeParameters.map(clone).toList();
    List<VariableDeclaration> positional =
        node.positionalParameters.map(clone).toList();
    List<VariableDeclaration> named = node.namedParameters.map(clone).toList();
    return new FunctionNode(cloneFunctionNodeBody(node),
        typeParameters: typeParameters,
        positionalParameters: positional,
        namedParameters: named,
        requiredParameterCount: node.requiredParameterCount,
        returnType: visitType(node.returnType),
        asyncMarker: node.asyncMarker,
        dartAsyncMarker: node.dartAsyncMarker)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset);
  }

  @override
  visitArguments(Arguments node) {
    return new Arguments(node.positional.map(clone).toList(),
        types: node.types.map(visitType).toList(),
        named: node.named.map(clone).toList());
  }

  @override
  visitNamedExpression(NamedExpression node) {
    return new NamedExpression(node.name, clone(node.value));
  }

  @override
  defaultBasicLiteral(BasicLiteral node) {
    return defaultExpression(node);
  }

  @override
  defaultExpression(Expression node) {
    throw 'Unimplemented clone for Kernel expression: $node';
  }

  @override
  defaultInitializer(Initializer node) {
    throw 'Unimplemented clone for Kernel initializer: $node';
  }

  @override
  defaultMember(Member node) {
    throw 'Unimplemented clone for Kernel member: $node';
  }

  @override
  defaultStatement(Statement node) {
    throw 'Unimplemented clone for Kernel statement: $node';
  }

  @override
  defaultTreeNode(TreeNode node) {
    throw 'Cloning Kernel non-members is not supported.  '
        'Tried cloning $node';
  }

  @override
  visitAssertInitializer(AssertInitializer node) {
    return new AssertInitializer(clone(node.statement));
  }

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return new CheckLibraryIsLoaded(node.import);
  }

  @override
  visitCombinator(Combinator node) {
    return defaultTreeNode(node);
  }

  @override
  visitFieldInitializer(FieldInitializer node) {
    return new FieldInitializer.byReference(
        node.fieldReference, clone(node.value));
  }

  @override
  visitInstantiation(Instantiation node) {
    return new Instantiation(
        clone(node.expression), node.typeArguments.map(visitType).toList());
  }

  @override
  visitInvalidInitializer(InvalidInitializer node) {
    return new InvalidInitializer();
  }

  @override
  visitLibraryDependency(LibraryDependency node) {
    return defaultTreeNode(node);
  }

  @override
  visitLibraryPart(LibraryPart node) {
    return defaultTreeNode(node);
  }

  @override
  visitLoadLibrary(LoadLibrary node) {
    return new LoadLibrary(node.import);
  }

  @override
  visitLocalInitializer(LocalInitializer node) {
    return new LocalInitializer(clone(node.variable));
  }

  @override
  visitComponent(Component node) {
    return defaultTreeNode(node);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    return new RedirectingInitializer.byReference(
        node.targetReference, clone(node.arguments));
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    return new SuperInitializer.byReference(
        node.targetReference, clone(node.arguments));
  }

  @override
  visitTypedef(Typedef node) {
    return defaultTreeNode(node);
  }

  @override
  TreeNode visitDynamicGet(DynamicGet node) {
    return new DynamicGet(node.kind, clone(node.receiver), node.name);
  }

  @override
  TreeNode visitDynamicInvocation(DynamicInvocation node) {
    return new DynamicInvocation(
        node.kind, clone(node.receiver), node.name, clone(node.arguments));
  }

  @override
  TreeNode visitDynamicSet(DynamicSet node) {
    return new DynamicSet(
        node.kind, clone(node.receiver), node.name, clone(node.value));
  }

  @override
  TreeNode visitEqualsCall(EqualsCall node) {
    return new EqualsCall.byReference(clone(node.left), clone(node.right),
        functionType: visitType(node.functionType) as FunctionType,
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitEqualsNull(EqualsNull node) {
    return new EqualsNull(clone(node.expression));
  }

  @override
  TreeNode visitFunctionInvocation(FunctionInvocation node) {
    return new FunctionInvocation(
        node.kind, clone(node.receiver), clone(node.arguments),
        functionType: visitOptionalType(node.functionType) as FunctionType?);
  }

  @override
  TreeNode visitInstanceGet(InstanceGet node) {
    return new InstanceGet.byReference(
        node.kind, clone(node.receiver), node.name,
        resultType: visitType(node.resultType),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitInstanceInvocation(InstanceInvocation node) {
    return new InstanceInvocation.byReference(
        node.kind, clone(node.receiver), node.name, clone(node.arguments),
        functionType: visitType(node.functionType) as FunctionType,
        interfaceTargetReference: node.interfaceTargetReference)
      ..flags = node.flags;
  }

  @override
  TreeNode visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    return new InstanceGetterInvocation.byReference(
        node.kind, clone(node.receiver), node.name, clone(node.arguments),
        functionType: visitOptionalType(node.functionType) as FunctionType,
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitInstanceSet(InstanceSet node) {
    return new InstanceSet.byReference(
        node.kind, clone(node.receiver), node.name, clone(node.value),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitInstanceTearOff(InstanceTearOff node) {
    return new InstanceTearOff.byReference(
        node.kind, clone(node.receiver), node.name,
        resultType: visitType(node.resultType),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    return new LocalFunctionInvocation(
        getVariableClone(node.variable)!, clone(node.arguments),
        functionType: visitType(node.functionType) as FunctionType);
  }

  @override
  TreeNode visitStaticTearOff(StaticTearOff node) {
    return new StaticTearOff.byReference(node.targetReference);
  }

  @override
  TreeNode visitFunctionTearOff(FunctionTearOff node) {
    return new FunctionTearOff(clone(node.receiver));
  }

  @override
  TreeNode visitConstructorTearOff(ConstructorTearOff node) {
    return new ConstructorTearOff.byReference(node.targetReference);
  }

  @override
  TreeNode visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    return new RedirectingFactoryTearOff.byReference(node.targetReference);
  }

  @override
  TreeNode visitTypedefTearOff(TypedefTearOff node) {
    prepareTypeParameters(node.typeParameters);
    return new TypedefTearOff(
        node.typeParameters.map(visitTypeParameter).toList(),
        clone(node.expression),
        node.typeArguments.map(visitType).toList());
  }
}

/// Visitor that return a clone of a tree, maintaining references to cloned
/// objects.
///
/// It is safe to clone members, but cloning a class or library is not
/// supported.
class CloneVisitorWithMembers extends CloneVisitorNotMembers {
  CloneVisitorWithMembers(
      {Map<TypeParameter, DartType>? typeSubstitution,
      Map<TypeParameter, TypeParameter>? typeParams,
      bool cloneAnnotations = true})
      : super(
            typeSubstitution: typeSubstitution,
            typeParams: typeParams,
            cloneAnnotations: cloneAnnotations);

  @override
  @Deprecated("When cloning with members one should use the specific cloneX")
  T clone<T extends TreeNode>(T node) {
    return super.clone(node);
  }

  Constructor cloneConstructor(Constructor node, Reference? reference) {
    final Uri? activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri;

    Constructor result = new Constructor(
      super.clone(node.function),
      name: node.name,
      isConst: node.isConst,
      isExternal: node.isExternal,
      isSynthetic: node.isSynthetic,
      initializers: node.initializers.map(super.clone).toList(),
      transformerFlags: node.transformerFlags,
      fileUri: node.fileUri,
      reference: reference,
    )
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[]
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset);

    _activeFileUri = activeFileUriSaved;
    return result;
  }

  Procedure cloneProcedure(Procedure node, Reference? reference) {
    final Uri? activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri;
    Procedure result = new Procedure(
        node.name, node.kind, super.clone(node.function),
        reference: reference,
        transformerFlags: node.transformerFlags,
        fileUri: node.fileUri,
        stubKind: node.stubKind,
        stubTarget: node.stubTarget)
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[]
      ..startFileOffset = _cloneFileOffset(node.startFileOffset)
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset)
      ..flags = node.flags;

    _activeFileUri = activeFileUriSaved;
    return result;
  }

  Field cloneField(
      Field node, Reference? getterReference, Reference? setterReference) {
    final Uri? activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri;

    Field result;
    if (node.hasSetter) {
      result = new Field.mutable(node.name,
          type: visitType(node.type),
          initializer: cloneOptional(node.initializer),
          transformerFlags: node.transformerFlags,
          fileUri: node.fileUri,
          getterReference: getterReference,
          setterReference: setterReference);
    } else {
      assert(
          setterReference == null,
          "Cannot use setter reference $setterReference "
          "for clone of an immutable field.");
      result = new Field.immutable(node.name,
          type: visitType(node.type),
          initializer: cloneOptional(node.initializer),
          transformerFlags: node.transformerFlags,
          fileUri: node.fileUri,
          getterReference: getterReference);
    }
    result
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[]
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset)
      ..flags = node.flags;

    _activeFileUri = activeFileUriSaved;
    return result;
  }

  RedirectingFactory cloneRedirectingFactory(
      RedirectingFactory node, Reference? reference) {
    final Uri? activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri;

    RedirectingFactory result = new RedirectingFactory(node.targetReference,
        name: node.name,
        isConst: node.isConst,
        isExternal: node.isExternal,
        transformerFlags: node.transformerFlags,
        typeArguments: node.typeArguments.map(visitType).toList(),
        function: super.clone(node.function),
        fileUri: node.fileUri,
        reference: reference)
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[];

    _activeFileUri = activeFileUriSaved;
    return result;
  }
}

/// Cloner that resolves super calls in mixin declarations.
class MixinApplicationCloner extends CloneVisitorWithMembers {
  final Class mixinApplicationClass;
  Map<Name, Member>? _getterMap;
  Map<Name, Member>? _setterMap;

  MixinApplicationCloner(this.mixinApplicationClass,
      {Map<TypeParameter, DartType>? typeSubstitution,
      Map<TypeParameter, TypeParameter>? typeParams,
      bool cloneAnnotations = true})
      : super(
            typeSubstitution: typeSubstitution,
            typeParams: typeParams,
            cloneAnnotations: cloneAnnotations);

  Member? _findSuperMember(Name name, {required bool isSetter}) {
    // ignore: unnecessary_null_comparison
    assert(isSetter != null);
    Map<Name, Member> cache;
    if (isSetter) {
      cache = _setterMap ??= {};
    } else {
      cache = _getterMap ??= {};
    }
    Member? member = cache[name];
    if (member != null) {
      return member;
    }
    Class? superClass = mixinApplicationClass.superclass;
    while (superClass != null) {
      for (Procedure procedure in superClass.procedures) {
        if (procedure.name == name) {
          if (isSetter) {
            if (procedure.kind == ProcedureKind.Setter &&
                !procedure.isAbstract) {
              return cache[name] = procedure;
            }
          } else {
            if (procedure.kind != ProcedureKind.Setter &&
                !procedure.isAbstract) {
              return cache[name] = procedure;
            }
          }
        }
      }
      for (Field field in superClass.fields) {
        if (field.name == name) {
          if (isSetter) {
            if (field.hasSetter) {
              return cache[name] = field;
            }
          } else {
            return cache[name] = field;
          }
        }
      }

      superClass = superClass.superclass;
    }
    // TODO(johnniwinther): Throw instead when the CFE reports missing concrete
    // super members.
    // throw new StateError(
    //     'No super member found for $name in $mixinApplicationClass');
    return null;
  }

  @override
  SuperMethodInvocation visitSuperMethodInvocation(SuperMethodInvocation node) {
    SuperMethodInvocation cloned =
        super.visitSuperMethodInvocation(node) as SuperMethodInvocation;
    cloned.interfaceTarget =
        _findSuperMember(node.name, isSetter: false) as Procedure?;
    return cloned;
  }

  @override
  SuperPropertyGet visitSuperPropertyGet(SuperPropertyGet node) {
    SuperPropertyGet cloned =
        super.visitSuperPropertyGet(node) as SuperPropertyGet;
    cloned.interfaceTarget = _findSuperMember(node.name, isSetter: false);
    return cloned;
  }

  @override
  SuperPropertySet visitSuperPropertySet(SuperPropertySet node) {
    SuperPropertySet cloned =
        super.visitSuperPropertySet(node) as SuperPropertySet;
    cloned.interfaceTarget = _findSuperMember(node.name, isSetter: true);
    return cloned;
  }
}

class CloneProcedureWithoutBody extends CloneVisitorWithMembers {
  CloneProcedureWithoutBody(
      {Map<TypeParameter, DartType>? typeSubstitution,
      bool cloneAnnotations = true})
      : super(
            typeSubstitution: typeSubstitution,
            cloneAnnotations: cloneAnnotations);

  @override
  Statement? cloneFunctionNodeBody(FunctionNode node) => null;
}
