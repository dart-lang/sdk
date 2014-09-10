// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test making sure we don't create an empty snapshot file when there
// is an error in the script.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";


main() {
  // Try to generate a snapshot.
  File thisscript = new File.fromUri(Platform.script);
  Directory dir = thisscript.parent;
  String snapshot = "${dir.path}/dummy.snapshot";
  String script = "${dir.path}/snapshot_fail_script.dart";
  var pr = Process.runSync(Platform.executable,
      ["--snapshot=$snapshot", script]);

  // There should be no dummy.snapshot file created.
  File dummy = new File(snapshot);
  bool exists = dummy.existsSync();
  if (exists) {
    dummy.deleteSync();
  }
  Expect.isFalse(exists);
}
