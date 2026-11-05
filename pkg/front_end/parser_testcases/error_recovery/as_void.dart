// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void expression(Object value) {
  value as void;
}

void pattern(Object value) {
  if (value case _ as void) {}
}

void functionType(Object value) {
  value as void Function();
  if (value case _ as void Function()) {}
}

class InvalidSupertype extends void {}
