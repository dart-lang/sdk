// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// dart2jsOptions=--omit-implicit-checks

import 'package:expect/expect.dart';
import 'dart:_internal' show extractTypeArguments;

main() {
  Expect.equals(int, extractTypeArguments<List>('hello'.codeUnits, <T>() => T));
}
