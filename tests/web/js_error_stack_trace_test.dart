// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
external void throwError();

@JS()
external void throwNonError();

void main() {
  eval('''
    self.throwNonError = function() {
      throw 'Hi from JS';
    }

    self.throwError = function() {
      throw new Error('Hi from JS');
    }
  ''');

  try {
    throwError();
  } catch (e, st) {
    Expect.isTrue(e.toString().contains('Hi from JS'));
    Expect.isTrue(st.toString().isNotEmpty);
  }

  try {
    throwNonError();
  } catch (e, st) {
    Expect.isTrue(e.toString().contains('Hi from JS'));
    Expect.isTrue(st.toString().isEmpty);
  }
}
