// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:test';

test() {
  new Class1a();
  new Class1b();
  SuperClass c2a = new Class2a();
  SuperClass c2b = new Class2b();
  Interface c3a = new Class3a();
  Interface c3b = new Class3b();
  Mixin c4a = new Class4a();
  Mixin c4b = new Class4b();
}
