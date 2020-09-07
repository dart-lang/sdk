// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

@valueClass
class A {}

class B {}

class C extends B with A {} // error, value class as mixin
class D extends A with B {} // error, D extends a value class

main() {}