// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summarize_ast_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LinkerUnitTest);
}

@reflectiveTest
class LinkerUnitTest extends SummaryLinkerTest {
  Linker linker;

  LinkerInputs linkerInputs;
  LibraryElementInBuildUnit _testLibrary;
  @override
  bool get allowMissingFiles => false;

  LibraryElementInBuildUnit get testLibrary => _testLibrary ??=
      linker.getLibrary(linkerInputs.testDartUri) as LibraryElementInBuildUnit;

  void createLinker(String text) {
    linkerInputs = createLinkerInputs(text);
    Map<String, LinkedLibraryBuilder> linkedLibraries =
        setupForLink(linkerInputs.linkedLibraries, linkerInputs.getUnit);
    linker = new Linker(linkedLibraries, linkerInputs.getDependency,
        linkerInputs.getUnit, true);
  }

  LibraryElementForLink getLibrary(String uri) {
    return linker.getLibrary(Uri.parse(uri));
  }

  void test_libraryCycle_ignoresDependenciesOutsideBuildUnit() {
    createLinker('import "dart:async";');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, [testLibrary]);
  }

  void test_libraryCycle_nontrivial() {
    addNamedSource('/a.dart', 'import "b.dart";');
    addNamedSource('/b.dart', 'import "a.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = libA.libraryCycleForLink;
    expect(libB.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, unorderedEquals([libA, libB]));
  }

  void test_libraryCycle_nontrivial_dependencies() {
    addNamedSource('/a.dart', '');
    addNamedSource('/b.dart', '');
    addNamedSource('/c.dart', 'import "a.dart"; import "d.dart";');
    addNamedSource('/d.dart', 'import "b.dart"; import "c.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryElementForLink libC = getLibrary('file:///c.dart');
    LibraryElementForLink libD = getLibrary('file:///d.dart');
    LibraryCycleForLink libraryCycle = libC.libraryCycleForLink;
    expect(libD.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies,
        unorderedEquals([libA.libraryCycleForLink, libB.libraryCycleForLink]));
    expect(libraryCycle.libraries, unorderedEquals([libC, libD]));
  }

  void test_libraryCycle_nontrivial_via_export() {
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', 'export "a.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = libA.libraryCycleForLink;
    expect(libB.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, unorderedEquals([libA, libB]));
  }

  void test_libraryCycle_trivial() {
    createLinker('');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, [testLibrary]);
  }

  void test_libraryCycle_trivial_dependencies() {
    addNamedSource('/a.dart', '');
    addNamedSource('/b.dart', '');
    createLinker('import "a.dart"; import "b.dart";');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies,
        unorderedEquals([libA.libraryCycleForLink, libB.libraryCycleForLink]));
    expect(libraryCycle.libraries, [testLibrary]);
  }
}
