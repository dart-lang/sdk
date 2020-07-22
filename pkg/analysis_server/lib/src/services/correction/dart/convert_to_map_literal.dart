// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToMapLiteral extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_MAP_LITERAL;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_MAP_LITERAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Ensure that this is the default constructor defined on either `Map` or
    // `LinkedHashMap`.
    //
    var creation = node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (creation == null ||
        node.offset > creation.argumentList.offset ||
        creation.constructorName.name != null ||
        creation.argumentList.arguments.isNotEmpty ||
        !_isMapClass(creation.staticType.element)) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var constructorTypeArguments = creation.constructorName.type.typeArguments;
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(creation), (builder) {
        if (constructorTypeArguments != null) {
          builder.write(utils.getNodeText(constructorTypeArguments));
        }
        builder.write('{}');
      });
    });
  }

  /// Return `true` if the [element] represents either the class `Map` or
  /// `LinkedHashMap`.
  bool _isMapClass(Element element) =>
      element is ClassElement &&
      (element == typeProvider.mapElement ||
          (element.name == 'LinkedHashMap' &&
              element.library.name == 'dart.collection'));

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToMapLiteral newInstance() => ConvertToMapLiteral();
}
