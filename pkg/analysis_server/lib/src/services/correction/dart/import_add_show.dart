// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ImportAddShow extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.IMPORT_ADD_SHOW;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // there should be no existing combinators
    if (importDirective.combinators.isNotEmpty) {
      return;
    }
    // prepare whole import namespace
    var importElement = importDirective.element;
    if (importElement == null) {
      return;
    }
    var namespace = getImportNamespace(importElement);
    // prepare names of referenced elements (from this import)
    var visitor = _ReferenceFinder(namespace);
    resolvedResult.unit.accept(visitor);
    var referencedNames = visitor.referencedNames;
    // ignore if unused
    if (referencedNames.isEmpty) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      var showCombinator = ' show ${referencedNames.join(', ')}';
      builder.addSimpleInsertion(importDirective.end - 1, showCombinator);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ImportAddShow newInstance() => ImportAddShow();
}

class _ReferenceFinder extends RecursiveAstVisitor<void> {
  final Map<String, Element> namespace;

  Set<String> referencedNames = SplayTreeSet<String>();

  _ReferenceFinder(this.namespace);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element != null &&
        (namespace[node.name] == element ||
            (node.name != element.name &&
                namespace[element.name] == element))) {
      referencedNames.add(element.displayName);
    }
  }
}
