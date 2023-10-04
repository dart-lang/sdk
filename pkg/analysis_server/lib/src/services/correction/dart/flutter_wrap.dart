// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterWrap extends MultiCorrectionProducer {
  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var producers = <ResolvedCorrectionProducer>[];
    var widgetExpr = flutter.identifyWidgetExpression(node);
    if (widgetExpr != null) {
      var widgetType = widgetExpr.typeOrThrow;
      producers.add(_FlutterWrapGeneric(widgetExpr));
      if (!flutter.isExactWidgetTypeCenter(widgetType)) {
        producers.add(_FlutterWrapCenter(widgetExpr));
      }
      if (!flutter.isExactWidgetTypeContainer(widgetType)) {
        producers.add(_FlutterWrapContainer(widgetExpr));
      }
      if (!flutter.isExactWidgetTypePadding(widgetType)) {
        producers.add(_FlutterWrapPadding(widgetExpr));
      }
      if (!flutter.isExactWidgetTypeSizedBox(widgetType)) {
        producers.add(_FlutterWrapSizedBox(widgetExpr));
      }
    }
    await _wrapMultipleWidgets(producers);
    return producers;
  }

  Future<void> _wrapMultipleWidgets(
      List<ResolvedCorrectionProducer> producers) async {
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
        if (selectedNode is! Expression ||
            !flutter.isWidgetExpression(selectedNode)) {
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
    producers.add(_FlutterWrapColumn(firstWidget, lastWidget));
    producers.add(_FlutterWrapRow(firstWidget, lastWidget));
  }
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapCenter extends _WrapSingleWidget {
  _FlutterWrapCenter(super.widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CENTER;

  @override
  String get _parentClassName => 'Center';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapColumn extends _WrapMultipleWidgets {
  _FlutterWrapColumn(super.firstWidget, super.lastWidget);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_COLUMN;

  @override
  String get _parentClassName => 'Column';
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapContainer extends _WrapSingleWidget {
  _FlutterWrapContainer(super.widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_CONTAINER;

  @override
  String get _parentClassName => 'Container';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapGeneric extends _WrapSingleWidget {
  _FlutterWrapGeneric(super.widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_GENERIC;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapPadding extends _WrapSingleWidget {
  _FlutterWrapPadding(super.widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_PADDING;

  @override
  List<String> get _leadingLines {
    var keyword = widgetExpr.inConstantContext ? '' : ' const';
    return ['padding:$keyword EdgeInsets.all(8.0),'];
  }

  @override
  String get _parentClassName => 'Padding';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapRow extends _WrapMultipleWidgets {
  _FlutterWrapRow(super.firstWidget, super.lastWidget);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_ROW;

  @override
  String get _parentClassName => 'Row';
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
class _FlutterWrapSizedBox extends _WrapSingleWidget {
  _FlutterWrapSizedBox(super.widgetExpr);

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_WRAP_SIZED_BOX;

  @override
  String get _parentClassName => 'SizedBox';

  @override
  String get _parentLibraryUri => flutter.widgetsUri;
}

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
abstract class _WrapMultipleWidgets extends ResolvedCorrectionProducer {
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

        var newSrc = utils.replaceSourceIndent(
          src,
          indentOld,
          indentNew2,
          includeLeading: false,
          includeTrailingNewline: false,
        );
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

  _WrapSingleWidget(this.widgetExpr);

  List<String> get _leadingLines => const [];

  String? get _parentClassName => null;

  String? get _parentLibraryUri => null;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widgetSrc = utils.getNodeText(widgetExpr);

    // If the wrapper class is specified, find its element.
    var parentLibraryUri = _parentLibraryUri;
    var parentClassName = _parentClassName;
    ClassElement? parentClassElement;
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
        // When there's no linked edit for the widget name, leave the selection
        // inside the opening paren which is useful if you want to add
        // additional named arguments to the newly-created widget.
        if (parentClassElement != null) {
          builder.selectHere();
        }
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
          widgetSrc = utils.replaceSourceIndent(
            widgetSrc,
            indentOld,
            indentNew,
            includeLeading: false,
            includeTrailingNewline: false,
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
