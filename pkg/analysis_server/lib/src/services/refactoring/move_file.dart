// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as pathos;

/// [MoveFileRefactoring] implementation.
class MoveFileRefactoringImpl extends RefactoringImpl
    implements MoveFileRefactoring {
  final ResourceProvider resourceProvider;
  final pathos.Context pathContext;
  final RefactoringWorkspace refactoringWorkspace;
  final ResolvedUnitResult resolvedUnit;
  late AnalysisDriver driver;

  late String oldFile;
  late String newFile;

  final packagePrefixedStringPattern = RegExp(r'''^r?['"]+package:''');

  MoveFileRefactoringImpl(this.resourceProvider, this.refactoringWorkspace,
      this.resolvedUnit, this.oldFile)
      : pathContext = resourceProvider.pathContext;

  @override
  String get refactoringName => 'Move File';

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
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
    if (!driver.resourceProvider.getFile(oldFile).exists) {
      return RefactoringStatus.fatal('$oldFile does not exist.');
    }

    return RefactoringStatus();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    return RefactoringStatus();
  }

  @override
  Future<SourceChange> createChange() async {
    var changeBuilder = ChangeBuilder(session: resolvedUnit.session);
    var element = resolvedUnit.unit.declaredElement;
    if (element == null) {
      return changeBuilder.sourceChange;
    }

    var libraryElement = element.library;

    final oldDir = pathContext.dirname(oldFile);
    final newDir = pathContext.dirname(newFile);

    // If this element is a library, update outgoing references inside the file.
    if (element == libraryElement.definingCompilationUnit) {
      // Handle part-of directives in this library
      var libraryResult = await driver.currentSession
          .getResolvedLibraryByElement(libraryElement);
      if (libraryResult is! ResolvedLibraryResult) {
        return changeBuilder.sourceChange;
      }
      var definingUnitResult = libraryResult.units.first;
      for (var result in libraryResult.units) {
        if (result.isPart) {
          var partOfs = result.unit.directives
              .whereType<PartOfDirective>()
              .map((e) => e.uri)
              .whereNotNull()
              .where((uri) => _isRelativeUri(uri.stringValue));
          if (partOfs.isNotEmpty) {
            await changeBuilder.addDartFileEdit(
                result.unit.declaredElement!.source.fullName, (builder) {
              partOfs.forEach((uri) {
                var newLocation =
                    pathContext.join(newDir, pathos.basename(newFile));
                var newUri = _getRelativeUri(newLocation, oldDir);
                builder.addSimpleReplacement(
                    SourceRange(uri.offset, uri.length), "'$newUri'");
              });
            });
          }
        }
      }

      if (newDir != oldDir) {
        await changeBuilder.addDartFileEdit(definingUnitResult.path, (builder) {
          for (var directive in definingUnitResult.unit.directives) {
            if (directive is UriBasedDirective) {
              _updateUriReference(builder, directive, oldDir, newDir);
            }
          }
        });
      }
    } else if (newDir != oldDir) {
      // Otherwise, we need to update any relative part-of references.
      var partOfs = resolvedUnit.unit.directives
          .whereType<PartOfDirective>()
          .map((e) => e.uri)
          .whereNotNull()
          .where((uri) => _isRelativeUri(uri.stringValue));

      if (partOfs.isNotEmpty) {
        await changeBuilder.addDartFileEdit(element.source.fullName, (builder) {
          partOfs.forEach((uri) {
            var oldLocation = pathContext.join(oldDir, uri.stringValue);
            var newUri = _getRelativeUri(oldLocation, newDir);
            builder.addSimpleReplacement(
                SourceRange(uri.offset, uri.length), "'$newUri'");
          });
        });
      }
    }

    // Update incoming references to this file
    var matches =
        await refactoringWorkspace.searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      await changeBuilder.addDartFileEdit(reference.file, (builder) {
        var newUri = _computeNewUri(reference);
        builder.addSimpleReplacement(reference.range, "'$newUri'");
      });
    }

    return changeBuilder.sourceChange;
  }

  /// Computes the URI to use to reference [newFile] from [reference].
  String _computeNewUri(SourceReference reference) {
    var refDir = pathContext.dirname(reference.file);
    // Try to keep package: URI
    if (_isPackageReference(reference)) {
      var restoredUri = driver.sourceFactory.pathToUri(newFile);
      // If the new URI is not a package: URI, fall back to computing a relative
      // URI below.
      if (restoredUri?.isScheme('package') ?? false) {
        return restoredUri.toString();
      }
    }
    return _getRelativeUri(newFile, refDir);
  }

  String _getRelativeUri(String path, String from) {
    var uri = pathContext.relative(path, from: from);
    var parts = pathContext.split(uri);
    return pathos.posix.joinAll(parts);
  }

  bool _isPackageReference(SourceReference reference) {
    var source = reference.element.source!;
    var quotedImportUri = source.contents.data.substring(reference.range.offset,
        reference.range.offset + reference.range.length);
    return packagePrefixedStringPattern.hasMatch(quotedImportUri);
  }

  /// Checks if the given [path] represents a relative URI.
  ///
  /// The following URI's are not relative:
  ///    `/absolute/path/file.dart`
  ///    `dart:math`
  bool _isRelativeUri(String? path) {
    if (path == null) {
      return false;
    }
    // absolute URI
    if (Uri.parse(path).isAbsolute) {
      return false;
    }
    // absolute path
    if (pathContext.isAbsolute(path)) {
      return false;
    }
    // OK
    return true;
  }

  void _updateUriReference(FileEditBuilder builder, UriBasedDirective directive,
      String oldDir, String newDir) {
    var uriNode = directive.uri;
    var uriValue = uriNode.stringValue;
    if (_isRelativeUri(uriValue)) {
      var elementPath = pathContext.join(oldDir, uriValue);
      var newUri = _getRelativeUri(elementPath, newDir);
      builder.addSimpleReplacement(range.node(uriNode), "'$newUri'");
    }
  }
}
