// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_not_null_assert.dart';
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
import 'package:analysis_server/src/services/correction/dart/convert_into_for_index.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_getter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_part_of_to_uri.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_field_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_multiline_string.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_normal_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/encapsulate_field.dart';
import 'package:analysis_server/src/services/correction/dart/exchange_operands.dart';
import 'package:analysis_server/src/services/correction/dart/import_add_show.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/introduce_local_cast_type.dart';
import 'package:analysis_server/src/services/correction/dart/invert_if_statement.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/shadow_field.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/split_and_condition.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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
    AddNotNullAssert.newInstance,
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
    ConvertIntoForIndex.newInstance,
    ConvertIntoGetter.newInstance,
    ConvertIntoIsNot.newInstance,
    ConvertIntoIsNotEmpty.newInstance,
    ConvertMapFromIterableToForLiteral.newInstance,
    ConvertPartOfToUri.newInstance,
    ConvertToDoubleQuotes.newInstance,
    ConvertToFieldParameter.newInstance,
    ConvertToMutilineString.newInstance,
    ConvertToNormalParameter.newInstance,
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
    EncapsulateField.newInstance,
    ExchangeOperands.newInstance,
    ImportAddShow.newInstance,
    InlineInvocation.newInstance,
    IntroduceLocalCastType.newInstance,
    InvertIfStatement.newInstance,
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
