// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Echo library reports its successful creation as an echo response.
library isolate.create.error.helper.echo;

import "dart:isolate";

void main(args, port) {
  for (String s in args) port.send(s);
}
