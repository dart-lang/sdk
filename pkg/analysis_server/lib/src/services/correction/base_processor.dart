// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// Base class for common processor functionality.
abstract class BaseProcessor {
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CorrectionUtils utils;
  final String file;

  final TypeProvider typeProvider;
  final Flutter flutter;

  final AnalysisSession session;
  final AnalysisSessionHelper sessionHelper;
  final ResolvedUnitResult resolvedResult;
  final ChangeWorkspace workspace;

  AstNode node;

  BaseProcessor({
    this.selectionOffset = -1,
    this.selectionLength = 0,
    @required this.resolvedResult,
    @required this.workspace,
  })  : file = resolvedResult.path,
        flutter = Flutter.of(resolvedResult),
        session = resolvedResult.session,
        sessionHelper = AnalysisSessionHelper(resolvedResult.session),
        typeProvider = resolvedResult.typeProvider,
        selectionEnd = (selectionOffset ?? 0) + (selectionLength ?? 0),
        utils = CorrectionUtils(resolvedResult);

  /// Returns the EOL to use for this [CompilationUnit].
  String get eol => utils.endOfLine;

  /// Return the status of known experiments.
  ExperimentStatus get experimentStatus =>
      (session.analysisContext.analysisOptions as AnalysisOptionsImpl)
          .experimentStatus;

