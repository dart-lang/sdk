// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RenameToCamelCase extends CorrectionProducer {
  /// The camel-case version of the name.
  String _newName;

  @override
  List<Object> get fixArguments => [_newName];

  @override
  FixKind get fixKind => DartFixKind.RENAME_TO_CAMEL_CASE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier identifier = node;

    // Prepare the new name.
    var words = identifier.name.split('_');
    if (words.length < 2) {
      return;
    }
    _newName = words.first + words.skip(1).map((w) => capitalize(w)).join();

    // Find references to the identifier.
    List<SimpleIdentifier> references;
    var element = identifier.staticElement;
    if (element is LocalVariableElement) {
      AstNode root = node.thisOrAncestorOfType<Block>();
      references = findLocalElementReferences(root, element);
    } else if (element is ParameterElement) {
      if (!element.isNamed) {
        var root = node.thisOrAncestorMatching((node) =>
            node.parent is ClassOrMixinDeclaration ||
            node.parent is CompilationUnit);
        references = findLocalElementReferences(root, element);
      }
    }
    if (references == null) {
      return;
    }

    // Compute the change.
    await builder.addDartFileEdit(file, (builder) {
      for (var reference in references) {
        builder.addSimpleReplacement(range.node(reference), _newName);
      }
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RenameToCamelCase newInstance() => RenameToCamelCase();
}
