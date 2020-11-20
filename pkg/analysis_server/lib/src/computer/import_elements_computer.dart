// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// An object used to compute a set of edits to add imports to a given library
/// in order to make a given set of elements visible.
///
/// This is used to implement the `edit.importElements` request.
class ImportElementsComputer {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The resolution result associated with the defining compilation unit of the
  /// library to which imports might be added.
  final ResolvedUnitResult libraryResult;

  /// Initialize a newly created builder.
  ImportElementsComputer(this.resourceProvider, this.libraryResult);

  /// Create the edits that will cause the list of [importedElements] to be
  /// imported into the library at the given [path].
  Future<SourceChange> createEdits(
      List<ImportedElements> importedElementsList) async {
    var filteredImportedElements =
        _filterImportedElements(importedElementsList);
    var libraryElement = libraryResult.libraryElement;
    var uriConverter = libraryResult.session.uriConverter;
    var existingImports = <ImportDirective>[];
    for (var directive in libraryResult.unit.directives) {
      if (directive is ImportDirective) {
        existingImports.add(directive);
      }
    }

    var builder = ChangeBuilder(session: libraryResult.session);
    await builder.addDartFileEdit(libraryResult.path, (builder) {
      for (var importedElements in filteredImportedElements) {
        var matchingImports =
            _findMatchingImports(existingImports, importedElements);
        if (matchingImports.isEmpty) {
          //
          // The required library is not being imported with a matching prefix,
          // so we need to add an import.
          //
          var importedFile = resourceProvider.getFile(importedElements.path);
          var uri = uriConverter.pathToUri(importedFile.path);
          var importedSource = importedFile.createSource(uri);
          var importUri = _getLibrarySourceUri(libraryElement, importedSource);
          var description = _getInsertionDescription(importUri);
          builder.addInsertion(description.offset, (builder) {
            for (var i = 0; i < description.newLinesBefore; i++) {
              builder.writeln();
            }
            builder.write("import '");
            builder.write(importUri);
            builder.write("'");
            if (importedElements.prefix.isNotEmpty) {
              builder.write(' as ');
              builder.write(importedElements.prefix);
            }
            builder.write(';');
            for (var i = 0; i < description.newLinesAfter; i++) {
              builder.writeln();
            }
          });
        } else {
          //
          // There are some imports of the library with a matching prefix. We
          // need to determine whether the names are already visible or whether
          // we need to make edits to make them visible.
          //
          // Compute the edits that need to be made.
          //
          var updateMap = <ImportDirective, _ImportUpdate>{};
          for (var requiredName in importedElements.elements) {
            _computeUpdate(updateMap, matchingImports, requiredName);
          }
          //
          // Apply the edits.
          //
          for (var directive in updateMap.keys) {
            var update = updateMap[directive];
            var namesToUnhide = update.namesToUnhide;
            var namesToShow = update.namesToShow;
            namesToShow.sort();
            var combinators = directive.combinators;
            var combinatorCount = combinators.length;
            for (var combinatorIndex = 0;
                combinatorIndex < combinatorCount;
                combinatorIndex++) {
              var combinator = combinators[combinatorIndex];
              if (combinator is HideCombinator && namesToUnhide.isNotEmpty) {
                var hiddenNames = combinator.hiddenNames;
                var nameCount = hiddenNames.length;
                var first = -1;
                for (var nameIndex = 0; nameIndex < nameCount; nameIndex++) {
                  if (namesToUnhide.contains(hiddenNames[nameIndex].name)) {
                    if (first < 0) {
                      first = nameIndex;
                    }
                  } else {
                    if (first >= 0) {
                      // Remove a range of names.
                      builder.addDeletion(range.startStart(
                          hiddenNames[first], hiddenNames[nameIndex]));
                      first = -1;
                    }
                  }
                }
                if (first == 0) {
                  // Remove the whole combinator.
                  if (combinatorIndex == 0) {
                    if (combinatorCount > 1) {
                      builder.addDeletion(range.startStart(
                          combinator, combinators[combinatorIndex + 1]));
                    } else {
                      var precedingNode = directive.prefix ??
                          directive.deferredKeyword ??
                          directive.uri;
                      if (precedingNode == null) {
                        builder.addDeletion(range.node(combinator));
                      } else {
                        builder.addDeletion(
                            range.endEnd(precedingNode, combinator));
                      }
                    }
                  } else {
                    builder.addDeletion(range.endEnd(
                        combinators[combinatorIndex - 1], combinator));
                  }
                } else if (first > 0) {
                  // Remove a range of names that includes the last name.
                  builder.addDeletion(range.endEnd(
                      hiddenNames[first - 1], hiddenNames[nameCount - 1]));
                }
              } else if (combinator is ShowCombinator &&
                  namesToShow.isNotEmpty) {
                // TODO(brianwilkerson) Add the names in alphabetic order.
                builder.addInsertion(combinator.shownNames.last.end, (builder) {
                  for (var nameToShow in namesToShow) {
                    builder.write(', ');
                    builder.write(nameToShow);
                  }
                });
              }
            }
          }
        }
      }
    });
    return builder.sourceChange;
  }

