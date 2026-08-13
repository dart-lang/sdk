// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E<T> on Set<T> {
  int get property => 0;
  set property(int value) {}
  int method() => 0;
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

main() {
  E({}).property;
  E({}).property = 0;
  E({}).method;
  E({}).method();
  E({}).property += 0;
  E({}).property ??= 0;
  E({})[0];
  E({})[0] = 0;
  E({})[0] += 0;
  E({})[0] ??= 0;

  E({})?.property;
  E({})?.property = 0;
  E({})?.method;
  E({})?.method();
  E({})?.property += 0;
  E({})?.property ??= 0;
  E({})?[0];
  E({})?[0] = 0;
  E({})?[0] += 0;
  E({})?[0] ??= 0;

  E<int>({}).property;
  E<int>({}).property = 0;
  E<int>({}).method;
  E<int>({}).method();
  E<int>({}).property += 0;
  E<int>({}).property ??= 0;
  E<int>({})[0];
  E<int>({})[0] = 0;
  E<int>({})[0] += 0;
  E<int>({})[0] ??= 0;

  E<int>({})?.property;
  E<int>({})?.property = 0;
  E<int>({})?.method;
  E<int>({})?.method();
  E<int>({})?.property += 0;
  E<int>({})?.property ??= 0;
  E<int>({})?[0];
  E<int>({})?[0] = 0;
  E<int>({})?[0] += 0;
  E<int>({})?[0] ??= 0;
}
