// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart'
    hide AssistContributor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

typedef _SimpleIdentifierVisitor(SimpleIdentifier node);

/**
 * The computer for Dart assists.
 */
class AssistProcessor {
  final DartAssistContext context;
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final AnalysisSession session;
  final AnalysisSessionHelper sessionHelper;
  final TypeProvider typeProvider;
  final String file;
  final CorrectionUtils utils;
  final Flutter flutter;

  final List<Assist> assists = <Assist>[];

  AstNode node;

  AssistProcessor(this.context)
      : selectionOffset = context.selectionOffset,
        selectionLength = context.selectionLength,
        selectionEnd = context.selectionOffset + context.selectionLength,
        session = context.resolveResult.session,
        sessionHelper = AnalysisSessionHelper(context.resolveResult.session),
        typeProvider = context.resolveResult.typeProvider,
        file = context.resolveResult.path,
        utils = new CorrectionUtils(context.resolveResult),
        flutter = Flutter.of(context.resolveResult);

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  /**
   * Return the status of the known experiments.
   */
  ExperimentStatus get experimentStatus =>
      (session.analysisContext.analysisOptions as AnalysisOptionsImpl)
          .experimentStatus;

  Future<List<Assist>> compute() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (!_setupCompute()) {
      return assists;
    }

    await _addProposal_addTypeAnnotation_DeclaredIdentifier();
    await _addProposal_addTypeAnnotation_SimpleFormalParameter();
    await _addProposal_addTypeAnnotation_VariableDeclaration();
    await _addProposal_assignToLocalVariable();
    await _addProposal_convertClassToMixin();
    await _addProposal_convertDocumentationIntoBlock();
    await _addProposal_convertDocumentationIntoLine();
    await _addProposal_convertIntoFinalField();
    await _addProposal_convertIntoGetter();
    await _addProposal_convertListConstructorToListLiteral();
    await _addProposal_convertListToSetToSetLiteral();
    await _addProposal_convertMapConstructorToMapLiteral();
    await _addProposal_convertPartOfToUri();
    await _addProposal_convertSetConstructorToSetLiteral();
    await _addProposal_convertToAsyncFunctionBody();
    await _addProposal_convertToBlockFunctionBody();
    await _addProposal_convertToDoubleQuotedString();
    await _addProposal_convertToExpressionFunctionBody();
    await _addProposal_convertToFieldParameter();
    await _addProposal_convertToForIndexLoop();
    await _addProposal_convertToGenericFunctionSyntax();
    await _addProposal_convertToIntLiteral();
    await _addProposal_convertToIsNot_onIs();
    await _addProposal_convertToIsNot_onNot();
    await _addProposal_convertToIsNotEmpty();
    await _addProposal_convertToMultilineString();
    await _addProposal_convertToNormalParameter();
    await _addProposal_convertToNullAware();
    await _addProposal_convertToPackageImport();
    await _addProposal_convertToSingleQuotedString();
    await _addProposal_encapsulateField();
    await _addProposal_exchangeOperands();
    await _addProposal_flutterConvertToChildren();
    await _addProposal_flutterConvertToStatefulWidget();
    await _addProposal_flutterMoveWidgetDown();
    await _addProposal_flutterMoveWidgetUp();
    await _addProposal_flutterRemoveWidget_singleChild();
    await _addProposal_flutterRemoveWidget_multipleChildren();
    await _addProposal_flutterSwapWithChild();
    await _addProposal_flutterSwapWithParent();
    await _addProposal_flutterWrapStreamBuilder();
    await _addProposal_flutterWrapWidget();
    await _addProposal_flutterWrapWidgets();
    await _addProposal_importAddShow();
    await _addProposal_inlineAdd();
    await _addProposal_introduceLocalTestedType();
    await _addProposal_invertIf();
    await _addProposal_joinIfStatementInner();
    await _addProposal_joinIfStatementOuter();
    await _addProposal_joinVariableDeclaration_onAssignment();
    await _addProposal_joinVariableDeclaration_onDeclaration();
    await _addProposal_removeTypeAnnotation();
    await _addProposal_reparentFlutterList();
    await _addProposal_replaceConditionalWithIfElse();
    await _addProposal_replaceIfElseWithConditional();
    await _addProposal_sortChildPropertyLast();
    await _addProposal_splitAndCondition();
    await _addProposal_splitVariableDeclaration();
    await _addProposal_surroundWith();
    await _addProposal_useCurlyBraces();

    if (experimentStatus.control_flow_collections) {
      await _addProposal_convertConditionalExpressionToIfElement();
      await _addProposal_convertMapFromIterableToForLiteral();
    }
    if (experimentStatus.spread_collections) {
      await _addProposal_convertAddAllToSpread();
    }

