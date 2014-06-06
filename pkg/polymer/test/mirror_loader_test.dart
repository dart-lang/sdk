// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'dart:mirrors';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'package:polymer/src/mirror_loader.dart';
/// prevent unused import warnings: [m1.XA] [m2.XA] [m3.XB] [m4.XA].
import 'mirror_loader_1.dart' as m1;
import 'mirror_loader_2.dart' as m2;
import 'mirror_loader_3.dart' as m3;
import 'mirror_loader_4.dart' as m4;

main() {
  useHtmlConfiguration();

  test('registered correctly', () {
    expect(_discover(#mirror_loader_test1).length, 1);
    expect(_discover(#mirror_loader_test2).length, 1);
  });

  test('parameterized custom tags are not registered', () {
    runZoned(() {
      expect(_discover(#mirror_loader_test3).length, 0);
    }, onError: (e) {
      expect(e is UnsupportedError, isTrue);
      expect('$e', contains(
          'Custom element classes cannot have type-parameters: XB'));
    });
  });

  test('registers correct types even when errors are found', () {
    runZoned(() {
      expect(_discover(#mirror_loader_test4).length, 1);
    }, onError: (e) {
      expect(e is UnsupportedError, isTrue);
      expect('$e', contains(
          'Custom element classes cannot have type-parameters: XB'));
    });
  });
}

final mirrors = currentMirrorSystem();
_discover(Symbol name) =>
    discoverInitializers([mirrors.findLibrary(name).uri.toString()]);
