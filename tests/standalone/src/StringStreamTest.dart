// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListInputStream implements InputStream {
  List<int> read() {
    var result = _data;
    _data = null;
    return result;
  }

  void set dataHandler(void callback()) {
    _dataHandler = callback;
  }

  void set closeHandler(void callback()) {
    _closeHandler = callback;
  }

  void set errorHandler(void callback(int error)) {
  }

  void write(List<int> data) {
    Expect.equals(null, _data);
    _data = data;
    if (_dataHandler != null) {
      // Data handler is not called through the event loop here.
      _dataHandler();
    }
  }

  void close() {
    // Close handler is not called through the event loop here.
    if (_closeHandler != null) _closeHandler();
  }

  List<int> _data;
  var _dataHandler;
  var _closeHandler;
}

void testUtf8() {
  List<int> data = [0x01,
                    0x7f,
                    0xc2, 0x80,
                    0xdf, 0xbf,
                    0xe0, 0xa0, 0x80,
                    0xef, 0xbf, 0xbf];
  InputStream s = new ListInputStream();
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
  stream.dataHandler = stringData;
  s.write(data);
}

void testLatin1() {
  List<int> data = [0x01,
                    0x7f,
                    0x44, 0x61, 0x72, 0x74,
                    0x80,
                    0xff];
  InputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s, "ISO-8859-1");
  void stringData() {
    String s = stream.read();
    Expect.equals(8, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals(new String.fromCharCodes([0x7f]), s[1]);
    Expect.equals("Dart", s.substring(2, 6));
    Expect.equals(new String.fromCharCodes([0x80]), s[6]);
    Expect.equals(new String.fromCharCodes([0xff]), s[7]);
  }
  stream.dataHandler = stringData;
  s.write(data);
}

void testAscii() {
  List<int> data = [0x01,
                    0x44, 0x61, 0x72, 0x74,
                    0x7f];
  InputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s, "ASCII");
  void stringData() {
    String s = stream.read();
    Expect.equals(6, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals("Dart", s.substring(1, 5));
    Expect.equals(new String.fromCharCodes([0x7f]), s[5]);
  }
  stream.dataHandler = stringData;
  s.write(data);
}

void testReadLine1() {
  InputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);
  var stage = 0;

  void stringData() {
    var line;
    if (stage == 0) {
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.close();
    } else if (stage == 1) {
      line = stream.readLine();
      Expect.equals("Line", line);
      line = stream.readLine();
      Expect.equals(null, line);
      Expect.equals(true, stream.closed);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(2, stage);
  }

  stream.dataHandler = stringData;
  stream.closeHandler = streamClosed;
  s.write("Line".charCodes());
  Expect.equals(2, stage);
}

void testReadLine2() {
  InputStream s = new ListInputStream();
  StringInputStream stream = new StringInputStream(s);
  var stage = 0;

  void stringData() {
    var line;
    if (stage == 0) {
      line = stream.readLine();
      Expect.equals("Line1", line);
      line = stream.readLine();
      Expect.equals("Line2", line);
      line = stream.readLine();
      Expect.equals("Line3", line);
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.write("ne4\n".charCodes());
    } else if (stage == 1) {
      line = stream.readLine();
      Expect.equals("Line4", line);
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.write("\n\n\r\n\r\n\r\r".charCodes());
    } else if (stage == 2) {
      // Expect 5 empty lines. As long as the stream is not closed the
      // final \r cannot be interpreted as a end of line.
      for (int i = 0; i < 5; i++) {
        line = stream.readLine();
        Expect.equals("", line);
      }
      line = stream.readLine();
      Expect.equals(null, line);
      stage++;
      s.close();
    } else if (stage == 3) {
      // The final \r can now be interpreted as an end of line.
      line = stream.readLine();
      Expect.equals("", line);
      line = stream.readLine();
      Expect.equals(null, line);
      Expect.equals(true, stream.closed);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(4, stage);
  }

  stream.lineHandler = stringData;
  stream.closeHandler = streamClosed;
  s.write("Line1\nLine2\r\nLine3\rLi".charCodes());
  Expect.equals(4, stage);
}

main() {
  testUtf8();
  testLatin1();
  testAscii();
  testReadLine1();
  testReadLine2();
}
