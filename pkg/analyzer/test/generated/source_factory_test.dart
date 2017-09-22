// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.test.generated.source_factory;

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine, Logger;
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' as utils;
import 'package:analyzer/src/source/source_resource.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  runPackageMapTests();
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceFactoryTest);
  });
}

Source createSource({String path, String uri}) =>
    //TODO(pquitslund): find some way to pass an actual URI into source creation
    new MemoryResourceProvider()
        .getFile(path)
        .createSource(uri != null ? Uri.parse(uri) : null);

void runPackageMapTests() {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  final Uri baseUri = new Uri.file('test/base');
  final List<UriResolver> testResolvers = [
    new ResourceUriResolver(resourceProvider)
  ];

  Packages createPackageMap(Uri base, String configFileContents) {
    List<int> bytes = UTF8.encode(configFileContents);
    Map<String, Uri> map = pkgfile.parse(bytes, base);
    return new MapPackages(map);
  }

  Map<String, List<Folder>> getPackageMap(String config) {
    Packages packages = createPackageMap(baseUri, config);
    SourceFactory factory = new SourceFactory(testResolvers, packages);
    return factory.packageMap;
  }

  String resolvePackageUri(
      {String uri,
      String config,
      Source containingSource,
      UriResolver customResolver}) {
    Packages packages = createPackageMap(baseUri, config);
    List<UriResolver> resolvers = testResolvers.toList();
    if (customResolver != null) {
      resolvers.add(customResolver);
    }
    SourceFactory factory = new SourceFactory(resolvers, packages);

    expect(AnalysisEngine.instance.logger, Logger.NULL);
    var logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      Source source = factory.resolveUri(containingSource, uri);
      expect(logger.log, []);
      return source != null ? source.fullName : null;
    } finally {
      AnalysisEngine.instance.logger = Logger.NULL;
    }
  }

  Uri restorePackageUri(
      {Source source, String config, UriResolver customResolver}) {
    Packages packages = createPackageMap(baseUri, config);
    List<UriResolver> resolvers = testResolvers.toList();
    if (customResolver != null) {
      resolvers.add(customResolver);
    }
    SourceFactory factory = new SourceFactory(resolvers, packages);
    return factory.restoreUri(source);
  }

  String _p(String path) => resourceProvider.convertPath(path);

  Uri _u(String path) => resourceProvider.pathContext.toUri(_p(path));

  group('SourceFactoryTest', () {
    group('package mapping', () {
      group('resolveUri', () {
        test('URI in mapping', () {
          String uri = resolvePackageUri(config: '''
unittest:${_u('/home/somebody/.pub/cache/unittest-0.9.9/lib/')}
async:${_u('/home/somebody/.pub/cache/async-1.1.0/lib/')}
quiver:${_u('/home/somebody/.pub/cache/quiver-1.2.1/lib')}
''', uri: 'package:unittest/unittest.dart');
          expect(
              uri,
              equals(_p(
                  '/home/somebody/.pub/cache/unittest-0.9.9/lib/unittest.dart')));
        });
        test('URI not in mapping', () {
          String uri = resolvePackageUri(config: '''
unittest:${_u('/home/somebody/.pub/cache/unittest-0.9.9/lib/')}
async:${_u('/home/somebody/.pub/cache/async-1.1.0/lib/')}
quiver:${_u('/home/somebody/.pub/cache/quiver-1.2.1/lib')}
''', uri: 'package:foo/foo.dart');
          expect(uri, isNull);
        });
        test('Non-package URI', () {
          var testResolver = new CustomUriResolver(uriPath: 'test_uri');
          String uri = resolvePackageUri(config: '''
unittest:${_u('/home/somebody/.pub/cache/unittest-0.9.9/lib/')}
''', uri: 'custom:custom.dart', customResolver: testResolver);
          expect(uri, testResolver.uriPath);
        });
        test('Bad package URI', () {
          String uri = resolvePackageUri(config: '', uri: 'package:foo');
          expect(uri, isNull);
        });
        test('Invalid URI', () {
          // TODO(pquitslund): fix clients to handle errors appropriately
          //   CLI: print message 'invalid package file format'
          //   SERVER: best case tell user somehow and recover...
          expect(
              () => resolvePackageUri(
                  config: 'foo:<:&%>', uri: 'package:foo/bar.dart'),
              throwsA(new isInstanceOf<FormatException>()));
        });
        test('Valid URI that cannot be further resolved', () {
          String uri = resolvePackageUri(
              config: 'foo:http://www.google.com', uri: 'package:foo/bar.dart');
          expect(uri, isNull);
        });
        test('Relative URIs', () {
          Source containingSource = createSource(
              path: _p('/foo/bar/baz/foo.dart'), uri: 'package:foo/foo.dart');
          String uri = resolvePackageUri(
              config: 'foo:${_u('/foo/bar/baz')}',
              uri: 'bar.dart',
              containingSource: containingSource);
          expect(uri, isNotNull);
          expect(uri, equals(_p('/foo/bar/baz/bar.dart')));
        });
      });
      group('restoreUri', () {
        test('URI in mapping', () {
          Uri uri = restorePackageUri(
              config: '''
unittest:${_u('/home/somebody/.pub/cache/unittest-0.9.9/lib/')}
async:${_u('/home/somebody/.pub/cache/async-1.1.0/lib/')}
quiver:${_u('/home/somebody/.pub/cache/quiver-1.2.1/lib')}
''',
              source: new FileSource(resourceProvider.getFile(
                  '/home/somebody/.pub/cache/unittest-0.9.9/lib/unittest.dart')));
          expect(uri, isNotNull);
          expect(uri.toString(), equals('package:unittest/unittest.dart'));
        });
      });
      group('packageMap', () {
        test('non-file URIs filtered', () {
          Map<String, List<Folder>> map = getPackageMap('''
quiver:${_u('/home/somebody/.pub/cache/quiver-1.2.1/lib')}
foo:http://www.google.com
''');
          expect(map.keys, unorderedEquals(['quiver']));
        });
      });
    });
  });

  group('URI utils', () {
    group('URI', () {
      test('startsWith', () {
        expect(utils.startsWith(Uri.parse('/foo/bar/'), Uri.parse('/foo/')),
            isTrue);
        expect(utils.startsWith(Uri.parse('/foo/bar/'), Uri.parse('/foo/bar/')),
            isTrue);
        expect(utils.startsWith(Uri.parse('/foo/bar'), Uri.parse('/foo/b')),
            isFalse);
        // Handle odd URIs (https://github.com/dart-lang/sdk/issues/24126)
        expect(utils.startsWith(Uri.parse('/foo/bar'), Uri.parse('')), isFalse);
        expect(utils.startsWith(Uri.parse(''), Uri.parse('/foo/bar')), isFalse);
      });
    });
  });
}

