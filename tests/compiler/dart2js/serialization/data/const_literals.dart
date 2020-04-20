// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  mapConstLiteral();
  dictionaryConstLiteral();
  listConstLiteral();
  setConstLiteral();
}

mapConstLiteral() => const {0: 1};

dictionaryConstLiteral() => const {'foo': 'bar'};

listConstLiteral() => const ['foo', 'bar'];

setConstLiteral() => const {'foo', 'bar'};
