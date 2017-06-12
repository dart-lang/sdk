// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as pathos;
import 'package:source_span/src/span.dart';
import 'package:yaml/yaml.dart';

/**
 * [ExtractLocalRefactoring] implementation.
 */
class MoveFileRefactoringImpl extends RefactoringImpl
    implements MoveFileRefactoring {
  final ResourceProvider resourceProvider;
  final pathos.Context pathContext;
  final SearchEngine searchEngine;
  final AnalysisContext context;
  final Source source;

  String oldFile;
  String newFile;

  SourceChange change;
  LibraryElement library;
  String oldLibraryDir;
  String newLibraryDir;

  MoveFileRefactoringImpl(ResourceProvider resourceProvider, this.searchEngine,
      this.context, this.source, this.oldFile)
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
    // move file
    if (source != null) {
      return _createFileChange();
    }
    // rename project
    if (oldFile != null) {
      Resource projectFolder = resourceProvider.getResource(oldFile);
      if (projectFolder is Folder && projectFolder.exists) {
        Resource pubspecFile = projectFolder.getChild('pubspec.yaml');
        if (pubspecFile is File && pubspecFile.exists) {
          return _createProjectChange(projectFolder, pubspecFile);
        }
      }
    }
    // no change
    return null;
  }

  @override
  bool requiresPreview() => false;

  /**
   * Computes the URI to use to reference [newFile] from [reference].
   */
  String _computeNewUri(SourceReference reference) {
    String refDir = pathContext.dirname(reference.file);
    // try to keep package: URI
    if (_isPackageReference(reference)) {
      Source newSource = new NonExistingSource(
          newFile, pathos.toUri(newFile), UriKind.FILE_URI);
      Uri restoredUri = context.sourceFactory.restoreUri(newSource);
      if (restoredUri != null) {
        return restoredUri.toString();
      }
    }
    // if no package: URI, prepare relative
    return _getRelativeUri(newFile, refDir);
  }

  Future<SourceChange> _createFileChange() async {
    change = new SourceChange('Update File References');
    List<Source> librarySources = context.getLibrariesContaining(source);
    await Future.forEach(librarySources, (Source librarySource) async {
      CompilationUnitElement unitElement =
          context.getCompilationUnitElement(source, librarySource);
      if (unitElement != null) {
        // if a defining unit, update outgoing references
        library = unitElement.library;
        if (library.definingCompilationUnit == unitElement) {
          oldLibraryDir = pathContext.dirname(oldFile);
          newLibraryDir = pathContext.dirname(newFile);
          _updateUriReferences(library.imports);
          _updateUriReferences(library.exports);
          _updateUriReferences(library.parts);
        }
        // update reference to the unit
        List<SearchMatch> matches =
            await searchEngine.searchReferences(unitElement);
        List<SourceReference> references = getSourceReferences(matches);
        for (SourceReference reference in references) {
          String newUri = _computeNewUri(reference);
          reference.addEdit(change, "'$newUri'");
        }
      }
    });
    return change;
  }

  Future<SourceChange> _createProjectChange(
      Folder project, File pubspecFile) async {
    change = new SourceChange('Rename project');
    String oldPackageName = pathContext.basename(oldFile);
    String newPackageName = pathContext.basename(newFile);
    // add pubspec.yaml change
    {
      // prepare "name" field value location
      SourceSpan nameSpan;
      {
        String pubspecString = pubspecFile.readAsStringSync();
        YamlMap pubspecNode = loadYamlNode(pubspecString);
        YamlNode nameNode = pubspecNode.nodes['name'];
        nameSpan = nameNode.span;
      }
      int nameOffset = nameSpan.start.offset;
      int nameLength = nameSpan.length;
      // add edit
      change.addEdit(pubspecFile.path, pubspecFile.modificationStamp,
          new SourceEdit(nameOffset, nameLength, newPackageName));
    }
    // check all local libraries
    for (Source librarySource in context.librarySources) {
      // should be a local library
      if (!project.contains(librarySource.fullName)) {
        continue;
      }
      // we need LibraryElement
      LibraryElement library = context.getLibraryElement(librarySource);
      if (library == null) {
        continue;
      }
      // update all imports
      updateUriElements(List<UriReferencedElement> uriElements) {
        for (UriReferencedElement element in uriElements) {
          String uri = element.uri;
          if (uri != null) {
            String oldPrefix = 'package:$oldPackageName/';
            if (uri.startsWith(oldPrefix)) {
              doSourceChange_addElementEdit(
                  change,
                  library,
                  new SourceEdit(element.uriOffset + 1, oldPrefix.length,
                      'package:$newPackageName/'));
            }
          }
        }
      }

      updateUriElements(library.imports);
      updateUriElements(library.exports);
    }
    // done
    return change;
  }

  String _getRelativeUri(String path, String from) {
    String uri = pathContext.relative(path, from: from);
    List<String> parts = pathContext.split(uri);
    return pathos.posix.joinAll(parts);
  }

  bool _isPackageReference(SourceReference reference) {
    Source source = reference.element.source;
    int offset = reference.range.offset + "'".length;
    String content = context.getContents(source).data;
    return content.startsWith('package:', offset);
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
