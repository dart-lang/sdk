// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'a_lib.dart';
import 'm_lib.dart';

class B extends A with M {
  B({double d = 2.71}) : super(d: d);
}
