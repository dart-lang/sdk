// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/results.dart';
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
    var conflictingElements = element.conflictingElements2;
    var name = element.name3;
    if (name == null || name.isEmpty) {
      return const [];
    }

    var (uris, unit, importDirectives) = _getImportDirectives(
      libraryResult,
      unitResult,
      conflictingElements,
      prefix,
    );

    if (unit == null || importDirectives.isEmpty || uris.isEmpty) {
      return const [];
    }

    var producers = <ResolvedCorrectionProducer>{};
    for (var uri in uris) {
      var thisContext = CorrectionProducerContext.createResolved(
        libraryResult: libraryResult,
        unitResult: unit,
        applyingBulkFixes: applyingBulkFixes,
        dartFixContext: context.dartFixContext,
        diagnostic: diagnostic,
        selectionLength: selectionLength,
        selectionOffset: selectionOffset,
      );
      var directives = importDirectives
          .whereNot((directive) => directive.uri.stringValue == uri)
          .toSet();
      producers.addAll([
        _ImportAddHide(name, uri, prefix, directives, context: thisContext),
        _ImportRemoveShow(name, uri, prefix, directives, context: thisContext),
      ]);
    }
    return producers.toList();
  }

  /// Returns [ImportDirective]s that import the given [conflictingElements]
  /// into [unitResult] and the set of uris (String) that represent each of the
  /// import directives.
  ///
  /// The uris and the import directives are both returned so that we can
  /// run the fix for a certain uri on all of the other import directives.
  ///
  /// The resulting [ResolvedUnitResult?] is the unit that contains the import
  /// directives. Usually this is the unit that contains the conflicting
  /// element, but it could be a parent unit if the conflicting element is
  /// a part file and the relevant imports are in an upstream file in the
  /// library hierarchy (enhanced parts).
  (Set<String>, ResolvedUnitResult?, Set<ImportDirective>) _getImportDirectives(
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult? unitResult,
    List<Element2> conflictingElements,
    String? prefix,
  ) {
    // The uris of all import directives that import the conflicting elements.
    var uris = <String>{};
    // The import directives that import the conflicting elements.
    var importDirectives = <ImportDirective>{};
    // Search in each unit up the chain for related imports.
    while (unitResult is ResolvedUnitResult) {
      for (var conflictingElement in conflictingElements) {
        var library = conflictingElement.enclosingElement2?.library2;
        if (library == null) {
          continue;
        }

        // Find all ImportDirective that import this library in this unit
        // and have the same prefix.
        for (var directive in unitResult.unit.directives
            .whereType<ImportDirective>()
            .whereNot(importDirectives.contains)) {
          var imported = directive.libraryImport?.importedLibrary2;
          if (imported == null) {
            continue;
          }
          // If the prefix is different, then this directive is not relevant.
          if (directive.prefix?.name != prefix) {
            continue;
          }

          // If this library is imported directly or if the directive exports the
          // library for this element.
          if (imported == library ||
              imported.exportedLibraries2.contains(library)) {
            var uri = directive.uri.stringValue;
            if (uri != null) {
              uris.add(uri);
              importDirectives.add(directive);
            }
          }
        }
      }

      if (importDirectives.isNotEmpty) {
        break;
      }

      // We continue up the chain.
      unitResult = libraryResult.parentUnitOf(unitResult);
    }

    return (uris, unitResult, importDirectives);
  }
}

class _ImportAddHide extends ResolvedCorrectionProducer {
  final Set<ImportDirective> importDirectives;
  final String uri;
  final String? prefix;
  final String _elementName;

  _ImportAddHide(
      this._elementName, this.uri, this.prefix, this.importDirectives,
      {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var prefix = '';
    if (!this.prefix.isEmptyOrNull) {
      prefix = ' as ${this.prefix}';
    }
    return [_elementName, uri, prefix];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_HIDE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_elementName.isEmpty || uri.isEmpty) {
      return;
    }

    var hideCombinators =
        <({ImportDirective directive, HideCombinator? hide})>[];

    for (var directive in importDirectives) {
      var show = directive.combinators.whereType<ShowCombinator>().firstOrNull;
      // If there is an import with a show combinator, then we don't want to
      // deal with this case here.
      if (show != null) {
        return;
      }
      var hide = directive.combinators.whereType<HideCombinator>().firstOrNull;
      hideCombinators.add((directive: directive, hide: hide));
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var (:directive, :hide) in hideCombinators) {
        if (hide != null) {
          var allNames = [
            ...hide.hiddenNames.map((name) => name.name),
            _elementName,
          ];
          if (_sortCombinators) {
            allNames.sort();
          }
          // TODO(FMorschel): Use the utility function instead of ', '.
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
  final String _elementName;
  final String uri;
  final String? prefix;

  _ImportRemoveShow(
      this._elementName, this.uri, this.prefix, this.importDirectives,
      {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var prefix = '';
    if (!this.prefix.isEmptyOrNull) {
      prefix = ' as ${this.prefix}';
    }
    return [_elementName, uri, prefix];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_REMOVE_SHOW;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_elementName.isEmpty || uri.isEmpty) {
      return;
    }

    var showCombinators =
        <({ImportDirective directive, ShowCombinator show})>[];
    for (var directive in importDirectives) {
      var show = directive.combinators.whereType<ShowCombinator>().firstOrNull;
      // If there is no show combinator, then we don't want to deal with this
      // case here.
      if (show == null) {
        return;
      }
      showCombinators.add((directive: directive, show: show));
    }

    await builder.addDartFileEdit(file, (builder) {
      for (var (:directive, :show) in showCombinators) {
        var allNames = [
          ...show.shownNames
              .map((name) => name.name)
              .where((name) => name != _elementName),
        ];
        if (_sortCombinators) {
          allNames.sort();
        }
        if (allNames.isEmpty) {
          builder.addDeletion(SourceRange(show.offset - 1, show.length + 1));
          var hideCombinator = ' hide $_elementName';
          builder.addSimpleInsertion(directive.end - 1, hideCombinator);
        } else {
          // TODO(FMorschel): Use the utility function instead of ', '.
          var combinator = 'show ${allNames.join(', ')}';
          var range = SourceRange(show.offset, show.length);
          builder.addSimpleReplacement(range, combinator);
        }
      }
    });
  }
}

extension on ResolvedCorrectionProducer {
  bool get _sortCombinators =>
      getCodeStyleOptions(unitResult.file).combinatorsOrdering;
}
