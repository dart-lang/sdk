// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library d;

import 'e.dart' as e;

d() async {
  print("D");
  return e.e();
}
