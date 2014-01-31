// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class RunningIsolates implements MessageRouter {
  final Map<int, RunningIsolate> isolates = new Map<int, RunningIsolate>();

  RunningIsolates();

  void isolateStartup(int portId, SendPort sp, String name) {
    var ri = new RunningIsolate(portId, sp, name);
    isolates[portId] = ri;
  }

  void isolateShutdown(int portId, SendPort sp) {
    isolates.remove(portId);
  }

  void _isolateCollectionRequest(Message message) {
    var members = [];
    var result = {};
    isolates.forEach((portId, runningIsolate) {
      members.add({
          'type': '@Isolate',
          'id': 'isolates/$portId',
          'name': '$portId',
      });
    });
    result['type'] = 'IsolateList';
    result['members'] = members;
    message.setResponse(JSON.encode(result));
  }

  Future<String> route(Message message) {
    if (message.path.length == 0) {
      message.setErrorResponse('No path.');
      return message.response;
    }
    if (message.path[0] != 'isolates') {
      message.setErrorResponse('Path must begin with /isolates/.');
      return message.response;
    }
    if (message.path.length == 1) {
      // Requesting list of running isolates.
      _isolateCollectionRequest(message);
      return message.response;
    }
    var isolateId;
    try {
      isolateId = int.parse(message.path[1]);
    } catch (e) {
      message.setErrorResponse('Could not parse isolate id: $e');
      return message.response;
    }
    var isolate = isolates[isolateId];
    if (isolate == null) {
      message.setErrorResponse('Cannot find isolate id: $isolateId');
      return message.response;
    }
    // Consume '/isolates/isolateId'
    message.path.removeRange(0, 2);
    return isolate.route(message);
  }
}
