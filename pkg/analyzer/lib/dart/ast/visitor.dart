// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines AST visitors that support useful patterns for visiting the nodes in
/// an [AST structure](ast.dart).
///
/// Dart is an evolving language, and the AST structure must evolved with it.
/// When the AST structure changes, the visitor interface will sometimes change
/// as well. If it is desirable to get a compilation error when the structure of
/// the AST has been modified, then you should consider implementing the
/// interface [AstVisitor] directly. Doing so will ensure that changes that
/// introduce new classes of nodes will be flagged. (Of course, not all changes
/// to the AST structure require the addition of a new class of node, and hence
/// cannot be caught this way.)
///
/// But if automatic detection of these kinds of changes is not necessary then
/// you will probably want to extend one of the classes in this library because
/// doing so will simplify the task of writing your visitor and guard against
/// future changes to the AST structure. For example, the [RecursiveAstVisitor]
/// automates the process of visiting all of the descendants of a node.
library;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';

part 'visitor.g.dart';

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure, similar to [GeneralizingAstVisitor]. This visitor uses a
/// breadth-first ordering rather than the depth-first ordering of
/// [GeneralizingAstVisitor].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// In addition, subclasses should <b>not</b> explicitly visit the children of a
/// node, but should ensure that the method [visitNode] is used to visit the
/// children (either directly or indirectly). Failure to do will break the order
/// in which nodes are visited.
///
/// Note that, unlike other visitors that begin to visit a structure of nodes by
/// asking the root node in the structure to accept the visitor, this visitor
/// requires that clients start the visit by invoking the method [visitAllNodes]
/// defined on the visitor with the root node as the argument:
///
///     visitor.visitAllNodes(rootNode);
///
/// Clients may extend this class.
class BreadthFirstVisitor<R> extends GeneralizingAstVisitor<R> {
  /// A queue holding the nodes that have not yet been visited in the order in
  /// which they ought to be visited.
  final Queue<AstNode> _queue = Queue<AstNode>();

  /// A visitor, used to visit the children of the current node, that will add
  /// the nodes it visits to the [_queue].
  late final _BreadthFirstChildVisitor _childVisitor;

  /// Initialize a newly created visitor.
  BreadthFirstVisitor() {
    _childVisitor = _BreadthFirstChildVisitor(this);
  }

  /// Visit all nodes in the tree starting at the given [root] node, in
  /// breadth-first order.
  void visitAllNodes(AstNode root) {
    _queue.add(root);
    while (_queue.isNotEmpty) {
      AstNode next = _queue.removeFirst();
      next.accept(this);
    }
  }

  @override
  R? visitNode(AstNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }
}

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For each node that is visited, the corresponding visit method on
/// one or more other visitors (the 'delegates') will be invoked.
///
/// For example, if an instance of this class is created with two delegates V1
/// and V2, and that instance is used to visit the expression 'x + 1', then the
/// following visit methods will be invoked:
/// 1. V1.visitBinaryExpression
/// 2. V2.visitBinaryExpression
/// 3. V1.visitSimpleIdentifier
/// 4. V2.visitSimpleIdentifier
/// 5. V1.visitIntegerLiteral
/// 6. V2.visitIntegerLiteral
///
/// Clients may not extend, implement or mix-in this class.
class DelegatingAstVisitor<T> extends UnifyingAstVisitor<T> {
  /// The delegates whose visit methods will be invoked.
  final Iterable<AstVisitor<T>> delegates;

  /// Initialize a newly created visitor to use each of the given delegate
  /// visitors to visit the nodes of an AST structure.
  const DelegatingAstVisitor(this.delegates);

  @override
  T? visitNode(AstNode node) {
    delegates.forEach(node.accept);
    node.visitChildren(this);
    return null;
  }
}

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure (like instances of the class [RecursiveAstVisitor]). In addition,
/// when a node of a specific type is visited not only will the visit method for
/// that specific type of node be invoked, but additional methods for the
/// superclasses of that node will also be invoked. For example, using an
/// instance of this class to visit a [Block] will cause the method [visitBlock]
/// to be invoked but will also cause the methods [visitStatement] and
/// [visitNode] to be subsequently invoked. This allows visitors to be written
/// that visit all statements without needing to override the visit method for
/// each of the specific subclasses of [Statement].
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the node to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// Clients may extend this class.
class GeneralizingAstVisitor<R> implements AstVisitor<R> {
  /// Initialize a newly created visitor.
  const GeneralizingAstVisitor();

