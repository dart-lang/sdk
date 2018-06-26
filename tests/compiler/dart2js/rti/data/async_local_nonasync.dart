// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // If any method was `async`, this would have triggered the need for the
  // signature on this closure. See the 'async_local.dart' test.
  /*kernel.*/
  /*strong.*/
  /*omit.*/
  local(object, stacktrace) => null;

  return local;
}
