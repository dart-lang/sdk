// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:frontend_server/src/strong_components.dart';
import 'package:kernel/ast.dart';
import 'package:test/test.dart';

void main() {
  test('empty component', () {
    final testComponent = Component(libraries: []);
    final StrongComponents strongComponents =
        StrongComponents(testComponent, {}, Uri.file('/c.dart'));
    strongComponents.computeModules();

    expect(strongComponents.modules, {});
  });

  test('no circular imports', () {
    final libraryA = Library(
      Uri.file('/a.dart'),
      fileUri: Uri.file('/a.dart'),
    );
    final libraryB = Library(
      Uri.file('/b.dart'),
      fileUri: Uri.file('/b.dart'),
      dependencies: [
        LibraryDependency.import(libraryA),
      ],
    );
    final libraryC = Library(
      Uri.file('/c.dart'),
      fileUri: Uri.file('/c.dart'),
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
    );
    final testComponent = Component(libraries: [
      libraryA,
      libraryB,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        StrongComponents(testComponent, {}, Uri.file('/c.dart'));
    strongComponents.computeModules();

    expect(strongComponents.modules, {
      Uri.file('/a.dart'): [libraryA],
      Uri.file('/b.dart'): [libraryB],
      Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.moduleAssignment, {
      Uri.file('/a.dart'): Uri.file('/a.dart'),
      Uri.file('/b.dart'): Uri.file('/b.dart'),
      Uri.file('/c.dart'): Uri.file('/c.dart'),
    });
  });

  test('circular imports are combined into single module', () {
    final libraryA = Library(
      Uri.file('/a.dart'),
      fileUri: Uri.file('/a.dart'),
    );
    final libraryB = Library(
      Uri.file('/b.dart'),
      fileUri: Uri.file('/b.dart'),
    );
    // induce circular import.
    libraryB.dependencies.add(LibraryDependency.import(libraryA));
    libraryA.dependencies.add(LibraryDependency.import(libraryB));
    final libraryC = Library(
      Uri.file('/c.dart'),
      fileUri: Uri.file('/c.dart'),
      dependencies: [
        LibraryDependency.import(libraryB),
      ],
    );
    final testComponent = Component(libraries: [
      libraryA,
      libraryB,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        StrongComponents(testComponent, {}, Uri.file('/c.dart'));
    strongComponents.computeModules();

    expect(strongComponents.modules, {
      // The choice of module here is arbitrary, but should be consistent for
      // a given component.
      Uri.file('/a.dart'): [libraryA, libraryB],
      Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.moduleAssignment, {
      Uri.file('/a.dart'): Uri.file('/a.dart'),
      Uri.file('/b.dart'): Uri.file('/a.dart'),
      Uri.file('/c.dart'): Uri.file('/c.dart'),
    });
  });

  test('does not index loaded, dart:, or unimported libraries', () {
    final libraryLoaded = Library(
      Uri.file('a.dart'),
      fileUri: Uri.file('/a.dart'),
    );
    final libraryDart = Library(
      Uri.parse('dart:foo'),
      fileUri: Uri.file('/b.dart'),
    );
    final libraryUnrelated = Library(
      Uri.file('/z.dart'),
      fileUri: Uri.file('/z.dart'),
    );
    final libraryC = Library(
      Uri.file('/c.dart'),
      fileUri: Uri.file('/c.dart'),
      dependencies: [
        LibraryDependency.import(libraryLoaded),
        LibraryDependency.import(libraryDart),
      ],
    );
    final testComponent = Component(libraries: [
      libraryLoaded,
      libraryDart,
      libraryUnrelated,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        StrongComponents(testComponent, {libraryLoaded}, Uri.file('/c.dart'));
    strongComponents.computeModules();

    expect(strongComponents.modules, {
      Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.moduleAssignment, {
      Uri.file('/c.dart'): Uri.file('/c.dart'),
    });
  });
}