  @override
  R? visitAdjacentStrings(AdjacentStrings node) => visitStringLiteral(node);

  R? visitAnnotatedNode(AnnotatedNode node) => visitNode(node);

  @override
  R? visitAnnotation(Annotation node) => visitNode(node);

  @override
  R? visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R? visitAsExpression(AsExpression node) => visitExpression(node);

  @override
  R? visitAssertInitializer(AssertInitializer node) => visitNode(node);

  @override
  R? visitAssertStatement(AssertStatement node) => visitStatement(node);

  @override
  R? visitAssignedVariablePattern(AssignedVariablePattern node) =>
      visitDartPattern(node);

  @override
  R? visitAssignmentExpression(AssignmentExpression node) =>
      visitExpression(node);

  @override
  R? visitAwaitExpression(AwaitExpression node) => visitExpression(node);

  @override
  R? visitBinaryExpression(BinaryExpression node) => visitExpression(node);

  @override
  R? visitBlock(Block node) => visitStatement(node);

  @override
  R? visitBlockFunctionBody(BlockFunctionBody node) => visitFunctionBody(node);

  @override
  R? visitBooleanLiteral(BooleanLiteral node) => visitLiteral(node);

  @override
  R? visitBreakStatement(BreakStatement node) => visitStatement(node);

  @override
  R? visitCascadeExpression(CascadeExpression node) => visitExpression(node);

  @override
  R? visitCaseClause(CaseClause node) => visitNode(node);

  @override
  R? visitCastPattern(CastPattern node) => visitDartPattern(node);

  @override
  R? visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R? visitCatchClauseParameter(CatchClauseParameter node) => visitNode(node);

  @override
  R? visitClassDeclaration(ClassDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  R? visitClassMember(ClassMember node) => visitDeclaration(node);

  @override
  R? visitClassTypeAlias(ClassTypeAlias node) => visitTypeAlias(node);

  R? visitCollectionElement(CollectionElement node) => visitNode(node);

  R? visitCombinator(Combinator node) => visitNode(node);

  @override
  R? visitComment(Comment node) => visitNode(node);

  @override
  R? visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R? visitCompilationUnit(CompilationUnit node) => visitNode(node);

  R? visitCompilationUnitMember(CompilationUnitMember node) =>
      visitDeclaration(node);

  @override
  R? visitConditionalExpression(ConditionalExpression node) =>
      visitExpression(node);

  @override
  R? visitConfiguration(Configuration node) => visitNode(node);

  @override
  R? visitConstantPattern(ConstantPattern node) => visitDartPattern(node);

  @override
  R? visitConstructorDeclaration(ConstructorDeclaration node) =>
      visitClassMember(node);

  @override
  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitConstructorInitializer(node);

  R? visitConstructorInitializer(ConstructorInitializer node) =>
      visitNode(node);

  @override
  R? visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R? visitConstructorReference(ConstructorReference node) =>
      visitExpression(node);

  @override
  R? visitConstructorSelector(ConstructorSelector node) => visitNode(node);

  @override
  R? visitContinueStatement(ContinueStatement node) => visitStatement(node);

  R? visitDartPattern(DartPattern node) => visitNode(node);

  R? visitDeclaration(Declaration node) => visitAnnotatedNode(node);

  @override
  R? visitDeclaredIdentifier(DeclaredIdentifier node) => visitDeclaration(node);

  @override
  R? visitDeclaredVariablePattern(DeclaredVariablePattern node) =>
      visitDartPattern(node);

  @override
  R? visitDefaultFormalParameter(DefaultFormalParameter node) =>
      visitFormalParameter(node);

  R? visitDirective(Directive node) => visitAnnotatedNode(node);

  @override
  R? visitDoStatement(DoStatement node) => visitStatement(node);

  @override
  R? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => visitExpression(node);

  @override
  R? visitDotShorthandInvocation(DotShorthandInvocation node) =>
      visitExpression(node);

  @override
  R? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      visitExpression(node);

  @override
  R? visitDottedName(DottedName node) => visitNode(node);

  @override
  R? visitDoubleLiteral(DoubleLiteral node) => visitLiteral(node);

  @override
  R? visitEmptyFunctionBody(EmptyFunctionBody node) => visitFunctionBody(node);

  @override
  R? visitEmptyStatement(EmptyStatement node) => visitStatement(node);

  @override
  R? visitEnumConstantArguments(EnumConstantArguments node) => visitNode(node);

  @override
  R? visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitDeclaration(node);

  @override
  R? visitEnumDeclaration(EnumDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R? visitExportDirective(ExportDirective node) =>
      visitNamespaceDirective(node);

  R? visitExpression(Expression node) => visitCollectionElement(node);

  @override
  R? visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      visitFunctionBody(node);

  @override
  R? visitExpressionStatement(ExpressionStatement node) => visitStatement(node);

  @override
  R? visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R? visitExtensionDeclaration(ExtensionDeclaration node) =>
      visitCompilationUnitMember(node);

  @override
  R? visitExtensionOnClause(ExtensionOnClause node) => visitNode(node);

  @override
  R? visitExtensionOverride(ExtensionOverride node) => visitExpression(node);

  @override
  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R? visitFieldDeclaration(FieldDeclaration node) => visitClassMember(node);

  @override
  R? visitFieldFormalParameter(FieldFormalParameter node) =>
      visitNormalFormalParameter(node);

  R? visitForEachParts(ForEachParts node) => visitNode(node);

  @override
  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) =>
      visitForEachParts(node);

  @override
  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) =>
      visitForEachParts(node);

