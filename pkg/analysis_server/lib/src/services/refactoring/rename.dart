// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Returns `true` if two given [Element]s are [LocalElement]s and have
 * intersecting with visibility ranges.
 */
bool haveIntersectingRanges(LocalElement localElement, Element element) {
  if (element is! LocalElement) {
    return false;
  }
  LocalElement localElement2 = element as LocalElement;
  Source localSource = localElement.source;
  Source localSource2 = localElement2.source;
  SourceRange localRange = localElement.visibleRange;
  SourceRange localRange2 = localElement2.visibleRange;
  return localSource2 == localSource &&
      localRange != null &&
      localRange2 != null &&
      localRange2.intersects(localRange);
}


/**
 * Checks if [element] is defined in the library containing [source].
 */
bool isDefinedInLibrary(Element element, AnalysisContext context, Source source)
    {
  // should be the same AnalysisContext
  if (!isInContext(element, context)) {
    return false;
  }
  // private elements are visible only in their library
  List<Source> librarySourcesOfSource = context.getLibrariesContaining(source);
  Source librarySourceOfElement = element.library.source;
  return librarySourcesOfSource.contains(librarySourceOfElement);
}


/**
 * Checks if the given [Element] is in the given [AnalysisContext].
 */
bool isInContext(Element element, AnalysisContext context) {
  return element.context == context;
}


/**
 * Checks if the given unqualified [SearchMatch] intersects with visibility
 * range of [localElement].
 */
bool isReferenceInLocalRange(LocalElement localElement, SearchMatch reference) {
  if (reference.isQualified) {
    return false;
  }
  Source localSource = localElement.source;
  Source referenceSource = reference.element.source;
  SourceRange localRange = localElement.visibleRange;
  SourceRange referenceRange = reference.sourceRange;
  return referenceSource == localSource &&
      referenceRange.intersects(localRange);
}


/**
 * Checks if [element] is visible in the library containing [source].
 */
bool isVisibleInLibrary(Element element, AnalysisContext context, Source source)
    {
  // should be the same AnalysisContext
  if (!isInContext(element, context)) {
    return false;
  }
  // public elements are always visible
  if (element.isPublic) {
    return true;
  }
  // private elements are visible only in their library
  return isDefinedInLibrary(element, context, source);
}



/**
 * An abstract implementation of [RenameRefactoring].
 */
abstract class RenameRefactoringImpl extends RefactoringImpl implements
    RenameRefactoring {
  final SearchEngine searchEngine;
  final Element element;
  final AnalysisContext context;
  final String elementKindName;
  final String oldName;

  SourceChange change;

  String newName;

  RenameRefactoringImpl(SearchEngine searchEngine, Element element)
      : searchEngine = searchEngine,
        element = element,
        context = element.context,
        elementKindName = element.kind.displayName,
        oldName = _getDisplayName(element);

  /**
   * Adds a [SourceEdit] to update [element] name to [change].
   */
  void addDeclarationEdit(Element element) {
    if (element != null) {
      SourceRange range = rangeElementName(element);
      SourceEdit edit = newSourceEdit_range(range, newName);
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  /**
   * Adds [SourceEdit]s to update [matches] to [change].
   */
  void addReferenceEdits(List<SearchMatch> matches) {
    List<SourceReference> references = getSourceReferences(matches);
    for (SourceReference reference in references) {
      reference.addEdit(change, newName);
    }
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = new RefactoringStatus();
    if (newName == oldName) {
      result.addFatalError(
          "The new name must be different than the current name.");
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() {
    change = new SourceChange(refactoringName);
    return fillChange().then((_) => change);
  }

  /**
   * Adds individual edits to [change].
   */
  Future fillChange();

  @override
  bool requiresPreview() {
    return false;
  }

  static String _getDisplayName(Element element) {
    if (element is ImportElement) {
      PrefixElement prefix = element.prefix;
      if (prefix != null) {
        return prefix.displayName;
      }
      return '';
    }
    return element.displayName;
  }
}
