// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TranslateUriTest);
  });
}

@reflectiveTest
class TranslateUriTest {
  void test_translate_dart() {
    var translator = new TranslateUri({}, {
      'core': Uri.parse('file:///sdk/core/core.dart'),
      'math': Uri.parse('file:///sdk/math/math.dart')
    });

    expect(translator.translate(Uri.parse('dart:core')),
        Uri.parse('file:///sdk/core/core.dart'));
    expect(translator.translate(Uri.parse('dart:core/string.dart')),
        Uri.parse('file:///sdk/core/string.dart'));

    expect(translator.translate(Uri.parse('dart:math')),
        Uri.parse('file:///sdk/math/math.dart'));

    expect(translator.translate(Uri.parse('dart:unknown')), isNull);
  }
}