    return assists;
  }

  Future<List<Assist>> computeAssist(AssistKind assistKind) async {
    if (!_setupCompute()) {
      return assists;
    }

    // Calculate only specific assists for edit.dartFix
    if (assistKind == DartAssistKind.CONVERT_CLASS_TO_MIXIN) {
      await _addProposal_convertClassToMixin();
    } else if (assistKind == DartAssistKind.CONVERT_TO_INT_LITERAL) {
      await _addProposal_convertToIntLiteral();
    } else if (assistKind == DartAssistKind.CONVERT_TO_SPREAD) {
      if (experimentStatus.spread_collections) {
        await _addProposal_convertAddAllToSpread();
      }
    } else if (assistKind == DartAssistKind.CONVERT_TO_FOR_ELEMENT) {
      if (experimentStatus.control_flow_collections) {
        await _addProposal_convertMapFromIterableToForLiteral();
      }
    } else if (assistKind == DartAssistKind.CONVERT_TO_IF_ELEMENT) {
      if (experimentStatus.control_flow_collections) {
        await _addProposal_convertConditionalExpressionToIfElement();
      }
    }
    return assists;
  }

  FunctionBody getEnclosingFunctionBody() {
    // TODO(brianwilkerson) Determine whether there is a reason why this method
    // isn't just "return node.getAncestor((node) => node is FunctionBody);"
    {
      FunctionExpression function =
          node.thisOrAncestorOfType<FunctionExpression>();
      if (function != null) {
        return function.body;
      }
    }
    {
      FunctionDeclaration function =
          node.thisOrAncestorOfType<FunctionDeclaration>();
      if (function != null) {
        return function.functionExpression.body;
      }
    }
    {
      ConstructorDeclaration constructor =
          node.thisOrAncestorOfType<ConstructorDeclaration>();
      if (constructor != null) {
        return constructor.body;
      }
    }
    {
      MethodDeclaration method = node.thisOrAncestorOfType<MethodDeclaration>();
      if (method != null) {
        return method.body;
      }
    }
    return null;
  }

  void _addAssistFromBuilder(DartChangeBuilder builder, AssistKind kind,
      {List args = null}) {
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty) {
      _coverageMarker();
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    assists.add(new Assist(kind, change));
  }

  Future<void> _addProposal_addTypeAnnotation_DeclaredIdentifier() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    DeclaredIdentifier declaredIdentifier =
        node.thisOrAncestorOfType<DeclaredIdentifier>();
    if (declaredIdentifier == null) {
      ForStatement forEach = node.thisOrAncestorMatching(
          (node) => node is ForStatement && node.forLoopParts is ForEachParts);
      ForEachParts forEachParts = forEach?.forLoopParts;
      int offset = node.offset;
      if (forEach != null &&
          forEachParts.iterable != null &&
          offset < forEachParts.iterable.offset) {
        declaredIdentifier = forEachParts is ForEachPartsWithDeclaration
            ? forEachParts.loopVariable
            : null;
      }
    }
    if (declaredIdentifier == null) {
      _coverageMarker();
      return;
    }
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      _coverageMarker();
      return;
    }
    DartType type = declaredIdentifier.identifier.staticType;
    if (type is! InterfaceType && type is! FunctionType) {
      _coverageMarker();
      return;
    }
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    bool validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      Token keyword = declaredIdentifier.keyword;
      if (keyword.keyword == Keyword.VAR) {
        builder.addReplacement(range.token(keyword), (DartEditBuilder builder) {
          validChange = builder.writeType(type);
        });
      } else {
        builder.addInsertion(declaredIdentifier.identifier.offset,
            (DartEditBuilder builder) {
          validChange = builder.writeType(type);
          builder.write(' ');
        });
      }
    });
    if (validChange) {
      _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
    }
  }

  Future<void> _addProposal_addTypeAnnotation_SimpleFormalParameter() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = this.node;
    // should be the name of a simple parameter
    if (node is! SimpleIdentifier || node.parent is! SimpleFormalParameter) {
      _coverageMarker();
      return;
    }
    SimpleIdentifier name = node;
    SimpleFormalParameter parameter = node.parent;
    // the parameter should not have a type
    if (parameter.type != null) {
      _coverageMarker();
      return;
    }
    // prepare the type
    DartType type = parameter.declaredElement.type;
    // TODO(scheglov) If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType) {
      _coverageMarker();
      return;
    }
    // prepare type source
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    bool validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(name.offset, (DartEditBuilder builder) {
        validChange = builder.writeType(type);
        builder.write(' ');
      });
    });
    if (validChange) {
      _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
    }
  }

  Future<void> _addProposal_addTypeAnnotation_VariableDeclaration() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = this.node;
    // prepare VariableDeclarationList
    VariableDeclarationList declarationList =
        node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declarationList == null) {
      _coverageMarker();
      return;
    }
    // may be has type annotation already
    if (declarationList.type != null) {
      _coverageMarker();
      return;
    }
    // prepare single VariableDeclaration
    List<VariableDeclaration> variables = declarationList.variables;
    if (variables.length != 1) {
      _coverageMarker();
      return;
    }
    VariableDeclaration variable = variables[0];
    // must be not after the name of the variable
    if (selectionOffset > variable.name.end) {
      _coverageMarker();
      return;
    }
    // we need an initializer to get the type from
    Expression initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return;
    }
    DartType type = initializer.staticType;
    // prepare type source
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType) {
      _coverageMarker();
      return;
    }
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    bool validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      Token keyword = declarationList.keyword;
      if (keyword?.keyword == Keyword.VAR) {
        builder.addReplacement(range.token(keyword), (DartEditBuilder builder) {
          validChange = builder.writeType(type);
        });
      } else {
        builder.addInsertion(variable.offset, (DartEditBuilder builder) {
          validChange = builder.writeType(type);
          builder.write(' ');
        });
      }
    });
    if (validChange) {
      _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
    }
  }

  Future<void> _addProposal_assignToLocalVariable() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare enclosing ExpressionStatement
    ExpressionStatement expressionStatement;
    for (AstNode node = this.node; node != null; node = node.parent) {
      if (node is ExpressionStatement) {
        expressionStatement = node;
        break;
      }
      if (node is ArgumentList ||
          node is AssignmentExpression ||
          node is Statement ||
          node is ThrowExpression) {
        _coverageMarker();
        return;
      }
    }
    if (expressionStatement == null) {
      _coverageMarker();
      return;
    }
    // prepare expression
    Expression expression = expressionStatement.expression;
    int offset = expression.offset;
    // prepare expression type
    DartType type = expression.staticType;
    if (type.isVoid) {
      _coverageMarker();
      return;
    }
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
    expression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);

    if (suggestions.isNotEmpty) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          builder.write('var ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
    }
  }

  Future<void> _addProposal_convertAddAllToSpread() async {
    AstNode node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      _coverageMarker();
      return;
    }
    SimpleIdentifier name = node;
    MethodInvocation invocation = node.parent;
    if (name != invocation.methodName ||
        name.name != 'addAll' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      _coverageMarker();
      return;
    }
    CascadeExpression cascade = invocation.thisOrAncestorOfType();
    NodeList<Expression> sections = cascade.cascadeSections;
    Expression target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      _coverageMarker();
      return;
    }

    bool isEmptyListLiteral(Expression expression) =>
        expression is ListLiteral && expression.elements.isEmpty;

    ListLiteral list = target;
    Expression argument = invocation.argumentList.arguments[0];
    String elementText;
    AssistKind kind = DartAssistKind.CONVERT_TO_SPREAD;
    List<String> args = null;
    if (argument is BinaryExpression &&
        argument.operator.type == TokenType.QUESTION_QUESTION) {
      Expression right = argument.rightOperand;
      if (isEmptyListLiteral(right)) {
        // ..addAll(things ?? const [])
        // ..addAll(things ?? [])
        elementText = '...?${utils.getNodeText(argument.leftOperand)}';
      }
    } else if (experimentStatus.control_flow_collections &&
        argument is ConditionalExpression) {
      Expression elseExpression = argument.elseExpression;
      if (isEmptyListLiteral(elseExpression)) {
        // ..addAll(condition ? things : const [])
        // ..addAll(condition ? things : [])
        String conditionText = utils.getNodeText(argument.condition);
        String thenText = utils.getNodeText(argument.thenExpression);
        elementText = 'if ($conditionText) ...$thenText';
      }
    } else if (argument is ListLiteral) {
      // ..addAll([ ... ])
      NodeList<CollectionElement> elements = argument.elements;
      if (elements.isEmpty) {
        // TODO(brianwilkerson) Consider adding a cleanup for the empty list
        //  case. We can essentially remove the whole invocation because it does
        //  nothing.
        return;
      }
      int startOffset = elements.first.offset;
      int endOffset = elements.last.end;
      elementText = utils.getText(startOffset, endOffset - startOffset);
      kind = DartAssistKind.INLINE_INVOCATION;
      args = ['addAll'];
    }
    elementText ??= '...${utils.getNodeText(argument)}';
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      if (list.elements.isNotEmpty) {
        // ['a']..addAll(['b', 'c']);
        builder.addSimpleInsertion(list.elements.last.end, ', $elementText');
      } else {
        // []..addAll(['b', 'c']);
        builder.addSimpleInsertion(list.leftBracket.end, elementText);
      }
      builder.addDeletion(range.node(invocation));
    });
    _addAssistFromBuilder(changeBuilder, kind, args: args);
  }

  Future<void> _addProposal_convertClassToMixin() async {
    ClassDeclaration classDeclaration =
        node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    if (selectionOffset > classDeclaration.name.end ||
        selectionEnd < classDeclaration.classKeyword.offset) {
      return;
    }
    if (classDeclaration.members
        .any((member) => member is ConstructorDeclaration)) {
      return;
    }
    _SuperclassReferenceFinder finder = new _SuperclassReferenceFinder();
    classDeclaration.accept(finder);
    List<ClassElement> referencedClasses = finder.referencedClasses;
    List<InterfaceType> superclassConstraints = <InterfaceType>[];
    List<InterfaceType> interfaces = <InterfaceType>[];

    ClassElement classElement = classDeclaration.declaredElement;
    for (InterfaceType type in classElement.mixins) {
      if (referencedClasses.contains(type.element)) {
        superclassConstraints.add(type);
      } else {
        interfaces.add(type);
      }
    }
    ExtendsClause extendsClause = classDeclaration.extendsClause;
    if (extendsClause != null) {
      if (referencedClasses.length > superclassConstraints.length) {
        superclassConstraints.insert(0, classElement.supertype);
      } else {
        interfaces.insert(0, classElement.supertype);
      }
    }
    interfaces.addAll(classElement.interfaces);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(
          range.startStart(
              classDeclaration.abstractKeyword ?? classDeclaration.classKeyword,
              classDeclaration.leftBracket), (DartEditBuilder builder) {
        builder.write('mixin ');
        builder.write(classDeclaration.name.name);
        builder.writeTypeParameters(
            classDeclaration.declaredElement.typeParameters);
        builder.writeTypes(superclassConstraints, prefix: ' on ');
        builder.writeTypes(interfaces, prefix: ' implements ');
        builder.write(' ');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_CLASS_TO_MIXIN);
  }

  Future<void> _addProposal_convertConditionalExpressionToIfElement() async {
    AstNode node = this.node.thisOrAncestorOfType<ConditionalExpression>();
    if (node == null) {
      _coverageMarker();
      return;
    }
    AstNode nodeToReplace = node;
    AstNode parent = node.parent;
    while (parent is ParenthesizedExpression) {
      nodeToReplace = parent;
      parent = parent.parent;
    }
    if (parent is ListLiteral || (parent is SetOrMapLiteral && parent.isSet)) {
      ConditionalExpression conditional = node;
      Expression condition = conditional.condition.unParenthesized;
      Expression thenExpression = conditional.thenExpression.unParenthesized;
      Expression elseExpression = conditional.elseExpression.unParenthesized;

      DartChangeBuilder changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(range.node(nodeToReplace),
            (DartEditBuilder builder) {
          builder.write('if (');
          builder.write(utils.getNodeText(condition));
          builder.write(') ');
          builder.write(utils.getNodeText(thenExpression));
          builder.write(' else ');
          builder.write(utils.getNodeText(elseExpression));
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_IF_ELEMENT);
    }
  }

  Future<void> _addProposal_convertDocumentationIntoBlock() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Comment comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null || !comment.isDocumentation) {
      return;
    }
    var tokens = comment.tokens;
    if (tokens.isEmpty ||
        tokens.any((Token token) =>
            token is! DocumentationCommentToken ||
            token.type != TokenType.SINGLE_LINE_COMMENT)) {
      return;
    }
    String prefix = utils.getNodePrefix(comment);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(comment), (DartEditBuilder builder) {
        builder.writeln('/**');
        for (Token token in comment.tokens) {
          builder.write(prefix);
          builder.write(' *');
          builder.writeln(token.lexeme.substring('///'.length));
        }
        builder.write(prefix);
        builder.write(' */');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK);
  }

  Future<void> _addProposal_convertDocumentationIntoLine() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Comment comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null ||
        !comment.isDocumentation ||
        comment.tokens.length != 1) {
      _coverageMarker();
      return;
    }
    Token token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      _coverageMarker();
      return;
    }
    String text = token.lexeme;
    List<String> lines = text.split('\n');
    String prefix = utils.getNodePrefix(comment);
    List<String> newLines = <String>[];
    bool firstLine = true;
    String linePrefix = '';
    for (String line in lines) {
      if (firstLine) {
        firstLine = false;
        String expectedPrefix = '/**';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return;
        }
        line = line.substring(expectedPrefix.length).trim();
        if (line.isNotEmpty) {
          newLines.add('/// $line');
          linePrefix = eol + prefix;
        }
      } else {
        if (line.startsWith(prefix + ' */')) {
          break;
        }
        String expectedPrefix = prefix + ' *';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return;
        }
        line = line.substring(expectedPrefix.length);
        if (line.isEmpty) {
          newLines.add('$linePrefix///');
        } else {
          newLines.add('$linePrefix///$line');
        }
        linePrefix = eol + prefix;
      }
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(comment), (DartEditBuilder builder) {
        for (String newLine in newLines) {
          builder.write(newLine);
        }
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE);
  }

  Future<void> _addProposal_convertIntoFinalField() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Find the enclosing getter.
    MethodDeclaration getter;
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodDeclaration) {
        getter = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (getter == null || !getter.isGetter) {
      return;
    }
    // Check that there is no corresponding setter.
    {
      ExecutableElement element = getter.declaredElement;
      if (element == null) {
        return;
      }
      Element enclosing = element.enclosingElement;
      if (enclosing is ClassElement) {
        if (enclosing.getSetter(element.name) != null) {
          return;
        }
      }
    }
    // Try to find the returned expression.
    Expression expression;
    {
      FunctionBody body = getter.body;
      if (body is ExpressionFunctionBody) {
        expression = body.expression;
      } else if (body is BlockFunctionBody) {
        List<Statement> statements = body.block.statements;
        if (statements.length == 1) {
          Statement statement = statements.first;
          if (statement is ReturnStatement) {
            expression = statement.expression;
          }
        }
      }
    }
    // Use the returned expression as the field initializer.
    if (expression != null) {
      String code = 'final';
      if (getter.returnType != null) {
        code += ' ' + _getNodeText(getter.returnType);
      }
      code += ' ' + _getNodeText(getter.name);
      if (expression is! NullLiteral) {
        code += ' = ' + _getNodeText(expression);
      }
      code += ';';
      SourceRange replacementRange =
          range.startEnd(getter.returnType ?? getter.propertyKeyword, getter);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(replacementRange, code);
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_INTO_FINAL_FIELD);
    }
  }

  Future<void> _addProposal_convertIntoGetter() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Find the enclosing field declaration.
    FieldDeclaration fieldDeclaration;
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is FieldDeclaration) {
        fieldDeclaration = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is VariableDeclaration ||
          n is VariableDeclarationList ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (fieldDeclaration == null) {
      return;
    }
    // The field must be final and has only one variable.
    VariableDeclarationList fieldList = fieldDeclaration.fields;
    if (!fieldList.isFinal || fieldList.variables.length != 1) {
      return;
    }
    VariableDeclaration field = fieldList.variables.first;
    // Prepare the initializer.
    Expression initializer = field.initializer;
    if (initializer == null) {
      return;
    }
    // Add proposal.
    String code = '';
    if (fieldList.type != null) {
      code += _getNodeText(fieldList.type) + ' ';
    }
    code += 'get';
    code += ' ' + _getNodeText(field.name);
    code += ' => ' + _getNodeText(initializer);
    code += ';';
    SourceRange replacementRange =
        range.startEnd(fieldList.keyword, fieldDeclaration);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(replacementRange, code);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_GETTER);
  }

  Future<void> _addProposal_convertListConstructorToListLiteral() async {
    //
    // Ensure that this is the default constructor defined on `List`.
    //
    InstanceCreationExpression creation = node.thisOrAncestorOfType();
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.staticType.element != typeProvider.listType.element ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty) {
      _coverageMarker();
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    TypeArgumentList constructorTypeArguments =
        creation.constructorName.type.typeArguments;
    //
    // Build the change and return the assist.
    //
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(creation), (DartEditBuilder builder) {
        if (constructorTypeArguments != null) {
          builder.write(_getNodeText(constructorTypeArguments));
        }
        builder.write('[]');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_TO_LIST_LITERAL);
  }

  Future<void> _addProposal_convertListToSetToSetLiteral() async {
    //
    // Ensure that this is an invocation of `toSet` on a list literal.
    //
    if (node is! SimpleIdentifier) {
      _coverageMarker();
      return;
    }
    AstNode parent = node.parent;
    if (parent is! MethodInvocation) {
      _coverageMarker();
      return;
    }
    MethodInvocation invocation = parent as MethodInvocation;
    if (invocation.methodName != node ||
        invocation.methodName.name != 'toSet') {
      _coverageMarker();
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    Expression target = invocation.target;
    bool hasTypeArgs;
    SourceRange openRange;
    SourceRange closeRange;
    if (target is ListLiteral) {
      hasTypeArgs = target.typeArguments != null;
      openRange = range.token(target.leftBracket);
      closeRange = range.startEnd(target.rightBracket, invocation);
    } else {
      _coverageMarker();
      return;
    }
    //
    // Build the change and return the assist.
    //
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      if (hasTypeArgs || _listHasUnambiguousElement(target)) {
        builder.addSimpleReplacement(openRange, '{');
      } else {
        builder.addSimpleReplacement(openRange, '<dynamic>{');
      }
      builder.addSimpleReplacement(closeRange, '}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_TO_SET_LITERAL);
  }

  Future<void> _addProposal_convertMapConstructorToMapLiteral() async {
    bool isMapClass(Element element) =>
        element is ClassElement &&
        (element == typeProvider.mapType.element ||
            (element.name == 'LinkedHashMap' &&
                element.library.name == 'dart.collection'));
    //
    // Ensure that this is the default constructor defined on either `Map` or
    // `LinkedHashMap`.
    //
    InstanceCreationExpression creation = node.thisOrAncestorOfType();
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty ||
        !isMapClass(creation.staticType.element)) {
      _coverageMarker();
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    TypeArgumentList constructorTypeArguments =
        creation.constructorName.type.typeArguments;
    //
    // Build the change and return the assist.
    //
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(creation), (DartEditBuilder builder) {
        if (constructorTypeArguments != null) {
          builder.write(_getNodeText(constructorTypeArguments));
        }
        builder.write('{}');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_TO_MAP_LITERAL);
  }

  Future<void> _addProposal_convertMapFromIterableToForLiteral() async {
    //
    // Ensure that the selection is inside an invocation of Map.fromIterable.
    //
    InstanceCreationExpression creation =
        node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      _coverageMarker();
      return;
    }
    ConstructorElement element = creation.staticElement;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != typeProvider.mapType.element) {
      _coverageMarker();
      return;
    }
    //
    // Ensure that the arguments have the right form.
    //
    NodeList<Expression> arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      _coverageMarker();
      return;
    }
    Expression iterator = arguments[0].unParenthesized;
    Expression secondArg = arguments[1];
    Expression thirdArg = arguments[2];

    Expression extractBody(FunctionExpression expression) {
      FunctionBody body = expression.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else if (body is BlockFunctionBody) {
        NodeList<Statement> statements = body.block.statements;
        if (statements.length == 1) {
          Statement statement = statements[0];
          if (statement is ReturnStatement) {
            return statement.expression;
          }
        }
      }
      return null;
    }

    FunctionExpression extractClosure(String name, Expression argument) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        Expression expression = argument.expression.unParenthesized;
        if (expression is FunctionExpression) {
          NodeList<FormalParameter> parameters =
              expression.parameters.parameters;
          if (parameters.length == 1 && parameters[0].isRequiredPositional) {
            if (extractBody(expression) != null) {
              return expression;
            }
          }
        }
      }
      return null;
    }

    FunctionExpression keyClosure =
        extractClosure('key', secondArg) ?? extractClosure('key', thirdArg);
    FunctionExpression valueClosure =
        extractClosure('value', thirdArg) ?? extractClosure('value', secondArg);
    if (keyClosure == null || valueClosure == null) {
      _coverageMarker();
      return;
    }
    //
    // Compute the loop variable name and convert the key and value closures if
    // necessary.
    //
    SimpleFormalParameter keyParameter = keyClosure.parameters.parameters[0];
    String keyParameterName = keyParameter.identifier.name;
    SimpleFormalParameter valueParameter =
        valueClosure.parameters.parameters[0];
    String valueParameterName = valueParameter.identifier.name;
    Expression keyBody = extractBody(keyClosure);
    String keyExpressionText = utils.getNodeText(keyBody);
    Expression valueBody = extractBody(valueClosure);
    String valueExpressionText = utils.getNodeText(valueBody);

    String loopVariableName;
    if (keyParameterName == valueParameterName) {
      loopVariableName = keyParameterName;
    } else {
      _ParameterReferenceFinder keyFinder =
          new _ParameterReferenceFinder(keyParameter.declaredElement);
      keyBody.accept(keyFinder);

      _ParameterReferenceFinder valueFinder =
          new _ParameterReferenceFinder(valueParameter.declaredElement);
      valueBody.accept(valueFinder);

      String computeUnusedVariableName() {
        String candidate = 'e';
        var index = 1;
        while (keyFinder.referencesName(candidate) ||
            valueFinder.referencesName(candidate)) {
          candidate = 'e${index++}';
        }
        return candidate;
      }

      if (valueFinder.isParameterUnreferenced) {
        if (valueFinder.referencesName(keyParameterName)) {
          // The name of the value parameter is not used, but we can't use the
          // name of the key parameter because doing so would hide a variable
          // referenced in the value expression.
          loopVariableName = computeUnusedVariableName();
          keyExpressionText = keyFinder.replaceName(
              keyExpressionText, loopVariableName, keyBody.offset);
        } else {
          loopVariableName = keyParameterName;
        }
      } else if (keyFinder.isParameterUnreferenced) {
        if (keyFinder.referencesName(valueParameterName)) {
          // The name of the key parameter is not used, but we can't use the
          // name of the value parameter because doing so would hide a variable
          // referenced in the key expression.
          loopVariableName = computeUnusedVariableName();
          valueExpressionText = valueFinder.replaceName(
              valueExpressionText, loopVariableName, valueBody.offset);
        } else {
          loopVariableName = valueParameterName;
        }
      } else {
        // The names are different and both are used. We need to find a name
        // that would not change the resolution of any other identifiers in
        // either the key or value expressions.
        loopVariableName = computeUnusedVariableName();
        keyExpressionText = keyFinder.replaceName(
            keyExpressionText, loopVariableName, keyBody.offset);
        valueExpressionText = valueFinder.replaceName(
            valueExpressionText, loopVariableName, valueBody.offset);
      }
    }
    //
    // Construct the edit.
    //
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(creation), (DartEditBuilder builder) {
        builder.write('{ for (var ');
        builder.write(loopVariableName);
        builder.write(' in ');
        builder.write(utils.getNodeText(iterator));
        builder.write(') ');
        builder.write(keyExpressionText);
        builder.write(' : ');
        builder.write(valueExpressionText);
        builder.write(' }');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_TO_FOR_ELEMENT);
  }

  Future<void> _addProposal_convertPartOfToUri() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    PartOfDirective directive = node.thisOrAncestorOfType<PartOfDirective>();
    if (directive == null || directive.libraryName == null) {
      return;
    }
    String libraryPath = context.resolveResult.libraryElement.source.fullName;
    String partPath = context.resolveResult.path;
    String relativePath = relative(libraryPath, from: dirname(partPath));
    String uri = new Uri.file(relativePath).toString();
    SourceRange replacementRange = range.node(directive.libraryName);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(replacementRange, "'$uri'");
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_PART_OF_TO_URI);
  }

  Future<void> _addProposal_convertSetConstructorToSetLiteral() async {
    //
    // Ensure that this is one of the constructors defined on `Set`.
    //
    InstanceCreationExpression creation = node.thisOrAncestorOfType();
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.staticType.element != typeProvider.setType.element) {
      // TODO(brianwilkerson) Consider also accepting uses of LinkedHashSet.
      _coverageMarker();
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    SimpleIdentifier name = creation.constructorName.name;
    TypeArgumentList constructorTypeArguments =
        creation.constructorName.type.typeArguments;
    TypeArgumentList elementTypeArguments;
    SourceRange elementsRange;
    if (name == null) {
      // Handle an invocation of the default constructor `Set()`.
    } else if (name.name == 'from' || name.name == 'of') {
      // Handle an invocation of the constructor `Set.from()` or `Set.of()`.
      NodeList<Expression> arguments = creation.argumentList.arguments;
      if (arguments.length != 1) {
        _coverageMarker();
        return;
      }
      if (arguments[0] is ListLiteral) {
        ListLiteral elements = arguments[0] as ListLiteral;
        elementTypeArguments = elements.typeArguments;
        elementsRange =
            range.endStart(elements.leftBracket, elements.rightBracket);
      } else {
        // TODO(brianwilkerson) Consider handling other iterables. Literal sets
        //  could be treated like lists, and arbitrary iterables by using a
        //  spread.
        _coverageMarker();
        return;
      }
    } else {
      // Invocation of an unhandled constructor.
      _coverageMarker();
      return;
    }
    new Map();
    //
    // Determine whether type arguments are strictly required in cases where no
    // type arguments were explicitly provided.
    //
    bool hasUnambiguousElement() {
      NodeList<Expression> arguments = creation.argumentList.arguments;
      if (arguments == null || arguments.isEmpty) {
        return false;
      }
      return _listHasUnambiguousElement(arguments[0]);
    }

    bool setWouldBeInferred() {
      AstNode parent = creation.parent;
      if (parent is VariableDeclaration) {
        AstNode parent2 = parent.parent;
        if (parent2 is VariableDeclarationList &&
            parent2.type?.type?.element == typeProvider.setType.element) {
          return true;
        }
      }
      return hasUnambiguousElement();
    }

    //
    // Build the change and return the assist.
    //
    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(creation), (DartEditBuilder builder) {
        if (constructorTypeArguments != null) {
          builder.write(_getNodeText(constructorTypeArguments));
        } else if (elementTypeArguments != null) {
          builder.write(_getNodeText(elementTypeArguments));
        } else if (!setWouldBeInferred()) {
          builder.write('<dynamic>');
        }
        builder.write('{');
        if (elementsRange != null) {
          builder.write(_getRangeText(elementsRange));
        }
        builder.write('}');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_TO_SET_LITERAL);
  }

  Future<void> _addProposal_convertToAsyncFunctionBody() async {
    FunctionBody body = getEnclosingFunctionBody();
    if (body == null ||
        body is EmptyFunctionBody ||
        body.isAsynchronous ||
        body.isGenerator) {
      _coverageMarker();
      return;
    }

    // Function bodies can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in a function body.
    if (body is BlockFunctionBody &&
        selectionOffset > body.block.beginToken.end) {
      return;
    }
    if (body is ExpressionFunctionBody &&
        selectionOffset > body.beginToken.end) {
      return;
    }

    AstNode parent = body.parent;
    if (parent is ConstructorDeclaration) {
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.convertFunctionFromSyncToAsync(body, typeProvider);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_ASYNC_BODY);
  }

  Future<void> _addProposal_convertToBlockFunctionBody() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    FunctionBody body = getEnclosingFunctionBody();
    // prepare expression body
    if (body is! ExpressionFunctionBody || body.isGenerator) {
      _coverageMarker();
      return;
    }

    Expression returnValue = (body as ExpressionFunctionBody).expression;

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnValue.offset) {
      _coverageMarker();
      return;
    }

    DartType returnValueType = returnValue.staticType;
    String returnValueCode = _getNodeText(returnValue);
    // prepare prefix
    String prefix = utils.getNodePrefix(body.parent);
    String indent = utils.getIndent(1);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(body), (DartEditBuilder builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('{$eol$prefix$indent');
        if (!returnValueType.isVoid && !returnValueType.isBottom) {
          builder.write('return ');
        }
        builder.write(returnValueCode);
        builder.write(';');
        builder.selectHere();
        builder.write('$eol$prefix}');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_BLOCK_BODY);
  }

  Future<void> _addProposal_convertToDoubleQuotedString() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    await _convertQuotes(false, DartAssistKind.CONVERT_TO_DOUBLE_QUOTED_STRING);
  }

  Future<void> _addProposal_convertToExpressionFunctionBody() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare current body
    FunctionBody body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody || body.isGenerator) {
      _coverageMarker();
      return;
    }
    // prepare return statement
    List<Statement> statements = (body as BlockFunctionBody).block.statements;
    if (statements.length != 1) {
      _coverageMarker();
      return;
    }
    Statement onlyStatement = statements.first;
    // prepare returned expression
    Expression returnExpression;
    if (onlyStatement is ReturnStatement) {
      returnExpression = onlyStatement.expression;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;
    }
    if (returnExpression == null) {
      _coverageMarker();
      return;
    }

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnExpression.offset) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(body), (DartEditBuilder builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('=> ');
        builder.write(_getNodeText(returnExpression));
        if (body.parent is! FunctionExpression ||
            body.parent.parent is FunctionDeclaration) {
          builder.write(';');
        }
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  Future<void> _addProposal_convertToFieldParameter() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (node == null) {
      return;
    }
    // prepare ConstructorDeclaration
    ConstructorDeclaration constructor =
        node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }
    FormalParameterList parameterList = constructor.parameters;
    List<ConstructorInitializer> initializers = constructor.initializers;
    // prepare parameter
    SimpleFormalParameter parameter;
    if (node.parent is SimpleFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      parameter = node.parent;
    }
    if (node is SimpleIdentifier &&
        node.parent is ConstructorFieldInitializer) {
      String name = (node as SimpleIdentifier).name;
      ConstructorFieldInitializer initializer = node.parent;
      if (initializer.expression == node) {
        for (FormalParameter formalParameter in parameterList.parameters) {
          if (formalParameter is SimpleFormalParameter &&
              formalParameter.identifier.name == name) {
            parameter = formalParameter;
          }
        }
      }
    }
    // analyze parameter
    if (parameter != null) {
      String parameterName = parameter.identifier.name;
      ParameterElement parameterElement = parameter.declaredElement;
      // check number of references
      {
        int numOfReferences = 0;
        AstVisitor visitor =
            new _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
          if (node.staticElement == parameterElement) {
            numOfReferences++;
          }
        });
        for (ConstructorInitializer initializer in initializers) {
          initializer.accept(visitor);
        }
        if (numOfReferences != 1) {
          return;
        }
      }
      // find the field initializer
      ConstructorFieldInitializer parameterInitializer;
      for (ConstructorInitializer initializer in initializers) {
        if (initializer is ConstructorFieldInitializer) {
          Expression expression = initializer.expression;
          if (expression is SimpleIdentifier &&
              expression.name == parameterName) {
            parameterInitializer = initializer;
          }
        }
      }
      if (parameterInitializer == null) {
        return;
      }
      String fieldName = parameterInitializer.fieldName.name;

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // replace parameter
        builder.addSimpleReplacement(range.node(parameter), 'this.$fieldName');
        // remove initializer
        int initializerIndex = initializers.indexOf(parameterInitializer);
        if (initializers.length == 1) {
          builder
              .addDeletion(range.endEnd(parameterList, parameterInitializer));
        } else {
          if (initializerIndex == 0) {
            ConstructorInitializer next = initializers[initializerIndex + 1];
            builder.addDeletion(range.startStart(parameterInitializer, next));
          } else {
            ConstructorInitializer prev = initializers[initializerIndex - 1];
            builder.addDeletion(range.endEnd(prev, parameterInitializer));
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_FIELD_PARAMETER);
    }
  }

  Future<void> _addProposal_convertToForIndexLoop() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // find enclosing ForEachStatement
    ForStatement forEachStatement = node.thisOrAncestorMatching(
        (node) => node is ForStatement && node.forLoopParts is ForEachParts);
    if (forEachStatement == null) {
      _coverageMarker();
      return;
    }
    ForEachParts forEachParts = forEachStatement.forLoopParts;
    if (selectionOffset < forEachStatement.offset ||
        forEachStatement.rightParenthesis.end < selectionOffset) {
      _coverageMarker();
      return;
    }
    // loop should declare variable
    DeclaredIdentifier loopVariable =
        forEachParts is ForEachPartsWithDeclaration
            ? forEachParts.loopVariable
            : null;
    if (loopVariable == null) {
      _coverageMarker();
      return;
    }
    // iterable should be VariableElement
    String listName;
    Expression iterable = forEachParts.iterable;
    if (iterable is SimpleIdentifier &&
        iterable.staticElement is VariableElement) {
      listName = iterable.name;
    } else {
      _coverageMarker();
      return;
    }
    // iterable should be List
    {
      DartType iterableType = iterable.staticType;
      InterfaceType listType = typeProvider.listType;
      if (iterableType is! InterfaceType ||
          iterableType.element != listType.element) {
        _coverageMarker();
        return;
      }
    }
    // body should be Block
    if (forEachStatement.body is! Block) {
      _coverageMarker();
      return;
    }
    Block body = forEachStatement.body;
    // prepare a name for the index variable
    String indexName;
    {
      Set<String> conflicts =
          utils.findPossibleLocalVariableConflicts(forEachStatement.offset);
      if (!conflicts.contains('i')) {
        indexName = 'i';
      } else if (!conflicts.contains('j')) {
        indexName = 'j';
      } else if (!conflicts.contains('k')) {
        indexName = 'k';
      } else {
        _coverageMarker();
        return;
      }
    }
    // prepare environment
    String prefix = utils.getNodePrefix(forEachStatement);
    String indent = utils.getIndent(1);
    int firstBlockLine = utils.getLineContentEnd(body.leftBracket.end);
    // add change
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // TODO(brianwilkerson) Create linked positions for the loop variable.
      builder.addSimpleReplacement(
          range.startEnd(forEachStatement, forEachStatement.rightParenthesis),
          'for (int $indexName = 0; $indexName < $listName.length; $indexName++)');
      builder.addSimpleInsertion(firstBlockLine,
          '$prefix$indent$loopVariable = $listName[$indexName];$eol');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  Future<void> _addProposal_convertToGenericFunctionSyntax() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = this.node;
    while (node != null) {
      if (node is FunctionTypeAlias) {
        await _convertFunctionTypeAliasToGenericTypeAlias(node);
        return;
      } else if (node is FunctionTypedFormalParameter) {
        await _convertFunctionTypedFormalParameterToSimpleFormalParameter(node);
        return;
      } else if (node is FormalParameterList) {
        // It would be confusing for this assist to alter a surrounding context
        // when the selection is inside a parameter list.
        return;
      }
      node = node.parent;
    }
  }

  Future<void> _addProposal_convertToIntLiteral() async {
    if (node is! DoubleLiteral) {
      _coverageMarker();
      return;
    }
    DoubleLiteral literal = node;
    int intValue;
    try {
      intValue = literal.value?.truncate();
    } catch (e) {
      // Double cannot be converted to int
    }
    if (intValue == null || intValue != literal.value) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(new SourceRange(literal.offset, literal.length),
          (DartEditBuilder builder) {
        builder.write('$intValue');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_TO_INT_LITERAL);
  }

  Future<void> _addProposal_convertToIsNot_onIs() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // may be child of "is"
    AstNode node = this.node;
    while (node != null && node is! IsExpression) {
      node = node.parent;
    }
    // prepare "is"
    if (node is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = node as IsExpression;
    if (isExpression.notOperator != null) {
      _coverageMarker();
      return;
    }
    // prepare enclosing ()
    AstNode parent = isExpression.parent;
    if (parent is! ParenthesizedExpression) {
      _coverageMarker();
      return;
    }
    ParenthesizedExpression parExpression = parent as ParenthesizedExpression;
    // prepare enclosing !()
    AstNode parent2 = parent.parent;
    if (parent2 is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefExpression = parent2 as PrefixExpression;
    if (prefExpression.operator.type != TokenType.BANG) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      if (getExpressionParentPrecedence(prefExpression) >=
          Precedence.relational) {
        builder.addDeletion(range.token(prefExpression.operator));
      } else {
        builder.addDeletion(
            range.startEnd(prefExpression, parExpression.leftParenthesis));
        builder.addDeletion(
            range.startEnd(parExpression.rightParenthesis, prefExpression));
      }
      builder.addSimpleInsertion(isExpression.isOperator.end, '!');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  Future<void> _addProposal_convertToIsNot_onNot() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // may be () in prefix expression
    AstNode node = this.node;
    if (node is ParenthesizedExpression && node.parent is PrefixExpression) {
      node = node.parent;
    }
    // prepare !()
    if (node is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefExpression = node as PrefixExpression;
    // should be ! operator
    if (prefExpression.operator.type != TokenType.BANG) {
      _coverageMarker();
      return;
    }
    // prepare !()
    Expression operand = prefExpression.operand;
    if (operand is! ParenthesizedExpression) {
      _coverageMarker();
      return;
    }
    ParenthesizedExpression parExpression = operand as ParenthesizedExpression;
    operand = parExpression.expression;
    // prepare "is"
    if (operand is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = operand as IsExpression;
    if (isExpression.notOperator != null) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      if (getExpressionParentPrecedence(prefExpression) >=
          Precedence.relational) {
        builder.addDeletion(range.token(prefExpression.operator));
      } else {
        builder.addDeletion(
            range.startEnd(prefExpression, parExpression.leftParenthesis));
        builder.addDeletion(
            range.startEnd(parExpression.rightParenthesis, prefExpression));
      }
      builder.addSimpleInsertion(isExpression.isOperator.end, '!');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  /**
   * Converts "!isEmpty" -> "isNotEmpty" if possible.
   */
  Future<void> _addProposal_convertToIsNotEmpty() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare "expr.isEmpty"
    AstNode isEmptyAccess = null;
    SimpleIdentifier isEmptyIdentifier = null;
    if (node is SimpleIdentifier) {
      SimpleIdentifier identifier = node as SimpleIdentifier;
      AstNode parent = identifier.parent;
      // normal case (but rare)
      if (parent is PropertyAccess) {
        isEmptyIdentifier = parent.propertyName;
        isEmptyAccess = parent;
      }
      // usual case
      if (parent is PrefixedIdentifier) {
        isEmptyIdentifier = parent.identifier;
        isEmptyAccess = parent;
      }
    }
    if (isEmptyIdentifier == null) {
      _coverageMarker();
      return;
    }
    // should be "isEmpty"
    Element propertyElement = isEmptyIdentifier.staticElement;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      _coverageMarker();
      return;
    }
    // should have "isNotEmpty"
    Element propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      _coverageMarker();
      return;
    }
    // should be in PrefixExpression
    if (isEmptyAccess.parent is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefixExpression =
        isEmptyAccess.parent as PrefixExpression;
    // should be !
    if (prefixExpression.operator.type != TokenType.BANG) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(
          range.startStart(prefixExpression, prefixExpression.operand));
      builder.addSimpleReplacement(range.node(isEmptyIdentifier), 'isNotEmpty');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  Future<void> _addProposal_convertToMultilineString() async {
    var node = this.node;
    if (node is InterpolationElement) {
      node = (node as InterpolationElement).parent;
    }
    if (node is SingleStringLiteral) {
      SingleStringLiteral literal = node;
      if (!literal.isMultiline) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (builder) {
          var newQuote = literal.isSingleQuoted ? "'''" : '"""';
          builder.addReplacement(
            SourceRange(literal.offset + (literal.isRaw ? 1 : 0), 1),
            (builder) {
              builder.writeln(newQuote);
            },
          );
          builder.addSimpleReplacement(
            SourceRange(literal.end - 1, 1),
            newQuote,
          );
        });
        _addAssistFromBuilder(
          changeBuilder,
          DartAssistKind.CONVERT_TO_MULTILINE_STRING,
        );
      }
    }
  }

  Future<void> _addProposal_convertToNormalParameter() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (node is SimpleIdentifier &&
        node.parent is FieldFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = node.parent.parent.parent;
      FormalParameterList parameterList = node.parent.parent;
      FieldFormalParameter parameter = node.parent;
      ParameterElement parameterElement = parameter.declaredElement;
      String name = (node as SimpleIdentifier).name;
      // prepare type
      DartType type = parameterElement.type;

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // replace parameter
        if (type.isDynamic) {
          builder.addSimpleReplacement(range.node(parameter), name);
        } else {
          builder.addReplacement(range.node(parameter),
              (DartEditBuilder builder) {
            builder.writeType(type);
            builder.write(' ');
            builder.write(name);
          });
        }
        // add field initializer
        List<ConstructorInitializer> initializers = constructor.initializers;
        if (initializers.isEmpty) {
          builder.addSimpleInsertion(parameterList.end, ' : $name = $name');
        } else {
          builder.addSimpleInsertion(initializers.last.end, ', $name = $name');
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_NORMAL_PARAMETER);
    }
  }

  Future<void> _addProposal_convertToNullAware() async {
    AstNode node = this.node;
    if (node is! ConditionalExpression) {
      _coverageMarker();
      return;
    }
    ConditionalExpression conditional = node;
    Expression condition = conditional.condition.unParenthesized;
    SimpleIdentifier identifier;
    Expression nullExpression;
    Expression nonNullExpression;
    int periodOffset;

    if (condition is BinaryExpression) {
      //
      // Identify the variable being compared to `null`, or return if the
      // condition isn't a simple comparison of `null` to a variable's value.
      //
      Expression leftOperand = condition.leftOperand;
      Expression rightOperand = condition.rightOperand;
      if (leftOperand is NullLiteral && rightOperand is SimpleIdentifier) {
        identifier = rightOperand;
      } else if (rightOperand is NullLiteral &&
          leftOperand is SimpleIdentifier) {
        identifier = leftOperand;
      } else {
        _coverageMarker();
        return;
      }
      if (identifier.staticElement is! LocalElement) {
        _coverageMarker();
        return;
      }
      //
      // Identify the expression executed when the variable is `null` and when
      // it is non-`null`. Return if the `null` expression isn't a null literal
      // or if the non-`null` expression isn't a method invocation whose target
      // is the save variable being compared to `null`.
      //
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullExpression = conditional.thenExpression;
        nonNullExpression = conditional.elseExpression;
      } else if (condition.operator.type == TokenType.BANG_EQ) {
        nonNullExpression = conditional.thenExpression;
        nullExpression = conditional.elseExpression;
      }
      if (nullExpression == null || nonNullExpression == null) {
        _coverageMarker();
        return;
      }
      if (nullExpression.unParenthesized is! NullLiteral) {
        _coverageMarker();
        return;
      }
      Expression unwrappedExpression = nonNullExpression.unParenthesized;
      Expression target;
      Token operator;
      if (unwrappedExpression is MethodInvocation) {
        target = unwrappedExpression.target;
        operator = unwrappedExpression.operator;
      } else if (unwrappedExpression is PrefixedIdentifier) {
        target = unwrappedExpression.prefix;
        operator = unwrappedExpression.period;
      } else {
        _coverageMarker();
        return;
      }
      if (operator.type != TokenType.PERIOD) {
        _coverageMarker();
        return;
      }
      if (!(target is SimpleIdentifier &&
          target.staticElement == identifier.staticElement)) {
        _coverageMarker();
        return;
      }
      periodOffset = operator.offset;

      DartChangeBuilder changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(node, nonNullExpression));
        builder.addSimpleInsertion(periodOffset, '?');
        builder.addDeletion(range.endEnd(nonNullExpression, node));
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_NULL_AWARE);
    }
  }

  Future<void> _addProposal_convertToPackageImport() async {
    var node = this.node;
    if (node is StringLiteral) {
      node = node.parent;
    }
    if (node is ImportDirective) {
      ImportDirective importDirective = node;
      var uriSource = importDirective.uriSource;

      // Ignore if invalid URI.
      if (uriSource == null) {
        return;
      }

      var importUri = uriSource.uri;
      if (importUri.scheme != 'package') {
        return;
      }

      // Don't offer to convert a 'package:' URI to itself.
      try {
        if (Uri.parse(importDirective.uriContent).scheme == 'package') {
          return;
        }
      } on FormatException {
        return;
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(importDirective.uri),
          "'$importUri'",
        );
      });
      _addAssistFromBuilder(
        changeBuilder,
        DartAssistKind.CONVERT_TO_PACKAGE_IMPORT,
      );
    }
  }

  Future<void> _addProposal_convertToSingleQuotedString() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    await _convertQuotes(true, DartAssistKind.CONVERT_TO_SINGLE_QUOTED_STRING);
  }

  Future<void> _addProposal_encapsulateField() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // find FieldDeclaration
    FieldDeclaration fieldDeclaration =
        node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration == null) {
      _coverageMarker();
      return;
    }
    // not interesting for static
    if (fieldDeclaration.isStatic) {
      _coverageMarker();
      return;
    }
    // has a parse error
    VariableDeclarationList variableList = fieldDeclaration.fields;
    if (variableList.keyword == null && variableList.type == null) {
      _coverageMarker();
      return;
    }
    // not interesting for final
    if (variableList.isFinal) {
      _coverageMarker();
      return;
    }
    // should have exactly one field
    List<VariableDeclaration> fields = variableList.variables;
    if (fields.length != 1) {
      _coverageMarker();
      return;
    }
    VariableDeclaration field = fields.first;
    SimpleIdentifier nameNode = field.name;
    FieldElement fieldElement = nameNode.staticElement;
    // should have a public name
    String name = nameNode.name;
    if (Identifier.isPrivateName(name)) {
      _coverageMarker();
      return;
    }
    // should be on the name
    if (nameNode != node) {
      _coverageMarker();
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // rename field
      builder.addSimpleReplacement(range.node(nameNode), '_$name');
      // update references in constructors
      ClassOrMixinDeclaration classDeclaration = fieldDeclaration.parent;
      for (ClassMember member in classDeclaration.members) {
        if (member is ConstructorDeclaration) {
          for (FormalParameter parameter in member.parameters.parameters) {
            ParameterElement parameterElement = parameter.declaredElement;
            if (parameterElement is FieldFormalParameterElement &&
                parameterElement.field == fieldElement) {
              SimpleIdentifier identifier = parameter.identifier;
              builder.addSimpleReplacement(range.node(identifier), '_$name');
            }
          }
        }
      }

      // Write getter and setter.
      builder.addInsertion(fieldDeclaration.end, (builder) {
        String docCode;
        if (fieldDeclaration.documentationComment != null) {
          docCode = utils.getNodeText(fieldDeclaration.documentationComment);
        }

        String typeCode = '';
        if (variableList.type != null) {
          typeCode = _getNodeText(variableList.type) + ' ';
        }

        // Write getter.
        builder.writeln();
        builder.writeln();
        if (docCode != null) {
          builder.write('  ');
          builder.writeln(docCode);
        }
        builder.write('  ${typeCode}get $name => _$name;');

        // Write setter.
        builder.writeln();
        builder.writeln();
        if (docCode != null) {
          builder.write('  ');
          builder.writeln(docCode);
        }
        builder.writeln('  set $name($typeCode$name) {');
        builder.writeln('    _$name = $name;');
        builder.write('  }');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.ENCAPSULATE_FIELD);
  }

  Future<void> _addProposal_exchangeOperands() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      _coverageMarker();
      return;
    }
    BinaryExpression binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!_isOperatorSelected(
        binaryExpression, selectionOffset, selectionLength)) {
      _coverageMarker();
      return;
    }
    // add edits
    Expression leftOperand = binaryExpression.leftOperand;
    Expression rightOperand = binaryExpression.rightOperand;
    // find "wide" enclosing binary expression with same operator
    while (binaryExpression.parent is BinaryExpression) {
      BinaryExpression newBinaryExpression =
          binaryExpression.parent as BinaryExpression;
      if (newBinaryExpression.operator.type != binaryExpression.operator.type) {
        _coverageMarker();
        break;
      }
      binaryExpression = newBinaryExpression;
    }
    // exchange parts of "wide" expression parts
    SourceRange leftRange = range.startEnd(binaryExpression, leftOperand);
    SourceRange rightRange = range.startEnd(rightOperand, binaryExpression);
    // maybe replace the operator
    Token operator = binaryExpression.operator;
    // prepare a new operator
    String newOperator = null;
    TokenType operatorType = operator.type;
    if (operatorType == TokenType.LT) {
      newOperator = '>';
    } else if (operatorType == TokenType.LT_EQ) {
      newOperator = '>=';
    } else if (operatorType == TokenType.GT) {
      newOperator = '<';
    } else if (operatorType == TokenType.GT_EQ) {
      newOperator = '<=';
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(leftRange, _getRangeText(rightRange));
      builder.addSimpleReplacement(rightRange, _getRangeText(leftRange));
      // Optionally replace the operator.
      if (newOperator != null) {
        builder.addSimpleReplacement(range.token(operator), newOperator);
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.EXCHANGE_OPERANDS);
  }

  Future<void> _addProposal_flutterConvertToChildren() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Find "child: widget" under selection.
    NamedExpression namedExp;
    {
      AstNode node = this.node;
      AstNode parent = node?.parent;
      AstNode parent2 = parent?.parent;
      if (node is SimpleIdentifier &&
          parent is Label &&
          parent2 is NamedExpression &&
          node.name == 'child' &&
          node.staticElement != null &&
          flutter.isWidgetExpression(parent2.expression)) {
        namedExp = parent2;
      } else {
        _coverageMarker();
        return;
      }
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      _convertFlutterChildToChildren(namedExp, eol, utils.getNodeText,
          utils.getLinePrefix, utils.getIndent, utils.getText, builder);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.FLUTTER_CONVERT_TO_CHILDREN);
  }

  Future<void> _addProposal_flutterConvertToStatefulWidget() async {
    ClassDeclaration widgetClass =
        node.thisOrAncestorOfType<ClassDeclaration>();
    TypeName superclass = widgetClass?.extendsClause?.superclass;
    if (widgetClass == null || superclass == null) {
      _coverageMarker();
      return;
    }

    // Don't spam, activate only from the `class` keyword to the class body.
    if (selectionOffset < widgetClass.classKeyword.offset ||
        selectionOffset > widgetClass.leftBracket.end) {
      _coverageMarker();
      return;
    }

    // Find the build() method.
    MethodDeclaration buildMethod;
    for (var member in widgetClass.members) {
      if (member is MethodDeclaration &&
          member.name.name == 'build' &&
          member.parameters != null &&
          member.parameters.parameters.length == 1) {
        buildMethod = member;
        break;
      }
    }
    if (buildMethod == null) {
      _coverageMarker();
      return;
    }

    // Must be a StatelessWidget subclasses.
    ClassElement widgetClassElement = widgetClass.declaredElement;
    if (!flutter.isExactlyStatelessWidgetType(widgetClassElement.supertype)) {
      _coverageMarker();
      return;
    }

    String widgetName = widgetClassElement.displayName;
    String stateName = '_${widgetName}State';

    // Find fields assigned in constructors.
    var fieldsAssignedInConstructors = new Set<FieldElement>();
    for (var member in widgetClass.members) {
      if (member is ConstructorDeclaration) {
        member.accept(new _SimpleIdentifierRecursiveAstVisitor((node) {
          if (node.parent is FieldFormalParameter) {
            Element element = node.staticElement;
            if (element is FieldFormalParameterElement) {
              fieldsAssignedInConstructors.add(element.field);
            }
          }
          if (node.parent is ConstructorFieldInitializer) {
            Element element = node.staticElement;
            if (element is FieldElement) {
              fieldsAssignedInConstructors.add(element);
            }
          }
          if (node.inSetterContext()) {
            Element element = node.staticElement;
            if (element is PropertyAccessorElement) {
              PropertyInducingElement field = element.variable;
              if (field is FieldElement) {
                fieldsAssignedInConstructors.add(field);
              }
            }
          }
        }));
      }
    }

    // Prepare nodes to move.
    var nodesToMove = new Set<ClassMember>();
    var elementsToMove = new Set<Element>();
    for (var member in widgetClass.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (VariableDeclaration fieldNode in member.fields.variables) {
          FieldElement fieldElement = fieldNode.declaredElement;
          if (!fieldsAssignedInConstructors.contains(fieldElement)) {
            nodesToMove.add(member);
            elementsToMove.add(fieldElement);
            elementsToMove.add(fieldElement.getter);
            if (fieldElement.setter != null) {
              elementsToMove.add(fieldElement.setter);
            }
          }
        }
      }
      if (member is MethodDeclaration && !member.isStatic) {
        nodesToMove.add(member);
        elementsToMove.add(member.declaredElement);
      }
    }

    /// Return the code for the [movedNode] which is suitable to be used
    /// inside the `State` class, so that references to the widget fields and
    /// methods, that are not moved, are qualified with the corresponding
    /// instance `widget.`, or static `MyWidgetClass.` qualifier.
    String rewriteWidgetMemberReferences(AstNode movedNode) {
      var linesRange = utils.getLinesRange(range.node(movedNode));
      var text = utils.getRangeText(linesRange);

      // Insert `widget.` before references to the widget instance members.
      final List<SourceEdit> edits = [];
      movedNode.accept(new _SimpleIdentifierRecursiveAstVisitor((node) {
        if (node.inDeclarationContext()) {
          return;
        }
        var element = node.staticElement;
        if (element is ExecutableElement &&
            element?.enclosingElement == widgetClassElement &&
            !elementsToMove.contains(element)) {
          var offset = node.offset - linesRange.offset;
          var qualifier = element.isStatic ? widgetName : 'widget';

          AstNode parent = node.parent;
          if (parent is InterpolationExpression &&
              parent.leftBracket.type ==
                  TokenType.STRING_INTERPOLATION_IDENTIFIER) {
            edits.add(new SourceEdit(offset, 0, '{$qualifier.'));
            edits.add(new SourceEdit(offset + node.length, 0, '}'));
          } else {
            edits.add(new SourceEdit(offset, 0, '$qualifier.'));
          }
        }
      }));
      return SourceEdit.applySequence(text, edits.reversed);
    }

    var statefulWidgetClass = await sessionHelper.getClass(
      flutter.widgetsUri,
      'StatefulWidget',
    );
    var stateClass = await sessionHelper.getClass(
      flutter.widgetsUri,
      'State',
    );
    if (statefulWidgetClass == null || stateClass == null) {
      return;
    }
    var stateType = stateClass.type.instantiate([widgetClassElement.type]);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(superclass), (builder) {
        builder.writeType(statefulWidgetClass.type);
      });

      int replaceOffset = 0;
      bool hasBuildMethod = false;

      /// Replace code between [replaceOffset] and [replaceEnd] with
      /// `createState()`, empty line, or nothing.
      void replaceInterval(int replaceEnd,
          {bool replaceWithEmptyLine = false,
          bool hasEmptyLineBeforeCreateState = false,
          bool hasEmptyLineAfterCreateState = true}) {
        int replaceLength = replaceEnd - replaceOffset;
        builder.addReplacement(
          new SourceRange(replaceOffset, replaceLength),
          (builder) {
            if (hasBuildMethod) {
              if (hasEmptyLineBeforeCreateState) {
                builder.writeln();
              }
              builder.writeln('  @override');
              builder.writeln('  $stateName createState() => $stateName();');
              if (hasEmptyLineAfterCreateState) {
                builder.writeln();
              }
              hasBuildMethod = false;
            } else if (replaceWithEmptyLine) {
              builder.writeln();
            }
          },
        );
        replaceOffset = 0;
      }

      // Remove continuous ranges of lines of nodes being moved.
      bool lastToRemoveIsField = false;
      int endOfLastNodeToKeep = 0;
      for (var node in widgetClass.members) {
        if (nodesToMove.contains(node)) {
          if (replaceOffset == 0) {
            var linesRange = utils.getLinesRange(range.node(node));
            replaceOffset = linesRange.offset;
          }
          if (node == buildMethod) {
            hasBuildMethod = true;
          }
          lastToRemoveIsField = node is FieldDeclaration;
        } else {
          var linesRange = utils.getLinesRange(range.node(node));
          endOfLastNodeToKeep = linesRange.end;
          if (replaceOffset != 0) {
            replaceInterval(linesRange.offset,
                replaceWithEmptyLine:
                    lastToRemoveIsField && node is! FieldDeclaration);
          }
        }
      }

      // Remove nodes at the end of the widget class.
      if (replaceOffset != 0) {
        // Remove from the last node to keep, so remove empty lines.
        if (endOfLastNodeToKeep != 0) {
          replaceOffset = endOfLastNodeToKeep;
        }
        replaceInterval(widgetClass.rightBracket.offset,
            hasEmptyLineBeforeCreateState: endOfLastNodeToKeep != 0,
            hasEmptyLineAfterCreateState: false);
      }

      // Create the State subclass.
      builder.addInsertion(widgetClass.end, (builder) {
        builder.writeln();
        builder.writeln();
        builder.writeClassDeclaration(stateName, superclass: stateType,
            membersWriter: () {
          bool writeEmptyLine = false;
          for (var member in nodesToMove) {
            if (writeEmptyLine) {
              builder.writeln();
            }
            String text = rewriteWidgetMemberReferences(member);
            builder.write(text);
            // Write empty lines between members, but not before the first.
            writeEmptyLine = true;
          }
        });
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.FLUTTER_CONVERT_TO_STATEFUL_WIDGET);
  }

  Future<void> _addProposal_flutterMoveWidgetDown() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var widget = flutter.identifyWidgetExpression(node);
    if (widget == null) {
      return;
    }

    AstNode parentList = widget.parent;
    if (parentList is ListLiteral) {
      List<CollectionElement> parentElements = parentList.elements;
      int index = parentElements.indexOf(widget);
      if (index != parentElements.length - 1) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          CollectionElement nextWidget = parentElements[index + 1];
          var nextRange = range.node(nextWidget);
          var nextText = utils.getRangeText(nextRange);

          var widgetRange = range.node(widget);
          var widgetText = utils.getRangeText(widgetRange);

          builder.addSimpleReplacement(nextRange, widgetText);
          builder.addSimpleReplacement(widgetRange, nextText);

          int lengthDelta = nextRange.length - widgetRange.length;
          int newWidgetOffset = nextRange.offset + lengthDelta;
          changeBuilder.setSelection(new Position(file, newWidgetOffset));
        });
        _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_MOVE_DOWN);
      }
    }
  }

  Future<void> _addProposal_flutterMoveWidgetUp() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var widget = flutter.identifyWidgetExpression(node);
    if (widget == null) {
      return;
    }

    AstNode parentList = widget.parent;
    if (parentList is ListLiteral) {
      List<CollectionElement> parentElements = parentList.elements;
      int index = parentElements.indexOf(widget);
      if (index > 0) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          CollectionElement previousWidget = parentElements[index - 1];
          var previousRange = range.node(previousWidget);
          var previousText = utils.getRangeText(previousRange);

          var widgetRange = range.node(widget);
          var widgetText = utils.getRangeText(widgetRange);

          builder.addSimpleReplacement(previousRange, widgetText);
          builder.addSimpleReplacement(widgetRange, previousText);

          int newWidgetOffset = previousRange.offset;
          changeBuilder.setSelection(new Position(file, newWidgetOffset));
        });
        _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_MOVE_UP);
      }
    }
  }

  Future<void> _addProposal_flutterRemoveWidget_multipleChildren() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var widgetCreation = flutter.identifyNewExpression(node);
    if (widgetCreation == null) {
      return;
    }

    // Prepare the list of our children.
    List<CollectionElement> childrenExpressions;
    {
      var childrenArgument = flutter.findChildrenArgument(widgetCreation);
      var childrenExpression = childrenArgument?.expression;
      if (childrenExpression is ListLiteral &&
          childrenExpression.elements.isNotEmpty) {
        childrenExpressions = childrenExpression.elements;
      } else {
        return;
      }
    }

    // We can inline the list of our children only into another list.
    var widgetParentNode = widgetCreation.parent;
    if (childrenExpressions.length > 1 && widgetParentNode is! ListLiteral) {
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var firstChild = childrenExpressions.first;
      var lastChild = childrenExpressions.last;
      var childText = utils.getRangeText(range.startEnd(firstChild, lastChild));
      var indentOld = utils.getLinePrefix(firstChild.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = _replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_REMOVE_WIDGET);
  }

  Future<void> _addProposal_flutterRemoveWidget_singleChild() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var widgetCreation = flutter.identifyNewExpression(node);
    if (widgetCreation == null) {
      return;
    }

    var childArgument = flutter.findChildArgument(widgetCreation);
    if (childArgument == null) {
      return;
    }

    // child: ThisWidget(child: ourChild)
    // children: [foo, ThisWidget(child: ourChild), bar]
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var childExpression = childArgument.expression;
      var childText = utils.getNodeText(childExpression);
      var indentOld = utils.getLinePrefix(childExpression.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = _replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_REMOVE_WIDGET);
  }

  Future<void> _addProposal_flutterSwapWithChild() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    InstanceCreationExpression parent = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(parent)) {
      _coverageMarker();
      return;
    }

    NamedExpression childArgument = flutter.findChildArgument(parent);
    if (childArgument?.expression is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(childArgument.expression)) {
      _coverageMarker();
      return;
    }
    InstanceCreationExpression child = childArgument.expression;

    await _swapParentAndChild(
        parent, child, DartAssistKind.FLUTTER_SWAP_WITH_CHILD);
  }

  Future<void> _addProposal_flutterSwapWithParent() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    InstanceCreationExpression child = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(child)) {
      _coverageMarker();
      return;
    }

    // NamedExpression (child:), ArgumentList, InstanceCreationExpression
    AstNode expr = child.parent?.parent?.parent;
    if (expr is! InstanceCreationExpression) {
      _coverageMarker();
      return;
    }
    InstanceCreationExpression parent = expr;

    await _swapParentAndChild(
        parent, child, DartAssistKind.FLUTTER_SWAP_WITH_PARENT);
  }

  Future<void> _addProposal_flutterWrapStreamBuilder() async {
    Expression widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr == null) {
      return;
    }
    if (flutter.isExactWidgetTypeStreamBuilder(widgetExpr.staticType)) {
      return;
    }
    String widgetSrc = utils.getNodeText(widgetExpr);

    var streamBuilderElement = await sessionHelper.getClass(
      flutter.widgetsUri,
      'StreamBuilder',
    );
    if (streamBuilderElement == null) {
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeType(streamBuilderElement.type);

        builder.write('<');
        builder.addSimpleLinkedEdit('type', 'Object');
        builder.writeln('>(');

        String indentOld = utils.getLinePrefix(widgetExpr.offset);
        String indentNew1 = indentOld + utils.getIndent(1);
        String indentNew2 = indentOld + utils.getIndent(2);

        builder.write(indentNew1);
        builder.writeln('stream: null,');

        builder.write(indentNew1);
        builder.writeln('builder: (context, snapshot) {');

        widgetSrc = widgetSrc.replaceAll(
          new RegExp("^$indentOld", multiLine: true),
          indentNew2,
        );
        builder.write(indentNew2);
        builder.write('return $widgetSrc');
        builder.writeln(';');

        builder.write(indentNew1);
        builder.writeln('}');

        builder.write(indentOld);
        builder.write(')');
      });
    });
    _addAssistFromBuilder(
      changeBuilder,
      DartAssistKind.FLUTTER_WRAP_STREAM_BUILDER,
    );
  }

  Future<void> _addProposal_flutterWrapWidget() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    await _addProposal_flutterWrapWidgetImpl();
    await _addProposal_flutterWrapWidgetImpl(
        kind: DartAssistKind.FLUTTER_WRAP_CENTER,
        parentLibraryUri: flutter.widgetsUri,
        parentClassName: 'Center',
        widgetValidator: (expr) {
          return !flutter.isExactWidgetTypeCenter(expr.staticType);
        });
    await _addProposal_flutterWrapWidgetImpl(
        kind: DartAssistKind.FLUTTER_WRAP_CONTAINER,
        parentLibraryUri: flutter.widgetsUri,
        parentClassName: 'Container',
        widgetValidator: (expr) {
          return !flutter.isExactWidgetTypeContainer(expr.staticType);
        });
    await _addProposal_flutterWrapWidgetImpl(
        kind: DartAssistKind.FLUTTER_WRAP_PADDING,
        parentLibraryUri: flutter.widgetsUri,
        parentClassName: 'Padding',
        leadingLines: ['padding: const EdgeInsets.all(8.0),'],
        widgetValidator: (expr) {
          return !flutter.isExactWidgetTypePadding(expr.staticType);
        });
  }

  Future<void> _addProposal_flutterWrapWidgetImpl(
      {AssistKind kind = DartAssistKind.FLUTTER_WRAP_GENERIC,
      bool Function(Expression widgetExpr) widgetValidator,
      String parentLibraryUri,
      String parentClassName,
      List<String> leadingLines = const []}) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    Expression widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr == null) {
      _coverageMarker();
      return;
    }
    if (widgetValidator != null && !widgetValidator(widgetExpr)) {
      _coverageMarker();
      return;
    }
    String widgetSrc = utils.getNodeText(widgetExpr);

    // If the wrapper class is specified, find its element.
    ClassElement parentClassElement;
    if (parentLibraryUri != null && parentClassName != null) {
      parentClassElement =
          await sessionHelper.getClass(parentLibraryUri, parentClassName);
      if (parentClassElement == null) {
        return;
      }
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(widgetExpr), (DartEditBuilder builder) {
        if (parentClassElement == null) {
          builder.addSimpleLinkedEdit('WIDGET', 'widget');
        } else {
          builder.writeType(parentClassElement.type);
        }
        builder.write('(');
        if (widgetSrc.contains(eol) || leadingLines.isNotEmpty) {
          String indentOld = utils.getLinePrefix(widgetExpr.offset);
          String indentNew = '$indentOld${utils.getIndent(1)}';

          for (var leadingLine in leadingLines) {
            builder.write(eol);
            builder.write(indentNew);
            builder.write(leadingLine);
          }

          builder.write(eol);
          builder.write(indentNew);
          widgetSrc = widgetSrc.replaceAll(
              new RegExp("^$indentOld", multiLine: true), indentNew);
          widgetSrc += ",$eol$indentOld";
        }
        if (parentClassElement == null) {
          builder.addSimpleLinkedEdit('CHILD', 'child');
        } else {
          builder.write('child');
        }
        builder.write(': ');
        builder.write(widgetSrc);
        builder.write(')');
      });
    });
    _addAssistFromBuilder(changeBuilder, kind);
  }

  Future<void> _addProposal_flutterWrapWidgets() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var selectionRange = new SourceRange(selectionOffset, selectionLength);
    var analyzer = new SelectionAnalyzer(selectionRange);
    context.resolveResult.unit.accept(analyzer);

    List<Expression> widgetExpressions = [];
    if (analyzer.hasSelectedNodes) {
      for (var selectedNode in analyzer.selectedNodes) {
        if (!flutter.isWidgetExpression(selectedNode)) {
          return;
        }
        widgetExpressions.add(selectedNode);
      }
    } else {
      var widget = flutter.identifyWidgetExpression(analyzer.coveringNode);
      if (widget != null) {
        widgetExpressions.add(widget);
      }
    }
    if (widgetExpressions.isEmpty) {
      return;
    }

    var firstWidget = widgetExpressions.first;
    var lastWidget = widgetExpressions.last;
    var selectedRange = range.startEnd(firstWidget, lastWidget);
    String src = utils.getRangeText(selectedRange);

    Future<void> addAssist(
        {@required AssistKind kind,
        @required String parentLibraryUri,
        @required String parentClassName}) async {
      // TODO(brianwilkerson) Determine whether this await is necessary.
      await null;
      ClassElement parentClassElement =
          await sessionHelper.getClass(parentLibraryUri, parentClassName);
      ClassElement widgetClassElement =
          await sessionHelper.getClass(flutter.widgetsUri, 'Widget');
      if (parentClassElement == null || widgetClassElement == null) {
        return;
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(selectedRange, (DartEditBuilder builder) {
          builder.writeType(parentClassElement.type);
          builder.write('(');

          String indentOld = utils.getLinePrefix(firstWidget.offset);
          String indentNew1 = indentOld + utils.getIndent(1);
          String indentNew2 = indentOld + utils.getIndent(2);

          builder.write(eol);
          builder.write(indentNew1);
          builder.write('children: <');
          builder.writeType(widgetClassElement.type);
          builder.write('>[');
          builder.write(eol);

          String newSrc = _replaceSourceIndent(src, indentOld, indentNew2);
          builder.write(indentNew2);
          builder.write(newSrc);

          builder.write(',');
          builder.write(eol);

          builder.write(indentNew1);
          builder.write('],');
          builder.write(eol);

          builder.write(indentOld);
          builder.write(')');
        });
      });
      _addAssistFromBuilder(changeBuilder, kind);
    }

    await addAssist(
        kind: DartAssistKind.FLUTTER_WRAP_COLUMN,
        parentLibraryUri: flutter.widgetsUri,
        parentClassName: 'Column');
    await addAssist(
        kind: DartAssistKind.FLUTTER_WRAP_ROW,
        parentLibraryUri: flutter.widgetsUri,
        parentClassName: 'Row');
  }

  Future<void> _addProposal_importAddShow() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare ImportDirective
    ImportDirective importDirective =
        node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      _coverageMarker();
      return;
    }
    // there should be no existing combinators
    if (importDirective.combinators.isNotEmpty) {
      _coverageMarker();
      return;
    }
    // prepare whole import namespace
    ImportElement importElement = importDirective.element;
    if (importElement == null) {
      _coverageMarker();
      return;
    }
    Map<String, Element> namespace = getImportNamespace(importElement);
    // prepare names of referenced elements (from this import)
    SplayTreeSet<String> referencedNames = new SplayTreeSet<String>();
    _SimpleIdentifierRecursiveAstVisitor visitor =
        new _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
      Element element = node.staticElement;
      if (element != null && namespace[node.name] == element) {
        referencedNames.add(element.displayName);
      }
    });
    context.resolveResult.unit.accept(visitor);
    // ignore if unused
    if (referencedNames.isEmpty) {
      _coverageMarker();
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      String showCombinator = ' show ${referencedNames.join(', ')}';
      builder.addSimpleInsertion(importDirective.end - 1, showCombinator);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.IMPORT_ADD_SHOW);
  }

  Future<void> _addProposal_inlineAdd() async {
    AstNode node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      _coverageMarker();
      return;
    }
    SimpleIdentifier name = node;
    MethodInvocation invocation = node.parent;
    if (name != invocation.methodName ||
        name.name != 'add' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      _coverageMarker();
      return;
    }
    CascadeExpression cascade = invocation.thisOrAncestorOfType();
    NodeList<Expression> sections = cascade.cascadeSections;
    Expression target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      _coverageMarker();
      return;
    }
    ListLiteral list = target;
    Expression argument = invocation.argumentList.arguments[0];
    String elementText = utils.getNodeText(argument);

    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      if (list.elements.isNotEmpty) {
        // ['a']..add(e);
        builder.addSimpleInsertion(list.elements.last.end, ', $elementText');
      } else {
        // []..add(e);
        builder.addSimpleInsertion(list.leftBracket.end, elementText);
      }
      builder.addDeletion(range.node(invocation));
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.INLINE_INVOCATION,
        args: ['add']);
  }

  Future<void> _addProposal_introduceLocalTestedType() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AstNode node = this.node;
    if (node is IfStatement) {
      node = (node as IfStatement).condition;
    } else if (node is WhileStatement) {
      node = (node as WhileStatement).condition;
    }
    // prepare IsExpression
    if (node is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = node;
    DartType castType = isExpression.type.type;
    String castTypeCode = _getNodeText(isExpression.type);
    // prepare environment
    String indent = utils.getIndent(1);
    String prefix;
    Block targetBlock;
    {
      Statement statement = node.thisOrAncestorOfType<Statement>();
      if (statement is IfStatement && statement.thenStatement is Block) {
        targetBlock = statement.thenStatement;
      } else if (statement is WhileStatement && statement.body is Block) {
        targetBlock = statement.body;
      } else {
        _coverageMarker();
        return;
      }
      prefix = utils.getNodePrefix(statement);
    }
    // prepare location
    int offset;
    String statementPrefix;
    if (isExpression.notOperator == null) {
      offset = targetBlock.leftBracket.end;
      statementPrefix = indent;
    } else {
      offset = targetBlock.rightBracket.end;
      statementPrefix = '';
    }
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
    isExpression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    // name(s)
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(castType, null, excluded);

    if (suggestions.isNotEmpty) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          builder.write(eol + prefix + statementPrefix);
          builder.write(castTypeCode);
          builder.write(' ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
          builder.write(_getNodeText(isExpression.expression));
          builder.write(';');
          builder.selectHere();
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE);
    }
  }

  Future<void> _addProposal_invertIf() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (node is! IfStatement) {
      return;
    }
    IfStatement ifStatement = node as IfStatement;
    Expression condition = ifStatement.condition;
    // should have both "then" and "else"
    Statement thenStatement = ifStatement.thenStatement;
    Statement elseStatement = ifStatement.elseStatement;
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    // prepare source
    String invertedCondition = utils.invertCondition(condition);
    String thenSource = _getNodeText(thenStatement);
    String elseSource = _getNodeText(elseStatement);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(range.node(thenStatement), elseSource);
      builder.addSimpleReplacement(range.node(elseStatement), thenSource);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.INVERT_IF_STATEMENT);
  }

  Future<void> _addProposal_joinIfStatementInner() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // climb up condition to the (supposedly) "if" statement
    AstNode node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare inner "if" statement
    Statement targetThenStatement = targetIfStatement.thenStatement;
    Statement innerStatement = getSingleStatement(targetThenStatement);
    if (innerStatement is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement innerIfStatement = innerStatement as IfStatement;
    if (innerIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(targetIfStatement);
    // merge conditions
    String condition;
    {
      Expression targetCondition = targetIfStatement.condition;
      Expression innerCondition = innerIfStatement.condition;
      String targetConditionSource = _getNodeText(targetCondition);
      String innerConditionSource = _getNodeText(innerCondition);
      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
        targetConditionSource = '($targetConditionSource)';
      }
      if (_shouldWrapParenthesisBeforeAnd(innerCondition)) {
        innerConditionSource = '($innerConditionSource)';
      }
      condition = '$targetConditionSource && $innerConditionSource';
    }
    // replace target "if" statement
    Statement innerThenStatement = innerIfStatement.thenStatement;
    List<Statement> innerThenStatements = getStatements(innerThenStatement);
    SourceRange lineRanges = utils.getLinesRangeStatements(innerThenStatements);
    String oldSource = utils.getRangeText(lineRanges);
    String newSource = utils.indentSourceLeftRight(oldSource);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(targetIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_INNER);
  }

  Future<void> _addProposal_joinIfStatementOuter() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // climb up condition to the (supposedly) "if" statement
    AstNode node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare outer "if" statement
    AstNode parent = targetIfStatement.parent;
    if (parent is Block) {
      if ((parent as Block).statements.length != 1) {
        _coverageMarker();
        return;
      }
      parent = parent.parent;
    }
    if (parent is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement outerIfStatement = parent as IfStatement;
    if (outerIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(outerIfStatement);
    // merge conditions
    Expression targetCondition = targetIfStatement.condition;
    Expression outerCondition = outerIfStatement.condition;
    String targetConditionSource = _getNodeText(targetCondition);
    String outerConditionSource = _getNodeText(outerCondition);
    if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
      targetConditionSource = '($targetConditionSource)';
    }
    if (_shouldWrapParenthesisBeforeAnd(outerCondition)) {
      outerConditionSource = '($outerConditionSource)';
    }
    String condition = '$outerConditionSource && $targetConditionSource';
    // replace outer "if" statement
    Statement targetThenStatement = targetIfStatement.thenStatement;
    List<Statement> targetThenStatements = getStatements(targetThenStatement);
    SourceRange lineRanges =
        utils.getLinesRangeStatements(targetThenStatements);
    String oldSource = utils.getRangeText(lineRanges);
    String newSource = utils.indentSourceLeftRight(oldSource);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(outerIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  Future<void> _addProposal_joinVariableDeclaration_onAssignment() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // check that node is LHS in assignment
    if (node is SimpleIdentifier &&
        node.parent is AssignmentExpression &&
        (node.parent as AssignmentExpression).leftHandSide == node &&
        node.parent.parent is ExpressionStatement) {
    } else {
      _coverageMarker();
      return;
    }
    AssignmentExpression assignExpression = node.parent as AssignmentExpression;
    // check that binary expression is assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      _coverageMarker();
      return;
    }
    // prepare "declaration" statement
    Element element = (node as SimpleIdentifier).staticElement;
    if (element == null) {
      _coverageMarker();
      return;
    }
    int declOffset = element.nameOffset;
    var unit = context.resolveResult.unit;
    AstNode declNode = new NodeLocator(declOffset).searchWithin(unit);
    if (declNode != null &&
        declNode.parent is VariableDeclaration &&
        (declNode.parent as VariableDeclaration).name == declNode &&
        declNode.parent.parent is VariableDeclarationList &&
        declNode.parent.parent.parent is VariableDeclarationStatement) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclaration decl = declNode.parent as VariableDeclaration;
    VariableDeclarationStatement declStatement =
        decl.parent.parent as VariableDeclarationStatement;
    // may be has initializer
    if (decl.initializer != null) {
      _coverageMarker();
      return;
    }
    // check that "declaration" statement declared only one variable
    if (declStatement.variables.variables.length != 1) {
      _coverageMarker();
      return;
    }
    // check that the "declaration" and "assignment" statements are
    // parts of the same Block
    ExpressionStatement assignStatement =
        node.parent.parent as ExpressionStatement;
    if (assignStatement.parent is Block &&
        assignStatement.parent == declStatement.parent) {
    } else {
      _coverageMarker();
      return;
    }
    Block block = assignStatement.parent as Block;
    // check that "declaration" and "assignment" statements are adjacent
    List<Statement> statements = block.statements;
    if (statements.indexOf(assignStatement) ==
        statements.indexOf(declStatement) + 1) {
    } else {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.endStart(declNode, assignExpression.operator), ' ');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  Future<void> _addProposal_joinVariableDeclaration_onDeclaration() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare enclosing VariableDeclarationList
    VariableDeclarationList declList =
        node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declList != null && declList.variables.length == 1) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclaration decl = declList.variables[0];
    // already initialized
    if (decl.initializer != null) {
      _coverageMarker();
      return;
    }
    // prepare VariableDeclarationStatement in Block
    if (declList.parent is VariableDeclarationStatement &&
        declList.parent.parent is Block) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclarationStatement declStatement =
        declList.parent as VariableDeclarationStatement;
    Block block = declStatement.parent as Block;
    List<Statement> statements = block.statements;
    // prepare assignment
    AssignmentExpression assignExpression;
    {
      // declaration should not be last Statement
      int declIndex = statements.indexOf(declStatement);
      if (declIndex < statements.length - 1) {
      } else {
        _coverageMarker();
        return;
      }
      // next Statement should be assignment
      Statement assignStatement = statements[declIndex + 1];
      if (assignStatement is ExpressionStatement) {
      } else {
        _coverageMarker();
        return;
      }
      ExpressionStatement expressionStatement =
          assignStatement as ExpressionStatement;
      // expression should be assignment
      if (expressionStatement.expression is AssignmentExpression) {
      } else {
        _coverageMarker();
        return;
      }
      assignExpression = expressionStatement.expression as AssignmentExpression;
    }
    // check that pure assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.endStart(decl.name, assignExpression.operator), ' ');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  Future<void> _addProposal_removeTypeAnnotation() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    VariableDeclarationList declarationList =
        node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declarationList == null) {
      _coverageMarker();
      return;
    }
    // we need a type
    TypeAnnotation typeNode = declarationList.type;
    if (typeNode == null) {
      _coverageMarker();
      return;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables[0].name.isSynthetic) {
      _coverageMarker();
      return;
    }
    // must be not after the name of the variable
    VariableDeclaration firstVariable = declarationList.variables[0];
    if (selectionOffset > firstVariable.name.end) {
      _coverageMarker();
      return;
    }
    // The variable must have an initializer, otherwise there is no other
    // source for its type.
    if (firstVariable.initializer == null) {
      _coverageMarker();
      return;
    }
    Token keyword = declarationList.keyword;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      SourceRange typeRange = range.startStart(typeNode, firstVariable);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.REMOVE_TYPE_ANNOTATION);
  }

  Future<void> _addProposal_reparentFlutterList() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (node is! ListLiteral) {
      return;
    }
    if ((node as ListLiteral).elements.any((CollectionElement exp) =>
        !(exp is InstanceCreationExpression &&
            flutter.isWidgetCreation(exp)))) {
      _coverageMarker();
      return;
    }
    String literalSrc = utils.getNodeText(node);
    int newlineIdx = literalSrc.lastIndexOf(eol);
    if (newlineIdx < 0 || newlineIdx == literalSrc.length - 1) {
      _coverageMarker();
      return; // Lists need to be in multi-line format already.
    }
    String indentOld = utils.getLinePrefix(node.offset + 1 + newlineIdx);
    String indentArg = '$indentOld${utils.getIndent(1)}';
    String indentList = '$indentOld${utils.getIndent(2)}';

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(node), (DartEditBuilder builder) {
        builder.write('[');
        builder.write(eol);
        builder.write(indentArg);
        builder.addSimpleLinkedEdit('WIDGET', 'widget');
        builder.write('(');
        builder.write(eol);
        builder.write(indentList);
        // Linked editing not needed since arg is always a list.
        builder.write('children: ');
        builder.write(literalSrc.replaceAll(
            new RegExp("^$indentOld", multiLine: true), "$indentList"));
        builder.write(',');
        builder.write(eol);
        builder.write(indentArg);
        builder.write('),');
        builder.write(eol);
        builder.write(indentOld);
        builder.write(']');
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_WRAP_GENERIC);
  }

  Future<void> _addProposal_replaceConditionalWithIfElse() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    ConditionalExpression conditional = null;
    // may be on Statement with Conditional
    Statement statement = node.thisOrAncestorOfType<Statement>();
    if (statement == null) {
      _coverageMarker();
      return;
    }
    // variable declaration
    bool inVariable = false;
    if (statement is VariableDeclarationStatement) {
      VariableDeclarationStatement variableStatement = statement;
      for (VariableDeclaration variable
          in variableStatement.variables.variables) {
        if (variable.initializer is ConditionalExpression) {
          conditional = variable.initializer as ConditionalExpression;
          inVariable = true;
          break;
        }
      }
    }
    // assignment
    bool inAssignment = false;
    if (statement is ExpressionStatement) {
      ExpressionStatement exprStmt = statement;
      if (exprStmt.expression is AssignmentExpression) {
        AssignmentExpression assignment =
            exprStmt.expression as AssignmentExpression;
        if (assignment.operator.type == TokenType.EQ &&
            assignment.rightHandSide is ConditionalExpression) {
          conditional = assignment.rightHandSide as ConditionalExpression;
          inAssignment = true;
        }
      }
    }
    // return
    bool inReturn = false;
    if (statement is ReturnStatement) {
      ReturnStatement returnStatement = statement;
      if (returnStatement.expression is ConditionalExpression) {
        conditional = returnStatement.expression as ConditionalExpression;
        inReturn = true;
      }
    }
    // prepare environment
    String indent = utils.getIndent(1);
    String prefix = utils.getNodePrefix(statement);

    if (inVariable || inAssignment || inReturn) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // Type v = Conditional;
        if (inVariable) {
          VariableDeclaration variable =
              conditional.parent as VariableDeclaration;
          builder.addDeletion(range.endEnd(variable.name, conditional));
          String conditionSrc = _getNodeText(conditional.condition);
          String thenSrc = _getNodeText(conditional.thenExpression);
          String elseSrc = _getNodeText(conditional.elseExpression);
          String name = variable.name.name;
          String src = eol;
          src += prefix + 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.endLength(statement, 0), src);
        }
        // v = Conditional;
        if (inAssignment) {
          AssignmentExpression assignment =
              conditional.parent as AssignmentExpression;
          Expression leftSide = assignment.leftHandSide;
          String conditionSrc = _getNodeText(conditional.condition);
          String thenSrc = _getNodeText(conditional.thenExpression);
          String elseSrc = _getNodeText(conditional.elseExpression);
          String name = _getNodeText(leftSide);
          String src = '';
          src += 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.node(statement), src);
        }
        // return Conditional;
        if (inReturn) {
          String conditionSrc = _getNodeText(conditional.condition);
          String thenSrc = _getNodeText(conditional.thenExpression);
          String elseSrc = _getNodeText(conditional.elseExpression);
          String src = '';
          src += 'if ($conditionSrc) {' + eol;
          src += prefix + indent + 'return $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + 'return $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.node(statement), src);
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE);
    }
  }

  Future<void> _addProposal_replaceIfElseWithConditional() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // should be "if"
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement ifStatement = node as IfStatement;
    // single then/else statements
    Statement thenStatement = getSingleStatement(ifStatement.thenStatement);
    Statement elseStatement = getSingleStatement(ifStatement.elseStatement);
    if (thenStatement == null || elseStatement == null) {
      _coverageMarker();
      return;
    }
    Expression thenExpression = null;
    Expression elseExpression = null;
    bool hasReturnStatements = false;
    if (thenStatement is ReturnStatement && elseStatement is ReturnStatement) {
      hasReturnStatements = true;
      thenExpression = thenStatement.expression;
      elseExpression = elseStatement.expression;
    }
    bool hasExpressionStatements = false;
    if (thenStatement is ExpressionStatement &&
        elseStatement is ExpressionStatement) {
      if (thenStatement.expression is AssignmentExpression &&
          elseStatement.expression is AssignmentExpression) {
        hasExpressionStatements = true;
        thenExpression = thenStatement.expression;
        elseExpression = elseStatement.expression;
      }
    }

    if (hasReturnStatements || hasExpressionStatements) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // returns
        if (hasReturnStatements) {
          String conditionSrc = _getNodeText(ifStatement.condition);
          String theSrc = _getNodeText(thenExpression);
          String elseSrc = _getNodeText(elseExpression);
          builder.addSimpleReplacement(range.node(ifStatement),
              'return $conditionSrc ? $theSrc : $elseSrc;');
        }
        // assignments -> v = Conditional;
        if (hasExpressionStatements) {
          AssignmentExpression thenAssignment = thenExpression;
          AssignmentExpression elseAssignment = elseExpression;
          String thenTarget = _getNodeText(thenAssignment.leftHandSide);
          String elseTarget = _getNodeText(elseAssignment.leftHandSide);
          if (thenAssignment.operator.type == TokenType.EQ &&
              elseAssignment.operator.type == TokenType.EQ &&
              thenTarget == elseTarget) {
            String conditionSrc = _getNodeText(ifStatement.condition);
            String theSrc = _getNodeText(thenAssignment.rightHandSide);
            String elseSrc = _getNodeText(elseAssignment.rightHandSide);
            builder.addSimpleReplacement(range.node(ifStatement),
                '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
    }
  }

  Future<void> _addProposal_sortChildPropertyLast() async {
    NamedExpression childProp = flutter.findNamedExpression(node, 'child');
    if (childProp == null) {
      childProp = flutter.findNamedExpression(node, 'children');
    }
    if (childProp == null) {
      return;
    }

    var parent = childProp.parent?.parent;
    if (parent is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(parent)) {
      return;
    }

    InstanceCreationExpression creationExpression = parent;
    var args = creationExpression.argumentList;

    var last = args.arguments.last;
    if (last == childProp) {
      // Already sorted.
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var start = childProp.beginToken.previous.end;
      var end = childProp.endToken.next.end;
      var childRange = range.startOffsetEndOffset(start, end);

      var childText = utils.getRangeText(childRange);
      builder.addSimpleReplacement(childRange, '');
      builder.addSimpleInsertion(last.end + 1, childText);

      changeBuilder.setSelection(new Position(file, last.end + 1));
    });

    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.SORT_CHILD_PROPERTY_LAST);
  }

  Future<void> _addProposal_splitAndCondition() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      _coverageMarker();
      return;
    }
    BinaryExpression binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!_isOperatorSelected(
        binaryExpression, selectionOffset, selectionLength)) {
      _coverageMarker();
      return;
    }
    // should be &&
    if (binaryExpression.operator.type != TokenType.AMPERSAND_AMPERSAND) {
      _coverageMarker();
      return;
    }
    // prepare "if"
    Statement statement = node.thisOrAncestorOfType<Statement>();
    if (statement is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement ifStatement = statement as IfStatement;
    // no support "else"
    if (ifStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // check that binary expression is part of first level && condition of "if"
    BinaryExpression condition = binaryExpression;
    while (condition.parent is BinaryExpression &&
        (condition.parent as BinaryExpression).operator.type ==
            TokenType.AMPERSAND_AMPERSAND) {
      condition = condition.parent as BinaryExpression;
    }
    if (ifStatement.condition != condition) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(ifStatement);
    String indent = utils.getIndent(1);
    // prepare "rightCondition"
    String rightConditionSource;
    {
      SourceRange rightConditionRange =
          range.startEnd(binaryExpression.rightOperand, condition);
      rightConditionSource = _getRangeText(rightConditionRange);
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // remove "&& rightCondition"
      builder
          .addDeletion(range.endEnd(binaryExpression.leftOperand, condition));
      // update "then" statement
      Statement thenStatement = ifStatement.thenStatement;
      if (thenStatement is Block) {
        Block thenBlock = thenStatement;
        SourceRange thenBlockRange = range.node(thenBlock);
        // insert inner "if" with right part of "condition"
        int thenBlockInsideOffset = thenBlockRange.offset + 1;
        builder.addSimpleInsertion(thenBlockInsideOffset,
            '$eol$prefix${indent}if ($rightConditionSource) {');
        // insert closing "}" for inner "if"
        int thenBlockEnd = thenBlockRange.end;
        // insert before outer "then" block "}"
        builder.addSimpleInsertion(thenBlockEnd - 1, '$indent}$eol$prefix');
      } else {
        // insert inner "if" with right part of "condition"
        String source = '$eol$prefix${indent}if ($rightConditionSource)';
        builder.addSimpleInsertion(
            ifStatement.rightParenthesis.offset + 1, source);
      }
      // indent "then" statements to correspond inner "if"
      {
        List<Statement> thenStatements = getStatements(thenStatement);
        SourceRange linesRange = utils.getLinesRangeStatements(thenStatements);
        String thenIndentOld = '$prefix$indent';
        String thenIndentNew = '$thenIndentOld$indent';
        builder.addSimpleReplacement(
            linesRange,
            utils.replaceSourceRangeIndent(
                linesRange, thenIndentOld, thenIndentNew));
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.SPLIT_AND_CONDITION);
  }

  Future<void> _addProposal_splitVariableDeclaration() async {
    var variableList = node?.thisOrAncestorOfType<VariableDeclarationList>();

    // Must be a local variable declaration.
    if (variableList?.parent is! VariableDeclarationStatement) {
      return;
    }
    VariableDeclarationStatement statement = variableList.parent;

    // Cannot be `const` or `final`.
    var keywordKind = variableList.keyword?.keyword;
    if (keywordKind == Keyword.CONST || keywordKind == Keyword.FINAL) {
      return;
    }

    var variables = variableList.variables;
    if (variables.length != 1) {
      return;
    }

    // The caret must be between the type and the variable name.
    var variable = variables[0];
    if (!range.startEnd(statement, variable.name).contains(selectionOffset)) {
      return;
    }

    // The variable must have an initializer.
    if (variable.initializer == null) {
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (builder) {
      if (variableList.type == null) {
        builder.addReplacement(range.token(variableList.keyword), (builder) {
          var type = variable.declaredElement.type;
          builder.writeType(type);
        });
      }

      var indent = utils.getNodePrefix(statement);
      var name = variable.name.name;
      builder.addSimpleInsertion(variable.name.end, ';' + eol + indent + name);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.SPLIT_VARIABLE_DECLARATION);
  }

  Future<void> _addProposal_surroundWith() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // prepare selected statements
    List<Statement> selectedStatements;
    {
      StatementAnalyzer selectionAnalyzer = new StatementAnalyzer(
          context.resolveResult,
          new SourceRange(selectionOffset, selectionLength));
      selectionAnalyzer.analyze();
      List<AstNode> selectedNodes = selectionAnalyzer.selectedNodes;
      // convert nodes to statements
      selectedStatements = [];
      for (AstNode selectedNode in selectedNodes) {
        if (selectedNode is Statement) {
          selectedStatements.add(selectedNode);
        }
      }
      // we want only statements in blocks
      for (var statement in selectedStatements) {
        if (statement.parent is! Block) {
          return;
        }
      }
      // we want only statements
      if (selectedStatements.isEmpty ||
          selectedStatements.length != selectedNodes.length) {
        return;
      }
    }
    // prepare statement information
    Statement firstStatement = selectedStatements[0];
    SourceRange statementsRange =
        utils.getLinesRangeStatements(selectedStatements);
    // prepare environment
    String indentOld = utils.getNodePrefix(firstStatement);
    String indentNew = '$indentOld${utils.getIndent(1)}';
    String indentedCode =
        utils.replaceSourceRangeIndent(statementsRange, indentOld, indentNew);
    // "block"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(statementsRange.offset, '$indentOld{$eol');
        builder.addSimpleReplacement(
            statementsRange,
            utils.replaceSourceRangeIndent(
                statementsRange, indentOld, indentNew));
        builder.addSimpleInsertion(statementsRange.end, '$indentOld}$eol');
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_BLOCK);
    }
    // "if"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('if (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_IF);
    }
    // "while"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('while (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_WHILE);
    }
    // "for-in"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('for (var ');
          builder.addSimpleLinkedEdit('NAME', 'item');
          builder.write(' in ');
          builder.addSimpleLinkedEdit('ITERABLE', 'iterable');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_FOR_IN);
    }
    // "for"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('for (var ');
          builder.addSimpleLinkedEdit('VAR', 'v');
          builder.write(' = ');
          builder.addSimpleLinkedEdit('INIT', 'init');
          builder.write('; ');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write('; ');
          builder.addSimpleLinkedEdit('INCREMENT', 'increment');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_FOR);
    }
    // "do-while"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('do {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('} while (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(');');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_DO_WHILE);
    }
    // "try-catch"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('try {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('} on ');
          builder.addSimpleLinkedEdit('EXCEPTION_TYPE', 'Exception');
          builder.write(' catch (');
          builder.addSimpleLinkedEdit('EXCEPTION_VAR', 'e');
          builder.write(') {');
          builder.write(eol);
          //
          builder.write(indentNew);
          builder.addSimpleLinkedEdit('CATCH', '// TODO');
          builder.selectHere();
          builder.write(eol);
          //
          builder.write(indentOld);
          builder.write('}');
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_TRY_CATCH);
    }
    // "try-finally"
    {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('try {');
          builder.write(eol);
          //
          builder.write(indentedCode);
          //
          builder.write(indentOld);
          builder.write('} finally {');
          builder.write(eol);
          //
          builder.write(indentNew);
          builder.addSimpleLinkedEdit('FINALLY', '// TODO');
          builder.selectHere();
          builder.write(eol);
          //
          builder.write(indentOld);
          builder.write('}');
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_TRY_FINALLY);
    }
  }

  Future<void> _addProposal_useCurlyBraces() async {
    Future<void> doStatement(DoStatement node) async {
      var body = node.body;
      if (body is Block) return;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.doKeyword, body),
          ' {$eol$indent',
        );
        builder.addSimpleReplacement(
          range.endStart(body, node.whileKeyword),
          '$eol$prefix} ',
        );
      });

      _addAssistFromBuilder(changeBuilder, DartAssistKind.USE_CURLY_BRACES);
    }

    Future<void> forStatement(ForStatement node) async {
      var body = node.body;
      if (body is Block) return;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.rightParenthesis, body),
          ' {$eol$indent',
        );
        builder.addSimpleInsertion(body.end, '$eol$prefix}');
      });

      _addAssistFromBuilder(changeBuilder, DartAssistKind.USE_CURLY_BRACES);
    }

    Future<void> ifStatement(IfStatement node, Statement thenOrElse) async {
      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        var thenStatement = node.thenStatement;
        if (thenStatement is! Block &&
            (thenOrElse == null || thenOrElse == thenStatement)) {
          builder.addSimpleReplacement(
            range.endStart(node.rightParenthesis, thenStatement),
            ' {$eol$indent',
          );
          if (node.elseKeyword != null) {
            builder.addSimpleReplacement(
              range.endStart(thenStatement, node.elseKeyword),
              '$eol$prefix} ',
            );
          } else {
            builder.addSimpleInsertion(thenStatement.end, '$eol$prefix}');
          }
        }

        var elseStatement = node.elseStatement;
        if (elseStatement != null &&
            elseStatement is! Block &&
            (thenOrElse == null || thenOrElse == elseStatement)) {
          builder.addSimpleReplacement(
            range.endStart(node.elseKeyword, elseStatement),
            ' {$eol$indent',
          );
          builder.addSimpleInsertion(elseStatement.end, '$eol$prefix}');
        }
      });

      _addAssistFromBuilder(changeBuilder, DartAssistKind.USE_CURLY_BRACES);
    }

    Future<void> whileStatement(WhileStatement node) async {
      var body = node.body;
      if (body is Block) return;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.rightParenthesis, body),
          ' {$eol$indent',
        );
        builder.addSimpleInsertion(body.end, '$eol$prefix}');
      });

      _addAssistFromBuilder(changeBuilder, DartAssistKind.USE_CURLY_BRACES);
    }

    var statement = this.node.thisOrAncestorOfType<Statement>();
    var parent = statement?.parent;

    if (statement is DoStatement) {
      return doStatement(statement);
    } else if (parent is DoStatement) {
      return doStatement(parent);
    } else if (statement is ForStatement) {
      return forStatement(statement);
    } else if (parent is ForStatement) {
      return forStatement(parent);
    } else if (statement is IfStatement) {
      if (statement.elseKeyword != null &&
          range.token(statement.elseKeyword).contains(selectionOffset)) {
        return ifStatement(statement, statement.elseStatement);
      } else {
        return ifStatement(statement, null);
      }
    } else if (parent is IfStatement) {
      return ifStatement(parent, statement);
    } else if (statement is WhileStatement) {
      return whileStatement(statement);
    } else if (parent is WhileStatement) {
      return whileStatement(parent);
    }
  }

  /**
   * Return `true` if all of the parameters in the given list of [parameters]
   * have an explicit type annotation.
   */
  bool _allParametersHaveTypes(FormalParameterList parameters) {
    for (FormalParameter parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = (parameter as DefaultFormalParameter).parameter;
      }
      if (parameter is SimpleFormalParameter) {
        if (parameter.type == null) {
          return false;
        }
      } else if (parameter is! FunctionTypedFormalParameter) {
        return false;
      }
    }
    return true;
  }

  /**
   * Configures [utils] using given [target].
   */
  void _configureTargetLocation(Object target) {
    utils.targetClassElement = null;
    if (target is AstNode) {
      ClassDeclaration targetClassDeclaration =
          target.thisOrAncestorOfType<ClassDeclaration>();
      if (targetClassDeclaration != null) {
        utils.targetClassElement = targetClassDeclaration.declaredElement;
      }
    }
  }

  void _convertFlutterChildToChildren(
      NamedExpression namedExp,
      String eol,
      Function getNodeText,
      Function getLinePrefix,
      Function getIndent,
      Function getText,
      DartFileEditBuilder builder) {
    Expression childArg = namedExp.expression;
    int childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    int listLoc = childArg.offset;
    String childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '<Widget>[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      int newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      String indentOld = getLinePrefix(childArg.offset + 1 + newlineLoc);
      String indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      String separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      String prefix = separator.contains(eol) ? "" : "$eol$indentNew";
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(
            namedExp.offset + 'child:'.length, ' <Widget>[');
        int argOffset = childArg.offset;
        builder
            .addDeletion(range.startOffsetEndOffset(argOffset - 2, argOffset));
      } else {
        builder.addSimpleInsertion(listLoc, '<Widget>[');
      }
      String newChildArgSrc =
          _replaceSourceIndent(childArgSrc, indentOld, indentNew);
      newChildArgSrc = "$prefix$newChildArgSrc,$eol$indentOld]";
      builder.addSimpleReplacement(range.node(childArg), newChildArgSrc);
    }
  }

  Future<void> _convertFunctionTypeAliasToGenericTypeAlias(
      FunctionTypeAlias node) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
    }
    String functionName = utils.getRangeText(
        range.startEnd(node.name, node.typeParameters ?? node.name));
    String parameters = utils.getNodeText(node.parameters);
    String replacement;
    if (returnType == null) {
      replacement = '$functionName = Function$parameters';
    } else {
      replacement = '$functionName = $returnType Function$parameters';
    }
    // add change
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.startStart(node.typedefKeyword.next, node.semicolon),
          replacement);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_GENERIC_FUNCTION_SYNTAX);
  }

  Future<void> _convertFunctionTypedFormalParameterToSimpleFormalParameter(
      FunctionTypedFormalParameter node) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
    }
    String functionName = utils.getRangeText(range.startEnd(
        node.identifier, node.typeParameters ?? node.identifier));
    String parameters = utils.getNodeText(node.parameters);
    String replacement;
    if (returnType == null) {
      replacement = 'Function$parameters $functionName';
    } else {
      replacement = '$returnType Function$parameters $functionName';
    }
    // add change
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(node), replacement);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_GENERIC_FUNCTION_SYNTAX);
  }

  Future<void> _convertQuotes(bool fromDouble, AssistKind kind) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (node is SimpleStringLiteral) {
      SimpleStringLiteral literal = node;
      if (fromDouble ? !literal.isSingleQuoted : literal.isSingleQuoted) {
        String newQuote = literal.isMultiline
            ? (fromDouble ? "'''" : '"""')
            : (fromDouble ? "'" : '"');
        int quoteLength = literal.isMultiline ? 3 : 1;
        String lexeme = literal.literal.lexeme;
        if (lexeme.indexOf(newQuote) < 0) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(
                new SourceRange(
                    literal.offset + (literal.isRaw ? 1 : 0), quoteLength),
                newQuote);
            builder.addSimpleReplacement(
                new SourceRange(literal.end - quoteLength, quoteLength),
                newQuote);
          });
          _addAssistFromBuilder(changeBuilder, kind);
        }
      }
    } else if (node is InterpolationString) {
      StringInterpolation parent = node.parent;
      if (fromDouble ? !parent.isSingleQuoted : parent.isSingleQuoted) {
        String newQuote = parent.isMultiline
            ? (fromDouble ? "'''" : '"""')
            : (fromDouble ? "'" : '"');
        int quoteLength = parent.isMultiline ? 3 : 1;
        NodeList<InterpolationElement> elements = parent.elements;
        for (int i = 0; i < elements.length; i++) {
          InterpolationElement element = elements[i];
          if (element is InterpolationString) {
            String lexeme = element.contents.lexeme;
            if (lexeme.indexOf(newQuote) >= 0) {
              return;
            }
          }
        }
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              new SourceRange(
                  parent.offset + (parent.isRaw ? 1 : 0), quoteLength),
              newQuote);
          builder.addSimpleReplacement(
              new SourceRange(parent.end - quoteLength, quoteLength), newQuote);
        });
        _addAssistFromBuilder(changeBuilder, kind);
      }
    }
  }

  /**
   * Returns the text of the given node in the unit.
   */
  String _getNodeText(AstNode node) {
    return utils.getNodeText(node);
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String _getRangeText(SourceRange range) {
    return utils.getRangeText(range);
  }

  /// Return `true` if the [element] is sufficient to lexically make the
  /// enclosing literal a set literal rather than a map.
  bool _isUnambiguousElement(CollectionElement element) {
    if (element is ForElement) {
      return _isUnambiguousElement(element.body);
    } else if (element is IfElement) {
      return _isUnambiguousElement(element.thenElement) ||
          _isUnambiguousElement(element.elseElement);
    } else if (element is Expression) {
      return true;
    }
    return false;
  }

  /// Return `true` if the given [node] is a list literal whose elements, if
  /// placed inside curly braces, would lexically make the resulting literal a
  /// set literal rather than a map literal.
  bool _listHasUnambiguousElement(AstNode node) {
    if (node is ListLiteral && node.elements.isNotEmpty) {
      for (CollectionElement element in node.elements) {
        if (_isUnambiguousElement(element)) {
          return true;
        }
      }
    }
    return false;
  }

  DartChangeBuilder _newDartChangeBuilder() {
    return new DartChangeBuilderImpl.forWorkspace(context.workspace);
  }

  bool _setupCompute() {
    var locator = new NodeLocator(selectionOffset, selectionEnd);
    node = locator.searchWithin(context.resolveResult.unit);
    return node != null;
  }

  Future<void> _swapParentAndChild(InstanceCreationExpression parent,
      InstanceCreationExpression child, AssistKind kind) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // The child must have its own child.
    if (flutter.findChildArgument(child) == null) {
      _coverageMarker();
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (builder) {
      builder.addReplacement(range.node(parent), (builder) {
        var childArgs = child.argumentList;
        var parentArgs = parent.argumentList;
        var childText = _getRangeText(range.startStart(child, childArgs));
        var parentText = _getRangeText(range.startStart(parent, parentArgs));

        var parentIndent = utils.getLinePrefix(parent.offset);
        var childIndent = parentIndent + '  ';

        // Write the beginning of the child.
        builder.write(childText);
        builder.writeln('(');

        // Write all the arguments of the parent.
        // Don't write the "child".
        Expression stableChild;
        for (Expression argument in childArgs.arguments) {
          if (flutter.isChildArgument(argument)) {
            stableChild = argument;
          } else {
            String text = _getNodeText(argument);
            text = _replaceSourceIndent(text, childIndent, parentIndent);
            builder.write(parentIndent);
            builder.write('  ');
            builder.write(text);
            builder.writeln(',');
          }
        }

        // Write the parent as a new child.
        builder.write(parentIndent);
        builder.write('  ');
        builder.write('child: ');
        builder.write(parentText);
        builder.writeln('(');

        // Write all arguments of the parent.
        // Don't write its child.
        for (Expression argument in parentArgs.arguments) {
          if (!flutter.isChildArgument(argument)) {
            String text = _getNodeText(argument);
            text = _replaceSourceIndent(text, parentIndent, childIndent);
            builder.write(childIndent);
            builder.write('  ');
            builder.write(text);
            builder.writeln(',');
          }
        }

        // Write the child of the "child" now, as the child of the "parent".
        {
          var text = _getNodeText(stableChild);
          builder.write(childIndent);
          builder.write('  ');
          builder.write(text);
          builder.writeln(',');
        }

        // Close the parent expression.
        builder.write(childIndent);
        builder.writeln('),');

        // Close the child expression.
        builder.write(parentIndent);
        builder.write(')');
      });
    });
    _addAssistFromBuilder(changeBuilder, kind);
  }

  /**
   * This method does nothing, but we invoke it in places where Dart VM
   * coverage agent fails to provide coverage information - such as almost
   * all "return" statements.
   *
   * https://code.google.com/p/dart/issues/detail?id=19912
   */
  static void _coverageMarker() {}

  /**
   * Returns `true` if the selection covers an operator of the given
   * [BinaryExpression].
   */
  static bool _isOperatorSelected(
      BinaryExpression binaryExpression, int offset, int length) {
    AstNode left = binaryExpression.leftOperand;
    AstNode right = binaryExpression.rightOperand;
    // between the nodes
    if (offset >= left.endToken.end && offset + length <= right.offset) {
      _coverageMarker();
      return true;
    }
    // or exactly select the node (but not with infix expressions)
    if (offset == left.offset && offset + length == right.endToken.end) {
      if (left is BinaryExpression || right is BinaryExpression) {
        _coverageMarker();
        return false;
      }
      _coverageMarker();
      return true;
    }
    // invalid selection (part of node, etc)
    _coverageMarker();
    return false;
  }

  static String _replaceSourceIndent(
      String source, String indentOld, String indentNew) {
    return source.replaceAll(
        new RegExp('^$indentOld', multiLine: true), indentNew);
  }

  /**
   * Checks if the given [Expression] should be wrapped with parenthesis when we
   * want to use it as operand of a logical `and` expression.
   */
  static bool _shouldWrapParenthesisBeforeAnd(Expression expr) {
    if (expr is BinaryExpression) {
      BinaryExpression binary = expr;
      int precedence = binary.operator.type.precedence;
      return precedence < TokenClass.LOGICAL_AND_OPERATOR.precedence;
    }
    return false;
  }
}

