// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests const factories with const functions disabled.

import "package:expect/expect.dart";

const printConst = MessageType.parse("print");
//                             ^
// [cfe] Non-redirecting const factory invocation is not a constant expression.

class MessageType {
  static const print = MessageType._('print');

  static const skip = MessageType._('skip');

  final String name;

  const factory MessageType.parse(String name) {
//^^^^^
// [analyzer] SYNTACTIC_ERROR.CONST_FACTORY
// [cfe] Only redirecting factory constructors can be declared to be 'const'.
    if (name == 'print') {
      return MessageType.print;
    }
    return MessageType.skip;
  }

  const MessageType._(this.name);
}
