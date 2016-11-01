// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.file_system.resource_uri_resolver_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResourceUriResolverTest);
  });
}

@reflectiveTest
class ResourceUriResolverTest {
  MemoryResourceProvider provider;
  ResourceUriResolver resolver;

  void setUp() {
    provider = new MemoryResourceProvider();
    resolver = new ResourceUriResolver(provider);
    provider.newFile(provider.convertPath('/test.dart'), '');
    provider.newFolder(provider.convertPath('/folder'));
  }

  void test_creation() {
    expect(provider, isNotNull);
    expect(resolver, isNotNull);
  }

  void test_resolveAbsolute_file() {
    var uri = provider.pathContext.toUri(provider.convertPath('/test.dart'));
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(source.exists(), isTrue);
    expect(source.fullName, provider.convertPath('/test.dart'));
  }

  void test_resolveAbsolute_folder() {
    var uri = provider.pathContext.toUri(provider.convertPath('/folder'));
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_dartUri() {
    var uri = new Uri(scheme: 'dart', path: 'core');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    var uri = new Uri(scheme: 'https', path: '127.0.0.1/test.dart');
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_restoreAbsolute() {
    var uri = provider.pathContext.toUri(provider.convertPath('/test.dart'));
    Source source = resolver.resolveAbsolute(uri);
    expect(source, isNotNull);
    expect(resolver.restoreAbsolute(source), uri);
    expect(
        resolver.restoreAbsolute(
            new NonExistingSource(source.fullName, null, null)),
        uri);
  }
}
