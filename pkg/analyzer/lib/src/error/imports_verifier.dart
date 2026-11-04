// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Instances of the class `ImportsVerifier` visit all of the referenced
/// libraries in the source code verifying that all of the imports are used,
/// otherwise a [diag.unusedImport] hint is generated with
/// [generateUnusedImportWarnings].
///
/// Additionally, [generateDuplicateImportWarnings] generates
/// [diag.duplicateImport] hints and [diag.unusedShownName]
/// warnings.
///
/// While this class does not yet have support for an "Organize Imports" action,
/// this logic built up in this class could be used for such an action in the
/// future.
class ImportsVerifier {
  final FileAnalysis fileAnalysis;

  /// All [ImportDirective]s of the current library.
  final List<ImportDirectiveImpl> _allImports = [];

  /// A list of [ImportDirective]s that the current library imports, but does
  /// not use.
  ///
  /// As identifiers are visited by this visitor and an import has been
  /// identified as being used by the library, the [ImportDirective] is removed
  /// from this list. After all the sources in the library have been evaluated,
  /// this list represents the set of unused imports.
  ///
  /// See [generateUnusedImportWarnings].
  final Set<ImportDirective> _unusedImports = {};

  /// After the list of [_unusedImports] has been computed, this list is a
  /// proper subset of the unused imports that are listed more than once.
  final List<ImportDirective> _duplicateImports = [];

  /// The map of export directives that are duplicates, either of an export
  /// directive within the same compilation unit, or of an export directive
  /// in an ancestor in the part hierarchy, mapped to duplicate export metadata.
  final Map<ExportDirective, _DuplicateExport> _duplicateExports = {};

  /// A map of names that are hidden more than once.
  final Map<NamespaceDirective, List<CombinatorName>> _duplicateHiddenNamesMap =
      {};

  /// A map of names that are shown more than once.
  final Map<NamespaceDirective, List<CombinatorName>> _duplicateShownNamesMap =
      {};

  new({required this.fileAnalysis});

  void addImports(CompilationUnit node) {
    var importsWithLibraries = <_NamespaceDirective>[];
    var exportsWithLibraries = <_NamespaceDirective>[];
    for (var directive in node.directives) {
      if (directive is ImportDirectiveImpl) {
        var libraryElement = directive.libraryImport?.importedLibrary;
        if (libraryElement == null) {
          continue;
        }
        if (libraryElement.isOriginNotExistingFile) {
          continue;
        }
        _allImports.add(directive);
        importsWithLibraries.add(
          _NamespaceDirective(node: directive, library: libraryElement),
        );
      } else if (directive is ExportDirective) {
        var libraryElement = directive.libraryExport?.exportedLibrary;
        if (libraryElement == null) {
          continue;
        }
        exportsWithLibraries.add(
          _NamespaceDirective(node: directive, library: libraryElement),
        );
      }

      if (directive is NamespaceDirective) {
        _addDuplicateShownHiddenNames(directive);
      }
    }
    var importDuplicates = _duplicates(importsWithLibraries);
    for (var duplicate in importDuplicates.keys) {
      _duplicateImports.add(duplicate as ImportDirective);
    }
    var exportDuplicates = _duplicates(exportsWithLibraries);
    for (var entry in exportDuplicates.entries) {
      var duplicate = entry.key as ExportDirective;
      var previous = entry.value as ExportDirective;
      _duplicateExports[duplicate] = _DuplicateExport(
        contextMessage: _contextMessageForExport(
          filePath: fileAnalysis.file.source.fullName,
          exportKeywordOffset: previous.exportKeyword.offset,
        ),
      );
    }

    _addAncestorDuplicateExports(node);
  }

  /// Any time after the defining compilation unit has been visited by this
  /// visitor, this method can be called to report an
  /// [diag.duplicateExport] hint for each of the export
  /// directives in the [_duplicateExports] map.
  void generateDuplicateExportWarnings(DiagnosticReporter diagnosticReporter) {
    for (var MapEntry(key: duplicate, value: duplicateExport)
        in _duplicateExports.entries) {
      var contextMessage = duplicateExport.contextMessage;
      var ancestorFileName = duplicateExport.ancestorFileName;
      var locatable = ancestorFileName != null
          ? diag.duplicateExportInPart.withArguments(fileName: ancestorFileName)
          : diag.duplicateExport;
      if (contextMessage != null) {
        locatable = locatable.withContextMessages([contextMessage]);
      }
      diagnosticReporter.report(locatable.at(duplicate.uri));
    }
  }

