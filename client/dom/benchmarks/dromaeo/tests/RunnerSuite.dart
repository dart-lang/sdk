typedef void Test();
typedef void Operation();
typedef void Reporter(Map<String, Result> results);

class Suite {
  /**
   * Ctor.
   *  [:_window:] The window of the suite.
   *  [:_name:] The name of the suite.
   */
  Suite(this._window, this._name) :
      _operations = new List<Operation>(),
      _nTests = 0, _nRanTests = 0 {
    _window.addEventListener(
        'message',
        (MessageEvent event) {
          String command = event.data;
          switch (command) {
            case 'start':
              _run();
              return;

            default:
              _window.alert('[${_name}]: unknown command ${command}');
          }
        },
        false
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
      List<double> runsPerSecond = new List<double>();

      // Run the test several times.
      try {
        // TODO(antonm): use .setTimeout to schedule next run as JS
        // version does.  That allows to report the intermidiate results
        // more smoothly as well.
        for (int i = 0; i < _N_RUNS; i++) {
          int runs = 0;
          final int start = new DateTime.now().value;

          int cur = new DateTime.now().value;
          while ((cur - start) < 1000) {
            test();
            cur = new DateTime.now().value;
            runs++;
          }

          runsPerSecond.add((runs * 1000.0) / (cur - start));
        }
      } catch(var exception, var stacktrace) {
        _window.alert('Exception ${exception}: ${stacktrace}');
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
        _window.setTimeout(handler, 1);
      } else {
        _postMessage('over');
      }
    }
    _window.setTimeout(handler, 0);
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
    // TODO(antonm): Remove dynamic below.
    _window.top.dynamic.postMessage(JSON.stringify(payload), '*');
  }

  // Implementation.

  final Window _window;
  final String _name;

  List<Operation> _operations;
  int _nTests;
  int _nRanTests;

  Suite _addOperation(Operation operation) {
    _operations.add(operation);
    return this;
  }
}
