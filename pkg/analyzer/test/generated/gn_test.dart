// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GnWorkspaceTest);
  });
}

@reflectiveTest
class GnWorkspaceTest extends Object with ResourceProviderMixin {
  void test_find_noJiriRoot() {
    newFolder('/workspace');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace, isNull);
  }

  void test_find_noPackagesFiles() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace'));
    expect(workspace, isNull);
  }

  void test_find_notAbsolute() {
    expect(
        () => GnWorkspace.find(resourceProvider, convertPath('not_absolute')),
        throwsArgumentError);
  }

  void test_find_withRoot() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n' + 'FUCHSIA_BUILD_DIR="$buildDir"\n' + 'BAR=bar\n');
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
  }

  void test_packages() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n' + 'FUCHSIA_BUILD_DIR="$buildDir"\n' + 'BAR=bar\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, packageLocation);
  }

  void test_packages_absoluteBuildDir() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String buildDir = convertPath('/workspace/out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n' + 'FUCHSIA_BUILD_DIR="$buildDir"\n' + 'BAR=bar\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, packageLocation);
  }

  void test_packages_fallbackBuildDir() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, packageLocation);
  }

  void test_packages_fallbackBuildDirWithUselessConfig() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    newFile('/workspace/.config', content: 'FOO=foo\n' + 'BAR=bar\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, packageLocation);
  }

  void test_packages_multipleCandidates() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String buildDir = convertPath('out/release-y22_256');
    newFile('/workspace/.config',
        content: 'FOO=foo\n' + 'FUCHSIA_BUILD_DIR="$buildDir"\n' + 'BAR=bar\n');
    String packageLocation = convertPath('/workspace/this/is/the/package');
    Uri packageUri = resourceProvider.pathContext.toUri(packageLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageUri');
    String otherPackageLocation = convertPath('/workspace/here/too');
    Uri otherPackageUri =
        resourceProvider.pathContext.toUri(otherPackageLocation);
    newFile(
        '/workspace/out/release-y22_256/dartlang/gen/some/code/foo.packages',
        content: 'rettulf:$otherPackageUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['rettulf'][0].path, otherPackageLocation);
  }

  void test_packages_multipleFiles() {
    newFolder('/workspace/.jiri_root');
    newFolder('/workspace/some/code');
    newFile('/workspace/some/code/pubspec.yaml');
    String buildDir = convertPath('out/debug-x87_128');
    newFile('/workspace/.config',
        content: 'FOO=foo\n' + 'FUCHSIA_BUILD_DIR=$buildDir\n' + 'BAR=bar\n');
    String packageOneLocation = convertPath('/workspace/this/is/the/package');
    Uri packageOneUri = resourceProvider.pathContext.toUri(packageOneLocation);
    newFile('/workspace/out/debug-x87_128/dartlang/gen/some/code/foo.packages',
        content: 'flutter:$packageOneUri');
    String packageTwoLocation =
        convertPath('/workspace/this/is/the/other/package');
    Uri packageTwoUri = resourceProvider.pathContext.toUri(packageTwoLocation);
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/some/code/foo_test.packages',
        content: 'rettulf:$packageTwoUri');
    GnWorkspace workspace =
        GnWorkspace.find(resourceProvider, convertPath('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, convertPath('/workspace'));
    expect(workspace.packageMap.length, 2);
    expect(workspace.packageMap['flutter'][0].path, packageOneLocation);
    expect(workspace.packageMap['rettulf'][0].path, packageTwoLocation);
  }
}
