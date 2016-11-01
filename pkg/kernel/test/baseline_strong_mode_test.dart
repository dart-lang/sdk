// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';
import 'package:kernel/type_checker.dart';
import 'package:path/path.dart' as pathlib;

import 'baseline_tester.dart';

class StrongModeTest extends TestTarget {
  @override
  List<String> get extraRequiredLibraries => [];

  @override
  String get name => 'strong-mode-test';

  @override
  bool get strongMode => true;

  @override
  List<String> transformProgram(Program program) {
    List<String> errors = <String>[];
    new MixinFullResolution().transform(program);
    new TestTypeChecker(
            errors, new CoreTypes(program), new ClassHierarchy(program))
        .checkProgram(program);
    return errors;
  }
}

class TestTypeChecker extends TypeChecker {
  final List<String> errors;

  TestTypeChecker(this.errors, CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy);

  @override
  void checkAssignable(TreeNode where, DartType from, DartType to) {
    if (!environment.isSubtypeOf(from, to)) {
      fail(where, '$from is not a subtype of $to');
    }
  }

  @override
  void fail(TreeNode where, String message) {
    var location = where.location;
    var locationString;
    if (location != null) {
      var file = pathlib.basename(Uri.parse(location.file).path);
      locationString = '($file:${location.line}:${location.column})';
    } else {
      locationString = '(no location)';
    }
    errors.add('$message $locationString');
  }
}

void main() {
  runBaselineTests('strong-mode', new StrongModeTest());
}
