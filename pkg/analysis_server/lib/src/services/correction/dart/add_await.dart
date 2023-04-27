// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddAwait extends CorrectionProducer {
  /// The kind of correction to be made.
  final _CorrectionKind _correctionKind;

  @override
  bool canBeAppliedInBulk;

  @override
  bool canBeAppliedToFile;

  AddAwait.nonBool()
      : _correctionKind = _CorrectionKind.nonBool,
        canBeAppliedInBulk = false,
        canBeAppliedToFile = false;

  AddAwait.unawaited()
      : _correctionKind = _CorrectionKind.unawaited,
        canBeAppliedInBulk = true,
        canBeAppliedToFile = true;

  @override
  FixKind get fixKind => DartFixKind.ADD_AWAIT;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_AWAIT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_correctionKind == _CorrectionKind.unawaited) {
      await _addAwait(builder);
    } else if (_correctionKind == _CorrectionKind.nonBool) {
      await _computeNonBool(builder);
    }
  }

  Future<void> _addAwait(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, 'await ');
    });
  }

  Future<void> _computeNonBool(ChangeBuilder builder) async {
    var expr = node;
    if (expr is! Expression) return;
    var staticType = expr.staticType;
    if (staticType is! ParameterizedType) return;

    if (staticType.isDartAsyncFuture &&
        staticType.typeArguments.firstOrNull?.isDartCoreBool == true) {
      await _addAwait(builder);
    }
  }
}

/// The kinds of corrections supported by [AddAwait].
enum _CorrectionKind {
  unawaited,
  nonBool,
}
