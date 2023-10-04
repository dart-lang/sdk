// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import 'workspace_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BasicWorkspaceTest);
    defineReflectiveTests(BasicWorkspacePackageTest);
  });
}

@reflectiveTest
class BasicWorkspacePackageTest extends WorkspacePackageTest {
  setUp() {
    newFolder('/workspace');

    workspace = BasicWorkspace.find(
      resourceProvider,
      Packages({
        'p1': Package(
          name: 'p1',
          rootFolder: getFolder('/.pubcache/p1'),
          libFolder: getFolder('/.pubcache/p1/lib'),
          languageVersion: null,
        ),
        'workspace': Package(
          name: 'workspace',
          rootFolder: getFolder('/workspace'),
          libFolder: getFolder('/workspace/lib'),
          languageVersion: null,
        ),
      }),
      convertPath('/workspace'),
    );
    expect(workspace.isBlaze, isFalse);
  }

  void test_contains_differentWorkspace() {
    newFile('/workspace2/project/lib/file.dart', '');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('/workspace2/project/lib/file.dart'))),
        isFalse);
  }

  void test_contains_sameWorkspace() {
    newFile('/workspace/project/lib/file2.dart', '');

    var package = findPackage('/workspace/project/lib/code.dart')!;
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/lib/file2.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/bin/bin.dart'))),
        isTrue);
    expect(
        package.contains(
            TestSource(convertPath('/workspace/project/test/test.dart'))),
        isTrue);
  }

  void test_findPackageFor_includedFile() {
    newFile('/workspace/project/lib/file.dart', '');

    var package = findPackage('/workspace/project/lib/file.dart')!;
    expect(package, isNotNull);
    expect(package.root, convertPath('/workspace'));
    expect(package.workspace, equals(workspace));
  }

  void test_findPackageFor_unrelatedFile() {
    newFile('/workspace/project/lib/file.dart', '');

    var package = findPackage('/workspace2/project/lib/file.dart');
    expect(package, isNull);
  }

  void test_isDevDependency_bin() {
    newFile('/workspace/bin/file.dart', '');
    var package = findPackage('/workspace/lib/code.dart')!;
    var testSource = TestSource(convertPath('/workspace/bin/file.dart'));
    expect(package.canBeDevDependency(testSource), false);
  }

  void test_isDevDependency_lib() {
    newFile('/workspace/lib/src/file.dart', '');
    var package = findPackage('/workspace/lib/code.dart')!;
    var testSource = TestSource(convertPath('/workspace/lib/src/file.dart'));
    expect(package.canBeDevDependency(testSource), false);
  }

  void test_isDevDependency_true() {
    newFile('/workspace/test/file.dart', '');
    var package = findPackage('/workspace/lib/code.dart')!;
    var testSource = TestSource(convertPath('/workspace/test/file.dart'));
    expect(package.canBeDevDependency(testSource), true);
  }

  void test_packagesAvailableTo() {
    var libraryPath = convertPath('/workspace/lib/test.dart');
    var package = findPackage(libraryPath)!;
    var packages = package.packagesAvailableTo(libraryPath);
    expect(
      packages.packages.map((e) => e.name),
      unorderedEquals(['p1', 'workspace']),
    );
  }
}

@reflectiveTest
class BasicWorkspaceTest with ResourceProviderMixin {
  setUp() {
    newFolder('/workspace');
  }

  void test_find_directory() {
    BasicWorkspace workspace = BasicWorkspace.find(
        resourceProvider, Packages.empty, convertPath('/workspace'));
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.isBlaze, isFalse);
  }

  void test_find_fail_notAbsolute() {
    expect(
        () => BasicWorkspace.find(
            resourceProvider, Packages.empty, convertPath('not_absolute')),
        throwsA(TypeMatcher<ArgumentError>()));
  }

  void test_find_file() {
    BasicWorkspace workspace = BasicWorkspace.find(resourceProvider,
        Packages.empty, convertPath('/workspace/project/lib/lib1.dart'));
    expect(workspace.root, convertPath('/workspace/project/lib'));
    expect(workspace.isBlaze, isFalse);
  }
}
