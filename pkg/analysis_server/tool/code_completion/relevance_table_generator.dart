// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/protocol_server.dart' show ElementKind;
import 'package:analysis_server/src/services/completion/dart/completion_location.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show Element, InterfaceElement, LibraryElement;
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/diagnostic.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_testing/package_root.dart' as package_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:args/args.dart';

import 'metrics_util.dart';

/// Compute metrics to determine whether they should be used to compute a
/// relevance score for completion suggestions.
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var provider = PhysicalResourceProvider.INSTANCE;
    var packageRoot = provider.pathContext.normalize(package_root.packageRoot);

    void writeRelevanceTable(RelevanceData data, {String suffix = ''}) {
      var generatedFilePath = provider.pathContext.join(
        packageRoot,
        'analysis_server',
        'lib',
        'src',
        'services',
        'completion',
        'dart',
        'relevance_tables$suffix.g.dart',
      );
      var generatedFile = provider.getFile(generatedFilePath);

      var buffer = StringBuffer();
      var writer = RelevanceTableWriter(buffer);
      writer.write(data);
      generatedFile.writeAsStringSync(buffer.toString());
      DartFormat.formatFile(io.File(generatedFile.path));
    }

    if (result.wasParsed('reduceDir')) {
      var data = RelevanceData();
      var dir = provider.getFolder(result['reduceDir'] as String);
      var suffix = result.rest.isNotEmpty ? result.rest[0] : '';
      for (var child in dir.getChildren()) {
        if (child is File) {
          var newData = RelevanceData.fromJson(child.readAsStringSync());
          data.addData(newData);
        }
      }
      writeRelevanceTable(data, suffix: suffix);
      return;
    }

    var rootPath = result.rest[0];
    print('Analyzing root: "$rootPath"');

    var computer = RelevanceMetricsComputer();
    var stopwatch = Stopwatch()..start();
    await computer.compute(rootPath, verbose: result['verbose'] as bool);
    if (result.wasParsed('mapFile')) {
      var mapFile = provider.getFile(result['mapFile'] as String);
      mapFile.writeAsStringSync(computer.data.toJson());
    } else {
      writeRelevanceTable(computer.data);
    }
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
    negatable: false,
  );
  parser.addOption(
    'mapFile',
    help:
        'The absolute path of the file to which the relevance data will be '
        'written. Using this option will prevent the relevance table from '
        'being written.',
  );
  parser.addOption(
    'reduceDir',
    help:
        'The absolute path of the directory from which the relevance data '
        'will be read.',
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
void printUsage(ArgParser parser, {String? error}) {
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
  } else if (result.wasParsed('reduceDir')) {
    return validateDir(parser, result['reduceDir'] as String);
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No package path specified.');
    return false;
  }
  if (result.wasParsed('mapFile')) {
    var mapFilePath = result['mapFile'];
    if (mapFilePath is! String ||
        !PhysicalResourceProvider.INSTANCE.pathContext.isAbsolute(
          mapFilePath,
        )) {
      printUsage(
        parser,
        error: 'The path "$mapFilePath" must be an absolute path.',
      );
      return false;
    }
  }
  return validateDir(parser, result.rest[0]);
}

/// Return `true` if the [dirPath] is an absolute path to a directory that
/// exists.
bool validateDir(ArgParser parser, String dirPath) {
  if (!PhysicalResourceProvider.INSTANCE.pathContext.isAbsolute(dirPath)) {
    printUsage(parser, error: 'The path "$dirPath" must be an absolute path.');
    return false;
  }
  if (!io.Directory(dirPath).existsSync()) {
    printUsage(parser, error: 'The directory "$dirPath" does not exist.');
    return false;
  }
  return true;
}

/// An object that records the data used to compute the tables.
class RelevanceData {
  /// A table mapping element kinds and keywords to counts by context.
  final Map<String, Map<_Kind, int>> _byKind = {};

  /// Initialize a newly created set of relevance data to be empty.
  new();

  /// Initialize a newly created set of relevance data based on the content of
  /// the JSON encoded string.
  new fromJson(String encoded) {
    var map = json.decode(encoded) as Map<String, dynamic>;
    for (var contextEntry in map.entries) {
      var contextMap = _byKind.putIfAbsent(contextEntry.key, () => {});
      for (var kindEntry
          in (contextEntry.value as Map<String, dynamic>).entries) {
        _Kind kind;
        var key = kindEntry.key;
        if (key.startsWith('e')) {
          kind = _ElementKind(ElementKind.values.byName(key.substring(1)));
        } else if (key.startsWith('k')) {
          kind = _Keyword(Keyword.keywords[key.substring(1)]!);
        } else {
          throw StateError('Invalid initial character in unique key "$key"');
        }
        contextMap[kind] = int.parse(kindEntry.value as String);
      }
    }
  }

  /// Add the data from the given relevance [data] to this set of relevance
  /// data.
  void addData(RelevanceData data) {
    for (var contextEntry in data._byKind.entries) {
      var contextMap = _byKind.putIfAbsent(contextEntry.key, () => {});
      for (var kindEntry in contextEntry.value.entries) {
        var kind = kindEntry.key;
        contextMap[kind] = (contextMap[kind] ?? 0) + kindEntry.value;
      }
    }
  }

  /// Record that an element of the given [kind] was found in the given
  /// [context].
  void recordElementKind(String context, ElementKind kind) {
    var contextMap = _byKind.putIfAbsent(context, () => {});
    var key = _ElementKind(kind);
    contextMap[key] = (contextMap[key] ?? 0) + 1;
  }

  /// Record that the given [keyword] was found in the given [context].
  void recordKeyword(String context, Keyword keyword) {
    var contextMap = _byKind.putIfAbsent(context, () => {});
    var key = _Keyword(keyword);
    contextMap[key] = (contextMap[key] ?? 0) + 1;
  }

  /// Convert this data to a JSON encoded format.
  String toJson() {
    var map = <String, Map<String, String>>{};
    for (var contextEntry in _byKind.entries) {
      var kindMap = <String, String>{};
      for (var kindEntry in contextEntry.value.entries) {
        kindMap[kindEntry.key.uniqueKey] = kindEntry.value.toString();
      }
      map[contextEntry.key] = kindMap;
    }
    return json.encode(map);
  }
}

/// An object that visits a compilation unit in order to collect the data used
/// to create the relevance tables.
///
/// Even though this class subclasses [RecursiveAstVisitor], and therefore isn't
/// required to implement every visit method, by convention it does have an
/// implementation of every visit method so that we can record that we have
/// considered the node class and don't need to collect any data at that
/// location. This makes it easier to figure out which node classes need to be
/// considered when updating the tool (because adding new visit methods to
/// [AstVisitor] won't force them to be added to this class).
class RelevanceDataCollector extends RecursiveAstVisitor<void> {
  static const List<Keyword> declarationKeywords = [
    Keyword.MIXIN,
    Keyword.TYPEDEF,
  ];

  static const List<Keyword> directiveKeywords = [
    Keyword.EXPORT,
    Keyword.IMPORT,
    Keyword.LIBRARY,
    Keyword.PART,
  ];

  static const List<Keyword> exportKeywords = [
    Keyword.AS,
    Keyword.HIDE,
    Keyword.SHOW,
  ];

  static const List<Keyword> expressionKeywords = [
    Keyword.AWAIT,
    Keyword.SUPER,
  ];

