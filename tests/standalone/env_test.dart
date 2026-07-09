// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Dvar -D -D=var -Dvar=invalid -Dvar=valid -Dvar

import "package:expect/expect.dart";

main() {
  Expect.equals('valid', const String.fromEnvironment('var'));
}
