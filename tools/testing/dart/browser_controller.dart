// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library browser;

import "dart:async";
import "dart:core";
import "dart:io";

import 'android.dart';
import 'utils.dart';

/** Class describing the interface for communicating with browsers. */
abstract class Browser {
  StringBuffer _stdout = new StringBuffer();
  StringBuffer _stderr = new StringBuffer();
  StringBuffer _usageLog = new StringBuffer();
  // This function is called when the process is closed.
  Completer _processClosedCompleter = new Completer();
  // This is called after the process is closed, after _processClosedCompleter
  // has been called, but before onExit. Subclasses can use this to cleanup
  // any browser specific resources (temp directories, profiles, etc)
  // The function is expected to do it's work synchronously.
  Function _cleanup;

  /** The version of the browser - normally set when starting a browser */
  String version = "";
  /**
   * The underlying process - don't mess directly with this if you don't
   * know what you are doing (this is an interactive process that needs
   * special threatment to not leak).
   */
  Process process;

  Function logger;

  /**
   * Id of the browser
   */
  String id;

  /** Print everything (stdout, stderr, usageLog) whenever we add to it */
  bool debugPrint = false;

  // This future will be lazily set when calling close() and will complete once
  // the process did exit.
  Future browserTerminationFuture;

  Browser();

  factory Browser.byName(String name) {
    if (name == 'ff' || name == 'firefox') {
      return new Firefox();
    } else if (name == 'chrome') {
      return new Chrome();
    } else if (name == 'safari') {
      return new Safari();
    } else {
      throw "Non supported browser";
    }
  }

  static const List<String> SUPPORTED_BROWSERS =
      const ['safari', 'ff', 'firefox', 'chrome'];

  static const List<String> BROWSERS_WITH_WINDOW_SUPPORT =
      const ['safari', 'ff', 'firefox', 'chrome'];

  // TODO(kustermann): add standard support for chrome on android
  static bool supportedBrowser(String name) {
    return SUPPORTED_BROWSERS.contains(name);
  }

  void _logEvent(String event) {
    String toLog = "$this ($id) - $event \n";
    if (debugPrint) print("usageLog: $toLog");
    if (logger != null) logger(toLog);
    _usageLog.write(toLog);
  }

  void _addStdout(String output) {
    if (debugPrint) print("stdout: $output");
    _stdout.write(output);
  }

  void _addStderr(String output) {
    if (debugPrint) print("stderr: $output");
    _stderr.write(output);
  }

  Future close() {
    _logEvent("Close called on browser");
    if (browserTerminationFuture == null) {
      var completer = new Completer();
      browserTerminationFuture = completer.future;

      if (process != null) {
        _processClosedCompleter.future.then((_) {
          process = null;
          completer.complete(true);
          if (_cleanup != null) {
            _cleanup();
          }
        });

        if (process.kill(ProcessSignal.SIGKILL)) {
          _logEvent("Successfully sent kill signal to process.");
        } else {
          _logEvent("Sending kill signal failed.");
        }
      } else {
        _logEvent("The process is already dead.");
        completer.complete(true);
      }
    }
    return browserTerminationFuture;
  }

