// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class MultipleConstructors {
  final bool foo;
  MultipleConstructors(this.foo);
  MultipleConstructors.named(this.foo);
}

mixin class SingleConstructor {
  final bool foo;
  SingleConstructor.named(this.foo);
}

class NoErrorWithMixinClass with SingleConstructor {}

class NoErrorWithMixinClass2 with MultipleConstructors {}
