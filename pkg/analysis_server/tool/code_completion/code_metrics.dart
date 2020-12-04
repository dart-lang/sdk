// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:args/args.dart';

/// Compute and print lexical and semantic information about a package.
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var out = io.stdout;
    var rootPath = result.rest[0];
    out.writeln('Analyzing root: "$rootPath"');

    var computer = CodeShapeMetricsComputer();
    var stopwatch = Stopwatch();
    stopwatch.start();
    await computer.compute(rootPath);
    stopwatch.stop();
    var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
    out.writeln('  Analysis performed in $duration');
    computer.writeResults(out);
    await out.flush();
  }
  io.exit(0);
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  var parser = ArgParser();
  parser.addOption(
    'help',
    abbr: 'h',
    help: 'Print this help message.',
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart code_metrics.dart [options] packagePath');
  print('');
  print('Compute and print lexical and semantic information about a package.');
  print('');
  print(parser.usage);
}

/// Return `true` if the command-line arguments (represented by the [result] and
/// parsed by the [parser]) are valid.
bool validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    printUsage(parser);
    return false;
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No package path specified.');
    return false;
  }
  var rootPath = result.rest[0];
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// An object that records the data used to compute the metrics.
class CodeShapeData {
  /// A table mapping the name of a node class to the number of instances of
  /// that class that were visited.
  Map<String, int> nodeData = {};

  /// A table mapping the name of a node class and the name of the node's
  /// parent's class to the number of instances of the node class that had a
  /// parent of the parent class.
  Map<String, Map<String, int>> parentData = {};

  /// A table mapping the name of a node class, the name of a property of that
  /// node, and the class of the property's value to number of instances of the
  /// node class that had a value of the property class for the property.
  Map<String, Map<String, Map<String, int>>> childData = {};

  /// A table mapping the name of a node class, the name of a list-valued
  /// property of that node, and the length of the list to number of instances
  /// of the node class that had a value of that length for the property.
  Map<String, Map<String, Map<int, int>>> lengthData = {};

  /// Information about children of nodes that were not correctly recorded.
  Set<String> missedChildren = {};

  /// Initialize a newly created set of relevance data to be empty.
  CodeShapeData();

  /// Record that an element of the given [node] was found in the given
  /// [context].
  void recordNode(String nodeClassName, String property, AstNode node) {
    var childClass = node?.runtimeType?.toString() ?? 'null';
    if (childClass.endsWith('Impl')) {
      childClass = childClass.substring(0, childClass.length - 4);
    }
    _recordChildData(nodeClassName, property, childClass);
  }

  /// Record that a node that is an instance of the [nodeClassName] was visited.
  void recordNodeClass(String nodeClassName) {
    nodeData[nodeClassName] = (nodeData[nodeClassName] ?? 0) + 1;
  }

  void recordNodeList(String nodeClassName, String property, NodeList list) {
    _recordListLength(nodeClassName, property, list);
    for (var element in list) {
      recordNode(nodeClassName, property, element);
    }
  }

  void recordParentClass(String nodeClassName, String parentClassName) {
    var classMap = parentData.putIfAbsent(nodeClassName, () => {});
    classMap[parentClassName] = (classMap[parentClassName] ?? 0) + 1;
  }

  void recordToken(String nodeClassName, String property, Token token) {
    var lexeme = token?.lexeme ?? 'null';
    _recordChildData(nodeClassName, property, lexeme);
  }

  void _recordChildData(
      String nodeClassName, String property, String childValue) {
    var classMap = childData.putIfAbsent(nodeClassName, () => {});
    var propertyMap = classMap.putIfAbsent(property, () => {});
    propertyMap[childValue] = (propertyMap[childValue] ?? 0) + 1;
  }

  /// Record that an element of the given [node] was found in the given
  /// [context].
  void _recordListLength(String nodeClassName, String property, NodeList list) {
    var classMap = lengthData.putIfAbsent(nodeClassName, () => {});
    var propertyMap = classMap.putIfAbsent(property, () => {});
    var length = list.length;
    propertyMap[length] = (propertyMap[length] ?? 0) + 1;
  }
}

