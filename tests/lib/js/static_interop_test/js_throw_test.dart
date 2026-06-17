// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

@JS()
external void eval(String code);

@JS()
external JSAny? catchAndReturn(JSFunction f);

void main() {
  eval('''
    globalThis.catchAndReturn = function(f) {
      try {
        f();
      } catch (error) {
        return error;
      }
    }
  ''');

  Expect.equals(
    'foo'.toJS,
    catchAndReturn((() => jsThrow('foo'.toJS)).toJS),
  );
  final caughtError = JSError.asError(
    catchAndReturn((() => jsThrow(JSError('foo'))).toJS),
  );
  Expect.equals('foo', caughtError?.message);
}
