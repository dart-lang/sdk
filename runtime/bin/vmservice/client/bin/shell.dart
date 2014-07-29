// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shell;

import 'package:observatory/service_io.dart';

import 'dart:io';

// Simple demo for service_io library. Connects to localhost on the default
// port, picks the first isolate, reads requests from stdin, and prints
// results to stdout. Example session:
// <<< prefix /isolates/1071334835
// >>> /classes/40
// <<< {"type":"Class","id":"classes\/40","name":"num","user_name":"num",...
// >>> /objects/0
// >>> {"type":"Array","class":{"type":"@Class","id":"classes\/62",...

void repl(VM vm, String prefix, String lastResult) {
  print(lastResult);
  // TODO(koda): Use 'get' when ServiceObjects have more informative toString.
  vm.getString(prefix + stdin.readLineSync()).then((String result) {
    repl(vm, prefix, result);
  });
}

void main() {
  String addr = 'ws://localhost:8181/ws';
  new WebSocketVM(new WebSocketVMTarget(addr)).get('vm').then((VM vm) {
    Isolate isolate = vm.isolates.first;
    String prefix = '${isolate.link}';
    repl(vm, prefix, 'prefix $prefix');
  });
}
