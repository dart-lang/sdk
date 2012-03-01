// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Utility script to echo stdin to stdout or stderr or both.

#import("dart:io");

main() {
  var options = new Options();
  if (options.arguments.length > 0) {
    if (options.arguments[0] == "0") {
      stdin.onData = () => stdout.write(stdin.read());
    } else if (options.arguments[0] == "1") {
      stdin.onData = () => stderr.write(stdin.read());
    } else if (options.arguments[0] == "2") {
      stdin.onData = () {
        var data = stdin.read();
        stdout.write(data);
        stderr.write(data);
      };
    }
  }
}
