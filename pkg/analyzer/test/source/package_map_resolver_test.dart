// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_PackageMapUriResolverTest);
  });
}

@reflectiveTest
class _PackageMapUriResolverTest {
  static const Map<String, List<Folder>> EMPTY_MAP = <String, List<Folder>>{};
  MemoryResourceProvider provider = MemoryResourceProvider();

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

  void test_new_null_packageMap() {
    expect(() {
      PackageMapUriResolver(provider, null);
    }, throwsArgumentError);
  }

  void test_new_null_resourceProvider() {
    expect(() {
      PackageMapUriResolver(null, <String, List<Folder>>{});
    }, throwsArgumentError);
  }

  void test_resolve_multiple_folders() {
    var a = provider.newFile(provider.convertPath('/aaa/a.dart'), '');
    var b = provider.newFile(provider.convertPath('/bbb/b.dart'), '');
    expect(() {
      PackageMapUriResolver(provider, <String, List<Folder>>{
        'pkg': <Folder>[a.parent, b.parent]
      });
    }, throwsArgumentError);
  }

  void test_resolve_nonPackage() {
    UriResolver resolver = PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('dart:core');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_OK() {
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[provider.getResource(provider.convertPath('/pkgA/lib'))],
      'pkgB': <Folder>[provider.getResource(provider.convertPath('/pkgB/lib'))]
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

  void test_resolve_OK_withNonAscii() {
    var resolver = PackageMapUriResolver(provider, {
      'aaa': <Folder>[
        provider.getFolder(
          provider.convertPath('/packages/aaa/lib'),
        ),
      ],
    });

    var uri = Uri.parse('package:aaa/проба/a.dart');
    var result = resolver.resolveAbsolute(uri);
    expect(
      result.fullName,
      provider.convertPath('/packages/aaa/lib/проба/a.dart'),
    );
  }

  void test_resolve_OK_withSpace() {
    var resolver = PackageMapUriResolver(provider, {
      'aaa': <Folder>[
        provider.getFolder(
          provider.convertPath('/packages/aaa/lib'),
        ),
      ],
    });

    var uri = Uri.parse('package:aaa/with space/a.dart');
    var result = resolver.resolveAbsolute(uri);
    expect(
      result.fullName,
      provider.convertPath('/packages/aaa/lib/with space/a.dart'),
    );
  }

  void test_resolve_package_invalid_leadingSlash() {
    UriResolver resolver = PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/foo');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_noSlash() {
    UriResolver resolver = PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:foo');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_invalid_onlySlash() {
    UriResolver resolver = PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:/');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_resolve_package_notInMap() {
    UriResolver resolver = PackageMapUriResolver(provider, EMPTY_MAP);
    Uri uri = Uri.parse('package:analyzer/analyzer.dart');
    Source result = resolver.resolveAbsolute(uri);
    expect(result, isNull);
  }

  void test_restoreAbsolute() {
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/src/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[provider.getResource(provider.convertPath('/pkgA/lib'))],
      'pkgB': <Folder>[provider.getResource(provider.convertPath('/pkgB/lib'))]
    });
    {
      Source source =
          _createFileSource(provider.convertPath('/pkgA/lib/libA.dart'));
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNotNull);
      expect(uri.toString(), 'package:pkgA/libA.dart');
    }
    {
      Source source =
          _createFileSource(provider.convertPath('/pkgB/lib/src/libB.dart'));
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNotNull);
      expect(uri.toString(), 'package:pkgB/src/libB.dart');
    }
    {
      Source source = _createFileSource('/no/such/file');
      Uri uri = resolver.restoreAbsolute(source);
      expect(uri, isNull);
    }
  }

  Source _createFileSource(String path) {
    return NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }
}
