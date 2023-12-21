// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

(T,) wrap<T>(T t) => (t,);

void main() {
  Expect.type<(int,) Function(int)>(wrap<int>);
}
