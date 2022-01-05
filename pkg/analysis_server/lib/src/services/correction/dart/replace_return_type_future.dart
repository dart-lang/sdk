// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ReplaceReturnTypeFuture extends CorrectionProducer {
  /// The text for the type argument to 'Future'.
  String _typeArgument = '';

  @override
  List<Object>? get fixArguments => [_typeArgument];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare the existing type
    var typeAnnotation = node.thisOrAncestorOfType<TypeAnnotation>();
    if (typeAnnotation == null) {
      return;
    }
    _typeArgument = utils.getNodeText(typeAnnotation);

    await builder.addDartFileEdit(file, (builder) {
      builder.replaceTypeWithFuture(typeAnnotation, typeProvider);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceReturnTypeFuture newInstance() => ReplaceReturnTypeFuture();
}
