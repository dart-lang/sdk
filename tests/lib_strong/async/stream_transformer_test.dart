// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'event_helper.dart';

_defaultData(x) {}
_defaultError(e, [st]) {}
_defaultDone() {}

/// Dummy StreamSubscription.
class MyStreamSubscription<T> implements StreamSubscription<T> {
  final Stream stream;
  final bool cancelOnError;
  Function handleData = null;
  Function handleError = null;
  Function handleDone = null;

  MyStreamSubscription(this.stream, this.cancelOnError);

  Future cancel() => null;
  void onData(void handleData(T data)) {
    this.handleData = handleData == null ? _defaultData : handleData;
  }

  void onError(Function handleError) {
    this.handleError = handleError == null ? _defaultError : handleError;
  }

  void onDone(void handleDone()) {
    this.handleDone = handleDone == null ? _defaultDone : handleDone;
  }

  void pause([Future resumeSignal]) {}
  void resume() {}

  final isPaused = false;
  Future asFuture([var futureValue]) => null;
}

main() {
  var transformer = new StreamTransformer<int, String>(
      (stream, cancelOnError) =>
          new MyStreamSubscription(stream, cancelOnError));

  var controller = new StreamController(sync: true);
  var stream = controller.stream;
  var transformed = stream.transform(transformer);

  var handleData = (String _) => 499;
  var handleError = (e, st) => 42;
  var handleDone = () => 99;

  var subscription =
      transformed.listen(handleData, onError: handleError, onDone: handleDone);

  Expect.identical(stream, subscription.stream);
  Expect.equals(false, subscription.cancelOnError);
  Expect.identical(handleData, subscription.handleData);
  Expect.identical(handleError, subscription.handleError);
  Expect.identical(handleDone, subscription.handleDone);

  // Note that we reuse the transformer.

  controller = new StreamController(sync: true);
  stream = controller.stream;
  transformed = stream.transform(transformer);
  subscription = transformed.listen(null);

  Expect.identical(stream, subscription.stream);
  Expect.equals(false, subscription.cancelOnError);
  Expect.identical(_defaultData, subscription.handleData);
  Expect.identical(_defaultError, subscription.handleError);
  Expect.identical(_defaultDone, subscription.handleDone);

  controller = new StreamController(sync: true);
  stream = controller.stream;
  transformed = stream.transform(transformer);
  subscription =
      transformed.listen(null, onDone: handleDone, cancelOnError: true);

  Expect.identical(stream, subscription.stream);
  Expect.equals(true, subscription.cancelOnError);
  Expect.identical(_defaultData, subscription.handleData);
  Expect.identical(_defaultError, subscription.handleError);
  Expect.identical(handleDone, subscription.handleDone);
}
