// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test `dart:js_interop`'s `isA` method with cross-realm and mock arrays.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS('iframeArray')
external JSAny get iframeArray;

@JS('mockArray')
external JSAny get mockArray;

void main() {
  eval('''
      // Create an array in another realm (within an iframe) and verify that it 
      // passes isA<JSArray>.
      const iframe = document.createElement('iframe');
      document.body.appendChild(iframe);
      globalThis.iframeArray = iframe.contentWindow.eval('[]');

      // Create a mock array object that has Array.prototype in its 
      // prototype chain
      // and verify that it passes isA<JSArray>.
      globalThis.mockArray = Object.create(Array.prototype);
    ''');

  Expect.isTrue(iframeArray.isA<JSArray>());
  Expect.isTrue(iframeArray.isA<JSArray?>());
  Expect.isTrue(mockArray.isA<JSArray>());
  Expect.isTrue(mockArray.isA<JSArray?>());
}
