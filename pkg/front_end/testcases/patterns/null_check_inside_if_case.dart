// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  if (x case var y?) {}
  if (x case int y?) {}
}

test2(num x) {
  if (x case var y?) {}
  if (x case int y?) {}
  if (x case String y?) {}
}
