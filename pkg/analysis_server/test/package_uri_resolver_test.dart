// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.resolver.package;

import 'package:analysis_server/src/package_uri_resolver.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import 'reflective_tests.dart';

main() {
  groupSep = ' | ';

  group('PackageMapUriResolver', () {
    runReflectiveTests(_PackageMapUriResolverTest);
  });
}


@ReflectiveTestCase()
class _PackageMapUriResolverTest {
  static const EMPTY_MAP = const <String, Folder>{};
  MemoryResourceProvider provider = new MemoryResourceProvider();

  setUp() {
  }

  tearDown() {
  }

  void test_isPackageUri() {
    Uri uri = Uri.parse('package:test/test.dart');
    expect(uri.scheme, 'package');
    expect(PackageMapUriResolver.isPackageUri(uri), isTrue);
  }

  void test_fromEncoding_nonPackage() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('file:/does/not/exist.dart');
    Source result = resolver.fromEncoding(UriKind.DART_URI, uri);
    expect(result, isNull);
  }

  void test_fromEncoding_package() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/does/not/exist.dart');
    Source result = resolver.fromEncoding(UriKind.PACKAGE_URI, uri);
    expect(result, isNotNull);
    expect(result.fullName, '/does/not/exist.dart');
  }

  void test_fromEncoding_packageSelf() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/does/not/exist.dart');
    Source result = resolver.fromEncoding(UriKind.PACKAGE_SELF_URI, uri);
    expect(result, isNotNull);
    expect(result.fullName, '/does/not/exist.dart');
  }

  void test_isPackageUri_null_scheme() {
    Uri uri = Uri.parse('foo.dart');
    expect(uri.scheme, '');
    expect(PackageMapUriResolver.isPackageUri(uri), isFalse);
  }

  void test_isPackageUri_other_scheme() {
    Uri uri = Uri.parse('memfs:/foo.dart');
    expect(uri.scheme, 'memfs');
    expect(PackageMapUriResolver.isPackageUri(uri), isFalse);
  }

  void test_resolve_OK() {
    const pkgFileA = '/pkgA/lib/libA.dart';
    const pkgFileB = '/pkgB/lib/libB.dart';
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver = new PackageMapUriResolver(provider,
        <String, Folder>{
      'pkgA': provider.getResource('/pkgA/lib/'),
      'pkgB': provider.getResource('/pkgB/lib/')
    });
    {
      Uri uri = Uri.parse('package:pkgA/libA.dart');
      Source result = resolver.resolveAbsolute(uri);
      expect(result, isNotNull);
      expect(result.exists(), isTrue);
      expect(result.uriKind, UriKind.PACKAGE_URI);
      expect(result.fullName, pkgFileA);
    }
    {
      Uri uri = Uri.parse('package:pkgB/libB.dart');
      Source result = resolver.resolveAbsolute(uri);
      expect(result, isNotNull);
      expect(result.exists(), isTrue);
      expect(result.uriKind, UriKind.PACKAGE_URI);
      expect(result.fullName, pkgFileB);
    }
  }

  void test_resolve_nonPackage() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('dart:core');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_leadingSlash() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/foo');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_noSlash() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:foo');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_onlySlash() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_notInMap() {
    UriResolver resolver = new PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:analyzer/analyzer.dart');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNotNull);
    expect(result.exists(), isFalse);
    expect(result.fullName, 'package:analyzer/analyzer.dart');
  }
}