class AbsoluteUriResolver extends UriResolver {
  final MemoryResourceProvider resourceProvider;

  AbsoluteUriResolver(this.resourceProvider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return new FileSource(
        resourceProvider.getFile(resourceProvider.pathContext.fromUri(uri)),
        actualUri);
  }
}

class CustomUriResolver extends UriResolver {
  String uriPath;
  CustomUriResolver({this.uriPath});

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) =>
      createSource(path: uriPath);
}

@reflectiveTest
class SourceFactoryTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  void test_creation() {
    expect(new SourceFactory([]), isNotNull);
  }

  void test_fromEncoding_invalidUri() {
    SourceFactory factory = new SourceFactory([]);
    expect(() => factory.fromEncoding("<:&%>"), throwsArgumentError);
  }

  void test_fromEncoding_noResolver() {
    SourceFactory factory = new SourceFactory([]);
    expect(() => factory.fromEncoding("foo:/does/not/exist.dart"),
        throwsArgumentError);
  }

  void test_fromEncoding_valid() {
    String encoding = "file:///does/not/exist.dart";
    SourceFactory factory = new SourceFactory(
        [new UriResolver_SourceFactoryTest_test_fromEncoding_valid(encoding)]);
    expect(factory.fromEncoding(encoding), isNotNull);
  }

  void test_resolveUri_absolute() {
    UriResolver_absolute resolver = new UriResolver_absolute();
    SourceFactory factory = new SourceFactory([resolver]);
    factory.resolveUri(null, "dart:core");
    expect(resolver.invoked, isTrue);
  }

  void test_resolveUri_nonAbsolute_absolute() {
    SourceFactory factory =
        new SourceFactory([new AbsoluteUriResolver(resourceProvider)]);
    String sourcePath = resourceProvider.convertPath('/does/not/exist.dart');
    String targetRawPath = '/does/not/matter.dart';
    String targetPath = resourceProvider.convertPath(targetRawPath);
    String targetUri =
        resourceProvider.pathContext.toUri(targetRawPath).toString();
    Source sourceSource = new FileSource(resourceProvider.getFile(sourcePath));
    Source result = factory.resolveUri(sourceSource, targetUri);
    expect(result.fullName, targetPath);
  }

  void test_resolveUri_nonAbsolute_relative() {
    SourceFactory factory =
        new SourceFactory([new AbsoluteUriResolver(resourceProvider)]);
    Source containingSource =
        new FileSource(resourceProvider.getFile("/does/not/have.dart"));
    Source result = factory.resolveUri(containingSource, "exist.dart");
    expect(result.fullName,
        FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath());
  }

  void test_resolveUri_nonAbsolute_relative_package() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    pathos.Context context = provider.pathContext;
    String packagePath =
        context.joinAll([context.separator, 'path', 'to', 'package']);
    String libPath = context.joinAll([packagePath, 'lib']);
    String dirPath = context.joinAll([libPath, 'dir']);
    String firstPath = context.joinAll([dirPath, 'first.dart']);
    String secondPath = context.joinAll([dirPath, 'second.dart']);

    provider.newFolder(packagePath);
    Folder libFolder = provider.newFolder(libPath);
    provider.newFolder(dirPath);
    File firstFile = provider.newFile(firstPath, '');
    provider.newFile(secondPath, '');

    PackageMapUriResolver resolver = new PackageMapUriResolver(provider, {
      'package': [libFolder]
    });
    SourceFactory factory = new SourceFactory([resolver]);
    Source librarySource =
        firstFile.createSource(Uri.parse('package:package/dir/first.dart'));

    Source result = factory.resolveUri(librarySource, 'second.dart');
    expect(result, isNotNull);
    expect(result.fullName, secondPath);
    expect(result.uri.toString(), 'package:package/dir/second.dart');
  }

  void test_restoreUri() {
    File file1 = resourceProvider.getFile("/some/file1.dart");
    File file2 = resourceProvider.getFile("/some/file2.dart");
    Source source1 = new FileSource(file1);
    Source source2 = new FileSource(file2);
    Uri expected1 = Uri.parse("file:///my_file.dart");
    SourceFactory factory =
        new SourceFactory([new UriResolver_restoreUri(source1, expected1)]);
    expect(factory.restoreUri(source1), same(expected1));
    expect(factory.restoreUri(source2), same(null));
  }

  /**
   * Return the [resourceProvider] specific path for the given Posix [path].
   */
  String _p(String path) => resourceProvider.convertPath(path);
}

class UriResolver_absolute extends UriResolver {
  bool invoked = false;

  UriResolver_absolute();

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    invoked = true;
    return null;
  }
}

class UriResolver_restoreUri extends UriResolver {
  Source source1;
  Uri expected1;
  UriResolver_restoreUri(this.source1, this.expected1);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) => null;

  @override
  Uri restoreAbsolute(Source source) {
    if (identical(source, source1)) {
      return expected1;
    }
    return null;
  }
}

class UriResolver_SourceFactoryTest_test_fromEncoding_valid
    extends UriResolver {
  String encoding;
  UriResolver_SourceFactoryTest_test_fromEncoding_valid(this.encoding);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.toString() == encoding) {
      return new TestSource();
    }
    return null;
  }
}
