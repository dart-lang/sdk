typedef void Test();
typedef void Operation();
typedef void Reporter(Map<String, Result> results);

class Suite {
  /**
   * Ctor.
   *  [:_name:] The name of the suite.
   */
  Suite(this._name) :
      _operations = new Array<Operation>(),
      _nTests = 0, _nRanTests = 0 {
    window.on.message.add(
        (MessageEvent event) {
          String command = event.data;
          switch (command) {
            case 'start':
              _run();
              return;

            default:
              window.alert('[${_name}]: unknown command ${command}');
          }
        }
    );
  }

  /**
   * Adds a preparation step to the suite.
   * [:operation:] The operation to be performed.
   */
  Suite prep(Operation operation){
    return _addOperation(operation);
  }

  // How many times each individual test should be ran.
  static final int _N_RUNS = 5;

  /**
   * Adds another test to the suite.
   * [:name:] The unique name of the test
   * [:test:] A function holding the test to run
   */
  Suite test(String name, Test test) {
    _nTests++;
    // Don't execute the test immediately.
    return _addOperation(() {
      // List of number of runs in seconds.
      Array<double> runsPerSecond = new Array<double>();

      // Run the test several times.
      try {
        // TODO(antonm): use .setTimeout to schedule next run as JS
        // version does.  That allows to report the intermidiate results
        // more smoothly as well.
        for (int i = 0; i < _N_RUNS; i++) {
          int runs = 0;
          final int start = new Date.now().value;

          int cur = new Date.now().value;
          while ((cur - start) < 1000) {
            test();
            cur = new Date.now().value;
            runs++;
          }

          runsPerSecond.add((runs * 1000.0) / (cur - start));
        }
      } catch(var exception, var stacktrace) {
        window.alert('Exception ${exception}: ${stacktrace}');
        return;
      }
      _reportTestResults(name, new Result(runsPerSecond));
    });
  }

  /**
   * Finalizes the suite.
   * It might either run the tests immediately or schedule them to be ran later.
   */
  void end() {
    _postMessage('inited', { 'nTests': _nTests });

  }

  _run() {
    int currentOperation = 0;
    handler() {
      if (currentOperation < _operations.length) {
        _operations[currentOperation]();
        currentOperation++;
        window.setTimeout(handler, 1);
      } else {
        _postMessage('over');
      }
    }
    window.setTimeout(handler, 0);
  }

  _reportTestResults(String name, Result result) {
    _nRanTests++;
    _postMessage('result', {
        'testName': name,
        'mean': result.mean,
        'error': result.error / result.mean,
        'percent': (100.0 * _nRanTests / _nTests)
    });
  }

  _postMessage(String command, [var data = null]) {
    final payload = { 'command': command };
    if (data != null) {
      payload['data'] = data;
    }
    window.top.postMessage(JSON.stringify(payload), '*');
  }

  // Implementation.

  final String _name;

  Array<Operation> _operations;
  int _nTests;
  int _nRanTests;

  Suite _addOperation(Operation operation) {
    _operations.add(operation);
    return this;
  }
}
