// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/quote.dart'
    show analyzeQuote, firstQuoteLength, lastQuoteLength;
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path show posix, Context;

typedef _FileReference = ({
  SourceRange range,
  String sourceFile,
  String targetFile,
  String quotedUriValue,
});

/// [MoveFileRefactoring] implementation.
class MoveFileRefactoringImpl extends RefactoringImpl
    implements MoveFileRefactoring {
  final ResourceProvider resourceProvider;
  final path.Context pathContext;
  final RefactoringWorkspace refactoringWorkspace;
  late AnalysisDriver driver;
  late AnalysisSession _session;

  /// A mapping of files or folders to be renamed.
  final Map<String, String?> _renameMapping;

  MoveFileRefactoringImpl(
      this.resourceProvider, this.refactoringWorkspace, String oldFile)
      : pathContext = resourceProvider.pathContext,
        _renameMapping = {oldFile: null};

  MoveFileRefactoringImpl.multi(
      this.resourceProvider, this.refactoringWorkspace, this._renameMapping)
      : pathContext = resourceProvider.pathContext;

  @override
  set newFile(String value) {
    if (_renameMapping.length != 1) {
      throw StateError('Cannot set newFile unless mapping has only a '
          'single item (actual: ${_renameMapping.length})');
    }
    _renameMapping[_renameMapping.keys.single] = value;
  }

  @override
  String get refactoringName => 'Move File';

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var oldFiles = _renameMapping.keys.toSet();
    var sessions = <AnalysisSession>{};
    for (var oldFile in oldFiles) {
      for (var driver in refactoringWorkspace.drivers) {
        var rootPath = driver.analysisContext!.contextRoot.root.path;
        if (pathContext.equals(rootPath, oldFile)) {
          return RefactoringStatus.fatal(
              'Renaming an analysis root is not supported ($oldFile)');
        }
      }

      final drivers = refactoringWorkspace.driversContaining(oldFile);
      if (drivers.length != 1) {
        return RefactoringStatus.fatal(
            '$oldFile does not belong to an analysis root.');
      }

      driver = drivers.first;
      await driver.applyPendingFileChanges();
      sessions.add(driver.currentSession);
      if (!resourceProvider.getResource(oldFile).exists) {
        return RefactoringStatus.fatal('$oldFile does not exist.');
      }
    }

    if (sessions.length != 1) {
      return RefactoringStatus.fatal(
          'Cannot move files from multiple analysis sessions');
    }
    _session = sessions.elementAt(0);

    return RefactoringStatus();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    return RefactoringStatus();
  }

  @override
  Future<SourceChange> createChange() async {
    var changeBuilder = ChangeBuilder(session: _session);
    var referencesToUpdate = <_FileReference>{};

    // First, resolve any folders to their child files in the mapping so
    // we have a complete flat list, and a way to quickly map target files to
    // their new paths when rewriting imports.
    var resolvedMapping = <String, String>{};
    for (final MapEntry(key: oldPath, value: newPath)
        in _renameMapping.entries) {
      if (newPath == null) {
        throw StateError('Rename mapping contains oldPath without newPath');
      }
      final resource = resourceProvider.getResource(oldPath);
      _resolveMapping(resolvedMapping, resource, newPath);
    }

    try {
      // Next, collect all source references that might need updating.
      for (final MapEntry(key: oldPath, value: newPath)
          in resolvedMapping.entries) {
        await _collectSourceReferences(referencesToUpdate, oldPath, newPath);

        if (isCancellationRequested) {
          return SourceChange('Refactor cancelled');
        }
      }

      // Group references by the files, so we can make edits to each file in a
      // single change builder.
      Map<String, Set<_FileReference>> referencesByFile = {};
      for (final reference in referencesToUpdate) {
        referencesByFile
            .putIfAbsent(reference.sourceFile, () => {})
            .add(reference);
      }

      // For each file, produce edits to update any URIs that are different when
      // taking into account that both files might have been moved.
      for (final MapEntry(key: sourceFile, value: references)
          in referencesByFile.entries) {
        if (references.isEmpty) continue;
        await changeBuilder.addDartFileEdit(sourceFile, (builder) {
          for (final reference in references) {
            final targetFile = reference.targetFile;
            final newSource = resolvedMapping[sourceFile] ?? sourceFile;
            final newTarget = resolvedMapping[targetFile] ?? targetFile;

            final (:startQuote, :endQuote, unquotedValue: uriValue) =
                _extractQuotes(reference.quotedUriValue);

            var newUri = _computeNewUri(
              sourceFile: newSource,
              targetFile: newTarget,
              currentUriValue: uriValue,
            );
            if (newUri != uriValue) {
              builder.addSimpleReplacement(
                  reference.range, '$startQuote$newUri$endQuote');
            }
          }
        });
      }
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user
      // modified the source and is no longer interested in the results.
      return SourceChange('Refactor cancelled by file modifications');
    }

    return changeBuilder.sourceChange;
  }

  /// Collects all source references that may need changing because of a move
  /// from [oldPath] to [newPath].
  Future<void> _collectSourceReferences(
    Set<_FileReference> referencesToUpdate,
    String oldPath,
    String newPath,
  ) async {
    var oldDir = pathContext.dirname(oldPath);
    var newDir = pathContext.dirname(newPath);

    var resolvedUnit = await _session.getResolvedUnit(oldPath);
    if (resolvedUnit is! ResolvedUnitResult) {
      return;
    }

    var element = resolvedUnit.unit.declaredElement;
    if (element == null) {
      return;
    }

    /// A helper to record a reference that may need updating.
    void recordReference({
      required SourceRange range,
      required String sourceFile,
      required String targetFile,
      required String quotedUriValue,
    }) {
      referencesToUpdate.add((
        range: range,
        sourceFile: sourceFile,
        targetFile: targetFile,
        quotedUriValue: quotedUriValue,
      ));
    }

    var libraryElement = element.library;

    // If this element is a library, handle inbound 'part of' directives which
    // are not included in `searchEngine.searchReferences` below.
    if (element == libraryElement.definingCompilationUnit) {
      var libraryResult =
          await _session.getResolvedLibraryByElement(libraryElement);
      if (libraryResult is! ResolvedLibraryResult) {
        return;
      }

      for (var result in libraryResult.units) {
        if (result.isPart) {
          var partOfs = result.unit.directives
              .whereType<PartOfDirective>()
              .map(_getDirectiveUri)
              .whereNotNull()
              .where((uri) => _isRelativeUri(uri.stringValue));
          if (partOfs.isNotEmpty) {
            for (var uriString in partOfs) {
              recordReference(
                range: range.node(uriString),
                sourceFile: result.unit.declaredElement!.source.fullName,
                targetFile: oldPath,
                quotedUriValue: uriString.literal.lexeme,
              );
            }
          }
        }
      }
    }

    // If this rename changes the folder the file is in (not just the name)
    // then outbound relative directives may also need updating.
    if (newDir != oldDir) {
      var partOfs = resolvedUnit.unit.directives
          .map(_getDirectiveUri)
          .whereNotNull()
          .where((uri) => _isRelativeUri(uri.stringValue));

      if (partOfs.isNotEmpty) {
        for (var uriString in partOfs) {
          var uriValue = uriString.stringValue;
          if (uriValue == null) continue;
          recordReference(
            range: range.node(uriString),
            sourceFile: element.source.fullName,
            targetFile: pathContext
                .normalize(pathContext.join(oldDir, _uriToPath(uriValue))),
            quotedUriValue: uriString.literal.lexeme,
          );
        }
      }
    }

    // Finally, locate all other incoming references to this file.
    var matches =
        await refactoringWorkspace.searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      recordReference(
        range: reference.range,
        sourceFile: reference.file,
        targetFile: oldPath,
        quotedUriValue: _extractUriString(reference),
      );
    }
  }

  /// Computes the URI to use to reference [targetFile] from [sourceFile].
  ///
  /// If [currentUriValue] is a 'package:' URI, will try to return another
  /// 'package:' URI, otherwise will be a relative URI.
  String _computeNewUri({
    required String sourceFile,
    required String targetFile,
    required String? currentUriValue,
  }) {
    // Try to keep package: URI
    if (currentUriValue?.startsWith('package:') ?? false) {
      var restoredUri = driver.sourceFactory.pathToUri(targetFile);
      // If the new URI is not a package: URI, fall back to computing a relative
      // URI below.
      if (restoredUri?.isScheme('package') ?? false) {
        return restoredUri.toString();
      }
    }

    // Otherwise, compute a relative URI.
    var uri =
        pathContext.relative(targetFile, from: pathContext.dirname(sourceFile));
    var parts = pathContext.split(uri);
    return path.posix.joinAll(parts);
  }

  ({String startQuote, String endQuote, String unquotedValue}) _extractQuotes(
      String quotedValue) {
    final quote = analyzeQuote(quotedValue);

    final startIndex = firstQuoteLength(quotedValue, quote);
    final endIndex = quotedValue.length - lastQuoteLength(quote);

    final startQuote = quotedValue.substring(0, startIndex);
    final endQuote = quotedValue.substring(endIndex);
    final unquotedValue = quotedValue.substring(startIndex, endIndex);

    return (
      startQuote: startQuote,
      endQuote: endQuote,
      unquotedValue: unquotedValue,
    );
  }

  /// Extracts the existing URI string from a [SourceReference].
  String _extractUriString(SourceReference reference) {
    var source = reference.element.source!;
    return source.contents.data
        .substring(reference.range.offset, reference.range.end);
  }

  /// Gets the string for the URI in a directive, or `null` if it's not a
  /// directive with a URI.
  SimpleStringLiteral? _getDirectiveUri(Directive directive) {
    final uri = directive is PartOfDirective
        ? directive.uri
        : directive is UriBasedDirective
            ? directive.uri
            : null;

    // We only handle simple string literals.
    return uri is SimpleStringLiteral ? uri : null;
  }

  /// Checks if the given [filePath] represents a relative URI.
  ///
  /// The following URI's are not relative:
  ///    `/absolute/path/file.dart`
  ///    `dart:math`
  bool _isRelativeUri(String? filePath) {
    if (filePath == null) {
      return false;
    }
    // absolute URI
    if (Uri.parse(filePath).isAbsolute) {
      return false;
    }
    // absolute path
    if (pathContext.isAbsolute(filePath)) {
      return false;
    }
    // OK
    return true;
  }

  /// Populates [resolvedMapping] with a mapping of file paths that will be
  /// renamed (resolving folders to their child files recursively).
  void _resolveMapping(
    Map<String, String> resolvedMapping,
    Resource resource,
    String newPath,
  ) {
    if (resource is File) {
      resolvedMapping[resource.path] = newPath;
    } else if (resource is Folder) {
      for (final child in resource.getChildren()) {
        _resolveMapping(
          resolvedMapping,
          child,
          pathContext.join(newPath, pathContext.basename(child.path)),
        );
      }
    }
  }

  /// Converts a relative URI string to a relative path.
  ///
  /// On Windows, relative URIs may have '/' but the file paths must use '\'.
  String _uriToPath(String relativeUri) {
    return pathContext.joinAll(path.posix.split(relativeUri));
  }
}
