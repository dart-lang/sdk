// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  List value = const [42];
  if (value case const [42]) {
    print('OK');
  } else {
    throw 'FAIL';
  }
}