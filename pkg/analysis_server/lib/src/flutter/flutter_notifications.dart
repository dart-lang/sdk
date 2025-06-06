// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/exception/exception.dart';

void sendFlutterNotificationOutline(
  LegacyAnalysisServer server,
  ResolvedUnitResult resolvedUnit,
) {
  _sendNotification(server, () {
    var computer = FlutterOutlineComputer(resolvedUnit);
    var outline = computer.compute();
    // send notification
    var params = protocol.FlutterOutlineParams(resolvedUnit.path, outline);
    server.sendNotification(
      params.toNotification(clientUriConverter: server.uriConverter),
    );
  });
}

/// Runs the given notification producing function [f], catching exceptions.
void _sendNotification(LegacyAnalysisServer server, void Function() f) {
  try {
    f();
  } catch (exception, stackTrace) {
    server.instrumentationService.logException(
      CaughtException.withMessage(
        'Failed to send notification',
        exception,
        stackTrace,
      ),
    );
  }
}
