// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_integration/file_system/single_root.dart';
import 'package:front_end/src/api_unstable/build_integration.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:test/test.dart';

main() {
  var root = Uri.parse('org-dartlang-test:///');
  var fileSystem = new SingleRootFileSystem(
      'single-root', root.resolve('A/B'), new MemoryFileSystem(root));

  SingleRootFileSystemEntity entityOf(String uri) =>
      fileSystem.entityForUri(Uri.parse(uri));

  String effectiveUriOf(String uri) => '${entityOf(uri).delegate.uri}';

  test('root is normalized', () {
    expect(fileSystem.root.path, '/A/B/');
  });

  test('URIs with the marker scheme are converted', () {
    expect(effectiveUriOf('single-root:///a/b/1.dart'),
        'org-dartlang-test:///A/B/a/b/1.dart');
  });

  test('single-root expects absolute paths', () {
    expect(effectiveUriOf('single-root:///a/8.dart'),
        'org-dartlang-test:///A/B/a/8.dart');
    expect(effectiveUriOf('single-root:///../B/a/8.dart'),
        'org-dartlang-test:///A/B/B/a/8.dart');
  });

  test('URIs with other schemes are not supported', () {
    expect(() => entityOf('foo-root:///a/b/1.dart'),
        throwsA((e) => e is FileSystemException));

    // The scheme of the underlying file system is also not supported
    expect(() => entityOf('org-dartlang-test:///a/b/1.dart'),
        throwsA((e) => e is FileSystemException));
  });
}
