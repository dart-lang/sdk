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
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

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

  Future<ChangeBuilder> createBuilder_addDiagnosticPropertyReference() async {
    final node = this.node;
    if (node is! SimpleIdentifier) {
      _coverageMarker();
      return null;
    }
    SimpleIdentifier name = node;
    final parent = node.parent;

    DartType type;

    // Getter.
    if (parent is MethodDeclaration) {
      MethodDeclaration methodDeclaration = parent;
      var element = methodDeclaration.declaredElement;
      if (element is PropertyAccessorElement) {
        PropertyAccessorElement propertyAccessor = element;
        type = propertyAccessor.returnType;
      }
      // Field.
    } else if (parent is VariableDeclaration) {
      VariableDeclaration variableDeclaration = parent;
      final element = variableDeclaration.declaredElement;
      if (element is FieldElement) {
        FieldElement fieldElement = element;
        type = fieldElement.type;
      }
    }

    if (type == null) {
      return null;
    }

    var constructorId;
    var typeArgs;
    var constructorName = '';

    if (type.element is FunctionTypedElement) {
      constructorId = 'ObjectFlagProperty';
      typeArgs = [type];
      constructorName = '.has';
    } else if (type.isDartCoreInt) {
      constructorId = 'IntProperty';
    } else if (type.isDartCoreDouble) {
      constructorId = 'DoubleProperty';
    } else if (type.isDartCoreString) {
      constructorId = 'StringProperty';
    } else if (isEnum(type)) {
      constructorId = 'EnumProperty';
      typeArgs = [type];
    } else if (isIterable(type)) {
      constructorId = 'IterableProperty';
      typeArgs = (type as InterfaceType).typeArguments;
    } else if (flutter.isColor(type)) {
      constructorId = 'ColorProperty';
    } else if (flutter.isMatrix4(type)) {
      constructorId = 'TransformProperty';
    } else {
      constructorId = 'DiagnosticsProperty';
      if (!type.isDynamic) {
        typeArgs = [type];
      }
    }

    void writePropertyReference(
      DartEditBuilder builder, {
      @required String prefix,
      @required String builderName,
    }) {
      builder.write('$prefix$builderName.add($constructorId');
      if (typeArgs != null) {
        builder.write('<');
        builder.writeTypes(typeArgs);
        builder.write('>');
      } else if (type.isDynamic) {
        TypeAnnotation declType;
        final decl = node.thisOrAncestorOfType<VariableDeclarationList>();
        if (decl != null) {
          declType = decl.type;
          // getter
        } else if (parent is MethodDeclaration) {
          declType = parent.returnType;
        }

        if (declType != null) {
          final typeText = utils.getNodeText(declType);
          if (typeText != 'dynamic') {
            builder.write('<');
            builder.write(utils.getNodeText(declType));
            builder.write('>');
          }
        }
      }
      builder.writeln("$constructorName('${name.name}', ${name.name}));");
    }

    final classDeclaration = parent.thisOrAncestorOfType<ClassDeclaration>();
    final debugFillProperties =
        classDeclaration.getMethod('debugFillProperties');
    if (debugFillProperties == null) {
      final insertOffset =
          utils.prepareNewMethodLocation(classDeclaration).offset;
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(utils.getLineNext(insertOffset),
            (DartEditBuilder builder) {
          final declPrefix =
              utils.getLinePrefix(classDeclaration.offset) + utils.getIndent(1);
          final bodyPrefix = declPrefix + utils.getIndent(1);

          builder.writeln('$declPrefix@override');
          builder.writeln(
              '${declPrefix}void debugFillProperties(DiagnosticPropertiesBuilder properties) {');
          builder
              .writeln('${bodyPrefix}super.debugFillProperties(properties);');
          writePropertyReference(builder,
              prefix: bodyPrefix, builderName: 'properties');
          builder.writeln('$declPrefix}');
        });
      });
      return changeBuilder;
    }

    final body = debugFillProperties.body;
    if (body is BlockFunctionBody) {
      BlockFunctionBody functionBody = body;

      var offset;
      var prefix;
      if (functionBody.block.statements.isEmpty) {
        offset = functionBody.block.leftBracket.offset;
        prefix = utils.getLinePrefix(offset) + utils.getIndent(1);
      } else {
        offset = functionBody.block.statements.last.endToken.offset;
        prefix = utils.getLinePrefix(offset);
      }

      var parameters = debugFillProperties.parameters.parameters;
      var propertiesBuilderName;
      for (var parameter in parameters) {
        if (parameter is SimpleFormalParameter) {
          final type = parameter.type;
          if (type is TypeName) {
            if (type.name.name == 'DiagnosticPropertiesBuilder') {
              propertiesBuilderName = parameter.identifier.name;
              break;
            }
          }
        }
      }
      if (propertiesBuilderName == null) {
        return null;
      }

      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(utils.getLineNext(offset),
            (DartEditBuilder builder) {
          writePropertyReference(builder,
              prefix: prefix, builderName: propertiesBuilderName);
        });
      });
      return changeBuilder;
    }

    return null;
  }

  Future<ChangeBuilder> createBuilder_addReturnType() async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      FunctionBody body;
      var parent = node.parent;
      if (parent is MethodDeclaration) {
        if (parent.returnType != null) {
          _coverageMarker();
          return null;
        }
        body = parent.body;
      } else if (parent is FunctionDeclaration) {
        if (parent.returnType != null) {
          _coverageMarker();
          return null;
        }
        body = parent.functionExpression.body;
      } else {
        _coverageMarker();
        return null;
      }
      var returnType = inferReturnType(body);
      if (returnType == null) {
        _coverageMarker();
        return null;
      }
      var changeBuilder = _newDartChangeBuilder();
      bool validChange = true;
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(node.offset, (DartEditBuilder builder) {
          validChange = builder.writeType(returnType);
          builder.write(' ');
        });
      });
      return validChange ? changeBuilder : null;
    }
    return null;
  }

  Future<ChangeBuilder>
      createBuilder_addTypeAnnotation_DeclaredIdentifier() async {
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
      return null;
    }
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      _coverageMarker();
      return null;
    }
    DartType type = declaredIdentifier.declaredElement.type;
    if (type is! InterfaceType && type is! FunctionType) {
      _coverageMarker();
      return null;
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
    return validChange ? changeBuilder : null;
  }

  Future<ChangeBuilder>
      createBuilder_addTypeAnnotation_SimpleFormalParameter() async {
    AstNode node = this.node;
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
    DartType type = parameter.declaredElement.type;
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
    bool validChange = true;
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
    AstNode node = this.node;
    // prepare VariableDeclarationList
    VariableDeclarationList declarationList =
        node.thisOrAncestorOfType<VariableDeclarationList>();
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
    VariableDeclaration variable = variables[0];
    // must be not after the name of the variable
    if (selectionOffset > variable.name.end) {
      _coverageMarker();
      return null;
    }
    // we need an initializer to get the type from
    Expression initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return null;
    }
    DartType type = initializer.staticType;
    // prepare type source
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType) {
      _coverageMarker();
      return null;
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
    return validChange ? changeBuilder : null;
  }

  Future<ConvertToSpreadCollectionsChange>
      createBuilder_convertAddAllToSpread() async {
    AstNode node = this.node;
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
    CascadeExpression cascade = invocation.thisOrAncestorOfType();
    NodeList<Expression> sections = cascade.cascadeSections;
    Expression target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      _coverageMarker();
      return null;
    }

    bool isEmptyListLiteral(Expression expression) =>
        expression is ListLiteral && expression.elements.isEmpty;

    ListLiteral list = target;
    Expression argument = invocation.argumentList.arguments[0];
    String elementText;
    ConvertToSpreadCollectionsChange change =
        ConvertToSpreadCollectionsChange();
    List<String> args;
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
        return null;
      }
      int startOffset = elements.first.offset;
      int endOffset = elements.last.end;
      elementText = utils.getText(startOffset, endOffset - startOffset);
      change.isLineInvocation = true;
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
      return changeBuilder;
    }

    return null;
  }

  Future<ChangeBuilder> createBuilder_convertDocumentationIntoLine() async {
    Comment comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null ||
        !comment.isDocumentation ||
        comment.tokens.length != 1) {
      _coverageMarker();
      return null;
    }
    Token token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      _coverageMarker();
      return null;
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
        String expectedPrefix = prefix + ' *';
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
        for (String newLine in newLines) {
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
    InstanceCreationExpression creation =
        node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      _coverageMarker();
      return null;
    }
    ConstructorElement element = creation.staticElement;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != typeProvider.mapElement) {
      _coverageMarker();
      return null;
    }
    //
    // Ensure that the arguments have the right form.
    //
    NodeList<Expression> arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      _coverageMarker();
      return null;
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
      return null;
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
          _ParameterReferenceFinder(keyParameter.declaredElement);
      keyBody.accept(keyFinder);

      _ParameterReferenceFinder valueFinder =
          _ParameterReferenceFinder(valueParameter.declaredElement);
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
    return changeBuilder;
  }

  Future<ChangeBuilder> createBuilder_convertQuotes(bool fromDouble) async {
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
    FunctionBody body = getEnclosingFunctionBody();
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
    AstNode node = this.node;
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

  Future<ChangeBuilder> createBuilder_convertToPackageImport() async {
    var node = this.node;
    if (node is StringLiteral) {
      node = node.parent;
    }
    if (node is ImportDirective) {
      ImportDirective importDirective = node;
      var uriSource = importDirective.uriSource;

      // Ignore if invalid URI.
      if (uriSource == null) {
        return null;
      }

      var importUri = uriSource.uri;
      if (importUri.scheme != 'package') {
        return null;
      }

      // Don't offer to convert a 'package:' URI to itself.
      try {
        if (Uri.parse(importDirective.uriContent).scheme == 'package') {
          return null;
        }
      } on FormatException {
        return null;
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.node(importDirective.uri),
          "'$importUri'",
        );
      });
      return changeBuilder;
    }
    return null;
  }

  Future<ChangeBuilder> createBuilder_convertToRelativeImport() async {
    var node = this.node;
    if (node is StringLiteral) {
      node = node.parent;
    }
    if (node is! ImportDirective) {
      return null;
    }

    ImportDirective importDirective = node;

    // Ignore if invalid URI.
    if (importDirective.uriSource == null) {
      return null;
    }

    // Ignore if the uri is not a package: uri.
    Uri sourceUri = resolvedResult.uri;
    if (sourceUri.scheme != 'package') {
      return null;
    }

    Uri importUri;
    try {
      importUri = Uri.parse(importDirective.uriContent);
    } on FormatException {
      return null;
    }

    // Ignore if import uri is not a package: uri.
    if (importUri.scheme != 'package') {
      return null;
    }

    // Verify that the source's uri and the import uri have the same package
    // name.
    List<String> sourceSegments = sourceUri.pathSegments;
    List<String> importSegments = importUri.pathSegments;
    if (sourceSegments.isEmpty ||
        importSegments.isEmpty ||
        sourceSegments.first != importSegments.first) {
      return null;
    }

    // We only write posix style paths in import directives.
    final String relativePath = path.posix.relative(
      importUri.path,
      from: path.dirname(sourceUri.path),
    );

    DartChangeBuilder changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(importDirective.uri).getExpanded(-1),
        relativePath,
      );
    });
    return changeBuilder;
  }

  Future<ChangeBuilder> createBuilder_inlineAdd() async {
    AstNode node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      _coverageMarker();
      return null;
    }
    SimpleIdentifier name = node;
    MethodInvocation invocation = node.parent;
    if (name != invocation.methodName ||
        name.name != 'add' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      _coverageMarker();
      return null;
    }
    CascadeExpression cascade = invocation.thisOrAncestorOfType();
    NodeList<Expression> sections = cascade.cascadeSections;
    Expression target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      _coverageMarker();
      return null;
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
    return changeBuilder;
  }

  /// todo (pq): unify with similar behavior in fix.
  Future<ChangeBuilder> createBuilder_removeTypeAnnotation() async {
    VariableDeclarationList declarationList =
        node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declarationList == null) {
      DeclaredIdentifier declaration = node.thisOrAncestorOfType();
      if (declaration == null) {
        _coverageMarker();
        return null;
      }
      TypeAnnotation typeNode = declaration.type;
      if (typeNode == null) {
        _coverageMarker();
        return null;
      }
      Token keyword = declaration.keyword;
      var variableName = declaration.identifier;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        SourceRange typeRange = range.startStart(typeNode, variableName);
        if (keyword != null && keyword.lexeme != 'var') {
          builder.addSimpleReplacement(typeRange, '');
        } else {
          builder.addSimpleReplacement(typeRange, 'var ');
        }
      });
      return changeBuilder;
    }
    // we need a type
    TypeAnnotation typeNode = declarationList.type;
    if (typeNode == null) {
      _coverageMarker();
      return null;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables[0].name.isSynthetic) {
      _coverageMarker();
      return null;
    }
    // must be not after the name of the variable
    VariableDeclaration firstVariable = declarationList.variables[0];
    if (selectionOffset > firstVariable.name.end) {
      _coverageMarker();
      return null;
    }
    // The variable must have an initializer, otherwise there is no other
    // source for its type.
    if (firstVariable.initializer == null) {
      _coverageMarker();
      return null;
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
    return changeBuilder;
  }

  Future<ChangeBuilder> createBuilder_replaceWithVar() async {
    final TypeAnnotation type = node.thisOrAncestorOfType<TypeAnnotation>();
    if (type == null) {
      return null;
    }
    var parent = type.parent;
    var grandparent = parent?.parent;
    if (parent is VariableDeclarationList &&
        (grandparent is VariableDeclarationStatement ||
            grandparent is ForPartsWithDeclarations)) {
      var variables = parent.variables;
      if (variables.length != 1) {
        return null;
      }
      var initializer = variables[0].initializer;
      String typeArgumentsText;
      int typeArgumentsOffset;
      if (type is NamedType && type.typeArguments != null) {
        if (initializer is TypedLiteral) {
          if (initializer.typeArguments == null) {
            typeArgumentsText = utils.getNodeText(type.typeArguments);
            typeArgumentsOffset = initializer.offset;
          }
        } else if (initializer is InstanceCreationExpression) {
          if (initializer.constructorName.type.typeArguments == null) {
            typeArgumentsText = utils.getNodeText(type.typeArguments);
            typeArgumentsOffset = initializer.constructorName.type.end;
          }
        }
      }
      if (initializer is SetOrMapLiteral &&
          initializer.typeArguments == null &&
          typeArgumentsText == null) {
        // TODO(brianwilkerson) This is to prevent the fix from converting a
        //  valid map or set literal into an ambiguous literal. We could apply
        //  this in more places by examining the elements of the collection.
        return null;
      }
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(type), 'var');
        if (typeArgumentsText != null) {
          builder.addSimpleInsertion(typeArgumentsOffset, typeArgumentsText);
        }
      });
      return changeBuilder;
    } else if (parent is DeclaredIdentifier &&
        grandparent is ForEachPartsWithDeclaration) {
      String typeArgumentsText;
      int typeArgumentsOffset;
      if (type is NamedType && type.typeArguments != null) {
        var iterable = grandparent.iterable;
        if (iterable is TypedLiteral && iterable.typeArguments == null) {
          typeArgumentsText = utils.getNodeText(type.typeArguments);
          typeArgumentsOffset = iterable.offset;
        }
      }
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(type), 'var');
        if (typeArgumentsText != null) {
          builder.addSimpleInsertion(typeArgumentsOffset, typeArgumentsText);
        }
      });
      return changeBuilder;
    }
    return null;
  }

  Future<ChangeBuilder> createBuilder_sortChildPropertyLast() async {
    NamedExpression childProp = flutter.findNamedExpression(node, 'child');
    childProp ??= flutter.findNamedExpression(node, 'children');
    if (childProp == null) {
      return null;
    }

    var parent = childProp.parent?.parent;
    if (parent is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(parent)) {
      return null;
    }

    InstanceCreationExpression creationExpression = parent;
    var args = creationExpression.argumentList;

    var last = args.arguments.last;
    if (last == childProp) {
      // Already sorted.
      return null;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var start = childProp.beginToken.previous.end;
      var end = childProp.endToken.next.end;
      var childRange = range.startOffsetEndOffset(start, end);

      var childText = utils.getRangeText(childRange);
      builder.addSimpleReplacement(childRange, '');
      builder.addSimpleInsertion(last.end + 1, childText);

      changeBuilder.setSelection(Position(file, last.end + 1));
    });

    return changeBuilder;
  }

  @protected
  Future<ChangeBuilder> createBuilder_useCurlyBraces() async {
    Future<ChangeBuilder> doStatement(DoStatement node) async {
      var body = node.body;
      if (body is Block) return null;

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
      return changeBuilder;
    }

    Future<ChangeBuilder> forStatement(ForStatement node) async {
      var body = node.body;
      if (body is Block) return null;

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

      return changeBuilder;
    }

    Future<ChangeBuilder> ifStatement(
        IfStatement node, Statement thenOrElse) async {
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

      return changeBuilder;
    }

    Future<ChangeBuilder> whileStatement(WhileStatement node) async {
      var body = node.body;
      if (body is Block) return null;

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
      return changeBuilder;
    }

    var statement = node.thisOrAncestorOfType<Statement>();
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
    return null;
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

  /// Return the type of value returned by the function [body], or `null` if a
  /// type can't be inferred.
  DartType inferReturnType(FunctionBody body) {
    bool isAsynchronous;
    bool isGenerator;
    DartType baseType;
    if (body is ExpressionFunctionBody) {
      isAsynchronous = body.isAsynchronous;
      isGenerator = body.isGenerator;
      baseType = body.expression.staticType;
    } else if (body is BlockFunctionBody) {
      isAsynchronous = body.isAsynchronous;
      isGenerator = body.isGenerator;
      var computer = _ReturnTypeComputer(resolvedResult.typeSystem);
      body.block.accept(computer);
      baseType = computer.returnType;
      if (baseType == null && computer.hasReturn) {
        baseType = typeProvider.voidType;
      }
    }
    if (baseType == null) {
      return null;
    }
    if (isAsynchronous) {
      if (isGenerator) {
        return typeProvider.streamElement.instantiate(
            typeArguments: [baseType],
            nullabilitySuffix: baseType.nullabilitySuffix);
      } else {
        return typeProvider.futureElement.instantiate(
            typeArguments: [baseType],
            nullabilitySuffix: baseType.nullabilitySuffix);
      }
    } else if (isGenerator) {
      return typeProvider.iterableElement.instantiate(
          typeArguments: [baseType],
          nullabilitySuffix: baseType.nullabilitySuffix);
    }
    return baseType;
  }

  bool isEnum(DartType type) {
    final element = type.element;
    return element is ClassElement && element.isEnum;
  }

  bool isIterable(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    ClassElement element = type.element;

    bool isExactIterable(ClassElement element) {
      return element?.name == 'Iterable' && element.library.isDartCore;
    }

    if (isExactIterable(element)) {
      return true;
    }
    for (InterfaceType type in element.allSupertypes) {
      if (isExactIterable(type.element)) {
        return true;
      }
    }
    return false;
  }

  @protected
  bool setupCompute() {
    final locator = NodeLocator(selectionOffset, selectionEnd);
    node = locator.searchWithin(resolvedResult.unit);
    return node != null;
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

  /// Configures [utils] using given [target].
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

/// Copied from lib/src/services/correction/base_processor.dart, but [hasReturn]
/// was added.
// TODO(brianwilkerson) Decide whether to unify the two classes.
class _ReturnTypeComputer extends RecursiveAstVisitor<void> {
  final TypeSystem typeSystem;

  DartType returnType;

  /// A flag indicating whether at least one return statement was found.
  bool hasReturn = false;

  _ReturnTypeComputer(this.typeSystem);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    hasReturn = true;
    // prepare expression
    Expression expression = node.expression;
    if (expression == null) {
      return;
    }
    // prepare type
    DartType type = expression.staticType;
    if (type.isBottom) {
      return;
    }
    // combine types
    if (returnType == null) {
      returnType = type;
    } else {
      if (returnType is InterfaceType && type is InterfaceType) {
        returnType = InterfaceType.getSmartLeastUpperBound(returnType, type);
      } else {
        returnType = typeSystem.leastUpperBound(returnType, type);
      }
    }
  }
}
