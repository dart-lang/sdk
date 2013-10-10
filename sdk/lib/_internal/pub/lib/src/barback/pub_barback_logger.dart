// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.pub_barback_logger;

import 'package:barback/barback.dart';

import '../log.dart' as log;

/// A [BarbackLogger] that routes through pub's logging code.
class PubBarbackLogger implements BarbackLogger {
  /// Since both [LogEntry] objects and the message itself often redundantly
  /// show the same context like the file where an error occurred, this tries
  /// to avoid showing redundant data in the entry.
  void logEntry(LogEntry entry) {
    messageMentions(String text) {
      return entry.message.toLowerCase().contains(text.toLowerCase());
    }

    var prefixParts = [];

    // Show the level (unless the message mentions it.)
    if (!messageMentions(entry.level.name)) {
      prefixParts.add("${entry.level} in");
    }

    // Show the transformer.
    prefixParts.add(entry.transform.transformer);

    // Mention the primary input of the transform unless the message seems to.
    if (!messageMentions(entry.transform.primaryId.path)) {
      prefixParts.add("on ${entry.transform.primaryId}");
    }

    // If the relevant asset isn't the primary input, mention it unless the
    // message already does.
    if (entry.asset != entry.transform.primaryId &&
        !messageMentions(entry.asset.path)) {
      prefixParts.add("with input ${entry.asset}");
    }

    var prefix = "[${prefixParts.join(' ')}]:";
    var message = entry.message;
    if (entry.span != null) {
      message = entry.span.getLocationMessage(entry.message);
    }

    switch (entry.level) {
      case LogLevel.ERROR:
        log.error("${log.red(prefix)}\n$message");
        break;

      case LogLevel.WARNING:
        log.warning("${log.yellow(prefix)}\n$message");
        break;

      case LogLevel.INFO:
        log.message("$prefix\n$message");
        break;
    }
  }
}
