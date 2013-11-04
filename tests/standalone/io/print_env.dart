// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

main(List<String> arguments) {
  if (!Platform.script.isAbsolute) {
    throw "Platform.script is not absolute: ${Platform.script}";
  }
  print(Platform.environment[arguments[0]]);
}