/// An object that visits a compilation unit in order to record the data used to
/// compute the metrics.
class CodeShapeDataCollector extends RecursiveAstVisitor<void> {
  /// The data being collected.
  final CodeShapeData data;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  CodeShapeDataCollector(this.data);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _visitChildren(node, {
      'strings': node.strings,
    });
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _visitChildren(node, {
      'name': node.name,
      'constructorName': node.constructorName,
      'arguments': node.arguments,
    });
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _visitChildren(node, {
      'arguments': node.arguments,
    });
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
      'type': node.type,
    });
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _visitChildren(node, {
      'condition': node.condition,
      'message': node.message,
    });
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _visitChildren(node, {
      'condition': node.condition,
      'message': node.message,
    });
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _visitChildren(node, {
      'leftHandSide': node.leftHandSide,
      'operator': node.operator,
      'rightHandSide': node.rightHandSide,
    });
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _visitChildren(node, {
      'leftOperand': node.leftOperand,
      'operator': node.operator,
      'rightOperand': node.rightOperand,
    });
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    _visitChildren(node, {
      'statement': node.statements,
    });
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _visitChildren(node, {
      'keyword': node.keyword,
      'star': node.star,
      'block': node.block,
    });
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _visitChildren(node, {
      'literal': node.literal,
    });
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _visitChildren(node, {
      'label': node.label,
    });
    super.visitBreakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _visitChildren(node, {
      'target': node.target,
      'cascadeSections': node.cascadeSections,
    });
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _visitChildren(node, {
      'exceptionType': node.exceptionType,
      'exceptionParameter': node.exceptionParameter,
      'stackTraceParameter': node.stackTraceParameter,
      'body': node.body,
    });
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'abstractKeyword': node.abstractKeyword,
      'name': node.name,
      'typeParameters': node.typeParameters,
      'extendsClause': node.extendsClause,
      'withClause': node.withClause,
      'implementsClause': node.implementsClause,
      'nativeClause': node.nativeClause,
      'members': node.members,
    });
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'abstractKeyword': node.abstractKeyword,
      'name': node.name,
      'typeParameters': node.typeParameters,
      'superclass': node.superclass,
      'withClause': node.withClause,
      'implementsClause': node.implementsClause,
    });
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    _visitChildren(node, {'references': node.references});
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _visitChildren(node, {
      'newKeyword': node.newKeyword,
      'identifier': node.identifier,
    });
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _visitChildren(node, {
      'scriptTag': node.scriptTag,
      'directives': node.directives,
      'declarations': node.declarations,
    });
    super.visitCompilationUnit(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _visitChildren(node, {
      'condition': node.condition,
      'thenExpression': node.thenExpression,
      'elseExpression': node.elseExpression,
    });
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    _visitChildren(node, {
      'name': node.name,
      'value': node.value,
      'uri': node.uri,
    });
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'externalKeyword': node.externalKeyword,
      'constKeyword': node.constKeyword,
      'factoryKeyword': node.factoryKeyword,
      'returnType': node.returnType,
      'name': node.name,
      'parameters': node.parameters,
      'initializers': node.initializers,
      'redirectedConstructor': node.redirectedConstructor,
      'body': node.body,
    });
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _visitChildren(node, {
      'thisKeyword': node.thisKeyword,
      'fieldName': node.fieldName,
      'expression': node.expression,
    });
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _visitChildren(node, {
      'type': node.type,
      'name': node.name,
    });
    super.visitConstructorName(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _visitChildren(node, {
      'label': node.label,
    });
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _visitChildren(node, {
      'keyword': node.keyword,
      'type': node.type,
      'identifier': node.identifier,
    });
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _visitChildren(node, {
      'parameter': node.parameter,
      'defaultValue': node.defaultValue,
    });
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _visitChildren(node, {
      'body': node.body,
      'condition': node.condition,
    });
    super.visitDoStatement(node);
  }

  @override
  void visitDottedName(DottedName node) {
    _visitChildren(node, {
      'components': node.components,
    });
    super.visitDottedName(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _visitChildren(node, {});
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _visitChildren(node, {});
    super.visitEmptyFunctionBody(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _visitChildren(node, {});
    super.visitEmptyStatement(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
    });
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
      'constants': node.constants,
    });
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'uri': node.uri,
      'configurations': node.configurations,
      'combinators': node.combinators,
    });
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _visitChildren(node, {
      'keyword': node.keyword,
      'star': node.star,
      'expression': node.expression,
    });
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _visitChildren(node, {
      'superclass': node.superclass,
    });
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _visitChildren(node, {
      'name': node.name,
      'typeParameters': node.typeParameters,
      'extendedType': node.extendedType,
      'member': node.members,
    });
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _visitChildren(node, {
      'extensionName': node.extensionName,
      'typeArguments': node.typeArguments,
      'argumentList': node.argumentList,
    });
    super.visitExtensionOverride(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'abstractKeyword': node.abstractKeyword,
      'covariantKeyword': node.covariantKeyword,
      'externalKeyword': node.externalKeyword,
      'staticKeyword': node.staticKeyword,
      'fields': node.fields,
    });
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'keyword': node.keyword,
      'type': node.type,
      'thisKeyword': node.thisKeyword,
      'identifier': node.identifier,
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'question': node.question,
    });
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _visitChildren(node, {
      'loopVariable': node.loopVariable,
      'iterable': node.iterable,
    });
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _visitChildren(node, {
      'identifier': node.identifier,
      'iterable': node.iterable,
    });
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _visitChildren(node, {
      'awaitKeyword': node.awaitKeyword,
      'forLoopParts': node.forLoopParts,
      'body': node.body,
    });
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _visitChildren(node, {
      'parameters': node.parameters,
    });
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _visitChildren(node, {
      'variables': node.variables,
      'condition': node.condition,
      'updater': node.updaters,
    });
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _visitChildren(node, {
      'initialization': node.initialization,
      'condition': node.condition,
      'updater': node.updaters,
    });
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _visitChildren(node, {
      'awaitKeyword': node.awaitKeyword,
      'forLoopParts': node.forLoopParts,
      'body': node.body,
    });
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'externalKeyword': node.externalKeyword,
      'propertyKeyword': node.propertyKeyword,
      'name': node.name,
      'functionExpression': node.functionExpression,
      'returnType': node.returnType,
    });
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _visitChildren(node, {
      'functionDeclaration': node.functionDeclaration,
    });
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitChildren(node, {
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'body': node.body,
    });
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _visitChildren(node, {
      'function': node.function,
      'typeArguments': node.typeArguments,
      'argumentList': node.argumentList,
    });
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'returnType': node.returnType,
      'name': node.name,
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
    });
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _visitChildren(node, {
      'covariantKeyword': node.covariantKeyword,
      'returnType': node.returnType,
      'identifier': node.identifier,
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'question': node.question,
    });
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _visitChildren(node, {
      'returnType': node.returnType,
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'question': node.question,
    });
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
      'typeParameters': node.typeParameters,
      'functionType': node.functionType,
    });
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _visitChildren(node, {
      'hiddenNames': node.hiddenNames,
    });
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _visitChildren(node, {
      'condition': node.condition,
      'thenElement': node.thenElement,
      'elseElement': node.elseElement,
    });
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _visitChildren(node, {
      'condition': node.condition,
      'thenStatement': node.thenStatement,
      'elseStatement': node.elseStatement,
    });
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _visitChildren(node, {
      'interfaces': node.interfaces,
    });
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'uri': node.uri,
      'deferredKeyword': node.deferredKeyword,
      'asKeyword': node.asKeyword,
      'prefix': node.prefix,
      'configurations': node.configurations,
      'combinators': node.combinators,
    });
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _visitChildren(node, {
      'target': node.target,
      'index': node.index,
    });
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitChildren(node, {
      'keyword': node.keyword,
      'constructorName': node.constructorName,
      'argumentList': node.argumentList,
    });
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    var value = node.value;
    if (value == -1 || value == 0 || value == 1) {
      _visitChildren(node, {
        'literal': node.literal,
      });
    } else {
      _visitChildren(node, {});
    }
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _visitChildren(node, {});
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
      'type': node.type,
    });
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    _visitChildren(node, {
      'label': node.label,
    });
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _visitChildren(node, {
      'statement': node.statement,
    });
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
    });
    super.visitLibraryDirective(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _visitChildren(node, {
      'components': node.components,
    });
    super.visitLibraryIdentifier(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _visitChildren(node, {
      'typeArguments': node.typeArguments,
      'elements': node.elements,
    });
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _visitChildren(node, {
      'key': node.key,
      'value': node.value,
    });
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'externalKeyword': node.externalKeyword,
      'modifierKeyword': node.modifierKeyword,
      'returnType': node.returnType,
      'name': node.name,
      'operatorKeyword': node.operatorKeyword,
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'body': node.body,
    });
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _visitChildren(node, {
      'target': node.target,
      'methodName': node.methodName,
      'typeArguments': node.typeArguments,
      'argumentList': node.argumentList,
    });
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
      'typeParameters': node.typeParameters,
      'onClause': node.onClause,
      'implementsClause': node.implementsClause,
      'members': node.members,
    });
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _visitChildren(node, {
      'name': node.name,
      'expression': node.expression,
    });
    super.visitNamedExpression(node);
  }

  @override
  void visitNativeClause(NativeClause node) {
    _visitChildren(node, {
      'name': node.name,
    });
    super.visitNativeClause(node);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _visitChildren(node, {});
    super.visitNativeFunctionBody(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _visitChildren(node, {});
    super.visitNullLiteral(node);
  }

  @override
  void visitOnClause(OnClause node) {
    _visitChildren(node, {
      'superclassConstraints': node.superclassConstraints,
    });
    super.visitOnClause(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'uri': node.uri,
    });
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'libraryName': node.libraryName,
      'uri': node.uri,
    });
    super.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _visitChildren(node, {
      'operand': node.operand,
      'operator': node.operator,
    });
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _visitChildren(node, {
      'prefix': node.prefix,
      'identifier': node.identifier,
    });
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _visitChildren(node, {
      'operator': node.operator,
      'operand': node.operand,
    });
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _visitChildren(node, {
      'target': node.target,
      'propertyName': node.propertyName,
    });
    super.visitPropertyAccess(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _visitChildren(node, {
      'constructorName': node.constructorName,
      'argumentList': node.argumentList,
    });
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _visitChildren(node, {});
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitReturnStatement(node);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _visitChildren(node, {});
    super.visitScriptTag(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _visitChildren(node, {
      'typeArguments': node.typeArguments,
      'elements': node.elements,
    });
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _visitChildren(node, {
      'shownNames': node.shownNames,
    });
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'covariantKeyword': node.covariantKeyword,
      'keyword': node.keyword,
      'type': node.type,
      'identifier': node.identifier,
    });
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _visitChildren(node, {});
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitSpreadElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitChildren(node, {
      'elements': node.elements,
    });
    super.visitStringInterpolation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _visitChildren(node, {
      'constructorName': node.constructorName,
      'argumentList': node.argumentList,
    });
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _visitChildren(node, {});
    super.visitSuperExpression(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _visitChildren(node, {
      'labels': node.labels,
      'expression': node.expression,
      'statements': node.statements,
    });
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _visitChildren(node, {
      'statements': node.statements,
    });
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _visitChildren(node, {
      'expression': node.expression,
      'members': node.members,
    });
    super.visitSwitchStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _visitChildren(node, {});
    super.visitSymbolLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _visitChildren(node, {});
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _visitChildren(node, {
      'expression': node.expression,
    });
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'externalKeyword': node.externalKeyword,
      'variables': node.variables,
    });
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _visitChildren(node, {
      'body': node.body,
      'catchClauses': node.catchClauses,
      'finallyBlock': node.finallyBlock,
    });
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _visitChildren(node, {
      'arguments': node.arguments,
    });
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeName(TypeName node) {
    _visitChildren(node, {
      'name': node.name,
      'typeArguments': node.typeArguments,
      'question': node.question,
    });
    super.visitTypeName(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _visitChildren(node, {
      'name': node.name,
      'bound': node.bound,
    });
    super.visitTypeParameter(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _visitChildren(node, {'typeParameters': node.typeParameters});
    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'name': node.name,
      'initializer': node.initializer,
    });
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _visitChildren(node, {
      'documentationComment': node.documentationComment,
      'metadata': node.metadata,
      'type': node.type,
      'variables': node.variables,
    });
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitChildren(node, {
      'variables': node.variables,
    });
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _visitChildren(node, {
      'condition': node.condition,
      'body': node.body,
    });
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    _visitChildren(node, {
      'mixinTypes': node.mixinTypes,
    });
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _visitChildren(node, {
      'star': node.star,
      'expression': node.expression,
    });
    super.visitYieldStatement(node);
  }

  String _className(AstNode node) {
    var className = node.runtimeType.toString();
    if (className.endsWith('Impl')) {
      className = className.substring(0, className.length - 4);
    }
    return className;
  }

  /// Visit the children of a node. The node is an instance of the class named
  /// [parentClass] and the children are in the [childMap], keyed by the name of
  /// the child property.
  void _visitChildren(AstNode node, Map<String, Object> childMap) {
    var nodeClassName = _className(node);

    data.recordNodeClass(nodeClassName);

    var parent = node.parent;
    if (parent != null) {
      data.recordParentClass(nodeClassName, _className(parent));
    }

    var visitChildren = <AstNode>[];
    for (var entry in childMap.entries) {
      var property = entry.key;
      var child = entry.value;
      if (child is AstNode) {
        data.recordNode(nodeClassName, property, child);
        visitChildren.add(child);
      } else if (child is NodeList) {
        data.recordNodeList(nodeClassName, property, child);
        visitChildren.addAll(child);
      } else if (child is Token || child == null) {
        data.recordToken(nodeClassName, property, child);
      } else {
        throw ArgumentError('Unknown class of child: ${child.runtimeType}');
      }
    }
    // Validate that all AST node children were included in the [childMap].
    for (var entity in node.childEntities) {
      if (entity is AstNode && !visitChildren.contains(entity)) {
        data.missedChildren.add('$nodeClassName (${entity.runtimeType})');
      }
    }
  }
}

