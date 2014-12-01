// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of [qualifiedNamesIn] and [canNamesResolveStaticallyTo].
library trydart.qualified_names_test;

import 'package:dart2js_incremental/library_updater.dart' show
    canNamesResolveStaticallyTo,
    qualifiedNamesIn;

import 'compiler_test_case.dart';

typedef Checker(LibraryElement script);

class NameTestCase extends CompilerTestCase {
  final Checker check;

  NameTestCase(String source, this.check)
      : super(source);

  Future run() => loadMainApp().then(check);
}

main() {
  runTests(tests.map((l) => new NameTestCase(l.first, l.last)).toList());
}

final List tests = [
    ["main() { x; }",
     (LibraryElement script) {
       var names = qualifiedNamesIn(script.findLocal("main"));
       Expect.setEquals(["main", "x"].toSet(), names);
     }],

    ["main() { x; x.y; }",
     (LibraryElement script) {
       var names = qualifiedNamesIn(script.findLocal("main"));
       Expect.setEquals(["main", "x", "x.y"].toSet(), names);
     }],

    ["main() { x; x.y; x.y.z; x.y.z.w;}",
     (LibraryElement script) {
       var names = qualifiedNamesIn(script.findLocal("main"));
       // ".w" is skipped.
       Expect.setEquals(["main", "x", "x.y", "x.y.z"].toSet(), names);
     }],


    ["x() {} y() {} z() {} w() {} main() { x; x.y; x.y.z; x.y.z.w;}",
     (LibraryElement script) {
       var main = script.findLocal("main");
       var names = qualifiedNamesIn(main);
       var x = script.findLocal("x");
       var y = script.findLocal("y");
       var z = script.findLocal("z");
       var w = script.findLocal("w");
       Expect.isTrue(canNamesResolveStaticallyTo(names, main, script));
       Expect.isTrue(canNamesResolveStaticallyTo(names, x, script));
       Expect.isFalse(canNamesResolveStaticallyTo(names, y, script));
       Expect.isFalse(canNamesResolveStaticallyTo(names, z, script));
       Expect.isFalse(canNamesResolveStaticallyTo(names, w, script));
     }],
];
