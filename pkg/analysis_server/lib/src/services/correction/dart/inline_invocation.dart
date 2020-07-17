// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InlineInvocation extends CorrectionProducer {
  @override
  List<Object> get assistArguments => ['add'];

  @override
  AssistKind get assistKind => DartAssistKind.INLINE_INVOCATION;

  @override
  List<Object> get fixArguments => ['add'];

  @override
  FixKind get fixKind => DartFixKind.INLINE_INVOCATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      return;
    }
    SimpleIdentifier name = node;
    MethodInvocation invocation = node.parent;
    if (name != invocation.methodName ||
        name.name != 'add' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      return;
    }
    var cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    var sections = cascade.cascadeSections;
    var target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      return;
    }
    ListLiteral list = target;
    var argument = invocation.argumentList.arguments[0];
    var elementText = utils.getNodeText(argument);

    await builder.addDartFileEdit(file, (builder) {
      if (list.elements.isNotEmpty) {
        // ['a']..add(e);
        builder.addSimpleInsertion(list.elements.last.end, ', $elementText');
      } else {
        // []..add(e);
        builder.addSimpleInsertion(list.leftBracket.end, elementText);
      }
      builder.addDeletion(range.node(invocation));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static InlineInvocation newInstance() => InlineInvocation();
}