  /// Any time after the defining compilation unit has been visited by this
  /// visitor, this method can be called to report an
  /// [diag.duplicateImport] hint for each of the import
  /// directives in the [_duplicateImports] list.
  void generateDuplicateImportWarnings(DiagnosticReporter diagnosticReporter) {
    var length = _duplicateImports.length;
    for (var i = 0; i < length; i++) {
      diagnosticReporter.report(
        diag.duplicateImport.at(_duplicateImports[i].uri),
      );
    }
  }

  /// Report a [diag.duplicateShownName] and
  /// [diag.duplicateHiddenName] hints for each duplicate shown or
  /// hidden name.
  ///
  /// Only call this method after all of the compilation units have been visited
  /// by this visitor.
  void generateDuplicateShownHiddenNameWarnings(DiagnosticReporter reporter) {
    _duplicateHiddenNamesMap.forEach((
      NamespaceDirective directive,
      List<CombinatorName> names,
    ) {
      int length = names.length;
      for (int i = 0; i < length; i++) {
        reporter.report(diag.duplicateHiddenName.at(names[i]));
      }
    });
    _duplicateShownNamesMap.forEach((
      NamespaceDirective directive,
      List<CombinatorName> names,
    ) {
      int length = names.length;
      for (int i = 0; i < length; i++) {
        reporter.report(diag.duplicateShownName.at(names[i]));
      }
    });
  }

  /// Report import directives that are unnecessary.
  ///
  /// In a given library, every import directive has a set of "used elements",
  /// the subset of elements provided by the import which are used in the
  /// library. In a given library, an import directive is "unnecessary" if
  /// there exists at least one other import directive with the same prefix
  /// as the first import directive, and a "used elements" set which is a
  /// proper superset of the first import directive's "used elements" set.
  void generateUnnecessaryImportHints(DiagnosticReporter diagnosticReporter) {
    var importsTracking = fileAnalysis.importsTracking;
    var usedImports = {..._allImports}..removeAll(_unusedImports);

    for (var firstDirective in usedImports) {
      var firstElement = firstDirective.libraryImport!;
      var tracker = importsTracking.trackerOf(firstElement);
      if (tracker == null) {
        continue;
      }

      // Ignore unresolved imports.
      var importedLibrary = firstElement.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Ignore explicit dart:core import.
      if (importedLibrary.isDartCore) {
        continue;
      }

      for (var secondDirective in usedImports) {
        if (secondDirective == firstDirective) {
          continue;
        }

        var secondElement = secondDirective.libraryImport!;

        // Must be the same import prefix, so the same tracker.
        var secondTracker = importsTracking.trackerOf(secondElement);
        if (secondTracker != tracker) {
          continue;
        }

        var firstSet = tracker.elementsOf2(firstElement);
        var secondSet = tracker.elementsOf2(secondElement);

        // The second must provide all elements of the first.
        if (!secondSet.containsAll(firstSet)) {
          continue;
        }

        // The second must provide strictly more than the first.
        if (!(secondSet.length > firstSet.length)) {
          continue;
        }

        var firstElementUri = firstElement.uri;
        var secondElementUri = secondElement.uri;
        if (firstElementUri is DirectiveUriWithLibraryImpl &&
            secondElementUri is DirectiveUriWithLibraryImpl) {
          diagnosticReporter.report(
            diag.unnecessaryImport
                .withArguments(
                  unnecessaryUri: firstElementUri.relativeUriString,
                  reasonUri: secondElementUri.relativeUriString,
                )
                .at(firstDirective.uri),
          );
          // Now that we reported on the first, so we are done.
          break;
        }
      }
    }
  }

