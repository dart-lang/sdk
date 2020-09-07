// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

@valueClass
class A {}

class B {}

class C {}

class D = A with B;
class E = B with A;

@valueClass
class F = B with C;

main() {}