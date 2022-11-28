// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:webdriver/io.dart';

import 'android.dart';
import 'configuration.dart';
import 'path.dart';
import 'service/web_driver_service.dart';
import 'utils.dart';

typedef BrowserDoneCallback = void Function(BrowserTestOutput output);
typedef TestChangedCallback = void Function(
    String browserId, String output, int testId);
typedef NextTestCallback = BrowserTest? Function(String browserId);

class BrowserOutput {
  final StringBuffer stdout = StringBuffer();
  final StringBuffer stderr = StringBuffer();
  final StringBuffer eventLog = StringBuffer();
}

/// Class describing the interface for communicating with browsers.
abstract class Browser {
  static int _browserIdCounter = 1;
  static String _nextBrowserId() => "BROWSER${_browserIdCounter++}";

  /// Get the output that was written so far to stdout/stderr/eventLog.
  BrowserOutput get testBrowserOutput => _testBrowserOutput;
  BrowserOutput _testBrowserOutput = BrowserOutput();

  /// This is called after the process is closed, before the done future
  /// is completed.
  ///
  /// Subclasses can use this to cleanup any browser specific resources
  /// (temp directories, profiles, etc). The function is expected to do
  /// it's work synchronously.
  void Function()? _cleanup;

  /// The version of the browser - normally set when starting a browser
  Future<String> get version;

  /// The underlying process - don't mess directly with this if you don't
  /// know what you are doing (this is an interactive process that needs
  /// special treatment to not leak).
  Process? process;

  void Function(String)? logger;

  /// Id of the browser.
  final String id = _nextBrowserId();

  /// Reset the browser to a known configuration on start-up.
  /// Browser specific implementations are free to ignore this.
  static bool resetBrowserConfiguration = false;

  /// Print everything (stdout, stderr, usageLog) whenever we add to it
  bool debugPrint = false;

  /// This future returns when the process exits. It is also the return value
  /// of close()
  Future<bool>? done;

  Browser();

  static Browser fromConfiguration(TestConfiguration configuration) {
    Browser browser;
    switch (configuration.runtime) {
      case Runtime.firefox:
        browser = Firefox(configuration.browserLocation);
        break;
      case Runtime.chrome:
        browser = Chrome(configuration.browserLocation);
        break;
      case Runtime.safari:
        var service = WebDriverService.fromRuntime(Runtime.safari);
        browser = Safari(service.port);
        break;
      case Runtime.ie9:
      case Runtime.ie10:
      case Runtime.ie11:
        browser = IE(configuration.browserLocation);
        break;
      default:
        throw "unreachable";
    }

    return browser;
  }

  static const List<String> supportedBrowsers = [
    'safari',
    'ff',
    'firefox',
    'chrome',
    'ie9',
    'ie10',
    'ie11'
  ];

  static bool requiresFocus(String browserName) {
    return browserName == "safari";
  }

  // TODO(kustermann): add standard support for chrome on android
  static bool supportedBrowser(String name) {
    return supportedBrowsers.contains(name);
  }

  void _logEvent(String event) {
    var toLog = "$this ($id) - $event \n";
    if (debugPrint) print("usageLog: $toLog");
    logger?.call(toLog);

    _testBrowserOutput.eventLog.write(toLog);
  }

  void _addStdout(String output) {
    if (debugPrint) print("stdout: $output");

    _testBrowserOutput.stdout.write(output);
  }

  void _addStderr(String output) {
    if (debugPrint) print("stderr: $output");

    _testBrowserOutput.stderr.write(output);
  }

  Future<bool> close() {
    _logEvent("Close called on browser");
    if (process != null) {
      if (process!.kill(ProcessSignal.sigkill)) {
        _logEvent("Successfully sent kill signal to process.");
      } else {
        _logEvent("Sending kill signal failed.");
      }
      return done ?? Future.value(true);
    } else {
      _logEvent("The process is already dead.");
      return Future.value(true);
    }
  }

  /// Start the browser using the supplied argument.
  /// This sets up the error handling and usage logging.
  Future<bool> startBrowserProcess(String command, List<String> arguments,
      {Map<String, String>? environment}) {
    return Process.start(command, arguments, environment: environment)
        .then((startedProcess) {
      _logEvent("Started browser using $command ${arguments.join(' ')}");
      process = startedProcess;
      // Used to notify when exiting, and as a return value on calls to
      // close().
      var doneCompleter = Completer<bool>();
      done = doneCompleter.future;

      var stdoutDone = Completer<Null>();
      var stderrDone = Completer<Null>();

      var stdoutIsDone = false;
      var stderrIsDone = false;
      StreamSubscription stdoutSubscription;
      StreamSubscription stderrSubscription;

      // This timer is used to close stdio to the subprocess once we got
      // the exitCode. Sometimes descendants of the subprocess keep stdio
      // handles alive even though the direct subprocess is dead.
      Timer? watchdogTimer;

      void closeStdout([_]) {
        if (!stdoutIsDone) {
          stdoutDone.complete();
          stdoutIsDone = true;

          if (stderrIsDone) {
            watchdogTimer?.cancel();
          }
        }
      }

      void closeStderr([_]) {
        if (!stderrIsDone) {
          stderrDone.complete();
          stderrIsDone = true;

          if (stdoutIsDone) {
            watchdogTimer?.cancel();
          }
        }
      }

      stdoutSubscription = process!.stdout
          .transform(utf8.decoder)
          .listen(_addStdout, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occurred in the process stdout handling: $error");
      }, onDone: closeStdout);

      stderrSubscription = process!.stderr
          .transform(utf8.decoder)
          .listen(_addStderr, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occurred in the process stderr handling: $error");
      }, onDone: closeStderr);

      process!.exitCode.then((exitCode) {
        _logEvent("Browser closed with exitcode $exitCode");

        if (!stdoutIsDone || !stderrIsDone) {
          watchdogTimer = Timer(maxStdioDelay, () {
            DebugLogger.warning("$maxStdioDelayPassedMessage (browser: $this)");
            watchdogTimer = null;
            stdoutSubscription.cancel();
            stderrSubscription.cancel();
            closeStdout();
            closeStderr();
          });
        }

        Future.wait([stdoutDone.future, stderrDone.future]).then((_) {
          process = null;
          _cleanup?.call();
        }).catchError((error) {
          _logEvent("Error closing browsers: $error");
        }).whenComplete(() => doneCompleter.complete(true));
      });
      return true;
    }).catchError((error) {
      _logEvent("Running $command $arguments failed with $error");
      return false;
    });
  }

  void resetTestBrowserOutput() {
    _testBrowserOutput = BrowserOutput();
  }

  /// Add useful info about the browser to the _testBrowserOutput.stdout,
  /// where it will be reported for failing tests.  Used to report which
  /// android device a failing test is running on.
  void logBrowserInfoToTestBrowserOutput() {}

  /// Starts the browser loading the given url
  Future<bool> start(String url);

  @override
  String toString() => '$runtimeType';
}

