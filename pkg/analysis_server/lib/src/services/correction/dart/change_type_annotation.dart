// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeTypeAnnotation extends CorrectionProducer {
  String _oldAnnotation = '';

  String _newAnnotation = '';

  @override
  List<Object> get fixArguments => [_oldAnnotation, _newAnnotation];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TYPE_ANNOTATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declaration = coveredNode?.parent;
    if (declaration is! VariableDeclaration) {
      return;
    }

    var initializer = declaration.initializer;
    if (initializer == null || initializer != coveredNode) {
      return;
    }

    var variableList = declaration.parent;
    if (variableList is VariableDeclarationList &&
        variableList.variables.length == 1) {
      var typeNode = variableList.type;
      if (typeNode != null) {
        var newType = initializer.typeOrThrow;
        if (newType is InterfaceType || newType is FunctionType) {
          _oldAnnotation = displayStringForType(typeNode.typeOrThrow);
          _newAnnotation = displayStringForType(newType);
          await builder.addDartFileEdit(file, (builder) {
            if (builder.canWriteType(newType)) {
              builder.addReplacement(range.node(typeNode), (builder) {
                builder.writeType(newType);
              });
            }
          });
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ChangeTypeAnnotation newInstance() => ChangeTypeAnnotation();
}
