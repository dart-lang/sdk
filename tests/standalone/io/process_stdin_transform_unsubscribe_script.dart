// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Utility script to echo stdin to stdout or stderr or both.

import "dart:io";

main() {
  var subscription;
  subscription = stdin
      .transform(new StringDecoder())
      .transform(new LineTransformer())
      .listen((String line) {
          // Unsubscribe after the first line.
          subscription.cancel();
        });
}