abstract class WebDriverBrowser extends Browser {
  WebDriver? _driver;
  final int _port;
  final Map<String, dynamic> _desiredCapabilities;
  bool _terminated = false;

  WebDriverBrowser(this._port, this._desiredCapabilities);

  @override
  Future<bool> start(String url) async {
    _logEvent('Starting $this browser on: $url');
    await _createDriver();
    if (_terminated) return false;
    await _driver!.get(url);
    try {
      _logEvent('Got version: ${await version}');
    } catch (error) {
      _logEvent('Failed to get version.\nError: $error');
      return false;
    }
    return true;
  }

  Future<void> _createDriver() async {
    for (var i = 5; i >= 0; i--) {
      // Give the driver process some time to be ready to accept connections.
      await Future.delayed(const Duration(seconds: 1));
      if (_terminated) return;
      try {
        _driver = await createDriver(
            uri: Uri.parse('http://localhost:$_port/'),
            desired: _desiredCapabilities);
      } catch (error) {
        if (_terminated) return;
        if (i > 0) {
          _logEvent(
              'Failed to create driver ($i retries left).\nError: $error');
        } else {
          _logEvent('Failed to create driver.\nError: $error');
          await close();
          rethrow;
        }
      }
      if (_driver != null) break;
    }
  }

  @override
  Future<bool> close() async {
    _terminated = true;
    await _driver?.quit();
    // Give the driver process some time to be quit the browser.
    return true;
  }
}

class Safari extends WebDriverBrowser {
  /// We get the safari version by parsing a version file
  static const versionFile = '/Applications/Safari.app/Contents/version.plist';

  Safari(int port)
      : super(port, {
          'browserName': 'safari',
        });

  @override
  Future<String> get version async {
    // Example of the file:
    // <?xml version="1.0" encoding="UTF-8"?>
    // <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    // <plist version="1.0">
    // <dict>
    // 	     <key>BuildVersion</key>
    // 	     <string>2</string>
    // 	     <key>CFBundleShortVersionString</key>
    // 	     <string>6.0.4</string>
    // 	     <key>CFBundleVersion</key>
    // 	     <string>8536.29.13</string>
    // 	     <key>ProjectName</key>
    // 	     <string>WebBrowser</string>
    // 	     <key>SourceVersion</key>
    // 	     <string>7536029013000000</string>
    // </dict>
    // </plist>
    final versionLine = (await File(versionFile).readAsLines())
        .skipWhile((line) => !line.contains("CFBundleShortVersionString"))
        .skip(1)
        .take(1);
    return versionLine.isEmpty ? 'unknown' : versionLine.first;
  }
}

class Chrome extends Browser {
  Chrome(this._binary);

  final String _binary;

  @override
  Future<String> get version async {
    if (Platform.isWindows) {
      // The version flag does not work on windows.
      // See issue:
      // https://code.google.com/p/chromium/issues/detail?id=158372
      // The registry hack does not seem to work.
      return "unknown on windows";
    }
    final result = await Process.run(_binary, ["--version"]);
    if (result.exitCode != 0) {
      _logEvent("Failed to get chrome version");
      _logEvent("Make sure $_binary is a valid program for running chrome");
      throw StateError(
          "Failed to get chrome version.\nExit code: ${result.exitCode}");
    }
    return result.stdout as String;
  }

  @override
  Future<bool> start(String url) async {
    _logEvent("Starting chrome browser on: $url");
    if (!await File(_binary).exists()) {
      _logEvent("Chrome binary not available.");
      _logEvent("Make sure $_binary is a valid program for running chrome");
      return false;
    }
    try {
      _logEvent("Got version: ${await version}");
      final userDir = await Directory.systemTemp.createTemp();
      _cleanup = () {
        try {
          userDir.deleteSync(recursive: true);
        } catch (e) {
          _logEvent(
              "Error: failed to delete Chrome user-data-dir ${userDir.path}, "
              "will try again in 40 seconds: $e");
          Timer(const Duration(seconds: 40), () {
            try {
              userDir.deleteSync(recursive: true);
            } catch (e) {
              _logEvent("Error: failed on second attempt to delete Chrome "
                  "user-data-dir ${userDir.path}: $e");
            }
          });
        }
      };
      var args = [
        "--bwsi",
        "--disable-component-update",
        "--disable-extensions",
        "--disable-popup-blocking",
        "--no-first-run",
        "--use-mock-keychain",
        "--user-data-dir=${userDir.path}",
        url,
      ];

      // TODO(rnystrom): Uncomment this to open the dev tools tab when Chrome
      // is spawned. Handy for debugging tests.
      // args.add("--auto-open-devtools-for-tabs");

      return startBrowserProcess(_binary, args);
    } catch (e) {
      _logEvent("Starting chrome failed with $e");
      return false;
    }
  }
}

