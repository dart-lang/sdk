// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ConvertIntoAsyncBody extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_ASYNC_BODY;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var body = getEnclosingFunctionBody();
    if (body == null ||
        body is EmptyFunctionBody ||
        body.isAsynchronous ||
        body.isGenerator) {
      return;
    }

    // Function bodies can be quite large, e.g. Flutter build() methods.
    // It is surprising to see this Quick Assist deep in a function body.
    if (body is BlockFunctionBody &&
        selectionOffset > body.block.beginToken.end) {
      return;
    }
    if (body is ExpressionFunctionBody &&
        selectionOffset > body.beginToken.end) {
      return;
    }

    var parent = body.parent;
    if (parent is ConstructorDeclaration) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.convertFunctionFromSyncToAsync(body, typeProvider);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoAsyncBody newInstance() => ConvertIntoAsyncBody();
}
