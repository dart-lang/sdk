// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.source_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:package_config/packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceFactoryImplTest);
  });
}

@reflectiveTest
class SourceFactoryImplTest extends AbstractContextTest {
  void test_restoreUri() {
    String libPath = resourceProvider.convertPath('/pkgs/somepkg/lib/');
    Uri libUri = resourceProvider.getFolder(libPath).toUri();
    Map<String, Uri> packageUriMap = <String, Uri>{'foo': libUri};
    SourceFactoryImpl sourceFactory = new SourceFactoryImpl(
      <UriResolver>[new ResourceUriResolver(resourceProvider)],
      new _MockPackages(packageUriMap),
    );
    Source libSource = newSource('/pkgs/somepkg/lib');
    Uri uri = sourceFactory.restoreUri(libSource);
    try {
      expect(uri, Uri.parse('package:foo/'));
    } catch (e) {
      print('=== debug info ===');
      print('libPath: $libPath');
      print('libUri: $libUri');
      print('libSource: ${libSource?.fullName}');
      rethrow;
    }
  }
}

/**
 * An implementation of [Packages] used for testing.
 */
class _MockPackages implements Packages {
  final Map<String, Uri> map;

  _MockPackages(this.map);

  @override
  Iterable<String> get packages => map.keys;

  @override
  Map<String, Uri> asMap() => map;

  @override
  Uri resolve(Uri packageUri, {Uri notFound(Uri packageUri)}) {
    fail('Unexpected invocation of resolve');
    return null;
  }
}
