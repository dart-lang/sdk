// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source.package_map_resolver;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  group('PackageMapUriResolverTest', () {
    test('isPackageUri', () {
      new _PackageMapUriResolverTest().test_isPackageUri();
    });
    test('isPackageUri_null_scheme', () {
      new _PackageMapUriResolverTest().test_isPackageUri_null_scheme();
    });
    test('isPackageUri_other_scheme', () {
      new _PackageMapUriResolverTest().test_isPackageUri_other_scheme();
    });
    test('resolve_multiple_folders', () {
      new _PackageMapUriResolverTest().test_resolve_multiple_folders();
    });
    test('resolve_nonPackage', () {
      new _PackageMapUriResolverTest().test_resolve_nonPackage();
    });
    test('resolve_OK', () {
      new _PackageMapUriResolverTest().test_resolve_OK();
    });
    test('resolve_package_invalid_leadingSlash', () {
      var inst = new _PackageMapUriResolverTest();
      inst.test_resolve_package_invalid_leadingSlash();
    });
    test('resolve_package_invalid_noSlash', () {
      new _PackageMapUriResolverTest().test_resolve_package_invalid_noSlash();
    });
    test('resolve_package_invalid_onlySlash', () {
      new _PackageMapUriResolverTest().test_resolve_package_invalid_onlySlash();
    });
    test('resolve_package_notInMap', () {
      new _PackageMapUriResolverTest().test_resolve_package_notInMap();
    });
    test('restoreAbsolute_OK', () {
      new _PackageMapUriResolverTest().test_restoreAbsolute();
    });
  });
}


class _PackageMapUriResolverTest {
  static const Map EMPTY_MAP = const <String, List<Folder>>{};
  MemoryResourceProvider provider = new MemoryResourceProvider();

  void test_isPackageUri() {
    Uri uri = Uri.parse('package:test/test.dart');
    expect(uri.scheme, 'package');
    expect(PackageMapUriResolver.isPackageUri(uri), isTrue);
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

  void test_resolve_multiple_folders() {
    const pkgFileA = '/part1/lib/libA.dart';
    const pkgFileB = '/part2/lib/libB.dart';
    provider.newFile(pkgFileA, 'library lib_a');
    provider.newFile(pkgFileB, 'library lib_b');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkg': [
          provider.getResource('/part1/lib/'),
          provider.getResource('/part2/lib/')]
    });
    {
      Uri uri = Uri.parse('package:pkg/libA.dart');
      Source result = resolver.resolveAbsolute(uri);
      expect(result, isNotNull);
      expect(result.exists(), isTrue);
      expect(result.uriKind, UriKind.PACKAGE_URI);
      expect(result.fullName, pkgFileA);
    }
    {
      Uri uri = Uri.parse('package:pkg/libB.dart');
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

  void test_resolve_OK() {
    const pkgFileA = '/pkgA/lib/libA.dart';
    const pkgFileB = '/pkgB/lib/libB.dart';
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': [provider.getResource('/pkgA/lib/')],
      'pkgB': [provider.getResource('/pkgB/lib/')]
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

  void test_restoreAbsolute() {
    const pkgFileA = '/pkgA/lib/libA.dart';
    const pkgFileB = '/pkgB/lib/src/libB.dart';
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': [provider.getResource('/pkgA/lib/')],
      'pkgB': [provider.getResource('/pkgB/lib/')]
    });
    {
      Source source = _createFileSource('/pkgA/lib/libA.dart');
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNotNull);
      expect(uri.path, 'package:pkgA/libA.dart');
    }
    {
      Source source = _createFileSource('/pkgB/lib/src/libB.dart');
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNotNull);
      expect(uri.path, 'package:pkgB/src/libB.dart');
    }
    {
      Source source = _createFileSource('/no/such/file');
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNull);
    }
  }

  Source _createFileSource(String path) {
    return new NonExistingSource(path, UriKind.FILE_URI);
  }
}
