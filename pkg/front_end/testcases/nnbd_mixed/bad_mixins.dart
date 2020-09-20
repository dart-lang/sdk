// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

import 'bad_mixins_lib.dart';

class Class1a extends Object with MixinA {} // error

class Class1b extends A with MixinA {} // ok

class Class2a extends Object with MixinB<int> {} // error

class Class2c extends B<num> with MixinB<int> {} // error

class Class2d extends B<int> with MixinB<int> {} // ok

class Class2e extends B<Object> with MixinB<dynamic> {} // error

class Class3a extends Object with MixinC<num, int> {} // error

class Class3b extends C<num, num> with MixinC<num, int> {} // error

class Class3d extends C<num, int> with MixinC<num, int> {} // ok

class Class4a extends ClassBa with MixinB<int> {} // ok

class Class4b extends ClassBb with MixinB<int> {} // ok

class Class5a extends ClassCa with MixinC<num, int> {} // ok

class Class5b extends ClassCb with MixinC<num, int> {} // ok

main() {}
