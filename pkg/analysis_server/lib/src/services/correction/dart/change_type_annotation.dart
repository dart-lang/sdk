// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
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
  Future<void> compute(DartChangeBuilder builder) async {
    var declaration = coveredNode?.parent;
    if (declaration is VariableDeclaration &&
        declaration.initializer == coveredNode) {
      var variableList = declaration.parent;
      if (variableList is VariableDeclarationList &&
          variableList.variables.length == 1) {
        var typeNode = variableList.type;
        if (typeNode != null) {
          Expression initializer = coveredNode;
          var newType = initializer.staticType;
          if (newType is InterfaceType || newType is FunctionType) {
            _oldAnnotation =
                typeNode.type.getDisplayString(withNullability: false);
            _newAnnotation = newType.getDisplayString(withNullability: false);
            await builder.addFileEdit(file, (DartFileEditBuilder builder) {
              builder.addReplacement(range.node(typeNode),
                  (DartEditBuilder builder) {
                builder.writeType(newType);
              });
            });
          }
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ChangeTypeAnnotation newInstance() => ChangeTypeAnnotation();
}