  @override
  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node) =>
      visitForEachParts(node);

  @override
  R? visitForElement(ForElement node) => visitCollectionElement(node);

  R? visitFormalParameter(FormalParameter node) => visitNode(node);

  @override
  R? visitFormalParameterList(FormalParameterList node) => visitNode(node);

  R? visitForParts(ForParts node) => visitNode(node);

  @override
  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node) =>
      visitForParts(node);

  @override
  R? visitForPartsWithExpression(ForPartsWithExpression node) =>
      visitForParts(node);

  @override
  R? visitForPartsWithPattern(ForPartsWithPattern node) => visitForParts(node);

  @override
  R? visitForStatement(ForStatement node) => visitStatement(node);

  R? visitFunctionBody(FunctionBody node) => visitNode(node);

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is FunctionDeclarationStatement) {
      return visitNode(node);
    }
    return visitNamedCompilationUnitMember(node);
  }

  @override
  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitStatement(node);

  @override
  R? visitFunctionExpression(FunctionExpression node) => visitExpression(node);

  @override
  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitInvocationExpression(node);

  @override
  R? visitFunctionReference(FunctionReference node) => visitExpression(node);

  @override
  R? visitFunctionTypeAlias(FunctionTypeAlias node) => visitTypeAlias(node);

  @override
  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R? visitGenericFunctionType(GenericFunctionType node) =>
      visitTypeAnnotation(node);

  @override
  R? visitGenericTypeAlias(GenericTypeAlias node) => visitTypeAlias(node);

  @override
  R? visitGuardedPattern(GuardedPattern node) => visitNode(node);

  @override
  R? visitHideCombinator(HideCombinator node) => visitCombinator(node);

  R? visitIdentifier(Identifier node) => visitExpression(node);

  @override
  R? visitIfElement(IfElement node) => visitCollectionElement(node);

  @override
  R? visitIfStatement(IfStatement node) => visitStatement(node);

  @override
  R? visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R? visitImplicitCallReference(ImplicitCallReference node) => visitNode(node);

  @override
  R? visitImportDirective(ImportDirective node) =>
      visitNamespaceDirective(node);

  @override
  R? visitImportPrefixReference(ImportPrefixReference node) => visitNode(node);

  @override
  R? visitIndexExpression(IndexExpression node) => visitExpression(node);

  @override
  R? visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitExpression(node);

  @override
  R? visitIntegerLiteral(IntegerLiteral node) => visitLiteral(node);

  R? visitInterpolationElement(InterpolationElement node) => visitNode(node);

  @override
  R? visitInterpolationExpression(InterpolationExpression node) =>
      visitInterpolationElement(node);

  @override
  R? visitInterpolationString(InterpolationString node) =>
      visitInterpolationElement(node);

  R? visitInvocationExpression(InvocationExpression node) =>
      visitExpression(node);

  @override
  R? visitIsExpression(IsExpression node) => visitExpression(node);

  @override
  R? visitLabel(Label node) => visitNode(node);

  @override
  R? visitLabeledStatement(LabeledStatement node) => visitStatement(node);

  @override
  R? visitLibraryDirective(LibraryDirective node) => visitDirective(node);

  @override
  R? visitLibraryIdentifier(LibraryIdentifier node) => visitIdentifier(node);

  @override
  R? visitListLiteral(ListLiteral node) => visitTypedLiteral(node);

  @override
  R? visitListPattern(ListPattern node) => visitDartPattern(node);

  R? visitLiteral(Literal node) => visitExpression(node);

  @override
  R? visitLogicalAndPattern(LogicalAndPattern node) => visitDartPattern(node);

  @override
  R? visitLogicalOrPattern(LogicalOrPattern node) => visitDartPattern(node);

  @override
  R? visitMapLiteralEntry(MapLiteralEntry node) => visitCollectionElement(node);

  @override
  R? visitMapPattern(MapPattern node) => visitDartPattern(node);

  @override
  R? visitMapPatternEntry(MapPatternEntry node) => visitNode(node);

  @override
  R? visitMethodDeclaration(MethodDeclaration node) => visitClassMember(node);

  @override
  R? visitMethodInvocation(MethodInvocation node) =>
      visitInvocationExpression(node);

  @override
  R? visitMixinDeclaration(MixinDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R? visitMixinOnClause(MixinOnClause node) {
    return visitNode(node);
  }

  R? visitNamedCompilationUnitMember(NamedCompilationUnitMember node) =>
      visitCompilationUnitMember(node);

  @override
  R? visitNamedExpression(NamedExpression node) => visitExpression(node);

  @override
  R? visitNamedType(NamedType node) => visitTypeAnnotation(node);

  R? visitNamespaceDirective(NamespaceDirective node) =>
      visitUriBasedDirective(node);

  @override
  R? visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R? visitNativeFunctionBody(NativeFunctionBody node) =>
      visitFunctionBody(node);

  R? visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  R? visitNormalFormalParameter(NormalFormalParameter node) =>
      visitFormalParameter(node);

  @override
  R? visitNullAssertPattern(NullAssertPattern node) => visitDartPattern(node);

  @override
  R? visitNullAwareElement(NullAwareElement node) =>
      visitCollectionElement(node);

  @override
  R? visitNullCheckPattern(NullCheckPattern node) => visitDartPattern(node);

  @override
  R? visitNullLiteral(NullLiteral node) => visitLiteral(node);

  @override
  R? visitObjectPattern(ObjectPattern node) => visitDartPattern(node);

  @override
  R? visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitExpression(node);

  @override
  R? visitParenthesizedPattern(ParenthesizedPattern node) =>
      visitDartPattern(node);

  @override
  R? visitPartDirective(PartDirective node) => visitUriBasedDirective(node);

  @override
  R? visitPartOfDirective(PartOfDirective node) => visitDirective(node);

  @override
  R? visitPatternAssignment(PatternAssignment node) => visitExpression(node);

  @override
  R? visitPatternField(PatternField node) => visitNode(node);

  @override
  R? visitPatternFieldName(PatternFieldName node) => visitNode(node);

  @override
  R? visitPatternVariableDeclaration(PatternVariableDeclaration node) =>
      visitNode(node);

  @override
  R? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) => visitStatement(node);

  @override
  R? visitPostfixExpression(PostfixExpression node) => visitExpression(node);

  @override
  R? visitPrefixedIdentifier(PrefixedIdentifier node) => visitIdentifier(node);

  @override
  R? visitPrefixExpression(PrefixExpression node) => visitExpression(node);

  @override
  R? visitPropertyAccess(PropertyAccess node) => visitExpression(node);

  @override
  R? visitRecordLiteral(RecordLiteral node) => visitLiteral(node);

  @override
  R? visitRecordPattern(RecordPattern node) => visitDartPattern(node);

  @override
  R? visitRecordTypeAnnotation(RecordTypeAnnotation node) =>
      visitTypeAnnotation(node);

  R? visitRecordTypeAnnotationField(RecordTypeAnnotationField node) =>
      visitNode(node);

  @override
  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) =>
      visitRecordTypeAnnotationField(node);

  @override
  R? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) => visitNode(node);

  @override
  R? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) => visitRecordTypeAnnotationField(node);

  @override
  R? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) => visitConstructorInitializer(node);

  @override
  R? visitRelationalPattern(RelationalPattern node) => visitDartPattern(node);

  @override
  R? visitRepresentationConstructorName(RepresentationConstructorName node) =>
      visitNode(node);

  @override
  R? visitRepresentationDeclaration(RepresentationDeclaration node) =>
      visitNode(node);

  @override
  R? visitRestPatternElement(RestPatternElement node) => visitNode(node);

  @override
  R? visitRethrowExpression(RethrowExpression node) => visitExpression(node);

  @override
  R? visitReturnStatement(ReturnStatement node) => visitStatement(node);

  @override
  R? visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  R? visitSetOrMapLiteral(SetOrMapLiteral node) => visitTypedLiteral(node);

  @override
  R? visitShowCombinator(ShowCombinator node) => visitCombinator(node);

  @override
  R? visitSimpleFormalParameter(SimpleFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R? visitSimpleIdentifier(SimpleIdentifier node) => visitIdentifier(node);

  @override
  R? visitSimpleStringLiteral(SimpleStringLiteral node) =>
      visitSingleStringLiteral(node);

  R? visitSingleStringLiteral(SingleStringLiteral node) =>
      visitStringLiteral(node);

  @override
  R? visitSpreadElement(SpreadElement node) => visitCollectionElement(node);

  R? visitStatement(Statement node) => visitNode(node);

  @override
  R? visitStringInterpolation(StringInterpolation node) =>
      visitSingleStringLiteral(node);

  R? visitStringLiteral(StringLiteral node) => visitLiteral(node);

  @override
  R? visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitConstructorInitializer(node);

  @override
  R? visitSuperExpression(SuperExpression node) => visitExpression(node);

  @override
  R? visitSuperFormalParameter(SuperFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R? visitSwitchCase(SwitchCase node) => visitSwitchMember(node);

  @override
  R? visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);

  @override
  R? visitSwitchExpression(SwitchExpression node) => visitExpression(node);

  @override
  R? visitSwitchExpressionCase(SwitchExpressionCase node) => visitNode(node);

  R? visitSwitchMember(SwitchMember node) => visitNode(node);

  @override
  R? visitSwitchPatternCase(SwitchPatternCase node) => visitSwitchMember(node);

  @override
  R? visitSwitchStatement(SwitchStatement node) => visitStatement(node);

  @override
  R? visitSymbolLiteral(SymbolLiteral node) => visitLiteral(node);

  @override
  R? visitThisExpression(ThisExpression node) => visitExpression(node);

  @override
  R? visitThrowExpression(ThrowExpression node) => visitExpression(node);

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitCompilationUnitMember(node);

  @override
  R? visitTryStatement(TryStatement node) => visitStatement(node);

  R? visitTypeAlias(TypeAlias node) => visitNamedCompilationUnitMember(node);

  R? visitTypeAnnotation(TypeAnnotation node) => visitNode(node);

  @override
  R? visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  R? visitTypedLiteral(TypedLiteral node) => visitLiteral(node);

  @override
  R? visitTypeLiteral(TypeLiteral node) => visitExpression(node);

  @override
  R? visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R? visitTypeParameterList(TypeParameterList node) => visitNode(node);

  R? visitUriBasedDirective(UriBasedDirective node) => visitDirective(node);

  @override
  R? visitVariableDeclaration(VariableDeclaration node) =>
      visitDeclaration(node);

  @override
  R? visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitStatement(node);

  @override
  R? visitWhenClause(WhenClause node) => visitNode(node);

  @override
  R? visitWhileStatement(WhileStatement node) => visitStatement(node);

  @override
  R? visitWildcardPattern(WildcardPattern node) => visitDartPattern(node);

  @override
  R? visitWithClause(WithClause node) => visitNode(node);

  @override
  R? visitYieldStatement(YieldStatement node) => visitStatement(node);
}

