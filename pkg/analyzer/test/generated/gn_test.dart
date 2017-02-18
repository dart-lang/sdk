// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.gn_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/gn.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GnPackageUriResolverTest);
    defineReflectiveTests(GnWorkspaceTest);
  });
}

@reflectiveTest
class GnPackageUriResolverTest extends _BaseTest {
  GnWorkspace workspace;
  GnPackageUriResolver resolver;

  void test_resolve() {
    _addResources([
      '/workspace/.jiri_root/',
      '/workspace/out/debug-x87_128/gen/dart.sources/',
      '/workspace/some/code/',
      '/workspace/a/source/code.dart',
    ]);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/dart.sources/flutter'),
        _p('/workspace/a/source'));
    _setUp();
    _assertResolve(
        'package:flutter/code.dart', _p('/workspace/a/source/code.dart'));
  }

  void test_resolveDoesNotExist() {
    _addResources([
      '/workspace/.jiri_root/',
      '/workspace/out/debug-x87_128/gen/dart.sources/',
      '/workspace/some/code/',
      '/workspace/a/source/code.dart',
    ]);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/dart.sources/flutter'),
        _p('/workspace/a/source'));
    _setUp();
    expect(
        resolver.resolveAbsolute(Uri.parse('package:bogus/code.dart')), null);
  }

  void test_resolveAddToCache() {
    _addResources([
      '/workspace/.jiri_root/',
      '/workspace/out/debug-x87_128/gen/dart.sources/',
      '/workspace/some/code/',
      '/workspace/a/source/code.dart',
    ]);
    _setUp();
    expect(
        resolver.resolveAbsolute(Uri.parse('package:flutter/code.dart')), null);
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/dart.sources/flutter'),
        _p('/workspace/a/source'));
    _assertResolve(
        'package:flutter/code.dart', _p('/workspace/a/source/code.dart'));
  }

  void _addResources(List<String> paths) {
    for (String path in paths) {
      if (path.endsWith('/')) {
        provider.newFolder(_p(path.substring(0, path.length - 1)));
      } else {
        provider.newFile(_p(path), '');
      }
    }
  }

  void _setUp() {
    workspace = GnWorkspace.find(provider, _p('/workspace'));
    resolver = new GnPackageUriResolver(workspace);
  }

  void _assertResolve(String uriStr, String posixPath,
      {bool exists: true, bool restore: true}) {
    Uri uri = Uri.parse(uriStr);
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.fullName, _p(posixPath));
    expect(source.uri, uri);
    expect(source.exists(), exists);
    // If enabled, test also "restoreAbsolute".
    if (restore) {
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri.toString(), uriStr);
    }
  }
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
    provider.newFolder(_p('/workspace/out/debug-x87_128/gen/dart.sources'));
    provider.newFolder(_p('/workspace/some/code'));
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace'));
  }

  void test_packages() {
    provider.newFolder(_p('/workspace/.jiri_root'));
    provider.newFolder(_p('/workspace/out/debug-x87_128/gen/dart.sources'));
    provider.newFile(
        _p('/workspace/out/debug-x87_128/gen/dart.sources/flutter'),
        _p('/path/to/source'));
    provider.newFolder(_p('/workspace/some/code'));
    GnWorkspace workspace =
        GnWorkspace.find(provider, _p('/workspace/some/code'));
    expect(workspace, isNotNull);
    expect(workspace.root, _p('/workspace'));
    expect(workspace.packageMap.length, 1);
    expect(workspace.packageMap['flutter'][0].path, _p('/path/to/source'));
  }
}

class _BaseTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}
