// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of FunctionUpdate by pretty printing the updated element before and
// after.
library trydart.library_updater_test;

import 'package:dart2js_incremental/library_updater.dart' show
    IncrementalCompilerContext,
    LibraryUpdater,
    Update;

import 'package:compiler/src/parser/partial_elements.dart' show
    PartialFunctionElement;

import 'package:compiler/src/script.dart' show
    Script;

import 'package:compiler/src/io/source_file.dart' show
    StringSourceFile;

import 'compiler_test_case.dart';

import 'library_updater_test.dart' show
    LibraryUpdaterTestCase,
    newScriptFrom,
    nolog;

class ApplyUpdateTestCase extends LibraryUpdaterTestCase {
  final String expectedUpdate;

  ApplyUpdateTestCase(
      {String before,
      String after,
      String update})
      : this.expectedUpdate = update,
        super(before: before, after: after, canReuse: true);

  Future run() => loadMainApp().then((LibraryElement library) {
    // Capture the current version of [before] before invoking the [updater].
    PartialFunctionElement before = library.localLookup(expectedUpdate);
    var beforeNode = before.parseNode(compiler.parsing);

    var context = new IncrementalCompilerContext();
    LibraryUpdater updater =
        new LibraryUpdater(this.compiler, null, nolog, nolog, context);
    context.registerUriWithUpdates([scriptUri]);

    bool actualCanReuse =
        updater.canReuseLibrary(
            library, <Script>[newScriptFrom(library, newSource)]);
    Expect.equals(expectedCanReuse, actualCanReuse);

    Update update = updater.updates.single;

    // Check that the [updater] didn't modify the changed element.
    Expect.identical(before, update.before);
    Expect.identical(beforeNode, before.parseNode(compiler.parsing));

    PartialFunctionElement after = update.after;
    var afterNode = after.parseNode(compiler.parsing);

    // Check that pretty-printing the elements match [source] (before), and
    // [newSource] (after).
    Expect.stringEquals(source, '$beforeNode');
    Expect.stringEquals(newSource, '$afterNode');
    Expect.notEquals(source, newSource);

    // Apply the update.
    update.apply();

    // Check that the update was applied by pretty-printing [before]. Make no
    // assumptions about [after], as the update may destroy that element.
    beforeNode = before.parseNode(compiler.parsing);
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
