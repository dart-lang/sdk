// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/assign_to_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_block.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_async_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_block_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_final_field.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_getter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_part_of_to_uri.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/exchange_operands.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/shadow_field.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/split_and_condition.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart'
    hide AssistContributor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

typedef _SimpleIdentifierVisitor = void Function(SimpleIdentifier node);

/// The computer for Dart assists.
class AssistProcessor extends BaseProcessor {
  /// A map that can be used to look up the names of the lints for which a given
  /// [CorrectionProducer] will be used.
  static final Map<ProducerGenerator, Set<String>> lintRuleMap =
      createLintRuleMap();

  /// A list of the generators used to produce assists.
  static const List<ProducerGenerator> generators = [
    AddDiagnosticPropertyReference.newInstance,
    AddReturnType.newInstance,
    AddTypeAnnotation.newInstance,
    AssignToLocalVariable.newInstance,
    ConvertAddAllToSpread.newInstance,
    ConvertClassToMixin.newInstance,
    ConvertConditionalExpressionToIfElement.newInstance,
    ConvertDocumentationIntoBlock.newInstance,
    ConvertDocumentationIntoLine.newInstance,
    ConvertIntoAsyncBody.newInstance,
    ConvertIntoBlockBody.newInstance,
    ConvertIntoFinalField.newInstance,
    ConvertIntoGetter.newInstance,
    ConvertMapFromIterableToForLiteral.newInstance,
    ConvertPartOfToUri.newInstance,
    ConvertToDoubleQuotes.newInstance,
    ConvertToSingleQuotes.newInstance,
    ConvertToExpressionFunctionBody.newInstance,
    ConvertToGenericFunctionSyntax.newInstance,
    ConvertToIntLiteral.newInstance,
    ConvertToListLiteral.newInstance,
    ConvertToMapLiteral.newInstance,
    ConvertToNullAware.newInstance,
    ConvertToPackageImport.newInstance,
    ConvertToRelativeImport.newInstance,
    ConvertToSetLiteral.newInstance,
    ExchangeOperands.newInstance,
    InlineInvocation.newInstance,
    RemoveTypeAnnotation.newInstance,
    ReplaceWithVar.newInstance,
    ShadowField.newInstance,
    SortChildPropertyLast.newInstance,
    SplitAndCondition.newInstance,
    UseCurlyBraces.newInstance,
  ];

  final DartAssistContext context;

  final List<Assist> assists = <Assist>[];

  AssistProcessor(this.context)
      : super(
          selectionOffset: context.selectionOffset,
          selectionLength: context.selectionLength,
          resolvedResult: context.resolveResult,
          workspace: context.workspace,
        );

  Future<List<Assist>> compute() async {
    if (!setupCompute()) {
      return assists;
    }
    await _addProposal_addNotNullAssert();
    await _addProposal_convertToFieldParameter();
    await _addProposal_convertToForIndexLoop();
    await _addProposal_convertToIsNot_onIs();
    await _addProposal_convertToIsNot_onNot();
    await _addProposal_convertToIsNotEmpty();
    await _addProposal_convertToMultilineString();
    await _addProposal_convertToNormalParameter();
    await _addProposal_encapsulateField();
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
    await _addProposal_introduceLocalTestedType();
    await _addProposal_invertIf();
    await _addProposal_joinIfStatementInner();
    await _addProposal_joinIfStatementOuter();
    await _addProposal_joinVariableDeclaration_onAssignment();
    await _addProposal_joinVariableDeclaration_onDeclaration();
    await _addProposal_reparentFlutterList();
    await _addProposal_replaceConditionalWithIfElse();
    await _addProposal_replaceIfElseWithConditional();
    await _addProposal_splitVariableDeclaration();
    await _addProposal_surroundWith();

    await _addFromProducers();

    return assists;
  }

  Future<List<Assist>> computeAssist(AssistKind assistKind) async {
    if (!setupCompute()) {
      return assists;
    }

    var context = CorrectionProducerContext(
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
      resolvedResult: resolvedResult,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return assists;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);

      var builder = _newDartChangeBuilder();
      await producer.compute(builder);

      _addAssistFromBuilder(builder, producer.assistKind,
          args: producer.assistArguments);
    }

