// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DBG_CONNECTION_WIN_H_
#define BIN_DBG_CONNECTION_WIN_H_

class DebuggerConnectionImpl {
 public:
  static void StartHandler(int port_number);
  static intptr_t Send(intptr_t socket, const char* buf, int len);
  static intptr_t Receive(intptr_t socket, char* buf, int len);

 private:
  static void ThreadEntry(uword args);
};

#endif  // BIN_DBG_CONNECTION_WIN_H_
