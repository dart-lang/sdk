// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {}
mixin Mixin {}

macro class Class1 {}
abstract macro class Class2 {}
macro class Class3 = Super with Mixin;
abstract macro class Class4 = Super with Mixin;

main() {}