    // Calculate only specific assists for edit.dartFix
    if (assistKind == DartAssistKind.CONVERT_CLASS_TO_MIXIN) {
      await compute(ConvertClassToMixin());
    } else if (assistKind == DartAssistKind.CONVERT_TO_INT_LITERAL) {
      await compute(ConvertToIntLiteral());
    } else if (assistKind == DartAssistKind.CONVERT_TO_SPREAD) {
      await compute(ConvertAddAllToSpread());
    } else if (assistKind == DartAssistKind.CONVERT_TO_FOR_ELEMENT) {
      await compute(ConvertMapFromIterableToForLiteral());
    } else if (assistKind == DartAssistKind.CONVERT_TO_IF_ELEMENT) {
      await compute(ConvertConditionalExpressionToIfElement());
    }
    return assists;
  }

  void _addAssistFromBuilder(DartChangeBuilder builder, AssistKind kind,
      {List<Object> args}) {
    if (builder == null) {
      return;
    }
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    assists.add(Assist(kind, change));
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext(
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
      resolvedResult: resolvedResult,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }
    for (var generator in generators) {
      var ruleNames = lintRuleMap[generator] ?? {};
      if (!_containsErrorCode(ruleNames)) {
        var producer = generator();
        producer.configure(context);

        var builder = _newDartChangeBuilder();
        await producer.compute(builder);

        _addAssistFromBuilder(builder, producer.assistKind,
            args: producer.assistArguments);
      }
    }
  }

  Future<void> _addProposal_addNotNullAssert() async {
    final identifier = node;
    if (identifier is SimpleIdentifier) {
      if (identifier.parent is FormalParameter) {
        final exp = identifier.parent.thisOrAncestorMatching(
            (node) => node is FunctionExpression || node is MethodDeclaration);
        var body;
        if (exp is FunctionExpression) {
          body = exp.body;
        } else if (exp is MethodDeclaration) {
          body = exp.body;
        }
        if (body is BlockFunctionBody) {
          var blockBody = body;
          // Check for an obvious pre-existing assertion.
          for (var statement in blockBody.block.statements) {
            if (statement is AssertStatement) {
              final condition = statement.condition;
              if (condition is BinaryExpression) {
                final leftOperand = condition.leftOperand;
                if (leftOperand is SimpleIdentifier) {
                  if (leftOperand.staticElement == identifier.staticElement &&
                      condition.operator.type == TokenType.BANG_EQ &&
                      condition.rightOperand is NullLiteral) {
                    return;
                  }
                }
              }
            }
          }

          final changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            final id = identifier.name;
            final prefix = utils.getNodePrefix(exp);
            final indent = utils.getIndent(1);
            // todo (pq): follow-ups:
            // 1. if the end token is on the same line as the body
            // we should add an `eol` before the assert as well.
            // 2. also, consider asking the block for the list of statements and
            // adding the statement to the beginning of the list, special casing
            // when there are no statements (or when there's a single statement
            // and the whole block is on the same line).
            var offset = min(utils.getLineNext(blockBody.beginToken.offset),
                blockBody.endToken.offset);
            builder.addSimpleInsertion(
                offset, '$prefix${indent}assert($id != null);$eol');
            _addAssistFromBuilder(
                changeBuilder, DartAssistKind.ADD_NOT_NULL_ASSERT);
          });
        }
      }
    }
  }

  Future<void> _addProposal_convertToFieldParameter() async {
    if (node == null) {
      return;
    }
    // prepare ConstructorDeclaration
    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }
    var parameterList = constructor.parameters;
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
      var name = (node as SimpleIdentifier).name;
      ConstructorFieldInitializer initializer = node.parent;
      if (initializer.expression == node) {
        for (var formalParameter in parameterList.parameters) {
          if (formalParameter is SimpleFormalParameter &&
              formalParameter.identifier.name == name) {
            parameter = formalParameter;
          }
        }
      }
    }
    // analyze parameter
    if (parameter != null) {
      var parameterName = parameter.identifier.name;
      var parameterElement = parameter.declaredElement;
      // check number of references
      {
        var numOfReferences = 0;
        AstVisitor visitor =
            _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
          if (node.staticElement == parameterElement) {
            numOfReferences++;
          }
        });
        for (var initializer in initializers) {
          initializer.accept(visitor);
        }
        if (numOfReferences != 1) {
          return;
        }
      }
      // find the field initializer
      ConstructorFieldInitializer parameterInitializer;
      for (var initializer in initializers) {
        if (initializer is ConstructorFieldInitializer) {
          var expression = initializer.expression;
          if (expression is SimpleIdentifier &&
              expression.name == parameterName) {
            parameterInitializer = initializer;
          }
        }
      }
      if (parameterInitializer == null) {
        return;
      }
      var fieldName = parameterInitializer.fieldName.name;

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // replace parameter
        builder.addSimpleReplacement(range.node(parameter), 'this.$fieldName');
        // remove initializer
        var initializerIndex = initializers.indexOf(parameterInitializer);
        if (initializers.length == 1) {
          builder
              .addDeletion(range.endEnd(parameterList, parameterInitializer));
        } else {
          if (initializerIndex == 0) {
            var next = initializers[initializerIndex + 1];
            builder.addDeletion(range.startStart(parameterInitializer, next));
          } else {
            var prev = initializers[initializerIndex - 1];
            builder.addDeletion(range.endEnd(prev, parameterInitializer));
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_FIELD_PARAMETER);
    }
  }

  Future<void> _addProposal_convertToForIndexLoop() async {
    // find enclosing ForEachStatement
    var forEachStatement = node.thisOrAncestorMatching(
            (node) => node is ForStatement && node.forLoopParts is ForEachParts)
        as ForStatement;
    if (forEachStatement == null) {
      return;
    }
    ForEachParts forEachParts = forEachStatement.forLoopParts;
    if (selectionOffset < forEachStatement.offset ||
        forEachStatement.rightParenthesis.end < selectionOffset) {
      return;
    }
    // loop should declare variable
    var loopVariable = forEachParts is ForEachPartsWithDeclaration
        ? forEachParts.loopVariable
        : null;
    if (loopVariable == null) {
      return;
    }
    // iterable should be VariableElement
    String listName;
    var iterable = forEachParts.iterable;
    if (iterable is SimpleIdentifier &&
        iterable.staticElement is VariableElement) {
      listName = iterable.name;
    } else {
      return;
    }
    // iterable should be List
    {
      var iterableType = iterable.staticType;
      if (iterableType is! InterfaceType ||
          iterableType.element != typeProvider.listElement) {
        return;
      }
    }
    // body should be Block
    if (forEachStatement.body is! Block) {
      return;
    }
    Block body = forEachStatement.body;
    // prepare a name for the index variable
    String indexName;
    {
      var conflicts =
          utils.findPossibleLocalVariableConflicts(forEachStatement.offset);
      if (!conflicts.contains('i')) {
        indexName = 'i';
      } else if (!conflicts.contains('j')) {
        indexName = 'j';
      } else if (!conflicts.contains('k')) {
        indexName = 'k';
      } else {
        return;
      }
    }
    // prepare environment
    var prefix = utils.getNodePrefix(forEachStatement);
    var indent = utils.getIndent(1);
    var firstBlockLine = utils.getLineContentEnd(body.leftBracket.end);
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

  Future<void> _addProposal_convertToIsNot_onIs() async {
    // may be child of "is"
    var node = this.node;
    while (node != null && node is! IsExpression) {
      node = node.parent;
    }
    // prepare "is"
    if (node is! IsExpression) {
      return;
    }
    var isExpression = node as IsExpression;
    if (isExpression.notOperator != null) {
      return;
    }
    // prepare enclosing ()
    var parent = isExpression.parent;
    if (parent is! ParenthesizedExpression) {
      return;
    }
    var parExpression = parent as ParenthesizedExpression;
    // prepare enclosing !()
    var parent2 = parent.parent;
    if (parent2 is! PrefixExpression) {
      return;
    }
    var prefExpression = parent2 as PrefixExpression;
    if (prefExpression.operator.type != TokenType.BANG) {
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
    // may be () in prefix expression
    var node = this.node;
    if (node is ParenthesizedExpression && node.parent is PrefixExpression) {
      node = node.parent;
    }
    // prepare !()
    if (node is! PrefixExpression) {
      return;
    }
    var prefExpression = node as PrefixExpression;
    // should be ! operator
    if (prefExpression.operator.type != TokenType.BANG) {
      return;
    }
    // prepare !()
    var operand = prefExpression.operand;
    if (operand is! ParenthesizedExpression) {
      return;
    }
    var parExpression = operand as ParenthesizedExpression;
    operand = parExpression.expression;
    // prepare "is"
    if (operand is! IsExpression) {
      return;
    }
    var isExpression = operand as IsExpression;
    if (isExpression.notOperator != null) {
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

  /// Converts "!isEmpty" -> "isNotEmpty" if possible.
  Future<void> _addProposal_convertToIsNotEmpty() async {
    // prepare "expr.isEmpty"
    AstNode isEmptyAccess;
    SimpleIdentifier isEmptyIdentifier;
    if (node is SimpleIdentifier) {
      var identifier = node as SimpleIdentifier;
      var parent = identifier.parent;
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
      return;
    }
    // should be "isEmpty"
    var propertyElement = isEmptyIdentifier.staticElement;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      return;
    }
    // should have "isNotEmpty"
    var propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }
    // should be in PrefixExpression
    if (isEmptyAccess.parent is! PrefixExpression) {
      return;
    }
    var prefixExpression = isEmptyAccess.parent as PrefixExpression;
    // should be !
    if (prefixExpression.operator.type != TokenType.BANG) {
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
      var literal = node;
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
    if (node is SimpleIdentifier &&
        node.parent is FieldFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = node.parent.parent.parent;
      FormalParameterList parameterList = node.parent.parent;
      FieldFormalParameter parameter = node.parent;
      var parameterElement = parameter.declaredElement;
      var name = (node as SimpleIdentifier).name;
      // prepare type
      var type = parameterElement.type;

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

  Future<void> _addProposal_encapsulateField() async {
    // find FieldDeclaration
    var fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration == null) {
      return;
    }
    // not interesting for static
    if (fieldDeclaration.isStatic) {
      return;
    }
    // has a parse error
    var variableList = fieldDeclaration.fields;
    if (variableList.keyword == null && variableList.type == null) {
      return;
    }
    // not interesting for final
    if (variableList.isFinal) {
      return;
    }
    // should have exactly one field
    List<VariableDeclaration> fields = variableList.variables;
    if (fields.length != 1) {
      return;
    }
    var field = fields.first;
    var nameNode = field.name;
    FieldElement fieldElement = nameNode.staticElement;
    // should have a public name
    var name = nameNode.name;
    if (Identifier.isPrivateName(name)) {
      return;
    }
    // should be on the name
    if (nameNode != node) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // rename field
      builder.addSimpleReplacement(range.node(nameNode), '_$name');
      // update references in constructors
      ClassOrMixinDeclaration classDeclaration = fieldDeclaration.parent;
      for (var member in classDeclaration.members) {
        if (member is ConstructorDeclaration) {
          for (var parameter in member.parameters.parameters) {
            var parameterElement = parameter.declaredElement;
            if (parameterElement is FieldFormalParameterElement &&
                parameterElement.field == fieldElement) {
              var identifier = parameter.identifier;
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

        var typeCode = '';
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

  Future<void> _addProposal_flutterConvertToChildren() async {
    // Find "child: widget" under selection.
    NamedExpression namedExp;
    {
      var node = this.node;
      var parent = node?.parent;
      var parent2 = parent?.parent;
      if (node is SimpleIdentifier &&
          parent is Label &&
          parent2 is NamedExpression &&
          node.name == 'child' &&
          node.staticElement != null &&
          flutter.isWidgetExpression(parent2.expression)) {
        namedExp = parent2;
      } else {
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
    var widgetClass = node.thisOrAncestorOfType<ClassDeclaration>();
    var superclass = widgetClass?.extendsClause?.superclass;
    if (widgetClass == null || superclass == null) {
      return;
    }

    // Don't spam, activate only from the `class` keyword to the class body.
    if (selectionOffset < widgetClass.classKeyword.offset ||
        selectionOffset > widgetClass.leftBracket.end) {
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
      return;
    }

    // Must be a StatelessWidget subclasses.
    var widgetClassElement = widgetClass.declaredElement;
    if (!flutter.isExactlyStatelessWidgetType(widgetClassElement.supertype)) {
      return;
    }

    var widgetName = widgetClassElement.displayName;
    var stateName = '_${widgetName}State';

    // Find fields assigned in constructors.
    var fieldsAssignedInConstructors = <FieldElement>{};
    for (var member in widgetClass.members) {
      if (member is ConstructorDeclaration) {
        member.accept(_SimpleIdentifierRecursiveAstVisitor((node) {
          if (node.parent is FieldFormalParameter) {
            var element = node.staticElement;
            if (element is FieldFormalParameterElement) {
              fieldsAssignedInConstructors.add(element.field);
            }
          }
          if (node.parent is ConstructorFieldInitializer) {
            var element = node.staticElement;
            if (element is FieldElement) {
              fieldsAssignedInConstructors.add(element);
            }
          }
          if (node.inSetterContext()) {
            var element = node.staticElement;
            if (element is PropertyAccessorElement) {
              var field = element.variable;
              if (field is FieldElement) {
                fieldsAssignedInConstructors.add(field);
              }
            }
          }
        }));
      }
    }

    // Prepare nodes to move.
    var nodesToMove = <ClassMember>{};
    var elementsToMove = <Element>{};
    for (var member in widgetClass.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        for (var fieldNode in member.fields.variables) {
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
      var edits = <SourceEdit>[];
      movedNode.accept(_SimpleIdentifierRecursiveAstVisitor((node) {
        if (node.inDeclarationContext()) {
          return;
        }
        var element = node.staticElement;
        if (element is ExecutableElement &&
            element?.enclosingElement == widgetClassElement &&
            !elementsToMove.contains(element)) {
          var offset = node.offset - linesRange.offset;
          var qualifier = element.isStatic ? widgetName : 'widget';

          var parent = node.parent;
          if (parent is InterpolationExpression &&
              parent.leftBracket.type ==
                  TokenType.STRING_INTERPOLATION_IDENTIFIER) {
            edits.add(SourceEdit(offset, 0, '{$qualifier.'));
            edits.add(SourceEdit(offset + node.length, 0, '}'));
          } else {
            edits.add(SourceEdit(offset, 0, '$qualifier.'));
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

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(superclass), (builder) {
        builder.writeReference(statefulWidgetClass);
      });

      var replaceOffset = 0;
      var hasBuildMethod = false;

      var typeParams = '';
      if (widgetClass.typeParameters != null) {
        typeParams = utils.getNodeText(widgetClass.typeParameters);
      }

      /// Replace code between [replaceOffset] and [replaceEnd] with
      /// `createState()`, empty line, or nothing.
      void replaceInterval(int replaceEnd,
          {bool replaceWithEmptyLine = false,
          bool hasEmptyLineBeforeCreateState = false,
          bool hasEmptyLineAfterCreateState = true}) {
        var replaceLength = replaceEnd - replaceOffset;
        builder.addReplacement(
          SourceRange(replaceOffset, replaceLength),
          (builder) {
            if (hasBuildMethod) {
              if (hasEmptyLineBeforeCreateState) {
                builder.writeln();
              }
              builder.writeln('  @override');
              builder.writeln(
                  '  $stateName$typeParams createState() => $stateName$typeParams();');
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
      var lastToRemoveIsField = false;
      var endOfLastNodeToKeep = 0;
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

        builder.write('class $stateName$typeParams extends ');
        builder.writeReference(stateClass);

        // Write just param names (and not bounds, metadata and docs).
        builder.write('<${widgetClass.name}');
        if (widgetClass.typeParameters != null) {
          builder.write('<');
          var first = true;
          for (var param in widgetClass.typeParameters.typeParameters) {
            if (!first) {
              builder.write(', ');
              first = false;
            }
            builder.write(param.name.name);
          }
          builder.write('>');
        }

        builder.writeln('> {');

        var writeEmptyLine = false;
        for (var member in nodesToMove) {
          if (writeEmptyLine) {
            builder.writeln();
          }
          var text = rewriteWidgetMemberReferences(member);
          builder.write(text);
          // Write empty lines between members, but not before the first.
          writeEmptyLine = true;
        }

        builder.write('}');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.FLUTTER_CONVERT_TO_STATEFUL_WIDGET);
  }

  Future<void> _addProposal_flutterMoveWidgetDown() async {
    var widget = flutter.identifyWidgetExpression(node);
    if (widget == null) {
      return;
    }

    var parentList = widget.parent;
    if (parentList is ListLiteral) {
      List<CollectionElement> parentElements = parentList.elements;
      var index = parentElements.indexOf(widget);
      if (index != parentElements.length - 1) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          var nextWidget = parentElements[index + 1];
          var nextRange = range.node(nextWidget);
          var nextText = utils.getRangeText(nextRange);

          var widgetRange = range.node(widget);
          var widgetText = utils.getRangeText(widgetRange);

          builder.addSimpleReplacement(nextRange, widgetText);
          builder.addSimpleReplacement(widgetRange, nextText);

          var lengthDelta = nextRange.length - widgetRange.length;
          var newWidgetOffset = nextRange.offset + lengthDelta;
          changeBuilder.setSelection(Position(file, newWidgetOffset));
        });
        _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_MOVE_DOWN);
      }
    }
  }

  Future<void> _addProposal_flutterMoveWidgetUp() async {
    var widget = flutter.identifyWidgetExpression(node);
    if (widget == null) {
      return;
    }

    var parentList = widget.parent;
    if (parentList is ListLiteral) {
      List<CollectionElement> parentElements = parentList.elements;
      var index = parentElements.indexOf(widget);
      if (index > 0) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          var previousWidget = parentElements[index - 1];
          var previousRange = range.node(previousWidget);
          var previousText = utils.getRangeText(previousRange);

          var widgetRange = range.node(widget);
          var widgetText = utils.getRangeText(widgetRange);

          builder.addSimpleReplacement(previousRange, widgetText);
          builder.addSimpleReplacement(widgetRange, previousText);

          var newWidgetOffset = previousRange.offset;
          changeBuilder.setSelection(Position(file, newWidgetOffset));
        });
        _addAssistFromBuilder(changeBuilder, DartAssistKind.FLUTTER_MOVE_UP);
      }
    }
  }

  Future<void> _addProposal_flutterRemoveWidget_multipleChildren() async {
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
    var parent = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(parent)) {
      return;
    }

    var childArgument = flutter.findChildArgument(parent);
    if (childArgument?.expression is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(childArgument.expression)) {
      return;
    }
    InstanceCreationExpression child = childArgument.expression;

    await _swapParentAndChild(
        parent, child, DartAssistKind.FLUTTER_SWAP_WITH_CHILD);
  }

  Future<void> _addProposal_flutterSwapWithParent() async {
    var child = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(child)) {
      return;
    }

    // NamedExpression (child:), ArgumentList, InstanceCreationExpression
    var expr = child.parent?.parent?.parent;
    if (expr is! InstanceCreationExpression) {
      return;
    }
    InstanceCreationExpression parent = expr;

    await _swapParentAndChild(
        parent, child, DartAssistKind.FLUTTER_SWAP_WITH_PARENT);
  }

  Future<void> _addProposal_flutterWrapStreamBuilder() async {
    var widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr == null) {
      return;
    }
    if (flutter.isExactWidgetTypeStreamBuilder(widgetExpr.staticType)) {
      return;
    }
    var widgetSrc = utils.getNodeText(widgetExpr);

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
        builder.writeReference(streamBuilderElement);

        builder.write('<');
        builder.addSimpleLinkedEdit('type', 'Object');
        builder.writeln('>(');

        var indentOld = utils.getLinePrefix(widgetExpr.offset);
        var indentNew1 = indentOld + utils.getIndent(1);
        var indentNew2 = indentOld + utils.getIndent(2);

        builder.write(indentNew1);
        builder.writeln('stream: null,');

        builder.write(indentNew1);
        builder.writeln('builder: (context, snapshot) {');

        widgetSrc = widgetSrc.replaceAll(
          RegExp('^$indentOld', multiLine: true),
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
    var widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr == null) {
      return;
    }
    if (widgetValidator != null && !widgetValidator(widgetExpr)) {
      return;
    }
    var widgetSrc = utils.getNodeText(widgetExpr);

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
          builder.writeReference(parentClassElement);
        }
        builder.write('(');
        if (widgetSrc.contains(eol) || leadingLines.isNotEmpty) {
          var indentOld = utils.getLinePrefix(widgetExpr.offset);
          var indentNew = '$indentOld${utils.getIndent(1)}';

          for (var leadingLine in leadingLines) {
            builder.write(eol);
            builder.write(indentNew);
            builder.write(leadingLine);
          }

          builder.write(eol);
          builder.write(indentNew);
          widgetSrc = widgetSrc.replaceAll(
              RegExp('^$indentOld', multiLine: true), indentNew);
          widgetSrc += ',$eol$indentOld';
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
    var selectionRange = SourceRange(selectionOffset, selectionLength);
    var analyzer = SelectionAnalyzer(selectionRange);
    context.resolveResult.unit.accept(analyzer);

    var widgetExpressions = <Expression>[];
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
    var src = utils.getRangeText(selectedRange);

    Future<void> addAssist(
        {@required AssistKind kind,
        @required String parentLibraryUri,
        @required String parentClassName}) async {
      var parentClassElement =
          await sessionHelper.getClass(parentLibraryUri, parentClassName);
      var widgetClassElement =
          await sessionHelper.getClass(flutter.widgetsUri, 'Widget');
      if (parentClassElement == null || widgetClassElement == null) {
        return;
      }

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(selectedRange, (DartEditBuilder builder) {
          builder.writeReference(parentClassElement);
          builder.write('(');

          var indentOld = utils.getLinePrefix(firstWidget.offset);
          var indentNew1 = indentOld + utils.getIndent(1);
          var indentNew2 = indentOld + utils.getIndent(2);

          builder.write(eol);
          builder.write(indentNew1);
          builder.write('children: [');
          builder.write(eol);

          var newSrc = _replaceSourceIndent(src, indentOld, indentNew2);
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
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // there should be no existing combinators
    if (importDirective.combinators.isNotEmpty) {
      return;
    }
    // prepare whole import namespace
    ImportElement importElement = importDirective.element;
    if (importElement == null) {
      return;
    }
    var namespace = getImportNamespace(importElement);
    // prepare names of referenced elements (from this import)
    var referencedNames = SplayTreeSet<String>();
    var visitor = _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
      var element = node.staticElement;
      if (element != null &&
          (namespace[node.name] == element ||
              (node.name != element.name &&
                  namespace[element.name] == element))) {
        referencedNames.add(element.displayName);
      }
    });
    context.resolveResult.unit.accept(visitor);
    // ignore if unused
    if (referencedNames.isEmpty) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var showCombinator = ' show ${referencedNames.join(', ')}';
      builder.addSimpleInsertion(importDirective.end - 1, showCombinator);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.IMPORT_ADD_SHOW);
  }

  Future<void> _addProposal_introduceLocalTestedType() async {
    var node = this.node;
    if (node is IfStatement) {
      node = (node as IfStatement).condition;
    } else if (node is WhileStatement) {
      node = (node as WhileStatement).condition;
    }
    // prepare IsExpression
    if (node is! IsExpression) {
      return;
    }
    IsExpression isExpression = node;
    var castType = isExpression.type.type;
    var castTypeCode = _getNodeText(isExpression.type);
    // prepare environment
    var indent = utils.getIndent(1);
    String prefix;
    Block targetBlock;
    {
      var statement = node.thisOrAncestorOfType<Statement>();
      if (statement is IfStatement && statement.thenStatement is Block) {
        targetBlock = statement.thenStatement;
      } else if (statement is WhileStatement && statement.body is Block) {
        targetBlock = statement.body;
      } else {
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
    var excluded = <String>{};
    var scopedNameFinder = ScopedNameFinder(offset);
    isExpression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    // name(s)
    var suggestions =
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
    if (node is! IfStatement) {
      return;
    }
    var ifStatement = node as IfStatement;
    var condition = ifStatement.condition;
    // should have both "then" and "else"
    var thenStatement = ifStatement.thenStatement;
    var elseStatement = ifStatement.elseStatement;
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    // prepare source
    var invertedCondition = utils.invertCondition(condition);
    var thenSource = _getNodeText(thenStatement);
    var elseSource = _getNodeText(elseStatement);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(range.node(thenStatement), elseSource);
      builder.addSimpleReplacement(range.node(elseStatement), thenSource);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.INVERT_IF_STATEMENT);
  }

  Future<void> _addProposal_joinIfStatementInner() async {
    // climb up condition to the (supposedly) "if" statement
    var node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      return;
    }
    var targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      return;
    }
    // prepare inner "if" statement
    var targetThenStatement = targetIfStatement.thenStatement;
    var innerStatement = getSingleStatement(targetThenStatement);
    if (innerStatement is! IfStatement) {
      return;
    }
    var innerIfStatement = innerStatement as IfStatement;
    if (innerIfStatement.elseStatement != null) {
      return;
    }
    // prepare environment
    var prefix = utils.getNodePrefix(targetIfStatement);
    // merge conditions
    String condition;
    {
      var targetCondition = targetIfStatement.condition;
      var innerCondition = innerIfStatement.condition;
      var targetConditionSource = _getNodeText(targetCondition);
      var innerConditionSource = _getNodeText(innerCondition);
      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
        targetConditionSource = '($targetConditionSource)';
      }
      if (_shouldWrapParenthesisBeforeAnd(innerCondition)) {
        innerConditionSource = '($innerConditionSource)';
      }
      condition = '$targetConditionSource && $innerConditionSource';
    }
    // replace target "if" statement
    var innerThenStatement = innerIfStatement.thenStatement;
    var innerThenStatements = getStatements(innerThenStatement);
    var lineRanges = utils.getLinesRangeStatements(innerThenStatements);
    var oldSource = utils.getRangeText(lineRanges);
    var newSource = utils.indentSourceLeftRight(oldSource);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(targetIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_INNER);
  }

  Future<void> _addProposal_joinIfStatementOuter() async {
    // climb up condition to the (supposedly) "if" statement
    var node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      return;
    }
    var targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      return;
    }
    // prepare outer "if" statement
    var parent = targetIfStatement.parent;
    if (parent is Block) {
      if ((parent as Block).statements.length != 1) {
        return;
      }
      parent = parent.parent;
    }
    if (parent is! IfStatement) {
      return;
    }
    var outerIfStatement = parent as IfStatement;
    if (outerIfStatement.elseStatement != null) {
      return;
    }
    // prepare environment
    var prefix = utils.getNodePrefix(outerIfStatement);
    // merge conditions
    var targetCondition = targetIfStatement.condition;
    var outerCondition = outerIfStatement.condition;
    var targetConditionSource = _getNodeText(targetCondition);
    var outerConditionSource = _getNodeText(outerCondition);
    if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
      targetConditionSource = '($targetConditionSource)';
    }
    if (_shouldWrapParenthesisBeforeAnd(outerCondition)) {
      outerConditionSource = '($outerConditionSource)';
    }
    var condition = '$outerConditionSource && $targetConditionSource';
    // replace outer "if" statement
    var targetThenStatement = targetIfStatement.thenStatement;
    var targetThenStatements = getStatements(targetThenStatement);
    var lineRanges = utils.getLinesRangeStatements(targetThenStatements);
    var oldSource = utils.getRangeText(lineRanges);
    var newSource = utils.indentSourceLeftRight(oldSource);

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(outerIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  Future<void> _addProposal_joinVariableDeclaration_onAssignment() async {
    // check that node is LHS in assignment
    if (node is SimpleIdentifier &&
        node.parent is AssignmentExpression &&
        (node.parent as AssignmentExpression).leftHandSide == node &&
        node.parent.parent is ExpressionStatement) {
    } else {
      return;
    }
    var assignExpression = node.parent as AssignmentExpression;
    // check that binary expression is assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      return;
    }
    // prepare "declaration" statement
    var element = (node as SimpleIdentifier).staticElement;
    if (element == null) {
      return;
    }
    var declOffset = element.nameOffset;
    var unit = context.resolveResult.unit;
    var declNode = NodeLocator(declOffset).searchWithin(unit);
    if (declNode != null &&
        declNode.parent is VariableDeclaration &&
        (declNode.parent as VariableDeclaration).name == declNode &&
        declNode.parent.parent is VariableDeclarationList &&
        declNode.parent.parent.parent is VariableDeclarationStatement) {
    } else {
      return;
    }
    var decl = declNode.parent as VariableDeclaration;
    var declStatement = decl.parent.parent as VariableDeclarationStatement;
    // may be has initializer
    if (decl.initializer != null) {
      return;
    }
    // check that "declaration" statement declared only one variable
    if (declStatement.variables.variables.length != 1) {
      return;
    }
    // check that the "declaration" and "assignment" statements are
    // parts of the same Block
    var assignStatement = node.parent.parent as ExpressionStatement;
    if (assignStatement.parent is Block &&
        assignStatement.parent == declStatement.parent) {
    } else {
      return;
    }
    var block = assignStatement.parent as Block;
    // check that "declaration" and "assignment" statements are adjacent
    List<Statement> statements = block.statements;
    if (statements.indexOf(assignStatement) ==
        statements.indexOf(declStatement) + 1) {
    } else {
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
    // prepare enclosing VariableDeclarationList
    var declList = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declList != null && declList.variables.length == 1) {
    } else {
      return;
    }
    var decl = declList.variables[0];
    // already initialized
    if (decl.initializer != null) {
      return;
    }
    // prepare VariableDeclarationStatement in Block
    if (declList.parent is VariableDeclarationStatement &&
        declList.parent.parent is Block) {
    } else {
      return;
    }
    var declStatement = declList.parent as VariableDeclarationStatement;
    var block = declStatement.parent as Block;
    List<Statement> statements = block.statements;
    // prepare assignment
    AssignmentExpression assignExpression;
    {
      // declaration should not be last Statement
      var declIndex = statements.indexOf(declStatement);
      if (declIndex < statements.length - 1) {
      } else {
        return;
      }
      // next Statement should be assignment
      var assignStatement = statements[declIndex + 1];
      if (assignStatement is ExpressionStatement) {
      } else {
        return;
      }
      var expressionStatement = assignStatement as ExpressionStatement;
      // expression should be assignment
      if (expressionStatement.expression is AssignmentExpression) {
      } else {
        return;
      }
      assignExpression = expressionStatement.expression as AssignmentExpression;
    }
    // check that pure assignment
    if (assignExpression.operator.type != TokenType.EQ) {
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

  Future<void> _addProposal_reparentFlutterList() async {
    if (node is! ListLiteral) {
      return;
    }
    if ((node as ListLiteral).elements.any((CollectionElement exp) =>
        !(exp is InstanceCreationExpression &&
            flutter.isWidgetCreation(exp)))) {
      return;
    }
    var literalSrc = utils.getNodeText(node);
    var newlineIdx = literalSrc.lastIndexOf(eol);
    if (newlineIdx < 0 || newlineIdx == literalSrc.length - 1) {
      return; // Lists need to be in multi-line format already.
    }
    var indentOld = utils.getLinePrefix(node.offset + 1 + newlineIdx);
    var indentArg = '$indentOld${utils.getIndent(1)}';
    var indentList = '$indentOld${utils.getIndent(2)}';

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
            RegExp('^$indentOld', multiLine: true), '$indentList'));
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
    ConditionalExpression conditional;
    // may be on Statement with Conditional
    var statement = node.thisOrAncestorOfType<Statement>();
    if (statement == null) {
      return;
    }
    // variable declaration
    var inVariable = false;
    if (statement is VariableDeclarationStatement) {
      var variableStatement = statement;
      for (var variable in variableStatement.variables.variables) {
        if (variable.initializer is ConditionalExpression) {
          conditional = variable.initializer as ConditionalExpression;
          inVariable = true;
          break;
        }
      }
    }
    // assignment
    var inAssignment = false;
    if (statement is ExpressionStatement) {
      var exprStmt = statement;
      if (exprStmt.expression is AssignmentExpression) {
        var assignment = exprStmt.expression as AssignmentExpression;
        if (assignment.operator.type == TokenType.EQ &&
            assignment.rightHandSide is ConditionalExpression) {
          conditional = assignment.rightHandSide as ConditionalExpression;
          inAssignment = true;
        }
      }
    }
    // return
    var inReturn = false;
    if (statement is ReturnStatement) {
      var returnStatement = statement;
      if (returnStatement.expression is ConditionalExpression) {
        conditional = returnStatement.expression as ConditionalExpression;
        inReturn = true;
      }
    }
    // prepare environment
    var indent = utils.getIndent(1);
    var prefix = utils.getNodePrefix(statement);

    if (inVariable || inAssignment || inReturn) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        // Type v = Conditional;
        if (inVariable) {
          var variable = conditional.parent as VariableDeclaration;
          builder.addDeletion(range.endEnd(variable.name, conditional));
          var conditionSrc = _getNodeText(conditional.condition);
          var thenSrc = _getNodeText(conditional.thenExpression);
          var elseSrc = _getNodeText(conditional.elseExpression);
          var name = variable.name.name;
          var src = eol;
          src += prefix + 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.endLength(statement, 0), src);
        }
        // v = Conditional;
        if (inAssignment) {
          var assignment = conditional.parent as AssignmentExpression;
          var leftSide = assignment.leftHandSide;
          var conditionSrc = _getNodeText(conditional.condition);
          var thenSrc = _getNodeText(conditional.thenExpression);
          var elseSrc = _getNodeText(conditional.elseExpression);
          var name = _getNodeText(leftSide);
          var src = '';
          src += 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.node(statement), src);
        }
        // return Conditional;
        if (inReturn) {
          var conditionSrc = _getNodeText(conditional.condition);
          var thenSrc = _getNodeText(conditional.thenExpression);
          var elseSrc = _getNodeText(conditional.elseExpression);
          var src = '';
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
    // should be "if"
    if (node is! IfStatement) {
      return;
    }
    var ifStatement = node as IfStatement;
    // single then/else statements
    var thenStatement = getSingleStatement(ifStatement.thenStatement);
    var elseStatement = getSingleStatement(ifStatement.elseStatement);
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    Expression thenExpression;
    Expression elseExpression;
    var hasReturnStatements = false;
    if (thenStatement is ReturnStatement && elseStatement is ReturnStatement) {
      hasReturnStatements = true;
      thenExpression = thenStatement.expression;
      elseExpression = elseStatement.expression;
    }
    var hasExpressionStatements = false;
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
          var conditionSrc = _getNodeText(ifStatement.condition);
          var theSrc = _getNodeText(thenExpression);
          var elseSrc = _getNodeText(elseExpression);
          builder.addSimpleReplacement(range.node(ifStatement),
              'return $conditionSrc ? $theSrc : $elseSrc;');
        }
        // assignments -> v = Conditional;
        if (hasExpressionStatements) {
          AssignmentExpression thenAssignment = thenExpression;
          AssignmentExpression elseAssignment = elseExpression;
          var thenTarget = _getNodeText(thenAssignment.leftHandSide);
          var elseTarget = _getNodeText(elseAssignment.leftHandSide);
          if (thenAssignment.operator.type == TokenType.EQ &&
              elseAssignment.operator.type == TokenType.EQ &&
              thenTarget == elseTarget) {
            var conditionSrc = _getNodeText(ifStatement.condition);
            var theSrc = _getNodeText(thenAssignment.rightHandSide);
            var elseSrc = _getNodeText(elseAssignment.rightHandSide);
            builder.addSimpleReplacement(range.node(ifStatement),
                '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
    }
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
        final type = variable.declaredElement.type;
        if (!type.isDynamic) {
          builder.addReplacement(range.token(variableList.keyword), (builder) {
            builder.writeType(type);
          });
        }
      }

      var indent = utils.getNodePrefix(statement);
      var name = variable.name.name;
      builder.addSimpleInsertion(variable.name.end, ';' + eol + indent + name);
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.SPLIT_VARIABLE_DECLARATION);
  }

  Future<void> _addProposal_surroundWith() async {
    // prepare selected statements
    List<Statement> selectedStatements;
    {
      var selectionAnalyzer = StatementAnalyzer(
          context.resolveResult, SourceRange(selectionOffset, selectionLength));
      selectionAnalyzer.analyze();
      var selectedNodes = selectionAnalyzer.selectedNodes;
      // convert nodes to statements
      selectedStatements = [];
      for (var selectedNode in selectedNodes) {
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
    var firstStatement = selectedStatements[0];
    var statementsRange = utils.getLinesRangeStatements(selectedStatements);
    // prepare environment
    var indentOld = utils.getNodePrefix(firstStatement);
    var indentNew = '$indentOld${utils.getIndent(1)}';
    var indentedCode =
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

    // flutter "setState((){ .. });"
    {
      var classDeclaration =
          node.parent.thisOrAncestorOfType<ClassDeclaration>();
      if (classDeclaration != null &&
          flutter.isState(classDeclaration.declaredElement)) {
        final changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addReplacement(statementsRange, (DartEditBuilder builder) {
            builder.write(indentOld);
            builder.writeln('setState(() {');
            builder.write(indentedCode);
            builder.write(indentOld);
            builder.selectHere();
            builder.writeln('});');
          });
        });
        _addAssistFromBuilder(
            changeBuilder, DartAssistKind.SURROUND_WITH_SET_STATE);
      }
    }
  }

  bool _containsErrorCode(Set<String> errorCodes) {
    final fileOffset = node.offset;
    for (var error in context.resolveResult.errors) {
      final errorSource = error.source;
      if (file == errorSource.fullName) {
        if (fileOffset >= error.offset &&
            fileOffset <= error.offset + error.length) {
          if (errorCodes.contains(error.errorCode.name)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _convertFlutterChildToChildren(
      NamedExpression namedExp,
      String eol,
      Function getNodeText,
      Function getLinePrefix,
      Function getIndent,
      Function getText,
      DartFileEditBuilder builder) {
    var childArg = namedExp.expression;
    var childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    var listLoc = childArg.offset;
    String childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      var newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      String indentOld = getLinePrefix(childArg.offset + 1 + newlineLoc);
      var indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      String separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      var prefix = separator.contains(eol) ? '' : '$eol$indentNew';
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(namedExp.offset + 'child:'.length, ' [');
        var argOffset = childArg.offset;
        builder
            .addDeletion(range.startOffsetEndOffset(argOffset - 2, argOffset));
      } else {
        builder.addSimpleInsertion(listLoc, '[');
      }
      var newChildArgSrc =
          _replaceSourceIndent(childArgSrc, indentOld, indentNew);
      newChildArgSrc = '$prefix$newChildArgSrc,$eol$indentOld]';
      builder.addSimpleReplacement(range.node(childArg), newChildArgSrc);
    }
  }

  /// Returns the text of the given node in the unit.
  String _getNodeText(AstNode node) {
    return utils.getNodeText(node);
  }

  /// Returns the text of the given range in the unit.
  String _getRangeText(SourceRange range) {
    return utils.getRangeText(range);
  }

  DartChangeBuilder _newDartChangeBuilder() {
    return DartChangeBuilderImpl.forWorkspace(context.workspace);
  }

  Future<void> _swapParentAndChild(InstanceCreationExpression parent,
      InstanceCreationExpression child, AssistKind kind) async {
    // The child must have its own child.
    if (flutter.findChildArgument(child) == null) {
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
        for (var argument in childArgs.arguments) {
          if (flutter.isChildArgument(argument)) {
            stableChild = argument;
          } else {
            var text = _getNodeText(argument);
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
        for (var argument in parentArgs.arguments) {
          if (!flutter.isChildArgument(argument)) {
            var text = _getNodeText(argument);
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

  /// Create and return a map that can be used to look up the names of the lints
  /// for which a given `CorrectionProducer` will be used. This allows us to
  /// ensure that we do not also offer the change as an assist when it's already
  /// being offered as a fix.
  static Map<ProducerGenerator, Set<String>> createLintRuleMap() {
    var map = <ProducerGenerator, Set<String>>{};
    for (var entry in FixProcessor.lintProducerMap.entries) {
      var lintName = entry.key;
      for (var generator in entry.value) {
        map.putIfAbsent(generator, () => <String>{}).add(lintName);
      }
    }
    return map;
  }

  static String _replaceSourceIndent(
      String source, String indentOld, String indentNew) {
    return source.replaceAll(RegExp('^$indentOld', multiLine: true), indentNew);
  }

  /// Checks if the given [Expression] should be wrapped with parenthesis when
  /// we want to use it as operand of a logical `and` expression.
  static bool _shouldWrapParenthesisBeforeAnd(Expression expr) {
    if (expr is BinaryExpression) {
      var binary = expr;
      var precedence = binary.operator.type.precedence;
      return precedence < TokenClass.LOGICAL_AND_OPERATOR.precedence;
    }
    return false;
  }
}

class _SimpleIdentifierRecursiveAstVisitor extends RecursiveAstVisitor<void> {
  final _SimpleIdentifierVisitor visitor;

  _SimpleIdentifierRecursiveAstVisitor(this.visitor);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    visitor(node);
  }
}
