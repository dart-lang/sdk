// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.refactoring.rename;

import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/source_range.dart';
import 'package:analysis_services/src/generated/change.dart';
import 'package:analysis_services/src/refactoring/refactoring.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Returns the [Edit] to replace the given [SearchMatch] reference.
 */
Edit createReferenceEdit(SourceReference reference, String newText) {
  return new Edit.range(reference.range, newText);
}


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
 * Checks if the given [Element] is in the given [AnalysisContext].
 */
bool isInContext(Element element, AnalysisContext context) {
  AnalysisContext elementContext = element.context;
  if (elementContext == context) {
    return true;
  }
  if (context is InstrumentedAnalysisContextImpl) {
    return elementContext == context.basis;
  }
  return false;
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
 * An abstract implementation of [RenameRefactoring].
 */
abstract class RenameRefactoringImpl extends RefactoringImpl implements
    RenameRefactoring {
  final SearchEngine searchEngine;
  final Element element;
  final AnalysisContext context;
  final String oldName;

  String newName;

  RenameRefactoringImpl(SearchEngine searchEngine, Element element)
      : searchEngine = searchEngine,
        element = element,
        context = element.context,
        oldName = _getDisplayName(element);

  /**
   * Adds the "Update declaration" [Edit] to [sourceChange].
   */
  void addDeclarationEdit(SourceChange sourceChange, Element element) {
    Edit edit = new Edit.range(rangeElementName(element), newName);
    sourceChange.addEdit(edit, "Update declaration");
  }

  /**
   * Adds an "Update reference" [Edit] to [sourceChange].
   */
  void addReferenceEdit(SourceChange sourceChange, SourceReference reference) {
    Edit edit = createReferenceEdit(reference, newName);
    sourceChange.addEdit(edit, "Update reference");
  }

  @override
  RefactoringStatus checkInitialConditions() {
    return new RefactoringStatus();
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

  static String _getDisplayName(Element element) {
    if (element is ImportElement) {
      PrefixElement prefix = element.prefix;
      if (prefix != null) {
        return prefix.displayName;
      }
    }
    return element.displayName;
  }
}


/**
 * The [SourceRange] in some [Source].
 */
class SourceReference {
  final MatchKind kind;
  final Source source;
  final SourceRange range;

  SourceReference(this.kind, this.source, this.range);

  @override
  int get hashCode {
    int hash = source.hashCode;
    hash = ((hash << 16) & 0xFFFFFFFF) + range.hashCode;
    return hash;
  }

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    if (obj is! SourceReference) {
      return false;
    }
    SourceReference other = obj as SourceReference;
    return other.source == source && other.range == range;
  }

  @override
  String toString() => '${source}@${range}';
}
