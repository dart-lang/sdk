// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void testEmptyListOutputStream1() {
  OutputStream stream = new ListOutputStream();
  Expect.equals(null, stream.contents());
  stream.close();
  Expect.equals(null, stream.contents());
  Expect.throws(() { stream.write([0]); });
}


void testEmptyListOutputStream2() {
  OutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();

  void onNoPendingWrite() {
    stream.close();
  }

  void onClose() {
    Expect.equals(null, stream.contents());
    donePort.toSendPort().send(null);
  }

  stream.noPendingWriteHandler = onNoPendingWrite;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}


void testListOutputStream1() {
  OutputStream stream = new ListOutputStream();
  Expect.equals(null, stream.contents());
  stream.write([1, 2]);
  stream.writeFrom([1, 2, 3, 4, 5], 2, 2);
  stream.write([5]);
  stream.close();
  var contents = stream.contents();
  Expect.equals(5, contents.length);
  for (var i = 0; i < contents.length; i++) Expect.equals(i + 1, contents[i]);
  Expect.equals(null, stream.contents());
}


void testListOutputStream2() {
  OutputStream stream = new ListOutputStream();
  ReceivePort donePort = new ReceivePort();
  int stage = 0;
  void onNoPendingWrite() {
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

  void onClose() {
    Expect.equals(4, stage);
    var contents = stream.contents();
    Expect.equals(5, contents.length);
    for (var i = 0; i < contents.length; i++) Expect.equals(i + 1, contents[i]);
    Expect.equals(null, stream.contents());
    donePort.toSendPort().send(null);
  }

  stream.noPendingWriteHandler = onNoPendingWrite;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}

main() {
  testEmptyListOutputStream1();
  testEmptyListOutputStream2();
  testListOutputStream1();
  testListOutputStream2();
}
