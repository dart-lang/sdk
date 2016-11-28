// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_checker.dart';
import 'dart:io';

final String usage = '''
Usage: typecheck FILE.dill

Runs the strong mode type checker on the given program.
''';

main(List<String> args) {
  if (args.length != 1) {
    print(usage);
    exit(1);
  }
  var program = loadProgramFromBinary(args[0]);
  var coreTypes = new CoreTypes(program);
  var hierarchy = new ClassHierarchy(program);
  new TestTypeChecker(coreTypes, hierarchy).checkProgram(program);
}

class TestTypeChecker extends TypeChecker {
  TestTypeChecker(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy);

  @override
  void checkAssignable(TreeNode where, DartType from, DartType to) {
    if (!environment.isSubtypeOf(from, to)) {
      fail(where, '$from is not a subtype of $to');
    }
  }

  @override
  void fail(TreeNode where, String message) {
    Location location = where.location;
    String locationString = location == null ? '' : '($location)';
    print('[error] $message $locationString');
  }
}
