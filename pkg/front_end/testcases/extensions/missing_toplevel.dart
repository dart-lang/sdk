// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  void set setter(int value) {}
}

var c = new Class();

var missingGetter = c.setter += 42;

main() {}
