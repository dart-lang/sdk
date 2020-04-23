// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:expect/expect.dart';

typedef Dart_PostIntegerNFT = IntPtr Function(Int64 port, Int64 message);
typedef Dart_PostIntegerFT = int Function(int port, int message);

main() async {
  const int message = 112344556677888;

  final completer = Completer();

  final receivePort = ReceivePort()
    ..listen((receivedMessage) => completer.complete(receivedMessage));

  final executableSymbols = DynamicLibrary.executable();

  final postInteger =
      executableSymbols.lookupFunction<Dart_PostIntegerNFT, Dart_PostIntegerFT>(
          "Dart_PostInteger");

  // Issue(dartbug.com/38545): The dart:ffi doesn't have a bool type yet.
  final bool success =
      postInteger(receivePort.sendPort.nativePort, message) != 0;
  Expect.isTrue(success);

  final postedMessage = await completer.future;
  Expect.equals(message, postedMessage);

  receivePort.close();
}