  /// Choose the import for which the least amount of work is required,
  /// preferring to do no work in there is an import that already makes the name
  /// visible, and preferring to remove hide combinators rather than add show
  /// combinators.
  ///
  /// The name is visible without needing any changes if:
  /// - there is an import with no combinators,
  /// - there is an import with only hide combinators and none of them hide the
  ///   name,
  /// - there is an import that shows the name and doesn't subsequently hide the
  ///   name.
  void _computeUpdate(Map<ImportDirective, _ImportUpdate> updateMap,
      List<ImportDirective> matchingImports, String requiredName) {
    /// Return `true` if the [requiredName] is in the given list of [names].
    bool nameIn(NodeList<SimpleIdentifier> names) {
      for (var name in names) {
        if (name.name == requiredName) {
          return true;
        }
      }
      return false;
    }

    ImportDirective preferredDirective;
    var bestEditCount = -1;
    var deleteHide = false;
    var addShow = false;

    for (var directive in matchingImports) {
      var combinators = directive.combinators;
      if (combinators.isEmpty) {
        return;
      }
      var hasHide = false;
      var needsShow = false;
      var editCount = 0;
      for (var combinator in combinators) {
        if (combinator is HideCombinator) {
          if (nameIn(combinator.hiddenNames)) {
            hasHide = true;
            editCount++;
          }
        } else if (combinator is ShowCombinator) {
          if (needsShow || !nameIn(combinator.shownNames)) {
            needsShow = true;
            editCount++;
          }
        }
      }
      if (editCount == 0) {
        return;
      } else if (bestEditCount < 0 || editCount < bestEditCount) {
        preferredDirective = directive;
        bestEditCount = editCount;
        deleteHide = hasHide;
        addShow = needsShow;
      }
    }

    var update = updateMap.putIfAbsent(
        preferredDirective, () => _ImportUpdate(preferredDirective));
    if (deleteHide) {
      update.unhide(requiredName);
    }
    if (addShow) {
      update.show(requiredName);
    }
  }

  /// Filter the given list of imported elements ([originalList]) so that only
  /// the names that are not already defined still remain. Names that are
  /// already defined are removed even if they might not resolve to the same
  /// name as in the original source.
  List<ImportedElements> _filterImportedElements(
      List<ImportedElements> originalList) {
    var filteredList = <ImportedElements>[];
    for (var elements in originalList) {
      var originalElements = elements.elements;
      var filteredElements = originalElements.toList();
      for (var name in originalElements) {
        if (_hasElement(elements.prefix, name)) {
          filteredElements.remove(name);
        }
      }
      if (originalElements.length == filteredElements.length) {
        filteredList.add(elements);
      } else if (filteredElements.isNotEmpty) {
        filteredList.add(
            ImportedElements(elements.path, elements.prefix, filteredElements));
      }
    }
    return filteredList;
  }

