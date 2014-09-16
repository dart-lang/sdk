// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Returns the [Edit] to replace the given [SearchMatch] reference.
 */
SourceEdit createReferenceEdit(SourceReference reference, String newText,
    {String id}) {
  return new SourceEdit.range(reference.range, newText, id: id);
}


/**
 * Returns the file containing declaration of the given [Element].
 */
String getElementFile(Element element) {
  return element.source.fullName;
}


/**
 * When a [Source] (a file) is used in more than one context, [SearchEngine]
 * will return separate [SearchMatch]s for each context. But in rename
 * refactorings we want to update each [Source] only once.
 */
List<SourceReference> getSourceReferences(List<SearchMatch> matches) {
  var uniqueReferences = new HashMap<SourceReference, SourceReference>();
  for (SearchMatch match in matches) {
    Element element = match.element;
    String file = getElementFile(element);
    SourceRange range = match.sourceRange;
    SourceReference newReference =
        new SourceReference(file, range, element, match.isResolved, match.isQualified);
    SourceReference oldReference = uniqueReferences[newReference];
    if (oldReference == null) {
      uniqueReferences[newReference] = newReference;
      oldReference = newReference;
    }
  }
  return uniqueReferences.keys.toList();
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

  String newName;

  RenameRefactoringImpl(SearchEngine searchEngine, Element element)
      : searchEngine = searchEngine,
        element = element,
        context = element.context,
        elementKindName = element.kind.displayName,
        oldName = _getDisplayName(element);

  /**
   * Adds the "Update declaration" [Edit] to [change].
   */
  void addDeclarationEdit(SourceChange change, Element element) {
    if (element != null) {
      SourceEdit edit =
          new SourceEdit.range(rangeElementName(element), newName);
      addElementSourceChange(change, element, edit);
    }
  }

  /**
   * Adds an "Update reference" [Edit] to [change].
   */
  void addReferenceEdit(SourceChange change, SourceReference reference) {
    SourceEdit edit = createReferenceEdit(reference, newName);
    addElementSourceChange(change, reference.element, edit);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = new RefactoringStatus();
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
  bool requiresPreview() {
    return false;
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
  final String file;
  final SourceRange range;
  final Element element;
  final bool isResolved;
  final bool isQualified;

  SourceReference(this.file, this.range, this.element, this.isResolved,
      this.isQualified);

  @override
  int get hashCode {
    int hash = file.hashCode;
    hash = ((hash << 16) & 0xFFFFFFFF) + range.hashCode;
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is SourceReference) {
      return other.file == file && other.range == range;
    }
    return false;
  }

  @override
  String toString() => '${file}@${range}';
}
