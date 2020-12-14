// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.clone;

import 'dart:core' hide MapEntry;

import 'ast.dart';
import 'type_algebra.dart';

/// Visitor that return a clone of a tree, maintaining references to cloned
/// objects.
///
/// This class does not clone members. For that, use the
/// [CloneVisitorWithMembers] and setup references properly.
class CloneVisitorNotMembers implements TreeVisitor<TreeNode> {
  final Map<VariableDeclaration, VariableDeclaration> variables =
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
      {Map<TypeParameter, DartType> typeSubstitution,
      Map<TypeParameter, TypeParameter> typeParams,
      this.cloneAnnotations = true})
      : this.typeSubstitution = ensureMutable(typeSubstitution),
        this.typeParams = typeParams ?? <TypeParameter, TypeParameter>{};

  static Map<TypeParameter, DartType> ensureMutable(
      Map<TypeParameter, DartType> map) {
    // We need to mutate this map, so make sure we don't use a constant map.
    if (map == null || map.isEmpty) {
      return <TypeParameter, DartType>{};
    }
    return map;
  }

  TreeNode visitLibrary(Library node) {
    throw 'Cloning of libraries is not implemented';
  }

  TreeNode visitClass(Class node) {
    throw 'Cloning of classes is not implemented';
  }

  TreeNode visitExtension(Extension node) {
    throw 'Cloning of extensions is not implemented';
  }

  TreeNode visitConstructor(Constructor node) {
    throw 'Cloning of constructors is not implemented here';
  }

  TreeNode visitProcedure(Procedure node) {
    throw 'Cloning of procedures is not implemented here';
  }

  TreeNode visitField(Field node) {
    throw 'Cloning of fields is not implemented here';
  }

  TreeNode visitRedirectingFactoryConstructor(
      RedirectingFactoryConstructor node) {
    throw 'Cloning of redirecting factory constructors is not implemented here';
  }

  // The currently active file uri where we are cloning [TreeNode]s from.  If
  // this is set to `null` we cannot clone file offsets to newly created nodes.
  // The [_cloneFileOffset] helper function will ensure this.
  Uri _activeFileUri;

  // If we don't know the file uri we are cloning elements from, it's not safe
  // to clone file offsets either.
  int _cloneFileOffset(int fileOffset) {
    return _activeFileUri == null ? TreeNode.noOffset : fileOffset;
  }

  T clone<T extends TreeNode>(T node) {
    final Uri activeFileUriSaved = _activeFileUri;
    if (node is FileUriNode) _activeFileUri = node.fileUri ?? _activeFileUri;
    final TreeNode result = node.accept(this)
      ..fileOffset = _cloneFileOffset(node.fileOffset);
    _activeFileUri = activeFileUriSaved;
    return result;
  }

  TreeNode cloneOptional(TreeNode node) {
    if (node == null) return null;
    final Uri activeFileUriSaved = _activeFileUri;
    if (node is FileUriNode) _activeFileUri = node.fileUri ?? _activeFileUri;
    TreeNode result = node?.accept(this);
    if (result != null) result.fileOffset = _cloneFileOffset(node.fileOffset);
    _activeFileUri = activeFileUriSaved;
    return result;
  }

  /// Root entry point for cloning a subtree within the same context where the
  /// file offsets are valid.
  T cloneInContext<T extends TreeNode>(T node) {
    assert(_activeFileUri == null);
    _activeFileUri = _activeFileUriFromContext(node);
    final TreeNode result = clone<T>(node);
    _activeFileUri = null;
    return result;
  }

  Uri _activeFileUriFromContext(TreeNode node) {
    while (node != null) {
      if (node is FileUriNode && node.fileUri != null) return node.fileUri;
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

  DartType visitOptionalType(DartType type) {
    return type == null ? null : substitute(type, typeSubstitution);
  }

  visitInvalidExpression(InvalidExpression node) {
    return new InvalidExpression(node.message);
  }

  visitVariableGet(VariableGet node) {
    return new VariableGet(
        variables[node.variable], visitOptionalType(node.promotedType));
  }

  visitVariableSet(VariableSet node) {
    return new VariableSet(variables[node.variable], clone(node.value));
  }

  visitPropertyGet(PropertyGet node) {
    return new PropertyGet.byReference(
        clone(node.receiver), node.name, node.interfaceTargetReference);
  }

  visitPropertySet(PropertySet node) {
    return new PropertySet.byReference(clone(node.receiver), node.name,
        clone(node.value), node.interfaceTargetReference);
  }

  visitSuperPropertyGet(SuperPropertyGet node) {
    return new SuperPropertyGet.byReference(
        node.name, node.interfaceTargetReference);
  }

  visitSuperPropertySet(SuperPropertySet node) {
    return new SuperPropertySet.byReference(
        node.name, clone(node.value), node.interfaceTargetReference);
  }

  visitStaticGet(StaticGet node) {
    return new StaticGet.byReference(node.targetReference);
  }

  visitStaticSet(StaticSet node) {
    return new StaticSet.byReference(node.targetReference, clone(node.value));
  }

  visitMethodInvocation(MethodInvocation node) {
    return new MethodInvocation.byReference(clone(node.receiver), node.name,
        clone(node.arguments), node.interfaceTargetReference)
      ..flags = node.flags;
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    return new SuperMethodInvocation.byReference(
        node.name, clone(node.arguments), node.interfaceTargetReference);
  }

  visitStaticInvocation(StaticInvocation node) {
    return new StaticInvocation.byReference(
        node.targetReference, clone(node.arguments),
        isConst: node.isConst);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    return new ConstructorInvocation.byReference(
        node.targetReference, clone(node.arguments),
        isConst: node.isConst);
  }

  visitNot(Not node) {
    return new Not(clone(node.operand));
  }

  visitNullCheck(NullCheck node) {
    return new NullCheck(clone(node.operand));
  }

  visitLogicalExpression(LogicalExpression node) {
    return new LogicalExpression(
        clone(node.left), node.operatorEnum, clone(node.right));
  }

  visitConditionalExpression(ConditionalExpression node) {
    return new ConditionalExpression(clone(node.condition), clone(node.then),
        clone(node.otherwise), visitOptionalType(node.staticType));
  }

  visitStringConcatenation(StringConcatenation node) {
    return new StringConcatenation(node.expressions.map(clone).toList());
  }

  visitListConcatenation(ListConcatenation node) {
    return new ListConcatenation(node.lists.map(clone).toList(),
        typeArgument: visitType(node.typeArgument));
  }

  visitSetConcatenation(SetConcatenation node) {
    return new SetConcatenation(node.sets.map(clone).toList(),
        typeArgument: visitType(node.typeArgument));
  }

  visitMapConcatenation(MapConcatenation node) {
    return new MapConcatenation(node.maps.map(clone).toList(),
        keyType: visitType(node.keyType), valueType: visitType(node.valueType));
  }

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

  visitFileUriExpression(FileUriExpression node) {
    return new FileUriExpression(clone(node.expression), _activeFileUri);
  }

  visitIsExpression(IsExpression node) {
    return new IsExpression(clone(node.operand), visitType(node.type))
      ..flags = node.flags;
  }

  visitAsExpression(AsExpression node) {
    return new AsExpression(clone(node.operand), visitType(node.type))
      ..flags = node.flags;
  }

  visitSymbolLiteral(SymbolLiteral node) {
    return new SymbolLiteral(node.value);
  }

  visitTypeLiteral(TypeLiteral node) {
    return new TypeLiteral(visitType(node.type));
  }

  visitThisExpression(ThisExpression node) {
    return new ThisExpression();
  }

  visitRethrow(Rethrow node) {
    return new Rethrow();
  }

  visitThrow(Throw node) {
    return new Throw(cloneOptional(node.expression));
  }

  visitListLiteral(ListLiteral node) {
    return new ListLiteral(node.expressions.map(clone).toList(),
        typeArgument: visitType(node.typeArgument), isConst: node.isConst);
  }

  visitSetLiteral(SetLiteral node) {
    return new SetLiteral(node.expressions.map(clone).toList(),
        typeArgument: visitType(node.typeArgument), isConst: node.isConst);
  }

  visitMapLiteral(MapLiteral node) {
    return new MapLiteral(node.entries.map(clone).toList(),
        keyType: visitType(node.keyType),
        valueType: visitType(node.valueType),
        isConst: node.isConst);
  }

  visitMapEntry(MapEntry node) {
    return new MapEntry(clone(node.key), clone(node.value));
  }

  visitAwaitExpression(AwaitExpression node) {
    return new AwaitExpression(clone(node.operand));
  }

  visitFunctionExpression(FunctionExpression node) {
    return new FunctionExpression(clone(node.function));
  }

  visitConstantExpression(ConstantExpression node) {
    return new ConstantExpression(
        visitConstant(node.constant), visitType(node.type));
  }

  visitStringLiteral(StringLiteral node) {
    return new StringLiteral(node.value);
  }

  visitIntLiteral(IntLiteral node) {
    return new IntLiteral(node.value);
  }

  visitDoubleLiteral(DoubleLiteral node) {
    return new DoubleLiteral(node.value);
  }

  visitBoolLiteral(BoolLiteral node) {
    return new BoolLiteral(node.value);
  }

  visitNullLiteral(NullLiteral node) {
    return new NullLiteral();
  }

  visitLet(Let node) {
    VariableDeclaration newVariable = clone(node.variable);
    return new Let(newVariable, clone(node.body));
  }

  visitBlockExpression(BlockExpression node) {
    return new BlockExpression(clone(node.body), clone(node.value));
  }

  visitExpressionStatement(ExpressionStatement node) {
    return new ExpressionStatement(clone(node.expression));
  }

  visitBlock(Block node) {
    return new Block(node.statements.map(clone).toList())
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset);
  }

  visitAssertBlock(AssertBlock node) {
    return new AssertBlock(node.statements.map(clone).toList());
  }

  visitEmptyStatement(EmptyStatement node) {
    return new EmptyStatement();
  }

  visitAssertStatement(AssertStatement node) {
    return new AssertStatement(clone(node.condition),
        conditionStartOffset: node.conditionStartOffset,
        conditionEndOffset: node.conditionEndOffset,
        message: cloneOptional(node.message));
  }

  visitLabeledStatement(LabeledStatement node) {
    LabeledStatement newNode = new LabeledStatement(null);
    labels[node] = newNode;
    newNode.body = clone(node.body)..parent = newNode;
    return newNode;
  }

  visitBreakStatement(BreakStatement node) {
    return new BreakStatement(labels[node.target]);
  }

  visitWhileStatement(WhileStatement node) {
    return new WhileStatement(clone(node.condition), clone(node.body));
  }

  visitDoStatement(DoStatement node) {
    return new DoStatement(clone(node.body), clone(node.condition));
  }

  visitForStatement(ForStatement node) {
    List<VariableDeclaration> variables = node.variables.map(clone).toList();
    return new ForStatement(variables, cloneOptional(node.condition),
        node.updates.map(clone).toList(), clone(node.body));
  }

  visitForInStatement(ForInStatement node) {
    VariableDeclaration newVariable = clone(node.variable);
    return new ForInStatement(
        newVariable, clone(node.iterable), clone(node.body),
        isAsync: node.isAsync)
      ..bodyOffset = node.bodyOffset;
  }

  visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase switchCase in node.cases) {
      switchCases[switchCase] = new SwitchCase(
          switchCase.expressions.map(clone).toList(),
          new List<int>.from(switchCase.expressionOffsets),
          null,
          isDefault: switchCase.isDefault);
    }
    return new SwitchStatement(
        clone(node.expression), node.cases.map(clone).toList());
  }

  visitSwitchCase(SwitchCase node) {
    SwitchCase switchCase = switchCases[node];
    switchCase.body = clone(node.body)..parent = switchCase;
    return switchCase;
  }

  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    return new ContinueSwitchStatement(switchCases[node.target]);
  }

  visitIfStatement(IfStatement node) {
    return new IfStatement(
        clone(node.condition), clone(node.then), cloneOptional(node.otherwise));
  }

  visitReturnStatement(ReturnStatement node) {
    return new ReturnStatement(cloneOptional(node.expression));
  }

  visitTryCatch(TryCatch node) {
    return new TryCatch(clone(node.body), node.catches.map(clone).toList(),
        isSynthetic: node.isSynthetic);
  }

  visitCatch(Catch node) {
    VariableDeclaration newException = cloneOptional(node.exception);
    VariableDeclaration newStackTrace = cloneOptional(node.stackTrace);
    return new Catch(newException, clone(node.body),
        stackTrace: newStackTrace, guard: visitType(node.guard));
  }

  visitTryFinally(TryFinally node) {
    return new TryFinally(clone(node.body), clone(node.finalizer));
  }

  visitYieldStatement(YieldStatement node) {
    return new YieldStatement(clone(node.expression))..flags = node.flags;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    return variables[node] = new VariableDeclaration(node.name,
        initializer: cloneOptional(node.initializer),
        type: visitType(node.type))
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(clone).toList()
          : const <Expression>[]
      ..flags = node.flags
      ..fileEqualsOffset = _cloneFileOffset(node.fileEqualsOffset);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    VariableDeclaration newVariable = clone(node.variable);
    return new FunctionDeclaration(newVariable, clone(node.function));
  }

  void prepareTypeParameters(List<TypeParameter> typeParameters) {
    for (TypeParameter node in typeParameters) {
      TypeParameter newNode = typeParams[node];
      if (newNode == null) {
        newNode = new TypeParameter(node.name);
        typeParams[node] = newNode;
        typeSubstitution[node] =
            new TypeParameterType.forAlphaRenaming(node, newNode);
      }
    }
  }

  visitTypeParameter(TypeParameter node) {
    TypeParameter newNode = typeParams[node];
    newNode.bound = visitType(node.bound);
    if (node.defaultType != null) {
      newNode.defaultType = visitType(node.defaultType);
    }
    return newNode
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(clone).toList()
          : const <Expression>[]
      ..flags = node.flags;
  }

  TreeNode cloneFunctionNodeBody(FunctionNode node) {
    bool savedCloneAnnotations = this.cloneAnnotations;
    try {
      this.cloneAnnotations = true;
      return cloneOptional(node.body);
    } finally {
      this.cloneAnnotations = savedCloneAnnotations;
    }
  }

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

  visitArguments(Arguments node) {
    return new Arguments(node.positional.map(clone).toList(),
        types: node.types.map(visitType).toList(),
        named: node.named.map(clone).toList());
  }

  visitNamedExpression(NamedExpression node) {
    return new NamedExpression(node.name, clone(node.value));
  }

  defaultBasicLiteral(BasicLiteral node) {
    return defaultExpression(node);
  }

  defaultExpression(Expression node) {
    throw 'Unimplemented clone for Kernel expression: $node';
  }

  defaultInitializer(Initializer node) {
    throw 'Unimplemented clone for Kernel initializer: $node';
  }

  defaultMember(Member node) {
    throw 'Unimplemented clone for Kernel member: $node';
  }

  defaultStatement(Statement node) {
    throw 'Unimplemented clone for Kernel statement: $node';
  }

  defaultTreeNode(TreeNode node) {
    throw 'Cloning Kernel non-members is not supported.  '
        'Tried cloning $node';
  }

  visitAssertInitializer(AssertInitializer node) {
    return new AssertInitializer(clone(node.statement));
  }

  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    return new CheckLibraryIsLoaded(node.import);
  }

  visitCombinator(Combinator node) {
    return defaultTreeNode(node);
  }

  visitFieldInitializer(FieldInitializer node) {
    return new FieldInitializer.byReference(
        node.fieldReference, clone(node.value));
  }

  visitInstantiation(Instantiation node) {
    return new Instantiation(
        clone(node.expression), node.typeArguments.map(visitType).toList());
  }

  visitInvalidInitializer(InvalidInitializer node) {
    return new InvalidInitializer();
  }

  visitLibraryDependency(LibraryDependency node) {
    return defaultTreeNode(node);
  }

  visitLibraryPart(LibraryPart node) {
    return defaultTreeNode(node);
  }

  visitLoadLibrary(LoadLibrary node) {
    return new LoadLibrary(node.import);
  }

  visitLocalInitializer(LocalInitializer node) {
    return new LocalInitializer(clone(node.variable));
  }

  visitComponent(Component node) {
    return defaultTreeNode(node);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    return new RedirectingInitializer.byReference(
        node.targetReference, clone(node.arguments));
  }

  visitSuperInitializer(SuperInitializer node) {
    return new SuperInitializer.byReference(
        node.targetReference, clone(node.arguments));
  }

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
        isNot: node.isNot,
        functionType: visitOptionalType(node.functionType),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitEqualsNull(EqualsNull node) {
    return new EqualsNull(clone(node.expression), isNot: node.isNot);
  }

  @override
  TreeNode visitFunctionInvocation(FunctionInvocation node) {
    return new FunctionInvocation(
        node.kind, clone(node.receiver), clone(node.arguments),
        functionType: visitOptionalType(node.functionType));
  }

  @override
  TreeNode visitInstanceGet(InstanceGet node) {
    return new InstanceGet.byReference(
        node.kind, clone(node.receiver), node.name,
        resultType: visitOptionalType(node.resultType),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitInstanceInvocation(InstanceInvocation node) {
    return new InstanceInvocation.byReference(
        node.kind, clone(node.receiver), node.name, clone(node.arguments),
        functionType: visitOptionalType(node.functionType),
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
        resultType: visitOptionalType(node.resultType),
        interfaceTargetReference: node.interfaceTargetReference);
  }

  @override
  TreeNode visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    return new LocalFunctionInvocation(
        variables[node.variable], clone(node.arguments),
        functionType: visitOptionalType(node.functionType));
  }

  @override
  TreeNode visitStaticTearOff(StaticTearOff node) {
    return new StaticTearOff.byReference(node.targetReference);
  }

  @override
  TreeNode visitFunctionTearOff(FunctionTearOff node) {
    return new FunctionTearOff(clone(node.receiver));
  }
}

