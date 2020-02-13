// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show convertElementToElementKind, ElementKind;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, Element, ExtensionElement, LibraryElement, LocalElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: a single absolute file path to analyze.');
    io.exit(1);
  }

  var rootPath = args[0];
  print('Analyzing root: \"$rootPath\"');
  if (!io.Directory(rootPath).existsSync()) {
    print('\tError: No such directory exists on this machine.\n');
    return;
  }

  var computer = RelevanceMetricsComputer();
  var stopwatch = Stopwatch();
  stopwatch.start();
  await computer.compute(rootPath);
  stopwatch.stop();
  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('Metrics computed in $duration');
  computer.printMetrics();
  io.exit(0);
}

/// An object that records the data used to compute the metrics.
class RelevanceData {
  static const String currentVersion = '1';

  /// A table mapping match distances to counts.
  Map<String, Map<int, int>> byDistance = {};

  /// A table mapping element kinds to counts by context.
  Map<String, Map<ElementKind, int>> byElementKind = {};

  /// A table mapping AST node classes to counts by context.
  Map<String, Map<String, int>> byNodeClass = {};

  /// A table mapping token types to counts by context.
  Map<String, Map<TokenType, int>> byTokenType = {};

  /// A table mapping match types to counts.
  Map<String, Map<bool, int>> byTypeMatch = {};

  /// Initialize a newly created set of relevance data to be empty.
  RelevanceData();

  /// Initialize a newly created set of relevance data to reflect the data in
  /// the given JSON encoded [content].
  RelevanceData.fromJson(String content) {
    _initializeFromJson(content);
  }

  /// Add the data from the given relevance [data] to this set of data.
  void addDataFrom(RelevanceData data) {
    _addToMap(byDistance, data.byDistance);
    _addToMap(byElementKind, data.byElementKind);
    _addToMap(byNodeClass, data.byNodeClass);
    _addToMap(byTokenType, data.byTokenType);
    _addToMap(byTypeMatch, data.byTypeMatch);
  }

  /// Record that a reference to an element was found and that the distance
  /// between that reference and the declaration site is the given [distance].
  /// The [descriptor] is used to describe the kind of distance being measured.
  void recordDistance(String descriptor, int distance) {
    var contextMap = byDistance.putIfAbsent(descriptor, () => {});
    contextMap[distance] = (contextMap[distance] ?? 0) + 1;
  }

  /// Record that an element of the given [kind] was found in the given
  /// [context].
  void recordElementKind(String context, ElementKind kind) {
    var contextMap = byElementKind.putIfAbsent(context, () => {});
    contextMap[kind] = (contextMap[kind] ?? 0) + 1;
  }

  /// Record that an element of the given [node] was found in the given
  /// [context].
  void recordNodeClass(String context, AstNode node) {
    var contextMap = byNodeClass.putIfAbsent(context, () => {});
    var className = node.runtimeType.toString();
    if (className.endsWith('Impl')) {
      className = className.substring(0, className.length - 4);
    }
    contextMap[className] = (contextMap[className] ?? 0) + 1;
  }

  /// Record that a token of the given [type] was found in the given [context].
  void recordTokenType(String context, TokenType type) {
    var contextMap = byTokenType.putIfAbsent(context, () => {});
    contextMap[type] = (contextMap[type] ?? 0) + 1;
  }

  /// Record whether the given [kind] or type match applied to a given argument
  /// (that is, whether [matches] is `true`).
  void recordTypeMatch(String kind, bool matches) {
    var contextMap = byTypeMatch.putIfAbsent(kind, () => {});
    contextMap[matches] = (contextMap[matches] ?? 0) + 1;
  }

  /// Return a JSON encoded string representing the data that was collected.
  String toJson() {
    return json.encode({
      'version': currentVersion,
      'byDistance': _encodeMap(byDistance, (distance) => distance.toString()),
      'byElementKind': _encodeMap(byElementKind, (kind) => kind.name),
      'byNodeClass': _encodeMap(byNodeClass, (className) => className),
      'byTokenType': _encodeMap(byTokenType, (type) => type.name),
      'byTypeMatch': _encodeMap(byTypeMatch, (match) => match.toString()),
    });
  }

