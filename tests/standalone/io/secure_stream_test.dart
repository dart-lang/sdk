// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// The --short_socket_write option does not work with external server
// www.google.dk.  Add this to the test when we have secure server sockets.
// See TODO below.

#import("dart:isolate");
#import("dart:io");

void main() {
  var testPkcertDatabase =
      new Path.fromNative(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.setCertificateDatabase(testPkcertDatabase.toNativePath());
  // TODO(3593): Use a Dart HTTPS server for this test.
  // When we use a Dart HTTPS server, allow --short_socket_write. The flag
  // causes fragmentation of the client hello message, which doesn't seem to
  // work with www.google.dk.
  var secure = new SecureSocket("www.google.dk", 443);
  List<String> chunks = <String>[];
  var input = secure.inputStream;
  var output = secure.outputStream;

  output.write("GET / HTTP/1.0\r\nHost: www.google.dk\r\n\r\n".charCodes);
  output.close();
  input.onData = () {
    chunks.add(new String.fromCharCodes(input.read()));
  };
  input.onClosed = () {
    String fullPage = Strings.concatAll(chunks);
    Expect.isTrue(fullPage.contains('</body></html>'));
  };
}
