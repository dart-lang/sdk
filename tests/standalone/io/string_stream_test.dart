// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:isolate");

void testUtf8() {
  List<int> data = [0x01,
                    0x7f,
                    0xc2, 0x80,
                    0xdf, 0xbf,
                    0xe0, 0xa0, 0x80,
                    0xef, 0xbf, 0xbf];
  ListInputStream s = new ListInputStream();
  s.write(data);
  s.markEndOfStream();
  StringInputStream stream = new StringInputStream(s);
  void stringData() {
    String s = stream.read();
    Expect.equals(6, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals(new String.fromCharCodes([0x7f]), s[1]);
    Expect.equals(new String.fromCharCodes([0x80]), s[2]);
    Expect.equals(new String.fromCharCodes([0x7ff]), s[3]);
    Expect.equals(new String.fromCharCodes([0x800]), s[4]);
    Expect.equals(new String.fromCharCodes([0xffff]), s[5]);
  }
  stream.onData = stringData;
}

void testLatin1() {
  List<int> data = [0x01,
                    0x7f,
                    0x44, 0x61, 0x72, 0x74,
                    0x80,
                    0xff];
  ListInputStream s = new ListInputStream();
  s.write(data);
  s.markEndOfStream();
  StringInputStream stream = new StringInputStream(s, Encoding.ISO_8859_1);
  void stringData() {
    String s = stream.read();
    Expect.equals(8, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals(new String.fromCharCodes([0x7f]), s[1]);
    Expect.equals("Dart", s.substring(2, 6));
    Expect.equals(new String.fromCharCodes([0x80]), s[6]);
    Expect.equals(new String.fromCharCodes([0xff]), s[7]);
  }
  stream.onData = stringData;
}

void testAscii() {
  List<int> data = [0x01,
                    0x44, 0x61, 0x72, 0x74,
                    0x7f];
  ListInputStream s = new ListInputStream();
  s.write(data);
  s.markEndOfStream();
  StringInputStream stream =
      new StringInputStream(s, Encoding.ASCII);
  void stringData() {
    String s = stream.read();
    Expect.equals(6, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals("Dart", s.substring(1, 5));
    Expect.equals(new String.fromCharCodes([0x7f]), s[5]);
  }
  stream.onData = stringData;
}

void testReadLine1() {
  ListInputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);
  var stage = 0;

  void stringData() {
    var line;
    if (stage == 0) {
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.markEndOfStream();
    } else if (stage == 1) {
      line = stream.readLine();
      Expect.equals("Line", line);
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(true, stream.closed);
    Expect.equals(2, stage);
  }

  stream.onData = stringData;
  stream.onClosed = streamClosed;
  s.write("Line".charCodes);
}

void testReadLine2() {
  ListInputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);
  var stage = 0;

  void stringData() {
    var line;
    if (stage == 0) {
      Expect.equals(21, stream.available());
      line = stream.readLine();
      Expect.equals("Line1", line);
      Expect.equals(15, stream.available());
      line = stream.readLine();
      Expect.equals("Line2", line);
      Expect.equals(8, stream.available());
      line = stream.readLine();
      Expect.equals("Line3", line);
      line = stream.readLine();
      Expect.equals(2, stream.available());
      Expect.equals(null, line);
      stage++;
      s.write("ne4\n".charCodes);
    } else if (stage == 1) {
      Expect.equals(6, stream.available());
      line = stream.readLine();
      Expect.equals("Line4", line);
      Expect.equals(0, stream.available());
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.write("\n\n\r\n\r\n\r\r".charCodes);
    } else if (stage == 2) {
      // Expect 5 empty lines. As long as the stream is not closed the
      // final \r cannot be interpreted as a end of line.
      Expect.equals(8, stream.available());
      for (int i = 0; i < 5; i++) {
        line = stream.readLine();
        Expect.equals("", line);
      }
      Expect.equals(1, stream.available());
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.markEndOfStream();
    } else if (stage == 3) {
      // The final \r can now be interpreted as an end of line.
      Expect.equals(1, stream.available());
      line = stream.readLine();
      Expect.equals("", line);
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(4, stage);
    Expect.equals(true, stream.closed);
  }

  stream.onLine = stringData;
  stream.onClosed = streamClosed;
  s.write("Line1\nLine2\r\nLine3\rLi".charCodes);
}

void testReadChunks() {
  ListInputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);

  void stringData() {
    var data;
    Expect.equals(8, stream.available());
    data = stream.read(1);
    Expect.equals("A", data);
    Expect.equals(7, stream.available());
    data = stream.read(2);
    Expect.equals("BC", data);
    Expect.equals(5, stream.available());
    data = stream.read(3);
    Expect.equals("D12", data);
    Expect.equals(2, stream.available());
    data = stream.read();
    Expect.equals("34", data);
    Expect.equals(0, stream.available());
    data = stream.read(1);
    Expect.equals(null, data);
    Expect.equals(0, stream.available());
    data = stream.read(2);
    Expect.equals(null, data);
    Expect.equals(0, stream.available());
    data = stream.read(3);
    Expect.equals(null, data);
    Expect.equals(0, stream.available());
    data = stream.read();
    Expect.equals(null, data);
    Expect.equals(0, stream.available());
  }

  s.write("ABCD1234".charCodes);
  stream.onData = stringData;
}

void testReadMixed() {
  ListInputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);
  var stage = 0;

  void stringData() {
    var data;
    if (stage == 0) {
      Expect.equals(11, stream.available());
      data = stream.read(2);
      Expect.equals("A\r", data);
      Expect.equals(9, stream.available());
      data = stream.readLine();
      Expect.equals("", data);
      Expect.equals(8, stream.available());
      data = stream.read(4);
      Expect.equals("BCD\n", data);
      Expect.equals(4, stream.available());
      data = stream.readLine();
      Expect.equals(null, data);
      data = stream.read(4);
      Expect.equals("1234", data);
      s.write("A\r\nBCD\n1234".charCodes);
      stage++;
    } else if (stage == 1) {
      Expect.equals(11, stream.available());
      data = stream.read(1);
      Expect.equals("A", data);
      Expect.equals(10, stream.available());
      data = stream.read(1);
      Expect.equals("\r", data);
      Expect.equals(9, stream.available());
      data = stream.read(1);
      Expect.equals("\n", data);
      Expect.equals(8, stream.available());
      data = stream.readLine();
      Expect.equals("BCD", data);
      data = stream.readLine();
      Expect.equals(null, data);
      data = stream.read(4);
      Expect.equals("1234", data);
      s.write("A\r\nBCD\n1234".charCodes);
      stage++;
    } else if (stage == 2) {
      Expect.equals(11, stream.available());
      data = stream.read(7);
      Expect.equals("A\r\nBCD\n", data);
      Expect.equals(4, stream.available());
      data = stream.readLine();
      Expect.equals(null, data);
      data = stream.read();
      Expect.equals("1234", data);
      stage++;
      s.markEndOfStream();
    }
  }

  void streamClosed() {
    Expect.equals(3, stage);
    Expect.equals(true, stream.closed);
  }

  s.write("A\r\nBCD\n1234".charCodes);
  stream.onData = stringData;
  stream.onClosed = streamClosed;
}

class TestException implements Exception {
  TestException();
}

class ErrorInputStream implements InputStream {
  ErrorInputStream();
  List<int> read([int len]) => null;
  int readInto(List<int> buffer, [int offset, int len]) => 0;
  int available() => 0;
  void pipe(OutputStream output, {bool close: true}){ }
  void close() { }
  bool get closed => true;
  void set onData(void callback()) { }
  void set onClosed(void callback()) { }
  void set onError(void callback(Exception e)) {
    callback(new TestException());
  }
}

testErrorHandler() {
  var errors = 0;
  var stream = new StringInputStream(new ErrorInputStream());
  stream.onError = (e) {
    errors++;
    Expect.isTrue(e is TestException);
  };
  Expect.equals(1, errors);
}

testEncodingErrorWithHandler() {
  var port = new ReceivePort();    
  var errors = 0;
  var expected = [206, 187, 120, 46, 32, 120, 10];
  ListInputStream input = new ListInputStream();
  input.write(expected);
  var stringStream = new StringInputStream(input, Encoding.ASCII);
  stringStream.onData = () {
    Expect.fail("We should not get any data");
  };
  stringStream.onError = (e) {
    port.close();
    Expect.isTrue(e is Exception);
  };
}


main() {
  testUtf8();
  testLatin1();
  testAscii();
  testReadLine1();
  testReadLine2();
  testReadChunks();
  testReadMixed();
  testErrorHandler();
  testEncodingErrorWithHandler();
}
