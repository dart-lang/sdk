// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Meta data for a remote Dart function in Chrome.
class FunctionMetaData {
  final String name;
  FunctionMetaData(this.name);

  /// Returns the [FunctionMetaData] for the Chrome [remoteObject].
  static Future<FunctionMetaData> metaDataFor(
    RemoteDebugger remoteDebugger,
    RemoteObject remoteObject,
  ) async {
    final evalExpression = globalToolConfiguration
        .loadStrategy
        .dartRuntimeDebugger
        .getFunctionMetadataJsExpression();

    final response = await remoteDebugger.sendCommand(
      'Runtime.callFunctionOn',
      params: {
        'functionDeclaration': evalExpression,
        'objectId': remoteObject.objectId,
        'returnByValue': true,
      },
    );
    handleErrorIfPresent(response, evalContents: evalExpression);
    final name =
        (response.result?['result'] as Map<String, dynamic>?)?['value']
            as String?;
    if (name == null) return FunctionMetaData('<unknown>');
    if (name.isEmpty) return FunctionMetaData('Closure');
    return FunctionMetaData(name);
  }
}
