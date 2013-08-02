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
  if(results == null) {
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

  TestConfiguration(this._port);

  void onInit() {}

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

makeDelayedSetup(index, s) => () {
  return new Future.delayed(new Duration(milliseconds:1), () {
    s.write('l$index U ');
  });
};

makeDelayedTeardown(index, s) => () {
  return new Future.delayed(new Duration(milliseconds:1), () {
    s.write('l$index D ');
  });
};

makeImmediateSetup(index, s) => () {
  s.write('l$index U ');
};

makeImmediateTeardown(index, s) => () {
  s.write('l$index D ');
};

runTestInIsolate() {
  port.receive((_, sendport) {
    var testConfig = new TestConfiguration(sendport);
    unittestConfiguration = testConfig;
    testFunction(testConfig);
  });
}

main() {
  spawnFunction(runTestInIsolate)
      .call('')
      .then((String msg) {
        expect(msg.trim(), equals(expected));
      });
}
