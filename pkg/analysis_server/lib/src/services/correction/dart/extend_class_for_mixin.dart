// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ExtendClassForMixin extends CorrectionProducer {
  String _typeName;

  @override
  List<Object> get fixArguments => [_typeName];

  @override
  FixKind get fixKind => DartFixKind.EXTEND_CLASS_FOR_MIXIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration != null && declaration.extendsClause == null) {
      // TODO(brianwilkerson) Find a way to pass in the name of the class
      //  without needing to parse the message.
      var message = diagnostic.problemMessage.message;
      var endIndex = message.lastIndexOf("'");
      var startIndex = message.lastIndexOf("'", endIndex - 1) + 1;
      _typeName = message.substring(startIndex, endIndex);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(
            declaration.typeParameters?.end ?? declaration.name.end,
            ' extends $_typeName');
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ExtendClassForMixin newInstance() => ExtendClassForMixin();
}
