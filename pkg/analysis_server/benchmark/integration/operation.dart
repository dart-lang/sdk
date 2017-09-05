// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:logging/logging.dart';

import 'driver.dart';
import 'input_converter.dart';

/**
 * A [CompletionRequestOperation] tracks response time along with
 * the first and last completion notifications.
 */
class CompletionRequestOperation extends RequestOperation {
  Driver driver;
  StreamSubscription<CompletionResultsParams> subscription;
  String notificationId;
  Stopwatch stopwatch;
  bool firstNotification = true;

  CompletionRequestOperation(
      CommonInputConverter converter, Map<String, dynamic> json)
      : super(converter, json);

  @override
  Future perform(Driver driver) {
    this.driver = driver;
    subscription = driver.onCompletionResults.listen(processNotification);
    return super.perform(driver);
  }

  void processNotification(CompletionResultsParams event) {
    if (event.id == notificationId) {
      Duration elapsed = stopwatch.elapsed;
      if (firstNotification) {
        firstNotification = false;
        driver.results.record('completion notification first', elapsed,
            notification: true);
      }
      if (event.isLast) {
        subscription.cancel();
        driver.results.record('completion notification last', elapsed,
            notification: true);
      }
    }
  }

  @override
  void processResult(
      String id, Map<String, dynamic> result, Stopwatch stopwatch) {
    notificationId = result['id'];
    this.stopwatch = stopwatch;
    super.processResult(id, result, stopwatch);
  }
}

/**
 * An [Operation] represents an action such as sending a request to the server.
 */
abstract class Operation {
  Future perform(Driver driver);
}

/**
 * A [RequestOperation] sends a [JSON] request to the server.
 */
class RequestOperation extends Operation {
  final CommonInputConverter converter;
  final Map<String, dynamic> json;

  RequestOperation(this.converter, this.json);

  @override
  Future perform(Driver driver) {
    Stopwatch stopwatch = new Stopwatch();
    String originalId = json['id'];
    String method = json['method'];
    json['clientRequestTime'] = new DateTime.now().millisecondsSinceEpoch;
    driver.logger.log(Level.FINE, 'Sending request: $method\n  $json');
    stopwatch.start();

    void recordResult(bool success, result) {
      Duration elapsed = stopwatch.elapsed;
      driver.results.record(method, elapsed, success: success);
      driver.logger
          .log(Level.FINE, 'Response received: $method : $elapsed\n  $result');
    }

    driver
        .send(method, converter.asMap(json['params']))
        .then((Map<String, dynamic> result) {
      recordResult(true, result);
      processResult(originalId, result, stopwatch);
    }).catchError((exception) {
      recordResult(false, exception);
      converter.processErrorResponse(originalId, exception);
    });
    return null;
  }

  void processResult(
      String id, Map<String, dynamic> result, Stopwatch stopwatch) {
    converter.processResponseResult(id, result);
  }
}

/**
 * A [ResponseOperation] waits for a [JSON] response from the server.
 */
class ResponseOperation extends Operation {
  static final Duration responseTimeout = new Duration(seconds: 60);
  final CommonInputConverter converter;
  final Map<String, dynamic> requestJson;
  final Map<String, dynamic> responseJson;
  final Completer completer = new Completer();
  Driver driver;

  ResponseOperation(this.converter, this.requestJson, this.responseJson) {
    completer.future.then(_processResult).timeout(responseTimeout);
  }

  @override
  Future perform(Driver driver) {
    this.driver = driver;
    return converter.processExpectedResponse(responseJson['id'], completer);
  }

  bool _equal(expectedResult, actualResult) {
    if (expectedResult is Map && actualResult is Map) {
      if (expectedResult.length == actualResult.length) {
        return expectedResult.keys.every((key) {
          return key ==
                  'fileStamp' || // fileStamp values will not be the same across runs
              _equal(expectedResult[key], actualResult[key]);
        });
      }
    } else if (expectedResult is List && actualResult is List) {
      if (expectedResult.length == actualResult.length) {
        for (int i = 0; i < expectedResult.length; ++i) {
          if (!_equal(expectedResult[i], actualResult[i])) {
            return false;
          }
        }
        return true;
      }
    }
    return expectedResult == actualResult;
  }

  /**
   * Compare the expected and actual server response result.
   */
  void _processResult(actualResult) {
    var expectedResult = responseJson['result'];
    if (!_equal(expectedResult, actualResult)) {
      var expectedError = responseJson['error'];
      String format(value) {
        String text = '\n$value';
        if (text.endsWith('\n')) {
          text = text.substring(0, text.length - 1);
        }
        return text.replaceAll('\n', '\n  ');
      }

      String message = 'Request:${format(requestJson)}\n'
          'expected result:${format(expectedResult)}\n'
          'expected error:${format(expectedError)}\n'
          'but received:${format(actualResult)}';
      driver.results.recordUnexpectedResults(requestJson['method']);
      converter.logOverlayContent();
      if (expectedError == null) {
        converter.logger.log(Level.SEVERE, message);
      } else {
        throw message;
      }
    }
  }
}

class StartServerOperation extends Operation {
  @override
  Future perform(Driver driver) {
    return driver.startServer();
  }
}

class WaitForAnalysisCompleteOperation extends Operation {
  @override
  Future perform(Driver driver) {
    DateTime start = new DateTime.now();
    driver.logger.log(Level.FINE, 'waiting for analysis to complete');
    StreamSubscription<ServerStatusParams> subscription;
    Timer timer;
    Completer completer = new Completer();
    bool isAnalyzing = false;
    subscription = driver.onServerStatus.listen((ServerStatusParams params) {
      if (params.analysis != null) {
        if (params.analysis.isAnalyzing) {
          isAnalyzing = true;
        } else {
          subscription.cancel();
          timer.cancel();
          DateTime end = new DateTime.now();
          Duration delta = end.difference(start);
          driver.logger.log(Level.FINE, 'analysis complete after $delta');
          completer.complete();
          driver.results.record('analysis complete', delta, notification: true);
        }
      }
    });
    timer = new Timer.periodic(new Duration(milliseconds: 20), (_) {
      if (!isAnalyzing) {
        // TODO (danrubel) revisit this once source change requests are implemented
        subscription.cancel();
        timer.cancel();
        driver.logger.log(Level.INFO, 'analysis never started');
        completer.complete();
        return;
      }
      // Timeout if no communication received within the last 60 seconds.
      double currentTime = driver.server.currentElapseTime;
      double lastTime = driver.server.lastCommunicationTime;
      if (currentTime - lastTime > 60) {
        subscription.cancel();
        timer.cancel();
        String message = 'gave up waiting for analysis to complete';
        driver.logger.log(Level.WARNING, message);
        completer.completeError(message);
      }
    });
    return completer.future;
  }
}
