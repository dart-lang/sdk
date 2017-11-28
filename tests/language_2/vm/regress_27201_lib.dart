// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library import_lib;

final foo = 1;
var someVar = 3;
var _privateVar;

int get someGetter => 2;

void set someSetter(int val) {}

int someFunc() => 0;

class SomeClass {}

typedef int Func(Object a);
