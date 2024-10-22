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
import 'package:collection/collection.dart';

class ImportAddHide extends MultiCorrectionProducer {
  ImportAddHide({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var node = this.node;
    Element? element;
    String? prefix;
    if (node is NamedType) {
      element = node.element;
      prefix = node.importPrefix?.name.lexeme;
    } else if (node is SimpleIdentifier) {
      element = node.staticElement;
      if (node.parent case PrefixedIdentifier(prefix: var currentPrefix)) {
        prefix = currentPrefix.name;
      }
    }
    if (element is! MultiplyDefinedElement) {
      return const [];
    }
    var elements = element.conflictingElements;
    var records = <({Element element, String uri, String? prefix}),
        List<ImportDirective>>{};
    for (var element in elements) {
      var library = element.enclosingElement3?.library;
      if (library == null) {
        continue;
      }

      var directives = <ImportDirective>[];
      // find all ImportDirective that import this library in this unit
      // and have the same prefix
      for (var directive in unit.directives.whereType<ImportDirective>()) {
        // Get import directive that
        var imported = directive.element?.importedLibrary;
        if (imported == null) {
          continue;
        }
        if (imported == library && directive.prefix?.name == prefix) {
          directives.add(directive);
        }
        // If the directive exports the library, then the library is also
        // imported.
        if (imported.exportedLibraries.contains(library) &&
            directive.prefix?.name == prefix) {
          directives.add(directive);
        }
      }
      for (var directive in directives) {
        var uri = directive.uri.stringValue;
        var prefix = directive.prefix?.name;
        if (uri != null) {
          records[(element: element, uri: uri, prefix: prefix)] = directives;
        }
      }
    }
    if (records.entries.isEmpty) {
      return const [];
    }

    var producers = <ResolvedCorrectionProducer>[];
    for (var MapEntry(key: key) in records.entries) {
      var directives = records.entries
          .whereNot((e) => e.key == key)
          .expand((e) => e.value)
          .whereNot((d) =>
              (d.prefix?.name == key.prefix) && (d.uri.stringValue == key.uri))
          .toSet();
      producers.add(_ImportAddHide(key.element, key.uri, key.prefix, directives,
          context: context));
    }
    return producers;
  }
}

class _ImportAddHide extends ResolvedCorrectionProducer {
  final Set<ImportDirective> importDirectives;
  final Element element;
  final String uri;
  final String? prefix;

  _ImportAddHide(this.element, this.uri, this.prefix, this.importDirectives,
      {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    // Any import directive that imports the element is directly showing it?
    var removeShow = false;
    for (var directives in importDirectives
        .map((d) => d.combinators.whereType<ShowCombinator>())
        .where((d) => d.isNotEmpty)) {
      for (var name in directives.first.shownNames) {
        if (name.name == _elementName) {
          removeShow = true;
          break;
        }
      }
    }
    // If there is a show combinator explicitly showing the element, then
    // we should remove it.
    var removeShowStr = removeShow ? ' (removing \'show\')' : '';
    var prefix = '';
    if ((this.prefix ?? '') != '') {
      prefix = ' as ${this.prefix}';
    }
    return [_elementName, uri, prefix, removeShowStr];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_HIDE;

  String get _elementName => element.name ?? '';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_elementName.isEmpty || uri.isEmpty) {
      return;
    }

    for (var directive in importDirectives) {
      var show = directive.combinators.whereType<ShowCombinator>();
      var hide = directive.combinators.whereType<HideCombinator>();
      await builder.addDartFileEdit(file, (builder) {
        if (show.isNotEmpty) {
          var showCombinator = show.first;
          var allNames = <String>[];
          for (var show in showCombinator.shownNames) {
            if (show.name == _elementName) continue;
            allNames.add(show.name);
          }
          allNames.sort();
          if (allNames.isEmpty) {
            builder.addDeletion(SourceRange(
                showCombinator.offset - 1, showCombinator.length + 1));
          } else {
            var combinator = 'show ${allNames.join(', ')}';
            var range =
                SourceRange(showCombinator.offset, showCombinator.length);
            builder.addSimpleReplacement(range, combinator);
          }
        }
        if (hide.isNotEmpty) {
          var hideCombinator = hide.first;
          var allNames = <String>[_elementName];
          for (var name in hideCombinator.hiddenNames) {
            allNames.add(name.name);
          }
          allNames.sort();
          var combinator = 'hide ${allNames.join(', ')}';
          var range = SourceRange(hideCombinator.offset, hideCombinator.length);
          builder.addSimpleReplacement(range, combinator);
        } else {
          var hideCombinator = ' hide $_elementName';
          builder.addSimpleInsertion(directive.end - 1, hideCombinator);
        }
      });
    }
  }
}
