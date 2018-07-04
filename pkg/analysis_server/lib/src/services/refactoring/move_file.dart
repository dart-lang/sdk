// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
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

  String oldFile;
  String newFile;

  SourceChange change;
  LibraryElement library;
  String oldLibraryDir;
  String newLibraryDir;

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
  Future<SourceChange> createChange() async {
    // TODO(dantup): Implement!
    return new SourceChange('Update File References');
  }

  @override
  bool requiresPreview() => false;

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

  void _updateUriReference(UriReferencedElement element) {
    if (!element.isSynthetic) {
      String elementUri = element.uri;
      if (_isRelativeUri(elementUri)) {
        String elementPath = pathContext.join(oldLibraryDir, elementUri);
        String newUri = _getRelativeUri(elementPath, newLibraryDir);
        int uriOffset = element.uriOffset;
        int uriLength = element.uriEnd - uriOffset;
        doSourceChange_addElementEdit(
            change, library, new SourceEdit(uriOffset, uriLength, "'$newUri'"));
      }
    }
  }

  void _updateUriReferences(List<UriReferencedElement> elements) {
    for (UriReferencedElement element in elements) {
      _updateUriReference(element);
    }
  }
}
