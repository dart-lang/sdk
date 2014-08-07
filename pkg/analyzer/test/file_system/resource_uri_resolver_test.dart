// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.resource_uri_resolver;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  group('ResourceUriResolver', () {
    MemoryResourceProvider provider;
    ResourceUriResolver resolver;

    setUp(() {
      provider = new MemoryResourceProvider();
      resolver = new ResourceUriResolver(provider);
      provider.newFile('/test.dart', '');
      provider.newFolder('/folder');
    });

    group('resolveAbsolute', () {
      test('file', () {
        var uri = new Uri(scheme: 'file', path: '/test.dart');
        Source source = resolver.resolveAbsolute(uri);
        expect(source, isNotNull);
        expect(source.exists(), isTrue);
        expect(source.fullName, '/test.dart');
      });

      test('folder', () {
        var uri = new Uri(scheme: 'file', path: '/folder');
        Source source = resolver.resolveAbsolute(uri);
        expect(source, isNull);
      });

      test('not a file URI', () {
        var uri = new Uri(scheme: 'https', path: '127.0.0.1/test.dart');
        Source source = resolver.resolveAbsolute(uri);
        expect(source, isNull);
      });
    });
  });
}
