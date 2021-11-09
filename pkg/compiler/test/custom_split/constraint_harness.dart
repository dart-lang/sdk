// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert';
import 'dart:isolate';

import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';

typedef ImportsProcessor = List<Node> Function(List<String>);

/// A helper function which waits for a list of deferred imports, and then
/// invokes the supplied [processFunc]. The list of nodes returned from
/// [processFunc] will then be serialized as json and sent back over the
/// supplied [sendPort].
void waitForImportsAndInvoke(
    SendPort sendPort, ImportsProcessor importsProcessor) async {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  var msg = await receivePort.first;
  assert(msg is List<String>);
  var constraints = importsProcessor(msg);
  sendPort.send(JsonEncoder.withIndent('  ').convert(constraints));
  receivePort.close();
}
