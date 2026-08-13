// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<T> sideEffect<T>(List<T> list) {
  print(T);
  return list;
}

method() {
  var [...] = sideEffect([]);
  [...] = sideEffect([]);
  if (sideEffect([]) case [...]) {
    print(true);
  }
  switch (sideEffect([])) {
    case [...]:
  }
  return switch (sideEffect([])) {
    [...] => true,
  };
}