  Future<ChangeBuilder>
      createBuilder_addTypeAnnotation_DeclaredIdentifier() async {
    var declaredIdentifier = node.thisOrAncestorOfType<DeclaredIdentifier>();
    if (declaredIdentifier == null) {
      var forEach = node.thisOrAncestorMatching((node) =>
              node is ForStatement && node.forLoopParts is ForEachParts)
          as ForStatement;
      ForEachParts forEachParts = forEach?.forLoopParts;
      var offset = node.offset;
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
      return null;
    }
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      _coverageMarker();
      return null;
    }
    var type = declaredIdentifier.declaredElement.type;
    if (type is! InterfaceType && type is! FunctionType) {
      _coverageMarker();
      return null;
    }
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    var validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var keyword = declaredIdentifier.keyword;
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
    return validChange ? changeBuilder : null;
  }

  Future<ChangeBuilder>
      createBuilder_addTypeAnnotation_SimpleFormalParameter() async {
    var node = this.node;
    // should be the name of a simple parameter
    if (node is! SimpleIdentifier || node.parent is! SimpleFormalParameter) {
      _coverageMarker();
      return null;
    }
    SimpleIdentifier name = node;
    SimpleFormalParameter parameter = node.parent;
    // the parameter should not have a type
    if (parameter.type != null) {
      _coverageMarker();
      return null;
    }
    // prepare the type
    var type = parameter.declaredElement.type;
    // TODO(scheglov) If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType) {
      _coverageMarker();
      return null;
    }
    // prepare type source
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    var validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(name.offset, (DartEditBuilder builder) {
        validChange = builder.writeType(type);
        builder.write(' ');
      });
    });
    return validChange ? changeBuilder : null;
  }

  Future<ChangeBuilder>
      createBuilder_addTypeAnnotation_VariableDeclaration() async {
    var node = this.node;
    // prepare VariableDeclarationList
    var declarationList = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declarationList == null) {
      _coverageMarker();
      return null;
    }
    // may be has type annotation already
    if (declarationList.type != null) {
      _coverageMarker();
      return null;
    }
    // prepare single VariableDeclaration
    List<VariableDeclaration> variables = declarationList.variables;
    if (variables.length != 1) {
      _coverageMarker();
      return null;
    }
    var variable = variables[0];
    // must be not after the name of the variable
    if (selectionOffset > variable.name.end) {
      _coverageMarker();
      return null;
    }
    // we need an initializer to get the type from
    var initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return null;
    }
    var type = initializer.staticType;
    // prepare type source
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType) {
      _coverageMarker();
      return null;
    }
    _configureTargetLocation(node);

    var changeBuilder = _newDartChangeBuilder();
    var validChange = true;
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var keyword = declarationList.keyword;
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
    return validChange ? changeBuilder : null;
  }

  Future<ConvertToSpreadCollectionsChange>
      createBuilder_convertAddAllToSpread() async {
    var node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      _coverageMarker();
      return null;
    }
    SimpleIdentifier name = node;
    MethodInvocation invocation = node.parent;
    if (name != invocation.methodName ||
        name.name != 'addAll' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      _coverageMarker();
      return null;
    }
    var cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    var sections = cascade.cascadeSections;
    var target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      _coverageMarker();
      return null;
    }

    bool isEmptyListLiteral(Expression expression) =>
        expression is ListLiteral && expression.elements.isEmpty;

    ListLiteral list = target;
    var argument = invocation.argumentList.arguments[0];
    String elementText;
    var change = ConvertToSpreadCollectionsChange();
    List<String> args;
    if (argument is BinaryExpression &&
        argument.operator.type == TokenType.QUESTION_QUESTION) {
      var right = argument.rightOperand;
      if (isEmptyListLiteral(right)) {
        // ..addAll(things ?? const [])
        // ..addAll(things ?? [])
        elementText = '...?${utils.getNodeText(argument.leftOperand)}';
      }
    } else if (experimentStatus.control_flow_collections &&
        argument is ConditionalExpression) {
      var elseExpression = argument.elseExpression;
      if (isEmptyListLiteral(elseExpression)) {
        // ..addAll(condition ? things : const [])
        // ..addAll(condition ? things : [])
        var conditionText = utils.getNodeText(argument.condition);
        var thenText = utils.getNodeText(argument.thenExpression);
        elementText = 'if ($conditionText) ...$thenText';
      }
    } else if (argument is ListLiteral) {
      // ..addAll([ ... ])
      var elements = argument.elements;
      if (elements.isEmpty) {
        // TODO(brianwilkerson) Consider adding a cleanup for the empty list
        //  case. We can essentially remove the whole invocation because it does
        //  nothing.
        return null;
      }
      var startOffset = elements.first.offset;
      var endOffset = elements.last.end;
      elementText = utils.getText(startOffset, endOffset - startOffset);
      change.isLineInvocation = true;
      args = ['addAll'];
    }
    elementText ??= '...${utils.getNodeText(argument)}';
    var changeBuilder = _newDartChangeBuilder();
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
    change.args = args;
    change.builder = changeBuilder;
    return change;
  }

  Future<ChangeBuilder>
      createBuilder_convertConditionalExpressionToIfElement() async {
    AstNode node = this.node.thisOrAncestorOfType<ConditionalExpression>();
    if (node == null) {
      _coverageMarker();
      return null;
    }
    var nodeToReplace = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      nodeToReplace = parent;
      parent = parent.parent;
    }
    if (parent is ListLiteral || (parent is SetOrMapLiteral && parent.isSet)) {
      ConditionalExpression conditional = node;
      var condition = conditional.condition.unParenthesized;
      var thenExpression = conditional.thenExpression.unParenthesized;
      var elseExpression = conditional.elseExpression.unParenthesized;

      var changeBuilder = _newDartChangeBuilder();
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
      return changeBuilder;
    }

    return null;
  }

  Future<ChangeBuilder> createBuilder_convertDocumentationIntoLine() async {
    var comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null ||
        !comment.isDocumentation ||
        comment.tokens.length != 1) {
      _coverageMarker();
      return null;
    }
    var token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      _coverageMarker();
      return null;
    }
    var text = token.lexeme;
    var lines = text.split('\n');
    var prefix = utils.getNodePrefix(comment);
    var newLines = <String>[];
    var firstLine = true;
    var linePrefix = '';
    for (var line in lines) {
      if (firstLine) {
        firstLine = false;
        var expectedPrefix = '/**';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return null;
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
        var expectedPrefix = prefix + ' *';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return null;
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
        for (var newLine in newLines) {
          builder.write(newLine);
        }
      });
    });
    return changeBuilder;
  }

  Future<ChangeBuilder>
      createBuilder_convertMapFromIterableToForLiteral() async {
    //
    // Ensure that the selection is inside an invocation of Map.fromIterable.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      _coverageMarker();
      return null;
    }
    var element = creation.staticElement;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != typeProvider.mapElement) {
      _coverageMarker();
      return null;
    }
    //
    // Ensure that the arguments have the right form.
    //
    var arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      _coverageMarker();
      return null;
    }
    var iterator = arguments[0].unParenthesized;
    var secondArg = arguments[1];
    var thirdArg = arguments[2];

    Expression extractBody(FunctionExpression expression) {
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else if (body is BlockFunctionBody) {
        var statements = body.block.statements;
        if (statements.length == 1) {
          var statement = statements[0];
          if (statement is ReturnStatement) {
            return statement.expression;
          }
        }
      }
      return null;
    }

    FunctionExpression extractClosure(String name, Expression argument) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        var expression = argument.expression.unParenthesized;
        if (expression is FunctionExpression) {
          var parameters = expression.parameters.parameters;
          if (parameters.length == 1 && parameters[0].isRequiredPositional) {
            if (extractBody(expression) != null) {
              return expression;
            }
          }
        }
      }
      return null;
    }

    var keyClosure =
        extractClosure('key', secondArg) ?? extractClosure('key', thirdArg);
    var valueClosure =
        extractClosure('value', thirdArg) ?? extractClosure('value', secondArg);
    if (keyClosure == null || valueClosure == null) {
      _coverageMarker();
      return null;
    }
    //
    // Compute the loop variable name and convert the key and value closures if
    // necessary.
    //
    SimpleFormalParameter keyParameter = keyClosure.parameters.parameters[0];
    var keyParameterName = keyParameter.identifier.name;
    SimpleFormalParameter valueParameter =
        valueClosure.parameters.parameters[0];
    var valueParameterName = valueParameter.identifier.name;
    var keyBody = extractBody(keyClosure);
    var keyExpressionText = utils.getNodeText(keyBody);
    var valueBody = extractBody(valueClosure);
    var valueExpressionText = utils.getNodeText(valueBody);

    String loopVariableName;
    if (keyParameterName == valueParameterName) {
      loopVariableName = keyParameterName;
    } else {
      var keyFinder = _ParameterReferenceFinder(keyParameter.declaredElement);
      keyBody.accept(keyFinder);

      var valueFinder =
          _ParameterReferenceFinder(valueParameter.declaredElement);
      valueBody.accept(valueFinder);

      String computeUnusedVariableName() {
        var candidate = 'e';
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
    var changeBuilder = _newDartChangeBuilder();
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
    return changeBuilder;
  }

  Future<ChangeBuilder> createBuilder_convertQuotes(bool fromDouble) async {
    if (node is SimpleStringLiteral) {
      SimpleStringLiteral literal = node;
      if (fromDouble ? !literal.isSingleQuoted : literal.isSingleQuoted) {
        var newQuote = literal.isMultiline
            ? (fromDouble ? "'''" : '"""')
            : (fromDouble ? "'" : '"');
        var quoteLength = literal.isMultiline ? 3 : 1;
        var lexeme = literal.literal.lexeme;
        if (!lexeme.contains(newQuote)) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(
                SourceRange(
                    literal.offset + (literal.isRaw ? 1 : 0), quoteLength),
                newQuote);
            builder.addSimpleReplacement(
                SourceRange(literal.end - quoteLength, quoteLength), newQuote);
          });
          return changeBuilder;
        }
      }
    } else if (node is InterpolationString) {
      StringInterpolation parent = node.parent;
      if (fromDouble ? !parent.isSingleQuoted : parent.isSingleQuoted) {
        var newQuote = parent.isMultiline
            ? (fromDouble ? "'''" : '"""')
            : (fromDouble ? "'" : '"');
        var quoteLength = parent.isMultiline ? 3 : 1;
        var elements = parent.elements;
        for (var i = 0; i < elements.length; i++) {
          var element = elements[i];
          if (element is InterpolationString) {
            var lexeme = element.contents.lexeme;
            if (lexeme.contains(newQuote)) {
              return null;
            }
          }
        }
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              SourceRange(parent.offset + (parent.isRaw ? 1 : 0), quoteLength),
              newQuote);
          builder.addSimpleReplacement(
              SourceRange(parent.end - quoteLength, quoteLength), newQuote);
        });
        return changeBuilder;
      }
    }
    return null;
  }

  Future<ChangeBuilder> createBuilder_convertToExpressionFunctionBody() async {
    // prepare current body
    var body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody || body.isGenerator) {
      _coverageMarker();
      return null;
    }
    // prepare return statement
    List<Statement> statements = (body as BlockFunctionBody).block.statements;
    if (statements.length != 1) {
      _coverageMarker();
      return null;
    }
    var onlyStatement = statements.first;
    // prepare returned expression
    Expression returnExpression;
    if (onlyStatement is ReturnStatement) {
      returnExpression = onlyStatement.expression;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;
    }
    if (returnExpression == null) {
      _coverageMarker();
      return null;
    }

    // Return expressions can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in the function body.
    if (selectionOffset >= returnExpression.offset) {
      _coverageMarker();
      return null;
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
    return changeBuilder;
  }

  Future<ChangeBuilder> createBuilder_convertToGenericFunctionSyntax() async {
    var node = this.node;
    while (node != null) {
      if (node is FunctionTypeAlias) {
        return _createBuilder_convertFunctionTypeAliasToGenericTypeAlias(node);
      } else if (node is FunctionTypedFormalParameter) {
        return _createBuilder_convertFunctionTypedFormalParameterToGenericTypeAlias(
            node);
      } else if (node is FormalParameterList) {
        // It would be confusing for this assist to alter a surrounding context
        // when the selection is inside a parameter list.
        return null;
      }
      node = node.parent;
    }
    return null;
  }

  Future<ChangeBuilder> createBuilder_convertToIntLiteral() async {
    if (node is! DoubleLiteral) {
      _coverageMarker();
      return null;
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
      return null;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(SourceRange(literal.offset, literal.length),
          (DartEditBuilder builder) {
        builder.write('$intValue');
      });
    });
    return changeBuilder;
  }

  FunctionBody getEnclosingFunctionBody() {
    // TODO(brianwilkerson) Determine whether there is a reason why this method
    // isn't just "return node.getAncestor((node) => node is FunctionBody);"
    {
      var function = node.thisOrAncestorOfType<FunctionExpression>();
      if (function != null) {
        return function.body;
      }
    }
    {
      var function = node.thisOrAncestorOfType<FunctionDeclaration>();
      if (function != null) {
        return function.functionExpression.body;
      }
    }
    {
      var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
      if (constructor != null) {
        return constructor.body;
      }
    }
    {
      var method = node.thisOrAncestorOfType<MethodDeclaration>();
      if (method != null) {
        return method.body;
      }
    }
    return null;
  }

  @protected
  bool setupCompute() {
    final locator = NodeLocator(selectionOffset, selectionEnd);
    node = locator.searchWithin(resolvedResult.unit);
    return node != null;
  }

  /// Return `true` if all of the parameters in the given list of [parameters]
  /// have an explicit type annotation.
  bool _allParametersHaveTypes(FormalParameterList parameters) {
    for (var parameter in parameters.parameters) {
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

  /// Configures [utils] using given [target].
  void _configureTargetLocation(Object target) {
    utils.targetClassElement = null;
    if (target is AstNode) {
      var targetClassDeclaration =
          target.thisOrAncestorOfType<ClassDeclaration>();
      if (targetClassDeclaration != null) {
        utils.targetClassElement = targetClassDeclaration.declaredElement;
      }
    }
  }

  Future<ChangeBuilder>
      _createBuilder_convertFunctionTypeAliasToGenericTypeAlias(
          FunctionTypeAlias node) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return null;
    }
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
    }
    var functionName = utils.getRangeText(
        range.startEnd(node.name, node.typeParameters ?? node.name));
    var parameters = utils.getNodeText(node.parameters);
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
    return changeBuilder;
  }

  Future<ChangeBuilder>
      _createBuilder_convertFunctionTypedFormalParameterToGenericTypeAlias(
          FunctionTypedFormalParameter node) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return null;
    }
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
    }
    var functionName = utils.getRangeText(range.startEnd(
        node.identifier, node.typeParameters ?? node.identifier));
    var parameters = utils.getNodeText(node.parameters);
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
    return changeBuilder;
  }

  /// Returns the text of the given node in the unit.
  String /* TODO (pq): make visible */ _getNodeText(AstNode node) =>
      utils.getNodeText(node);

  DartChangeBuilder _newDartChangeBuilder() =>
      DartChangeBuilderImpl.forWorkspace(workspace);

  /// This method does nothing, but we invoke it in places where Dart VM
  /// coverage agent fails to provide coverage information - such as almost
  /// all "return" statements.
  ///
  /// https://code.google.com/p/dart/issues/detail?id=19912
  static void _coverageMarker() {}
}

