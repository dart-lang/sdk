// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrap extends MultiCorrectionProducer {
  @override
  Iterable<CorrectionProducer> get producers sync* {
    var widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr != null) {
      var widgetType = widgetExpr.staticType;
      yield _FlutterWrapGeneric(widgetExpr);
      if (!flutter.isExactWidgetTypeCenter(widgetType)) {
        yield _FlutterWrapCenter(widgetExpr);
      }
      if (!flutter.isExactWidgetTypeContainer(widgetType)) {
        yield _FlutterWrapContainer(widgetExpr);
      }
      if (!flutter.isExactWidgetTypePadding(widgetType)) {
        yield _FlutterWrapPadding(widgetExpr);
      }
      if (!flutter.isExactWidgetTypeSizedBox(widgetType)) {
        yield _FlutterWrapSizedBox(widgetExpr);
      }
    }
    yield* _wrapMultipleWidgets();
  }

  Iterable<CorrectionProducer> _wrapMultipleWidgets() sync* {
    var selectionRange = SourceRange(selectionOffset, selectionLength);
    var analyzer = SelectionAnalyzer(selectionRange);
    resolvedResult.unit.accept(analyzer);

    var widgetExpressions = <Expression>[];
    if (analyzer.hasSelectedNodes) {
      for (var selectedNode in analyzer.selectedNodes) {
        if (!flutter.isWidgetExpression(selectedNode)) {
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

      var widget = flutter.identifyWidgetExpression(coveringNode);
      if (widget != null) {
        widgetExpressions.add(widget);
      }
    }
    if (widgetExpressions.isEmpty) {
      return;
    }

    var firstWidget = widgetExpressions.first;
    var lastWidget = widgetExpressions.last;
    yield _FlutterWrapColumn(firstWidget, lastWidget);
    yield _FlutterWrapRow(firstWidget, lastWidget);
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterWrap newInstance() => FlutterWrap();
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapCenter extends _WrapSingleWidget {
  _FlutterWrapCenter(Expression widgetExpr) : super(widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CENTER;

  @override
  String get _parentClassName => 'Center';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapColumn extends _WrapMultipleWidgets {
  _FlutterWrapColumn(Expression firstWidget, Expression lastWidget)
      : super(firstWidget, lastWidget);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_COLUMN;

  @override
  String get _parentClassName => 'Column';
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapContainer extends _WrapSingleWidget {
  _FlutterWrapContainer(Expression widgetExpr) : super(widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CONTAINER;

  @override
  String get _parentClassName => 'Container';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapGeneric extends _WrapSingleWidget {
  _FlutterWrapGeneric(Expression widgetExpr) : super(widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_GENERIC;
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapPadding extends _WrapSingleWidget {
  _FlutterWrapPadding(Expression widgetExpr) : super(widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_PADDING;

  @override
  List<String> get _leadingLines {
    var keyword =
        (widgetExpr as ExpressionImpl).inConstantContext ? '' : ' const';
    return ['padding:$keyword EdgeInsets.all(8.0),'];
  }

  @override
  String get _parentClassName => 'Padding';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapRow extends _WrapMultipleWidgets {
  _FlutterWrapRow(Expression firstWidget, Expression lastWidget)
      : super(firstWidget, lastWidget);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_ROW;

  @override
  String get _parentClassName => 'Row';
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
class _FlutterWrapSizedBox extends _WrapSingleWidget {
  _FlutterWrapSizedBox(Expression widgetExpr) : super(widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_SIZED_BOX;

  @override
  String get _parentClassName => 'SizedBox';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
abstract class _WrapMultipleWidgets extends CorrectionProducer {
  final Expression firstWidget;

  final Expression lastWidget;

  _WrapMultipleWidgets(this.firstWidget, this.lastWidget);

  String get _parentClassName;

  String get _parentLibraryUri => flutter.widgetsUri;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var selectedRange = range.startEnd(firstWidget, lastWidget);
    var src = utils.getRangeText(selectedRange);
    var parentClassElement =
        await sessionHelper.getClass(_parentLibraryUri, _parentClassName);
    var widgetClassElement =
        await sessionHelper.getClass(flutter.widgetsUri, 'Widget');
    if (parentClassElement == null || widgetClassElement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(selectedRange, (builder) {
        builder.writeReference(parentClassElement);
        builder.write('(');

        var indentOld = utils.getLinePrefix(firstWidget.offset);
        var indentNew1 = indentOld + utils.getIndent(1);
        var indentNew2 = indentOld + utils.getIndent(2);

        builder.write(eol);
        builder.write(indentNew1);
        builder.write('children: [');
        builder.write(eol);

        var newSrc = replaceSourceIndent(src, indentOld, indentNew2);
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

/// A correction processor that can make one of the possible change computed by
/// the [FlutterWrap] producer.
abstract class _WrapSingleWidget extends CorrectionProducer {
  final Expression widgetExpr;

  _WrapSingleWidget(this.widgetExpr);

  List<String> get _leadingLines => const [];

  String get _parentClassName => null;

  String get _parentLibraryUri => null;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetSrc = utils.getNodeText(widgetExpr);

    // If the wrapper class is specified, find its element.
    var parentLibraryUri = _parentLibraryUri;
    var parentClassName = _parentClassName;
    ClassElement parentClassElement;
    if (parentLibraryUri != null && parentClassName != null) {
      parentClassElement =
          await sessionHelper.getClass(parentLibraryUri, parentClassName);
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
        var leadingLines = _leadingLines;
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
  }
}
