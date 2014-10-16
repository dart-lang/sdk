// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * When a [Source] (a file) is used in more than one context, [SearchEngine]
 * will return separate [SearchMatch]s for each context. But in rename
 * refactorings we want to update each [Source] only once.
 */
List<SourceReference> getSourceReferences(List<SearchMatch> matches) {
  var uniqueReferences = new HashMap<SourceReference, SourceReference>();
  for (SearchMatch match in matches) {
    Element element = match.element;
    String file = element.source.fullName;
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
 * Abstract implementation of [Refactoring].
 */
abstract class RefactoringImpl implements Refactoring {
  final List<String> potentialEditIds = <String>[];

  @override
  Future<RefactoringStatus> checkAllConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return checkInitialConditions().then((status) {
      result.addStatus(status);
      if (result.hasFatalError) {
        return result;
      }
      return checkFinalConditions().then((status) {
        result.addStatus(status);
        return result;
      });
    });
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

  /**
   * Adds the [SourceEdit] to replace this reference.
   */
  void addEdit(SourceChange change, String newText, {String id}) {
    SourceEdit edit = createEdit(newText, id: id);
    doSourceChange_addElementEdit(change, element, edit);
  }

  /**
   * Returns the [SourceEdit] to replace this reference.
   */
  SourceEdit createEdit(String newText, {String id}) {
    return newSourceEdit_range(range, newText, id: id);
  }

  @override
  String toString() => '${file}@${range}';
}
