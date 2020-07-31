// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";

main(List<String> args) {
  final String encoded = base64.encode(args[0].codeUnits);
  print(String.fromCharCodes(base64.decode(encoded)));
}
