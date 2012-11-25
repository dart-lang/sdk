// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.stringEquals('1', Error.safeToString(1));
  Expect.stringEquals('0.5', Error.safeToString(0.5));
  Expect.stringEquals('"1"', Error.safeToString("1"));
  Expect.stringEquals('"\'"', Error.safeToString("'"));
  Expect.stringEquals('"\'\'"', Error.safeToString("''"));
  Expect.stringEquals(r'"\""', Error.safeToString('"'));
  Expect.stringEquals(r'"\"\""', Error.safeToString('""'));

  Expect.stringEquals(r'"\\\"\n\r"', Error.safeToString('\\"\n\r'));

  Expect.stringEquals('null', Error.safeToString(null));
  Expect.stringEquals('true', Error.safeToString(true));
  Expect.stringEquals('false', Error.safeToString(false));
  Expect.stringEquals("Instance of 'Object'",
                      Error.safeToString(new Object()));
}
