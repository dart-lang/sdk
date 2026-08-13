// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/config.dart';

@JS('location.href')
external JSString? get locationHref;

void main() {
  final String? nullableHref = locationHref?.toDart;

  Expect.isNotNull(nullableHref);
  final String href = nullableHref!;
  print('location.href = $href');

  if (isBrowserConfiguration) {
    Expect.isTrue(href.startsWith('http://'));
    Expect.isTrue(href.contains('/test.html'));
  } else {
    Expect.isTrue(href.startsWith('file://'));
    Expect.isTrue(href.endsWith('.wasm'));
  }
}
