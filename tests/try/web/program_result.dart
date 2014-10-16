// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.test.program_result;

class ProgramResult {
  final String code;

  final List<String> messages;

  const ProgramResult(this.code, this.messages);

  List<String> messagesWith(String extra) {
    return new List<String>.from(messages)..add(extra);
  }
}
