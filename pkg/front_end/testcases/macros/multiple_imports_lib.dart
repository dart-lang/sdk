// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Const(0)
import 'dart:math';
@Const(1)
import 'dart:convert';

method() {
  new Random();
  json.encoder;
}

class Const {
  final int field;

  const Const(this.field);
}
