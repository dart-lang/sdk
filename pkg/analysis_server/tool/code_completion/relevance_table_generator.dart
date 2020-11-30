// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/protocol_server.dart' show ElementKind;
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, Element, LibraryElement;
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';

/// Compute metrics to determine whether they should be used to compute a
/// relevance score for completion suggestions.
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var rootPath = result.rest[0];
    print('Analyzing root: "$rootPath"');

    var provider = PhysicalResourceProvider.INSTANCE;
    var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
    var generatedFilePath = provider.pathContext.join(
        packageRoot,
        'analysis_server',
        'lib',
        'src',
        'services',
        'completion',
        'dart',
        'relevance_tables.g.dart');
    var generatedFile = provider.getFile(generatedFilePath);

    var computer = RelevanceMetricsComputer();
    var stopwatch = Stopwatch();
    stopwatch.start();
    await computer.compute(rootPath, verbose: result['verbose']);
    var buffer = StringBuffer();
    var writer = RelevanceTableWriter(buffer);
    writer.write(computer.data);
    generatedFile.writeAsStringSync(buffer.toString());
    DartFormat.formatFile(io.File(generatedFile.path));
    stopwatch.stop();

    var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
    print('Tables generated in $duration');
  }
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  var parser = ArgParser();
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Print this help message.',
  );
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Print additional information about the analysis',
    negatable: false,
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart relevance_table_generator.dart [options] packagePath');
  print('');
  print('Generate the tables used to compute the values of certain features.');
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
  if (!PhysicalResourceProvider.INSTANCE.pathContext.isAbsolute(rootPath)) {
    printUsage(parser, error: 'The package path must be an absolute path.');
    return false;
  }
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// An object that records the data used to compute the tables.
class RelevanceData {
  /// A table mapping element kinds and keywords to counts by context.
  Map<String, Map<_Kind, int>> byKind = {};

  /// Initialize a newly created set of relevance data to be empty.
  RelevanceData();

  /// Add the data from the given relevance [data] to this set of data.
  void addDataFrom(RelevanceData data) {
    _addToMap(byKind, data.byKind);
  }

  /// Record that an element of the given [kind] was found in the given
  /// [context].
  void recordElementKind(String context, ElementKind kind) {
    var contextMap = byKind.putIfAbsent(context, () => {});
    var key = _ElementKind(kind);
    contextMap[key] = (contextMap[key] ?? 0) + 1;
  }

  /// Record that the given [keyword] was found in the given [context].
  void recordKeyword(String context, Keyword keyword) {
    var contextMap = byKind.putIfAbsent(context, () => {});
    var key = _Keyword(keyword);
    contextMap[key] = (contextMap[key] ?? 0) + 1;
  }

  /// Add the data in the [source] map to the [target] map.
  void _addToMap<K>(Map<K, Map<K, int>> target, Map<K, Map<K, int>> source) {
    for (var outerEntry in source.entries) {
      var innerTarget = target.putIfAbsent(outerEntry.key, () => {});
      for (var innerEntry in outerEntry.value.entries) {
        var innerKey = innerEntry.key;
        innerTarget[innerKey] = (innerTarget[innerKey] ?? 0) + innerEntry.value;
      }
    }
  }
}

/// An object that visits a compilation unit in order to record the data used to
/// compute the metrics.
class RelevanceDataCollector extends RecursiveAstVisitor<void> {
  static const List<Keyword> declarationKeywords = [
    Keyword.MIXIN,
    Keyword.TYPEDEF
  ];

  static const List<Keyword> directiveKeywords = [
    Keyword.EXPORT,
    Keyword.IMPORT,
    Keyword.LIBRARY,
    Keyword.PART
  ];

  static const List<Keyword> exportKeywords = [
    Keyword.AS,
    Keyword.HIDE,
    Keyword.SHOW
  ];

  static const List<Keyword> expressionKeywords = [
    Keyword.AWAIT,
    Keyword.SUPER
  ];

  static const List<Keyword> functionBodyKeywords = [
    Keyword.ASYNC,
    Keyword.SYNC
  ];

  static const List<Keyword> importKeywords = [
    Keyword.AS,
    Keyword.HIDE,
    Keyword.SHOW
  ];

