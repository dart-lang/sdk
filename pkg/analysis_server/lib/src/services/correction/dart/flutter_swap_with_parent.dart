// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_swap_with_child.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class FlutterSwapWithParent extends FlutterParentAndChild {
  FlutterSwapWithParent({required super.context});

  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_SWAP_WITH_PARENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var child = node.findInstanceCreationExpression;
    if (child == null || !child.isWidgetCreation) {
      return;
    }
    var parentHadSingleChild = true;

    NamedExpression? namedExpression;
    if (child.parent case ListLiteral listLiteral) {
      if (listLiteral.elements case NodeList(length: var length)
          when length != 1) {
        return;
      }
      if (listLiteral.parent case NamedExpression parent) {
        namedExpression = parent;
        parentHadSingleChild = false;
      }
    }
    // NamedExpression (child:), ArgumentList, InstanceCreationExpression
    var expr = (namedExpression ?? child.parent)?.parent?.parent;
    if (expr is! InstanceCreationExpression) {
      return;
    }

    await swapParentAndChild(builder, expr, child, parentHadSingleChild);
  }
}