/**
 * A visitor that can be used to find references to a parameter.
 */
class _ParameterReferenceFinder extends RecursiveAstVisitor<void> {
  /**
   * The parameter for which references are being sought, or `null` if we are
   * just accumulating a list of referenced names.
   */
  final ParameterElement parameter;

  /**
   * A list of the simple identifiers that reference the [parameter].
   */
  final List<SimpleIdentifier> references = <SimpleIdentifier>[];

  /**
   * A collection of the names of other simple identifiers that were found. We
   * need to know these in order to ensure that the selected loop variable does
   * not hide a name from an enclosing scope that is already being referenced.
   */
  final Set<String> otherNames = new Set<String>();

  /**
   * Initialize a newly created finder to find references to the [parameter].
   */
  _ParameterReferenceFinder(this.parameter) : assert(parameter != null);

  /**
   * Return `true` if the parameter is unreferenced in the nodes that have been
   * visited.
   */
  bool get isParameterUnreferenced => references.isEmpty;

  /**
   * Return `true` is the given name (assumed to be different than the name of
   * the parameter) is references in the nodes that have been visited.
   */
  bool referencesName(String name) => otherNames.contains(name);

  /**
   * Replace all of the references to the parameter in the given [source] with
   * the [newName]. The [offset] is the offset of the first character of the
   * [source] relative to the start of the file.
   */
  String replaceName(String source, String newName, int offset) {
    int oldLength = parameter.name.length;
    for (int i = references.length - 1; i >= 0; i--) {
      int oldOffset = references[i].offset - offset;
      source = source.replaceRange(oldOffset, oldOffset + oldLength, newName);
    }
    return source;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == parameter) {
      references.add(node);
    } else if (!node.isQualified) {
      // Only non-prefixed identifiers can be hidden.
      otherNames.add(node.name);
    }
  }
}

