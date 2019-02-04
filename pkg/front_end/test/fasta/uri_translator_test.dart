// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:package_config/packages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriTranslatorImplTest);
  });
}

@reflectiveTest
class UriTranslatorImplTest {
  UriTranslator translator = new UriTranslator(
      new TargetLibrariesSpecification('vm', {
        'core': new LibraryInfo('core',
            Uri.parse('org-dartlang-test:///sdk/core/core.dart'), const []),
        'math': new LibraryInfo('core',
            Uri.parse('org-dartlang-test:///sdk/math/math.dart'), const []),
      }),
      Packages.noPackages);

  void test_isPlatformImplementation() {
    bool isPlatform(String uriStr) {
      var uri = Uri.parse(uriStr);
      return translator.isPlatformImplementation(uri);
    }

    expect(isPlatform('dart:core/string.dart'), isTrue);
    expect(isPlatform('dart:core'), isFalse);
    expect(isPlatform('dart:_builtin'), isTrue);
    expect(isPlatform('org-dartlang-test:///sdk/math/math.dart'), isFalse);
  }

  void test_translate_dart() {
    expect(translator.translate(Uri.parse('dart:core')),
        Uri.parse('org-dartlang-test:///sdk/core/core.dart'));
    expect(translator.translate(Uri.parse('dart:core/string.dart')), null);

    expect(translator.translate(Uri.parse('dart:math')),
        Uri.parse('org-dartlang-test:///sdk/math/math.dart'));
  }
}
