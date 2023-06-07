// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/socket_connect_debug.so
//
// Tests stack trace on socket exceptions.
//

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:native_stack_traces/native_stack_traces.dart";
import "package:path/path.dart";

Future<List<String>> findFrames(
    Dwarf dwarf, RegExp re, StackTrace stackTrace) async {
  final dwarfed = await Stream.value(stackTrace.toString())
      .transform(const LineSplitter())
      .toList();
  return Stream.fromIterable(dwarfed)
      .transform(DwarfStackTraceDecoder(dwarf))
      .where(re.hasMatch)
      .toList();
}

Future<void> main() async {
  asyncStart();
  final dwarfFromFile = Dwarf.fromFile(path.join(
      Platform.environment['TEST_COMPILATION_DIR'], 'socket_connect_debug.so'));
  if (dwarfFromFile == null) {
    Expect.fail('Debug binary is missing');
    return;
  }
  Dwarf dwarf = dwarfFromFile;
  // Test stacktrace when lookup fails
  try {
    await WebSocket.connect('ws://localhost.tld:0/ws');
  } catch (err, stackTrace) {
    Expect.contains('Failed host lookup', err.toString());
    final decoded = await findFrames(dwarf, RegExp("main"), stackTrace);
    Expect.equals(1, decoded.length);
  }

  // Test stacktrace when connection fails
  try {
    await WebSocket.connect('ws://localhost:0/ws');
  } catch (err, stackTrace) {
    Expect.contains('was not upgraded to websocket', err.toString());
    final decoded = await findFrames(dwarf, RegExp("main"), stackTrace);
    Expect.equals(1, decoded.length);
  }
  asyncEnd();
}
