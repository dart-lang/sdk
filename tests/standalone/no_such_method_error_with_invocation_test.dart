// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Using withInvocation constructor.
  var receiver = Object();
  {
    var invocationGet = Invocation.getter(#foo);
    var errorGet = NoSuchMethodError.withInvocation(receiver, invocationGet);
    var errorString = errorGet.toString();
    Expect.isTrue(errorString.contains("foo"), "01: $errorString");
    Expect.isTrue(errorString.contains("getter"), "02: $errorString");
  }
  {
    var invocationSet = Invocation.setter(#foo, 42);
    var error = NoSuchMethodError.withInvocation(receiver, invocationSet);
    var errorString = error.toString();
    Expect.isTrue(errorString.contains("foo"), "03: $errorString");
    Expect.isTrue(errorString.contains("setter"), "04: $errorString");
  }
  {
    var invocationCall = Invocation.method(#foo, [42]);
    var error = NoSuchMethodError.withInvocation(receiver, invocationCall);
    var errorString = error.toString();
    Expect.isTrue(errorString.contains("foo"), "05: $errorString");
    Expect.isTrue(errorString.contains("method"), "06: $errorString");
    Expect.isTrue(errorString.contains("(_)"), "07: $errorString");
  }
  {
    var invocationCall = Invocation.method(#foo, [42], {#bar: 37});
    var error = NoSuchMethodError.withInvocation(receiver, invocationCall);
    var errorString = error.toString();
    Expect.isTrue(errorString.contains("foo"), "08: $errorString");
    Expect.isTrue(errorString.contains("method"), "09: $errorString");
    Expect.isTrue(errorString.contains("(_, {bar: _})"), "10: $errorString");
  }
  {
    var invocationCall = Invocation.genericMethod(#foo, [int], [42]);
    var error = NoSuchMethodError.withInvocation(receiver, invocationCall);
    var errorString = error.toString();
    Expect.isTrue(errorString.contains("foo"), "11: $errorString");
    Expect.isTrue(errorString.contains("method"), "12: $errorString");
    Expect.isTrue(errorString.contains("<_>(_)"), "13: $errorString");
  }
}
