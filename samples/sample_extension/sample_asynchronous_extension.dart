// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sample_asynchronous_extension;

import 'dart:async';
import 'dart:isolate';
import 'dart-ext:sample_extension';

// A class caches the native port used to call an asynchronous extension.
class RandomArray {
  static SendPort _port;

  Future<List<int>> randomArray(int seed, int length) {
    var completer = Completer<List<int>>();
    var replyPort = RawReceivePort();
    var args = List<Object>(3);
    args[0] = seed;
    args[1] = length;
    args[2] = replyPort.sendPort;
    _servicePort.send(args);
    replyPort.handler = (List<int> result) {
      replyPort.close();
      if (result != null) {
        completer.complete(result);
      } else {
        completer.completeError(Exception('Random array creation failed'));
      }
    };
    return completer.future;
  }

  SendPort get _servicePort => _port ??= _newServicePort();

  SendPort _newServicePort() native 'RandomArray_ServicePort';
}
