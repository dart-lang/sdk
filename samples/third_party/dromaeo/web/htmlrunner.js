// An version of Dromaeo's original htmlrunner adapted for the
// Dart-based test driver.

var _operations = [];
var _N_RUNS = 5;
var _nRanTests = 0;
var _nTests = 0;
var _T_DISTRIBUTION = 2.776;

function startTest() {
  window.addEventListener(
      'message',
      function (event) {
        if (event.data == 'start') {
          _run();
        } else {
          window.alert('Unknown command: ' + event.data);
        }
      },
      false);
}

function _run() {
  var currentOperation = 0;
  function handler() {
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

function _postMessage(command, data) {
  var payload = { 'command': command };
  if (data) {
    payload['data'] = data;
  }
  window.parent.postMessage(JSON.stringify(payload), '*');
}

function test(name, fn) {
  _nTests++;
  _operations.push(function () {
      // List of number of runs in seconds.
      var runsPerSecond = [];
      // Run the test several times.
      try {
        // TODO(antonm): use .setTimeout to schedule next run as JS
        // version does.  That allows to report the intermediate results
        // more smoothly as well.
        for (var i = 0; i < _N_RUNS; i++) {
          var runs = 0;
          var start = Date.now();

          var cur = Date.now();
          while ((cur - start) < 1000) {
            fn();
            cur = Date.now();
            runs++;
          }

          runsPerSecond.push((runs * 1000.0) / (cur - start));
        }
      } catch(e) {
        window.alert('Exception : ' + e);
        return;
      }
      _reportTestResults(name, runsPerSecond);
    });
}

// Adapted from Dromaeo's webrunner.
function _compute(times){
  var results = {runs: times.length}, num = times.length;

  times = times.sort(function(a,b){
      return a - b;
    });

  // Make Sum
  results.sum = 0;

  for ( var i = 0; i < num; i++ )
    results.sum += times[i];

  // Make Min
  results.min = times[0];

  // Make Max
  results.max = times[ num - 1 ];

  // Make Mean
  results.mean = results.sum / num;

  // Make Median
  results.median = num % 2 == 0 ?
      (times[Math.floor(num/2)] + times[Math.ceil(num/2)]) / 2 :
      times[Math.round(num/2)];

  // Make Variance
  results.variance = 0;

  for ( var i = 0; i < num; i++ )
    results.variance += Math.pow(times[i] - results.mean, 2);

  results.variance /= num - 1;

  // Make Standard Deviation
  results.deviation = Math.sqrt( results.variance );

  // Compute Standard Errors Mean
  results.sem = (results.deviation / Math.sqrt(results.runs)) * _T_DISTRIBUTION;

  // Error
  results.error = ((results.sem / results.mean) * 100) || 0;

  return results;
}

function _reportTestResults(name, times) {
  _nRanTests++;
  var results = _compute(times);

  _postMessage('result', {
      'testName': name,
      'mean': results.mean,
      'error': results.error,
      'percent': (100.0 * _nRanTests / _nTests)
          });
}

function endTest() {
  _postMessage('inited', { 'nTests': _nTests });
}

function prep(fn) {
  _operations.push(fn);
}
