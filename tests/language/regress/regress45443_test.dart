// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class C1<T extends void Function<TT extends T>()> {}

class C2<T extends TT Function<TT extends T>()> {}

main() {
  print("OK");
}
