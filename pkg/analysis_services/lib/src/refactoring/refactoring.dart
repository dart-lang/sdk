// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.refactoring;

import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/refactoring/refactoring.dart';


/**
 * Abstract implementation of {@link Refactoring}.
 */
abstract class RefactoringImpl implements Refactoring {
  @override
  RefactoringStatus checkAllConditions() {
    RefactoringStatus result = new RefactoringStatus();
    result.addStatus(checkInitialConditions());
    if (!result.hasFatalError) {
      result.addStatus(checkFinalConditions());
    }
    return result;
  }
}
