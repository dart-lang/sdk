// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

class NotAnInteger {
  operator==(other) => other == 1;
  operator<(other) => other > 1;
  operator+(other) => 1;
}

class NotAList {
  get length() => 10;
  operator[](index) => 1;
}

testSocketCreation(host, port) {
  var s = new Socket(host, port);
  s.onError = (e) => null;
  s.onConnect = () => Expect.fail("Shouldn't get connected");
}

testReadList(buffer, offset, length) {
  var server = new ServerSocket("127.0.0.1", 0, 5);
  var s = new Socket("127.0.0.1", server.port);
  s.onConnect = () {
    try { s.readList(buffer, offset, length); } catch (e) {}
    s.close();
  };
  s.onError = (e) => null;
}

testWriteList(buffer, offset, length) {
  var server = new ServerSocket("127.0.0.1", 0, 5);
  var s = new Socket("127.0.0.1", server.port);
  s.onConnect = () {
    try { s.writeList(buffer, offset, length); } catch (e) {}
    s.close();
  };
  s.onError = (e) => null;
}

testServerSocketCreation(address, port, backlog) {
  var server;
  try {
    server = new ServerSocket(address, port, backlog);
    server.onError = (e) => null;
    server.onConnection = (c) => Expect.fail("Shouldn't get connection");
  } catch (e) {
    // ignore
  }
}

main() {
  testSocketCreation(123, 123);
  testSocketCreation("string", null);
  testSocketCreation(null, null);
  testReadList(null, 123, 123);
  testReadList(new NotAList(), 1, 1);
  testReadList([1, 2, 3], new NotAnInteger(), new NotAnInteger());
  testReadList([1, 2, 3], 1, new NotAnInteger());
  testWriteList(null, 123, 123);
  testWriteList(new NotAList(), 1, 1);
  testWriteList([1, 2, 3], new NotAnInteger(), new NotAnInteger());
  testWriteList([1, 2, 3], 1, new NotAnInteger());
  testWriteList([1, 2, 3], new NotAnInteger(), 1);
  testServerSocketCreation(123, 123, 123);
  testServerSocketCreation("string", null, null);
  testServerSocketCreation("string", 123, null);
}
