// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#import("dart:isolate");
#import("dart:io");

void main() {
  // TODO(3593): Use a Dart HTTPS server for this test using TLS server sockets.
  var tls = new TlsSocket("www.google.dk", 443);
  String message = '';
  tls.onConnect = () {
    var get_list =
      "GET / HTTP/1.0\r\nHost: www.google.dk\r\n\r\n".charCodes();
    tls.writeList(get_list, 0, 20);
    tls.writeList(get_list, 20, get_list.length - 20);
  };
  tls.onData = () {
    var buffer = new List(2000);
    int len = tls.readList(buffer, 0, 2000);
    var received = new String.fromCharCodes(buffer.getRange(0, len));
    message = '$message$received';
  };
  tls.onClosed = () {
    Expect.isTrue(message.contains('</script></body></html>'));
  };
}
