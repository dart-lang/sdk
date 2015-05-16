part of dromaeo;

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
    starter(MessageEvent event) {
      String command = event.data;
      switch (command) {
        case 'start':
          _run();
          return;
        default:
          _window.alert('[${_name}]: unknown command ${command}');
      }
    };
    _window.onMessage.listen(starter);
  }

  /**
   * Adds a preparation step to the suite.
   * [:operation:] The operation to be performed.
   */
  Suite prep(Operation operation){
    return _addOperation(operation);
  }

  // How many times each individual test should be ran.
  static const int _N_RUNS = 5;

  /**
   * Adds another test to the suite.
   * [:name:] The unique name of the test
   * [:test:] A function holding the test to run
   */
  Suite test(String name, Test test_) {
    _nTests++;
    // Don't execute the test immediately.
    return _addOperation(() {
      // List of number of runs in seconds.
      List<double> runsPerSecond = new List<double>();

      // Run the test several times.
      try {
        // TODO(antonm): use timer to schedule next run as JS
        // version does.  That allows to report the intermidiate results
        // more smoothly as well.
        for (int i = 0; i < _N_RUNS; i++) {
          int runs = 0;
          final int start = new DateTime.now().millisecondsSinceEpoch;

          int cur = new DateTime.now().millisecondsSinceEpoch;
          while ((cur - start) < 1000) {
            test_();
            cur = new DateTime.now().millisecondsSinceEpoch;
            runs++;
          }

          runsPerSecond.add((runs * 1000.0) / (cur - start));
        }
      } catch (exception, stacktrace) {
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
        new Timer(const Duration(milliseconds: 1), handler);
      } else {
        _postMessage('over');
      }
    }
    Timer.run(handler);
  }

  _reportTestResults(String name, Result result) {
    _nRanTests++;
    _postMessage('result', {
        'testName': name,
        'mean': result.mean,
        'error': result.error,
        'percent': (100.0 * _nRanTests / _nTests)
    });
  }

  _postMessage(String command, [var data = null]) {
    final payload = { 'command': command };
    if (data != null) {
      payload['data'] = data;
    }
    _window.parent.postMessage(JSON.encode(payload), '*');
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
