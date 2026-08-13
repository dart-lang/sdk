// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method() {
  var ([double v1] && [num v2]) = [42];
  print(v1);
  print(v2);
}
