// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "vmservice.dart";

class RunningIsolate implements MessageRouter {
  final int portId;
  final SendPort sendPort;
  final String name;

  RunningIsolate(this.portId, this.sendPort, this.name);

  String get serviceId => 'isolates/$portId';

  Future<String> route(Message message) {
    // Send message to isolate.
    return message.send(sendPort);
  }
}
