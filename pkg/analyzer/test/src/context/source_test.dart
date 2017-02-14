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
    Map<String, Uri> packageUriMap = <String, Uri>{
      'foo': Uri.parse('file:///pkgs/somepkg/lib/')
    };
    SourceFactoryImpl sourceFactory = new SourceFactoryImpl(
      <UriResolver>[new ResourceUriResolver(resourceProvider)],
      new _MockPackages(packageUriMap),
    );
    Uri uri = sourceFactory.restoreUri(newSource('/pkgs/somepkg/lib'));
    // TODO(danrubel) fix on Windows
    if (resourceProvider.absolutePathContext.separator != r'\') {
      expect(uri, Uri.parse('package:foo/'));
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