class IE extends Browser {
  IE(this._binary);

  final String _binary;

  @override
  Future<String> get version async {
    var args = [
      "query",
      "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer",
      "/v",
      "svcVersion"
    ];
    final result = await Process.run("reg", args);
    if (result.exitCode != 0) {
      throw StateError("Could not get the version of internet explorer");
    }
    // The string we get back looks like this:
    // HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer
    //    version    REG_SZ    9.0.8112.16421
    var findString = "REG_SZ";
    var index = (result.stdout as String).indexOf(findString);
    if (index > 0) {
      return (result.stdout as String)
          .substring(index + findString.length)
          .trim();
    }
    throw StateError("Could not get the version of internet explorer");
  }

  // Clears the recovery cache and allows popups on localhost if the static
  // resetBrowserConfiguration flag is set.
  Future<bool> resetConfiguration() async {
    if (!Browser.resetBrowserConfiguration) return true;
    const ieKey = r"HKCU\Software\Microsoft\Internet Explorer";
    // Turn off popup blocker
    await _setRegistryKey("$ieKey\\New Windows", "PopupMgr",
        data: "0", type: "REG_DWORD");
    // Allow popups from localhost
    await _setRegistryKey("$ieKey\\New Windows\\Allow", "127.0.0.1");
    // Disable IE first run wizard
    await _setRegistryKey("$ieKey\Main", "DisableFirstRunCustomize",
        data: "1", type: "REG_DWORD");

    var localAppData = Platform.environment['LOCALAPPDATA'];
    var dir = Directory("$localAppData\\Microsoft\\"
        "Internet Explorer\\Recovery");
    try {
      dir.delete(recursive: true);
      return true;
    } catch (error) {
      _logEvent("Deleting recovery dir failed with $error");
      return false;
    }
  }

  @override
  Future<bool> start(String url) async {
    _logEvent("Starting ie browser on: $url");
    await resetConfiguration();
    _logEvent("Got version: ${await version}");
    return startBrowserProcess(_binary, [url]);
  }

  Future<void> _setRegistryKey(String key, String value,
      {String? data, String? type}) async {
    var args = <String>[
      "add",
      key,
      "/v",
      value,
      "/f",
      if (type != null) ...["/t", type]
    ];
    var result = await Process.run("reg", args);
    if (result.exitCode != 0) {
      _logEvent("Failed to set '$key' to '$value'");
    }
  }
}

class AndroidChrome extends Browser {
  static const String viewAction = 'android.intent.action.VIEW';
  static const String mainAction = 'android.intent.action.MAIN';
  static const String chromePackage = 'com.android.chrome';
  static const String chromeActivity = '.Main';
  static const String browserPackage = 'com.android.browser';
  static const String browserActivity = '.BrowserActivity';
  static const String firefoxPackage = 'org.mozilla.firefox';
  static const String firefoxActivity = '.App';
  static const String turnScreenOnPackage = 'com.google.dart.turnscreenon';
  static const String turnScreenOnActivity = '.Main';

  final AdbDevice _adbDevice;

  AndroidChrome(this._adbDevice);

  @override
  Future<bool> start(String url) {
    var chromeIntent = Intent(viewAction, chromePackage, chromeActivity, url);
    var turnScreenOnIntent =
        Intent(mainAction, turnScreenOnPackage, turnScreenOnActivity);

    var testingResourcesDir = Path('third_party/android_testing_resources');
    if (!Directory(testingResourcesDir.toNativePath()).existsSync()) {
      DebugLogger.error("$testingResourcesDir doesn't exist. Exiting now.");
      exit(1);
    }

    var chromeAPK = testingResourcesDir.append('com.android.chrome-1.apk');
    var turnScreenOnAPK = testingResourcesDir.append('TurnScreenOn.apk');
    var chromeConfDir = testingResourcesDir.append('chrome_configuration');
    var chromeConfDirRemote = Path('/data/user/0/com.android.chrome/');

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

  @override
  Future<bool> close() async {
    await _adbDevice.forceStop(chromePackage);
    await _adbDevice.killAll();
    return true;
  }

  void logBrowserInfoToTestBrowserOutput() {
    _testBrowserOutput.stdout
        .write('Android device id: ${_adbDevice.deviceId}\n');
  }

  @override
  final Future<String> version = Future.value('unknown');

  @override
  String toString() => "chromeOnAndroid";
}

class Firefox extends Browser {
  Firefox(this._binary);

  final String _binary;

  static const String enablePopUp =
      'user_pref("dom.disable_open_during_load", false);';
  static const String disableDefaultCheck =
      'user_pref("browser.shell.checkDefaultBrowser", false);';
  static const String disableScriptTimeLimit =
      'user_pref("dom.max_script_run_time", 0);';

  void _createPreferenceFile(String path) {
    var file = File("$path/user.js");
    var randomFile = file.openSync(mode: FileMode.write);
    randomFile.writeStringSync(enablePopUp);
    randomFile.writeStringSync(disableDefaultCheck);
    randomFile.writeStringSync(disableScriptTimeLimit);
    randomFile.close();
  }

  @override
  Future<String> get version async {
    final result = await Process.run(_binary, ["--version"]);
    if (result.exitCode != 0) {
      _logEvent("Failed to get firefox version");
      _logEvent("Make sure $_binary is a valid program for running firefox");
      throw StateError(
          "Failed to get firefox version.\nExit code: ${result.exitCode}");
    }
    return result.stdout as String;
  }

