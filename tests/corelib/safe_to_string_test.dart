// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.stringEquals('1', Error.safeToString(1));
  Expect.stringEquals('0.5', Error.safeToString(0.5));
  Expect.stringEquals('"1"', Error.safeToString("1"));
  Expect.stringEquals('"\'"', Error.safeToString("'"));
  Expect.stringEquals('"\'\'"', Error.safeToString("''"));
  Expect.stringEquals(r'"\""', Error.safeToString('"'));
  Expect.stringEquals(r'"\"\""', Error.safeToString('""'));

  Expect.stringEquals(r'"\\\"\n\r"', Error.safeToString('\\"\n\r'));

  Expect.stringEquals(r'"\x00\x01\x02\x03\x04\x05\x06\x07"',
                      Error.safeToString('\x00\x01\x02\x03\x04\x05\x06\x07'));
  Expect.stringEquals(r'"\x08\t\n\x0b\x0c\r\x0e\x0f"',
                      Error.safeToString('\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f'));
  Expect.stringEquals(r'"\x10\x11\x12\x13\x14\x15\x16\x17"',
                      Error.safeToString('\x10\x11\x12\x13\x14\x15\x16\x17'));
  Expect.stringEquals(r'"\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"',
                      Error.safeToString('\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f'));
  Expect.stringEquals('" "', Error.safeToString(" "));

  Expect.stringEquals('null', Error.safeToString(null));
  Expect.stringEquals('true', Error.safeToString(true));
  Expect.stringEquals('false', Error.safeToString(false));
  Expect.stringEquals("Instance of 'Object'",
                      Error.safeToString(new Object()));
}
