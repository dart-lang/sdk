// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String lineLength = '120';

foo({lineLength: lineLength}) {
  print(lineLength);
}

bar({lineLength: lineLength}) async {
  print(lineLength);
}

baz([lineLength = lineLength]) {
  print(lineLength);
}

qux([lineLength = lineLength]) async {
  print(lineLength);
}

main() {
  foo();
  bar();
  baz();
  qux();
}