  @override
  Future<bool> start(String url) async {
    _logEvent("Starting firefox browser on: $url");
    try {
      _logEvent("Got version: ${await version}");
      final userDir = await Directory.systemTemp.createTemp();
      _createPreferenceFile(userDir.path);
      _cleanup = () {
        userDir.deleteSync(recursive: true);
      };
      var args = [
        "-profile",
        "${userDir.path}",
        "-no-remote",
        "-new-instance",
        url
      ];
      var environment = Map<String, String>.from(Platform.environment);
      environment["MOZ_CRASHREPORTER_DISABLE"] = "1";
      return startBrowserProcess(_binary, args, environment: environment);
    } catch (e) {
      _logEvent("Starting firefox failed with $e");
      return false;
    }
  }
}

/// Describes the current state of a browser used for testing.
class BrowserStatus {
  Browser browser;
  BrowserTest? currentTest;

  // This is currently not used for anything except for error reporting.
  // Given the usefulness of this in debugging issues this should not be
  // removed even when we have a really stable system.
  BrowserTest? lastTest;
  bool timeout = false;
  Timer? nextTestTimeout;
  Stopwatch timeSinceRestart = Stopwatch()..start();

  BrowserStatus(this.browser);
}

/// Describes a single test to be run in the browser.
class BrowserTest {
  // TODO(ricow): Add timeout callback instead of the string passing hack.
  BrowserDoneCallback doneCallback;
  String url;
  int timeout;
  String lastKnownMessage = '';
  late Stopwatch stopwatch;

  Duration? delayUntilTestStarted;

  // We store this here for easy access when tests time out (instead of
  // capturing this in a closure)
  late Timer timeoutTimer;

  // Used for debugging, this is simply a unique identifier assigned to each
  // test.
  final int id = _idCounter++;
  static int _idCounter = 0;

  BrowserTest(this.url, this.doneCallback, this.timeout);

  String toJSON() => jsonEncode({'url': url, 'id': id});
}

/* Describes the output of running the test in a browser */
class BrowserTestOutput {
  final Duration? delayUntilTestStarted;
  final Duration duration;

  final String lastKnownMessage;

  final BrowserOutput browserOutput;
  final bool didTimeout;

  BrowserTestOutput(this.delayUntilTestStarted, this.duration,
      this.lastKnownMessage, this.browserOutput,
      {this.didTimeout = false});
}

/// Encapsulates all the functionality for running tests in browsers.
/// Tests are added to the queue and the supplied callbacks are called
/// when a test completes.
/// BrowserTestRunner starts up to maxNumBrowser instances of the browser,
/// to run the tests, starting them sequentially, as needed, so only
/// one is starting up at a time.
/// BrowserTestRunner starts a BrowserTestingServer, which serves a
/// driver page to the browsers, serves tests, and receives results and
/// requests back from the browsers.
class BrowserTestRunner {
  static const int _maxNextTestTimeouts = 10;
  static const Duration _nextTestTimeout = Duration(seconds: 120);
  static const Duration _restartBrowserInterval = Duration(seconds: 60);

  /// If the queue was recently empty, don't start another browser.
  static const Duration _minNonemptyQueueTime = Duration(seconds: 1);

  final TestConfiguration configuration;
  final BrowserTestingServer testingServer;
  final Browser Function(TestConfiguration configuration) browserFactory;

  final String localIp;
  final int maxNumBrowsers;
  int numBrowsers = 0;

  /// Used to send back logs from the browser (start, stop etc.).
  void Function(String)? logger;

  bool testingServerStarted = false;
  bool underTermination = false;
  int numBrowserGetTestTimeouts = 0;
  DateTime lastEmptyTestQueueTime = DateTime.now();
  String? _currentStartingBrowserId;
  List<BrowserTest> testQueue = [];
  Map<String, BrowserStatus> browserStatus = {};

  Map<String, AdbDevice> adbDeviceMapping = {};
  late List<AdbDevice> idleAdbDevices;

  /// This cache is used to guarantee that we never see double reporting.
  /// If we do we need to provide developers with this information.
  /// We don't add urls to the cache until we have run it.
  Map<int, String> testCache = {};

  Map<int, String> doubleReportingOutputs = {};
  List<String> timedOut = [];

  /// We will start a new browser when the test queue hasn't been empty
  /// recently, we have fewer than maxNumBrowsers browsers, and there is
  /// no other browser instance currently starting up.
  bool get queueWasEmptyRecently {
    return testQueue.isEmpty ||
        DateTime.now().difference(lastEmptyTestQueueTime) <
            _minNonemptyQueueTime;
  }

  /// While a browser is starting, but has not requested its first test, its
  /// browserId is stored in _currentStartingBrowserId.
  /// When no browser is currently starting, _currentStartingBrowserId is null.
  bool get aBrowserIsCurrentlyStarting => _currentStartingBrowserId != null;
  void markCurrentlyStarting(String id) {
    _currentStartingBrowserId = id;
  }

  void markNotCurrentlyStarting(String id) {
    if (_currentStartingBrowserId == id) _currentStartingBrowserId = null;
  }

  BrowserTestRunner(this.configuration, this.localIp, this.maxNumBrowsers,
      [this.browserFactory = Browser.fromConfiguration])
      : testingServer = BrowserTestingServer(configuration, localIp,
            Browser.requiresFocus(configuration.runtime.name)) {
    testingServer.testRunner = this;
  }

  Future<BrowserTestRunner> start() async {
    await testingServer.start();
    testingServer
      ..testDoneCallBack = handleResults
      ..testStatusUpdateCallBack = handleStatusUpdate
      ..testStartedCallBack = handleStarted
      ..nextTestCallBack = getNextTest;
    testingServerStarted = true;
    requestBrowser();
    return this;
  }

