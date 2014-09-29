// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of FunctionUpdate by pretty printing the updated element before and
// after.
library trydart.library_updater_test;

import 'dart:convert' show
    UTF8;

import 'package:dart2js_incremental/library_updater.dart' show
    LibraryUpdater,
    Update;

import 'package:compiler/implementation/elements/elements.dart' show
    LibraryElement;

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    PartialFunctionElement;

import 'compiler_test_case.dart';

import 'library_updater_test.dart' show
    LibraryUpdaterTestCase,
    nolog;

class ApplyUpdateTestCase extends LibraryUpdaterTestCase {
  final String expectedUpdate;

  ApplyUpdateTestCase(
      {String before,
      String after,
      String update})
      : this.expectedUpdate = update,
        super(before: before, after: after, canReuse: true);

  Future run() => mainApp.then((LibraryElement library) {
    // Capture the current version of [before] before invoking the [updater].
    PartialFunctionElement before = library.localLookup(expectedUpdate);
    var beforeNode = before.parseNode(compiler);

    LibraryUpdater updater =
        new LibraryUpdater(this.compiler, null, scriptUri, nolog, nolog);
    bool actualCanReuse =
        updater.canReuseLibrary(library, UTF8.encode(newSource));
    Expect.equals(expectedCanReuse, actualCanReuse);

    Update update = updater.updates.single;

    // Check that the [updater] didn't modify the changed element.
    Expect.identical(before, update.before);
    Expect.identical(beforeNode, before.parseNode(compiler));

    PartialFunctionElement after = update.after;
    var afterNode = after.parseNode(compiler);

    // Check that pretty-printing the elements match [source] (before), and
    // [newSource] (after).
    Expect.stringEquals(source, '$beforeNode');
    Expect.stringEquals(newSource, '$afterNode');
    Expect.notEquals(source, newSource);

    // Apply the update.
    update.apply();

    // Check that the update was applied by pretty-printing [before]. Make no
    // assumptions about [after], as the update may destroy that element.
    beforeNode = before.parseNode(compiler);
    Expect.notEquals(source, '$beforeNode');
    Expect.stringEquals(newSource, '$beforeNode');
  });
}

void main() {
  runTests(
      [
          new ApplyUpdateTestCase(
              before: 'main(){print("Hello, World!");}',
              after: 'main(){print("Hello, Brave New World!");}',
              update: 'main'),

          new ApplyUpdateTestCase(
              before: 'main(){foo(){return 1;}return foo();}',
              after: 'main(){bar(){return "1";}return bar();}',
              update: 'main'),

          new ApplyUpdateTestCase(
              before: 'main()=>null;',
              after: 'main(){}',
              update: 'main'),

          new ApplyUpdateTestCase(
              before: 'main(){}',
              after: 'main()=>null;',
              update: 'main'),

          // TODO(ahe): When supporting class members, test abstract methods.
      ]
  );
}