  /// Add the data in the [source] map to the [target] map.
  void _addToMap<T>(
      Map<String, Map<T, int>> target, Map<String, Map<T, int>> source) {
    for (var outerEntry in source.entries) {
      var innerTarget = target.putIfAbsent(outerEntry.key, () => {});
      for (var innerEntry in outerEntry.value.entries) {
        var innerKey = innerEntry.key;
        innerTarget[innerKey] = (innerTarget[innerKey] ?? 0) + innerEntry.value;
      }
    }
  }

  Map<String, dynamic> _convert(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw FormatException('Expected a JSON map.', value);
  }

  /// Decode the content of the [source] map into the [target] map, using the
  /// [keyMapper] to map the inner keys from a string to a [T].
  void _decodeMap<T>(Map<String, Map<T, int>> target,
      Map<String, dynamic> source, T Function(String) keyMapper) {
    for (var outerEntry in source.entries) {
      var outerKey = outerEntry.key;
      var innerMap = _convert(outerEntry.value);
      for (var innerEntry in innerMap.entries) {
        var innerKey = keyMapper(innerEntry.key);
        var count = innerEntry.value as int;
        target.putIfAbsent(outerKey, () => {})[innerKey] = count;
      }
    }
  }

  /// Decode the content of the [map] map into form that can be JSON encoded,
  /// using the [keyMapper] to map the inner keys from a [T] to a string.
  Map<String, Map<String, int>> _encodeMap<T>(
      Map<String, Map<T, int>> map, String Function(T) keyMapper) {
    return map.map((key, value) => MapEntry(
        key, value.map((key, value) => MapEntry(keyMapper(key), value))));
  }

  /// Initialize the state of this object from the given JSON encoded [content].
  void _initializeFromJson(String content) {
    var tokenTypes = <String, TokenType>{};
    for (var type in TokenType.all) {
      tokenTypes[type.name] = type;
    }
    var contentObject = _convert(json.decode(content));
    var version = contentObject['version'].toString();
    if (version != currentVersion) {
      throw StateError(
          'Invalid version: expected $currentVersion, found $version');
    }
    _decodeMap(byDistance, _convert(contentObject['byDistance']),
        (distance) => int.parse(distance));
    _decodeMap(byElementKind, _convert(contentObject['byElementKind']),
        (key) => ElementKind.fromJson(null, null, key));
    _decodeMap(byNodeClass, _convert(contentObject['byNodeClass']),
        (className) => className);
    _decodeMap(byTokenType, _convert(contentObject['byTokenType']),
        (key) => tokenTypes[key]);
    _decodeMap(byTypeMatch, _convert(contentObject['byTypeMatch']),
        (match) => match == 'true' ? true : false);
  }
}

/// An object that visits a compilation unit in order to record the data used to
/// compute the metrics.
class RelevanceDataCollector extends RecursiveAstVisitor<void> {
  /// The relevance data being collected.
  final RelevanceData data;

  /// The library containing the compilation unit being visited.
  LibraryElement enclosingLibrary;

