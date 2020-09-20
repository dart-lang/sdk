// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class FlutterMoveUp extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_MOVE_UP;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var widget = flutter.identifyWidgetExpression(node);
    if (widget == null) {
      return;
    }

    var parentList = widget.parent;
    if (parentList is ListLiteral) {
      List<CollectionElement> parentElements = parentList.elements;
      var index = parentElements.indexOf(widget);
      if (index > 0) {
        await builder.addDartFileEdit(file, (fileBuilder) {
          var previousWidget = parentElements[index - 1];
          var previousRange = range.node(previousWidget);
          var previousText = utils.getRangeText(previousRange);

          var widgetRange = range.node(widget);
          var widgetText = utils.getRangeText(widgetRange);

          fileBuilder.addSimpleReplacement(previousRange, widgetText);
          fileBuilder.addSimpleReplacement(widgetRange, previousText);

          var newWidgetOffset = previousRange.offset;
          builder.setSelection(Position(file, newWidgetOffset));
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterMoveUp newInstance() => FlutterMoveUp();
}
