// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.refactoring.rename_local;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';


/**
 * A [Refactoring] for renaming [LocalElement]s.
 */
class RenameLocalRefactoringImpl extends RenameRefactoringImpl {
  RenameLocalRefactoringImpl(SearchEngine searchEngine, LocalElement element) :
      super(
      searchEngine,
      element);

  @override
  LocalElement get element => super.element as LocalElement;

  @override
  String get refactoringName {
    if (element is ParameterElement) {
      return "Rename Parameter";
    }
    if (element is FunctionElement) {
      return "Rename Local Function";
    }
    return "Rename Local Variable";
  }

  @override
  RefactoringStatus checkFinalConditions() {
    // TODO: implement checkFinalConditions
  }

  // TODO: implement refactoringName
  @override
  Change createChange() {
    // TODO: implement createChange
  }

  @override
  bool requiresPreview() {
    // TODO: implement requiresPreview
  }
}