/// An object used to compute metrics for a single file or directory.
class CodeShapeMetricsComputer {
  /// The metrics data that was computed.
  final CodeShapeData data = CodeShapeData();

  /// Initialize a newly created metrics computer that can compute the metrics
  /// in one or more files and directories.
  CodeShapeMetricsComputer();

  /// Compute the metrics for the file(s) in the [rootPath].
  Future<void> compute(String rootPath) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = CodeShapeDataCollector(data);
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot, collector);
    }
  }

  /// Write a report of the metrics that were computed to the [sink].
  void writeResults(StringSink sink) {
    // Write error information.
    _writeMissedChildren(sink);

    // Write normal information.
    _writeChildData(sink);
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector]. Include additional details in the
  /// output if [verbose] is `true`.
  Future<void> _computeInContext(
      ContextRoot root, CodeShapeDataCollector collector) async {
    // Create a new collection to avoid consuming large quantities of memory.
    final collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (AnalysisEngine.isDartFileName(filePath)) {
        try {
          var resolvedUnitResult =
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

  /// Convert the contents of a single [map] into the values for each row in the
  /// column occupied by the map.
  List<String> _convertMap<T extends Object>(String context, Map<T, int> map) {
    var columns = <String>[];
    if (map == null) {
      return columns;
    }
    var entries = map.entries.toList()
      ..sort((first, second) {
        return second.value.compareTo(first.value);
      });
    var total = 0;
    for (var entry in entries) {
      total += entry.value;
    }
    columns.add('$context ($total)');
    for (var entry in entries) {
      var value = entry.value;
      var percent = _formatPercent(value, total);
      columns.add('  $percent%: ${entry.key} ($value)');
    }
    return columns;
  }

  /// Compute and format a percentage for the fraction [value] / [total].
  String _formatPercent(int value, int total) {
    var percent = ((value / total) * 100).toStringAsFixed(1);
    if (percent.length == 3) {
      percent = '  $percent';
    } else if (percent.length == 4) {
      percent = ' $percent';
    }
    return percent;
  }

  /// Write the child data to the [sink].
  void _writeChildData(StringSink sink) {
    sink.writeln('');
    sink.writeln('Child data');

    // TODO(brianwilkerson) This misses all node kinds for which zero instances
    //  were visited.
    var nodeData = data.nodeData;
    var parentData = data.parentData;
    var childData = data.childData;
    var lengthData = data.lengthData;
    var nodeClasses = nodeData.keys.toList()..sort();
    for (var nodeClass in nodeClasses) {
      var count = nodeData[nodeClass];
      sink.writeln();
      sink.writeln('$nodeClass ($count)');

      var parentMap = parentData[nodeClass];
      if (parentMap != null) {
        var lines = _convertMap('parent', parentMap);
        for (var line in lines) {
          sink.writeln('  $line');
        }
      }

      var childMap = childData[nodeClass] ?? {};
      var listMap = lengthData[nodeClass] ?? {};
      var childNames = {...childMap.keys, ...listMap.keys}.toList()..sort();
      for (var childName in childNames) {
        var listLengths = listMap[childName];
        if (listLengths != null) {
          var lines = _convertMap(childName, listLengths);
          for (var line in lines) {
            sink.writeln('  $line');
          }
        }

        var childTypes = childMap[childName];
        if (childTypes != null) {
          var lines = _convertMap(childName, childTypes);
          for (var line in lines) {
            sink.writeln('  $line');
          }
        }
      }
    }
  }

  /// Write a report of the metrics that were computed to the [sink].
  void _writeMissedChildren(StringSink sink) {
    var missedChildren = data.missedChildren;
    if (missedChildren.isNotEmpty) {
      sink.writeln();
      sink.writeln('Missed children in the following classes:');
      for (var nodeClass in missedChildren.toList()..sort()) {
        sink.writeln('  $nodeClass');
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
