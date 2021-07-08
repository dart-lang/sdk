// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ConcreteClass {}
abstract class AbstractClass {}
mixin Mixin {}
class NamedMixinApplication = Object with Mixin;
abstract class AbstractNamedMixinApplication = Object with Mixin;
extension Extension on int {}

test() {
  ConcreteClass.new; // ok
  AbstractClass.new; // error
  Mixin.new; // error
  NamedMixinApplication.new; // ok
  AbstractNamedMixinApplication.new; // error
  Extension.new; // error
}

main() {}