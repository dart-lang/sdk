// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_mixin`

import 'dart:collection';

import 'dart:convert';

class A {}

class B extends Object with A {} // LINT

mixin M {}

class C with M {} // OK

abstract class I with IterableMixin {} //OK

abstract class L with ListMixin {} //OK

abstract class MM with MapMixin {} //OK

abstract class S with SetMixin {} //OK

abstract class SCS with StringConversionSinkMixin {} //OK

// nonfunction-type-aliases

typedef AA = A;

abstract class CC with AA { } // LINT

typedef AAA = M;

abstract class CCC with AAA { } //OK
