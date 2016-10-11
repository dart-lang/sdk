// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.sdk_ext_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(SdkExtUriResolverTest);
}

@reflectiveTest
class SdkExtUriResolverTest {
  MemoryResourceProvider resourceProvider;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    resourceProvider.newFolder('/empty');
    resourceProvider.newFolder('/tmp');
    resourceProvider.newFile(
        '/tmp/_sdkext',
        r'''
{
  "dart:fox": "slippy.dart",
  "dart:bear": "grizzly.dart",
  "dart:relative": "../relative.dart",
  "dart:deep": "deep/directory/file.dart",
  "fart:loudly": "nomatter.dart"
}''');
  }

  test_create_badJSON() {
    var resolver = new SdkExtUriResolver(null);
    resolver.addSdkExt(r'''{{{,{{}}},}}''', null);
    expect(resolver.length, equals(0));
  }

  test_create_noSdkExtPackageMap() {
    var resolver = new SdkExtUriResolver({
      'fox': <Folder>[resourceProvider.getResource('/empty')]
    });
    expect(resolver.length, equals(0));
  }

  test_create_nullPackageMap() {
    var resolver = new SdkExtUriResolver(null);
    expect(resolver.length, equals(0));
  }

  test_create_sdkExtPackageMap() {
    var resolver = new SdkExtUriResolver({
      'fox': <Folder>[resourceProvider.getResource('/tmp')]
    });
    // We have four mappings.
    expect(resolver.length, equals(4));
    // Check that they map to the correct paths.
    expect(resolver['dart:fox'], equals("/tmp/slippy.dart"));
    expect(resolver['dart:bear'], equals("/tmp/grizzly.dart"));
    expect(resolver['dart:relative'], equals("/relative.dart"));
    expect(resolver['dart:deep'], equals("/tmp/deep/directory/file.dart"));
  }

  test_restoreAbsolute() {
    var resolver = new SdkExtUriResolver({
      'fox': <Folder>[resourceProvider.getResource('/tmp')]
    });
    var source = resolver.resolveAbsolute(Uri.parse('dart:fox'));
    expect(source, isNotNull);
    // Restore source's uri.
    var restoreUri = resolver.restoreAbsolute(source);
    expect(restoreUri, isNotNull);
    // Verify that it is 'dart:fox'.
    expect(restoreUri.toString(), equals('dart:fox'));
    expect(restoreUri.scheme, equals('dart'));
    expect(restoreUri.path, equals('fox'));
  }
}
