// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ImportAddHide extends MultiCorrectionProducer {
  ImportAddHide({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var node = this.node;
    Element? element;
    if (node is NamedType) {
      element = node.element;
    } else if (node is SimpleIdentifier) {
      element = node.staticElement;
    }
    if (element is! MultiplyDefinedElement) {
      return const [];
    }
    var elements = element.conflictingElements;
    var pairs = <ImportDirective, Element>{};
    for (var element in elements) {
      var library = element.enclosingElement3?.library;
      // find all ImportDirective that import this library in this unit
      for (var directive in unit.directives.whereType<ImportDirective>()) {
        var imported = directive.element?.importedLibrary;
        if (imported == null) {
          continue;
        }
        if (imported == library) {
          pairs[directive] = element;
        }
        // If the directive exports the library, then the library is also
        // imported.
        if (imported.exportedLibraries.contains(library)) {
          pairs[directive] = element;
        }
      }
    }
    return [
      for (var MapEntry(key: import, value: element) in pairs.entries)
        _ImportAddHide(import, element, context: context),
    ];
  }
}

class _ImportAddHide extends ResolvedCorrectionProducer {
  _ImportAddHide(this.importDirective, this.element, {required super.context});

  final ImportDirective importDirective;
  final Element element;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_HIDE;

  @override
  List<String> get fixArguments {
    var aliasStr = importDirective.prefix?.name;
    var alias = '';
    if (aliasStr != null) {
      alias = " as '$aliasStr'";
    }
    return [elementName, importStr, alias];
  }

  String get importStr => importDirective.uri.stringValue ?? '';
  String get elementName => element.name ?? '';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (elementName.isEmpty || importStr.isEmpty) {
      return;
    }

    if (importDirective.combinators.whereType<ShowCombinator>().isNotEmpty) {
      return;
    }

    var hide = importDirective.combinators.whereType<HideCombinator>();
    if (hide.isNotEmpty) {
      return await builder.addDartFileEdit(file, (builder) {
        var hideCombinator = hide.first;
        var allNames = <String>[elementName];
        for (var name in hideCombinator.hiddenNames) {
          allNames.add(name.name);
        }
        allNames.sort();
        var combinator = 'hide ${allNames.join(', ')}';
        var range = SourceRange(hideCombinator.offset, hideCombinator.length);
        builder.addSimpleReplacement(range, combinator);
      });
    }

    await builder.addDartFileEdit(file, (builder) {
      var hideCombinator = ' hide $elementName';
      builder.addSimpleInsertion(importDirective.end - 1, hideCombinator);
    });
  }
}
