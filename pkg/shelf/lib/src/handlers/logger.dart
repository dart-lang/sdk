// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.handlers.logger;

import 'package:stack_trace/stack_trace.dart';

import '../middleware.dart';
import '../util.dart';

/// Middleware which prints the time of the request, the elapsed time for the
/// inner handlers, the response's status code and the request URI.
///
/// [logger] takes two paramaters.
///
/// `msg` includes the request time, duration, request method, and requested
/// path.
///
/// For successful requests, `msg` also includes the status code.
///
/// When an error is thrown, `isError` is true and `msg` contains the error
/// description and stack trace.
Middleware logRequests({void logger(String msg, bool isError)}) =>
    (innerHandler) {
  if (logger == null) logger = _defaultLogger;

  return (request) {
    var startTime = new DateTime.now();
    var watch = new Stopwatch()..start();

    return syncFuture(() => innerHandler(request)).then((response) {
      var msg = _getMessage(startTime, response.statusCode, request.url,
          request.method, watch.elapsed);

      logger(msg, false);

      return response;
    }, onError: (error, stackTrace) {
      var msg = _getErrorMessage(startTime, request.url, request.method,
          watch.elapsed, error, stackTrace);

      logger(msg, true);

      throw error;
    });
  };
};

String _getMessage(DateTime requestTime, int statusCode, Uri url,
  String method, Duration elapsedTime) {

  return '${requestTime}\t$elapsedTime\t$method\t[${statusCode}]\t${url}';
}

String _getErrorMessage(DateTime requestTime, Uri url,
  String method, Duration elapsedTime, Object error, StackTrace stack) {

  var chain = new Chain.current();
  if (stack != null) {
    chain = new Chain.forTrace(stack)
      .foldFrames((frame) => frame.isCore || frame.package == 'shelf')
      .terse;
  }

  var msg = '${requestTime}\t$elapsedTime\t$method\t${url}\n$error';
  if(chain == null) return msg;

  return '$msg\n$chain';
}

void _defaultLogger(String msg, bool isError) {
  if (isError) {
    print('[ERROR] $msg');
  } else {
    print(msg);
  }
}
