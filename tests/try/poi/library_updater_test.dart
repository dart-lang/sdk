// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of LibraryUpdater.
library trydart.library_updater_test;

import 'dart:convert' show
    UTF8;

import 'package:dart2js_incremental/library_updater.dart' show
    LibraryUpdater,
    Update;

import 'compiler_test_case.dart';

void nolog(_) {}

class LibraryUpdaterTestCase extends CompilerTestCase {
  final String newSource;

  final bool expectedCanReuse;

  final List<String> expectedUpdates;

  LibraryUpdaterTestCase(
      {String before,
       String after,
       bool canReuse,
       List<String> updates})
      : this.newSource = after,
        this.expectedCanReuse = canReuse,
        this.expectedUpdates = updates,
        super(before);

  Future run() => mainApp.then((LibraryElement library) {
    LibraryUpdater updater =
        new LibraryUpdater(this.compiler, null, scriptUri, nolog, nolog);
    bool actualCanReuse =
        updater.canReuseLibrary(library, UTF8.encode(newSource));
    Expect.equals(expectedCanReuse, actualCanReuse);

    Expect.setEquals(
        expectedUpdates.toSet(),
        updater.updates.map((Update update) => update.before.name).toSet());
  });

  String toString() => 'Before:\n$source\n\n\nAfter:\n$newSource';
}

void main() {
  runTests(
      [
          // Only method body changed. Can be reused if 'main' is
          // updated/patched.
          new LibraryUpdaterTestCase(
              before: 'main() { print("Hello, World!"); }',
              after: 'main() { print("Hello, Brave New World!"); }',
              canReuse: true,
              updates: ['main']),

          // Signature changed. Can't be reused.
          new LibraryUpdaterTestCase(
              before: 'main() { print("Hello, World!"); }',
              after: 'void main() { print("Hello, World!"); }',
              canReuse: false,
              updates: []),

          // Only whitespace changes. Can be reused; no updates/patches needed.
          new LibraryUpdaterTestCase(
              before: 'main(){print("Hello, World!");}',
              after: 'main() { print ( "Hello, World!" ) ; }',
              canReuse: true,
              updates: []),

          // Only whitespace/comment changes (in signature). Can be reused; no
          // updates/patches needed.
          new LibraryUpdaterTestCase(
              before:
                  '/* Implicitly dynamic. */ main ( /* No parameters. */ ) '
                  '{print("Hello, World!");}',
              after: 'main() {print("Hello, World!");}',
              canReuse: true,
              updates: []),

          // Arrow function changed to method body. Can be reused if 'main' is
          // updated/patched.
          new LibraryUpdaterTestCase(
              before: 'main() => null',
              after: 'main() { return null; }',
              canReuse: true,
              updates: ['main']),

          // Empty body changed to contain a statement. Can be reused if 'main'
          // is updated/patched.
          new LibraryUpdaterTestCase(
              before: 'main() {}',
              after: 'main() { return null; }',
              canReuse: true,
              updates: ['main']),

          // Empty body changed to arrow. Can be reused if 'main'
          // is updated/patched.
          new LibraryUpdaterTestCase(
              before: 'main() {}',
              after: 'main() => null;',
              canReuse: true,
              updates: ['main']),

          // Arrow changed to empty body. Can be reused if 'main'
          // is updated/patched.
          new LibraryUpdaterTestCase(
              before: 'main() => null;',
              after: 'main() {}',
              canReuse: true,
              updates: ['main']),

          // TODO(ahe): When supporting class members, test abstract methods.
      ]
  );
}
