// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library edit.fix;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/json.dart';


class ErrorFixes implements HasToJson {
  final AnalysisError error;
  final List<Change> fixes = <Change>[];

  ErrorFixes(this.error);

  void addFix(Fix fix) {
    Change change = fix.change;
    fixes.add(change);
  }

  @override
  Map<String, Object> toJson() {
    return {
      ERROR: error.toJson(),
      FIXES: objectToJson(fixes)
    };
  }

  @override
  String toString() => 'ErrorFixes(error=$error, fixes=$fixes)';
}
