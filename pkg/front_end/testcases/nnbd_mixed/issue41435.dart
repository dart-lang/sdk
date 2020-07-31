// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7
import 'issue41435_lib.dart';

void main() {
  Null nil;
  x = null;
  x = nil;
  takesNever(null);
  takesNever(nil);
  takesTakesNull(takesNever);
  f = (Never x) {};
}
