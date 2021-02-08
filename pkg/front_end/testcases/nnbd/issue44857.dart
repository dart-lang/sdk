// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F = Never Function(void Function<T extends Never>(T));

void main() {
  const c = F;
  print("Are $c, $F identical?");
  print(identical(c, F));
}
