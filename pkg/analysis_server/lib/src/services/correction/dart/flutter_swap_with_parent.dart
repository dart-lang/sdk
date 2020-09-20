// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_swap_with_child.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class FlutterSwapWithParent extends FlutterParentAndChild {
  @override
  AssistKind get assistKind => DartAssistKind.FLUTTER_SWAP_WITH_PARENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var child = flutter.identifyNewExpression(node);
    if (!flutter.isWidgetCreation(child)) {
      return;
    }

    // NamedExpression (child:), ArgumentList, InstanceCreationExpression
    var expr = child.parent?.parent?.parent;
    if (expr is! InstanceCreationExpression) {
      return;
    }

    await swapParentAndChild(builder, expr, child);
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static FlutterSwapWithParent newInstance() => FlutterSwapWithParent();
}