  /// requestBrowser() is called whenever we might want to start an additional
  /// browser instance.
  ///
  /// It is called when starting the BrowserTestRunner, and whenever a browser
  /// is killed, whenever a new test is enqueued, or whenever a browser
  /// finishes a test.
  /// So we are guaranteed that this will always eventually be called, as long
  /// as the test queue isn't empty.
  void requestBrowser() {
    if (!testingServerStarted) return;
    if (underTermination) return;
    if (numBrowsers == maxNumBrowsers) return;
    if (aBrowserIsCurrentlyStarting) return;
    if (numBrowsers > 0 && queueWasEmptyRecently) return;
    createBrowser();
  }

  Future<bool> createBrowser() {
    Browser browser;
    if (configuration.runtime == Runtime.chromeOnAndroid) {
      var device = idleAdbDevices.removeLast();
      browser = AndroidChrome(device);
      adbDeviceMapping[browser.id] = device;
    } else {
      browser = browserFactory(configuration);
      browser.logger = logger;
    }
    markCurrentlyStarting(browser.id);
    var status = BrowserStatus(browser);
    browserStatus[browser.id] = status;
    numBrowsers++;
    status.nextTestTimeout = createNextTestTimer(status);
    return browser.start(testingServer.getDriverUrl(browser.id));
  }

  void handleResults(String browserId, String output, int testId) {
    var status = browserStatus[browserId];
    if (testCache.containsKey(testId)) {
      doubleReportingOutputs[testId] = output;
      return;
    }

    var test = status?.currentTest;
    if (status == null || status.timeout) {
      // We don't do anything, this browser is currently being killed and
      // replaced. The browser here can be null if we decided to kill the
      // browser.
    } else if (test != null) {
      test.timeoutTimer.cancel();
      test.stopwatch.stop();

      if (test.id != testId) {
        print("Expected test id ${test.id} for ${test.url}");
        print("Got test id $testId");
        print("Last test id was ${status.lastTest?.id} for ${test.url}");
        throw "This should never happen, wrong test id";
      }
      testCache[testId] = test.url;

      // Report that the test is finished now
      var browserTestOutput = BrowserTestOutput(test.delayUntilTestStarted,
          test.stopwatch.elapsed, output, status.browser.testBrowserOutput);
      test.doneCallback(browserTestOutput);

      status.lastTest = test;
      status.currentTest = null;
      status.nextTestTimeout = createNextTestTimer(status);
    } else {
      print("\nThis is bad, should never happen, handleResult no test");
      print("URL: ${status.lastTest?.url}");
      print(output);
      terminate().then((_) {
        exit(1);
      });
    }
  }

  void handleStatusUpdate(String browserId, String output, int testId) {
    var status = browserStatus[browserId];

    if (status == null || status.timeout) {
      // We don't do anything, this browser is currently being killed and
      // replaced. The browser here can be null if we decided to kill the
      // browser.
    } else if (status.currentTest?.id == testId) {
      status.currentTest!.lastKnownMessage = output;
    }
  }

  void handleStarted(String browserId, String output, int testId) {
    var status = browserStatus[browserId];
    if (status == null || status.timeout) return;

    var currentTest = status.currentTest;
    if (currentTest == null) return;

    currentTest.timeoutTimer.cancel();
    currentTest.timeoutTimer = createTimeoutTimer(currentTest, status);
    currentTest.delayUntilTestStarted = currentTest.stopwatch.elapsed;
  }

  Future handleTimeout(BrowserStatus status) async {
    // We simply kill the browser and starts up a new one!
    // We could be smarter here, but it does not seems like it is worth it.
    if (status.timeout) {
      DebugLogger.error("Got test timeout for an already restarting browser");
      return;
    }
    status.timeout = true;
    var currentTest = status.currentTest!;
    timedOut.add(currentTest.url);
    var id = status.browser.id;

    currentTest.stopwatch.stop();
    await status.browser.close();
    var lastKnownMessage =
        'Dom could not be fetched, since the test timed out.';
    if (currentTest.lastKnownMessage.isNotEmpty) {
      lastKnownMessage = currentTest.lastKnownMessage;
    }
    if (status.lastTest != null) {
      lastKnownMessage += '\nPrevious test was ${status.lastTest!.url}';
    }
    // Wait until the browser is closed before reporting the test as timeout.
    // This will enable us to capture stdout/stderr from the browser
    // (which might provide us with information about what went wrong).
    var browserTestOutput = BrowserTestOutput(
        currentTest.delayUntilTestStarted,
        currentTest.stopwatch.elapsed,
        lastKnownMessage,
        status.browser.testBrowserOutput,
        didTimeout: true);
    currentTest.doneCallback(browserTestOutput);
    status.lastTest = status.currentTest;
    status.currentTest = null;

    // We don't want to start a new browser if we are terminating.
    if (underTermination) return;
    removeBrowser(id);
    requestBrowser();
  }

  /// Remove a browser that has closed from our data structures that track
  /// open browsers. Check if we want to replace it with a new browser.
  void removeBrowser(String id) {
    if (configuration.runtime == Runtime.chromeOnAndroid) {
      idleAdbDevices.add(adbDeviceMapping.remove(id)!);
    }
    markNotCurrentlyStarting(id);
    browserStatus.remove(id);
    --numBrowsers;
  }

