// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/js_model/locals.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:front_end/src/testing/id_extractor.dart';

export 'package:_fe_analyzer_shared/src/testing/id.dart';
export 'package:front_end/src/testing/id_extractor.dart';

SourceSpan computeSourceSpanFromUriOffset(Uri uri, int offset) {
  if (uri != null) {
    if (offset != null) {
      return new SourceSpan(uri, offset, offset + 1);
    } else {
      return new SourceSpan(uri, 0, 0);
    }
  }
  return null;
}

abstract class IrDataRegistryMixin<T> implements DataRegistry<T> {
  DiagnosticReporter get reporter;

  @override
  void report(Uri uri, int offset, String message) {
    reportHere(reporter, computeSourceSpanFromUriOffset(uri, offset), message);
  }

  @override
  void fail(String message) {
    Expect.fail(message);
  }
}

abstract class IrDataExtractor<T> extends DataExtractor<T>
    with IrDataRegistryMixin<T> {
  @override
  final DiagnosticReporter reporter;

  IrDataExtractor(this.reporter, Map<Id, ActualData<T>> actualMap)
      : super(actualMap);

  SourceSpan computeSourceSpan(ir.TreeNode node) {
    return computeSourceSpanFromTreeNode(node);
  }

  @override
  visitLabeledStatement(ir.LabeledStatement node) {
    if (!JumpVisitor.canBeBreakTarget(node.body) &&
        !JumpVisitor.canBeContinueTarget(node.parent)) {
      computeForNode(node, createLabeledStatementId(node));
    }
    super.visitLabeledStatement(node);
  }
}