  static const List<Keyword> functionBodyKeywords = [
    Keyword.ASYNC,
    Keyword.SYNC,
  ];

  static const List<Keyword> importKeywords = [
    Keyword.AS,
    Keyword.HIDE,
    Keyword.SHOW,
  ];

  static const List<Keyword> memberKeywords = [
    Keyword.FACTORY,
    Keyword.GET,
    Keyword.OPERATOR,
    Keyword.SET,
    Keyword.STATIC,
  ];

  static const List<Keyword> patternKeywords = [
    Keyword.CONST,
    Keyword.FALSE,
    Keyword.FINAL,
    Keyword.NULL,
    Keyword.TRUE,
    Keyword.VAR,
  ];

  static const List<Keyword> noKeywords = [];

  static const List<Keyword> statementKeywords = [Keyword.AWAIT, Keyword.YIELD];

  /// The relevance data being collected.
  final RelevanceData data;

  /// The compilation unit in which data is currently being collected.
  late CompilationUnit unit;

  /// A set of the identifier and keyword tokens in the compilation unit being
  /// analyzed.
  ///
  /// Used to find tokens that are not included in the tables but should be.
  final Set<Token> _identifiersAndKeywords = {};

  /// The library containing the compilation unit being visited.
  late LibraryElement enclosingLibrary;

  /// The type provider associated with the current compilation unit.
  late TypeProvider typeProvider;

  /// The type system associated with the current compilation unit.
  late TypeSystem typeSystem;

  /// The object used to compute the values of features.
  late FeatureComputer featureComputer;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  new(this.data);

  /// Initialize this collector prior to visiting the unit in the [result].
  void initializeFrom(ResolvedUnitResult result) {
    _identifiersAndKeywords.clear();
    unit = result.unit;
    var token = unit.beginToken;
    while (!token.isEof) {
      if (token.isKeywordOrIdentifier) {
        _identifiersAndKeywords.add(token);
      }
      token = token.next!;
    }
  }

  void recordKeyword(String context, Token keyword) {
    // TODO(brianwilkerson): Figure out whether this method is needed. It seems
    //  like the keyword should already have been removed from the list. If
    //  that's not the case we should understand why.
    data.recordKeyword(context, keyword.keyword!);
    _identifiersAndKeywords.remove(keyword);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // There are no completions.
    super.visitAdjacentStrings(node);
  }

  @override
  void visitAnnotation(Annotation node) {
    _recordDataForNode(CompletionLocation.annotationName, node.name);
    super.visitAnnotation(node);
  }

  @override
  // ignore: experimental_member_use
  void visitAnonymousBlockBody(AnonymousBlockBody node) {
    // TODO(brianwilkerson): Implement this if the language feature is accepted.
  }

  @override
  // ignore: experimental_member_use
  void visitAnonymousExpressionBody(AnonymousExpressionBody node) {
    // TODO(brianwilkerson): Implement this if the language feature is accepted.
  }

  @override
  // ignore: experimental_member_use
  void visitAnonymousMethodInvocation(AnonymousMethodInvocation node) {
    // TODO(brianwilkerson): Implement this if the language feature is accepted.
  }

