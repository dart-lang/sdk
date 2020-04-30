// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue41567_lib.dart';

class B extends A {}

class in1 extends out_Object implements B {} // ok

class in2 extends B implements out_Object {} // ok

class in3 extends out_int implements B {} // error

class in4 extends B implements out_int {} // error

main() {}
