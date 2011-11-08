// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// A test that runs forever.
void main() {
  final HOST = "127.0.0.1";
  // Use port 0 to chose free port.
  ServerSocket listenForever = new ServerSocket(HOST, 0, 10);
  // Does not call listenForever.close();
}