  BrowserTest? getNextTest(String browserId) {
    markNotCurrentlyStarting(browserId);
    var status = browserStatus[browserId];
    if (status == null) return null;
    status.nextTestTimeout?.cancel();
    status.nextTestTimeout = null;
    if (testQueue.isEmpty) return null;

    // We are currently terminating this browser, don't start a new test.
    if (status.timeout) return null;

    // Restart Internet Explorer if it has been
    // running for longer than RESTART_BROWSER_INTERVAL. The tests have
    // had flaky timeouts, and this may help.
    if ((configuration.runtime == Runtime.ie10 ||
            configuration.runtime == Runtime.ie11) &&
        status.timeSinceRestart.elapsed > _restartBrowserInterval) {
      var id = status.browser.id;
      // Reset stopwatch so we don't trigger again before restarting.
      status.timeout = true;
      status.browser.close().then((_) {
        // We don't want to start a new browser if we are terminating.
        if (underTermination) return;
        removeBrowser(id);
        requestBrowser();
      });
      // Don't send a test to the browser we are restarting.
      return null;
    }

    var test = testQueue.removeLast();
    // If our queue isn't empty, try starting more browsers
    if (testQueue.isEmpty) {
      lastEmptyTestQueueTime = DateTime.now();
    } else {
      requestBrowser();
    }
    if (status.currentTest != null) {
      // TODO(ricow): Handle this better.
      print("Browser requested next test before reporting previous result");
      print("This happened for browser $browserId");
      print("Old test was: ${status.currentTest!.url}");
      print("The test before that was: ${status.lastTest?.url}");
      print("Timed out tests:");
      for (var v in timedOut) {
        print("  $v");
      }
      exit(1);
    }
    status.currentTest = test
      ..lastKnownMessage = ''
      ..timeoutTimer = createTimeoutTimer(test, status)
      ..stopwatch = (Stopwatch()..start());

    // Reset the test specific output information (stdout, stderr) on the
    // browser, since a new test is being started.
    status.browser.resetTestBrowserOutput();
    status.browser.logBrowserInfoToTestBrowserOutput();
    return test;
  }

  /// Creates a timer that is active while a test is running on a browser.
  Timer createTimeoutTimer(BrowserTest test, BrowserStatus status) {
    return Timer(Duration(seconds: test.timeout), () {
      handleTimeout(status);
    });
  }

  /// Creates a timer that is active while no test is running on the
  /// browser. It has finished one test, and it has not requested a new test.
  Timer createNextTestTimer(BrowserStatus status) {
    return Timer(BrowserTestRunner._nextTestTimeout, () {
      handleNextTestTimeout(status);
    });
  }

  void handleNextTestTimeout(BrowserStatus status) {
    DebugLogger.warning(
        "Browser timed out before getting next test. Restarting");
    if (status.timeout) return;
    numBrowserGetTestTimeouts++;
    if (numBrowserGetTestTimeouts >= _maxNextTestTimeouts) {
      DebugLogger.error(
          "Too many browser timeouts before getting next test. Terminating");
      terminate().then((_) => exit(1));
    } else {
      status.timeout = true;
      status.browser.close().then((_) {
        removeBrowser(status.browser.id);
        requestBrowser();
      });
    }
  }

  void enqueueTest(BrowserTest test) {
    testQueue.add(test);
    requestBrowser();
  }

  void printDoubleReportingTests() {
    if (doubleReportingOutputs.isEmpty) return;
    // TODO(ricow): die on double reporting.
    // Currently we just report this here, we could have a callback to the
    // encapsulating environment.
    print("");
    print("Double reporting tests");
    for (var id in doubleReportingOutputs.keys) {
      print("  ${testCache[id]}");
    }

    DebugLogger.warning("Double reporting tests:");
    for (var id in doubleReportingOutputs.keys) {
      DebugLogger.warning("${testCache[id]}");
    }
  }

  // TODO(26191): Call a unified fatalError(), that shuts down all subprocesses.
  // This just kills the browsers in this BrowserTestRunner instance.
  Future terminate() async {
    var browsers = <Browser>[];
    underTermination = true;
    testingServer.underTermination = true;
    for (var status in browserStatus.values) {
      browsers.add(status.browser);
      status.nextTestTimeout?.cancel();
      status.nextTestTimeout = null;
    }

    for (var browser in browsers) {
      await browser.close();
    }

    testingServer.errorReportingServer.close();
    printDoubleReportingTests();
  }
}

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
class BrowserTestingServer {
  final TestConfiguration configuration;

  final String localIp;
  final bool requiresFocus;
  late BrowserTestRunner testRunner;

  static const String driverPath = "/driver";
  static const String nextTestPath = "/next_test";
  static const String reportPath = "/report";
  static const String statusUpdatePath = "/status_update";
  static const String startedPath = "/started";
  static const String waitSignal = "WAIT";
  static const String terminateSignal = "TERMINATE";

  var testCount = 0;
  late HttpServer errorReportingServer;
  bool underTermination = false;

  late TestChangedCallback testDoneCallBack;
  late TestChangedCallback testStatusUpdateCallBack;
  late TestChangedCallback testStartedCallBack;
  late NextTestCallback nextTestCallBack;

  BrowserTestingServer(this.configuration, this.localIp, this.requiresFocus);

  Future start() async {
    var server =
        await HttpServer.bind(localIp, configuration.testDriverErrorPort);
    setupErrorServer(server);
    setupDispatchingServer(server);
  }

  void setupErrorServer(HttpServer server) {
    errorReportingServer = server;
    void errorReportingHandler(HttpRequest request) {
      var buffer = StringBuffer();
      request.cast<List<int>>().transform(utf8.decoder).listen((data) {
        buffer.write(data);
      }, onDone: () {
        var back = buffer.toString();
        request.response.headers.set("Access-Control-Allow-Origin", "*");
        request.response.done.catchError((error) {
          DebugLogger.error("Error getting error from browser"
              "on uri ${request.uri.path}: $error");
        });
        request.response.close();
        DebugLogger.error("Error from browser on : "
            "${request.uri.path}, data:  $back");
      }, onError: print);
    }

    void errorHandler(e) {
      if (!underTermination) print("Error occurred in httpserver: $e");
    }

    errorReportingServer.listen(errorReportingHandler, onError: errorHandler);
  }

