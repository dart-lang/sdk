// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef T G<T>(T t);

test() {
  T local<T extends num>(T t) => t;
  local("");
  local<String>(throw '');
  local(0);
  local<int>(throw '');
  local<int, String>(throw '');
  var f = local;
  f("");
  f<String>(throw '');
  f(0);
  f<int>(throw '');
  f<int, String>(throw '');
}

main() {}
