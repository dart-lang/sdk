// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.move_file;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as pathos;


/**
 * [ExtractLocalRefactoring] implementation.
 */
class MoveFileRefactoringImpl extends RefactoringImpl implements
    MoveFileRefactoring {
  final SearchEngine searchEngine;
  final AnalysisContext context;
  final Source source;

  String oldFile;
  String newFile;

  SourceChange change;
  LibraryElement library;
  String oldLibraryDir;
  String newLibraryDir;

  MoveFileRefactoringImpl(this.searchEngine, this.context, this.source) {
    oldFile = source.fullName;
  }

  @override
  String get refactoringName => 'Move File';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  Future<SourceChange> createChange() {
    change = new SourceChange(refactoringName);
    List<Source> librarySources = context.getLibrariesContaining(source);
    return Future.forEach(librarySources, (Source librarySource) {
      CompilationUnitElement unitElement =
          context.getCompilationUnitElement(source, librarySource);
      if (unitElement != null) {
        // update reference to the unit
        searchEngine.searchReferences(unitElement).then((matches) {
          List<SourceReference> references = getSourceReferences(matches);
          for (SourceReference reference in references) {
            String refDir = pathos.dirname(reference.file);
            String newUri = pathos.relative(newFile, from: refDir);
            change.addElementEdit(
                reference.element,
                createReferenceEdit(reference, "'$newUri'"));
          }
        });
        // if a defining unit, update outgoing references
        library = unitElement.library;
        if (library.definingCompilationUnit == unitElement) {
          oldLibraryDir = pathos.dirname(oldFile);
          newLibraryDir = pathos.dirname(newFile);
          // update references to the imported/exported libraries
          _updateUriReferences(library.imports);
          _updateUriReferences(library.exports);
          // update references to the sources units
          for (CompilationUnitElement unit in library.parts) {
            _updateUriReference(unit);
          }
        }
      }
    }).then((_) {
      return change;
    });
  }

  @override
  bool requiresPreview() => false;

  void _updateUriReference(UriReferencedElement element) {
    if (!element.isSynthetic) {
      String elementUri = element.uri;
      if (_isRelativeUri(elementUri)) {
        String elementPath = pathos.join(oldLibraryDir, elementUri);
        String newUri = pathos.relative(elementPath, from: newLibraryDir);
        int uriOffset = element.uriOffset;
        int uriLength = element.uriEnd - uriOffset;
        change.addElementEdit(
            library,
            new SourceEdit(uriOffset, uriLength, "'$newUri'"));
      }
    }
  }

  void _updateUriReferences(List<UriReferencedElement> elements) {
    for (UriReferencedElement element in elements) {
      _updateUriReference(element);
    }
  }

  /**
   * Checks if the given [path] represents a relative URI.
   *
   * The following URI's are not relative:
   *    `/absolute/path/file.dart`
   *    `dart:math`
   */
  static bool _isRelativeUri(String path) {
    // absolute path
    if (pathos.isAbsolute(path)) {
      return false;
    }
    // absolute URI
    if (Uri.parse(path).isAbsolute) {
      return false;
    }
    // OK
    return true;
  }
}
