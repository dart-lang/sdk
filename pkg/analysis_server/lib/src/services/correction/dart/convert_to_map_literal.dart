// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToMapLiteral extends ResolvedCorrectionProducer {
  ConvertToMapLiteral({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToMapLiteral;

  @override
  FixKind get fixKind => DartFixKind.convertToMapLiteral;

  @override
  FixKind get multiFixKind => DartFixKind.convertToMapLiteralMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Ensure that this is the default constructor defined on either `Map` or
    // `LinkedHashMap`.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null) {
      return;
    }

    var type = creation.staticType;
    if (node.offset > creation.argumentList.offset ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty ||
        type is! InterfaceType ||
        !_isMapClass(type.element)) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var constructorTypeArguments = creation.constructorName.type.typeArguments;
    List<DartType>? staticTypeArguments;
    if (constructorTypeArguments == null) {
      var variableDeclarationList = creation
          .thisOrAncestorOfType<VariableDeclarationList>();
      if (variableDeclarationList?.type == null) {
        staticTypeArguments = type.typeArguments;
        if (staticTypeArguments.first is DynamicType &&
            staticTypeArguments.last is DynamicType) {
          staticTypeArguments = null;
        }
      }
    }
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(creation), (builder) {
        if (constructorTypeArguments != null) {
          builder.write(utils.getNodeText(constructorTypeArguments));
        } else if (staticTypeArguments?.isNotEmpty ?? false) {
          builder.write('<');
          builder.writeTypes(staticTypeArguments);
          builder.write('>');
        }
        builder.write('{}');
      });
    });
  }

  /// Return `true` if the [element] represents either the class `Map` or
  /// `LinkedHashMap`.
  bool _isMapClass(InterfaceElement element) =>
      element == typeProvider.mapElement ||
      (element.name == 'LinkedHashMap' &&
          element.library.name == 'dart.collection');
}
