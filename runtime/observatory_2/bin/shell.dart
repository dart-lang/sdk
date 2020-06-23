// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shell;

import 'package:observatory_2/service_io.dart';

import 'dart:io';

// Simple demo for service_io library. Connects to localhost on the default
// port, picks the first isolate, reads requests from stdin, and prints
// results to stdout. Example session:
// <<< isolate isolates/1071334835
// >>> /classes/40
// <<< {"type":"Class","id":"classes\/40","name":"num","user_name":"num",...
// >>> /objects/0
// >>> {"type":"Array","class":{"type":"@Class","id":"classes\/62",...

void repl(VM vm, Isolate isolate, String lastResult) {
  print(lastResult);
  Map params = {
    'objectId': stdin.readLineSync(),
  };
  isolate.invokeRpcNoUpgrade('getObject', params).then((Map result) {
    repl(vm, isolate, result.toString());
  });
}

void main() {
  String addr = 'ws://localhost:8181/ws';
  new WebSocketVM(new WebSocketVMTarget(addr)).load().then((serviceObject) {
    VM vm = serviceObject;
    Isolate isolate = vm.isolates.first;
    repl(vm, isolate, 'isolate ${isolate.id}');
  });
}
