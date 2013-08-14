// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:async";

main() {
  new Timer(new Duration(seconds: 2), () {
    new Directory(new Options().arguments[0]).delete(recursive: true);
  });
}
