// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddTypeName extends ResolvedCorrectionProducer {
  AddTypeName({required super.context});

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  AssistKind? get assistKind => DartAssistKind.addTypeName;

  @override
  FixKind get fixKind => DartFixKind.addTypeName;

  @override
  FixKind? get multiFixKind => DartFixKind.addTypeNameMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node.thisOrParentDotShorthand;
    if (node == null) {
      // We are not on a dot-shorthand node.
      return;
    }
    var element = node.dotShorthandEnclosingElement;
    if (element is! InstanceElement) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(node.offset, (builder) {
        if (builder is DartEditBuilderImpl) {
          builder.writeType(element.thisType, writeTypeArguments: false);
        }
      });
    });
  }
}

extension on AstNode {
  /// Returns the enclosing element of the element represented by `this`.
  Element? get dotShorthandEnclosingElement => switch (this) {
    DotShorthandConstructorInvocation(:var constructorName) =>
      constructorName.element?.enclosingElement,
    DotShorthandInvocation(:var memberName) =>
      memberName.element?.enclosingElement,
    DotShorthandPropertyAccess(:var propertyName) =>
      propertyName.element?.enclosingElement,
    _ => null,
  };

  AstNode? get thisOrParentDotShorthand =>
      thisOrParentOfType<DotShorthandConstructorInvocation>() ??
      thisOrParentOfType<DotShorthandInvocation>() ??
      thisOrParentOfType<DotShorthandPropertyAccess>();

  AstNode? thisOrParentOfType<T extends AstNode>() {
    if (this is T) {
      return this;
    }
    if (parent case T parent) {
      return parent;
    }
    return null;
  }
}
