// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';

/// The handler used for the request that are no longer supported.
class UnsupportedRequestHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  UnsupportedRequestHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    sendResponse(Response.unsupportedFeature(request.id,
        'Please contact the Dart analyzer team if you need this request.'));
  }
}
