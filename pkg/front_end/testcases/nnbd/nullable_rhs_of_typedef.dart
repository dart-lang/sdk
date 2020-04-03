// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F = void Function()?;

void foo(void Function() x) {
  bar(x);
  bar(null);

  baz(x);
  baz(null);
}

void bar(F x) {}
void baz(F? x) {}

main() {}
