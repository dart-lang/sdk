// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring;

import 'dart:async';

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';


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