  /// The type system associated with the current compilation unit.
  TypeSystem typeSystem;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  RelevanceDataCollector(this.data);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // There are no completions.
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _recordDataForNode('Annotation (name)', node.name);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      if (argument is NamedExpression) {
        _recordDataForNode('ArgumentList (named)', argument.expression);
        _recordTypeMatch(argument.expression);
      } else {
        _recordDataForNode('ArgumentList (unnamed)', argument);
        _recordTypeMatch(argument);
      }
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _recordDataForNode('AsExpression (type)', node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _recordDataForNode('AssertInitializer (condition)', node.condition);
    _recordDataForNode('AssertInitializer (message)', node.message);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _recordDataForNode('AssertStatement (condition)', node.condition);
    _recordDataForNode('AssertStatement (message)', node.message);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _recordDataForNode('AssignmentExpression (rhs)', node.rightHandSide);
    var operatorType = node.operator.type;
    if (operatorType != TokenType.EQ &&
        operatorType != TokenType.QUESTION_QUESTION_EQ) {
      _recordTypeMatch(node.rightHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _recordDataForNode('AwaitExpression (expression)', node.expression);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var operator = node.operator.lexeme;
    _recordDataForNode('BinaryExpression ($operator)', node.rightOperand);
    if (node.operator.isUserDefinableOperator) {
      _recordTypeMatch(node.rightOperand);
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    for (var statement in node.statements) {
      _recordDataForNode('Block (statement)', statement);
    }
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _recordTokenType('BlockFunctionBody (start)', node);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _recordTokenType('BooleanLiteral (start)', node);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    // The token following the `break` (if there is one) is always a label.
    super.visitBreakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var cascade in node.cascadeSections) {
      _recordDataForNode('CascadeExpression (section)', cascade);
    }
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _recordDataForNode('CatchClause (on)', node.exceptionType);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // After the name and optional type parameters.
    if (node.extendsClause != null) {
      _recordTokenType('ClassDeclaration (name)', node.extendsClause);
      if (node.withClause != null) {
        _recordTokenType('ClassDeclaration (extends)', node.withClause);
        _recordTokenType('ClassDeclaration (with)', node.implementsClause);
      } else {
        _recordTokenType('ClassDeclaration (extends)', node.implementsClause);
      }
    } else if (node.withClause != null) {
      _recordTokenType('ClassDeclaration (name)', node.withClause);
      _recordTokenType('ClassDeclaration (with)', node.implementsClause);
    } else {
      _recordTokenType('ClassDeclaration (name)', node.implementsClause);
    }
    // At the start of each member.
    for (var member in node.members) {
      _recordDataForNode('ClassDeclaration (member)', member);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _recordDataForNode('ClassTypeAlias (superclass)', node.superclass);
    if (node.withClause != null) {
      _recordTokenType('ClassDeclaration (superclass)', node.withClause);
      _recordTokenType('ClassDeclaration (with)', node.implementsClause);
    } else {
      _recordTokenType('ClassDeclaration (superclass)', node.implementsClause);
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    // There are no completions.
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _recordDataForNode('CommentReference (name)', node.identifier);
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    enclosingLibrary = node.declaredElement.library;
    typeSystem = enclosingLibrary.typeSystem;

    for (var member in node.directives) {
      _recordTokenType('CompilationUnit (directive)', member);
    }
    for (var member in node.declarations) {
      _recordDataForNode('CompilationUnit (declaration)', member);
    }
    super.visitCompilationUnit(node);

    typeSystem = null;
    enclosingLibrary = null;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _recordDataForNode('ConditionalExpression (then)', node.thenExpression);
    _recordDataForNode('ConditionalExpression (else)', node.elseExpression);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    // There are no completions.
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers) {
      _recordTokenType('ConstructorDeclaration (initializer)', initializer);
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _recordDataForNode(
        'ConstructorFieldInitializer (expression)', node.expression);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // The token following the `.` is always an identifier.
    super.visitConstructorName(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    // The token following the `continue` (if there is one) is always a label.
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    // There are no completions.
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _recordDataForNode(
        'DefaultFormalParameter (defaultValue)', node.defaultValue);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _recordDataForNode('DoStatement (body)', node.body);
    _recordDataForNode('DoStatement (condition)', node.condition);
    super.visitDoStatement(node);
  }

  @override
  void visitDottedName(DottedName node) {
    // The components are always identifiers.
    super.visitDottedName(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // There are no completions.
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    // There are no completions.
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    // There are no completions.
    super.visitEmptyStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // There are no completions.
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // There are no completions.
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    if (node.configurations.isNotEmpty) {
      _recordTokenType('ImportDirective (uri)', node.configurations[0]);
    } else if (node.combinators.isNotEmpty) {
      _recordTokenType('ImportDirective (uri)', node.combinators[0]);
    }
    for (var combinator in node.combinators) {
      _recordTokenType('ImportDirective (combinator)', combinator);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _recordTokenType('ExpressionFunctionBody (start)', node);
    _recordDataForNode('ExpressionFunctionBody (expression)', node.expression);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _recordDataForNode('ExpressionStatement (start)', node.expression);
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _recordDataForNode('ExtendsClause (type)', node.superclass);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _recordDataForNode('ExtensionDeclaration (type)', node.extendedType);
    for (var member in node.members) {
      _recordDataForNode('ExtensionDeclaration (member)', member);
    }
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    // There are no completions.
    super.visitExtensionOverride(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // There are no completions.
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    // The completions after `this.` are always existing fields.
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _recordDataForNode(
        'ForEachPartsWithDeclaration (declaration)', node.loopVariable);
    _recordDataForNode('ForEachPartsWithDeclaration (in)', node.iterable);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _recordDataForNode('ForEachPartsWithIdentifier (in)', node.iterable);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _recordNodeClass('ForElement (parts)', node.forLoopParts);
    _recordTokenType('ForElement (parts)', node.forLoopParts);
    _recordDataForNode('ForElement (body)', node.body);
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      _recordDataForNode('FormalParameterList (parameter)', parameter);
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _recordDataForNode('ForPartsWithDeclarations (condition)', node.condition);
    for (var updater in node.updaters) {
      _recordDataForNode('ForPartsWithDeclarations (updater)', updater);
    }
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _recordDataForNode('ForPartsWithDeclarations (condition)', node.condition);
    for (var updater in node.updaters) {
      _recordDataForNode('ForPartsWithDeclarations (updater)', updater);
    }
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _recordNodeClass('ForElement (parts)', node.forLoopParts);
    _recordTokenType('ForElement (parts)', node.forLoopParts);
    _recordDataForNode('ForElement (body)', node.body);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // There are no completions.
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // There are no completions.
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // There are no completions.
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // There are no completions.
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // There are no completions.
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    // There are no completions.
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // There are no completions.
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _recordDataForNode('GenericTypeAlias (functionType)', node.functionType);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    for (var name in node.hiddenNames) {
      _recordDataForNode('HideCombinator (name)', name);
    }
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _recordDataForNode('IfElement (condition)', node.condition);
    _recordDataForNode('IfElement (then)', node.thenElement);
    _recordDataForNode('IfElement (else)', node.elseElement);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _recordDataForNode('IfStatement (condition)', node.condition);
    _recordDataForNode('IfStatement (then)', node.thenStatement);
    _recordDataForNode('IfStatement (else)', node.elseStatement);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    // At the start of each type name.
    for (var typeName in node.interfaces) {
      _recordDataForNode('ImplementsClause (type)', typeName);
    }
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (node.deferredKeyword != null) {
      data.recordTokenType('ImportDirective (uri)', node.deferredKeyword.type);
    } else if (node.asKeyword != null) {
      data.recordTokenType('ImportDirective (uri)', node.asKeyword.type);
    } else if (node.configurations.isNotEmpty) {
      _recordTokenType('ImportDirective (uri)', node.configurations[0]);
    } else if (node.combinators.isNotEmpty) {
      _recordTokenType('ImportDirective (uri)', node.combinators[0]);
    }
    for (var combinator in node.combinators) {
      _recordTokenType('ImportDirective (combinator)', combinator);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _recordDataForNode('IndexExpression (index)', node.index);
    _recordTypeMatch(node.index);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // There are no completions.
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // There are no completions.
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _recordDataForNode('InterpolationExpression (expression)', node.expression);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    // There are no completions.
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _recordDataForNode('IsExpression (type)', node.type);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    // There are no completions.
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _recordDataForNode('LabeledStatement (statement)', node.statement);
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    // There are no completions.
    super.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    // There are no completions.
    super.visitLibraryIdentifier(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    for (var element in node.elements) {
      _recordDataForNode('ListLiteral (element)', element);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _recordDataForNode('MapLiteralEntry (value)', node.value);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // There are no completions.
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordMemberDepth(node.target?.staticType, node.methodName.staticElement);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // After the name and optional type parameters.
    if (node.onClause != null) {
      _recordTokenType('MixinDeclaration (name)', node.onClause);
      _recordTokenType('MixinDeclaration (on)', node.implementsClause);
    } else {
      _recordTokenType('MixinDeclaration (name)', node.implementsClause);
    }
    // At the start of each member.
    for (var member in node.members) {
      _recordDataForNode('MixinDeclaration (member)', member);
    }
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    // Named expressions only occur in argument lists and are handled there.
    super.visitNamedExpression(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    // There are no completions.
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    // There are no completions.
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // There are no completions.
    super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    for (var constraint in node.superclassConstraints) {
      _recordDataForNode('OnClause (type)', constraint);
    }
    super.visitOnClause(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _recordDataForNode('ParenthesizedExpression (expression)', node.expression);
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    // There are no completions.
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    // There are no completions.
    super.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _recordTypeMatch(node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // There are no completions.
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordDataForNode('PrefixExpression (${node.operator})', node.operand);
    _recordTypeMatch(node.operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _recordMemberDepth(
        node.target?.staticType, node.propertyName.staticElement);
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    // There are no completions.
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // There are no completions.
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _recordDataForNode('ReturnStatement (expression)', node.expression);
    if (node.expression == null) {
      data.recordTokenType('ReturnStatement (expression)', node.semicolon.type);
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    // There are no completions.
    super.visitScriptTag(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    for (var element in node.elements) {
      _recordDataForNode('SetOrMapLiteral (element)', element);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    for (var name in node.shownNames) {
      _recordDataForNode('ShowCombinator (name)', name);
    }
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    // There are no completions.
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      var element = node.staticElement;
      if (element != null) {
        // TODO(brianwilkerson) We might want to cross reference the depth of
        //  the declaration with the depth of the reference to see whether there
        //  is a pattern.
        _recordDistance('depth', _depth(element));
      }
      if (element is LocalElement) {
        // TODO(brianwilkerson) Record the distance between the reference site
        //  and the declaration site to determine whether local variables that
        //  are declared nearer are more likely to be referenced.
      }
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // There are no completions.
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _recordDataForNode('SpreadElement (expression)', node.expression);
    super.visitSpreadElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // There are no completions.
    super.visitStringInterpolation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // There are no completions.
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    // There are no completions.
    super.visitSuperExpression(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _recordDataForNode('SwitchCase (expression)', node.expression);
    for (var statement in node.statements) {
      _recordDataForNode('SwitchCase (statement)', statement);
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    for (var statement in node.statements) {
      _recordDataForNode('SwitchDefault (statement)', statement);
    }
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _recordDataForNode('SwitchStatement (expression)', node.expression);
    super.visitSwitchStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    // There are no completions.
    super.visitSymbolLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    // There are no completions.
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _recordDataForNode('ThrowExpression (expression)', node.expression);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // There are no completions.
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    for (var clause in node.catchClauses) {
      _recordTokenType('TryStatement (clause)', clause);
    }
    if (node.finallyKeyword != null) {
      data.recordTokenType('TryStatement (clause)', node.finallyKeyword.type);
    }
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    for (var typeArgument in node.arguments) {
      _recordDataForNode('TypeArgumentList (argument)', typeArgument);
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeName(TypeName node) {
    // There are no completions.
    super.visitTypeName(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node.bound != null) {
      _recordDataForNode('TypeParameter (bound)', node.bound);
    }
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    // There are no completions.
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _recordDataForNode('VariableDeclaration (initializer)', node.initializer);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    // There are no completions.
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    // There are no completions.
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _recordDataForNode('WhileStatement (condition)', node.condition);
    _recordDataForNode('WhileStatement (body)', node.body);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    for (var typeName in node.mixinTypes) {
      _recordDataForNode('WithClause (type)', typeName);
    }
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _recordDataForNode('YieldStatement (expression)', node.expression);
    super.visitYieldStatement(node);
  }

  /// Return the depth of the given [element]. For example:
  /// 0: imported
  /// 1: prefix
  /// 2: top-level decl
  /// 3: class member
  /// 4: local variable, function, parameter
  /// 5: local to a local function
  int _depth(Element element) {
    if (element.library != enclosingLibrary) {
      return 0;
    }
    var depth = 0;
    var currentElement = element;
    while (currentElement != enclosingLibrary) {
      depth++;
      currentElement = currentElement.enclosingElement;
    }
    return depth;
  }

  /// Return the first child of the [node] that is neither a comment nor an
  /// annotation.
  SyntacticEntity _firstChild(AstNode node) {
    var children = node.childEntities.toList();
    for (int i = 0; i < children.length; i++) {
      var child = children[i];
      if (child is! Comment && child is! Annotation) {
        return child;
      }
    }
    return null;
  }

  /// Return the left-most child of the [node] if it is a simple identifier, or
  /// `null` if the left-most child is not a simple identifier. Comments and
  /// annotations are ignored for this purpose.
  SimpleIdentifier _leftMostIdentifier(AstNode node) {
    var currentNode = node;
    while (currentNode != null && currentNode is! SimpleIdentifier) {
      var firstChild = _firstChild(currentNode);
      if (firstChild is AstNode) {
        currentNode = firstChild;
      } else {
        currentNode = null;
      }
    }
    if (currentNode is SimpleIdentifier && currentNode.inDeclarationContext()) {
      return null;
    }
    return currentNode;
  }

  /// Return the element kind of the element associated with the left-most
  /// identifier that is a child of the [node].
  ElementKind _leftMostKind(AstNode node) {
    var identifier = _leftMostIdentifier(node);
    var element = identifier?.staticElement;
    if (element == null) {
      return null;
    }
    return convertElementToElementKind(element);
  }

  /// Return the left-most token that is a child of the [node].
  Token _leftMostToken(AstNode node) {
    SyntacticEntity entity = node;
    while (entity is AstNode) {
      entity = _firstChild(entity as AstNode);
    }
    if (entity is Token) {
      return entity;
    }
    return null;
  }

  /// Record information about the given [node] occurring the given [context].
  void _recordDataForNode(String context, AstNode node) {
    _recordElementKind(context, node);
    _recordNodeClass(context, node);
    _recordTokenType(context, node);
  }

  /// Record the [distance] from a reference to the declaration. The kind of
  /// distance is described by the [descriptor].
  void _recordDistance(String descriptor, int distance) {
    data.recordDistance(descriptor, distance);
  }

  /// Record the element kind of the element associated with the left-most
  /// identifier that is a child of the [node] in the given [context].
  void _recordElementKind(String context, AstNode node) {
    if (node != null) {
      var kind = _leftMostKind(node);
      if (kind != null) {
        data.recordElementKind(context, kind);
      }
    }
  }

  /// Record the distance between the static type of the target (the
  /// [targetType]) and the [element] to which the member reference was
  /// resolved.
  void _recordMemberDepth(DartType targetType, Element element) {
    if (targetType is InterfaceType) {
      var subclass = targetType.element;
      var extension = element.thisOrAncestorOfType<ExtensionElement>();
      if (extension != null) {
        // TODO(brianwilkerson) It might be interesting to also know whether the
        //  [element] was found in a class, interface, mixin or extension.
        return;
      }
      var superclass = element.thisOrAncestorOfType<ClassElement>();
      if (superclass != null) {
        int getSuperclassDepth() {
          var depth = 0;
          var currentClass = subclass;
          while (currentClass != null) {
            if (currentClass == superclass) {
              return depth;
            }
            for (var mixin in currentClass.mixins.reversed) {
              depth++;
              if (mixin.element == superclass) {
                return depth;
              }
            }
            depth++;
            currentClass = currentClass.supertype?.element;
          }
          return -1;
        }

        var notFound = 0xFFFF;
        int getInterfaceDepth(ClassElement currentClass) {
          if (currentClass == null) {
            return notFound;
          } else if (currentClass == superclass) {
            return 0;
          }
          var minDepth = getInterfaceDepth(currentClass.supertype?.element);
          for (var mixin in currentClass.mixins) {
            var depth = getInterfaceDepth(mixin.element);
            if (depth < minDepth) {
              minDepth = depth;
            }
          }
          for (var interface in currentClass.interfaces) {
            var depth = getInterfaceDepth(interface.element);
            if (depth < minDepth) {
              minDepth = depth;
            }
          }
          return minDepth + 1;
        }

        int superclassDepth = getSuperclassDepth();
        if (superclassDepth >= 0) {
          _recordDistance('member (superclass)', superclassDepth);
        } else {
          int interfaceDepth = getInterfaceDepth(subclass);
          if (interfaceDepth < notFound) {
            _recordDistance('member (interface)', interfaceDepth);
          } else {
            _recordDistance('member (not found)', 0);
          }
        }
      }
    }
  }

  /// Record the class of the [node] in the given [context].
  void _recordNodeClass(String context, AstNode node) {
    if (node != null) {
      data.recordNodeClass(context, node);
    }
  }

  /// Record the token type of the left-most token that is a child of the
  /// [node] in the given [context].
  void _recordTokenType(String context, AstNode node) {
    if (node != null) {
      var token = _leftMostToken(node);
      if (token != null) {
        data.recordTokenType(context, token.type);
      }
    }
  }

  /// Record information about how the argument as a whole and the first token
  /// in the expression match the type of the associated parameter.
  void _recordTypeMatch(Expression argument) {
    var parameterType = argument.staticParameterElement?.type;
    if (parameterType == null || parameterType.isDynamic) {
      return;
    }
    var argumentType = argument.staticType;
    if (argumentType != null) {
      _recordTypeRelationships('whole argument', parameterType, argumentType);
    }
    var identifier = _leftMostIdentifier(argument);
    if (identifier != null) {
      var firstTokenType = identifier.staticType;
      if (firstTokenType == null) {
        var element = identifier.staticElement;
        if (element is ClassElement) {
          // This is effectively treating a reference to a class name as having
          // the same type as an instance of the class, which isn't valid, but
          // on the other hand, the spec doesn't define the static type of a
          // class name in this context so anything we do will be wrong in some
          // sense.
          firstTokenType = element.thisType;
        }
      }
      if (firstTokenType != null) {
        _recordTypeRelationships('first token', parameterType, firstTokenType);
      }
    }
  }

  /// Record information about how the [parameterType] and [argumentType] are
  /// related, using the [descriptor] to differentiate between the counts.
  void _recordTypeRelationships(
      String descriptor, DartType parameterType, DartType argumentType) {
    var matches = argumentType == parameterType;
    data.recordTypeMatch('$descriptor (exact)', matches);

    var subtype = typeSystem.isSubtypeOf(argumentType, parameterType);
    data.recordTypeMatch('$descriptor (subtype)', subtype);
  }
}

/// An object used to compute metrics for a single file or directory.
class RelevanceMetricsComputer {
  /// The metrics data that was computed.
  final RelevanceData data = RelevanceData();

  /// Initialize a newly created metrics computer that can compute the metrics
  /// in one or more files and directories.
  RelevanceMetricsComputer();

  /// Compute the metrics for the file(s) in the [rootPath].
  void compute(String rootPath) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = RelevanceDataCollector(data);

    for (var context in collection.contexts) {
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath)) {
          try {
            ResolvedUnitResult resolvedUnitResult =
                await context.currentSession.getResolvedUnit(filePath);
            //
            // Check for errors that cause the file to be skipped.
            //
            if (resolvedUnitResult.state != ResultState.VALID) {
              print('File $filePath skipped because it could not be analyzed.');
              print('');
              continue;
            } else if (hasError(resolvedUnitResult)) {
              print('File $filePath skipped due to errors:');
              for (var error in resolvedUnitResult.errors) {
                print('  ${error.toString()}');
              }
              print('');
              continue;
            }

            resolvedUnitResult.unit.accept(collector);
          } catch (exception) {
            print('Exception caught analyzing: "$filePath"');
            print(exception.toString());
          }
        }
      }
    }
  }

  /// Print a report of the metrics that were computed.
  void printMetrics() {
    print('');
    print('Node classes by context');
    _printContextMap(data.byNodeClass, (className) => className);
    print('');
    print('Element kinds by context');
    _printContextMap(data.byElementKind, (kind) => kind.name);
    print('');
    print('Token types by context');
    _printContextMap(data.byTokenType, (type) => type.name);
    print('');
    print('Argument types match');
    _printContextMap(data.byTypeMatch, (match) => match.toString());
    print('');
    print('Distance from reference to declaration');
    _printContextMap(data.byDistance, (distance) => distance.toString());
  }

  /// Print a [contextMap] containing one kind of metric data, using the
  /// [getName] function to print the second-level keys.
  void _printContextMap<T>(
      Map<String, Map<T, int>> contextMap, String Function(T) getName) {
    var contexts = contextMap.keys.toList()..sort();
    for (var context in contexts) {
      var kindMap = contextMap[context];
      var entries = kindMap.entries.toList()
        ..sort((first, second) {
          return second.value.compareTo(first.value);
        });
      var total = 0;
      for (var entry in entries) {
        total += entry.value;
      }
      print('  $context ($total)');
      for (var entry in entries) {
        var value = entry.value;
        var percent = ((value / total) * 100).toStringAsFixed(1);
        if (percent.length < 4) {
          percent = ' $percent';
        }
        print('    $percent%: ${getName(entry.key)} ($value)');
      }
    }
  }

  /// Return `true` if the [result] contains an error.
  static bool hasError(ResolvedUnitResult result) {
    for (var error in result.errors) {
      if (error.severity == Severity.error) {
        return true;
      }
    }
    return false;
  }
}
