// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.util.fast_uri_test;

import 'package:analyzer/src/util/fast_uri.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(_FastUriTest);
}

@reflectiveTest
class _FastUriTest {
  static final isInstanceOf<FastUri> isFastUri = new isInstanceOf<FastUri>();

  void test_parse_absolute_dart() {
    _compareTextWithCoreUri('dart:core');
  }

  void test_parse_absolute_file() {
    _compareTextWithCoreUri('file:///Users/scheglov/util/fast_uri.dart');
  }

  void test_parse_absolute_folder_withSlashAtTheEnd() {
    _compareTextWithCoreUri('file:///Users/scheglov/util/');
  }

  void test_parse_absolute_package() {
    _compareTextWithCoreUri('package:analyzer/src/util/fast_uri.dart');
  }

  void test_parse_notFast_hasAuthority() {
    Uri uri = FastUri.parse('http://www.google.com/pages/about.html');
    expect(uri, isNot(isFastUri));
  }

  void test_parse_notFast_hasPort() {
    Uri uri = FastUri.parse('http://www.google.com:8080/pages/about.html');
    expect(uri, isNot(isFastUri));
  }

  void test_parse_relative_down() {
    _compareTextWithCoreUri('util/fast_uri.dart');
  }

  void test_parse_relative_up() {
    _compareTextWithCoreUri('../util/fast_uri.dart');
  }

  void test_resolve() {
    Uri uri1 = FastUri.parse('package:analyzer/aaa/bbbb/c.dart');
    Uri uri2 = uri1.resolve('dd.dart');
    _compareUris(uri2, Uri.parse('package:analyzer/aaa/bbbb/dd.dart'));
  }

  void test_resolveUri_absolute() {
    _checkResolveUri('package:analyzer/aaa/b.dart', 'package:path/style.dart',
        'package:path/style.dart');
  }

  void test_resolveUri_endWithSlash_onlyName() {
    _checkResolveUri('package:analyzer/aaa/bbbb/', 'cc.dart',
        'package:analyzer/aaa/bbbb/cc.dart');
  }

  void test_resolveUri_nameStartsWithOneDot() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', '.name.dart',
        'package:analyzer/aaa/bbbb/.name.dart');
  }

  void test_resolveUri_nameStartsWithTwoDots() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', '..name.dart',
        'package:analyzer/aaa/bbbb/..name.dart');
  }

  void test_resolveUri_noSlash_onlyName() {
    _checkResolveUri('dart:core', 'int.dart', 'dart:core/int.dart');
  }

  void test_resolveUri_onlyName() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', 'dd.dart',
        'package:analyzer/aaa/bbbb/dd.dart');
  }

  void test_resolveUri_pathHasOneDot() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', 'dd/./ee.dart',
        'package:analyzer/aaa/bbbb/dd/ee.dart');
  }

  void test_resolveUri_pathHasTwoDots() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', 'dd/../ee.dart',
        'package:analyzer/aaa/bbbb/ee.dart');
  }

  void test_resolveUri_pathStartsWithOneDot() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', './ddd.dart',
        'package:analyzer/aaa/bbbb/ddd.dart');
  }

  void test_resolveUri_pathStartsWithTwoDots() {
    _checkResolveUri('package:analyzer/aaa/bbbb/ccc.dart', '../ddd.dart',
        'package:analyzer/aaa/ddd.dart');
  }

  void test_resolveUri_pathWithSubFolder() {
    Uri uri1 = FastUri.parse('package:analyzer/aaa/bbbb/ccc.dart');
    Uri uri2 = FastUri.parse('dd/eeee.dart');
    expect(uri1, isFastUri);
    expect(uri2, isFastUri);
    Uri uri3 = uri1.resolveUri(uri2);
    expect(uri3, isFastUri);
    _compareUris(uri3, Uri.parse('package:analyzer/aaa/bbbb/dd/eeee.dart'));
  }

  void _checkResolveUri(String srcText, String relText, String targetText) {
    Uri src = FastUri.parse(srcText);
    Uri rel = FastUri.parse(relText);
    expect(src, isFastUri);
    expect(rel, isFastUri);
    Uri target = src.resolveUri(rel);
    expect(target, isFastUri);
    _compareUris(target, Uri.parse(targetText));
  }

  void _compareTextWithCoreUri(String text, {bool isFast: true}) {
    Uri fastUri = FastUri.parse(text);
    Uri coreUri = Uri.parse(text);
    if (isFast) {
      expect(fastUri, isFastUri);
    }
    _compareUris(fastUri, coreUri);
  }

  void _compareUris(Uri fastUri, Uri coreUri) {
    expect(fastUri.authority, coreUri.authority);
    expect(fastUri.data, coreUri.data);
    expect(fastUri.fragment, coreUri.fragment);
    expect(fastUri.hasAbsolutePath, coreUri.hasAbsolutePath);
    expect(fastUri.hasAuthority, coreUri.hasAuthority);
    expect(fastUri.hasEmptyPath, coreUri.hasEmptyPath);
    expect(fastUri.hasFragment, coreUri.hasFragment);
    expect(fastUri.hasPort, coreUri.hasPort);
    expect(fastUri.hasQuery, coreUri.hasQuery);
    expect(fastUri.hasScheme, coreUri.hasScheme);
    expect(fastUri.host, coreUri.host);
    expect(fastUri.isAbsolute, coreUri.isAbsolute);
    if (coreUri.scheme == 'http' || coreUri.scheme == 'https') {
      expect(fastUri.origin, coreUri.origin);
    }
    expect(fastUri.path, coreUri.path);
    expect(fastUri.pathSegments, coreUri.pathSegments);
    expect(fastUri.port, coreUri.port);
    expect(fastUri.query, coreUri.query);
    expect(fastUri.queryParameters, coreUri.queryParameters);
    expect(fastUri.queryParametersAll, coreUri.queryParametersAll);
    expect(fastUri.scheme, coreUri.scheme);
    expect(fastUri.userInfo, coreUri.userInfo);
    // Object
    expect(fastUri.hashCode, coreUri.hashCode);
    expect(fastUri == coreUri, isTrue);
    expect(coreUri == fastUri, isTrue);
  }
}
