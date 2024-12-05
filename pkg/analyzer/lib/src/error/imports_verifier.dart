// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `ImportsVerifier` visit all of the referenced
/// libraries in the source code verifying that all of the imports are used,
/// otherwise a [HintCode.UNUSED_IMPORT] hint is generated with
/// [generateUnusedImportHints].
///
/// Additionally, [generateDuplicateImportWarnings] generates
/// [HintCode.DUPLICATE_IMPORT] hints and [HintCode.UNUSED_SHOWN_NAME] hints.
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
  /// See [ImportsVerifier.generateUnusedImportErrors].
  final Set<ImportDirective> _unusedImports = {};

  /// After the list of [unusedImports] has been computed, this list is a proper
  /// subset of the unused imports that are listed more than once.
  final List<ImportDirective> _duplicateImports = [];

  /// This list is a proper subset of the unused exports that are listed more
  /// than once.
  final List<ExportDirective> _duplicateExports = [];

  /// A map of names that are hidden more than once.
  final Map<NamespaceDirective, List<SimpleIdentifier>>
      _duplicateHiddenNamesMap = {};

  /// A map of names that are shown more than once.
  final Map<NamespaceDirective, List<SimpleIdentifier>>
      _duplicateShownNamesMap = {};

  ImportsVerifier({
    required this.fileAnalysis,
  });

  void addImports(CompilationUnit node) {
    var importsWithLibraries = <_NamespaceDirective>[];
    var exportsWithLibraries = <_NamespaceDirective>[];
    for (var directive in node.directives) {
      if (directive is ImportDirectiveImpl) {
        var libraryElement = directive.element?.importedLibrary;
        if (libraryElement == null) {
          continue;
        }
        if (libraryElement.isSynthetic) {
          continue;
        }
        _allImports.add(directive);
        importsWithLibraries.add(
          _NamespaceDirective(
            node: directive,
            library: libraryElement,
          ),
        );
      } else if (directive is ExportDirective) {
        var libraryElement = directive.element?.exportedLibrary;
        if (libraryElement == null) {
          continue;
        }
        exportsWithLibraries.add(
          _NamespaceDirective(
            node: directive,
            library: libraryElement,
          ),
        );
      }

      if (directive is NamespaceDirective) {
        _addDuplicateShownHiddenNames(directive);
      }
    }
    var importDuplicates = _duplicates(importsWithLibraries);
    for (var duplicate in importDuplicates) {
      _duplicateImports.add(duplicate as ImportDirective);
    }
    var exportDuplicates = _duplicates(exportsWithLibraries);
    for (var duplicate in exportDuplicates) {
      _duplicateExports.add(duplicate as ExportDirective);
    }
  }

  /// Any time after the defining compilation unit has been visited by this
  /// visitor, this method can be called to report an
  /// [WarningCode.DUPLICATE_EXPORT] hint for each of the export
  /// directives in the [_duplicateExports] list.
  void generateDuplicateExportWarnings(ErrorReporter errorReporter) {
    var length = _duplicateExports.length;
    for (var i = 0; i < length; i++) {
      errorReporter.atNode(
        _duplicateExports[i].uri,
        WarningCode.DUPLICATE_EXPORT,
      );
    }
  }

  /// Any time after the defining compilation unit has been visited by this
  /// visitor, this method can be called to report an
  /// [WarningCode.DUPLICATE_IMPORT] hint for each of the import
  /// directives in the [_duplicateImports] list.
  void generateDuplicateImportWarnings(ErrorReporter errorReporter) {
    var length = _duplicateImports.length;
    for (var i = 0; i < length; i++) {
      errorReporter.atNode(
        _duplicateImports[i].uri,
        WarningCode.DUPLICATE_IMPORT,
      );
    }
  }

  /// Report a [WarningCode.DUPLICATE_SHOWN_NAME] and
  /// [WarningCode.DUPLICATE_HIDDEN_NAME] hints for each duplicate shown or
  /// hidden name.
  ///
  /// Only call this method after all of the compilation units have been visited
  /// by this visitor.
  void generateDuplicateShownHiddenNameWarnings(ErrorReporter reporter) {
    _duplicateHiddenNamesMap.forEach(
        (NamespaceDirective directive, List<SimpleIdentifier> identifiers) {
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        reporter.atNode(
          identifier,
          WarningCode.DUPLICATE_HIDDEN_NAME,
        );
      }
    });
    _duplicateShownNamesMap.forEach(
        (NamespaceDirective directive, List<SimpleIdentifier> identifiers) {
      int length = identifiers.length;
      for (int i = 0; i < length; i++) {
        Identifier identifier = identifiers[i];
        reporter.atNode(
          identifier,
          WarningCode.DUPLICATE_SHOWN_NAME,
        );
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
  void generateUnnecessaryImportHints(ErrorReporter errorReporter) {
    var importsTracking = fileAnalysis.importsTracking;
    var usedImports = {..._allImports}..removeAll(_unusedImports);

    for (var firstDirective in usedImports) {
      var firstElement = firstDirective.element!;
      var tracker = importsTracking.trackerOf(firstElement);

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

        var secondElement = secondDirective.element!;

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
          errorReporter.atNode(
            firstDirective.uri,
            HintCode.UNNECESSARY_IMPORT,
            arguments: [
              firstElementUri.relativeUriString,
              secondElementUri.relativeUriString,
            ],
          );
          // Now that we reported on the first, so we are done.
          break;
        }
      }
    }
  }

  /// Report [WarningCode.UNUSED_IMPORT] for each unused import.
  void generateUnusedImportHints(ErrorReporter errorReporter) {
    var importsTracking = fileAnalysis.importsTracking;
    for (var importDirective in fileAnalysis.unit.directives) {
      if (importDirective is ImportDirectiveImpl) {
        var importElement = importDirective.element!;
        var prefixElement = importElement.prefix?.element;
        var tracking = importsTracking.map[prefixElement]!;

        // Ignore the group of imports with a prefix in a comment reference.
        if (tracking.hasPrefixUsedInCommentReference) {
          continue;
        }

        if (importElement.uri case DirectiveUriWithLibraryImpl uri) {
          // Ignore explicit dart:core import.
          if (uri.library.isDartCore) {
            continue;
          }

          // The URI target does not exist, reported this elsewhere.
          if (uri.library.isSynthetic) {
            continue;
          }

          var isUsed = tracking.importToUsedElements.containsKey(importElement);
          if (!isUsed) {
            _unusedImports.add(importDirective);
            errorReporter.atNode(
              importDirective.uri,
              WarningCode.UNUSED_IMPORT,
              arguments: [uri.relativeUriString],
            );
          }
        }
      }
    }
  }

  /// Use the error [reporter] to report an [WarningCode.UNUSED_SHOWN_NAME]
  /// for each unused shown name.
  ///
  /// This method should be invoked after [generateUnusedImportHints].
  void generateUnusedShownNameHints(ErrorReporter reporter) {
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
      var importElement = importDirective.element!;
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
          for (var identifier in combinator.shownNames) {
            var element = identifier.staticElement;
            if (element != null) {
              var importElements = importsTracking.elementsOf(importElement);

              var isUsed = importElements.contains(element);
              if (element is PropertyInducingElement) {
                isUsed = importElements.contains(element.getter) ||
                    importElements.contains(element.setter);
              }

              if (!isUsed) {
                reporter.atNode(
                  identifier,
                  WarningCode.UNUSED_SHOWN_NAME,
                  arguments: [identifier.name],
                );
              }
            }
          }
        }
      }
    }
  }

  /// Add duplicate shown and hidden names from [directive] into
  /// [_duplicateHiddenNamesMap] and [_duplicateShownNamesMap].
  void _addDuplicateShownHiddenNames(NamespaceDirective directive) {
    for (var combinator in directive.combinators) {
      // Use a Set to find duplicates in faster than O(n^2) time.
      var identifiers = <Element>{};
      if (combinator is HideCombinator) {
        for (var name in combinator.hiddenNames) {
          var element = name.staticElement;
          if (element != null) {
            if (!identifiers.add(element)) {
              // [name] is a duplicate.
              List<SimpleIdentifier> duplicateNames =
                  _duplicateHiddenNamesMap.putIfAbsent(directive, () => []);
              duplicateNames.add(name);
            }
          }
        }
      } else if (combinator is ShowCombinator) {
        for (var name in combinator.shownNames) {
          var element = name.staticElement;
          if (element != null) {
            if (!identifiers.add(element)) {
              // [name] is a duplicate.
              List<SimpleIdentifier> duplicateNames =
                  _duplicateShownNamesMap.putIfAbsent(directive, () => []);
              duplicateNames.add(name);
            }
          }
        }
      }
    }
  }

  /// Return the duplicates in [directives].
  List<NamespaceDirective> _duplicates(List<_NamespaceDirective> directives) {
    var duplicates = <NamespaceDirective>[];
    if (directives.length > 1) {
      // order the list of directives to find duplicates in faster than
      // O(n^2) time
      directives.sort((import1, import2) {
        return import1.libraryUriStr.compareTo(import2.libraryUriStr);
      });
      var currentDirective = directives[0];
      for (var i = 1; i < directives.length; i++) {
        var nextDirective = directives[i];
        if (currentDirective.libraryUriStr == nextDirective.libraryUriStr &&
            ImportDirectiveImpl.areSyntacticallyIdenticalExceptUri(
              currentDirective.node,
              nextDirective.node,
            )) {
          // Add either the currentDirective or nextDirective depending on which
          // comes second, this guarantees that the first of the duplicates
          // won't be highlighted.
          if (currentDirective.node.offset < nextDirective.node.offset) {
            duplicates.add(nextDirective.node);
          } else {
            duplicates.add(currentDirective.node);
          }
        }
        currentDirective = nextDirective;
      }
    }
    return duplicates;
  }
}

/// [NamespaceDirective] with non-null imported or exported [LibraryElement].
class _NamespaceDirective {
  final NamespaceDirective node;
  final LibraryElement library;

  _NamespaceDirective({
    required this.node,
    required this.library,
  });

  /// Returns the absolute URI of the library.
  String get libraryUriStr => '${library.source.uri}';
}