  /**
   * Start the browser using the supplied argument.
   * This sets up the error handling and usage logging.
   */
  Future<bool> startBrowser(String command, List<String> arguments) {
    return Process.start(command, arguments).then((startedProcess) {
      process = startedProcess;
      Completer stdoutDone = new Completer();
      Completer stderrDone = new Completer();

      process.stdout.transform(new StringDecoder()).listen((data) {
        _addStdout(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occured in the process stdout handling: $error");
      }, onDone: () {
        stdoutDone.complete(true);
      });

      process.stderr.transform(new StringDecoder()).listen((data) {
        _addStderr(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occured in the process stderr handling: $error");
      },  onDone: () {
        stderrDone.complete(true);
      });

      process.exitCode.then((exitCode) {
        _logEvent("Browser closed with exitcode $exitCode");
        Future.wait([stdoutDone.future, stderrDone.future]).then((_) {
          _processClosedCompleter.complete(exitCode);
        });
      });
      return true;
    }).catchError((error) {
      _logEvent("Running $command $arguments failed with $error");
      return false;
    });
  }

  /**
   * Get any stdout that the browser wrote during execution.
   */
  String get stdout => _stdout.toString();
  String get stderr => _stderr.toString();
  String get usageLog => _usageLog.toString();

  String toString();
  /** Starts the browser loading the given url */
  Future<bool> start(String url);
}

class Safari extends Browser {
  /**
   * The binary used to run safari - changing this can be nececcary for
   * testing or using non standard safari installation.
   */
  const String binary = "/Applications/Safari.app/Contents/MacOS/Safari";

  /**
   * We get the safari version by parsing a version file
   */
  const String versionFile = "/Applications/Safari.app/Contents/version.plist";


  Future<bool> allowPopUps() {
    var command = "defaults";
    var args = ["write", "com.apple.safari",
                "com.apple.Safari.ContentPageGroupIdentifier."
                "WebKit2JavaScriptCanOpenWindowsAutomatically",
                "1"];
    return Process.run(command, args).then((result) {
        if (result.exitCode != 0) {
          _logEvent("Could not disable pop-up blocking for safari");
          return false;
        }
        return true;
    });
  }

  Future<String> getVersion() {
    /**
     * Example of the file:
     * <?xml version="1.0" encoding="UTF-8"?>
     * <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     * <plist version="1.0">
     * <dict>
     *	     <key>BuildVersion</key>
     * 	     <string>2</string>
     * 	     <key>CFBundleShortVersionString</key>
     * 	     <string>6.0.4</string>
     * 	     <key>CFBundleVersion</key>
     * 	     <string>8536.29.13</string>
     * 	     <key>ProjectName</key>
     * 	     <string>WebBrowser</string>
     * 	     <key>SourceVersion</key>
     * 	     <string>7536029013000000</string>
     * </dict>
     * </plist>
     */
    File f = new File(versionFile);
    return f.readAsLines().then((content) {
      bool versionOnNextLine = false;
      for (var line in content) {
        if (versionOnNextLine) return line;
        if (line.contains("CFBundleShortVersionString")) {
          versionOnNextLine = true;
        }
      }
      return null;
    });
  }

  void _createLaunchHTML(var path, var url) {
    var file = new File("${path}/launch.html");
    var randomFile = file.openSync(FileMode.WRITE);
    var content = '<script language="JavaScript">location = "$url"</script>';
    randomFile.writeStringSync(content);
    randomFile.close();
  }

  Future<bool> start(String url) {
    _logEvent("Starting Safari browser on: $url");
    // Get the version and log that.
    return allowPopUps().then((success) {
      if (!success) {
        return new Future.immediate(false);
      }
      return getVersion().then((version) {
        _logEvent("Got version: $version");
        var args = ["'$url'"];
        return new Directory('').createTemp().then((userDir) {
          _cleanup = () { userDir.deleteSync(recursive: true); };
          _createLaunchHTML(userDir.path, url);
          var args = ["${userDir.path}/launch.html"];
          return startBrowser(binary, args);
        });
      }).catchError((e) {
        _logEvent("Running $binary --version failed with $e");
        return false;
      });
    });
  }

  String toString() => "Safari";
}


class Chrome extends Browser {
  /**
   * The binary used to run chrome - changing this can be nececcary for
   * testing or using non standard chrome installation.
   */
  const String binary = "google-chrome";

  Future<bool> start(String url) {
    _logEvent("Starting chrome browser on: $url");
    // Get the version and log that.
    return Process.run(binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to chrome get version");
        _logEvent("Make sure $binary is a valid program for running chrome");
        return new Future.immediate(false);
      }
      version = versionResult.stdout;
      _logEvent("Got version: $version");

      return new Directory('').createTemp().then((userDir) {
        _cleanup = () { userDir.deleteSync(recursive: true); };
        var args = ["--user-data-dir=${userDir.path}", url,
                    "--disable-extensions", "--disable-popup-blocking",
                    "--bwsi", "--no-first-run"];
        return startBrowser(binary, args);

      });
    }).catchError((e) {
      _logEvent("Running $binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Chrome";
}

class AndroidChrome extends Browser {
  const String viewAction = 'android.intent.action.VIEW';
  const String mainAction = 'android.intent.action.MAIN';
  const String chromePackage = 'com.android.chrome';
  const String browserPackage = 'com.android.browser';
  const String firefoxPackage = 'org.mozilla.firefox';
  const String turnScreenOnPackage = 'com.google.dart.turnscreenon';

  AndroidEmulator _emulator;
  AdbDevice _adbDevice;

  AndroidChrome(this._adbDevice);

  Future<bool> start(String url) {
    var browserIntent = new Intent(
        viewAction, browserPackage, '.BrowserActivity', url);
    var chromeIntent = new Intent(viewAction, chromePackage, '.Main', url);
    var firefoxIntent = new Intent(viewAction, firefoxPackage, '.App', url);
    var turnScreenOnIntent =
        new Intent(mainAction, turnScreenOnPackage, '.Main');

    var testing_resources_dir =
        new Path('third_party/android_testing_resources');
    if (!new Directory.fromPath(testing_resources_dir).existsSync()) {
      DebugLogger.error("$testing_resources_dir doesn't exist. Exiting now.");
      exit(1);
    }

    var chromeAPK = testing_resources_dir.append('com.android.chrome-1.apk');
    var turnScreenOnAPK = testing_resources_dir.append('TurnScreenOn.apk');
    var chromeConfDir = testing_resources_dir.append('chrome_configuration');
    var chromeConfDirRemote = new Path('/data/user/0/com.android.chrome/');

    return _adbDevice.waitForBootCompleted().then((_) {
      return _adbDevice.forceStop(chromeIntent.package);
    }).then((_) {
      return _adbDevice.killAll();
    }).then((_) {
      return _adbDevice.adbRoot();
    }).then((_) {
      return _adbDevice.installApk(turnScreenOnAPK);
    }).then((_) {
      return _adbDevice.installApk(chromeAPK);
    }).then((_) {
      return _adbDevice.pushData(chromeConfDir, chromeConfDirRemote);
    }).then((_) {
      return _adbDevice.chmod('777', chromeConfDirRemote);
    }).then((_) {
      return _adbDevice.startActivity(turnScreenOnIntent).then((_) => true);
    }).then((_) {
      return _adbDevice.startActivity(chromeIntent).then((_) => true);
    });
  }

  Future<bool> close() {
    if (_adbDevice != null) {
      return _adbDevice.forceStop(chromePackage).then((_) {
        return _adbDevice.killAll().then((_) => true);
      });
    }
    return new Future.immediate(true);
  }

  String toString() => "chromeOnAndroid";
}

class Firefox extends Browser {
  /**
   * The binary used to run firefox - changing this can be nececcary for
   * testing or using non standard firefox installation.
   */
  const String binary = "firefox";

  const String enablePopUp =
      'user_pref("dom.disable_open_during_load", false);';
  const String disableDefaultCheck =
      'user_pref("browser.shell.checkDefaultBrowser", false);';

  Future _createPreferenceFile(var path) {
    var file = new File("${path.toString()}/user.js");
    var randomFile = file.openSync(FileMode.WRITE);
    randomFile.writeStringSync(enablePopUp);
    randomFile.writeStringSync(disableDefaultCheck);
    randomFile.close();
  }


  Future<bool> start(String url) {
    _logEvent("Starting firefox browser on: $url");
    // Get the version and log that.
    return Process.run(binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to firefox get version");
        _logEvent("Make sure $binary is a valid program for running firefox");
        return new Future.immediate(false);
      }
      version = versionResult.stdout;
      _logEvent("Got version: $version");

      return new Directory('').createTemp().then((userDir) {
        _createPreferenceFile(userDir.path);
        _cleanup = () { userDir.deleteSync(recursive: true); };
        var args = ["-profile", "${userDir.path}",
                    "-no-remote", "-new-instance", url];
        return startBrowser(binary, args);

      });
    }).catchError((e) {
      _logEvent("Running $binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Firefox";
}


/**
 * Describes the current state of a browser used for testing.
 */
class BrowserTestingStatus {
// TODO(ricow): Add prefetching to the browsers. We spend a lot of time waiting
// for the next test. Handling timeouts is the hard part of this!

  Browser browser;
  BrowserTest currentTest;
  // This is currently not used for anything except for error reporting.
  // Given the usefulness of this in debugging issues this should not be
  // removed even when we have really stable system.
  BrowserTest lastTest;
  bool timeout = false;
  BrowserTestingStatus(Browser this.browser);
}


/**
 * Describes a single test to be run int the browser.
 */
class BrowserTest {
  // TODO(ricow): Add timeout callback instead of the string passing hack.
  Function doneCallback;
  String url;
  int timeout;
  Stopwatch stopwatch;
  // We store this here for easy access when tests time out (instead of
  // capturing this in a closure)
  Timer timeoutTimer;

  // Used for debugging, this is simply a unique identifier assigned to each
  // test.
  int id;
  static int _idCounter = 0;

  BrowserTest(this.url, this.doneCallback, this.timeout) {
    id = _idCounter++;
  }
}


/**
 * Encapsulates all the functionality for running tests in browsers.
 * The interface is rather simple. After starting the runner tests
 * are simply added to the queue and a the supplied callbacks are called
 * whenever a test completes.
 */
class BrowserTestRunner {
  String local_ip;
  String browserName;
  int maxNumBrowsers;
  // Used to send back logs from the browser (start, stop etc)
  Function logger;
  int browserIdCount = 0;

  bool underTermination = false;

  List<BrowserTest> testQueue = new List<BrowserTest>();
  Map<String, BrowserTestingStatus> browserStatus =
      new Map<String, BrowserTestingStatus>();

  var adbDeviceMapping = new Map<String, AdbDevice>();
  // This cache is used to guarantee that we never see double reporting.
  // If we do we need to provide developers with this information.
  // We don't add urls to the cache until we have run it.
  Map<int, String> testCache = new Map<int, String>();
  List<int> doubleReportingTests = new List<int>();

  BrowserTestingServer testingServer;

  BrowserTestRunner(this.local_ip, this.browserName, this.maxNumBrowsers);

  Future<bool> start() {
    // If [browserName] doesn't support opening new windows, we use new iframes
    // instead.
    bool useIframe =
        !Browser.BROWSERS_WITH_WINDOW_SUPPORT.contains(browserName);
    testingServer = new BrowserTestingServer(local_ip, useIframe);
    return testingServer.start().then((_) {
      testingServer.testDoneCallBack = handleResults;
      testingServer.nextTestCallBack = getNextTest;
      return getBrowsers().then((browsers) {
        var futures = [];
        for (var browser in browsers) {
          var url = testingServer.getDriverUrl(browser.id);
          var future = browser.start(url).then((success) {
            if (success) {
              browserStatus[browser.id] = new BrowserTestingStatus(browser);
            }
            return success;
          });
          futures.add(future);
        }
        return Future.wait(futures).then((values) {
          return !values.contains(false);
        });
      });
    });
  }

  Future<List<Browser>> getBrowsers() {
    // TODO(kustermann): This is a hackisch way to accomplish it and should
    // be encapsulated
    var browsersCompleter = new Completer();
    if (browserName == 'chromeOnAndroid') {
      AdbHelper.listDevices().then((deviceIds) {
        if (deviceIds.length > 0) {
          var browsers = [];
          for (int i = 0; i < deviceIds.length; i++) {
            var id = "BROWSER$i";
            var device = new AdbDevice(deviceIds[i]);
            adbDeviceMapping[id] = device;
            var browser = new AndroidChrome(device);
            browsers.add(browser);
            // We store this in case we need to kill the browser.
            browser.id = id;
          }
          browsersCompleter.complete(browsers);
        } else {
          throw new StateError("No android devices found.");
        }
      });
    } else {
      var browsers = [];
      for (int i = 0; i < maxNumBrowsers; i++) {
        var id = "BROWSER$browserIdCount";
        browserIdCount++;
        var browser = getInstance();
        browsers.add(browser);
        // We store this in case we need to kill the browser.
        browser.id = id;
      }
      browsersCompleter.complete(browsers);
    }
    return browsersCompleter.future;
  }

  var timedOut = [];

  void handleResults(String browserId, String output, int testId) {
    var status = browserStatus[browserId];
    DebugLogger.info("Handling result for browser ${browserId}");
    if (testCache.containsKey(testId)) {
      doubleReportingTests.add(testId);
      return;
    }

    if (status.timeout) {
      // We don't do anything, this browser is currently being killed and
      // replaced.
    } else if (status.currentTest != null) {
      status.currentTest.timeoutTimer.cancel();
      status.currentTest.stopwatch.stop();

      if (status.currentTest.id != testId) {
        print("Expected test id ${status.currentTest.id} for"
              "${status.currentTest.url}");
        print("Got test id ${testId}");
        print("Last test id was ${status.lastTest.id} for "
              "${status.currentTest.url}");
        throw("This should never happen, wrong test id");
      }
      testCache[testId] = status.currentTest.url;
      status.currentTest.doneCallback(output,
                                      status.currentTest.stopwatch.elapsed);
      status.lastTest = status.currentTest;
      status.currentTest = null;
    } else {
      print("\nThis is bad, should never happen, handleResult no test");
      print("URL: ${status.lastTest.url}");
      print(output);
      terminate().then((_) {
        exit(1);
      });
    }
  }

  void handleTimeout(BrowserTestingStatus status) {
    // We simply kill the browser and starts up a new one!
    // We could be smarter here, but it does not seems like it is worth it.
    DebugLogger.info("Handling timeout for browser ${status.browser.id}");
    status.timeout = true;
    timedOut.add(status.currentTest.url);
    var id = status.browser.id;
    status.browser.close().then((closed) {
      if (!closed) {
        // Very bad, we could not kill the browser.
        print("could not kill browser $id");
        return;
      }
      // We don't want to start a new browser if we are terminating.
      if (underTermination) return;
      var browser;
      var new_id = id;
      if (browserName == 'chromeOnAndroid') {
        browser = new AndroidChrome(adbDeviceMapping[id]);
      } else {
        browserStatus.remove(id);
        browser = getInstance();
        new_id = "BROWSER$browserIdCount";
        browserIdCount++;
        browserStatus[new_id] = new BrowserTestingStatus(browser);
      }
      browser.id = new_id;
      browser.start(testingServer.getDriverUrl(new_id)).then((success) {
        // We may have started terminating in the mean time.
        if (underTermination) {
          browser.close().then((success) {
            // We should never hit this, print it out.
            if (!success) {
              print("Could not kill browser ($id) started due to timeout");
            }
          });
          return;
        }
        if (success) {
          browserStatus[browser.id] = new BrowserTestingStatus(browser);
        } else {
          // TODO(ricow): Handle this better.
          print("This is bad, should never happen, could not start browser");
          exit(1);
        }
      });
    });
    status.currentTest.stopwatch.stop();
    status.currentTest.doneCallback("TIMEOUT",
                                    status.currentTest.stopwatch.elapsed);
    status.currentTest = null;
  }

  BrowserTest getNextTest(String browserId) {
    if (testQueue.isEmpty) return null;
    var status = browserStatus[browserId];
    if (status == null) return null;
    DebugLogger.info("Handling getNext for browser "
                     "${browserId} timeout status: ${status.timeout}");

    // We are currently terminating this browser, don't start a new test.
    if (status.timeout) return null;
    BrowserTest test = testQueue.removeLast();
    if (status.currentTest == null) {
      status.currentTest = test;
    } else {
      // TODO(ricow): Handle this better.
      print("This is bad, should never happen, getNextTest all full");
      print("This happened for browser $browserId");
      print("Old test was: ${status.currentTest.url}");
      print("Timed out tests:");
      for (var v in timedOut) {
        print("  $v");
      }
      exit(1);
    }
    Timer timer = new Timer(new Duration(seconds: test.timeout),
                            () { handleTimeout(status); });
    status.currentTest.timeoutTimer = timer;
    status.currentTest.stopwatch = new Stopwatch()..start();
    return test;
  }

  void queueTest(BrowserTest test) {
    testQueue.add(test);
  }

  void printDoubleReportingTests() {
    if (doubleReportingTests.length == 0) return;
    // TODO(ricow): die on double reporting.
    // Currently we just report this here, we could have a callback to the
    // encapsulating environment.
    print("");
    print("Double reporting tests");
    for (var id in doubleReportingTests) {
      print("  ${testCache[id]}");
    }
  }

  Future<bool> terminate() {
    var futures = [];
    underTermination = true;
    testingServer.underTermination = true;
    for (BrowserTestingStatus status in browserStatus.values) {
      futures.add(status.browser.close());
    }
    return Future.wait(futures).then((values) {
      testingServer.httpServer.close();
      testingServer.errorReportingServer.close();
      printDoubleReportingTests();
      return !values.contains(false);
    });
  }

  Browser getInstance() {
    var browser = new Browser.byName(browserName);
    browser.logger = logger;
    return browser;
  }
}

class BrowserTestingServer {
  /// Interface of the testing server:
  ///
  /// GET /driver/BROWSER_ID -- This will get the driver page to fetch
  ///                           and run tests ...
  /// GET /next_test/BROWSER_ID -- returns "WAIT" "TERMINATE" or "url#id"
  /// where url is the test to run, and id is the id of the test.
  /// If there are currently no available tests the waitSignal is send
  /// back. If we are in the process of terminating the terminateSignal
  /// is send back and the browser will stop requesting new tasks.
  /// POST /report/BROWSER_ID?id=NUM -- sends back the dom of the executed
  ///                                   test

  final String local_ip;

  const String driverPath = "/driver";
  const String nextTestPath = "/next_test";
  const String reportPath = "/report";
  const String waitSignal = "WAIT";
  const String terminateSignal = "TERMINATE";

  var testCount = 0;
  var httpServer;
  var errorReportingServer;
  bool underTermination = false;
  bool useIframe = false;

  Function testDoneCallBack;
  Function nextTestCallBack;

  BrowserTestingServer(this.local_ip, this.useIframe);

  Future start() {
    return HttpServer.bind(local_ip, 0).then((createdServer) {
      httpServer = createdServer;
      void handler(HttpRequest request) {
        if (request.uri.path.startsWith(reportPath)) {
          var browserId = request.uri.path.substring(reportPath.length + 1);
          var testId = int.parse(request.queryParameters["id"].split("=")[1]);

          handleReport(request, browserId, testId);
          // handleReport will asynchroniously fetch the data and will handle
          // the closing of the streams.
          return;
        }
        var textResponse = "";
        if (request.uri.path.startsWith(driverPath)) {
          var browserId = request.uri.path.substring(driverPath.length + 1);
          textResponse = getDriverPage(browserId);
        } else if (request.uri.path.startsWith(nextTestPath)) {
          var browserId = request.uri.path.substring(nextTestPath.length + 1);
          textResponse = getNextTest(browserId);
        } else {
          // We silently ignore other requests.
        }
        request.response.write(textResponse);
        request.listen((_) {}, onDone: request.response.close);
        request.response.done.catchError((error) {
          if (!underTermination) {
            print("URI ${request.uri}");
            print("Textresponse $textResponse");
            throw "Error returning content to browser: $error";
          }
      });
      }
      void errorHandler(e) {
        if (!underTermination) print("Error occured in httpserver: $e");
      };

      httpServer.listen(handler, onError: errorHandler);

      // Set up the error reporting server that enables us to send back
      // errors from the browser.
      return HttpServer.bind(local_ip, 0).then((createdReportServer) {
        errorReportingServer = createdReportServer;
        void errorReportingHandler(HttpRequest request) {
          StringBuffer buffer = new StringBuffer();
          request.transform(new StringDecoder()).listen((data) {
            buffer.write(data);
          }, onDone: () {
              String back = buffer.toString();
              request.response.headers.set("Access-Control-Allow-Origin", "*");

              request.response.done.catchError((error) {
                DebugLogger.error("Error getting error from browser"
                                  "on uri ${request.uri.path}: $error");
              });
              request.response.close();
              DebugLogger.error("Error from browser on : "
                               "${request.uri.path}, data:  $back");
          }, onError: (error) { print(error); });
        }
        errorReportingServer.listen(errorReportingHandler,
                                    onError: errorHandler);
        return true;
      });
    });
  }

  void handleReport(HttpRequest request, String browserId, var testId) {
    StringBuffer buffer = new StringBuffer();
    request.transform(new StringDecoder()).listen((data) {
      buffer.write(data);
      }, onDone: () {
        String back = buffer.toString();
        request.response.close();
        testDoneCallBack(browserId, back, testId);
      }, onError: (error) { print(error); });
  }

  String getNextTest(String browserId) {
    var nextTest = nextTestCallBack(browserId);
    if (underTermination) {
      // Browsers will be killed shortly, send them a terminate signal so
      // that they stop pulling.
      return terminateSignal;
    } else if (nextTest == null) {
      // We don't currently have any tests ready for consumption, wait.
      return waitSignal;
    } else {
      return "${nextTest.url}#id=${nextTest.id}";
    }
  }

  String getDriverUrl(String browserId) {
    if (httpServer == null) {
      print("Bad browser testing server, you are not started yet. Can't "
            "produce driver url");
      exit(1);
      // This should never happen - exit immediately;
    }
    return "http://$local_ip:${httpServer.port}/driver/$browserId";
  }


  String getDriverPage(String browserId) {
    var errorReportingUrl =
        "http://$local_ip:${errorReportingServer.port}/$browserId";
    String driverContent = """
<!DOCTYPE html><html>
<head>
  <title>Driving page</title>
  <script type='text/javascript'>

    function startTesting() {
      var number_of_tests = 0;
      var current_id;
      var last_reported_id;
      var testing_window;
      // We use this to determine if we did actually get back a start event
      // from the test we just loaded.
      var did_start = false;

      var embedded_iframe = document.getElementById('embedded_iframe');
      var use_iframe = ${useIframe};
      var start = new Date();

      function newTaskHandler() {
        if (this.readyState == this.DONE) {
          if (this.status == 200) {
            if (this.responseText == '$waitSignal') {
              setTimeout(getNextTask, 500);
            } else if (this.responseText == '$terminateSignal') {
              // Don't do anything, we will be killed shortly.
            } else {
              var elapsed = new Date() - start;
              reportError('Done getting task at: ' + elapsed);
              // TODO(ricow): Do something more clever here.
              if (nextTask != undefined) alert('This is really bad');
              // The task is send to us as:
              // URL#ID
              var split = this.responseText.split('#');
              var nextTask = split[0];
              current_id = split[1];
              did_start = false;
              run(nextTask);
            }
          } else {
            reportError('Could not contact the server and get a new task');
          }
        }
      }

      function getNextTask() {
        var elapsed = new Date() - start;
        reportError('Getting task at: ' + elapsed);
        var client = new XMLHttpRequest();
        client.onreadystatechange = newTaskHandler;
        client.open('GET', '$nextTestPath/$browserId');
        client.send();
      }

      function run(url) {
        number_of_tests++;
        document.getElementById('number').innerHTML = number_of_tests;
        if (use_iframe) {
          embedded_iframe.src = url;
        } else {
          if (testing_window == undefined) {
            testing_window = window.open(url);
          } else {
            testing_window.location = url;
          }
        }
      }

      window.onerror = function (message, url, lineNumber) {
        if (url) {
          reportError(url + ':' + lineNumber + ':' + message);
        } else {
          reportError(message);
        }
      }

      function reportError(msg) {
        var client = new XMLHttpRequest();
        function handleReady() {
          if (this.readyState == this.DONE && this.status != 200) {
            // We could not report, pop up to notify if running interactively.
            alert(this.status);
          }
        }
        client.onreadystatechange = handleReady;
        client.open('POST', '$errorReportingUrl?test=1');
        client.setRequestHeader('Content-type',
                                'application/x-www-form-urlencoded');
        client.send(msg);
      }

      function reportMessage(msg) {
        if (msg == 'STARTING') {
          did_start = true;
          return;
        }
        var client = new XMLHttpRequest();
        function handleReady() {
          if (this.readyState == this.DONE) {
            if (this.status == 200) {
              if (last_reported_id != current_id && did_start) {
                var elapsed = new Date() - start;
                reportError('Done sending results at: ' + elapsed);
                getNextTask();
                last_reported_id = current_id;
              }
            } else {
              reportError('Error sending result to server');
            }
          }
        }
        client.onreadystatechange = handleReady;
        // If did_start is false it means that we did actually set the url on
        // the testing_window, but this is a report left in the event loop or
        // a callback because the page did not load yet.
        // In both cases this is a double report from the last test.
        var posting_id = did_start ? current_id : last_reported_id;
        client.open('POST', '$reportPath/${browserId}?id=' + posting_id);
        client.setRequestHeader('Content-type',
                                'application/x-www-form-urlencoded');
        client.send(msg);
        var elapsed = new Date() - start;
        reportError('Sending results at: ' + elapsed);
      }

      function messageHandler(e) {
        var msg = e.data;
        if (typeof msg != 'string') return;
        reportMessage(msg);
      }

      window.addEventListener('message', messageHandler, false);
      waitForDone = false;

      getNextTask();
    }

  </script>
</head>
  <body onload="startTesting()">
    Dart test driver, number of tests: <div id="number"></div>
    <iframe id="embedded_iframe"></iframe>
  </body>
</html>
""";
    return driverContent;
  }
}
