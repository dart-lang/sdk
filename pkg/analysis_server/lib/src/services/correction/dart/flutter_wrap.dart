// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrap extends MultiCorrectionProducer {
  FlutterWrap({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var producers = <ResolvedCorrectionProducer>[];
    var widgetExpr = node.findWidgetExpression;
    if (widgetExpr != null) {
      var widgetType = widgetExpr.typeOrThrow;
      producers.add(_FlutterWrapGeneric(widgetExpr, context: context));
      if (!widgetType.isExactWidgetTypeCenter) {
        producers.add(_FlutterWrapCenter(widgetExpr, context: context));
      }
      if (!widgetType.isExactWidgetTypeContainer) {
        producers.add(_FlutterWrapContainer(widgetExpr, context: context));
      }
      if (!widgetType.isExactWidgetTypeExpanded &&
          (widgetExpr.isParentFlexWidget || !widgetExpr.isParentWidget)) {
        producers.add(_FlutterWrapExpanded(widgetExpr, context: context));
      }
      if (!widgetType.isExactWidgetTypeFlexible &&
          (widgetExpr.isParentFlexWidget || !widgetExpr.isParentWidget)) {
        producers.add(_FlutterWrapFlexible(widgetExpr, context: context));
      }
      if (!widgetType.isExactWidgetTypePadding) {
        producers.add(_FlutterWrapPadding(widgetExpr, context: context));
      }
      if (!widgetType.isExactWidgetTypeSizedBox) {
        producers.add(_FlutterWrapSizedBox(widgetExpr, context: context));
      }
    }
    await _wrapMultipleWidgets(producers);
    return producers;
  }

  Future<void> _wrapMultipleWidgets(
    List<ResolvedCorrectionProducer> producers,
  ) async {
    var selectionRange = SourceRange(selectionOffset, selectionLength);
    var analyzer = SelectionAnalyzer(selectionRange);
    unitResult.unit.accept(analyzer);

    var widgetExpressions = <Expression>[];
    if (analyzer.hasSelectedNodes) {
      for (var selectedNode in analyzer.selectedNodes) {
        // If the user has selected exactly a Widget constructor name (without
        // the argument list), expand the selection.
        //
        //    Text('foo')
        //   [^^^^]
        var parent = selectedNode.parent;
        if (selectedNode is ConstructorName &&
            parent is InstanceCreationExpression) {
          selectedNode = parent;
        }
        if (selectedNode is! Expression || !selectedNode.isWidgetExpression) {
          return;
        }
        widgetExpressions.add(selectedNode);
      }
    } else {
      var coveringNode = analyzer.coveringNode;

      // If the coveringNode is an argument list but the caret is exactly at the
      // start (before the opening paren) we should use the parent instead
      // as the user associates this location with the widget name:
      //
      //     Text^('foo')
      if (coveringNode is ArgumentList &&
          coveringNode.offset == selectionOffset) {
        coveringNode = coveringNode.parent;
      }

      var widget = coveringNode.findWidgetExpression;
      if (widget != null) {
        widgetExpressions.add(widget);
      }
    }
    if (widgetExpressions.isEmpty) {
      return;
    }

    var firstWidget = widgetExpressions.first;
    var lastWidget = widgetExpressions.last;
    producers.add(
      _FlutterWrapColumn(firstWidget, lastWidget, context: context),
    );
    producers.add(_FlutterWrapRow(firstWidget, lastWidget, context: context));
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapCenter extends _WrapSingleWidget {
  _FlutterWrapCenter(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CENTER;

  @override
  String get _parentClassName => 'Center';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapColumn extends _WrapMultipleWidgets {
  _FlutterWrapColumn(
    super.firstWidget,
    super.lastWidget, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_COLUMN;

  @override
  String get _parentClassName => 'Column';
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapContainer extends _WrapSingleWidget {
  _FlutterWrapContainer(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CONTAINER;

  @override
  String get _parentClassName => 'Container';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapExpanded extends _WrapSingleWidget {
  _FlutterWrapExpanded(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_EXPANDED;

  @override
  String get _parentClassName => 'Expanded';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapFlexible extends _WrapSingleWidget {
  _FlutterWrapFlexible(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_FLEXIBLE;

  @override
  String get _parentClassName => 'Flexible';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapGeneric extends _WrapSingleWidget {
  _FlutterWrapGeneric(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_GENERIC;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapPadding extends _WrapSingleWidget {
  _FlutterWrapPadding(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_PADDING;

  @override
  List<String> get _leadingLines {
    var keyword = widgetExpr.inConstantContext ? '' : ' const';
    var codeStyleOptions = getCodeStyleOptions(unitResult.file);
    var paddingStr = codeStyleOptions.preferIntLiterals ? '8' : '8.0';
    return ['padding:$keyword EdgeInsets.all($paddingStr),'];
  }

  @override
  String get _parentClassName => 'Padding';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapRow extends _WrapMultipleWidgets {
  _FlutterWrapRow(
    super.firstWidget,
    super.lastWidget, {
    required super.context,
  });

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_ROW;

  @override
  String get _parentClassName => 'Row';
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapSizedBox extends _WrapSingleWidget {
  _FlutterWrapSizedBox(super.widgetExpr, {required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_SIZED_BOX;

  @override
  String get _parentClassName => 'SizedBox';

  @override
  String get _parentLibraryUri => widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
abstract class _WrapMultipleWidgets extends ResolvedCorrectionProducer {
  final Expression firstWidget;

  final Expression lastWidget;

  _WrapMultipleWidgets(
    this.firstWidget,
    this.lastWidget, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  String get _parentClassName;

  String get _parentLibraryUri => widgetsUri;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var selectedRange = range.startEnd(firstWidget, lastWidget);
    var src = utils.getRangeText(selectedRange);
    var parentClassElement = await sessionHelper.getClass(
      _parentLibraryUri,
      _parentClassName,
    );
    var widgetClassElement = await sessionHelper.getFlutterClass('Widget');
    if (parentClassElement == null || widgetClassElement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(selectedRange, (builder) {
        builder.writeReference(parentClassElement);
        builder.write('(');

        var indentOld = utils.getLinePrefix(firstWidget.offset);
        var indentNew1 = indentOld + utils.oneIndent;
        var indentNew2 = indentOld + utils.twoIndents;

        builder.write(eol);
        builder.write(indentNew1);
        builder.write('children: [');
        builder.write(eol);

        var newSrc = utils.replaceSourceIndent(src, indentOld, indentNew2);
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
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
abstract class _WrapSingleWidget extends ResolvedCorrectionProducer {
  final Expression widgetExpr;

  _WrapSingleWidget(this.widgetExpr, {required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  List<String> get _leadingLines => const [];

  String? get _parentClassName => null;

  String? get _parentLibraryUri => null;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetSrc = utils.getNodeText(widgetExpr);

    // If the wrapper class is specified, find its element.
    var parentLibraryUri = _parentLibraryUri;
    var parentClassName = _parentClassName;
    ClassElement2? parentClassElement;
    if (parentLibraryUri != null && parentClassName != null) {
      parentClassElement = await sessionHelper.getClass(
        parentLibraryUri,
        parentClassName,
      );
      if (parentClassElement == null) {
        return;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        if (parentClassElement == null) {
          builder.addSimpleLinkedEdit('WIDGET', 'widget');
        } else {
          builder.writeReference(parentClassElement);
        }
        builder.write('(');
        // When there's no linked edit for the widget name, leave the selection
        // inside the opening paren which is useful if you want to add
        // additional named arguments to the newly-created widget.
        if (parentClassElement != null) {
          builder.selectHere();
        }
        var leadingLines = _leadingLines;
        if (widgetSrc.contains(eol) || leadingLines.isNotEmpty) {
          var indentOld = utils.getLinePrefix(widgetExpr.offset);
          var indentNew = '$indentOld${utils.oneIndent}';

          for (var leadingLine in leadingLines) {
            builder.write(eol);
            builder.write(indentNew);
            builder.write(leadingLine);
          }

          builder.write(eol);
          builder.write(indentNew);
          widgetSrc = utils.replaceSourceIndent(
            widgetSrc,
            indentOld,
            indentNew,
          );
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
  }
}

extension on Expression {
  /// Return `true` if the parent is a `Flex` widget creation.
  ///
  /// This is used to determine if the widget is wrapped in a `Row`, `Column`,
  /// or `Flex` widget.
  bool get isParentFlexWidget {
    var parent = _getParentInstanceCreationExpression();
    if (parent == null || !parent.isWidgetCreation) {
      return false;
    }
    return parent.staticType.isWidgetFlexType;
  }

  /// Return `true` if the parent is a widget creation.
  ///
  /// This tells if this is a direct child of a widget creation.
  /// It will return `false` if we are assigning this to a variable or
  /// returning it from a function or other similar cases.
  bool get isParentWidget {
    var parent = _getParentInstanceCreationExpression();
    return parent != null && parent.isWidgetCreation;
  }

  /// Return the parent `InstanceCreationExpression` if it exists.
  ///
  /// This is used to find the parent widget creation if it exists.
  InstanceCreationExpression? _getParentInstanceCreationExpression() {
    var self = this;
    NamedExpression? namedExpression;
    if (self.parent case ListLiteral listLiteral) {
      if (listLiteral.parent case NamedExpression parent) {
        namedExpression = parent;
      }
    }
    // NamedExpression (child:), ArgumentList, InstanceCreationExpression
    if ((namedExpression ?? self.parent)?.parent?.parent
        case InstanceCreationExpression parent?) {
      return parent;
    }
    return null;
  }
}

extension on DartType? {
  bool get isWidgetFlexType {
    var self = this;
    return self is InterfaceType && self.element3.isFlexWidget;
  }
}
