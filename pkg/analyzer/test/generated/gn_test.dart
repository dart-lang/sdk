// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.gn_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GnWorkspaceTest);
  });
}

@reflectiveTest
class GnWorkspaceTest extends _BaseTest {
  void test_find_notAbsolute() {
    expect(() => GnWorkspace.find(provider, _p('not_absolute')),
        throwsArgumentError);
  }

  void test_find_noJiriRoot() {
    provider.newFolder(_p('/workspace'));
    GnWorkspace workspace = GnWorkspace.find(provider, _p('/workspace'));
    expect(workspace, isNull);
  }

  void test_find_withRoot() {
    provider.newFolder(_p('/workspace/.jiri_root'));
    provider.newFolder(_p('/workspace/some/code'));
    provider.newFile(_p('/workspace/some/code/pubspec.yaml'), '');
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/some/code/foo.packages'), '');
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace/some/code'));
  }

  void test_find_inHost() {
    provider.newFolder(_p('/workspace/.jiri_root'));
    provider.newFolder(_p('/workspace/some/code'));
    provider.newFile(_p('/workspace/some/code/pubspec.yaml'), '');
    provider.newFile(
        _p('/workspace/out/debug-x87_128/host_y32/gen/some/code/foo.packages'),
        '');
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace/some/code'));
  }

  void test_packages() {
    provider.newFolder(_p('/workspace/.jiri_root'));
    provider.newFolder(_p('/workspace/some/code'));
    provider.newFile(_p('/workspace/some/code/pubspec.yaml'), '');
    String packageLocation = _p('/workspace/this/is/the/package');
    Uri packageUri = provider.pathContext.toUri(packageLocation);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/some/code/foo.packages'),
        'flutter:$packageUri');
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace/some/code'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, packageLocation);
  }

  void test_packages_multipleFiles() {
    provider.newFolder(_p('/workspace/.jiri_root'));
    provider.newFolder(_p('/workspace/some/code'));
    provider.newFile(_p('/workspace/some/code/pubspec.yaml'), '');
    String packageOneLocation = _p('/workspace/this/is/the/package');
    Uri packageOneUri = provider.pathContext.toUri(packageOneLocation);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/some/code/foo.packages'),
        'flutter:$packageOneUri');
    String packageTwoLocation = _p('/workspace/this/is/the/other/package');
    Uri packageTwoUri = provider.pathContext.toUri(packageTwoLocation);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/some/code/foo_test.packages'),
        'rettluf:$packageTwoUri');
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace/some/code'));
    expect(workspace.packageMap.length, 2);
    expect(workspace.packageMap['flutter'][0].path, packageOneLocation);
    expect(workspace.packageMap['rettluf'][0].path, packageTwoLocation);
  }
}

class _BaseTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}