  /// Return all of the import elements in the list of [existingImports] that
  /// match the given specification of [importedElements], or an empty list if
  /// there are no such imports.
  List<ImportDirective> _findMatchingImports(
      List<ImportDirective> existingImports,
      ImportedElements importedElements) {
    var matchingImports = <ImportDirective>[];
    for (var existingImport in existingImports) {
      if (_matches(existingImport, importedElements)) {
        matchingImports.add(existingImport);
      }
    }
    return matchingImports;
  }

  /// Return the offset at which an import of the given [importUri] should be
  /// inserted.
  ///
  /// Partially copied from DartFileEditBuilderImpl.
  _InsertionDescription _getInsertionDescription(String importUri) {
    var unit = libraryResult.unit;
    LibraryDirective libraryDirective;
    var importDirectives = <ImportDirective>[];
    var otherDirectives = <Directive>[];
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        libraryDirective = directive;
      } else if (directive is ImportDirective) {
        importDirectives.add(directive);
      } else {
        otherDirectives.add(directive);
      }
    }
    if (importDirectives.isEmpty) {
      if (libraryDirective == null) {
        if (otherDirectives.isEmpty) {
          // TODO(brianwilkerson) Insert after any non-doc comments.
          return _InsertionDescription(0, after: 2);
        }
        return _InsertionDescription(otherDirectives[0].offset, after: 2);
      }
      return _InsertionDescription(libraryDirective.end, before: 2);
    }
    // TODO(brianwilkerson) Fix this to find the right location.
    // See DartFileEditBuilderImpl._addLibraryImports for inspiration.
    return _InsertionDescription(importDirectives.last.end, before: 1);
  }

  /// Computes the best URI to import [what] into [from].
  ///
  /// Copied from DartFileEditBuilderImpl.
  String _getLibrarySourceUri(LibraryElement from, Source what) {
    var whatPath = what.fullName;
    // check if an absolute URI (such as 'dart:' or 'package:')
    var whatUri = what.uri;
    var whatUriScheme = whatUri.scheme;
    if (whatUriScheme != '' && whatUriScheme != 'file') {
      return whatUri.toString();
    }
    // compute a relative URI
    var context = resourceProvider.pathContext;
    var fromFolder = context.dirname(from.source.fullName);
    var relativeFile = context.relative(whatPath, from: fromFolder);
    return context.split(relativeFile).join('/');
  }

  bool _hasElement(String prefix, String name) {
    var scope = libraryResult.libraryElement.scope;

    if (prefix.isNotEmpty) {
      var prefixElement = scope.lookup(prefix).getter;
      if (prefixElement is PrefixElement) {
        scope = prefixElement.scope;
      } else {
        return false;
      }
    }

    var lookupResult = scope.lookup(name);
    return lookupResult.getter != null || lookupResult.setter != null;
  }

  /// Return `true` if the given [import] matches the given specification of
  /// [importedElements]. They will match if they import the same library using
  /// the same prefix.
  bool _matches(ImportDirective import, ImportedElements importedElements) {
    var library = import.element.importedLibrary;
    return library != null &&
        library.source.fullName == importedElements.path &&
        (import.prefix?.name ?? '') == importedElements.prefix;
  }
}

/// Information about how a given import directive needs to be updated in order
/// to make the required names visible.
class _ImportUpdate {
  /// The import directive to be updated.
  final ImportDirective import;

  /// The list of names that are currently hidden that need to not be hidden.
  final List<String> namesToUnhide = <String>[];

  /// The list of names that need to be added to show clauses.
  final List<String> namesToShow = <String>[];

  /// Initialize a newly created information holder to hold information about
  /// updates to the given [import].
  _ImportUpdate(this.import);

  /// Record that the given [name] needs to be added to show combinators.
  void show(String name) {
    namesToShow.add(name);
  }

  /// Record that the given [name] needs to be removed from hide combinators.
  void unhide(String name) {
    namesToUnhide.add(name);
  }
}

class _InsertionDescription {
  final int newLinesBefore;
  final int offset;
  final int newLinesAfter;

  _InsertionDescription(this.offset, {int before = 0, int after = 0})
      : newLinesBefore = before,
        newLinesAfter = after;
}
