// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library analyzer.test.generated.source_factory;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SourceFactoryTest);
}

@reflectiveTest
class SourceFactoryTest {
  void test_creation() {
    expect(new SourceFactory([]), isNotNull);
  }

  void test_fromEncoding_invalidUri() {
    SourceFactory factory = new SourceFactory([]);
    expect(() => factory.fromEncoding("<:&%>"),
        throwsA(new isInstanceOf<IllegalArgumentException>()));
  }

  void test_fromEncoding_noResolver() {
    SourceFactory factory = new SourceFactory([]);
    expect(() => factory.fromEncoding("foo:/does/not/exist.dart"),
        throwsA(new isInstanceOf<IllegalArgumentException>()));
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
        new SourceFactory([new UriResolver_nonAbsolute_absolute()]);
    String absolutePath = "/does/not/matter.dart";
    Source containingSource =
        new FileBasedSource(FileUtilities2.createFile("/does/not/exist.dart"));
    Source result = factory.resolveUri(containingSource, absolutePath);
    expect(result.fullName,
        FileUtilities2.createFile(absolutePath).getAbsolutePath());
  }

  void test_resolveUri_nonAbsolute_relative() {
    SourceFactory factory =
        new SourceFactory([new UriResolver_nonAbsolute_relative()]);
    Source containingSource =
        new FileBasedSource(FileUtilities2.createFile("/does/not/have.dart"));
    Source result = factory.resolveUri(containingSource, "exist.dart");
    expect(result.fullName,
        FileUtilities2.createFile("/does/not/exist.dart").getAbsolutePath());
  }

  void test_resolveUri_nonAbsolute_relative_package() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    Context context = provider.pathContext;
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

    PackageMapUriResolver resolver =
        new PackageMapUriResolver(provider, {'package': [libFolder]});
    SourceFactory factory = new SourceFactory([resolver]);
    Source librarySource =
        firstFile.createSource(Uri.parse('package:package/dir/first.dart'));

    Source result = factory.resolveUri(librarySource, 'second.dart');
    expect(result, isNotNull);
    expect(result.fullName, secondPath);
    expect(result.uri.toString(), 'package:package/dir/second.dart');
  }

  void test_restoreUri() {
    JavaFile file1 = FileUtilities2.createFile("/some/file1.dart");
    JavaFile file2 = FileUtilities2.createFile("/some/file2.dart");
    Source source1 = new FileBasedSource(file1);
    Source source2 = new FileBasedSource(file2);
    Uri expected1 = parseUriWithException("file:///my_file.dart");
    SourceFactory factory =
        new SourceFactory([new UriResolver_restoreUri(source1, expected1)]);
    expect(factory.restoreUri(source1), same(expected1));
    expect(factory.restoreUri(source2), same(null));
  }
}

class UriResolver_absolute extends UriResolver {
  bool invoked = false;

  UriResolver_absolute();

  @override
  Source resolveAbsolute(Uri uri) {
    invoked = true;
    return null;
  }
}

class UriResolver_nonAbsolute_absolute extends UriResolver {
  @override
  Source resolveAbsolute(Uri uri) {
    return new FileBasedSource(new JavaFile.fromUri(uri), uri);
  }
}

class UriResolver_nonAbsolute_relative extends UriResolver {
  @override
  Source resolveAbsolute(Uri uri) {
    return new FileBasedSource(new JavaFile.fromUri(uri), uri);
  }
}

class UriResolver_restoreUri extends UriResolver {
  Source source1;
  Uri expected1;
  UriResolver_restoreUri(this.source1, this.expected1);

  @override
  Source resolveAbsolute(Uri uri) => null;

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
  Source resolveAbsolute(Uri uri) {
    if (uri.toString() == encoding) {
      return new TestSource();
    }
    return null;
  }
}
