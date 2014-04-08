// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.log;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

import 'mock.dart';

/// A transformer that logs given entries during its apply.
class LogTransformer extends MockTransformer {
  /// The list of entries that it should log.
  ///
  /// Each entry has the log level followed by the message, like:
  ///
  ///     error: This is the error message.
  final List<String> _entries;

  LogTransformer(this._entries);

  Future<bool> doIsPrimary(_) => new Future.value(true);

  Future doApply(Transform transform) {
    return newFuture(() {
      for (var entry in _entries) {
        var parts = entry.split(":");
        var logFn;
        switch (parts[0]) {
          case "error":   logFn = transform.logger.error; break;
          case "warning": logFn = transform.logger.warning; break;
          case "info":    logFn = transform.logger.info; break;
          case "fine":    logFn = transform.logger.fine; break;
        }

        logFn(parts[1].trim());
      }
    });
  }
}
