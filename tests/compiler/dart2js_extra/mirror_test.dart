// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:mirrors';

void main() {
  var now = new DateTime.now();
  InstanceMirror mirror = reflect(now);
  print('now: ${now}');
  print('mirror.type: ${mirror.type}');
  print('now.toUtc(): ${now.toUtc()}');

  var value = mirror.invoke(const Symbol("toUtc"), []);
  print('mirror.invoke("toUtc", []): $value');
  Expect.isTrue(value.hasReflectee);
  Expect.equals(now.toUtc(), value.reflectee);
}