class ConvertToSpreadCollectionsChange {
  ChangeBuilder builder;
  List<String> args;
  bool isLineInvocation = false;
}

/// A visitor that can be used to find references to a parameter.
class _ParameterReferenceFinder extends RecursiveAstVisitor<void> {
  /// The parameter for which references are being sought, or `null` if we are
  /// just accumulating a list of referenced names.
  final ParameterElement parameter;

  /// A list of the simple identifiers that reference the [parameter].
  final List<SimpleIdentifier> references = <SimpleIdentifier>[];

  /// A collection of the names of other simple identifiers that were found. We
  /// need to know these in order to ensure that the selected loop variable does
  /// not hide a name from an enclosing scope that is already being referenced.
  final Set<String> otherNames = <String>{};

  /// Initialize a newly created finder to find references to the [parameter].
  _ParameterReferenceFinder(this.parameter) : assert(parameter != null);

  /// Return `true` if the parameter is unreferenced in the nodes that have been
  /// visited.
  bool get isParameterUnreferenced => references.isEmpty;

  /// Return `true` is the given name (assumed to be different than the name of
  /// the parameter) is references in the nodes that have been visited.
  bool referencesName(String name) => otherNames.contains(name);

  /// Replace all of the references to the parameter in the given [source] with
  /// the [newName]. The [offset] is the offset of the first character of the
  /// [source] relative to the start of the file.
  String replaceName(String source, String newName, int offset) {
    var oldLength = parameter.name.length;
    for (var i = references.length - 1; i >= 0; i--) {
      var oldOffset = references[i].offset - offset;
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
