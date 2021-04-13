// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests const factories with const functions.

import "package:expect/expect.dart";

const printConst = MessageType.parse("print");

class MessageType {
  static const print = MessageType._('print');

  static const skip = MessageType._('skip');

  final String name;

  const factory MessageType.parse(String name) {
    if (name == 'print') {
      return MessageType.print;
    }
    return MessageType.skip;
  }

  const MessageType._(this.name);
}

void main() {
  Expect.equals(printConst, MessageType.print);
}
