// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittestTest;

Future _defer(void fn()) {
  return new Future.sync(fn);
}

String buildStatusString(int passed, int failed, int errors,
                         var results,
                         {int count: 0,
                         String setup: '', String teardown: '',
                         String uncaughtError: null,
                         String message: ''}) {
  var totalTests = 0;
  var testDetails = new StringBuffer();
  if (results == null) {
    // no op
    assert(message == '');
  } else if (results is String) {
    totalTests = passed + failed + errors;
    testDetails.write(':$results:$message');
  } else {
    totalTests = results.length;
    for (var i = 0; i < results.length; i++) {
      testDetails.write(':${results[i].description}:'
          '${collapseWhitespace(results[i].message)}');
    }
  }
  return '$passed:$failed:$errors:$totalTests:$count:'
      '$setup:$teardown:$uncaughtError$testDetails';
}

class TestConfiguration extends Configuration {

  // Some test state that is captured.
  int count = 0; // A count of callbacks.
  String setup = ''; // The name of the test group setup function, if any.
  String teardown = ''; // The name of the group teardown function, if any.

  // The port to communicate with the parent isolate
  final SendPort _port;
  String _result;

  TestConfiguration(this._port): super.blank();

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    _result = buildStatusString(passed, failed, errors, results,
        count: count, setup: setup, teardown: teardown,
        uncaughtError: uncaughtError);
  }

  void onDone(bool success) {
    _port.send(_result);
  }
}

Function makeDelayedSetup(index, s) => () {
  return new Future.delayed(new Duration(milliseconds: 1), () {
    s.write('l$index U ');
  });
};

Function makeDelayedTeardown(index, s) => () {
  return new Future.delayed(new Duration(milliseconds: 1), () {
    s.write('l$index D ');
  });
};

Function makeImmediateSetup(index, s) => () {
  s.write('l$index U ');
};

Function makeImmediateTeardown(index, s) => () {
  s.write('l$index D ');
};

void runTestInIsolate(sendport) {
  var testConfig = new TestConfiguration(sendport);
  unittestConfiguration = testConfig;
  testFunction(testConfig);
}

void main() {
  var replyPort = new ReceivePort();
  Isolate.spawn(runTestInIsolate, replyPort.sendPort);
  replyPort.first.then((String msg) {
    expect(msg.trim(), expected);
  });
}
