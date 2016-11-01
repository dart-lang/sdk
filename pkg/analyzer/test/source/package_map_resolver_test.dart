// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.package_map_resolver_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/source.dart';
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
  static const Map<String, List<Folder>> EMPTY_MAP =
      const <String, List<Folder>>{};
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

  void test_new_null_packageMap() {
    expect(() {
      new PackageMapUriResolver(provider, null);
    }, throws);
  }

  void test_new_null_resourceProvider() {
    expect(() {
      new PackageMapUriResolver(null, <String, List<Folder>>{});
    }, throws);
  }

  void test_resolve_multiple_folders() {
    String pkgFileA = provider.convertPath('/part1/lib/libA.dart');
    String pkgFileB = provider.convertPath('/part2/lib/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a');
    provider.newFile(pkgFileB, 'library lib_b');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkg': <Folder>[
        provider.getResource(provider.convertPath('/part1/lib/')),
        provider.getResource(provider.convertPath('/part2/lib/'))
      ]
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
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[
        provider.getResource(provider.convertPath('/pkgA/lib/'))
      ],
      'pkgB': <Folder>[provider.getResource(provider.convertPath('/pkgB/lib/'))]
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
    expect(result.fullName, 'analyzer.dart');
    expect(result.uri.toString(), 'package:analyzer/analyzer.dart');
  }

  void test_restoreAbsolute() {
    String pkgFileA = provider.convertPath('/pkgA/lib/libA.dart');
    String pkgFileB = provider.convertPath('/pkgB/lib/src/libB.dart');
    provider.newFile(pkgFileA, 'library lib_a;');
    provider.newFile(pkgFileB, 'library lib_b;');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkgA': <Folder>[
        provider.getResource(provider.convertPath('/pkgA/lib/'))
      ],
      'pkgB': <Folder>[provider.getResource(provider.convertPath('/pkgB/lib/'))]
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

  void test_restoreAbsolute_ambiguous() {
    String file1 = provider.convertPath('/foo1/lib/bar.dart');
    String file2 = provider.convertPath('/foo2/lib/bar.dart');
    provider.newFile(file1, 'library bar');
    provider.newFile(file2, 'library bar');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'foo': <Folder>[
        provider.getResource(provider.convertPath('/foo1/lib')),
        provider.getResource(provider.convertPath('/foo2/lib'))
      ]
    });
    // Restoring file1 should yield a package URI, and that package URI should
    // resolve back to file1.
    Source source1 = _createFileSource(file1);
    Uri uri1 = resolver.restoreAbsolute(source1);
    expect(uri1.toString(), 'package:foo/bar.dart');
    expect(resolver.resolveAbsolute(uri1).fullName, file1);
    // Restoring file2 should not yield a package URI, because there is no URI
    // that resolves to file2.
    Source source2 = _createFileSource(file2);
    expect(resolver.restoreAbsolute(source2), isNull);
  }

  void test_restoreAbsolute_longestMatch() {
    String file1 = provider.convertPath('/foo1/bar1/lib.dart');
    String file2 = provider.convertPath('/foo2/bar2/lib.dart');
    provider.newFile(file1, 'library lib');
    provider.newFile(file2, 'library lib');
    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, <String, List<Folder>>{
      'pkg1': <Folder>[
        provider.getResource(provider.convertPath('/foo1')),
        provider.getResource(provider.convertPath('/foo2/bar2'))
      ],
      'pkg2': <Folder>[
        provider.getResource(provider.convertPath('/foo1/bar1')),
        provider.getResource(provider.convertPath('/foo2'))
      ]
    });
    // Restoring file1 should yield a package URI for pkg2, since pkg2's match
    // for the file path (/foo1/bar1) is longer than pkg1's match (/foo1).
    Source source1 = _createFileSource(file1);
    Uri uri1 = resolver.restoreAbsolute(source1);
    expect(uri1.toString(), 'package:pkg2/lib.dart');
    // Restoring file2 should yield a package URI for pkg1, since pkg1's match
    // for the file path (/foo2/bar2) is longer than pkg2's match (/foo2).
    Source source2 = _createFileSource(file2);
    Uri uri2 = resolver.restoreAbsolute(source2);
    expect(uri2.toString(), 'package:pkg1/lib.dart');
  }

  Source _createFileSource(String path) {
    return new NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }
}
