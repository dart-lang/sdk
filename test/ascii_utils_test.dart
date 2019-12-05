// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/util/ascii_utils.dart';
import 'package:test/test.dart';

void main() {
  group('fileNames', () {
    group('good', () {
      for (var name in goodFileNames) {
        test(name, () {
          expect(isValidDartFileName(name), isTrue);
        });
      }
    });

    group('bad', () {
      for (var name in badFileNames) {
        test(name, () {
          expect(isValidDartFileName(name), isFalse);
        });
      }
    });
  });
}

final badFileNames = [
  'Foo.dart',
  'fooBar.dart',
  '.foo_Bar.dart',
  'F_B.dart',
  'JS.dart',
  'JSON.dart',
];

final goodFileNames = [
  // Generated files.
  'file-system.g.dart',
  'SliderMenu.css.dart',
  '_file.dart',
  '_file.g.dart',
  // Non-strict Dart.
  'bwu_server.shared.datastore.some_file',
  'foo_bar.baz',
  'foo_bar.dart',
  'foo_bar.g.dart',
  'foo_bar',
  'foo.bar',
  'foo_bar_baz',
  'foo',
  'foo_',
  'foo.bar_baz.bang',
  //See: https://github.com/flutter/flutter/pull/1996
  'pointycastle.impl.ec_domain_parameters.gostr3410_2001_cryptopro_a',
  'a.b',
  'a.b.c',
  'p2.src.acme',
  //See: https://github.com/dart-lang/linter/issues/1803
  '_',
  '_f',
  '__f',
  '___f',
  'Foo',
  'fooBar.',
  '.foo_Bar',
  '_.',
  '.',
  'F_B',
  'JS',
  'JSON',
];
