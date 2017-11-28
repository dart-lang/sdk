// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

class Message {
  final message;
  Message(this.message);
  toString() => message;
}

void test(IOSink sink) {
  sink.add([65, 66, 67]);
  sink.write('DEF');
  sink.writeAll(['GH', 'I']);
  sink.writeCharCode(74);
  sink.writeln('KLM');
}

void main(List<String> arguments) {
  stdout.nonBlocking.writeln('stdout');
  stderr.nonBlocking.writeln('stderr');
  stdout.nonBlocking.writeln();
  stderr.nonBlocking.writeln();
  stdout.nonBlocking.writeln(new Message('tuodts'));
  stderr.nonBlocking.writeln(new Message('rredts'));
  test(stdout.nonBlocking);
  test(stderr.nonBlocking);
  Future.wait([stdout.nonBlocking.close(), stderr.nonBlocking.close()]).then(
      (_) => exit(1));
}
