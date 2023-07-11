// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that generic function invocations have their default type arguments
// resolved in a dynamic call when the type argument is a JS entity.

void main() {
  dynamic arrayLiteral = [];
  arrayLiteral.map((v) => '$v');
}
