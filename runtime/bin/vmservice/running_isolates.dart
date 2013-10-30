// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class RunningIsolates implements ServiceRequestRouter {
  final Map<int, RunningIsolate> isolates = new Map<int, RunningIsolate>();

  RunningIsolates();

  void isolateStartup(int portId, SendPort sp, String name) {
    if (isolates[portId] != null) {
      throw new StateError('Duplicate isolate startup.');
    }
    var ri = new RunningIsolate(portId, sp, name);
    isolates[portId] = ri;
  }

  void isolateShutdown(int portId, SendPort sp) {
    if (isolates[portId] == null) {
      throw new StateError('Unknown isolate.');
    }
    isolates.remove(portId);
  }

  void _isolateCollectionRequest(ServiceRequest request) {
    var members = [];
    var result = {};
    isolates.forEach((portId, runningIsolate) {
      members.add({
        'id': portId,
        'name': runningIsolate.name
        });
    });
    result['type'] = 'IsolateList';
    result['members'] = members;
    request.setResponse(JSON.encode(result));
  }

  Future route(ServiceRequest request) {
    if (request.pathSegments.length == 0) {
      return null;
    }
    if (request.pathSegments[0] != 'isolates') {
      return null;
    }
    if (request.pathSegments.length == 1) {
      // Requesting list of running isolates.
      _isolateCollectionRequest(request);
      return new Future.value(request);
    }
    var isolateId;
    try {
      isolateId = int.parse(request.pathSegments[1]);
    } catch (e) {
      request.setErrorResponse('Could not parse isolate id: $e');
      return new Future.value(request);
    }
    var isolate = isolates[isolateId];
    if (isolate == null) {
      request.setErrorResponse('Cannot find isolate id: $isolateId');
      return new Future.value(request);
    }
    // Consume '/isolates/isolateId'
    request.pathSegments.removeRange(0, 2);
    if (request.pathSegments.length == 0) {
      // The request is now empty.
      request.setErrorResponse('No request for isolate: /isolates/$isolateId');
      return new Future.value(request);
    }
    return isolate.route(request);
  }
}
