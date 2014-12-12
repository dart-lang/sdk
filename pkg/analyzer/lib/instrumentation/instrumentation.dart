// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation;

/**
 * The interface used by client code to communicate with an instrumentation
 * server.
 */
abstract class InstrumentationServer {
  /**
   * Pass the given [message] to the instrumentation server so that it will be
   * logged with other messages.
   *
   * This method should be used for most logging.
   */
  void log(String message);

  /**
   * Pass the given [message] to the instrumentation server so that it will be
   * logged with other messages.
   *
   * This method should only be used for logging high priority messages, such as
   * exceptions that cause the server to shutdown.
   */
  void logWithPriority(String message);

  /**
   * Signal that the client is done communicating with the instrumentation
   * server. This method should be invoked exactly one time and no other methods
   * should be invoked on this instance after this method has been invoked.
   */
  void shutdown();
}

/**
 * The interface used by client code to communicate with an instrumentation
 * server by wrapping an [InstrumentationServer].
 */
class InstrumentationService {
  /**
   * An instrumentation service that will not log any instrumentation data.
   */
  static const InstrumentationService NULL_SERVICE =
      const InstrumentationService(null);

  static const String TAG_NOTIFICATION = 'Noti';
  static const String TAG_REQUEST = 'Req';
  static const String TAG_RESPONSE = 'Res';
  static const String TAG_VERSION = 'Ver';
  /**
   * The instrumentation server used to communicate with the server, or `null`
   * if instrumentation data should not be logged.
   */
  final InstrumentationServer instrumentationServer;

  /**
   * Initialize a newly created instrumentation service to comunicate with the
   * given instrumentation server.
   */
  const InstrumentationService(this.instrumentationServer);

  /**
   * The current time, expressed as a decimal encoded number of milliseconds.
   */
  String get _timestamp => new DateTime.now().millisecond.toString();

  /**
   * Log that a notification has been sent to the client.
   */
  void logNotification(String notification) {
    _log(TAG_NOTIFICATION, notification);
  }

  /**
   * Log that a request has been sent to the client.
   */
  void logRequest(String request) {
    _log(TAG_REQUEST, request);
  }

  /**
   * Log that a response has been sent to the client.
   */
  void logResponse(String response) {
    _log(TAG_RESPONSE, response);
  }

  /**
   * Signal that the client is done communicating with the instrumentation
   * server. This method should be invoked exactly one time and no other methods
   * should be invoked on this instance after this method has been invoked.
   */
  void shutdown() {
    if (instrumentationServer != null) {
      instrumentationServer.shutdown();
    }
  }

  /**
   * Log the given message with the given tag.
   */
  void _log(String tag, String message) {
    if (instrumentationServer != null) {
      instrumentationServer.log('$_timestamp:$tag:$message');
    }
  }
}
