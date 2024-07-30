// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that GC doesn't crash due to an incorrect stack map
// for spilled exception/stack trace variables which are live only
// after entering catch block.
// Regression test for https://github.com/dart-lang/sdk/issues/55442.

import "dart:io";
import "dart:isolate";

class ExpectException {
  final String message;
  final String name;

  ExpectException(this.message) : name = "";

  @override
  String toString() {
    if (name != "") return 'In test "$name" $message';
    return message;
  }
}

class Expect {
  static void testError(String message) {
    _fail("Test error: $message");
  }

  static String _getMessage(String reason) =>
      reason.isEmpty ? "" : ", '$reason'";

  static Never _fail(String message) {
    throw ExpectException(message);
  }

  static T throws<T extends Object>(void Function() computation,
      [bool Function(T error)? check, String reason = ""]) {
    try {
      computation();
    } catch (e, s) {
      // A test failure doesn't count as throwing, and can't be expected.
      if (e is ExpectException) rethrow;
      if (e is T && (check == null || check(e))) return e;
      // Throws something unexpected.
      String msg = _getMessage(reason);
      String type = "";
      if (T != dynamic && T != Object) {
        type = "<$T>";
      }
      _fail("Expect.throws$type$msg: "
          "Unexpected '${Error.safeToString(e)}'\n$s");
    }
    _fail('Expect.throws${_getMessage(reason)} fails: Did not throw');
  }
}

void main(List<String> args) async {
  if (!args.contains("--child")) {
    for (var i = 0; i < 4; i++) {
      Isolate.spawn(main, ["--child"]);
    }
  }

  for (var i = 0; i < 10000; i++) {
    final d = Directory("does-not-exist");
    Expect.throws(() => d.listSync(), (e) => e is FileSystemException);
  }
}
