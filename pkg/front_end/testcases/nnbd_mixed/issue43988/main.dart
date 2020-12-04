// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'main_lib.dart';

class E1 with A, D {}

class E2 = Object with A, D;

abstract class C6 extends C3 implements C4 {}

abstract class C8 extends C5 implements C7 {}

main() {}
