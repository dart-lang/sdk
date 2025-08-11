// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/utilities/extensions/uri.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriExtensionTest);
  });
}

@reflectiveTest
class UriExtensionTest {
  void test_isImplementation_packageScheme_insideSrc() {
    expect(Uri.parse('package:foo/src/foo.dart').isImplementation, isTrue);
  }

  void test_isImplementation_packageScheme_outsideSrc() {
    expect(Uri.parse('package:foo/foo.dart').isImplementation, isFalse);
  }

  void test_isImplementation_relative() {
    expect(Uri.parse('foo.dart').isImplementation, isFalse);
  }

  void test_samePackage_nonPackageScheme() {
    expect(
      Uri.parse(
        'file://foo/foo.dart',
      ).isSamePackageAs(Uri.parse('package:foo/bar.dart')),
      isFalse,
    );
  }

  void test_samePackage_packageScheme_notSame() {
    expect(
      Uri.parse(
        'package:foo/foo.dart',
      ).isSamePackageAs(Uri.parse('package:bar/bar.dart')),
      isFalse,
    );
  }

  void test_samePackage_packageScheme_same() {
    expect(
      Uri.parse(
        'package:foo/foo.dart',
      ).isSamePackageAs(Uri.parse('package:foo/bar.dart')),
      isTrue,
    );
  }
}