  /// Reports [diag.unusedImport] for each unused import.
  void generateUnusedImportWarnings(DiagnosticReporter diagnosticReporter) {
    var importsTracking = fileAnalysis.importsTracking;
    for (var importDirective in fileAnalysis.unit.directives) {
      if (importDirective is ImportDirectiveImpl) {
        var importElement = importDirective.libraryImport!;
        var prefixElement = importElement.prefix?.element;

        var tracking = importsTracking.map[prefixElement];
        if (tracking == null) {
          continue;
        }

        // Ignore the group of imports with a prefix used without a name.
        if (tracking.hasPrefixUsedWithoutName) {
          continue;
        }

        if (importElement.uri case DirectiveUriWithLibraryImpl uri) {
          // Ignore explicit dart:core import.
          if (uri.library.isDartCore) {
            continue;
          }

          // The URI target does not exist, reported this elsewhere.
          if (uri.library.isOriginNotExistingFile) {
            continue;
          }

          var isUsed = tracking.importToUsedElements.containsKey(importElement);
          if (!isUsed) {
            _unusedImports.add(importDirective);
            diagnosticReporter.report(
              diag.unusedImport
                  .withArguments(uriStr: uri.relativeUriString)
                  .at(importDirective.uri),
            );
          }
        }
      }
    }
  }

  /// Use the error [reporter] to report an [diag.unusedShownName]
  /// for each unused shown name.
  ///
  /// This method should be invoked after [generateUnusedImportWarnings].
  void generateUnusedShownNameHints(DiagnosticReporter reporter) {
    var importsTracking = fileAnalysis.importsTracking;
    for (var importDirective in fileAnalysis.unit.directives) {
      if (importDirective is! ImportDirectiveImpl) {
        continue;
      }

      // The whole import is unused, not just one or more shown names from it,
      // so an "unused_import" hint will be generated, making it unnecessary
      // to generate hints for the individual names.
      if (_unusedImports.contains(importDirective)) {
        continue;
      }

      // Ignore unresolved imports.
      var importElement = importDirective.libraryImport!;
      var importedLibrary = importElement.importedLibrary;
      if (importedLibrary == null) {
        continue;
      }

      // Ignore explicit dart:core import.
      if (importedLibrary.isDartCore) {
        continue;
      }

      for (var combinator in importDirective.combinators) {
        if (combinator is ShowCombinatorImpl) {
          for (var name in combinator.names) {
            var element = name.element;
            var setterElement = name.setterElement;
            if (element != null || setterElement != null) {
              var importElements = importsTracking.elementsOf(importElement);

              var isUsed =
                  importElements.contains(element) ||
                  importElements.contains(setterElement);

              if (!isUsed) {
                reporter.report(
                  diag.unusedShownName
                      .withArguments(name: name.name.lexeme)
                      .at(name),
                );
              }
            }
          }
        }
      }
    }
  }

  /// Add duplicate export directives from [node] that match export directives
  /// in ancestor parts in the part hierarchy into [_duplicateExports].
  void _addAncestorDuplicateExports(CompilationUnit node) {
    if (isGeneratedSource(fileAnalysis.file.source)) {
      return;
    }
    var parent = fileAnalysis.fragment.enclosingFragment;
    if (parent == null) {
      return;
    }

    for (var directive in node.directives.whereType<ExportDirective>()) {
      if (directive.configurations.isNotEmpty) {
        continue;
      }
      if (_duplicateExports.containsKey(directive)) {
        continue;
      }
      var currentExport = directive.libraryExport;
      if (currentExport is! LibraryExportImpl) {
        continue;
      }
      var currentLibrary = currentExport.exportedLibrary;
      if (currentLibrary == null) {
        continue;
      }

      var seen = <LibraryFragmentImpl>{};
      for (
        LibraryFragmentImpl? ancestor = parent;
        ancestor != null && seen.add(ancestor);
        ancestor = ancestor.enclosingFragment
      ) {
        var matchingExports = ancestor.libraryExports
            .where((export) => export.exportedLibrary == currentLibrary)
            .toList();

        if (matchingExports.isEmpty) {
          continue;
        }

        if (!isGeneratedSource(ancestor.source)) {
          LibraryExportImpl? matchingExport;
          for (var export in matchingExports) {
            if (ElementDirectiveImpl.areIdenticalExceptUri(
              currentExport,
              export,
            )) {
              matchingExport = export;
              break;
            }
          }
          if (matchingExport != null) {
            _duplicateExports[directive] = _DuplicateExport(
              ancestorFileName: ancestor.source.shortName,
              contextMessage: _contextMessageForExport(
                filePath: ancestor.source.fullName,
                exportKeywordOffset: matchingExport.exportKeywordOffset,
              ),
            );
          }
        }
        break;
      }
    }
  }