/// Visitor that return a clone of a tree, maintaining references to cloned
/// objects.
///
/// It is safe to clone members, but cloning a class or library is not
/// supported.
class CloneVisitorWithMembers extends CloneVisitorNotMembers {
  CloneVisitorWithMembers(
      {Map<TypeParameter, DartType> typeSubstitution,
      Map<TypeParameter, TypeParameter> typeParams,
      bool cloneAnnotations = true})
      : super(
            typeSubstitution: typeSubstitution,
            typeParams: typeParams,
            cloneAnnotations: cloneAnnotations);

  @Deprecated("When cloning with members one should use the specific cloneX")
  T clone<T extends TreeNode>(T node) {
    return super.clone(node);
  }

  Constructor cloneConstructor(Constructor node, Constructor referenceFrom) {
    final Uri activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri ?? _activeFileUri;

    Constructor result = new Constructor(
      super.clone(node.function),
      name: node.name,
      isConst: node.isConst,
      isExternal: node.isExternal,
      isSynthetic: node.isSynthetic,
      initializers: node.initializers.map(super.clone).toList(),
      transformerFlags: node.transformerFlags,
      fileUri: _activeFileUri,
      reference: referenceFrom?.reference,
    )
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[]
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset);

    _activeFileUri = activeFileUriSaved;
    return result;
  }

  Procedure cloneProcedure(Procedure node, Procedure referenceFrom) {
    final Uri activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri ?? _activeFileUri;
    Procedure result = new Procedure(
        node.name, node.kind, super.clone(node.function),
        reference: referenceFrom?.reference,
        transformerFlags: node.transformerFlags,
        fileUri: _activeFileUri,
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

  Field cloneField(Field node, Field referenceFrom) {
    final Uri activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri ?? _activeFileUri;

    Field result = new Field(node.name,
        type: visitType(node.type),
        initializer: cloneOptional(node.initializer),
        isCovariant: node.isCovariant,
        isFinal: node.isFinal,
        isConst: node.isConst,
        isStatic: node.isStatic,
        isLate: node.isLate,
        hasImplicitGetter: node.hasImplicitGetter,
        hasImplicitSetter: node.hasImplicitSetter,
        transformerFlags: node.transformerFlags,
        fileUri: _activeFileUri,
        getterReference: referenceFrom?.getterReference,
        setterReference: referenceFrom?.setterReference)
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[]
      ..fileOffset = _cloneFileOffset(node.fileOffset)
      ..fileEndOffset = _cloneFileOffset(node.fileEndOffset)
      ..flags = node.flags;

    _activeFileUri = activeFileUriSaved;
    return result;
  }

  RedirectingFactoryConstructor cloneRedirectingFactoryConstructor(
      RedirectingFactoryConstructor node,
      RedirectingFactoryConstructor referenceFrom) {
    final Uri activeFileUriSaved = _activeFileUri;
    _activeFileUri = node.fileUri ?? _activeFileUri;

    prepareTypeParameters(node.typeParameters);
    RedirectingFactoryConstructor result = new RedirectingFactoryConstructor(
        node.targetReference,
        name: node.name,
        isConst: node.isConst,
        isExternal: node.isExternal,
        transformerFlags: node.transformerFlags,
        typeArguments: node.typeArguments.map(visitType).toList(),
        typeParameters: node.typeParameters.map(super.clone).toList(),
        positionalParameters:
            node.positionalParameters.map(super.clone).toList(),
        namedParameters: node.namedParameters.map(super.clone).toList(),
        requiredParameterCount: node.requiredParameterCount,
        fileUri: _activeFileUri,
        reference: referenceFrom?.reference)
      ..annotations = cloneAnnotations && !node.annotations.isEmpty
          ? node.annotations.map(super.clone).toList()
          : const <Expression>[];

    _activeFileUri = activeFileUriSaved;
    return result;
  }
}

class CloneProcedureWithoutBody extends CloneVisitorWithMembers {
  CloneProcedureWithoutBody(
      {Map<TypeParameter, DartType> typeSubstitution,
      bool cloneAnnotations = true})
      : super(
            typeSubstitution: typeSubstitution,
            cloneAnnotations: cloneAnnotations);

  @override
  TreeNode cloneFunctionNodeBody(FunctionNode node) => null;
}