/// An AST visitor that captures visit call timings.
///
/// Clients may not extend, implement or mix-in this class.
class TimedAstVisitor<T> implements AstVisitor<T> {
  /// The base visitor whose visit methods will be timed.
  final AstVisitor<T> _baseVisitor;

  /// Collects elapsed time for visit calls.
  final Stopwatch stopwatch;

  /// Initialize a newly created visitor to time calls to the given base
  /// visitor's visits.
  TimedAstVisitor(this._baseVisitor, [Stopwatch? watch])
    : stopwatch = watch ?? Stopwatch();

  @override
  T? visitAdjacentStrings(AdjacentStrings node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAdjacentStrings(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAnnotation(Annotation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAnnotation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitArgumentList(ArgumentList node) {
    stopwatch.start();
    T? result = _baseVisitor.visitArgumentList(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAsExpression(AsExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAsExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAssertInitializer(AssertInitializer node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAssertInitializer(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAssertStatement(AssertStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAssertStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAssignedVariablePattern(AssignedVariablePattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAssignedVariablePattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAssignmentExpression(AssignmentExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAssignmentExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitAwaitExpression(AwaitExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitAwaitExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitBinaryExpression(BinaryExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitBinaryExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitBlock(Block node) {
    stopwatch.start();
    T? result = _baseVisitor.visitBlock(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitBlockFunctionBody(BlockFunctionBody node) {
    stopwatch.start();
    T? result = _baseVisitor.visitBlockFunctionBody(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitBooleanLiteral(BooleanLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitBooleanLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitBreakStatement(BreakStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitBreakStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCascadeExpression(CascadeExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCascadeExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCaseClause(CaseClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCaseClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCastPattern(CastPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCastPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCatchClause(CatchClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCatchClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCatchClauseParameter(CatchClauseParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCatchClauseParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitClassDeclaration(ClassDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitClassDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitClassTypeAlias(ClassTypeAlias node) {
    stopwatch.start();
    T? result = _baseVisitor.visitClassTypeAlias(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitComment(Comment node) {
    stopwatch.start();
    T? result = _baseVisitor.visitComment(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCommentReference(CommentReference node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCommentReference(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitCompilationUnit(CompilationUnit node) {
    stopwatch.start();
    T? result = _baseVisitor.visitCompilationUnit(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConditionalExpression(ConditionalExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConditionalExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConfiguration(Configuration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConfiguration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstantPattern(ConstantPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstantPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstructorDeclaration(ConstructorDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstructorDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstructorFieldInitializer(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstructorName(ConstructorName node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstructorName(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstructorReference(ConstructorReference node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstructorReference(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitConstructorSelector(ConstructorSelector node) {
    stopwatch.start();
    T? result = _baseVisitor.visitConstructorSelector(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitContinueStatement(ContinueStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitContinueStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDeclaredIdentifier(DeclaredIdentifier node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDeclaredIdentifier(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDeclaredVariablePattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDefaultFormalParameter(DefaultFormalParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDefaultFormalParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDoStatement(DoStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDoStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    stopwatch.start();
    T? result = _baseVisitor.visitDotShorthandConstructorInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDotShorthandInvocation(DotShorthandInvocation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDotShorthandInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDotShorthandPropertyAccess(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDottedName(DottedName node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDottedName(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitDoubleLiteral(DoubleLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitDoubleLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitEmptyFunctionBody(EmptyFunctionBody node) {
    stopwatch.start();
    T? result = _baseVisitor.visitEmptyFunctionBody(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitEmptyStatement(EmptyStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitEmptyStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitEnumConstantArguments(EnumConstantArguments node) {
    stopwatch.start();
    T? result = _baseVisitor.visitEnumConstantArguments(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitEnumConstantDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitEnumDeclaration(EnumDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitEnumDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExportDirective(ExportDirective node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExportDirective(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExpressionFunctionBody(ExpressionFunctionBody node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExpressionFunctionBody(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExpressionStatement(ExpressionStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExpressionStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExtendsClause(ExtendsClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExtendsClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExtensionDeclaration(ExtensionDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExtensionDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExtensionOnClause(ExtensionOnClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExtensionOnClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExtensionOverride(ExtensionOverride node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExtensionOverride(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitExtensionTypeDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFieldDeclaration(FieldDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFieldDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFieldFormalParameter(FieldFormalParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFieldFormalParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForEachPartsWithDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForEachPartsWithIdentifier(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForEachPartsWithPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForElement(ForElement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForElement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFormalParameterList(FormalParameterList node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFormalParameterList(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForPartsWithDeclarations(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForPartsWithExpression(ForPartsWithExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForPartsWithExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForPartsWithPattern(ForPartsWithPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForPartsWithPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitForStatement(ForStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitForStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionDeclaration(FunctionDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionDeclarationStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionExpression(FunctionExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionExpressionInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionReference(FunctionReference node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionReference(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionTypeAlias(FunctionTypeAlias node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionTypeAlias(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitFunctionTypedFormalParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitGenericFunctionType(GenericFunctionType node) {
    stopwatch.start();
    T? result = _baseVisitor.visitGenericFunctionType(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitGenericTypeAlias(GenericTypeAlias node) {
    stopwatch.start();
    T? result = _baseVisitor.visitGenericTypeAlias(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitGuardedPattern(GuardedPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitGuardedPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitHideCombinator(HideCombinator node) {
    stopwatch.start();
    T? result = _baseVisitor.visitHideCombinator(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitIfElement(IfElement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitIfElement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitIfStatement(IfStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitIfStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitImplementsClause(ImplementsClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitImplementsClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitImplicitCallReference(ImplicitCallReference node) {
    stopwatch.start();
    T? result = _baseVisitor.visitImplicitCallReference(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitImportDirective(ImportDirective node) {
    stopwatch.start();
    T? result = _baseVisitor.visitImportDirective(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitImportPrefixReference(ImportPrefixReference node) {
    stopwatch.start();
    T? result = _baseVisitor.visitImportPrefixReference(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitIndexExpression(IndexExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitIndexExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitInstanceCreationExpression(InstanceCreationExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitInstanceCreationExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitIntegerLiteral(IntegerLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitIntegerLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitInterpolationExpression(InterpolationExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitInterpolationExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitInterpolationString(InterpolationString node) {
    stopwatch.start();
    T? result = _baseVisitor.visitInterpolationString(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitIsExpression(IsExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitIsExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLabel(Label node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLabel(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLabeledStatement(LabeledStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLabeledStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLibraryDirective(LibraryDirective node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLibraryDirective(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLibraryIdentifier(LibraryIdentifier node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLibraryIdentifier(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitListLiteral(ListLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitListLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitListPattern(ListPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitListPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLogicalAndPattern(LogicalAndPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLogicalAndPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitLogicalOrPattern(LogicalOrPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitLogicalOrPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMapLiteralEntry(MapLiteralEntry node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMapLiteralEntry(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMapPattern(MapPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMapPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMapPatternEntry(MapPatternEntry node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMapPatternEntry(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMethodDeclaration(MethodDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMethodDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMethodInvocation(MethodInvocation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMethodInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMixinDeclaration(MixinDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMixinDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitMixinOnClause(MixinOnClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitMixinOnClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNamedExpression(NamedExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNamedExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNamedType(NamedType node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNamedType(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNativeClause(NativeClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNativeClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNativeFunctionBody(NativeFunctionBody node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNativeFunctionBody(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNullAssertPattern(NullAssertPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNullAssertPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNullAwareElement(NullAwareElement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNullAwareElement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNullCheckPattern(NullCheckPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNullCheckPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitNullLiteral(NullLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitNullLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitObjectPattern(ObjectPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitObjectPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitParenthesizedExpression(ParenthesizedExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitParenthesizedExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitParenthesizedPattern(ParenthesizedPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitParenthesizedPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPartDirective(PartDirective node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPartDirective(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPartOfDirective(PartOfDirective node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPartOfDirective(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPatternAssignment(PatternAssignment node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPatternAssignment(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPatternField(PatternField node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPatternField(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPatternFieldName(PatternFieldName node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPatternFieldName(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPatternVariableDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    stopwatch.start();
    T? result = _baseVisitor.visitPatternVariableDeclarationStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPostfixExpression(PostfixExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPostfixExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPrefixedIdentifier(PrefixedIdentifier node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPrefixedIdentifier(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPrefixExpression(PrefixExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPrefixExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitPropertyAccess(PropertyAccess node) {
    stopwatch.start();
    T? result = _baseVisitor.visitPropertyAccess(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordLiteral(RecordLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordPattern(RecordPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordTypeAnnotation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordTypeAnnotationNamedField(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordTypeAnnotationNamedFields(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    stopwatch.start();
    T? result = _baseVisitor.visitRecordTypeAnnotationPositionalField(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    stopwatch.start();
    T? result = _baseVisitor.visitRedirectingConstructorInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRelationalPattern(RelationalPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRelationalPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRepresentationConstructorName(RepresentationConstructorName node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRepresentationConstructorName(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRepresentationDeclaration(RepresentationDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRepresentationDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRestPatternElement(RestPatternElement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRestPatternElement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitRethrowExpression(RethrowExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitRethrowExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitReturnStatement(ReturnStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitReturnStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitScriptTag(ScriptTag node) {
    stopwatch.start();
    T? result = _baseVisitor.visitScriptTag(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSetOrMapLiteral(SetOrMapLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSetOrMapLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitShowCombinator(ShowCombinator node) {
    stopwatch.start();
    T? result = _baseVisitor.visitShowCombinator(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSimpleFormalParameter(SimpleFormalParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSimpleFormalParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSimpleIdentifier(SimpleIdentifier node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSimpleIdentifier(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSimpleStringLiteral(SimpleStringLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSimpleStringLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSpreadElement(SpreadElement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSpreadElement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitStringInterpolation(StringInterpolation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitStringInterpolation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSuperConstructorInvocation(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSuperExpression(SuperExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSuperExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSuperFormalParameter(SuperFormalParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSuperFormalParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchCase(SwitchCase node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchCase(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchDefault(SwitchDefault node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchDefault(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchExpression(SwitchExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchExpressionCase(SwitchExpressionCase node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchExpressionCase(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchPatternCase(SwitchPatternCase node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchPatternCase(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSwitchStatement(SwitchStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSwitchStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitSymbolLiteral(SymbolLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitSymbolLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitThisExpression(ThisExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitThisExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitThrowExpression(ThrowExpression node) {
    stopwatch.start();
    T? result = _baseVisitor.visitThrowExpression(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTopLevelVariableDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTryStatement(TryStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTryStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTypeArgumentList(TypeArgumentList node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTypeArgumentList(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTypeLiteral(TypeLiteral node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTypeLiteral(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTypeParameter(TypeParameter node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTypeParameter(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitTypeParameterList(TypeParameterList node) {
    stopwatch.start();
    T? result = _baseVisitor.visitTypeParameterList(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitVariableDeclaration(VariableDeclaration node) {
    stopwatch.start();
    T? result = _baseVisitor.visitVariableDeclaration(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitVariableDeclarationList(VariableDeclarationList node) {
    stopwatch.start();
    T? result = _baseVisitor.visitVariableDeclarationList(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitVariableDeclarationStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitWhenClause(WhenClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitWhenClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitWhileStatement(WhileStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitWhileStatement(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitWildcardPattern(WildcardPattern node) {
    stopwatch.start();
    T? result = _baseVisitor.visitWildcardPattern(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitWithClause(WithClause node) {
    stopwatch.start();
    T? result = _baseVisitor.visitWithClause(node);
    stopwatch.stop();
    return result;
  }

  @override
  T? visitYieldStatement(YieldStatement node) {
    stopwatch.start();
    T? result = _baseVisitor.visitYieldStatement(node);
    stopwatch.stop();
    return result;
  }
}

/// A helper class used to implement the correct order of visits for a
/// [BreadthFirstVisitor].
class _BreadthFirstChildVisitor extends UnifyingAstVisitor<void> {
  /// The [BreadthFirstVisitor] being helped by this visitor.
  final BreadthFirstVisitor outerVisitor;

  /// Initialize a newly created visitor to help the [outerVisitor].
  _BreadthFirstChildVisitor(this.outerVisitor);

  @override
  void visitNode(AstNode node) {
    outerVisitor._queue.add(node);
  }
}
