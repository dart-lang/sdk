// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveLeadingUnderscore extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_LEADING_UNDERSCORE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var identifier = node;
    if (identifier is! SimpleIdentifier) {
      return;
    }

    var name = identifier.name;
    if (name.length < 2) {
      return;
    }

    var newName = name.substring(1);

    // Find references to the identifier.
    List<SimpleIdentifier>? references;
    var element = identifier.staticElement;
    if (element is LocalVariableElement) {
      var root = node.thisOrAncestorOfType<Block>();
      if (root != null) {
        references = findLocalElementReferences(root, element);
      }
    } else if (element is ParameterElement) {
      if (!element.isNamed) {
        print(node.parent.runtimeType);
        print(node.parent?.parent.runtimeType);
        print(node.parent?.parent?.parent.runtimeType);
        var root = node
            .thisOrAncestorMatching((node) =>
                node.parent is FunctionDeclaration ||
                node.parent is MethodDeclaration)
            ?.parent;
        if (root != null) {
          references = findLocalElementReferences(root, element);
        }
      }
    }
    if (references == null) {
      return;
    }

    // Compute the change.
    var references_final = references;
    await builder.addDartFileEdit(file, (builder) {
      for (var reference in references_final) {
        builder.addSimpleReplacement(range.node(reference), newName);
      }
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveLeadingUnderscore newInstance() => RemoveLeadingUnderscore();
}
