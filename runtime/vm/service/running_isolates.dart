// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class RunningIsolates implements MessageRouter {
  final Map<int, RunningIsolate> isolates = new Map<int, RunningIsolate>();
  int _rootPortId;

  RunningIsolates();

  void isolateStartup(int portId, SendPort sp, String name) {
    if (_rootPortId == null) {
      _rootPortId = portId;
    }
    var ri = new RunningIsolate(portId, sp, name);
    isolates[portId] = ri;
  }

  void isolateShutdown(int portId, SendPort sp) {
    if (_rootPortId == portId) {
      _rootPortId = null;
    }
    isolates.remove(portId);
  }

  Future<String> route(Message message) {
    String isolateParam = message.params['isolateId'];
    int isolateId;
    if (!isolateParam.startsWith('isolates/')) {
      message.setErrorResponse(
          kInvalidParams, "invalid 'isolateId' parameter: $isolateParam");
      return message.response;
    }
    isolateParam = isolateParam.substring('isolates/'.length);
    if (isolateParam == 'root') {
      isolateId = _rootPortId;
    } else {
      try {
        isolateId = int.parse(isolateParam);
      } catch (e) {
        message.setErrorResponse(
            kInvalidParams, "invalid 'isolateId' parameter: $isolateParam");
        return message.response;
      }
    }
    var isolate = isolates[isolateId];
    if (isolate == null) {
      message.setErrorResponse(
          kInvalidParams, "invalid 'isolateId' parameter: $isolateParam");
      return message.response;
    }
    return isolate.route(message);
  }
}
