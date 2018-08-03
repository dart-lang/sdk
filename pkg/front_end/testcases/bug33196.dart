// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

main() {
  var result = returnsString();
  print(result.runtimeType);
}

FutureOr<String> returnsString() async {
  return "oh no";
}
