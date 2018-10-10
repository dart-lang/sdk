// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:path/path.dart' as pathos;

/**
 * [MoveFileRefactoring] implementation.
 */
class MoveFileRefactoringImpl extends RefactoringImpl
    implements MoveFileRefactoring {
  final ResourceProvider resourceProvider;
  final pathos.Context pathContext;
  final RefactoringWorkspace workspace;
  final Source source;
  AnalysisDriver driver;

  String oldFile;
  String newFile;

  MoveFileRefactoringImpl(ResourceProvider resourceProvider, this.workspace,
      this.source, this.oldFile)
      : resourceProvider = resourceProvider,
        pathContext = resourceProvider.pathContext {
    if (source != null) {
      oldFile = source.fullName;
    }
  }

  @override
  String get refactoringName => 'Move File';

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    final drivers = workspace.driversContaining(oldFile);
    if (drivers.length != 1) {
      if (workspace.drivers
          .any((d) => pathContext.equals(d.contextRoot.root, oldFile))) {
        return new RefactoringStatus.fatal(
            'Renaming an analysis root is not supported ($oldFile)');
      } else {
        return new RefactoringStatus.fatal(
            '$oldFile does not belong to an analysis root.');
      }
    }
    driver = drivers.first;
    if (!driver.resourceProvider.getFile(oldFile).exists) {
      return new RefactoringStatus.fatal('$oldFile does not exist.');
    }
    return new RefactoringStatus();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    return new RefactoringStatus();
  }

  @override
  Future<SourceChange> createChange() async {
    var changeBuilder = new DartChangeBuilder(driver.currentSession);
    final result = await driver.getUnitElement(oldFile);
    final element = result?.element;
    if (element == null) {
      return changeBuilder.sourceChange;
    }
    final library = element.library;

    // If this element is a library, update outgoing references inside the file.
    if (element == library.definingCompilationUnit) {
      await changeBuilder.addFileEdit(library.source.fullName, (builder) {
        final oldDir = pathContext.dirname(oldFile);
        final newDir = pathContext.dirname(newFile);
        _updateUriReferences(builder, library.imports, oldDir, newDir);
        _updateUriReferences(builder, library.exports, oldDir, newDir);
        _updateUriReferences(builder, library.parts, oldDir, newDir);
      });
    } else {
      // Otherwise, we need to update any relative part-of references.
      Iterable<PartOfDirective> partOfs = element.unit.directives
          .whereType<PartOfDirective>()
          .where((po) => po.uri != null && _isRelativeUri(po.uri.stringValue));

      if (partOfs.isNotEmpty) {
        await changeBuilder.addFileEdit(element.source.fullName, (builder) {
          partOfs.forEach((po) {
            final oldDir = pathContext.dirname(oldFile);
            final newDir = pathContext.dirname(newFile);
            String oldLocation = pathContext.join(oldDir, po.uri.stringValue);
            String newUri = _getRelativeUri(oldLocation, newDir);
            builder.addSimpleReplacement(
                new SourceRange(po.uri.offset, po.uri.length), "'$newUri'");
          });
        });
      }
    }

    // Update incoming references to this file
    List<SearchMatch> matches =
        await workspace.searchEngine.searchReferences(element);
    List<SourceReference> references = getSourceReferences(matches);
    for (SourceReference reference in references) {
      await changeBuilder.addFileEdit(reference.file, (builder) {
        String newUri = _computeNewUri(reference);
        builder.addSimpleReplacement(reference.range, "'$newUri'");
      });
    }

    return changeBuilder.sourceChange;
  }

  /**
   * Computes the URI to use to reference [newFile] from [reference].
   */
  String _computeNewUri(SourceReference reference) {
    String refDir = pathContext.dirname(reference.file);
    // try to keep package: URI
    // if (_isPackageReference(reference)) {
    //   Source newSource = new NonExistingSource(
    //       newFile, pathos.toUri(newFile), UriKind.FILE_URI);
    //   Uri restoredUri = context.sourceFactory.restoreUri(newSource);
    //   if (restoredUri != null) {
    //     return restoredUri.toString();
    //   }
    // }
    // if no package: URI, prepare relative
    return _getRelativeUri(newFile, refDir);
  }

  String _getRelativeUri(String path, String from) {
    String uri = pathContext.relative(path, from: from);
    List<String> parts = pathContext.split(uri);
    return pathos.posix.joinAll(parts);
  }

  /**
   * Checks if the given [path] represents a relative URI.
   *
   * The following URI's are not relative:
   *    `/absolute/path/file.dart`
   *    `dart:math`
   */
  bool _isRelativeUri(String path) {
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

  void _updateUriReference(DartFileEditBuilder builder,
      UriReferencedElement element, String oldDir, String newDir) {
    if (!element.isSynthetic) {
      String elementUri = element.uri;
      if (_isRelativeUri(elementUri)) {
        String elementPath = pathContext.join(oldDir, elementUri);
        String newUri = _getRelativeUri(elementPath, newDir);
        int uriOffset = element.uriOffset;
        int uriLength = element.uriEnd - uriOffset;
        builder.addSimpleReplacement(
            new SourceRange(uriOffset, uriLength), "'$newUri'");
      }
    }
  }

  void _updateUriReferences(DartFileEditBuilder builder,
      List<UriReferencedElement> elements, String oldDir, String newDir) {
    for (UriReferencedElement element in elements) {
      _updateUriReference(builder, element, oldDir, newDir);
    }
  }
}
