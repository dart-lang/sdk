// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../test_pub.dart';

/// The buildbots do not have the Dart SDK (containing "dart" and "pub") on
/// their PATH, so we need to spawn the binstub process with a PATH that
/// explicitly includes it.
Future<Map> getEnvironment() {
  final completer0 = new Completer();
  scheduleMicrotask(() {
    try {
      var binDir = p.dirname(Platform.executable);
      join0(x0) {
        var separator = x0;
        var path = "${Platform.environment["PATH"]}${separator}${binDir}";
        getPubTestEnvironment().then((x1) {
          try {
            var environment = x1;
            environment["PATH"] = path;
            completer0.complete(environment);
          } catch (e0, s0) {
            completer0.completeError(e0, s0);
          }
        }, onError: completer0.completeError);
      }
      if (Platform.operatingSystem == "windows") {
        join0(";");
      } else {
        join0(":");
      }
    } catch (e, s) {
      completer0.completeError(e, s);
    }
  });
  return completer0.future;
}