class _SimpleIdentifierRecursiveAstVisitor extends RecursiveAstVisitor {
  final _SimpleIdentifierVisitor visitor;

  _SimpleIdentifierRecursiveAstVisitor(this.visitor);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    visitor(node);
  }
}

/**
 * A visitor used to find all of the classes that define members referenced via
 * `super`.
 */
class _SuperclassReferenceFinder extends RecursiveAstVisitor {
  final List<ClassElement> referencedClasses = <ClassElement>[];

  _SuperclassReferenceFinder();

  @override
  visitSuperExpression(SuperExpression node) {
    AstNode parent = node.parent;
    if (parent is BinaryExpression) {
      _addElement(parent.staticElement);
    } else if (parent is IndexExpression) {
      _addElement(parent.staticElement);
    } else if (parent is MethodInvocation) {
      _addIdentifier(parent.methodName);
    } else if (parent is PrefixedIdentifier) {
      _addIdentifier(parent.identifier);
    } else if (parent is PropertyAccess) {
      _addIdentifier(parent.propertyName);
    }
    return super.visitSuperExpression(node);
  }

  void _addElement(Element element) {
    if (element is ExecutableElement) {
      Element enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement) {
        referencedClasses.add(enclosingElement);
      }
    }
  }

  void _addIdentifier(SimpleIdentifier identifier) {
    _addElement(identifier.staticElement);
  }
}
