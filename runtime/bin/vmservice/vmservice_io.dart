// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnmccutchan): Convert this into separate library which imports
// the vmservice library.

part of vmservice;

var _port;

main() {
  var service = new VmService();
  var server = new Server(service, _port);
  server.startServer();
}
