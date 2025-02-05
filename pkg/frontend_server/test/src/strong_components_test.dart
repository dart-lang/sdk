// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:frontend_server/src/strong_components.dart';
import 'package:kernel/ast.dart';
import 'package:test/test.dart';

void main() {
  test('empty component', () {
    final Component testComponent = new Component(libraries: []);
    final StrongComponents strongComponents =
        new StrongComponents(testComponent, {}, new Uri.file('/c.dart'));
    strongComponents.computeLibraryBundles();

    expect(strongComponents.libraryBundleImportToLibraries, {});
  });

  test('no circular imports', () {
    final Library libraryA = new Library(
      new Uri.file('/a.dart'),
      fileUri: new Uri.file('/a.dart'),
    );
    final Library libraryB = new Library(
      new Uri.file('/b.dart'),
      fileUri: new Uri.file('/b.dart'),
      dependencies: [
        new LibraryDependency.import(libraryA),
      ],
    );
    final Library libraryC = new Library(
      new Uri.file('/c.dart'),
      fileUri: new Uri.file('/c.dart'),
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
    );
    final Component testComponent = new Component(libraries: [
      libraryA,
      libraryB,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        new StrongComponents(testComponent, {}, new Uri.file('/c.dart'));
    strongComponents.computeLibraryBundles();

    expect(strongComponents.libraryBundleImportToLibraries, {
      new Uri.file('/a.dart'): [libraryA],
      new Uri.file('/b.dart'): [libraryB],
      new Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.libraryImportToLibraryBundleImport, {
      new Uri.file('/a.dart'): new Uri.file('/a.dart'),
      new Uri.file('/b.dart'): new Uri.file('/b.dart'),
      new Uri.file('/c.dart'): new Uri.file('/c.dart'),
    });
  });

  test('no circular imports with partial component', () {
    final Uri uriA = new Uri.file('/a.dart');
    final Library libraryA = new Library(
      uriA,
      fileUri: uriA,
    );
    final Uri uriB = new Uri.file('/b.dart');
    final Library libraryB = new Library(
      uriB,
      fileUri: uriB,
      dependencies: [
        new LibraryDependency.import(libraryA),
      ],
    );
    final Uri uriC = new Uri.file('/c.dart');
    final Library libraryC = new Library(
      uriC,
      fileUri: uriC,
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
    );
    final Library partialA = new Library(
      uriA,
      fileUri: uriA,
    );
    final Component testComponent = new Component(libraries: [
      libraryA,
      libraryB,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        new StrongComponents(testComponent, {}, uriC);
    strongComponents.computeLibraryBundles({uriA: partialA});

    expect(strongComponents.libraryBundleImportToLibraries, {
      uriA: [partialA],
      uriB: [libraryB],
      uriC: [libraryC],
    });
    expect(strongComponents.libraryImportToLibraryBundleImport, {
      uriA: uriA,
      uriB: uriB,
      uriC: uriC,
    });
  });

  test('circular imports are combined into single bundle', () {
    final Library libraryA = new Library(
      new Uri.file('/a.dart'),
      fileUri: new Uri.file('/a.dart'),
    );
    final Library libraryB = new Library(
      new Uri.file('/b.dart'),
      fileUri: new Uri.file('/b.dart'),
    );
    // induce circular import.
    libraryB.dependencies.add(new LibraryDependency.import(libraryA));
    libraryA.dependencies.add(new LibraryDependency.import(libraryB));
    final Library libraryC = new Library(
      new Uri.file('/c.dart'),
      fileUri: new Uri.file('/c.dart'),
      dependencies: [
        new LibraryDependency.import(libraryB),
      ],
    );
    final Component testComponent = new Component(libraries: [
      libraryA,
      libraryB,
      libraryC,
    ]);
    final StrongComponents strongComponents =
        new StrongComponents(testComponent, {}, new Uri.file('/c.dart'));
    strongComponents.computeLibraryBundles();

    expect(strongComponents.libraryBundleImportToLibraries, {
      // The choice of bundle here is arbitrary, but should be consistent for
      // a given component.
      new Uri.file('/a.dart'): [libraryA, libraryB],
      new Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.libraryImportToLibraryBundleImport, {
      new Uri.file('/a.dart'): new Uri.file('/a.dart'),
      new Uri.file('/b.dart'): new Uri.file('/a.dart'),
      new Uri.file('/c.dart'): new Uri.file('/c.dart'),
    });
  });

  test('does not index loaded, dart:, or unimported libraries', () {
    final Library libraryLoaded = new Library(
      new Uri.file('a.dart'),
      fileUri: new Uri.file('/a.dart'),
    );
    final Library libraryDart = new Library(
      Uri.parse('dart:foo'),
      fileUri: new Uri.file('/b.dart'),
    );
    final Library libraryUnrelated = new Library(
      new Uri.file('/z.dart'),
      fileUri: new Uri.file('/z.dart'),
    );
    final Library libraryC = new Library(
      new Uri.file('/c.dart'),
      fileUri: new Uri.file('/c.dart'),
      dependencies: [
        new LibraryDependency.import(libraryLoaded),
        new LibraryDependency.import(libraryDart),
      ],
    );
    final Component testComponent = new Component(libraries: [
      libraryLoaded,
      libraryDart,
      libraryUnrelated,
      libraryC,
    ]);
    final StrongComponents strongComponents = new StrongComponents(
        testComponent, {libraryLoaded}, new Uri.file('/c.dart'));
    strongComponents.computeLibraryBundles();

    expect(strongComponents.libraryBundleImportToLibraries, {
      new Uri.file('/c.dart'): [libraryC],
    });
    expect(strongComponents.libraryImportToLibraryBundleImport, {
      new Uri.file('/c.dart'): new Uri.file('/c.dart'),
    });
  });
}
