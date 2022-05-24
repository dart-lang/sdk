// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/file_system/file_system.dart';

/// The handler for the `execution.mapUri` request.
class ExecutionMapUriHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  ExecutionMapUriHandler(super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = ExecutionMapUriParams.fromRequest(request);
    var contextId = params.id;
    var path = server.executionContext.contextMap[contextId];
    if (path == null) {
      sendResponse(Response.invalidParameter(request, 'id',
          'There is no execution context with an id of $contextId'));
      return;
    }

    var driver = server.getAnalysisDriver(path);
    if (driver == null) {
      sendResponse(Response.invalidExecutionContext(request, contextId));
      return;
    }
    var sourceFactory = driver.sourceFactory;

    var file = params.file;
    var uri = params.uri;
    if (file != null) {
      if (uri != null) {
        sendResponse(Response.invalidParameter(request, 'file',
            'Either file or uri must be provided, but not both'));
        return;
      }
      var resource = server.resourceProvider.getResource(file);
      if (!resource.exists) {
        sendResponse(Response.invalidParameter(request, 'file', 'Must exist'));
        return;
      } else if (resource is! File) {
        sendResponse(Response.invalidParameter(
            request, 'file', 'Must not refer to a directory'));
        return;
      }

      var source = driver.fsState.getFileForPath(file).source;
      if (!source.uri.isScheme('file')) {
        uri = source.uri.toString();
      } else {
        uri = sourceFactory.pathToUri(file).toString();
      }
      sendResult(ExecutionMapUriResult(uri: uri));
      return;
    } else if (uri != null) {
      var source = sourceFactory.forUri(uri);
      if (source == null) {
        sendResponse(Response.invalidParameter(request, 'uri', 'Invalid URI'));
        return;
      }
      file = source.fullName;
      sendResult(ExecutionMapUriResult(file: file));
      return;
    }
    sendResponse(Response.invalidParameter(
        request, 'file', 'Either file or uri must be provided'));
  }
}
