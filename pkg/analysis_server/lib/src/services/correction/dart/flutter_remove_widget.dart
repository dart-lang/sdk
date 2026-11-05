// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterRemoveWidget extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.flutterRemoveWidget;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryContainer;

  @override
  FixKind? get multiFixKind => DartFixKind.removeUnnecessaryContainerMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetCreation = node.findInstanceCreationExpression;
    if (widgetCreation == null || !widgetCreation.isWidgetCreation) {
      return;
    }

    if (applyingBulkFixes) {
      await _removeDiagnosedContainers(builder, widgetCreation);
      return;
    }

    if (widgetCreation.childrenArgument case var childrenArgument?) {
      var childrenExpression = childrenArgument.argumentExpression;
      if (childrenExpression is ListLiteral &&
          childrenExpression.elements.isNotEmpty) {
        await _removeChildren(
          builder,
          widgetCreation,
          childrenExpression.elements,
        );
      }
    } else if (widgetCreation.childArgument case var childArgument?) {
      await _removeSingle(
        builder,
        widgetCreation,
        childArgument.argumentExpression,
      );
    } else if (widgetCreation.builderArgument case var builderArgument?) {
      await _removeBuilder(builder, widgetCreation, builderArgument);
    } else if (widgetCreation.sliversArgument case var sliversArgument?) {
      var sliversExpression = sliversArgument.argumentExpression;
      if (sliversExpression is ListLiteral &&
          sliversExpression.elements.isNotEmpty) {
        await _removeChildren(
          builder,
          widgetCreation,
          sliversExpression.elements,
        );
      }
    } else if (widgetCreation.sliverArgument case var sliverArgument?) {
      await _removeSingle(
        builder,
        widgetCreation,
        sliverArgument.argumentExpression,
      );
    } else {
      await _removeSingleWhenInList(builder, widgetCreation);
    }
  }

  /// Whether [container] is enclosed by another container in
  /// [diagnosedContainers].
  ///
  /// If [root] is provided, the search considers ancestors only through
  /// [root], including [root] itself. A [container] equal to [root] is not
  /// considered its own ancestor.
  ///
  /// The bounded search is used while composing a replacement to select only
  /// the outermost diagnosed containers within the subtree being rewritten.
  bool _hasDiagnosedAncestor(
    InstanceCreationExpression container,
    Set<InstanceCreationExpression> diagnosedContainers, {
    AstNode? root,
  }) {
    if (container == root) return false;

    for (
      var ancestor = container.parent;
      ancestor != null;
      ancestor = ancestor.parent
    ) {
      if (diagnosedContainers.contains(ancestor)) return true;
      if (ancestor == root) return false;
    }
    return false;
  }

  Future<void> _removeBuilder(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
    NamedArgument builderArgument,
  ) async {
    var builderExpression = builderArgument.argumentExpression;
    if (builderExpression is! FunctionExpression) return;
    var parameterElement = builderExpression
        .parameters
        ?.parameters
        .firstOrNull
        ?.declaredFragment
        ?.element;
    if (parameterElement == null) return;

    var visitor = _UsageFinder(parameterElement);
    var body = builderExpression.body;
    body.visitChildren(visitor);
    if (visitor.used) return;

    if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length != 1) return;
      var statement = statements.first;
      if (statement is! ReturnStatement) return;
      var expression = statement.expression;
      if (expression == null) return;
      await _removeSingle(builder, widgetCreation, expression);
    } else if (body is ExpressionFunctionBody) {
      await _removeSingle(builder, widgetCreation, body.expression);
    }
  }

  Future<void> _removeChildren(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
    List<CollectionElement> childrenExpressions,
  ) async {
    // We can inline the list of our children only into another list.
    var widgetParentNode = widgetCreation.parent;
    if (childrenExpressions.length > 1 && widgetParentNode is! ListLiteral) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var firstChild = childrenExpressions.first;
      var lastChild = childrenExpressions.last;
      var childText = utils.getRangeText(range.startEnd(firstChild, lastChild));
      var indentOld = utils.getLinePrefix(firstChild.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = utils.replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }

  /// Removes the outermost diagnosed container, including any diagnosed
  /// containers nested inside it.
  ///
  /// Each single-location fix replaces its whole container, so independently
  /// produced fixes for nested containers overlap. In bulk, the outermost
  /// diagnostic coordinates the nested fixes and produces one replacement.
  Future<void> _removeDiagnosedContainers(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
  ) async {
    var diagnosticCode = diagnostic?.diagnosticCode;
    if (diagnosticCode == null) return;

    // Use the diagnostics reported for this unit, rather than finding matching
    // containers syntactically, so ignored diagnostics remain untouched.
    var diagnosedContainers = <InstanceCreationExpression>{};
    for (var candidate in unitResult.diagnostics) {
      if (candidate.diagnosticCode != diagnosticCode) continue;

      var candidateNode = unit.nodeCovering(
        offset: candidate.offset,
        length: candidate.length,
      );
      var candidateCreation = candidateNode?.findInstanceCreationExpression;
      if (candidateCreation != null) {
        diagnosedContainers.add(candidateCreation);
      }
    }

    // The bulk processor invokes this producer for every diagnostic. Let only
    // the outermost diagnosed container coordinate each nested group; its
    // descendants will be folded into its replacement.
    if (!diagnosedContainers.contains(widgetCreation) ||
        _hasDiagnosedAncestor(widgetCreation, diagnosedContainers)) {
      return;
    }

    // Compose all nested removals before adding an edit, avoiding replacements
    // whose source ranges overlap the outer container.
    var replacement = _replacementForDiagnosedContainer(
      widgetCreation,
      diagnosedContainers,
    );
    if (replacement == null) return;

    // One whole-container replacement now represents the complete nested
    // transformation coordinated by this diagnostic.
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(widgetCreation), replacement);
    });
  }

  Future<void> _removeSingle(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
    Expression expression,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      var childText = utils.getNodeText(expression);
      var indentOld = utils.getLinePrefix(expression.offset);
      var indentNew = utils.getLinePrefix(widgetCreation.offset);
      childText = utils.replaceSourceIndent(childText, indentOld, indentNew);
      builder.addSimpleReplacement(range.node(widgetCreation), childText);
    });
  }

  Future<void> _removeSingleWhenInList(
    ChangeBuilder builder,
    InstanceCreationExpression widgetCreation,
  ) async {
    // We can only remove the widget when this widget is in list.
    var widgetParentNode = widgetCreation.parent;
    if (widgetParentNode is! ListLiteral) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        range.nodeInList(widgetParentNode.elements, widgetCreation),
      );
    });
  }

  /// Builds the source that replaces [container] when it is removed.
  ///
  /// Diagnosed containers within its `child:` expression are removed
  /// recursively before the child is promoted to the indentation of
  /// [container].
  ///
  /// Returns `null` if [container] has no `child:` argument and therefore
  /// cannot be handled by this bulk-removal path.
  String? _replacementForDiagnosedContainer(
    InstanceCreationExpression container,
    Set<InstanceCreationExpression> diagnosedContainers,
  ) {
    var childArgument = container.childArgument;
    if (childArgument == null) return null;

    var child = childArgument.argumentExpression;
    var childText = _textWithDiagnosedContainersRemoved(
      child,
      diagnosedContainers,
    );
    var oldIndent = utils.getLinePrefix(child.offset);
    var newIndent = utils.getLinePrefix(container.offset);
    return utils.replaceSourceIndent(childText, oldIndent, newIndent);
  }

  /// Returns the source of [expression] with diagnosed containers in its
  /// subtree, including [expression] itself, recursively replaced by their
  /// children.
  ///
  /// Only the outermost diagnosed containers within [expression] are replaced
  /// directly. Their diagnosed descendants are incorporated recursively into
  /// those replacements, ensuring that no generated source ranges overlap.
  /// Sibling replacements are applied from right to left so their original
  /// offsets remain valid.
  String _textWithDiagnosedContainersRemoved(
    Expression expression,
    Set<InstanceCreationExpression> diagnosedContainers,
  ) {
    var nestedContainers = diagnosedContainers.where((container) {
      return expression.offset <= container.offset &&
          container.end <= expression.end &&
          !_hasDiagnosedAncestor(
            container,
            diagnosedContainers,
            root: expression,
          );
    }).toList()..sort((a, b) => b.offset.compareTo(a.offset));

    var text = utils.getNodeText(expression);
    for (var container in nestedContainers) {
      var replacement = _replacementForDiagnosedContainer(
        container,
        diagnosedContainers,
      );
      if (replacement == null) continue;

      var relativeOffset = container.offset - expression.offset;
      text = text.replaceRange(
        relativeOffset,
        relativeOffset + container.length,
        replacement,
      );
    }
    return text;
  }
}

class _UsageFinder extends RecursiveAstVisitor<void> {
  final Element element;
  bool used = false;

  new(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.writeOrReadElement == element) {
      used = true;
    }
  }
}