  /// Add duplicate shown and hidden names from [directive] into
  /// [_duplicateHiddenNamesMap] and [_duplicateShownNamesMap].
  void _addDuplicateShownHiddenNames(NamespaceDirective directive) {
    for (var combinator in directive.combinators) {
      // Use a Set to find duplicates in faster than O(n^2) time.
      var elements = <(Element?, Element?)>{};
      if (combinator is HideCombinator) {
        for (var name in combinator.names) {
          var pair = (name.element, name.setterElement);
          if (pair != (null, null)) {
            if (!elements.add(pair)) {
              // [name] is a duplicate.
              List<CombinatorName> duplicateNames = _duplicateHiddenNamesMap
                  .putIfAbsent(directive, () => []);
              duplicateNames.add(name);
            }
          }
        }
      } else if (combinator is ShowCombinator) {
        for (var name in combinator.names) {
          var pair = (name.element, name.setterElement);
          if (pair != (null, null)) {
            if (!elements.add(pair)) {
              // [name] is a duplicate.
              List<CombinatorName> duplicateNames = _duplicateShownNamesMap
                  .putIfAbsent(directive, () => []);
              duplicateNames.add(name);
            }
          }
        }
      }
    }
  }

  /// Return the duplicates in [directives], mapped to the directive that they
  /// duplicate.
  Map<NamespaceDirective, NamespaceDirective> _duplicates(
    List<_NamespaceDirective> directives,
  ) {
    var duplicates = <NamespaceDirective, NamespaceDirective>{};
    if (directives.length > 1) {
      // order the list of directives to find duplicates in faster than
      // O(n^2) time
      directives.sort((d1, d2) {
        var compare = d1.libraryUriStr.compareTo(d2.libraryUriStr);
        if (compare != 0) return compare;
        return d1.node.offset.compareTo(d2.node.offset);
      });
      var currentDirective = directives[0];
      for (var i = 1; i < directives.length; i++) {
        var nextDirective = directives[i];
        var currentElementDirective = switch (currentDirective.node) {
          ImportDirective node => node.libraryImport as LibraryImportImpl,
          ExportDirective node => node.libraryExport as LibraryExportImpl,
        };
        var nextElementDirective = switch (nextDirective.node) {
          ImportDirective node => node.libraryImport as LibraryImportImpl,
          ExportDirective node => node.libraryExport as LibraryExportImpl,
        };
        if (currentDirective.libraryUriStr == nextDirective.libraryUriStr &&
            ElementDirectiveImpl.areIdenticalExceptUri(
              currentElementDirective,
              nextElementDirective,
            )) {
          // The nextDirective comes second because directives are sorted by offset.
          duplicates[nextDirective.node] = currentDirective.node;
        }
        currentDirective = nextDirective;
      }
    }
    return duplicates;
  }

  static diag.DiagnosticMessageImpl? _contextMessageForExport({
    required String filePath,
    required int exportKeywordOffset,
  }) {
    if (exportKeywordOffset < 0) {
      return null;
    }
    return diag.DiagnosticMessageImpl(
      filePath: filePath,
      length: 'export'.length,
      message: 'The previous export that is being duplicated.',
      offset: exportKeywordOffset,
      url: null,
    );
  }
}

class _DuplicateExport {
  final diag.DiagnosticMessageImpl? contextMessage;
  final String? ancestorFileName;

  new({this.contextMessage, this.ancestorFileName});
}

/// [NamespaceDirective] with non-null imported or exported [LibraryElement].
class _NamespaceDirective {
  final NamespaceDirective node;
  final LibraryElement library;

  new({required this.node, required this.library});

  /// Returns the absolute URI of the library.
  String get libraryUriStr => '${library.uri}';
}
