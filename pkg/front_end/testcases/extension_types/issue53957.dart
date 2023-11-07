// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type Ext(Object? _) {
  int get value => 42;
}

void main() {
  if (Ext("") case Ext(:var value)) print(value);
}