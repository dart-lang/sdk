// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A command line debugger implemented using the VM Service protocol.

library ddbg2;

import "dart:async";

import 'package:ddbg/debugger.dart';

Debugger debugger;

void onError(self, parent, zone, error, StackTrace trace) {
  if (debugger != null) {
    debugger.onUncaughtError(error, trace);
  } else {
    print('\n--------\nExiting due to unexpected error:\n'
          '  $error\n$trace\n');
    exit();
  }
}

void main(List<String> args) {
  // Setup a zone which will exit the debugger cleanly on any uncaught
  // exception.
  var zone = Zone.ROOT.fork(specification:new ZoneSpecification(
      handleUncaughtError: onError));
  
  zone.run(() {
      debugger = new Debugger();
  });
}
