// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceFactoryTest);
  });
}

Source createSource({String path, String uri}) =>
    //TODO(pquitslund): find some way to pass an actual URI into source creation
    MemoryResourceProvider()
        .getFile(path)
        .createSource(uri != null ? Uri.parse(uri) : null);

class AbsoluteUriResolver extends UriResolver {
  final MemoryResourceProvider resourceProvider;

  AbsoluteUriResolver(this.resourceProvider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    return FileSource(
        resourceProvider.getFile(resourceProvider.pathContext.fromUri(uri)),
        actualUri);
  }
}

@reflectiveTest
class SourceFactoryTest with ResourceProviderMixin {
  void test_creation() {
    expect(SourceFactory([]), isNotNull);
  }

  void test_resolveUri_absolute() {
    UriResolver_absolute resolver = UriResolver_absolute();
    SourceFactory factory = SourceFactory([resolver]);
    factory.resolveUri(null, "dart:core");
    expect(resolver.invoked, isTrue);
  }

  void test_resolveUri_nonAbsolute_absolute() {
    SourceFactory factory =
        SourceFactory([AbsoluteUriResolver(resourceProvider)]);
    String sourcePath = convertPath('/does/not/exist.dart');
    String targetRawPath = '/does/not/matter.dart';
    String targetPath = convertPath(targetRawPath);
    String targetUri = toUri(targetRawPath).toString();
    Source sourceSource = FileSource(getFile(sourcePath));
    Source result = factory.resolveUri(sourceSource, targetUri);
    expect(result.fullName, targetPath);
  }

  void test_resolveUri_nonAbsolute_relative() {
    SourceFactory factory =
        SourceFactory([AbsoluteUriResolver(resourceProvider)]);
    Source containingSource = FileSource(getFile('/does/not/have.dart'));
    Source result = factory.resolveUri(containingSource, 'exist.dart');
    expect(result.fullName, convertPath('/does/not/exist.dart'));
  }

  void test_resolveUri_nonAbsolute_relative_package() {
    MemoryResourceProvider provider = MemoryResourceProvider();
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

    PackageMapUriResolver resolver = PackageMapUriResolver(provider, {
      'package': [libFolder]
    });
    SourceFactory factory = SourceFactory([resolver]);
    Source librarySource =
        firstFile.createSource(Uri.parse('package:package/dir/first.dart'));

    Source result = factory.resolveUri(librarySource, 'second.dart');
    expect(result, isNotNull);
    expect(result.fullName, secondPath);
    expect(result.uri.toString(), 'package:package/dir/second.dart');
  }

  void test_restoreUri() {
    File file1 = getFile("/some/file1.dart");
    File file2 = getFile("/some/file2.dart");
    Source source1 = FileSource(file1);
    Source source2 = FileSource(file2);
    Uri expected1 = Uri.parse("file:///my_file.dart");
    SourceFactory factory =
        SourceFactory([UriResolver_restoreUri(source1, expected1)]);
    expect(factory.restoreUri(source1), same(expected1));
    expect(factory.restoreUri(source2), same(null));
  }
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
      return TestSource();
    }
    return null;
  }
}
