// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AmbiguousImportFix extends MultiCorrectionProducer {
  AmbiguousImportFix({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var node = this.node;
    Element2? element;
    String? prefix;
    if (node is NamedType) {
      element = node.element2;
      prefix = node.importPrefix?.name.lexeme;
    } else if (node is SimpleIdentifier) {
      element = node.element;
      if (node.parent case PrefixedIdentifier(prefix: var currentPrefix)) {
        prefix = currentPrefix.name;
      }
    }
    if (element is! MultiplyDefinedElement2) {
      return const [];
    }
    var elements = element.conflictingElements2;
    var records = <({Element2 element, String uri, String? prefix}),
        List<ImportDirective>>{};
    for (var element in elements) {
      var library = element.enclosingElement2?.library2;
      if (library == null) {
        continue;
      }

      var directives = <ImportDirective>[];
      // find all ImportDirective that import this library in this unit
      // and have the same prefix
      for (var directive in unit.directives.whereType<ImportDirective>()) {
        // Get import directive that
        var imported = directive.libraryImport?.importedLibrary2;
        if (imported == null) {
          continue;
        }
        if (imported == library && directive.prefix?.name == prefix) {
          directives.add(directive);
        }
        // If the directive exports the library, then the library is also
        // imported.
        if (imported.exportedLibraries2.contains(library) &&
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
      producers.add(_ImportRemoveShow(
          key.element, key.uri, key.prefix, directives,
          context: context));
    }
    return producers;
  }
}

class _ImportAddHide extends ResolvedCorrectionProducer {
  final Set<ImportDirective> importDirectives;
  final Element2 element;
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
    var prefix = '';
    if ((this.prefix ?? '') != '') {
      prefix = ' as ${this.prefix}';
    }
    return [_elementName, uri, prefix];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_HIDE;

  String get _elementName => element.name3 ?? '';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_elementName.isEmpty || uri.isEmpty) {
      return;
    }

    var hideCombinator =
        <({ImportDirective directive, HideCombinator? hide})>[];

    for (var directive in importDirectives) {
      var show = directive.combinators.whereType<ShowCombinator>().firstOrNull;
      // If there is an import with a show combinator, then we don't want to
      // deal with this case here.
      if (show != null) {
        return;
      }
      var hide = directive.combinators.whereType<HideCombinator>().firstOrNull;
      hideCombinator.add((directive: directive, hide: hide));
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var (:directive, :hide) in hideCombinator) {
        if (hide != null) {
          var allNames = <String>[_elementName];
          for (var name in hide.hiddenNames) {
            allNames.add(name.name);
          }
          allNames.sort();
          var combinator = 'hide ${allNames.join(', ')}';
          var range = SourceRange(hide.offset, hide.length);
          builder.addSimpleReplacement(range, combinator);
        } else {
          var hideCombinator = ' hide $_elementName';
          builder.addSimpleInsertion(directive.end - 1, hideCombinator);
        }
      }
    });
  }
}

class _ImportRemoveShow extends ResolvedCorrectionProducer {
  final Set<ImportDirective> importDirectives;
  final Element2 element;
  final String uri;
  final String? prefix;

  _ImportRemoveShow(this.element, this.uri, this.prefix, this.importDirectives,
      {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var prefix = '';
    if ((this.prefix ?? '') != '') {
      prefix = ' as ${this.prefix}';
    }
    return [_elementName, uri, prefix];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_REMOVE_SHOW;

  String get _elementName => element.name3 ?? '';

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_elementName.isEmpty || uri.isEmpty) {
      return;
    }

    var showCombinator = <({ImportDirective directive, ShowCombinator show})>[];
    for (var directive in importDirectives) {
      var show = directive.combinators.whereType<ShowCombinator>().firstOrNull;
      // If there is no show combinator, then we don't want to deal with this
      // case here.
      if (show == null) {
        return;
      }
      showCombinator.add((directive: directive, show: show));
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var (:directive, :show) in showCombinator) {
        var allNames = <String>[];
        for (var show in show.shownNames) {
          if (show.name == _elementName) continue;
          allNames.add(show.name);
        }
        allNames.sort();
        if (allNames.isEmpty) {
          builder.addDeletion(SourceRange(show.offset - 1, show.length + 1));
          var hideCombinator = ' hide $_elementName';
          builder.addSimpleInsertion(directive.end - 1, hideCombinator);
        } else {
          var combinator = 'show ${allNames.join(', ')}';
          var range = SourceRange(show.offset, show.length);
          builder.addSimpleReplacement(range, combinator);
        }
      }
    });
  }
}