  void setupDispatchingServer(_) {
    var server = configuration.servers.server!;
    void noCache(HttpRequest request) {
      request.response.headers
          .set("Cache-Control", "no-cache, no-store, must-revalidate");
    }

    int testId(HttpRequest request) =>
        int.parse(request.uri.queryParameters["id"]!);
    String browserId(HttpRequest request, String prefix) =>
        request.uri.path.substring(prefix.length + 1);

    server.addHandler(reportPath, (HttpRequest request) {
      noCache(request);
      handleReport(request, browserId(request, reportPath), testId(request),
          isStatusUpdate: false);
    });
    server.addHandler(statusUpdatePath, (HttpRequest request) {
      noCache(request);
      handleReport(
          request, browserId(request, statusUpdatePath), testId(request),
          isStatusUpdate: true);
    });
    server.addHandler(startedPath, (HttpRequest request) {
      noCache(request);
      handleStarted(request, browserId(request, startedPath), testId(request));
    });

    void sendPageHandler(HttpRequest request) {
      // Do NOT make this method async. We need to call catchError below
      // synchronously to avoid unhandled asynchronous errors.
      noCache(request);
      Future<String> textResponse;
      if (request.uri.path.startsWith(driverPath)) {
        textResponse = getDriverPage(browserId(request, driverPath));
        request.response.headers.set('Content-Type', 'text/html');
      } else if (request.uri.path.startsWith(nextTestPath)) {
        textResponse =
            Future.value(getNextTest(browserId(request, nextTestPath)));
        request.response.headers.set('Content-Type', 'text/plain');
      } else {
        textResponse = Future.value("");
      }
      request.response.done.catchError((error) async {
        if (!underTermination) {
          var text = await textResponse;
          print("URI ${request.uri}");
          print("text $text");
          throw "Error returning content to browser: $error";
        }
      });
      textResponse.then((String text) async {
        request.response.write(text);
        await request.listen(null).asFuture();
        // Ignoring the returned closure as it returns the 'done' future
        // which already has catchError installed above.
        request.response.close();
      });
    }

    server.addHandler(driverPath, sendPageHandler);
    server.addHandler(nextTestPath, sendPageHandler);
  }

  void handleReport(HttpRequest request, String browserId, int testId,
      {required bool isStatusUpdate}) {
    var buffer = StringBuffer();
    request.cast<List<int>>().transform(utf8.decoder).listen((data) {
      buffer.write(data);
    }, onDone: () {
      var back = buffer.toString();
      request.response.close();
      if (isStatusUpdate) {
        testStatusUpdateCallBack(browserId, back, testId);
      } else {
        testDoneCallBack(browserId, back, testId);
      }
      // TODO(ricow): We should do something smart if we get an error here.
    }, onError: (error) {
      DebugLogger.error("$error");
    });
  }

  void handleStarted(HttpRequest request, String browserId, int testId) {
    var buffer = StringBuffer();
    // If an error occurs while receiving the data from the request stream,
    // we don't handle it specially. We can safely ignore it, since the started
    // events are not crucial.
    request.cast<List<int>>().transform(utf8.decoder).listen((data) {
      buffer.write(data);
    }, onDone: () {
      var back = buffer.toString();
      request.response.close();
      testStartedCallBack(browserId, back, testId);
    }, onError: (error) {
      DebugLogger.error("$error");
    });
  }

  String getNextTest(String browserId) {
    var nextTest = nextTestCallBack(browserId);
    if (underTermination) {
      // Browsers will be killed shortly, send them a terminate signal so
      // that they stop pulling.
      return terminateSignal;
    }
    return nextTest == null ? waitSignal : nextTest.toJSON();
  }

  String getDriverUrl(String browserId) {
    return "http://$localIp:${configuration.servers.port}/driver/$browserId";
  }

