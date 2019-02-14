// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:package_config/packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubWorkspacePackageTest);
    defineReflectiveTests(PubWorkspaceTest);
  });
}

class MockContextBuilder implements ContextBuilder {
  Map<String, Packages> packagesMapMap = <String, Packages>{};
  Map<Packages, Map<String, List<Folder>>> packagesToMapMap =
      <Packages, Map<String, List<Folder>>>{};

  Map<String, List<Folder>> convertPackagesToMap(Packages packages) =>
      packagesToMapMap[packages];

  Packages createPackageMap(String rootDirectoryPath) =>
      packagesMapMap[rootDirectoryPath];

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPackages implements Packages {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@reflectiveTest
class PubWorkspacePackageTest with ResourceProviderMixin {
  PubWorkspace workspace;

  setUp() {
    final contextBuilder = new MockContextBuilder();
    final packages = new MockPackages();
    final packageMap = <String, List<Folder>>{'project': []};
    contextBuilder.packagesMapMap[convertPath('/workspace')] = packages;
    contextBuilder.packagesToMapMap[packages] = packageMap;

    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    workspace = PubWorkspace.find(
        resourceProvider, convertPath('/workspace'), contextBuilder);
  }

  void test_findPackageFor_unrelatedFile() {
    newFile('/workspace/project/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace2/project/lib/file.dart'));
    expect(package, isNull);
  }

  void test_findPackageFor_includedFile() {
    newFile('/workspace/project/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/file.dart'));
    expect(package, isNotNull);
    expect(package.root, convertPath('/workspace'));
    expect(package.workspace, equals(workspace));
  }

  void test_contains_differentWorkspace() {
    newFile('/workspace2/project/lib/file.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/code.dart'));
    expect(package.contains('/workspace2/project/lib/file.dart'), isFalse);
  }

  void test_contains_sameWorkspace() {
    newFile('/workspace/project/lib/file2.dart');

    var package = workspace
        .findPackageFor(convertPath('/workspace/project/lib/code.dart'));
    expect(package.contains('/workspace/project/lib/file2.dart'), isTrue);
    expect(package.contains('/workspace/project/bin/bin.dart'), isTrue);
    expect(package.contains('/workspace/project/test/test.dart'), isTrue);
  }
}

@reflectiveTest
class PubWorkspaceTest with ResourceProviderMixin {
  void test_find_fail_notAbsolute() {
    expect(
        () => PubWorkspace.find(resourceProvider, convertPath('not_absolute'),
            new MockContextBuilder()),
        throwsA(TypeMatcher<ArgumentError>()));
  }

  void test_find_missingPubspec() {
    PubWorkspace workspace = PubWorkspace.find(resourceProvider,
        convertPath('/workspace/lib/lib1.dart'), new MockContextBuilder());
    expect(workspace, isNull);
  }

  void test_find_directory() {
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PubWorkspace workspace = PubWorkspace.find(
        resourceProvider, convertPath('/workspace'), new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_find_file() {
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    PubWorkspace workspace = PubWorkspace.find(resourceProvider,
        convertPath('/workspace/lib/lib1.dart'), new MockContextBuilder());
    expect(workspace.root, convertPath('/workspace'));
  }
}
