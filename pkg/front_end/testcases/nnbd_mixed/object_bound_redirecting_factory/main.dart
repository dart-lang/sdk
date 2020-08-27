// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

import 'opt_in_lib.dart';

class Class {}

class XToken extends Token {
  const XToken();
}

const list = [
  CP(Class),
  VP.forToken(XToken(), 'Hello World'),
];

const m = M(list: list);

main() {}
