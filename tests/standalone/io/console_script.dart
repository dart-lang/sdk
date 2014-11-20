// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

class Message {
  final message;
  Message(this.message);
  toString() => message;
}

void test(ConsoleSink sink) {
  sink.add([65, 66, 67]);
  sink.write('DEF');
  sink.writeAll(['GH', 'I']);
  sink.writeCharCode(74);
  sink.writeln('KLM');
}

void main(List<String> arguments) {
  console.log('stdout');
  console.error('stderr');
  console.log();
  console.error();
  console.log(new Message('tuodts'));
  console.error(new Message('rredts'));
  test(console.log);
  test(console.error);
  exit(1);
}