  static const List<Keyword> memberKeywords = [
    Keyword.FACTORY,
    Keyword.GET,
    Keyword.OPERATOR,
    Keyword.SET,
    Keyword.STATIC
  ];

  static const List<Keyword> noKeywords = [];

  static const List<Keyword> statementKeywords = [Keyword.AWAIT, Keyword.YIELD];

  /// The relevance data being collected.
  final RelevanceData data;

  /// The compilation unit in which data is currently being collected.
  CompilationUnit unit;

  InheritanceManager3 inheritanceManager = InheritanceManager3();

  /// The library containing the compilation unit being visited.
  LibraryElement enclosingLibrary;

  /// The type provider associated with the current compilation unit.
  TypeProvider typeProvider;

  /// The type system associated with the current compilation unit.
  TypeSystem typeSystem;

  /// The object used to compute the values of features.
  FeatureComputer featureComputer;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  RelevanceDataCollector(this.data);

  /// Initialize this collector prior to visiting the unit in the [result].
  void initializeFrom(ResolvedUnitResult result) {
    unit = result.unit;
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // There are no completions.
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _recordDataForNode('Annotation_name', node.name);
    super.visitAnnotation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    var context = _argumentListContext(node);
    for (var argument in node.arguments) {
      var realArgument = argument;
      var argumentKind = 'unnamed';
      if (argument is NamedExpression) {
        realArgument = argument.expression;
        argumentKind = 'named';
      }
      _recordDataForNode('ArgumentList_${context}_$argumentKind', realArgument,
          allowedKeywords: expressionKeywords);
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    _recordDataForNode('AsExpression_type', node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _recordDataForNode('AssertInitializer_condition', node.condition,
        allowedKeywords: expressionKeywords);
    _recordDataForNode('AssertInitializer_message', node.message,
        allowedKeywords: expressionKeywords);
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _recordDataForNode('AssertStatement_condition', node.condition,
        allowedKeywords: expressionKeywords);
    _recordDataForNode('AssertStatement_message', node.message,
        allowedKeywords: expressionKeywords);
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _recordDataForNode('AssignmentExpression_rightHandSide', node.rightHandSide,
        allowedKeywords: expressionKeywords);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _recordDataForNode('AwaitExpression_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _recordDataForNode(
        'BinaryExpression_${node.operator}_rightOperand', node.rightOperand,
        allowedKeywords: expressionKeywords);
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    for (var statement in node.statements) {
      // Function declaration statements that have no return type begin with an
      // identifier but don't have an element kind associated with the
      // identifier.
      _recordDataForNode('Block_statement', statement,
          allowedKeywords: statementKeywords);
    }
    super.visitBlock(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _recordKeyword('BlockFunctionBody_start', node,
        allowedKeywords: functionBodyKeywords);
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _recordKeyword('BooleanLiteral_start', node);
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
      _recordDataForNode('CascadeExpression_cascadeSection', cascade);
    }
    super.visitCascadeExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _recordDataForNode('CatchClause_exceptionType', node.exceptionType);
    super.visitCatchClause(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var context = 'name';
    if (node.extendsClause != null) {
      _recordKeyword('ClassDeclaration_$context', node.extendsClause,
          allowedKeywords: [Keyword.EXTENDS]);
      context = 'extends';
    }
    if (node.withClause != null) {
      _recordKeyword('ClassDeclaration_$context', node.withClause);
      context = 'with';
    }
    _recordKeyword('ClassDeclaration_$context', node.implementsClause,
        allowedKeywords: [Keyword.IMPLEMENTS]);

    for (var member in node.members) {
      _recordDataForNode('ClassDeclaration_member', member,
          allowedKeywords: memberKeywords);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _recordDataForNode('ClassTypeAlias_superclass', node.superclass);
    var context = 'superclass';
    if (node.withClause != null) {
      _recordKeyword('ClassTypeAlias_$context', node.withClause);
      context = 'with';
    }
    _recordKeyword('ClassTypeAlias_$context', node.implementsClause);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    // There are no completions.
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _recordDataForNode('CommentReference_identifier', node.identifier);
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    enclosingLibrary = node.declaredElement.library;
    typeProvider = enclosingLibrary.typeProvider;
    typeSystem = enclosingLibrary.typeSystem;
    inheritanceManager = InheritanceManager3();
    featureComputer = FeatureComputer(typeSystem, typeProvider);

    for (var directive in node.directives) {
      _recordKeyword('CompilationUnit_directive', directive,
          allowedKeywords: directiveKeywords);
    }
    for (var declaration in node.declarations) {
      _recordDataForNode('CompilationUnit_declaration', declaration,
          allowedKeywords: declarationKeywords);
    }
    super.visitCompilationUnit(node);

    featureComputer = null;
    inheritanceManager = null;
    typeSystem = null;
    typeProvider = null;
    enclosingLibrary = null;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _recordDataForNode(
        'ConditionalExpression_thenExpression', node.thenExpression,
        allowedKeywords: expressionKeywords);
    _recordDataForNode(
        'ConditionalExpression_elseExpression', node.elseExpression,
        allowedKeywords: expressionKeywords);
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    // There are no completions.
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _recordDataForNode('ConstructorDeclaration_returnType', node.returnType);
    for (var initializer in node.initializers) {
      _recordDataForNode('ConstructorDeclaration_initializer', initializer);
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _recordDataForNode(
        'ConstructorFieldInitializer_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // The token following the `.` is always the name of a constructor.
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
    _recordDataForNode('DefaultFormalParameter_defaultValue', node.defaultValue,
        allowedKeywords: expressionKeywords);
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _recordDataForNode('DoStatement_body', node.body,
        allowedKeywords: statementKeywords);
    _recordDataForNode('DoStatement_condition', node.condition,
        allowedKeywords: expressionKeywords);
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
    var context = 'uri';
    if (node.configurations.isNotEmpty) {
      _recordKeyword('ImportDirective_$context', node.configurations[0],
          allowedKeywords: exportKeywords);
      context = 'configurations';
    }
    if (node.combinators.isNotEmpty) {
      _recordKeyword('ImportDirective_$context', node.combinators[0],
          allowedKeywords: exportKeywords);
    }
    for (var combinator in node.combinators) {
      _recordKeyword('ImportDirective_combinator', combinator,
          allowedKeywords: exportKeywords);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _recordKeyword('ExpressionFunctionBody_start', node,
        allowedKeywords: functionBodyKeywords);
    _recordDataForNode('ExpressionFunctionBody_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _recordDataForNode('ExpressionStatement_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _recordDataForNode('ExtendsClause_superclass', node.superclass);
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _recordDataForNode('ExtensionDeclaration_extendedType', node.extendedType);
    for (var member in node.members) {
      _recordDataForNode('ExtensionDeclaration_member', member,
          allowedKeywords: memberKeywords);
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
    _recordDataForNode('FieldDeclaration_fields', node.fields);
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
        'ForEachPartsWithDeclaration_loopVariable', node.loopVariable);
    _recordDataForNode('ForEachPartsWithDeclaration_iterable', node.iterable,
        allowedKeywords: expressionKeywords);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _recordDataForNode(
        'ForEachPartsWithIdentifier_identifier', node.identifier);
    _recordDataForNode('ForEachPartsWithIdentifier_iterable', node.iterable,
        allowedKeywords: expressionKeywords);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForElement(ForElement node) {
    _recordDataForNode('ForElement_forLoopParts', node.forLoopParts);
    _recordDataForNode('ForElement_body', node.body);
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      _recordDataForNode('FormalParameterList_parameter', parameter,
          allowedKeywords: [Keyword.COVARIANT]);
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _recordDataForNode('ForParts_condition', node.condition,
        allowedKeywords: expressionKeywords);
    for (var updater in node.updaters) {
      _recordDataForNode('ForParts_updater', updater,
          allowedKeywords: expressionKeywords);
    }
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _recordDataForNode('ForParts_condition', node.condition,
        allowedKeywords: expressionKeywords);
    for (var updater in node.updaters) {
      _recordDataForNode('ForParts_updater', updater,
          allowedKeywords: expressionKeywords);
    }
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _recordDataForNode('ForStatement_forLoopParts', node.forLoopParts);
    _recordDataForNode('ForStatement_body', node.body,
        allowedKeywords: statementKeywords);
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _recordDataForNode('FunctionDeclaration_returnType', node.returnType);
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
    _recordDataForNode('GenericTypeAlias_functionType', node.functionType,
        allowedKeywords: [Keyword.FUNCTION]);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    for (var hiddenName in node.hiddenNames) {
      _recordDataForNode('HideCombinator_hiddenName', hiddenName);
    }
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _recordDataForNode('IfElement_condition', node.condition,
        allowedKeywords: expressionKeywords);
    _recordDataForNode('IfElement_thenElement', node.thenElement);
    _recordDataForNode('IfElement_elseElement', node.elseElement);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _recordDataForNode('IfStatement_condition', node.condition,
        allowedKeywords: expressionKeywords);
    _recordDataForNode('IfStatement_thenStatement', node.thenStatement,
        allowedKeywords: statementKeywords);
    _recordDataForNode('IfStatement_elseStatement', node.elseStatement,
        allowedKeywords: statementKeywords);
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    // At the start of each type name.
    for (var typeName in node.interfaces) {
      _recordDataForNode('ImplementsClause_interface', typeName);
    }
    super.visitImplementsClause(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var context = 'uri';
    if (node.deferredKeyword != null) {
      data.recordKeyword('ImportDirective_$context', node.deferredKeyword.type);
      context = 'deferred';
    }
    if (node.asKeyword != null) {
      data.recordKeyword('ImportDirective_$context', node.asKeyword.type);
      context = 'prefix';
    }
    if (node.configurations.isNotEmpty) {
      _recordKeyword('ImportDirective_$context', node.configurations[0],
          allowedKeywords: importKeywords);
      context = 'configurations';
    }
    if (node.combinators.isNotEmpty) {
      _recordKeyword('ImportDirective_$context', node.combinators[0],
          allowedKeywords: importKeywords);
    }
    for (var combinator in node.combinators) {
      _recordKeyword('ImportDirective_combinator', combinator,
          allowedKeywords: importKeywords);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _recordDataForNode('IndexExpression_index', node.index,
        allowedKeywords: expressionKeywords);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordDataForNode(
        'InstanceCreationExpression_constructorName', node.constructorName);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // There are no completions.
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    // TODO(brianwilkerson) Consider splitting this based on whether the
    //  expression is a simple identifier ('$') or a full expression ('${').
    _recordDataForNode('InterpolationExpression_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    // There are no completions.
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _recordDataForNode('IsExpression_type', node.type);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    // There are no completions.
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _recordDataForNode('LabeledStatement_statement', node.statement,
        allowedKeywords: statementKeywords);
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
      _recordDataForNode('ListLiteral_element', element,
          allowedKeywords: expressionKeywords);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _recordDataForNode('MapLiteralEntry_value', node.value,
        allowedKeywords: expressionKeywords);
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _recordDataForNode('MethodDeclaration_returnType', node.returnType);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // There are no completions.
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var context = 'name';
    if (node.onClause != null) {
      _recordKeyword('MixinDeclaration_$context', node.onClause,
          allowedKeywords: [Keyword.ON]);
      context = 'on';
    }
    _recordKeyword('MixinDeclaration_$context', node.implementsClause,
        allowedKeywords: [Keyword.IMPLEMENTS]);

    for (var member in node.members) {
      _recordDataForNode('MixinDeclaration_member', member,
          allowedKeywords: memberKeywords);
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
      _recordDataForNode('OnClause_superclassConstraint', constraint);
    }
    super.visitOnClause(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _recordDataForNode('ParenthesizedExpression_expression', node.expression,
        allowedKeywords: expressionKeywords);
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
    // There are no completions.
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // There are no completions.
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordDataForNode(
        'PrefixExpression_${node.operator}_operand', node.operand,
        allowedKeywords: expressionKeywords);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _recordDataForNode('PropertyAccess_propertyName', node.propertyName);
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
    _recordDataForNode('ReturnStatement_expression', node.expression,
        allowedKeywords: expressionKeywords);
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
      _recordDataForNode('SetOrMapLiteral_element', element,
          allowedKeywords: expressionKeywords);
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    for (var name in node.shownNames) {
      _recordDataForNode('ShowCombinator_shownName', name);
    }
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    // There are no completions.
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // There are no completions.
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _recordDataForNode('SpreadElement_expression', node.expression,
        allowedKeywords: expressionKeywords);
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
    _recordDataForNode('SwitchCase_expression', node.expression,
        allowedKeywords: expressionKeywords);
    for (var statement in node.statements) {
      _recordDataForNode('SwitchMember_statement', statement,
          allowedKeywords: statementKeywords);
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    for (var statement in node.statements) {
      _recordDataForNode('SwitchMember_statement', statement,
          allowedKeywords: statementKeywords);
    }
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _recordDataForNode('SwitchStatement_expression', node.expression,
        allowedKeywords: expressionKeywords);
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
    _recordDataForNode('ThrowExpression_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // There are no completions.
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    var context = 'try';
    for (var clause in node.catchClauses) {
      _recordKeyword('TryStatement_$context', clause,
          allowedKeywords: [Keyword.ON]);
      context = 'catch';
    }
    if (node.finallyKeyword != null) {
      data.recordKeyword('TryStatement_$context', node.finallyKeyword.type);
    }
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    for (var typeArgument in node.arguments) {
      _recordDataForNode('TypeArgumentList_argument', typeArgument);
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
      _recordDataForNode('TypeParameter_bound', node.bound);
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
    var keywords = node.parent.parent is FieldDeclaration
        ? [Keyword.COVARIANT, ...expressionKeywords]
        : expressionKeywords;
    _recordDataForNode('VariableDeclaration_initializer', node.initializer,
        allowedKeywords: keywords);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _recordDataForNode('VariableDeclarationList_type', node.type);
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    // There are no completions.
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _recordDataForNode('WhileStatement_condition', node.condition,
        allowedKeywords: expressionKeywords);
    _recordDataForNode('WhileStatement_body', node.body,
        allowedKeywords: statementKeywords);
    super.visitWhileStatement(node);
  }

  @override
  void visitWithClause(WithClause node) {
    for (var typeName in node.mixinTypes) {
      _recordDataForNode('WithClause_mixinType', typeName);
    }
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _recordDataForNode('YieldStatement_expression', node.expression,
        allowedKeywords: expressionKeywords);
    super.visitYieldStatement(node);
  }

  /// Return the context in which the [node] occurs. The [node] is expected to
  /// be the parent of the argument expression.
  String _argumentListContext(AstNode node) {
    if (node is ArgumentList) {
      var parent = node.parent;
      if (parent is Annotation) {
        return 'annotation';
      } else if (parent is ExtensionOverride) {
        return 'extensionOverride';
      } else if (parent is FunctionExpressionInvocation) {
        return 'function';
      } else if (parent is InstanceCreationExpression) {
        if (Flutter.instance.isWidgetType(parent.staticType)) {
          return 'widgetConstructor';
        }
        return 'constructor';
      } else if (parent is MethodInvocation) {
        return 'method';
      } else if (parent is RedirectingConstructorInvocation) {
        return 'constructorRedirect';
      } else if (parent is SuperConstructorInvocation) {
        return 'constructorRedirect';
      }
    } else if (node is AssignmentExpression ||
        node is BinaryExpression ||
        node is PrefixExpression ||
        node is PostfixExpression) {
      return 'operator';
    } else if (node is IndexExpression) {
      return 'index';
    }
    throw ArgumentError(
        'Unknown parent of ${node.runtimeType}: ${node.parent.runtimeType}');
  }

  /// Return the first child of the [node] that is neither a comment nor an
  /// annotation.
  SyntacticEntity _firstChild(AstNode node) {
    var children = node.childEntities.toList();
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      if (child is! Comment && child is! Annotation) {
        return child;
      }
    }
    return null;
  }

  /// Return the element associated with the left-most identifier that is a
  /// child of the [node].
  Element _leftMostElement(AstNode node) =>
      _leftMostIdentifier(node)?.staticElement;

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
    if (node is InstanceCreationExpression) {
      return featureComputer
          .computeElementKind(node.constructorName.staticElement);
    }
    var element = _leftMostElement(node);
    if (element == null) {
      return null;
    }
    if (element is ClassElement) {
      var parent = node.parent;
      if (parent is Annotation && parent.arguments != null) {
        element = parent.element;
      }
    }
    return featureComputer.computeElementKind(element);
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

  /// Record information about the given [node] occurring in the given
  /// [context].
  void _recordDataForNode(String context, AstNode node,
      {List<Keyword> allowedKeywords = noKeywords}) {
    _recordElementKind(context, node);
    _recordKeyword(context, node, allowedKeywords: allowedKeywords);
  }

  /// Record the element kind of the element associated with the left-most
  /// identifier that is a child of the [node] in the given [context].
  void _recordElementKind(String context, AstNode node) {
    if (node != null) {
      var kind = _leftMostKind(node);
      if (kind != null) {
        data.recordElementKind(context, kind);
        if (node is Expression) {
          data.recordElementKind('Expression', kind);
        } else if (node is Statement) {
          data.recordElementKind('Statement', kind);
        }
      }
    }
  }

  /// If the left-most token of the [node] is a keyword, then record that it
  /// occurred in the given [context].
  void _recordKeyword(String context, AstNode node,
      {List<Keyword> allowedKeywords = noKeywords}) {
    if (node != null) {
      var token = _leftMostToken(node);
      if (token.isKeyword) {
        var keyword = token.type;
        if (keyword == Keyword.NEW) {
          // We don't suggest `new`, so we don't care about the frequency with
          // which it is used.
          return;
        } else if (token.keyword.isBuiltInOrPseudo &&
            !allowedKeywords.contains(token.keyword)) {
          // These keywords can be used as identifiers, so determine whether
          // it is being used as a keyword or an identifier.
          return;
        }
        data.recordKeyword(context, keyword);
      }
    }
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
  /// If [corpus] is true, treat rootPath as a container of packages, creating
  /// a new context collection for each subdirectory.
  Future<void> compute(String rootPath, {@required bool verbose}) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = RelevanceDataCollector(data);
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot, collector, verbose: verbose);
    }
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector]. Include additional details in the
  /// output if [verbose] is `true`.
  Future<void> _computeInContext(
      ContextRoot root, RelevanceDataCollector collector,
      {@required bool verbose}) async {
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
          if (resolvedUnitResult == null) {
            print('File $filePath skipped because resolved unit was null.');
            if (verbose) {
              print('');
            }
            continue;
          } else if (resolvedUnitResult.state != ResultState.VALID) {
            print('File $filePath skipped because it could not be analyzed.');
            if (verbose) {
              print('');
            }
            continue;
          } else if (hasError(resolvedUnitResult)) {
            if (verbose) {
              print('File $filePath skipped due to errors:');
              for (var error in resolvedUnitResult.errors
                  .where((e) => e.severity == Severity.error)) {
                print('  ${error.toString()}');
              }
              print('');
            } else {
              print('File $filePath skipped due to analysis errors.');
            }
            continue;
          }

          collector.initializeFrom(resolvedUnitResult);
          resolvedUnitResult.unit.accept(collector);
        } catch (exception, stacktrace) {
          print('Exception caught analyzing: "$filePath"');
          print(exception);
          print(stacktrace);
        }
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

/// A class used to write relevance data as a set of tables in a generated Dart
/// file.
class RelevanceTableWriter {
  final StringSink sink;

  RelevanceTableWriter(this.sink);

  void write(RelevanceData data) {
    writeFileHeader();
    writeElementKindTable(data);
    writeKeywordTable(data);
  }

  void writeElementKindTable(RelevanceData data) {
    sink.writeln();
    sink.write('''
/// A table keyed by completion location and element kind whose values are the
/// ranges of the relevance of those element kinds in those locations.
const elementKindRelevance = {
''');

    var byKind = data.byKind;
    var completionLocations = byKind.keys.toList()..sort();
    for (var completionLocation in completionLocations) {
      var counts = byKind[completionLocation];
      if (_hasElementKind(counts)) {
        var totalCount = _totalCount(counts);
        // TODO(brianwilkerson) If two element kinds have the same count they
        //  ought to have the same probability. This doesn't correctly do that.
        var entries = counts.entries.toList()
          ..sort((first, second) => first.value.compareTo(second.value));

        sink.write("  '");
        sink.write(completionLocation);
        sink.writeln("': {");
        var cumulativeCount = 0;
        var lowerBound = 0.0;
        for (var entry in entries) {
          var kind = entry.key;
          cumulativeCount += entry.value;
          var upperBound = cumulativeCount / totalCount;
          if (kind is _ElementKind) {
            sink.write('    ElementKind.');
            sink.write(kind.elementKind.name);
            sink.write(': ProbabilityRange(lower: ');
            sink.write(lowerBound.toStringAsFixed(3));
            sink.write(', upper: ');
            sink.write(upperBound.toStringAsFixed(3));
            sink.writeln('),');
          }
          lowerBound = upperBound;
        }
        sink.writeln('  },');
      }
    }
    sink.writeln('};');
  }

  void writeFileHeader() {
    sink.write('''
// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/completion_metrics/relevance_table_generator.dart",
// passing it the location of a corpus of code that is large enough for the
// computed values to be statistically meaningful.

import 'package:analysis_server/src/services/completion/dart/probability_range.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
''');
  }

  void writeKeywordTable(RelevanceData data) {
    sink.writeln();
    sink.write('''
/// A table keyed by completion location and keyword whose values are the
/// ranges of the relevance of those keywords in those locations.
const keywordRelevance = {
''');

    var byKind = data.byKind;
    var completionLocations = byKind.keys.toList()..sort();
    for (var completionLocation in completionLocations) {
      var counts = byKind[completionLocation];
      if (_hasKeyword(counts)) {
        var totalCount = _totalCount(counts);
        // TODO(brianwilkerson) If two keywords have the same count they ought to
        //  have the same probability. This doesn't correctly do that.
        var entries = counts.entries.toList()
          ..sort((first, second) => first.value.compareTo(second.value));

        sink.write("  '");
        sink.write(completionLocation);
        sink.writeln("': {");
        var cumulativeCount = 0;
        var lowerBound = 0.0;
        for (var entry in entries) {
          var kind = entry.key;
          cumulativeCount += entry.value;
          var upperBound = cumulativeCount / totalCount;
          if (kind is _Keyword) {
            sink.write("    '");
            sink.write(kind.keyword.lexeme);
            sink.write("': ProbabilityRange(lower: ");
            sink.write(lowerBound.toStringAsFixed(3));
            sink.write(', upper: ');
            sink.write(upperBound.toStringAsFixed(3));
            sink.writeln('),');
          }
          lowerBound = upperBound;
        }
        sink.writeln('  },');
      }
    }
    sink.writeln('};');
  }

  /// Return `true` if the table of [counts] contains at least one key that is
  /// an element kind.
  bool _hasElementKind(Map<_Kind, int> counts) {
    for (var kind in counts.keys) {
      if (kind is _ElementKind) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if the table of [counts] contains at least one key that is a
  /// keyword.
  bool _hasKeyword(Map<_Kind, int> counts) {
    for (var kind in counts.keys) {
      if (kind is _Keyword) {
        return true;
      }
    }
    return false;
  }

  /// Return the total of the counts in the given table of [counts].
  int _totalCount(Map<_Kind, int> counts) {
    return counts.values
        .fold(0, (previousValue, value) => previousValue + value);
  }
}

/// A wrapper for an element kind to allow keywords and element kinds to be used
/// as keys in a single table.
class _ElementKind extends _Kind {
  static final Map<ElementKind, _ElementKind> instances = {};

  final ElementKind elementKind;

  factory _ElementKind(ElementKind elementKind) =>
      instances.putIfAbsent(elementKind, () => _ElementKind._(elementKind));

  _ElementKind._(this.elementKind);
}

/// A wrapper for a keyword to allow keywords and element kinds to be used as
/// keys in a single table.
class _Keyword extends _Kind {
  static final Map<Keyword, _Keyword> instances = {};

  final Keyword keyword;

  factory _Keyword(Keyword keyword) =>
      instances.putIfAbsent(keyword, () => _Keyword._(keyword));

  _Keyword._(this.keyword);
}

/// A superclass for [_ElementKind] and [_Keyword] to allow keywords and element
/// kinds to be used as keys in a single table.
class _Kind {}
