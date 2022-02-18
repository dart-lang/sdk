// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {}
mixin Mixin {}

augment class Class1 {}
abstract augment class Class2 {}
augment class Class3 = Super with Mixin;
abstract augment class Class4 = Super with Mixin;

main() {}