  @override
  void visitArgumentList(ArgumentList node) {
    var context = _argumentListContext(node);
    for (var argument in node.arguments) {
      var realArgument = argument.argumentExpression;
      _recordDataForNode(
        CompletionLocation.argumentList(
          context,
          isNamed: argument is NamedArgument,
        ),
        realArgument,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitArgumentList(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    // There is only one token that is valid at this point.
    _unrecorded(node.asOperator);
    _recordDataForNode(CompletionLocation.asExpressionType, node.type);
    super.visitAsExpression(node);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _recordDataForNode(
      CompletionLocation.assertInitializerCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.assertInitializerMessage,
      node.message,
      allowedKeywords: expressionKeywords,
    );
    super.visitAssertInitializer(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _recordDataForNode(
      CompletionLocation.assertStatementCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.assertStatementMessage,
      node.message,
      allowedKeywords: expressionKeywords,
    );
    super.visitAssertStatement(node);
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    _recordElementKind(
      CompletionLocation.assignedVariablePatternIdentifier,
      node,
    );
    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _recordDataForNode(
      CompletionLocation.assignmentExpressionRightHandSide,
      node.rightHandSide,
      allowedKeywords: expressionKeywords,
    );
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _recordDataForNode(
      CompletionLocation.awaitExpressionExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitAwaitExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _recordDataForNode(
      CompletionLocation.binaryExpressionRightOperand(node.operator.lexeme),
      node.rightOperand,
      allowedKeywords: expressionKeywords,
    );
    super.visitBinaryExpression(node);
  }

  @override
  void visitBlock(Block node) {
    for (var statement in node.statements) {
      // Function declaration statements that have no return type begin with an
      // identifier but don't have an element kind associated with the
      // identifier.
      _recordDataForNode(
        CompletionLocation.blockStatement,
        statement,
        allowedKeywords: statementKeywords,
      );
    }
    super.visitBlock(node);
  }

  @override
  void visitBlockClassBody(BlockClassBody node) {
    // Data is not recorded here. It is recorded in the parent
    // (ClassDeclaration, MixinDeclaration, etc.) in order to allow the tables
    // to have different probabilities for the same construct depending on the
    // context.
    super.visitBlockClassBody(node);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _recordKeyword(
      CompletionLocation.blockFunctionBodyStart,
      node,
      allowedKeywords: functionBodyKeywords,
    );
    super.visitBlockFunctionBody(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _recordKeyword(CompletionLocation.booleanLiteralStart, node);
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    // The token following the `break` (if there is one) is always a label.
    if (node.label case var label?) _unrecorded(label.name);
    super.visitBreakStatement(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var cascade in node.cascadeSections) {
      _recordDataForNode(
        CompletionLocation.cascadeExpressionCascadeSection,
        cascade,
      );
    }
    super.visitCascadeExpression(node);
  }

  @override
  void visitCaseClause(CaseClause node) {
    // No other completions are valid here.
    _unrecorded(node.caseKeyword);
    _recordDataForNode(
      CompletionLocation.caseClausePattern,
      node.guardedPattern,
      allowedKeywords: patternKeywords,
    );
    super.visitCaseClause(node);
  }

  @override
  void visitCastPattern(CastPattern node) {
    // There is only one token available at this point.
    _unrecorded(node.asToken);
    _recordDataForNode(CompletionLocation.castPatternType, node.type);
    super.visitCastPattern(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _recordDataForNode(
      CompletionLocation.catchClauseExceptionType,
      node.exceptionType,
    );
    // No other completions are valid here.
    if (node.catchKeyword case var keyword?) _unrecorded(keyword);
    super.visitCatchClause(node);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    // There are no completions.
    _recordDeclaration(node.name);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // If there are modifiers before `class`, then the first will be recorded
    // by the containing node, but the rest will not use the relevance tables
    // because there is a fixed order in which they must appear.
    _unrecordedBetween(
      node.firstTokenAfterCommentAndMetadata,
      node.classKeyword,
    );

    var location = CompletionLocation.classDeclarationName;
    _recordDeclaration(node.namePart.typeName);
    if (node.extendsClause != null) {
      _recordKeyword(
        location,
        node.extendsClause,
        allowedKeywords: [Keyword.EXTENDS],
      );
      location = CompletionLocation.classDeclarationExtends;
    }
    if (node.withClause != null) {
      _recordKeyword(location, node.withClause);
      location = CompletionLocation.classDeclarationWith;
    }
    _recordKeyword(
      location,
      node.implementsClause,
      allowedKeywords: [Keyword.IMPLEMENTS],
    );

    for (var member in node.body.members) {
      _recordDataForNode(
        CompletionLocation.classDeclarationMember,
        member,
        allowedKeywords: memberKeywords,
      );
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _recordDeclaration(node.name);
    _recordDataForNode(
      CompletionLocation.classTypeAliasSuperclass,
      node.superclass,
    );
    _recordKeyword(
      CompletionLocation.classTypeAliasSuperclass,
      node.withClause,
    );
    _recordKeyword(
      CompletionLocation.classTypeAliasWith,
      node.implementsClause,
    );
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    // There are no completions.
    super.visitComment(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _recordDataForNode(
      CompletionLocation.commentReferenceIdentifier,
      node.expression,
    );
    super.visitCommentReference(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    enclosingLibrary = node.declaredFragment!.element;
    typeProvider = enclosingLibrary.typeProvider;
    typeSystem = enclosingLibrary.typeSystem;
    featureComputer = FeatureComputer(typeSystem, typeProvider);

    for (var directive in node.directives) {
      _recordKeyword(
        CompletionLocation.compilationUnitDirective,
        directive,
        allowedKeywords: directiveKeywords,
      );
    }
    for (var declaration in node.declarations) {
      _recordDataForNode(
        CompletionLocation.compilationUnitDeclaration,
        declaration,
        allowedKeywords: declarationKeywords,
      );
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _recordDataForNode(
      CompletionLocation.conditionalExpressionThenExpression,
      node.thenExpression,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.conditionalExpressionElseExpression,
      node.elseExpression,
      allowedKeywords: expressionKeywords,
    );
    super.visitConditionalExpression(node);
  }

  @override
  void visitConfiguration(Configuration node) {
    // The list of valid names is short, so we don't use the relevance tables to
    // try to sort them by frequency.
    for (var token in node.name.tokens) {
      _identifiersAndKeywords.remove(token);
    }
    super.visitConfiguration(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    _recordDataForNode(
      CompletionLocation.constantPatternExpression,
      node.expression,
      allowedKeywords: [Keyword.CONST],
    );
    super.visitConstantPattern(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // The type name must always be the same as the enclosing class.
    if (node.typeName?.token case var name?) _unrecorded(name);
    if (node.name case var name?) _recordDeclaration(name);

    for (var keyword in [node.newKeyword, node.factoryKeyword]) {
      if (keyword != null &&
          keyword != node.firstTokenAfterCommentAndMetadata) {
        _unrecorded(keyword);
      }
    }

    if (node.typeName case var typeName?) {
      _recordDataForNode(
        CompletionLocation.constructorDeclarationReturnType,
        typeName,
      );
    }
    for (var initializer in node.initializers) {
      _recordDataForNode(
        CompletionLocation.constructorDeclarationInitializer,
        initializer,
      );
    }
    var redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor != null) {
      // There is no relevance data for redirections because only constructors
      // are allowed after the `=`.
      _unrecorded(redirectedConstructor.beginToken);
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.thisKeyword != null) {
      _recordMember(node.fieldName.token);
    }
    _recordDataForNode(
      CompletionLocation.constructorFieldInitializerExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // The token following the `.` is always the name of a constructor.
    if (node.name?.token case var token?) _unrecorded(token);
    super.visitConstructorName(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    // The only valid option is a constructor name.
    super.visitConstructorReference(node);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    // The relevance of individual constructor names isn't dependent on any
    // information available while building the table.
    _unrecorded(node.name.token);
    super.visitConstructorSelector(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    // The token following the `continue` (if there is one) is always a label.
    if (node.label case var label?) _unrecorded(label.name);
    super.visitContinueStatement(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _recordDataForNode(
      CompletionLocation.variableDeclarationListType,
      node.type,
    );
    _recordDeclaration(node.name);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _recordDataForNode(
      CompletionLocation.declaredVariablePatternType,
      node.type,
    );
    _recordDeclaration(node.name);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    // There's only one valid choice at this location.
    _unrecorded(node.whileKeyword);
    _recordDataForNode(
      CompletionLocation.doStatementBody,
      node.body,
      allowedKeywords: statementKeywords,
    );
    _recordDataForNode(
      CompletionLocation.doStatementCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    super.visitDoStatement(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _recordDataForNode(
      CompletionLocation.dotShorthandConstructorInvocationConstructorName,
      node.constructorName,
    );
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _recordDataForNode(
      CompletionLocation.dotShorthandInvocationMemberName,
      node.memberName,
    );
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    _recordDataForNode(
      CompletionLocation.dotShorthandPropertyAccessPropertyName,
      node.propertyName,
    );
    super.visitDotShorthandPropertyAccess(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // There are no completions.
    super.visitDoubleLiteral(node);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {
    // There are no completions.
    super.visitEmptyClassBody(node);
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
  void visitEnumConstantArguments(EnumConstantArguments node) {
    // There are no completions.
    super.visitEnumConstantArguments(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // There are no completions.
    _recordDeclaration(node.name);
    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // If there are modifiers before `enum`, then the first will be recorded
    // by the containing node, but the rest will not use the relevance tables
    // because there is a fixed order in which they must appear.
    _unrecordedBetween(
      node.firstTokenAfterCommentAndMetadata,
      node.enumKeyword,
    );

    _recordDeclaration(node.namePart.typeName);
    _recordKeyword(
      CompletionLocation.enumDeclarationName,
      node.implementsClause,
      allowedKeywords: [Keyword.IMPLEMENTS],
    );

    for (var member in node.body.members) {
      _recordDataForNode(
        CompletionLocation.enumDeclarationMember,
        member,
        allowedKeywords: memberKeywords,
      );
    }

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var location = CompletionLocation.importDirectiveUri;
    if (node.configurations.isNotEmpty) {
      _recordKeyword(
        location,
        node.configurations[0],
        allowedKeywords: exportKeywords,
      );
      location = CompletionLocation.importDirectiveConfigurations;
    }
    if (node.combinators.isNotEmpty) {
      _recordKeyword(
        location,
        node.combinators[0],
        allowedKeywords: exportKeywords,
      );
    }
    for (var combinator in node.combinators) {
      _recordKeyword(
        CompletionLocation.importDirectiveCombinator,
        combinator,
        allowedKeywords: exportKeywords,
      );
    }
    super.visitExportDirective(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _recordKeyword(
      CompletionLocation.expressionFunctionBodyStart,
      node,
      allowedKeywords: functionBodyKeywords,
    );
    _recordDataForNode(
      CompletionLocation.expressionFunctionBodyExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _recordDataForNode(
      CompletionLocation.expressionStatementExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitExpressionStatement(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _recordDataForNode(
      CompletionLocation.extendsClauseSuperclass,
      node.superclass,
    );
    super.visitExtendsClause(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // If there are modifiers before `extension`, then the first will be
    // recorded by the containing node, but the rest will not use the relevance
    // tables because there is a fixed order in which they must appear.
    _unrecordedBetween(
      node.firstTokenAfterCommentAndMetadata,
      node.extensionKeyword,
    );

    if (node.name case var name?) {
      _recordDeclaration(name);
    }
    _recordKeyword(
      CompletionLocation.extensionDeclarationOnClause,
      node.onClause,
      allowedKeywords: [Keyword.ON],
    );
    if (node.body case BlockClassBody body) {
      for (var member in body.members) {
        _recordDataForNode(
          CompletionLocation.extensionDeclarationMember,
          member,
          allowedKeywords: memberKeywords,
        );
      }
    }
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    _recordDataForNode(
      CompletionLocation.extensionOnClauseExtendedType,
      node.extendedType,
    );
    super.visitExtensionOnClause(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    // If there's a prefix, it's handled by the surrounding context and we still
    // need to handle the member.
    if (node.importPrefix != null) {
      _recordMember(node.name);
    }
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    // If there are modifiers before `extension`, then the first will be
    // recorded by the containing node, but the rest will not use the relevance
    // tables because there is a fixed order in which they must appear.
    _unrecordedBetween(
      node.firstTokenAfterCommentAndMetadata,
      node.extensionKeyword,
    );
    // No other completions are valid after `extension`.
    _unrecorded(node.typeKeyword);

    _recordDeclaration(node.namePart.typeName);

    for (var member in node.body.members) {
      _recordDataForNode(
        CompletionLocation.extensionTypeDeclarationMember,
        member,
        allowedKeywords: memberKeywords,
      );
    }
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _recordDataForNode(CompletionLocation.fieldDeclarationFields, node.fields);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    // No other completions are valid here.
    _unrecorded(node.thisKeyword);
    // The completions after `this.` are always existing fields.
    _unrecorded(node.name);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    // No other completions are valid here.
    _unrecorded(node.inKeyword);
    _recordDataForNode(
      CompletionLocation.forEachPartsWithDeclarationLoopVariable,
      node.loopVariable,
    );
    _recordDataForNode(
      CompletionLocation.forEachPartsIterable,
      node.iterable,
      allowedKeywords: expressionKeywords,
    );
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    // No other completions are valid here.
    _unrecorded(node.inKeyword);
    _recordDataForNode(
      CompletionLocation.forEachPartsWithIdentifierIdentifier,
      node.identifier,
    );
    _recordDataForNode(
      CompletionLocation.forEachPartsIterable,
      node.iterable,
      allowedKeywords: expressionKeywords,
    );
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    // No other completions are valid here.
    _unrecorded(node.inKeyword);
    _recordDataForNode(
      CompletionLocation.forEachPartsWithPatternPattern,
      node.pattern,
      allowedKeywords: patternKeywords,
    );
    _recordDataForNode(
      CompletionLocation.forEachPartsWithPatternIterable,
      node.iterable,
      allowedKeywords: expressionKeywords,
    );
    super.visitForEachPartsWithPattern(node);
  }

  @override
  void visitForElement(ForElement node) {
    if (node.awaitKeyword != null) _unrecorded(node.forKeyword);
    _recordDataForNode(
      CompletionLocation.forElementForLoopParts,
      node.forLoopParts,
    );
    _recordDataForNode(CompletionLocation.forElementBody, node.body);
    super.visitForElement(node);
  }

  @override
  void visitFormalParameterDefaultClause(FormalParameterDefaultClause node) {
    _recordDataForNode(
      CompletionLocation.defaultFormalParameterDefaultValue,
      node.value,
      allowedKeywords: expressionKeywords,
    );
    super.visitFormalParameterDefaultClause(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      _recordDataForNode(
        CompletionLocation.formalParameterListParameter,
        parameter,
        allowedKeywords: [Keyword.COVARIANT, Keyword.REQUIRED],
      );
    }
    super.visitFormalParameterList(node);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _recordDataForNode(
      CompletionLocation.forPartsCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    for (var updater in node.updaters) {
      _recordDataForNode(
        CompletionLocation.forPartsUpdater,
        updater,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitForPartsWithDeclarations(node);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _recordDataForNode(
      CompletionLocation.forPartsCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    for (var updater in node.updaters) {
      _recordDataForNode(
        CompletionLocation.forPartsUpdater,
        updater,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitForPartsWithExpression(node);
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _recordDataForNode(
      CompletionLocation.forPartsCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    for (var updater in node.updaters) {
      _recordDataForNode(
        CompletionLocation.forPartsUpdater,
        updater,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitForPartsWithPattern(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) _unrecorded(node.forKeyword);
    _recordDataForNode(
      CompletionLocation.forStatementForLoopParts,
      node.forLoopParts,
    );
    _recordDataForNode(
      CompletionLocation.forStatementBody,
      node.body,
      allowedKeywords: statementKeywords,
    );
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _recordDeclaration(node.name);
    _recordDataForNode(
      CompletionLocation.functionDeclarationReturnType,
      node.returnType,
    );
    if (node.propertyKeyword case var keyword?) _unrecorded(keyword);
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
  void visitFunctionReference(FunctionReference node) {
    // There are no completions.
    super.visitFunctionReference(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // There are no completions.
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitFunctionTypedFormalParameterSuffix(
    FunctionTypedFormalParameterSuffix node,
  ) {
    // There are no completions.
    super.visitFunctionTypedFormalParameterSuffix(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    // No other completions are valid here.
    _unrecorded(node.functionKeyword);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _recordDeclaration(node.name);
    _recordDataForNode(
      CompletionLocation.genericTypeAliasType,
      node.type,
      allowedKeywords: [Keyword.FUNCTION],
    );
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    // There are no completions.
    super.visitGuardedPattern(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    for (var hiddenName in node.hiddenNames) {
      _recordDataForNode(
        CompletionLocation.hideCombinatorHiddenName,
        hiddenName,
      );
    }
    super.visitHideCombinator(node);
  }

  @override
  void visitIfElement(IfElement node) {
    // This is handled by locations where an expression is expected.
    if (node.elseKeyword case var keyword?) _unrecorded(keyword);

    _recordDataForNode(
      CompletionLocation.ifElementCondition,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.ifElementThenElement,
      node.thenElement,
    );
    _recordDataForNode(
      CompletionLocation.ifElementElseElement,
      node.elseElement,
    );
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    // This is handled by locations where a statement is expected.
    if (node.elseKeyword case var keyword?) _unrecorded(keyword);

    _recordDataForNode(
      CompletionLocation.ifStatementCondition,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.ifStatementThenStatement,
      node.thenStatement,
      allowedKeywords: statementKeywords,
    );
    _recordDataForNode(
      CompletionLocation.ifStatementElseStatement,
      node.elseStatement,
      allowedKeywords: statementKeywords,
    );
    super.visitIfStatement(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    // The set of keywords available at this point is small and deterministic.
    _unrecorded(node.implementsKeyword);
    // At the start of each type name.
    for (var namedType in node.interfaces) {
      _recordDataForNode(
        CompletionLocation.implementsClauseInterface,
        namedType,
      );
    }
    super.visitImplementsClause(node);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    // TODO(brianwilkerson): implement visitImplicitCallReference
    super.visitImplicitCallReference(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    // We don't record relevance data here because we make the assumption that
    // `as` occurs more often than `deferred` at this location.
    if (node.asKeyword case var keyword?) _unrecorded(keyword);
    if (node.prefix case var prefix?) _recordDeclaration(prefix.token);

    var location = CompletionLocation.importDirectiveUri;
    var deferredKeyword = node.deferredKeyword;
    if (deferredKeyword != null) {
      recordKeyword(location, deferredKeyword);
      location = CompletionLocation.importDirectiveDeferred;
    }
    var asKeyword = node.asKeyword;
    if (asKeyword != null) {
      recordKeyword(location, asKeyword);
      location = CompletionLocation.importDirectivePrefix;
    }
    if (node.configurations.isNotEmpty) {
      _recordKeyword(
        location,
        node.configurations[0],
        allowedKeywords: importKeywords,
      );
      location = CompletionLocation.importDirectiveConfigurations;
    }
    if (node.combinators.isNotEmpty) {
      _recordKeyword(
        location,
        node.combinators[0],
        allowedKeywords: importKeywords,
      );
    }
    for (var combinator in node.combinators) {
      _recordKeyword(
        CompletionLocation.importDirectiveCombinator,
        combinator,
        allowedKeywords: importKeywords,
      );
    }
    super.visitImportDirective(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    // There are no completions.
    super.visitImportPrefixReference(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _recordDataForNode(
      CompletionLocation.indexExpressionIndex,
      node.index,
      allowedKeywords: expressionKeywords,
    );
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordDataForNode(
      CompletionLocation.instanceCreationExpressionConstructorName,
      node.constructorName,
    );
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // There are no completions.
    super.visitIntegerLiteral(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    // TODO(brianwilkerson): Consider splitting this based on whether the
    //  expression is a simple identifier ('$') or a full expression ('${').
    _recordDataForNode(
      CompletionLocation.interpolationExpressionExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitInterpolationExpression(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    // There are no completions.
    super.visitInterpolationString(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _recordMember(node.isOperator);
    _recordDataForNode(CompletionLocation.isExpressionType, node.type);
    super.visitIsExpression(node);
  }

  @override
  void visitLabel(Label node) {
    // There are no completions.
    _recordDeclaration(node.name);
    super.visitLabel(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _recordDataForNode(
      CompletionLocation.labeledStatementStatement,
      node.statement,
      allowedKeywords: statementKeywords,
    );
    super.visitLabeledStatement(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    if (node.name case var name?) {
      for (var token in name.tokens) {
        _recordDeclaration(token);
      }
    }
    super.visitLibraryDirective(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    for (var element in node.elements) {
      _recordDataForNode(
        CompletionLocation.listLiteralElement,
        element,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitListLiteral(node);
  }

  @override
  void visitListPattern(ListPattern node) {
    for (var element in node.elements) {
      _recordDataForNode(
        CompletionLocation.listPatternElement,
        element,
        allowedKeywords: patternKeywords,
      );
    }
    super.visitListPattern(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _recordDataForNode(
      CompletionLocation.logicalAndPatternRightOperand,
      node.rightOperand,
      allowedKeywords: patternKeywords,
    );
    super.visitLogicalAndPattern(node);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _recordDataForNode(
      CompletionLocation.logicalOrPatternRightOperand,
      node.rightOperand,
      allowedKeywords: patternKeywords,
    );
    super.visitLogicalOrPattern(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    // The information about the key is recorded in `visitSetOrMapLiteral` under
    // the key 'SetOrMapLiteral_element'.
    _recordDataForNode(
      CompletionLocation.mapLiteralEntryValue,
      node.value,
      allowedKeywords: expressionKeywords,
    );
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitMapPattern(MapPattern node) {
    // There are no completions.
    super.visitMapPattern(node);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    _recordDataForNode(
      CompletionLocation.mapPatternEntryKey,
      node.key,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.mapPatternEntryValue,
      node.value,
      allowedKeywords: patternKeywords,
    );
    super.visitMapPatternEntry(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.propertyKeyword case var keyword?) _unrecorded(keyword);
    if (node.operatorKeyword case var keyword?) _unrecorded(keyword);
    _recordDeclaration(node.name);

    _recordDataForNode(
      CompletionLocation.methodDeclarationReturnType,
      node.returnType,
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // There are no completions.
    _recordMember(node.methodName.token);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // If there are modifiers before `mixin`, then the first will be recorded
    // by the containing node, but the rest will not use the relevance tables
    // because there is a fixed order in which they must appear.
    _unrecordedBetween(
      node.firstTokenAfterCommentAndMetadata,
      node.mixinKeyword,
    );

    _recordDeclaration(node.name);
    var location = CompletionLocation.mixinDeclarationName;
    if (node.onClause != null) {
      _recordKeyword(location, node.onClause, allowedKeywords: [Keyword.ON]);
      location = CompletionLocation.mixinDeclarationOn;
    }
    _recordKeyword(
      location,
      node.implementsClause,
      allowedKeywords: [Keyword.IMPLEMENTS],
    );

    if (node.body case BlockClassBody body) {
      for (var member in body.members) {
        _recordDataForNode(
          CompletionLocation.mixinDeclarationMember,
          member,
          allowedKeywords: memberKeywords,
        );
      }
    }
    super.visitMixinDeclaration(node);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    for (var constraint in node.superclassConstraints) {
      _recordDataForNode(
        CompletionLocation.onClauseSuperclassConstraint,
        constraint,
      );
    }
    super.visitMixinOnClause(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    // Named expressions only occur in argument lists and are handled there.
    // The label token (`name:`) uses fixed `Relevance.[required]namedArgument`
    // score rather than relevance tables.
    _unrecorded(node.name);
    super.visitNamedArgument(node);
  }

  @override
  void visitNamedType(NamedType node) {
    // There are no completions.
    if (node.importPrefix != null) {
      // There is no relevance data for names following a prefix.
      _recordMember(node.name);
    }
    super.visitNamedType(node);
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    // TODO(brianwilkerson): implement visitNameWithTypeParameters
    super.visitNameWithTypeParameters(node);
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
  void visitNullAssertPattern(NullAssertPattern node) {
    // There are no completions.
    super.visitNullAssertPattern(node);
  }

  @override
  void visitNullAwareElement(NullAwareElement node) {
    _recordDataForNode(CompletionLocation.nullAwareElementValue, node.value);
    super.visitNullAwareElement(node);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    // There are no completions.
    super.visitNullCheckPattern(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    // There are no completions.
    super.visitNullLiteral(node);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    // There are no completions.
    super.visitObjectPattern(node);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _recordDataForNode(
      CompletionLocation.parenthesizedExpressionExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitParenthesizedExpression(node);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    _recordDataForNode(
      CompletionLocation.parenthesizedPatternPattern,
      node.pattern,
      allowedKeywords: patternKeywords,
    );
    super.visitParenthesizedPattern(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    // There are no completions.
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    // No other completions are valid here.
    _unrecorded(node.ofKeyword);
    super.visitPartOfDirective(node);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _recordDataForNode(
      CompletionLocation.patternAssignmentExpression,
      node.expression,
    );
    super.visitPatternAssignment(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _recordDataForNode(
      CompletionLocation.patternFieldPattern,
      node.pattern,
      allowedKeywords: patternKeywords,
    );
    super.visitPatternField(node);
  }

  @override
  void visitPatternFieldName(PatternFieldName node) {
    // The relevance of individual field names isn't dependent on any
    // information available while building the table.
    if (node.name case var name?) _unrecorded(name);
    super.visitPatternFieldName(node);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _recordDataForNode(
      CompletionLocation.patternVariableDeclarationPattern,
      node.pattern,
      allowedKeywords: patternKeywords,
    );
    _recordDataForNode(
      CompletionLocation.patternVariableDeclarationExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPatternVariableDeclarationStatement(
    PatternVariableDeclarationStatement node,
  ) {
    // There are no completions.
    super.visitPatternVariableDeclarationStatement(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    // There are no completions.
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // There are no completions.
    _recordMember(node.identifier.token);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordDataForNode(
      CompletionLocation.prefixExpressionOperand(node.operator.lexeme),
      node.operand,
      allowedKeywords: expressionKeywords,
    );
    super.visitPrefixExpression(node);
  }

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    for (var initializer in node.initializers) {
      _recordDataForNode(
        CompletionLocation.constructorDeclarationInitializer,
        initializer,
      );
    }
    super.visitPrimaryConstructorBody(node);
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    // There are no completions.
    if (node.constKeyword case var keyword?) _unrecorded(keyword);
    super.visitPrimaryConstructorDeclaration(node);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    // There are no completions.
    _recordDeclaration(node.name);
    super.visitPrimaryConstructorName(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _recordMember(node.propertyName.token);
    _recordDataForNode(
      CompletionLocation.propertyAccessPropertyName,
      node.propertyName,
    );
    super.visitPropertyAccess(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (var field in node.fields) {
      if (field is RecordLiteralNamedField) {
        _recordDeclaration(field.name);
        _recordDataForNode(
          CompletionLocation.recordLiteralFields,
          field.fieldExpression,
        );
      } else {
        _recordDataForNode(CompletionLocation.recordLiteralFields, field);
      }
    }
    super.visitRecordLiteral(node);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    // There are no completions.
    super.visitRecordPattern(node);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    // TODO(brianwilkerson): implement visitRecordTypeAnnotation
    super.visitRecordTypeAnnotation(node);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    _recordDataForNode(
      CompletionLocation.recordTypeAnnotationFields,
      node.type,
    );
    _recordDeclaration(node.name);
    super.visitRecordTypeAnnotationNamedField(node);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    // There are no completions.
    super.visitRecordTypeAnnotationNamedFields(node);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    _recordDataForNode(
      CompletionLocation.recordTypeAnnotationFields,
      node.type,
    );
    if (node.name case var name?) _recordDeclaration(name);
    super.visitRecordTypeAnnotationPositionalField(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    // The name of the constructor being redirected to is currently not
    // recorded. Consider adding this to the table so that we could order the
    // list of constructors.
    if (node.constructorName?.token case var name?) _recordMember(name);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    _recordDataForNode(CompletionLocation.simpleFormalParameterType, node.type);
    if (node.name case var name?) {
      _recordDeclaration(name);
    }
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    _recordDataForNode(
      CompletionLocation.relationalPatternOperatorOperand(node.operator.lexeme),
      node.operand,
      allowedKeywords: expressionKeywords,
    );
    super.visitRelationalPattern(node);
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    _recordDataForNode(
      CompletionLocation.restPatternElementPattern,
      node.pattern,
      allowedKeywords: patternKeywords,
    );
    super.visitRestPatternElement(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // There are no completions.
    super.visitRethrowExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _recordDataForNode(
      CompletionLocation.returnStatementExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
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
      _recordDataForNode(
        CompletionLocation.setOrMapLiteralElement,
        element,
        allowedKeywords: expressionKeywords,
      );
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    for (var name in node.shownNames) {
      _recordDataForNode(CompletionLocation.showCombinatorShownName, name);
    }
    super.visitShowCombinator(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // There are no completions.
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // There are no completions.
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _recordDataForNode(
      CompletionLocation.spreadElementExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitSpreadElement(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // There are no completions.
    super.visitStringInterpolation(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // The name of the super constructor is currently not recorded. Consider
    // adding this to the table so that we could order the list of constructors.
    if (node.constructorName?.token case var name?) _recordMember(name);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    // There are no completions.
    super.visitSuperExpression(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    // No other completions are valid here.
    _unrecorded(node.superKeyword);
    _recordDeclaration(node.name);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // No other completions are valid here.
    _unrecorded(node.keyword);
    _recordDataForNode(
      CompletionLocation.switchCaseExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    for (var statement in node.statements) {
      _recordDataForNode(
        CompletionLocation.switchMemberStatement,
        statement,
        allowedKeywords: statementKeywords,
      );
    }
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    // No other completions are valid here.
    _unrecorded(node.keyword);
    for (var statement in node.statements) {
      _recordDataForNode(
        CompletionLocation.switchMemberStatement,
        statement,
        allowedKeywords: statementKeywords,
      );
    }
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _recordDataForNode(
      CompletionLocation.switchExpressionExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitSwitchExpression(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _recordDataForNode(
      CompletionLocation.switchExpressionPattern,
      node.guardedPattern,
      allowedKeywords: patternKeywords,
    );
    _recordDataForNode(
      CompletionLocation.switchExpressionCaseExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    // No other completions are valid here.
    _unrecorded(node.keyword);
    _recordDataForNode(
      CompletionLocation.switchPatternCasePattern,
      node.guardedPattern,
      allowedKeywords: patternKeywords,
    );
    for (var statement in node.statements) {
      _recordDataForNode(
        CompletionLocation.switchMemberStatement,
        statement,
        allowedKeywords: statementKeywords,
      );
    }
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _recordDataForNode(
      CompletionLocation.switchStatementExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitSwitchStatement(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    // There are no completions in symbol literals.
    for (var component in node.components) {
      _unrecorded(component);
    }
    super.visitSymbolLiteral(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    // There are no completions.
    super.visitThisExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _recordDataForNode(
      CompletionLocation.throwExpressionExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitThrowExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // There are no completions.
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    var location = CompletionLocation.tryStatementTry;
    for (var clause in node.catchClauses) {
      _recordKeyword(location, clause, allowedKeywords: [Keyword.ON]);
      location = CompletionLocation.tryStatementCatch;
    }
    var finallyKeyword = node.finallyKeyword;
    if (finallyKeyword != null) {
      recordKeyword(location, finallyKeyword);
    }
    super.visitTryStatement(node);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    for (var typeArgument in node.arguments) {
      _recordDataForNode(
        CompletionLocation.typeArgumentListArgument,
        typeArgument,
      );
    }
    super.visitTypeArgumentList(node);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    // TODO(brianwilkerson): Consider recording the kind of declaration that
    //  produced the type. If it's more common to see classes than mixins, for
    //  example, then we could use that to adjust the relevance of completions.
    super.visitTypeLiteral(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    // There is no relevance data because there's only one allowed keyword.
    if (node.extendsKeyword case var keyword?) _unrecorded(keyword);

    _recordDeclaration(node.name);
    if (node.bound != null) {
      _recordDataForNode(CompletionLocation.typeParameterBound, node.bound);
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
    _recordDeclaration(node.name);
    var keywords = node.parent?.parent is FieldDeclaration
        ? [Keyword.COVARIANT, ...expressionKeywords]
        : expressionKeywords;
    _recordDataForNode(
      CompletionLocation.variableDeclarationInitializer,
      node.initializer,
      allowedKeywords: keywords,
    );
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.lateKeyword != null) {
      if (node.keyword case var keyword?) {
        _unrecorded(keyword);
      }
    }
    _recordDataForNode(
      CompletionLocation.variableDeclarationListType,
      node.type,
    );
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    // There are no completions.
    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhenClause(WhenClause node) {
    // No other completions are valid here.
    _unrecorded(node.whenKeyword);
    _recordDataForNode(
      CompletionLocation.whenClauseExpression,
      node.expression,
    );
    super.visitWhenClause(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _recordDataForNode(
      CompletionLocation.whileStatementCondition,
      node.condition,
      allowedKeywords: expressionKeywords,
    );
    _recordDataForNode(
      CompletionLocation.whileStatementBody,
      node.body,
      allowedKeywords: statementKeywords,
    );
    super.visitWhileStatement(node);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {
    _recordDataForNode(CompletionLocation.wildcardPatternType, node.type);
    _unrecorded(node.name);
    super.visitWildcardPattern(node);
  }

  @override
  void visitWithClause(WithClause node) {
    // The set of keywords available at this point is small and deterministic.
    _unrecorded(node.withKeyword);
    for (var namedType in node.mixinTypes) {
      _recordDataForNode(CompletionLocation.withClauseMixinType, namedType);
    }
    super.visitWithClause(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _recordDataForNode(
      CompletionLocation.yieldStatementExpression,
      node.expression,
      allowedKeywords: expressionKeywords,
    );
    super.visitYieldStatement(node);
  }

  /// Return the context in which the [node] occurs. The [node] is expected to
  /// be the parent of the argument expression.
  String _argumentListContext(AstNode node) {
    if (node is ArgumentList) {
      var parent = node.parent;
      if (parent is Annotation) {
        return 'annotation';
      } else if (parent is DotShorthandConstructorInvocation) {
        if (parent.staticType.isWidgetType) {
          return 'widgetConstructor';
        }
        return 'constructor';
      } else if (parent is DotShorthandInvocation) {
        return 'method';
      } else if (parent is EnumConstantArguments) {
        return 'enumConstantArguments';
      } else if (parent is ExtensionOverride) {
        return 'extensionOverride';
      } else if (parent is FunctionExpressionInvocation) {
        return 'function';
      } else if (parent is InstanceCreationExpression) {
        if (parent.staticType.isWidgetType) {
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
      'Unknown parent of ${node.runtimeType}: ${node.parent.runtimeType}',
    );
  }

  /// Return the first child of the [node] that is neither a comment nor an
  /// annotation.
  SyntacticEntity? _firstChild(AstNode node) {
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
  /// child of the [node], or `null` if the left-most token is not an
  /// identifier reference (for example, a keyword, literal, or declared name).
  /// Comments and annotations are ignored for this purpose.
  Element? _leftMostElement(AstNode node) {
    AstNode? currentNode = node;
    while (currentNode != null) {
      // For unqualified `Foo()` return the constructor rather than descending
      // to `NamedType` (which resolves to the class).
      if (currentNode is InstanceCreationExpression &&
          currentNode.keyword == null &&
          currentNode.constructorName.type.importPrefix == null) {
        return currentNode.constructorName.element;
      }

      var firstChild = _firstChild(currentNode);
      if (firstChild is AstNode) {
        currentNode = firstChild;
      } else {
        return switch (currentNode) {
          AssignedVariablePattern() => currentNode.element,
          ExtensionOverride() => currentNode.element,
          ImportPrefixReference() => currentNode.element,
          NamedType() => currentNode.element,
          SimpleIdentifier() when !currentNode.inDeclarationContext() =>
            currentNode.writeOrReadElement,
          _ => null,
        };
      }
    }
    return null;
  }

  /// Return the element kind of the element associated with the left-most
  /// identifier that is a child of the [node].
  ElementKind? _leftMostKind(AstNode node) {
    var element = _leftMostElement(node);
    if (element == null) {
      return null;
    }
    if (element is InterfaceElement) {
      var parent = node.parent;
      if (parent is Annotation && parent.arguments != null) {
        element = parent.element!;
      }
    }
    return featureComputer.computeElementKind2(element);
  }

  /// Return the left-most token that is a child of the [node].
  Token? _leftMostToken(AstNode node) {
    SyntacticEntity? entity = node;
    while (entity is AstNode) {
      entity = _firstChild(entity);
    }
    if (entity is Token) {
      return entity;
    }
    return null;
  }

  /// Record information about the given [node] occurring in the given
  /// [context].
  void _recordDataForNode(
    String context,
    AstNode? node, {
    List<Keyword> allowedKeywords = noKeywords,
  }) {
    // Skip past the null-aware operator if present. This is making the
    // assumption that the probability of the next token is not dependent on the
    // presence or absence of the null-aware operator.
    var token = node != null ? _leftMostToken(node) : null;
    if (node is MapLiteralEntry && node.keyQuestion == token) {
      token = token?.next;
    } else if (node is NullAwareElement && node.question == token) {
      token = token?.next;
    }
    _identifiersAndKeywords.remove(token);
    _recordElementKind(context, node);
    _recordKeywordToken(context, token, allowedKeywords: allowedKeywords);
    // Record data for all of the keywords in a formal parameter. This is
    // contrary to the way other strings of keywords are handled, and probably
    // needs a good justification (or needs to be changed).
    if (node is FormalParameter && token != null && token.isKeyword) {
      token = token.next;
      while (token != null && token.isKeyword && token != node.name) {
        _recordKeywordToken(context, token, allowedKeywords: allowedKeywords);
        token = token.next;
      }
      if (node.type case var type?) {
        _identifiersAndKeywords.remove(_leftMostToken(type));
        _recordElementKind(context, type);
      }
    }
  }

  /// There is no information recorded about identifiers that are being
  /// declared because code completion bases its suggestions on the name of the
  /// context type, but they need to be removed from the list of identifiers and
  /// keywords so that they aren't reported as being unrecorded.
  ///
  /// This is effectively a marker explaining why the identifier isn't recorded
  /// that doesn't require a comment at every invocation site.
  void _recordDeclaration(Token token) {
    _unrecorded(token);
  }

  /// Record the element kind of the element associated with the left-most
  /// identifier that is a child of the [node] in the given [context].
  void _recordElementKind(String context, AstNode? node) {
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
  void _recordKeyword(
    String context,
    AstNode? node, {
    List<Keyword> allowedKeywords = noKeywords,
  }) {
    if (node != null) {
      var token = _leftMostToken(node);
      _recordKeywordToken(context, token, allowedKeywords: allowedKeywords);
    }
  }

  /// Record that [token] occurred in the given context.
  void _recordKeywordToken(
    String context,
    Token? token, {
    List<Keyword> allowedKeywords = noKeywords,
  }) {
    if (token != null && token.isKeyword) {
      _identifiersAndKeywords.remove(token);
      var keyword = token.keyword!;
      if (keyword == Keyword.NEW) {
        // We don't suggest `new`, so we don't care about the frequency with
        // which it is used.
        return;
      } else if (keyword.isBuiltInOrPseudo &&
          !allowedKeywords.contains(keyword)) {
        // These keywords can be used as identifiers, so determine whether
        // it is being used as a keyword or an identifier.
        return;
      }
      recordKeyword(context, token);
    }
  }

  /// There is no information recorded about the names of members that are being
  /// accessed, but they need to be removed from the list of identifiers and
  /// keywords so that they aren't reported as being unrecorded.
  void _recordMember(Token? token) {
    // TODO(brianwilkerson): Consider collecting and using the data at every
    //  location where this method is invoked. If the data would not be helpful,
    //  invoke `_unrecorded` instead.
    if (token != null) _identifiersAndKeywords.remove(token);
  }

  /// The given [token] is in a location where no relevance table entry is
  /// needed. Remove the token from the list of unrecorded tokens so that it
  /// won't produce a false positive.
  ///
  /// Invocation sites should indicate why there's no relevance table entry.
  void _unrecorded(Token token) {
    _identifiersAndKeywords.remove(token);
  }

  /// If the [firstToken] and [lastToken] are not the same, then record that the
  /// tokens after [firstToken] up to and including the [lastToken] are not
  /// captured in the relevance table.
  void _unrecordedBetween(Token firstToken, Token lastToken) {
    if (firstToken != lastToken) {
      var token = firstToken.next!;
      while (token != lastToken) {
        _unrecorded(token);
        token = token.next!;
      }
      _unrecorded(token);
    }
  }
}

/// An object used to compute metrics for a single file or directory.
class RelevanceMetricsComputer {
  /// The metrics data that was computed.
  final RelevanceData data = RelevanceData();

  /// Initialize a newly created metrics computer that can compute the metrics
  /// in one or more files and directories.
  new();

  /// Compute the metrics for the file(s) in the [rootPath].
  /// If [corpus] is true, treat rootPath as a container of packages, creating
  /// a new context collection for each subdirectory.
  Future<void> compute(String rootPath, {required bool verbose}) async {
    var collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var collector = RelevanceDataCollector(data);
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot, collector, verbose: verbose);
    }
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector]. Include additional details in the
  /// output if [verbose] is `true`.
  Future<void> _computeInContext(
    ContextRoot root,
    RelevanceDataCollector collector, {
    required bool verbose,
  }) async {
    // Create a new collection to avoid consuming large quantities of memory.
    var collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];
    var pathContext = context.contextRoot.resourceProvider.pathContext;
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (!file_paths.isDart(pathContext, filePath) ||
          shouldSkipFile(pathContext, filePath)) {
        continue;
      }
      try {
        var resolvedUnitResult = await context.currentSession.getResolvedUnit(
          filePath,
        );
        //
        // Check for errors that cause the file to be skipped.
        //
        if (resolvedUnitResult is! ResolvedUnitResult) {
          print("File $filePath skipped because it couldn't be analyzed.");
          if (verbose) {
            print('');
          }
          continue;
        } else if (resolvedUnitResult.diagnostics.errors.isNotEmpty) {
          if (verbose) {
            print('File $filePath skipped due to errors:');
            for (var diagnostic in resolvedUnitResult.diagnostics.errors) {
              print('  ${diagnostic.toString()}');
            }
            print('');
          } else {
            print('File $filePath skipped due to analysis errors.');
          }
          continue;
        }

        collector.initializeFrom(resolvedUnitResult);
        resolvedUnitResult.unit.accept(collector);
        var identifiersAndKeywords = collector._identifiersAndKeywords;
        if (identifiersAndKeywords.isNotEmpty) {
          print('Unrecorded identifiers and keywords in $filePath:');
          for (var token in identifiersAndKeywords) {
            print(_tokenInContext(token));
            var ancestors = resolvedUnitResult.unit
                .nodeCovering(offset: token.offset)
                ?.withAncestors;
            if (ancestors == null) {
              print('*** Node not found');
            } else {
              print(
                ancestors.map((node) => node.runtimeType.toString()).join(', '),
              );
            }
          }
        }
      } catch (exception, stacktrace) {
        print('Exception caught analyzing: "$filePath"');
        print(exception);
        print(stacktrace);
      }
    }
  }

  /// Print the [token] surrounded by markup, together with the 10 tokens before
  /// and 10 tokens after the [token].
  String _tokenInContext(Token token) {
    var first = token;
    for (var i = 0; i < 10; i++) {
      first = first.previous!;
    }
    var last = token;
    for (var i = 0; i < 10; i++) {
      last = last.next!;
    }
    var buffer = StringBuffer()..write('  ');
    var current = first;
    if (!current.isEof) {
      buffer.write('...');
    }
    while (current != last) {
      buffer.write(' ');
      if (current == token) buffer.write('[!');
      buffer.write(current.lexeme);
      if (current == token) buffer.write('!]');
      current = current.next!;
    }
    buffer.write(' ${current.lexeme}');
    if (!current.isEof) {
      buffer.write(' ...');
    }
    return buffer.toString();
  }
}

/// A class used to write relevance data as a set of tables in a generated Dart
/// file.
class RelevanceTableWriter {
  final StringSink sink;

  new(this.sink);

  void write(RelevanceData data) {
    writeFileHeader();
    writeElementKindTable(data);
    writeKeywordTable(data);
    writeFileFooter();
  }

  void writeElementKindTable(RelevanceData data) {
    sink.writeln();
    sink.write('''
const defaultElementKindRelevance = {
''');

    var byKind = data._byKind;
    var entries = byKind.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    for (var entry in entries) {
      var completionLocation = entry.key;
      var counts = entry.value;
      if (_hasElementKind(counts)) {
        var totalCount = _totalCount(counts);
        // TODO(brianwilkerson): If two element kinds have the same count they
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

  void writeFileFooter() {
    sink.write('''
/// A table keyed by completion location and element kind whose values are the
/// ranges of the relevance of those element kinds in those locations.
Map<String, Map<ElementKind, ProbabilityRange>> elementKindRelevance =
    defaultElementKindRelevance;

/// A table keyed by completion location and keyword whose values are the
/// ranges of the relevance of those keywords in those locations.
Map<String, Map<String, ProbabilityRange>> keywordRelevance =
    defaultKeywordRelevance;
''');
  }

  void writeFileHeader() {
    sink.write('''
// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
const defaultKeywordRelevance = {
''');

    var byKind = data._byKind;
    var entries = byKind.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    for (var entry in entries) {
      var completionLocation = entry.key;
      var counts = entry.value;
      if (_hasKeyword(counts)) {
        var totalCount = _totalCount(counts);
        // TODO(brianwilkerson): If two keywords have the same count they ought to
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
    return counts.values.fold(
      0,
      (previousValue, value) => previousValue + value,
    );
  }
}

/// A wrapper for an element kind to allow keywords and element kinds to be used
/// as keys in a single table.
class _ElementKind extends _Kind {
  static final Map<ElementKind, _ElementKind> instances = {};

  final ElementKind elementKind;

  factory(ElementKind elementKind) =>
      instances.putIfAbsent(elementKind, () => _ElementKind._(elementKind));

  new _(this.elementKind);

  @override
  String get uniqueKey => 'e${elementKind.name}';
}

/// A wrapper for a keyword to allow keywords and element kinds to be used as
/// keys in a single table.
class _Keyword extends _Kind {
  static final Map<Keyword, _Keyword> instances = {};

  final Keyword keyword;

  factory(Keyword keyword) =>
      instances.putIfAbsent(keyword, () => _Keyword._(keyword));

  new _(this.keyword);

  @override
  String get uniqueKey => 'k${keyword.lexeme}';
}

/// A superclass for [_ElementKind] and [_Keyword] to allow keywords and element
/// kinds to be used as keys in a single table.
abstract class _Kind {
  /// Return the unique key used when representing an instance of a subclass in
  /// a JSON format.
  String get uniqueKey;
}
