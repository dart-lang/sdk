// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.stringEquals('1', NoSuchMethodError.safeToString(1));
  Expect.stringEquals('0.5', NoSuchMethodError.safeToString(0.5));
  Expect.stringEquals('"1"', NoSuchMethodError.safeToString("1"));
  Expect.stringEquals('"\'"', NoSuchMethodError.safeToString("'"));
  Expect.stringEquals('"\'\'"', NoSuchMethodError.safeToString("''"));
  Expect.stringEquals(r'"\""', NoSuchMethodError.safeToString('"'));
  Expect.stringEquals(r'"\"\""', NoSuchMethodError.safeToString('""'));
  Expect.stringEquals('null', NoSuchMethodError.safeToString(null));
  Expect.stringEquals('true', NoSuchMethodError.safeToString(true));
  Expect.stringEquals('false', NoSuchMethodError.safeToString(false));
  Expect.stringEquals("Instance of 'Object'",
                      NoSuchMethodError.safeToString(new Object()));
}
