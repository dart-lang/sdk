// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_import;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A [Refactoring] for renaming [ImportElement]s.
 */
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  RenameImportRefactoringImpl(SearchEngine searchEngine, ImportElement element)
      : super(searchEngine, element);

  @override
  ImportElement get element => super.element as ImportElement;

  @override
  String get refactoringName {
    return "Rename Import Prefix";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateImportPrefixName(newName));
    return result;
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    // update declaration
    {
      String file = getElementFile(element);
      PrefixElement prefix = element.prefix;
      SourceEdit edit = null;
      if (newName.isEmpty) {
        int uriEnd = element.uriEnd;
        int prefixEnd = element.prefixOffset + prefix.displayName.length;
        SourceRange range = rangeStartEnd(uriEnd, prefixEnd);
        edit = editFromRange(range, "");
      } else {
        if (prefix == null) {
          SourceRange range = rangeStartLength(element.uriEnd, 0);
          edit = editFromRange(range, " as ${newName}");
        } else {
          int offset = element.prefixOffset;
          int length = prefix.displayName.length;
          SourceRange range = rangeStartLength(offset, length);
          edit = editFromRange(range, newName);
        }
      }
      if (edit != null) {
        change.addEdit(file, edit);
      }
    }
    // update references
    return searchEngine.searchReferences(element).then((refMatches) {
      List<SourceReference> references = getSourceReferences(refMatches);
      for (SourceReference reference in references) {
        SourceEdit edit;
        if (newName.isEmpty) {
          edit = createReferenceEdit(reference, newName);
        } else {
          edit = createReferenceEdit(reference, "${newName}.");
        }
        change.addEdit(reference.file, edit);
      }
      return change;
    });
  }
}
