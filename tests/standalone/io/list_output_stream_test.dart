// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:isolate");

void testEmptyListOutputStream1() {
  ListOutputStream stream = new ListOutputStream();
  Expect.equals(null, stream.read());
  stream.close();
  Expect.equals(null, stream.read());
  Expect.throws(() { stream.write([0]); });
}


void testEmptyListOutputStream2() {
  ListOutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();

  void onNoPendingWrites() {
    stream.close();
  }

  void onClosed() {
    Expect.equals(null, stream.read());
    donePort.toSendPort().send(null);
  }

  stream.onNoPendingWrites = onNoPendingWrites;
  stream.onClosed = onClosed;

  donePort.receive((x,y) => donePort.close());
}


void testListOutputStream1() {
  ListOutputStream stream = new ListOutputStream();
  Expect.equals(null, stream.read());
  stream.write([1, 2]);
  stream.writeFrom([1, 2, 3, 4, 5], 2, 2);
  stream.write([5]);
  stream.close();
  var contents = stream.read();
  Expect.equals(5, contents.length);
  for (var i = 0; i < contents.length; i++) Expect.equals(i + 1, contents[i]);
  Expect.equals(null, stream.read());
}


void testListOutputStream2() {
  ListOutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();
  int stage = 0;
  void onNoPendingWrites() {
    switch (stage) {
      case 0:
        stream.write([1, 2]);
        break;
      case 1:
        stream.writeFrom([1, 2, 3, 4, 5], 2, 2);
        break;
      case 2:
        stream.write([5]);
        break;
      case 3:
        stream.close();
        break;
    }
    stage++;
  }

  void onClosed() {
    Expect.equals(4, stage);
    var contents = stream.read();
    Expect.equals(5, contents.length);
    for (var i = 0; i < contents.length; i++) Expect.equals(i + 1, contents[i]);
    Expect.equals(null, stream.read());
    donePort.toSendPort().send(null);
  }

  stream.onNoPendingWrites = onNoPendingWrites;
  stream.onClosed = onClosed;

  donePort.receive((x,y) => donePort.close());
}

void testListOutputStream3() {
  ListOutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();
  void onNoPendingWrites() {
    stream.writeString("abcdABCD");
    stream.writeString("abcdABCD", Encoding.UTF_8);
    stream.writeString("abcdABCD", Encoding.ISO_8859_1);
    stream.writeString("abcdABCD", Encoding.ASCII);
    stream.writeString("æøå", Encoding.UTF_8);
    stream.close();
  }

  void onClosed() {
    var contents = stream.read();
    Expect.equals(38, contents.length);
    donePort.toSendPort().send(null);
  }

  stream.onNoPendingWrites = onNoPendingWrites;
  stream.onClosed = onClosed;

  donePort.receive((x,y) => donePort.close());
}

void testListOutputStream4() {
  ListOutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();
  List result = <int>[];

  void onData() => result.addAll(stream.read());

  void onClosed() {
    Expect.equals(4, result.length);
    for (var i = 0; i < result.length; i++) Expect.equals(i + 1, result[i]);
    donePort.toSendPort().send(null);
  }

  stream.onData = onData;
  stream.onClosed = onClosed;

  new Timer(0, (_) {
    result.add(1);
    stream.write([2]);

    new Timer(0, (_) {
      result.add(3);
      stream.write([4]);
      stream.close();
    });
  });

  donePort.receive((x,y) => donePort.close());
}

void testListOutputStream5() {
  ListOutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();

  stream.onClosed = () {
    Expect.isTrue(stream.closed);
    var contents = stream.read();
    Expect.equals(3, contents.length);
    for (var i = 0; i < contents.length; i++) Expect.equals(i + 1, contents[i]);
    donePort.toSendPort().send(null);
  };

  Expect.isFalse(stream.closed);
  stream.write([1, 2, 3]);
  Expect.isFalse(stream.closed);
  stream.close();
  Expect.isTrue(stream.closed);
  Expect.throws(() => stream.write([4, 5, 6]));

  donePort.receive((x,y) => donePort.close());
}

main() {
  testEmptyListOutputStream1();
  testEmptyListOutputStream2();
  testListOutputStream1();
  testListOutputStream2();
  testListOutputStream3();
  testListOutputStream4();
  testListOutputStream5();
}
