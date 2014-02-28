// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart script to launch performance tests without WebDriver/Selenium.
///
/// WARNING: Although this is laid out like a package, it is not really a
/// package since it relies on test.dart files!
library browser_perf_testing;

import '../../browser_controller.dart';
import '../../utils.dart';
import '../../http_server.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:args/args.dart' as args_parser;

final String ADDRESS = '127.0.0.1';

/// A map that is passed to the testing framework to specify what ports the
/// browser controller runs on.
final Map SERVER_CONFIG = {
  'test_driver_port': 0,
  'test_driver_error_port': 0
};

void main (List<String> args) {
  var options = _parseArguments(args);

  // Start a server to serve the entire repo: the http server is available on
  // window.location.port.
  var servers = new TestingServers(
      new Path('/Users/efortuna/dart-git2/dart/xcodebuild/ReleaseIA32'),
      false, options['browser'], path.dirname(path.dirname(path.dirname(
      path.dirname(path.dirname(path.dirname(Platform.script.path)))))));
  servers.startServers(ADDRESS).then((_) {
    _runPerfTests(options, servers);
  });
}

/// Helper function to parse the arguments for this file.
Map _parseArguments(List<String> args) {
  var parser =  new args_parser.ArgParser();
  parser.addOption('browser', defaultsTo: 'chrome', help: 'Name of the browser'
      ' to run this test with.');
  parser.addOption('termination_test_file', defaultsTo:
      '/root_dart/samples/third_party/dromaeo/dromaeo_end_condition.js',
      help: 'Path to a javascript file that contains the function '
      '"testIsComplete" tests whether the performance test has finished '
      'running. This is in a form that can be served up by '
      'http_server.dart, so it begins with /root_dart or some other server '
      'understood prefix.');
  parser.addOption('test_path', defaultsTo:
      '/root_dart/samples/third_party/dromaeo/index-js.html?jsANDqueryORjs'
      'ANDtraverseORjsANDattributes', help: 'Path to the performance test we '
      'wish to run. This is in a form that can be served up by '
      'http_server.dart, so it begins with /root_dart or some other server '
      'understood prefix.');
  parser.addOption('checked', defaultsTo: false,
      help: 'Run this test in checked mode.');
  parser.addFlag('help', abbr: 'h', negatable: false, callback: (help) {
    if (help) {
      print(parser.getUsage());
      exit(0);
    };
  });
  parser.addOption('timeout', defaultsTo: 300,
      help: 'Maximum amount of time to let a test run, in seconds.');
  return parser.parse(args);
}

void _runPerfTests(Map options, TestingServers servers) {
  var browserName = options['browser'];

  var testRunner = new BrowserTestRunner(SERVER_CONFIG, ADDRESS, browserName, 1,
      checkedMode: options['checked'],
      testingServer: new BrowserPerfTestingServer(browserName,
      options['termination_test_file'], servers.port));

  var url = 'http://$ADDRESS:${servers.port}${options["test_path"]}';

  BrowserTest browserTest = new BrowserTest(url,
      (BrowserTestOutput output) {
        var eventQueue = JSON.decode(output.lastKnownMessage);
        var lastEvent = eventQueue.last;
        var lines = lastEvent['value'].split('\n');
        for (var line in lines) {
          print(line);
        }
        testRunner.terminate();
        servers.stopServers();
      }, options['timeout']);

  testRunner.start().then((started) {
    if (started) {
      testRunner.queueTest(browserTest);
    } else {
      print("Issue starting browser test runner $started");
      exit(1);
    }
  });
}

/// Server for controlling and running performance tests. Note the tests
/// themselves are served on the local file system (to eliminate any additional
/// potential sources of lag), but we need a server to communicate when the test
/// is done.
class BrowserPerfTestingServer extends BrowserTestingServer {
  // Path to the script containing the ending condition of the performance test,
  // in the form of /root_dart, /root_build, or some other, as per the form of
  // url expected from http_server.dart.
  String endConditionScript;
  /// Port number to access the server serving the whole Dart repository.
  int repoPort;

  BrowserPerfTestingServer(String browserName, this.endConditionScript,
      this.repoPort) : super(SERVER_CONFIG, ADDRESS,
      !Browser.BROWSERS_WITH_WINDOW_SUPPORT.contains(browserName));

  /// We create a slightly modified version of the original browser_controller
  /// driver page.
  String getDriverPage(String browserId) {
    var orig = super.getDriverPage(browserId);
    //TODO(efortuna): Hacky!
    var insertIndex = orig.indexOf('<script type');
    var otherInsert = orig.indexOf('} else {',
        orig.indexOf('if (isStatusUpdate)'));
    var result = orig.substring(0, insertIndex) + """
    <!-- To create a performance test, you must write a script that provides an
  ending condition for the particular test, in the form /root_dart/foo (or
  whatever base from http_server). // TODO not hard code.-->
  <script src="http://$localIp:$repoPort$endConditionScript"></script>
""" + orig.substring(insertIndex, otherInsert) + """
            if (testIsComplete(msg)) {
              var obj = new Object();
              obj['message'] = msg;
              obj['is_first_message'] = false;
              obj['is_status_update'] = false;
              obj['is_done'] = true;
              window.postMessage(JSON.stringify(obj), '*');
            }""" + orig.substring(otherInsert);
    return result;
  }
}
