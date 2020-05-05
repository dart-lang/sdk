// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

class RunningIsolate implements MessageRouter {
  final int portId;
  final SendPort sendPort;
  final String name;
  final Set<String> _resumeApprovalsByName = {};

  RunningIsolate(this.portId, this.sendPort, this.name);

  String get serviceId => 'isolates/$portId';

  static const kInvalidPauseEvent = -1;
  static const kPauseOnStartMask = 1 << 0;
  static const kPauseOnReloadMask = 1 << 1;
  static const kPauseOnExitMask = 1 << 2;
  static const kDefaultResumePermissionMask =
      kPauseOnStartMask | kPauseOnReloadMask | kPauseOnExitMask;

  /// Resumes the isolate if all clients which need to approve a resume have
  /// done so. Called when the last client of a given name disconnects or
  /// changes name to ensure we don't deadlock waiting for approval to resume
  /// from a disconnected client.
  Future<void> maybeResumeAfterClientChange(
      VMService service, String disconnectedClientName) async {
    // Remove approvals from the disconnected client.
    _resumeApprovalsByName.remove(disconnectedClientName);

    // If we've received approval to resume from all clients who care, clear
    // approval state and resume.
    var pauseType;
    try {
      pauseType = await _isolatePauseType(service, portId.toString());
    } catch (_errorResponse) {
      // ignore errors when attempting to retrieve isolate pause type
      return;
    }
    if (pauseType != kInvalidPauseEvent &&
        _shouldResume(service, null, pauseType)) {
      _resumeApprovalsByName.clear();
      await Message.forMethod('resume')
        ..params.addAll({
          'isolateId': portId,
        })
        ..sendToIsolate(sendPort);
    }
  }

  bool _shouldResume(VMService service, Client? client, int pauseType) {
    if (client != null) {
      // Mark the approval by the client.
      _resumeApprovalsByName.add(client.name);
    }
    final requiredClientApprovals = <String>{};
    final permissions = service.clientResumePermissions;

    // Determine which clients require approval for this pause type.
    permissions.forEach((name, clientNamePermissions) {
      if (clientNamePermissions.permissionsMask & pauseType != 0) {
        requiredClientApprovals.add(name);
      }
    });

    // We require at least a single client to resume, even if that client
    // doesn't require resume approval.
    if (_resumeApprovalsByName.isEmpty) {
      return false;
    }

    // If all the required approvals are present, we should resume.
    return _resumeApprovalsByName.containsAll(requiredClientApprovals);
  }

  Future<int> _isolatePauseType(VMService service, String isolateId) async {
    final getIsolateMessage = Message.forMethod('getIsolate')
      ..params.addAll({
        'isolateId': isolateId,
      });
    final Response result = await routeRequest(service, getIsolateMessage);
    final resultJson = result.decodeJson();
    if (resultJson['result'] == null ||
        resultJson['result']['pauseEvent'] == null) {
      // Failed to send getIsolate message(due to isolate being de-registered
      // for example).
      throw result;
    }
    final pauseEvent = resultJson['result']['pauseEvent'];
    const pauseEvents = <String, int>{
      'PauseStart': kPauseOnStartMask,
      'PausePostRequest': kPauseOnReloadMask,
      'PauseExit': kPauseOnExitMask,
    };
    final kind = pauseEvent['kind'];
    return pauseEvents[kind] ?? kInvalidPauseEvent;
  }

  Future<Response> _routeResumeRequest(
      VMService service, Message message) async {
    // If we've received approval to resume from all clients who care, clear
    // approval state and resume.
    var pauseType;
    try {
      pauseType = await _isolatePauseType(service, message.params['isolateId']);
    } on Response catch (errorResponse) {
      return errorResponse;
    }
    if (pauseType == kInvalidPauseEvent ||
        _shouldResume(service, message.client, pauseType)) {
      _resumeApprovalsByName.clear();
      return message.sendToIsolate(sendPort);
    }

    // We're still awaiting some approvals. Simply return success, but don't
    // resume yet.
    return Response(ResponsePayloadKind.String, encodeSuccess(message));
  }

  @override
  Future<Response> routeRequest(VMService service, Message message) {
    if (message.method == 'resume') {
      return _routeResumeRequest(service, message);
    }
    // Send message to isolate.
    return message.sendToIsolate(sendPort);
  }

  @override
  void routeResponse(Message message) {}
}