  Future<String> getDriverPage(String browserId) async {
    var errorReportingUrl =
        "http://$localIp:${errorReportingServer.port}/$browserId";
    var driverContent = """
<!DOCTYPE html><html>
<head>
  <title>Driving page</title>
  <meta charset="utf-8">
  <style>
.big-notice {
  background-color: red;
  color: white;
  font-weight: bold;
  font-size: xx-large;
  text-align: center;
}
.controller.box {
  white-space: nowrap;
  overflow: scroll;
  height: 6em;
}
body {
  font-family: sans-serif;
}
body div {
  padding-top: 10px;
}
  </style>
  <script type='text/javascript'>
    var STATUS_UPDATE_INTERVAL = 10000;

    function startTesting() {
      var number_of_tests = 0;
      var current_id;
      var next_id;

      // Has the test in the current iframe reported that it is done?
      var test_completed = true;
      // Has the test in the current iframe reported that it is started?
      var test_started = false;
      var testing_window;

      var embedded_iframe_div = document.getElementById('embedded_iframe_div');
      var embedded_iframe = document.getElementById('embedded_iframe');
      var number_div = document.getElementById('number');
      var executing_div = document.getElementById('currently_executing');
      var error_div = document.getElementById('unhandled_error');
      var use_iframe = ${configuration.runtime.requiresIFrame};
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
              var nextTask = JSON.parse(this.responseText);
              var url = nextTask.url;
              next_id = nextTask.id;
              run(url);
            }
          } else {
            reportError('Could not contact the server and get a new task');
          }
        }
      }

      function contactBrowserController(method,
                                        path,
                                        callback,
                                        msg,
                                        isUrlEncoded) {
        var client = new XMLHttpRequest();
        client.onreadystatechange = callback;
        client.open(method, path);
        if (isUrlEncoded) {
          client.setRequestHeader('Content-type',
                                  'application/x-www-form-urlencoded');
        }
        client.send(msg);
      }

      function getNextTask() {
        // Until we have the next task we set the current_id to a specific
        // negative value.
        contactBrowserController(
            'GET', '$nextTestPath/$browserId', newTaskHandler, "", false);
      }

      function childError(message, filename, lineno, colno, error) {
        sendStatusUpdate();
        if (error) {
          reportMessage('FAIL:' + filename + ':' + lineno +
               ':' + colno + ':' + message + '\\n' + error.stack, false, false);
        } else if (filename) {
          reportMessage('FAIL:' + filename + ':' + lineno +
               ':' + colno + ':' + message, false, false);
        } else {
          reportMessage('FAIL: ' + message, false, false);
        }
        return true;
      }

      function run(url) {
        number_of_tests++;
        number_div.textContent = number_of_tests;
        executing_div.textContent = url;
        if (use_iframe) {
          embedded_iframe.onload = null;
          embedded_iframe_div.removeChild(embedded_iframe);
          embedded_iframe = document.createElement('iframe');
          embedded_iframe.id = "embedded_iframe";
          embedded_iframe.width='800px';
          embedded_iframe.height='600px';
          embedded_iframe_div.appendChild(embedded_iframe);
          embedded_iframe.src = url;
        } else {
          if (typeof testing_window != 'undefined') {
            testing_window.close();
          }
          testing_window = window.open(url);
        }
        test_started = false;
        test_completed = false;
      }

      window.onerror = function (message, url, lineNumber) {
        if (url) {
          reportError(url + ':' + lineNumber + ':' + message);
        } else {
          reportError(message);
        }
      }

      function reportError(msg) {
        function handleReady() {
          if (this.readyState == this.DONE && this.status != 200) {
            var error = 'Sending back error did not succeeed: ' + this.status;
            error = error + '. Failed to send msg: ' + msg;
            error_div.innerHTML = error;
          }
        }
        contactBrowserController(
            'POST', '$errorReportingUrl?test=1', handleReady, msg, true);
      }

      function reportMessage(msg, isFirstMessage, isStatusUpdate) {
        if (isFirstMessage) {
          if (test_started) {
            reportMessage(
                "FAIL: test started more than once (test reloads itself) " +
                msg, false, false);
            return;
          }
          current_id = next_id;
          test_started = true;
          contactBrowserController(
            'POST', '$startedPath/$browserId?id=' + current_id,
            function () {}, msg, true);
        } else if (isStatusUpdate) {
            contactBrowserController(
              'POST', '$statusUpdatePath/$browserId?id=' + current_id,
              function() {}, msg, true);
        } else {
          var is_double_report = test_completed;
          var retry = 0;
          test_completed = true;

          function reportDoneMessage() {
            contactBrowserController(
                'POST', '$reportPath/$browserId?id=' + current_id,
                handleReady, msg, true);
          }

          function handleReady() {
            if (this.readyState == this.DONE) {
              if (this.status == 200) {
                if (!is_double_report) {
                  getNextTask();
                }
              } else {
                reportError('Error sending result to server. Status: ' +
                            this.status + ' Retry: ' + retry);
                retry++;
                if (retry < 3) {
                  setTimeout(reportDoneMessage, 1000);
                }
              }
            }
          }

          reportDoneMessage();
        }
      }

      function parseResult(result) {
        var parsedData = null;
        try {
          parsedData = JSON.parse(result);
        } catch(error) { }
        return parsedData;
      }

      // Browser tests send JSON messages to the driver window, handled here.
      function messageHandler(e) {
        var msg = e.data;
        if (typeof msg != 'string') return;
        var expectedSource =
            use_iframe ? embedded_iframe.contentWindow : testing_window;
        if (e.source != expectedSource) {
            reportError("Message received from old test window: " + msg);
            return;
        }
        var parsedData = parseResult(msg);
        if (parsedData) {
          // Only if the JSON message contains all required parameters,
          // will we handle it and post it back to the test controller.
          if ('message' in parsedData &&
              'is_first_message' in parsedData &&
              'is_status_update' in parsedData &&
              'is_done' in parsedData) {
            var message = parsedData['message'];
            var isFirstMessage = parsedData['is_first_message'];
            var isStatusUpdate = parsedData['is_status_update'];
            var isDone = parsedData['is_done'];
            if (!isFirstMessage && !isStatusUpdate) {
              if (!isDone) {
                alert("Bug in test_controller.js: " +
                      "isFirstMessage/isStatusUpdate/isDone were all false");
              }
            }
            reportMessage(message, isFirstMessage, isStatusUpdate);
          }
        }
      }

      function sendStatusUpdate () {
        var dom =
            embedded_iframe.contentWindow.document.documentElement.innerHTML;
        var message = 'Status:\\n';
        message += '  DOM:\\n' +
                   '    ' + dom;
        reportMessage(message, false, true);
      }

      function sendRepeatingStatusUpdate() {
        sendStatusUpdate();
        setTimeout(sendRepeatingStatusUpdate, STATUS_UPDATE_INTERVAL);
      }

      window.addEventListener('message', messageHandler, false);
      waitForDone = false;
      getNextTask();
    }
  </script>
</head>
  <body onload="startTesting()">

    <div class='big-notice'>
      Please keep this window in focus at all times.
    </div>

    <div>
      Some browsers, Safari, in particular, may pause JavaScript when not
      visible to conserve power consumption and CPU resources. In addition,
      some tests of focus events will not work correctly if this window doesn't
      have focus. It's also advisable to close any other programs that may open
      modal dialogs, for example, Chrome with Calendar open.
    </div>

    <div class="controller box">
    Dart test driver, number of tests: <span id="number"></span><br>
    Currently executing: <span id="currently_executing"></span><br>
    Unhandled error: <span id="unhandled_error"></span>
    </div>
    <div id="embedded_iframe_div" class="test box">
      <iframe id="embedded_iframe"></iframe>
    </div>
  </body>
</html>
""";
    return driverContent;
  }
}
