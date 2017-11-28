// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.test.src.multi_root_file_system.dart;

import 'dart:async';

import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/multi_root_file_system.dart';

import 'package:test/test.dart';

var root = Uri.parse('org-dartlang-test:///');

main() {
  var memoryFs;
  var rootUris;
  var multiRoot;

  write(String multiRoot, String path) {
    var realPath = multiRoot == '' ? path : '$multiRoot/$path';
    var uri = root.resolve(realPath);
    memoryFs.entityForUri(uri).writeAsStringSync('$uri');
  }

  Future<String> read(String uri) =>
      multiRoot.entityForUri(Uri.parse(uri)).readAsString();

  Future<bool> exists(String uri) =>
      multiRoot.entityForUri(Uri.parse(uri)).exists();

  Future<String> effectiveUriOf(String uri) async =>
      (await multiRoot.entityForUri(Uri.parse(uri)).delegate).uri.toString();

  setUp(() {
    memoryFs = new MemoryFileSystem(root);
    rootUris = ['r1', 'r2/', 'A/B/', ''].map((r) => root.resolve(r)).toList();
    multiRoot = new MultiRootFileSystem('multi-root', rootUris, memoryFs);
  });

  test('roots are normalized', () async {
    expect(multiRoot.roots.map((x) => x.path).toList(),
        ['/r1/', '/r2/', '/A/B/', '/']);
  });

  test('file URIs are not converted', () async {
    write('r1', 'a/b/1.dart');
    write('', 'a/b/1.dart');
    expect(await effectiveUriOf('org-dartlang-test:///a/b/1.dart'),
        'org-dartlang-test:///a/b/1.dart');
  });

  test('only URIs with the marker scheme are converted', () async {
    write('r1', 'a/b/2.dart');
    expect(await effectiveUriOf('multi-root:///a/b/2.dart'),
        'org-dartlang-test:///r1/a/b/2.dart');
    expect(await effectiveUriOf('foo-root:///a/b/2.dart'),
        'foo-root:///a/b/2.dart');
  });

  test('roots are visited in declaration order (match first root)', () async {
    write('r1', 'a/3.dart');
    write('r2', 'a/3.dart');
    write('', 'a/3.dart');
    expect(await effectiveUriOf('multi-root:///a/3.dart'),
        'org-dartlang-test:///r1/a/3.dart');
  });

  test('roots are visited in declaration order (match second root)', () async {
    write('r2', 'a/4.dart');
    write('', 'a/4.dart');
    expect(await effectiveUriOf('multi-root:///a/4.dart'),
        'org-dartlang-test:///r2/a/4.dart');
  });

  test('roots are visited in declaration order (match last root)', () async {
    write('', 'a/5.dart');
    expect(await effectiveUriOf('multi-root:///a/5.dart'),
        'org-dartlang-test:///a/5.dart');
  });

  test('operations are forwarded to the correct target', () async {
    write('r1', 'a/6.dart');
    write('r2', 'a/6.dart');
    write('r2', 'a/7.dart');

    expect(await exists('multi-root:///a/6.dart'), isTrue);
    expect(await read('multi-root:///a/6.dart'),
        'org-dartlang-test:///r1/a/6.dart');

    expect(await exists('multi-root:///a/7.dart'), isTrue);
    expect(await read('multi-root:///a/7.dart'),
        'org-dartlang-test:///r2/a/7.dart');
    expect(await exists('org-dartlang-test:///r2/a/7.dart'), isTrue);
    expect(await read('org-dartlang-test:///r2/a/7.dart'),
        'org-dartlang-test:///r2/a/7.dart');

    expect(await exists('multi-root:///a/8.dart'), isFalse);
  });

  test('multi-root expects absolute paths', () async {
    write('A/B', 'a/8.dart');

    expect(await effectiveUriOf('multi-root:///a/8.dart'),
        'org-dartlang-test:///A/B/a/8.dart');
    expect(await effectiveUriOf('multi-root:///../B/a/8.dart'),
        'multi-root:///B/a/8.dart');

    // Embedding the full absolute path after a few `..` gets resolved because
    // we have also included '' as a root.
    expect(await effectiveUriOf('multi-root:///../A/B/a/8.dart'),
        'org-dartlang-test:///A/B/a/8.dart');
    expect(await effectiveUriOf('multi-root:///../../A/B/a/8.dart'),
        'org-dartlang-test:///A/B/a/8.dart');

    // If we remove '' as a root, those URIs are not resolved.
    multiRoot =
        new MultiRootFileSystem('multi-root', [root.resolve('A/B/')], memoryFs);
    expect(await effectiveUriOf('multi-root:///../A/B/a/8.dart'),
        'multi-root:///A/B/a/8.dart');
    expect(await effectiveUriOf('multi-root:///../../A/B/a/8.dart'),
        'multi-root:///A/B/a/8.dart');
  });
}
