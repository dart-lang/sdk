// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B<T> {}

class C<T, S extends T> {}

mixin MixinA on A {}

mixin MixinB<T> on B<T> {}

mixin MixinC<T, S extends T> on C<T, S> {}

class Class1a extends Object with MixinA {} // error

class Class1b extends A with MixinA {} // ok

class Class2a extends Object with MixinB<int> {} // error

class Class2b extends B<int?> with MixinB<int> {} // error

class Class2c extends B<num> with MixinB<int> {} // error

class Class2d extends B<int> with MixinB<int> {} // ok

class Class2e extends B<Object> with MixinB<dynamic> {} // error

class Class2f extends B<Object?> with MixinB<dynamic> {} // ok

class Class3a extends Object with MixinC<num, int> {} // error

class Class3b extends C<num, num> with MixinC<num, int> {} // error

class Class3c extends C<num?, int> with MixinC<num, int> {} // error

class Class3d extends C<num, int> with MixinC<num, int> {} // ok

class ClassBa extends B<int?> {}

class ClassBb extends B<int> {}

class ClassCa extends C<num?, int?> {}

class ClassCb extends C<num?, int> {}

class Class4a extends ClassBa with MixinB<int> {} // error

class Class4b extends ClassBa with MixinB<int?> {} // ok

class Class4c extends ClassBb with MixinB<int?> {} // error

class Class4d extends ClassBb with MixinB<int> {} // ok

class Class5a extends ClassCa with MixinC<num?, int> {} // error

class Class5b extends ClassCa with MixinC<num?, int?> {} // ok

class Class5c extends ClassCb with MixinC<num?, int?> {} // error

class Class5d extends ClassCb with MixinC<num?, int> {} // ok
