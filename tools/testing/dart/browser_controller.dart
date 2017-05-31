// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'android.dart';
import 'configuration.dart';
import 'path.dart';
import 'reset_safari.dart';
import 'utils.dart';

typedef void BrowserDoneCallback(BrowserTestOutput output);
typedef void TestChangedCallback(String browserId, String output, int testId);
typedef BrowserTest NextTestCallback(String browserId);

class BrowserOutput {
  final StringBuffer stdout = new StringBuffer();
  final StringBuffer stderr = new StringBuffer();
  final StringBuffer eventLog = new StringBuffer();
}

/** Class describing the interface for communicating with browsers. */
abstract class Browser {
  BrowserOutput _allBrowserOutput = new BrowserOutput();
  BrowserOutput _testBrowserOutput = new BrowserOutput();

  // This is called after the process is closed, before the done future
  // is completed.
  // Subclasses can use this to cleanup any browser specific resources
  // (temp directories, profiles, etc). The function is expected to do
  // it's work synchronously.
  Function _cleanup;

  /** The version of the browser - normally set when starting a browser */
  String version = "";

  // The path to the browser executable.
  String _binary;

  /**
   * The underlying process - don't mess directly with this if you don't
   * know what you are doing (this is an interactive process that needs
   * special treatment to not leak).
   */
  Process process;

  Function logger;

  /**
   * Id of the browser
   */
  String id;

  /**
   * Reset the browser to a known configuration on start-up.
   * Browser specific implementations are free to ignore this.
   */
  static bool resetBrowserConfiguration = false;

  /** Print everything (stdout, stderr, usageLog) whenever we add to it */
  bool debugPrint = false;

  // This future returns when the process exits. It is also the return value
  // of close()
  Future done;

  Browser();

  factory Browser.byRuntime(Runtime runtime, String executablePath,
      [bool checkedMode = false]) {
    Browser browser;
    switch (runtime) {
      case Runtime.firefox:
        browser = new Firefox();
        break;
      case Runtime.chrome:
        browser = new Chrome();
        break;
      case Runtime.dartium:
        browser = new Dartium(checkedMode);
        break;
      case Runtime.safari:
        browser = new Safari();
        break;
      case Runtime.safariMobileSim:
        browser = new SafariMobileSimulator();
        break;
      case Runtime.ie9:
      case Runtime.ie10:
      case Runtime.ie11:
        browser = new IE();
        break;
      default:
        throw "unreachable";
    }

    browser._binary = executablePath;
    return browser;
  }

  static const List<String> SUPPORTED_BROWSERS = const [
    'safari',
    'ff',
    'firefox',
    'chrome',
    'ie9',
    'ie10',
    'ie11',
    'dartium'
  ];

  static bool requiresFocus(String browserName) {
    return browserName == "safari";
  }

  // TODO(kustermann): add standard support for chrome on android
  static bool supportedBrowser(String name) {
    return SUPPORTED_BROWSERS.contains(name);
  }

  void _logEvent(String event) {
    String toLog = "$this ($id) - $event \n";
    if (debugPrint) print("usageLog: $toLog");
    if (logger != null) logger(toLog);

    _allBrowserOutput.eventLog.write(toLog);
    _testBrowserOutput.eventLog.write(toLog);
  }

  void _addStdout(String output) {
    if (debugPrint) print("stdout: $output");

    _allBrowserOutput.stdout.write(output);
    _testBrowserOutput.stdout.write(output);
  }

  void _addStderr(String output) {
    if (debugPrint) print("stderr: $output");

    _allBrowserOutput.stderr.write(output);
    _testBrowserOutput.stderr.write(output);
  }

  Future close() {
    _logEvent("Close called on browser");
    if (process != null) {
      if (process.kill(ProcessSignal.SIGKILL)) {
        _logEvent("Successfully sent kill signal to process.");
      } else {
        _logEvent("Sending kill signal failed.");
      }
      return done;
    } else {
      _logEvent("The process is already dead.");
      return new Future.value(true);
    }
  }

  /**
   * Start the browser using the supplied argument.
   * This sets up the error handling and usage logging.
   */
  Future<bool> startBrowserProcess(String command, List<String> arguments,
      {Map<String, String> environment}) {
    return Process
        .start(command, arguments, environment: environment)
        .then((startedProcess) {
      _logEvent("Started browser using $command ${arguments.join(' ')}");
      process = startedProcess;
      // Used to notify when exiting, and as a return value on calls to
      // close().
      var doneCompleter = new Completer<bool>();
      done = doneCompleter.future;

      Completer stdoutDone = new Completer<Null>();
      Completer stderrDone = new Completer<Null>();

      bool stdoutIsDone = false;
      bool stderrIsDone = false;
      StreamSubscription stdoutSubscription;
      StreamSubscription stderrSubscription;

      // This timer is used to close stdio to the subprocess once we got
      // the exitCode. Sometimes descendants of the subprocess keep stdio
      // handles alive even though the direct subprocess is dead.
      Timer watchdogTimer;

      void closeStdout([_]) {
        if (!stdoutIsDone) {
          stdoutDone.complete();
          stdoutIsDone = true;

          if (stderrIsDone && watchdogTimer != null) {
            watchdogTimer.cancel();
          }
        }
      }

      void closeStderr([_]) {
        if (!stderrIsDone) {
          stderrDone.complete();
          stderrIsDone = true;

          if (stdoutIsDone && watchdogTimer != null) {
            watchdogTimer.cancel();
          }
        }
      }

      stdoutSubscription =
          process.stdout.transform(UTF8.decoder).listen((data) {
        _addStdout(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occured in the process stdout handling: $error");
      }, onDone: closeStdout);

      stderrSubscription =
          process.stderr.transform(UTF8.decoder).listen((data) {
        _addStderr(data);
      }, onError: (error) {
        // This should _never_ happen, but we really want this in the log
        // if it actually does due to dart:io or vm bug.
        _logEvent("An error occured in the process stderr handling: $error");
      }, onDone: closeStderr);

      process.exitCode.then((exitCode) {
        _logEvent("Browser closed with exitcode $exitCode");

        if (!stdoutIsDone || !stderrIsDone) {
          watchdogTimer = new Timer(MAX_STDIO_DELAY, () {
            DebugLogger
                .warning("$MAX_STDIO_DELAY_PASSED_MESSAGE (browser: $this)");
            watchdogTimer = null;
            stdoutSubscription.cancel();
            stderrSubscription.cancel();
            closeStdout();
            closeStderr();
          });
        }

        Future.wait([stdoutDone.future, stderrDone.future]).then((_) {
          process = null;
          if (_cleanup != null) {
            _cleanup();
          }
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

  /**
   * Get the output that was written so far to stdout/stderr/eventLog.
   */
  BrowserOutput get allBrowserOutput => _allBrowserOutput;
  BrowserOutput get testBrowserOutput => _testBrowserOutput;

  void resetTestBrowserOutput() {
    _testBrowserOutput = new BrowserOutput();
  }

  /**
   * Add useful info about the browser to the _testBrowserOutput.stdout,
   * where it will be reported for failing tests.  Used to report which
   * android device a failing test is running on.
   */
  void logBrowserInfoToTestBrowserOutput() {}

  String toString();

  /** Starts the browser loading the given url */
  Future<bool> start(String url);

  /// Called when the driver page is requested, that is, when the browser first
  /// contacts the test server. At this time, it's safe to assume that the
  /// browser process has started and opened its first window.
  ///
  /// This is used by [Safari] to ensure the browser window has focus.
  Future<Null> onDriverPageRequested() => new Future<Null>.value();
}

class Safari extends Browser {
  /**
   * We get the safari version by parsing a version file
   */
  static const String versionFile =
      "/Applications/Safari.app/Contents/version.plist";

  static const String safariBundleLocation = "/Applications/Safari.app/";

  // Clears the cache if the static resetBrowserConfiguration flag is set.
  // Returns false if the command to actually clear the cache did not complete.
  Future<bool> resetConfiguration() async {
    if (!Browser.resetBrowserConfiguration) return true;

    var completer = new Completer<Null>();
    handleUncaughtError(error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      } else {
        throw new AsyncError(error, stackTrace);
      }
    }

    Zone parent = Zone.current;
    ZoneSpecification specification = new ZoneSpecification(
        print: (Zone self, ZoneDelegate delegate, Zone zone, String line) {
      delegate.run(parent, () {
        _logEvent(line);
      });
    });
    Future zoneWrapper() {
      Uri safariUri = Uri.base.resolve(safariBundleLocation);
      return new Future(() => killAndResetSafari(bundle: safariUri))
          .then(completer.complete);
    }

    // We run killAndResetSafari in a Zone as opposed to running an external
    // process. The Zone allows us to collect its output, and protect the rest
    // of the test infrastructure against errors in it.
    runZoned(zoneWrapper,
        zoneSpecification: specification, onError: handleUncaughtError);

    try {
      await completer.future;
      return true;
    } catch (error, st) {
      _logEvent("Unable to reset Safari: $error$st");
      return false;
    }
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

  Future<Null> _createLaunchHTML(String path, String url) async {
    var file = new File("$path/launch.html");
    var randomFile = await file.open(mode: FileMode.WRITE);
    var content = '<script language="JavaScript">location = "$url"</script>';
    await randomFile.writeString(content);
    await randomFile.close();
  }

  Future<bool> start(String url) async {
    _logEvent("Starting Safari browser on: $url");
    if (!await resetConfiguration()) {
      _logEvent("Could not clear cache");
      return false;
    }
    String version;
    try {
      version = await getVersion();
    } catch (error) {
      _logEvent("Running $_binary --version failed with $error");
      return false;
    }
    _logEvent("Got version: $version");
    Directory userDir;
    try {
      userDir = await Directory.systemTemp.createTemp();
    } catch (error) {
      _logEvent("Error creating temporary directory: $error");
      return false;
    }
    _cleanup = () {
      userDir.deleteSync(recursive: true);
    };
    try {
      await _createLaunchHTML(userDir.path, url);
    } catch (error) {
      _logEvent("Error creating launch HTML: $error");
      return false;
    }
    var args = [
      "-d",
      "-i",
      "-m",
      "-s",
      "-u",
      _binary,
      "${userDir.path}/launch.html"
    ];
    try {
      return startBrowserProcess("/usr/bin/caffeinate", args);
    } catch (error) {
      _logEvent("Error starting browser process: $error");
      return false;
    }
  }

  Future<Null> onDriverPageRequested() async {
    await Process.run(
        "/usr/bin/osascript", ['-e', 'tell application "Safari" to activate']);
  }

  String toString() => "Safari";
}

class Chrome extends Browser {
  String _version = "Version not found yet";

  Map<String, String> _getEnvironment() => null;

  Future<bool> _getVersion() {
    if (Platform.isWindows) {
      // The version flag does not work on windows.
      // See issue:
      // https://code.google.com/p/chromium/issues/detail?id=158372
      // The registry hack does not seem to work.
      _version = "Can't get version on windows";
      // We still validate that the binary exists so that we can give good
      // feedback.
      return new File(_binary).exists().then((exists) {
        if (!exists) {
          _logEvent("Chrome binary not available.");
          _logEvent("Make sure $_binary is a valid program for running chrome");
        }
        return exists;
      });
    }
    return Process.run(_binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to chrome get version");
        _logEvent("Make sure $_binary is a valid program for running chrome");
        return false;
      }
      _version = versionResult.stdout as String;
      return true;
    });
  }

  Future<bool> start(String url) {
    _logEvent("Starting chrome browser on: $url");
    // Get the version and log that.
    return _getVersion().then<bool>((success) {
      if (!success) return false;
      _logEvent("Got version: $_version");

      return Directory.systemTemp.createTemp().then((userDir) {
        _cleanup = () {
          try {
            userDir.deleteSync(recursive: true);
          } catch (e) {
            _logEvent(
                "Error: failed to delete Chrome user-data-dir ${userDir.path}"
                ", will try again in 40 seconds: $e");
            new Timer(new Duration(seconds: 40), () {
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
          "--user-data-dir=${userDir.path}",
          url,
          "--disable-extensions",
          "--disable-popup-blocking",
          "--bwsi",
          "--no-first-run"
        ];
        return startBrowserProcess(_binary, args,
            environment: _getEnvironment());
      });
    }).catchError((e) {
      _logEvent("Running $_binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Chrome";
}

class SafariMobileSimulator extends Safari {
  /**
   * Directories where safari simulator stores state. We delete these if the
   * resetBrowserConfiguration is set
   */
  static const List<String> CACHE_DIRECTORIES = const [
    "Library/Application Support/iPhone Simulator/7.1/Applications"
  ];

  // Helper function to delete many directories recursively.
  Future<bool> deleteIfExists(Iterable<String> paths) async {
    for (var path in paths) {
      Directory directory = new Directory(path);
      if (await directory.exists()) {
        _logEvent("Deleting $path");
        try {
          await directory.delete(recursive: true);
        } catch (error) {
          _logEvent("Failure trying to delete $path: $error");
          return false;
        }
      } else {
        _logEvent("$path is not present");
      }
    }
    return true;
  }

  // Clears the cache if the static resetBrowserConfiguration flag is set.
  // Returns false if the command to actually clear the cache did not complete.
  Future<bool> resetConfiguration() {
    if (!Browser.resetBrowserConfiguration) return new Future.value(true);
    var home = Platform.environment['HOME'];
    var paths = CACHE_DIRECTORIES.map((s) => "$home/$s");
    return deleteIfExists(paths);
  }

  Future<bool> start(String url) {
    _logEvent("Starting safari mobile simulator browser on: $url");
    return resetConfiguration().then((success) {
      if (!success) {
        _logEvent("Could not clear cache, exiting");
        return false;
      }
      var args = [
        "-SimulateApplication",
        "/Applications/Xcode.app/Contents/Developer/Platforms/"
            "iPhoneSimulator.platform/Developer/SDKs/"
            "iPhoneSimulator7.1.sdk/Applications/MobileSafari.app/"
            "MobileSafari",
        "-u",
        url
      ];
      return startBrowserProcess(_binary, args).catchError((e) {
        _logEvent("Running $_binary --version failed with $e");
        return false;
      });
    });
  }

  String toString() => "SafariMobileSimulator";
}

class Dartium extends Chrome {
  final bool checkedMode;

  Dartium(this.checkedMode);

  Map<String, String> _getEnvironment() {
    var environment = new Map<String, String>.from(Platform.environment);
    // By setting this environment variable, dartium will forward "print()"
    // calls in dart to the top-level javascript function "dartPrint()" if
    // available.
    environment['DART_FORWARDING_PRINT'] = '1';
    if (checkedMode) {
      environment['DART_FLAGS'] = '--checked';
    }
    return environment;
  }

  String toString() => "Dartium";
}

class IE extends Browser {
  Future<String> getVersion() {
    var args = [
      "query",
      "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer",
      "/v",
      "svcVersion"
    ];
    return Process.run("reg", args).then((result) {
      if (result.exitCode == 0) {
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
      }
      return "Could not get the version of internet explorer";
    });
  }

  // Clears the recovery cache if the static resetBrowserConfiguration flag is
  // set.
  Future<bool> resetConfiguration() {
    if (!Browser.resetBrowserConfiguration) return new Future.value(true);
    var localAppData = Platform.environment['LOCALAPPDATA'];

    Directory dir = new Directory("$localAppData\\Microsoft\\"
        "Internet Explorer\\Recovery");
    return dir.delete(recursive: true).then((_) {
      return true;
    }).catchError((error) {
      _logEvent("Deleting recovery dir failed with $error");
      return false;
    });
  }

  Future<bool> start(String url) {
    _logEvent("Starting ie browser on: $url");
    return resetConfiguration().then((_) => getVersion()).then((version) {
      _logEvent("Got version: $version");
      return startBrowserProcess(_binary, [url]);
    });
  }

  String toString() => "IE";
}

class AndroidBrowserConfig {
  final String name;
  final String package;
  final String activity;
  final String action;
  AndroidBrowserConfig(this.name, this.package, this.activity, this.action);
}

final contentShellOnAndroidConfig = new AndroidBrowserConfig(
    'ContentShellOnAndroid',
    'org.chromium.content_shell_apk',
    '.ContentShellActivity',
    'android.intent.action.VIEW');

final dartiumOnAndroidConfig = new AndroidBrowserConfig('DartiumOnAndroid',
    'com.google.android.apps.chrome', '.Main', 'android.intent.action.VIEW');

class AndroidBrowser extends Browser {
  final bool checkedMode;
  AdbDevice _adbDevice;
  AndroidBrowserConfig _config;

  AndroidBrowser(
      this._adbDevice, this._config, this.checkedMode, String apkPath) {
    _binary = apkPath;
  }

  Future<bool> start(String url) {
    var intent =
        new Intent(_config.action, _config.package, _config.activity, url);
    return _adbDevice.waitForBootCompleted().then((_) {
      return _adbDevice.forceStop(_config.package);
    }).then((_) {
      return _adbDevice.killAll();
    }).then((_) {
      return _adbDevice.adbRoot();
    }).then((_) {
      return _adbDevice.setProp("DART_FORWARDING_PRINT", "1");
    }).then((_) {
      if (checkedMode) {
        return _adbDevice.setProp("DART_FLAGS", "--checked");
      } else {
        return _adbDevice.setProp("DART_FLAGS", "");
      }
    }).then((_) {
      return _adbDevice.installApk(new Path(_binary));
    }).then((_) {
      return _adbDevice.startActivity(intent).then((_) => true);
    });
  }

  Future<bool> close() {
    if (_adbDevice != null) {
      return _adbDevice.forceStop(_config.package).then((_) {
        return _adbDevice.killAll().then((_) => true);
      });
    }
    return new Future.value(true);
  }

  void logBrowserInfoToTestBrowserOutput() {
    _testBrowserOutput.stdout
        .write('Android device id: ${_adbDevice.deviceId}\n');
  }

  String toString() => _config.name;
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

  AdbDevice _adbDevice;

  AndroidChrome(this._adbDevice);

  Future<bool> start(String url) {
    var chromeIntent =
        new Intent(viewAction, chromePackage, chromeActivity, url);
    var turnScreenOnIntent =
        new Intent(mainAction, turnScreenOnPackage, turnScreenOnActivity);

    var testing_resources_dir =
        new Path('third_party/android_testing_resources');
    if (!new Directory(testing_resources_dir.toNativePath()).existsSync()) {
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
    return new Future.value(true);
  }

  void logBrowserInfoToTestBrowserOutput() {
    _testBrowserOutput.stdout
        .write('Android device id: ${_adbDevice.deviceId}\n');
  }

  String toString() => "chromeOnAndroid";
}

class Firefox extends Browser {
  static const String enablePopUp =
      'user_pref("dom.disable_open_during_load", false);';
  static const String disableDefaultCheck =
      'user_pref("browser.shell.checkDefaultBrowser", false);';
  static const String disableScriptTimeLimit =
      'user_pref("dom.max_script_run_time", 0);';

  void _createPreferenceFile(String path) {
    var file = new File("$path/user.js");
    var randomFile = file.openSync(mode: FileMode.WRITE);
    randomFile.writeStringSync(enablePopUp);
    randomFile.writeStringSync(disableDefaultCheck);
    randomFile.writeStringSync(disableScriptTimeLimit);
    randomFile.close();
  }

  Future<bool> start(String url) {
    _logEvent("Starting firefox browser on: $url");
    // Get the version and log that.
    return Process.run(_binary, ["--version"]).then((var versionResult) {
      if (versionResult.exitCode != 0) {
        _logEvent("Failed to firefox get version");
        _logEvent("Make sure $_binary is a valid program for running firefox");
        return new Future.value(false);
      }
      version = versionResult.stdout as String;
      _logEvent("Got version: $version");

      return Directory.systemTemp.createTemp().then((userDir) {
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
        var environment = new Map<String, String>.from(Platform.environment);
        environment["MOZ_CRASHREPORTER_DISABLE"] = "1";
        return startBrowserProcess(_binary, args, environment: environment);
      });
    }).catchError((e) {
      _logEvent("Running $_binary --version failed with $e");
      return false;
    });
  }

  String toString() => "Firefox";
}

/**
 * Describes the current state of a browser used for testing.
 */
class BrowserStatus {
  Browser browser;
  BrowserTest currentTest;

  // This is currently not used for anything except for error reporting.
  // Given the usefulness of this in debugging issues this should not be
  // removed even when we have a really stable system.
  BrowserTest lastTest;
  bool timeout = false;
  Timer nextTestTimeout;
  Stopwatch timeSinceRestart = new Stopwatch()..start();

  BrowserStatus(Browser this.browser);
}

/**
 * Describes a single test to be run in the browser.
 */
class BrowserTest {
  // TODO(ricow): Add timeout callback instead of the string passing hack.
  BrowserDoneCallback doneCallback;
  String url;
  int timeout;
  String lastKnownMessage = '';
  Stopwatch stopwatch;

  // This might be null
  Duration delayUntilTestStarted;

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

  String toJSON() => JSON.encode({'url': url, 'id': id, 'isHtmlTest': false});
}

/**
 * Describes a test with a custom HTML page to be run in the browser.
 */
class HtmlTest extends BrowserTest {
  List<String> expectedMessages;

  HtmlTest(String url, BrowserDoneCallback doneCallback, int timeout,
      this.expectedMessages)
      : super(url, doneCallback, timeout) {}

  String toJSON() => JSON.encode({
        'url': url,
        'id': id,
        'isHtmlTest': true,
        'expectedMessages': expectedMessages
      });
}

/* Describes the output of running the test in a browser */
class BrowserTestOutput {
  final Duration delayUntilTestStarted;
  final Duration duration;

  final String lastKnownMessage;

  final BrowserOutput browserOutput;
  final bool didTimeout;

  BrowserTestOutput(this.delayUntilTestStarted, this.duration,
      this.lastKnownMessage, this.browserOutput,
      {this.didTimeout: false});
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
  static const int MAX_NEXT_TEST_TIMEOUTS = 10;
  static const Duration NEXT_TEST_TIMEOUT = const Duration(seconds: 120);
  static const Duration RESTART_BROWSER_INTERVAL = const Duration(seconds: 60);

  /// If the queue was recently empty, don't start another browser.
  static const Duration MIN_NONEMPTY_QUEUE_TIME = const Duration(seconds: 1);

  final Configuration configuration;
  final BrowserTestingServer testingServer;

  final String localIp;
  int maxNumBrowsers;
  int numBrowsers = 0;
  // Used to send back logs from the browser (start, stop etc)
  Function logger;

  int browserIdCounter = 1;

  bool testingServerStarted = false;
  bool underTermination = false;
  int numBrowserGetTestTimeouts = 0;
  DateTime lastEmptyTestQueueTime = new DateTime.now();
  String _currentStartingBrowserId;
  List<BrowserTest> testQueue = [];
  Map<String, BrowserStatus> browserStatus = {};

  Map<String, AdbDevice> adbDeviceMapping = {};
  List<AdbDevice> idleAdbDevices;

  // This cache is used to guarantee that we never see double reporting.
  // If we do we need to provide developers with this information.
  // We don't add urls to the cache until we have run it.
  Map<int, String> testCache = {};

  Map<int, String> doubleReportingOutputs = {};
  List<String> timedOut = [];

  // We will start a new browser when the test queue hasn't been empty
  // recently, we have fewer than maxNumBrowsers browsers, and there is
  // no other browser instance currently starting up.
  bool get queueWasEmptyRecently {
    return testQueue.isEmpty ||
        new DateTime.now().difference(lastEmptyTestQueueTime) <
            MIN_NONEMPTY_QUEUE_TIME;
  }

  // While a browser is starting, but has not requested its first test, its
  // browserId is stored in _currentStartingBrowserId.
  // When no browser is currently starting, _currentStartingBrowserId is null.
  bool get aBrowserIsCurrentlyStarting => _currentStartingBrowserId != null;
  void markCurrentlyStarting(String id) {
    _currentStartingBrowserId = id;
  }

  void markNotCurrentlyStarting(String id) {
    if (_currentStartingBrowserId == id) _currentStartingBrowserId = null;
  }

  BrowserTestRunner(
      Configuration configuration, String localIp, this.maxNumBrowsers)
      : configuration = configuration,
        localIp = localIp,
        testingServer = new BrowserTestingServer(configuration, localIp,
            Browser.requiresFocus(configuration.runtime.name)) {
    testingServer.testRunner = this;
  }

  Future start() async {
    await testingServer.start();
    testingServer
      ..testDoneCallBack = handleResults
      ..testStatusUpdateCallBack = handleStatusUpdate
      ..testStartedCallBack = handleStarted
      ..nextTestCallBack = getNextTest;
    if (configuration.runtime == Runtime.chromeOnAndroid) {
      var idbNames = await AdbHelper.listDevices();
      idleAdbDevices = new List.from(idbNames.map((id) => new AdbDevice(id)));
      maxNumBrowsers = min(maxNumBrowsers, idleAdbDevices.length);
    }
    testingServerStarted = true;
    requestBrowser();
  }

  /// requestBrowser() is called whenever we might want to start an additional
  /// browser instance.
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

  String getNextBrowserId() => "BROWSER${browserIdCounter++}";

  void createBrowser() {
    var id = getNextBrowserId();
    var url = testingServer.getDriverUrl(id);

    Browser browser;
    if (configuration.runtime == Runtime.chromeOnAndroid) {
      AdbDevice device = idleAdbDevices.removeLast();
      adbDeviceMapping[id] = device;
      browser = new AndroidChrome(device);
    } else {
      var path = configuration.browserLocation;
      browser = new Browser.byRuntime(
          configuration.runtime, path, configuration.isChecked);
      browser.logger = logger;
    }

    browser.id = id;
    markCurrentlyStarting(id);
    var status = new BrowserStatus(browser);
    browserStatus[id] = status;
    numBrowsers++;
    status.nextTestTimeout = createNextTestTimer(status);
    browser.start(url);
  }

  void handleResults(String browserId, String output, int testId) {
    var status = browserStatus[browserId];
    if (testCache.containsKey(testId)) {
      doubleReportingOutputs[testId] = output;
      return;
    }

    if (status == null || status.timeout) {
      // We don't do anything, this browser is currently being killed and
      // replaced. The browser here can be null if we decided to kill the
      // browser.
    } else if (status.currentTest != null) {
      status.currentTest.timeoutTimer.cancel();
      status.currentTest.stopwatch.stop();

      if (status.currentTest.id != testId) {
        print("Expected test id ${status.currentTest.id} for"
            "${status.currentTest.url}");
        print("Got test id ${testId}");
        print("Last test id was ${status.lastTest.id} for "
            "${status.currentTest.url}");
        throw ("This should never happen, wrong test id");
      }
      testCache[testId] = status.currentTest.url;

      // Report that the test is finished now
      var browserTestOutput = new BrowserTestOutput(
          status.currentTest.delayUntilTestStarted,
          status.currentTest.stopwatch.elapsed,
          output,
          status.browser.testBrowserOutput);
      status.currentTest.doneCallback(browserTestOutput);

      status.lastTest = status.currentTest;
      status.currentTest = null;
      status.nextTestTimeout = createNextTestTimer(status);
    } else {
      print("\nThis is bad, should never happen, handleResult no test");
      print("URL: ${status.lastTest.url}");
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
    } else if (status.currentTest != null && status.currentTest.id == testId) {
      status.currentTest.lastKnownMessage = output;
    }
  }

  void handleStarted(String browserId, String output, int testId) {
    var status = browserStatus[browserId];

    if (status != null && !status.timeout && status.currentTest != null) {
      status.currentTest.timeoutTimer.cancel();
      status.currentTest.timeoutTimer =
          createTimeoutTimer(status.currentTest, status);
      status.currentTest.delayUntilTestStarted =
          status.currentTest.stopwatch.elapsed;
    }
  }

  Future handleTimeout(BrowserStatus status) async {
    // We simply kill the browser and starts up a new one!
    // We could be smarter here, but it does not seems like it is worth it.
    if (status.timeout) {
      DebugLogger.error("Got test timeout for an already restarting browser");
      return;
    }
    status.timeout = true;
    timedOut.add(status.currentTest.url);
    var id = status.browser.id;

    status.currentTest.stopwatch.stop();

    // Before closing the browser, we'll try to capture a screenshot on
    // windows when using IE (to debug flakiness).
    if (status.browser is IE) {
      await captureInternetExplorerScreenshot(
          'IE screenshot for ${status.currentTest.url}');
    }
    await status.browser.close();
    var lastKnownMessage =
        'Dom could not be fetched, since the test timed out.';
    if (status.currentTest.lastKnownMessage.length > 0) {
      lastKnownMessage = status.currentTest.lastKnownMessage;
    }
    if (status.lastTest != null) {
      lastKnownMessage += '\nPrevious test was ${status.lastTest.url}';
    }
    // Wait until the browser is closed before reporting the test as timeout.
    // This will enable us to capture stdout/stderr from the browser
    // (which might provide us with information about what went wrong).
    var browserTestOutput = new BrowserTestOutput(
        status.currentTest.delayUntilTestStarted,
        status.currentTest.stopwatch.elapsed,
        lastKnownMessage,
        status.browser.testBrowserOutput,
        didTimeout: true);
    status.currentTest.doneCallback(browserTestOutput);
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
      idleAdbDevices.add(adbDeviceMapping.remove(id));
    }
    markNotCurrentlyStarting(id);
    browserStatus.remove(id);
    --numBrowsers;
  }

  BrowserTest getNextTest(String browserId) {
    markNotCurrentlyStarting(browserId);
    var status = browserStatus[browserId];
    if (status == null) return null;
    if (status.nextTestTimeout != null) {
      status.nextTestTimeout.cancel();
      status.nextTestTimeout = null;
    }
    if (testQueue.isEmpty) return null;

    // We are currently terminating this browser, don't start a new test.
    if (status.timeout) return null;

    // Restart Internet Explorer if it has been
    // running for longer than RESTART_BROWSER_INTERVAL. The tests have
    // had flaky timeouts, and this may help.
    if ((configuration.runtime == Runtime.ie10 ||
            configuration.runtime == Runtime.ie11) &&
        status.timeSinceRestart.elapsed > RESTART_BROWSER_INTERVAL) {
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

    BrowserTest test = testQueue.removeLast();
    // If our queue isn't empty, try starting more browsers
    if (testQueue.isEmpty) {
      lastEmptyTestQueueTime = new DateTime.now();
    } else {
      requestBrowser();
    }
    if (status.currentTest == null) {
      status.currentTest = test;
      status.currentTest.lastKnownMessage = '';
    } else {
      // TODO(ricow): Handle this better.
      print("Browser requested next test before reporting previous result");
      print("This happened for browser $browserId");
      print("Old test was: ${status.currentTest.url}");
      print("The test before that was: ${status.lastTest.url}");
      print("Timed out tests:");
      for (var v in timedOut) {
        print("  $v");
      }
      exit(1);
    }

    status.currentTest.timeoutTimer = createTimeoutTimer(test, status);
    status.currentTest.stopwatch = new Stopwatch()..start();

    // Reset the test specific output information (stdout, stderr) on the
    // browser, since a new test is being started.
    status.browser.resetTestBrowserOutput();
    status.browser.logBrowserInfoToTestBrowserOutput();
    return test;
  }

  /// Creates a timer that is active while a test is running on a browser.
  Timer createTimeoutTimer(BrowserTest test, BrowserStatus status) {
    return new Timer(new Duration(seconds: test.timeout), () {
      handleTimeout(status);
    });
  }

  /// Creates a timer that is active while no test is running on the
  /// browser. It has finished one test, and it has not requested a new test.
  Timer createNextTestTimer(BrowserStatus status) {
    return new Timer(BrowserTestRunner.NEXT_TEST_TIMEOUT, () {
      handleNextTestTimeout(status);
    });
  }

  void handleNextTestTimeout(BrowserStatus status) {
    DebugLogger
        .warning("Browser timed out before getting next test. Restarting");
    if (status.timeout) return;
    numBrowserGetTestTimeouts++;
    if (numBrowserGetTestTimeouts >= MAX_NEXT_TEST_TIMEOUTS) {
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
    if (doubleReportingOutputs.length == 0) return;
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
      DebugLogger.warning("${testCache[id]}, output: ");
      DebugLogger.warning("${doubleReportingOutputs[id]}");
      DebugLogger.warning("");
      DebugLogger.warning("");
    }
  }

  // TODO(26191): Call a unified fatalError(), that shuts down all subprocesses.
  // This just kills the browsers in this BrowserTestRunner instance.
  Future terminate() async {
    var browsers = <Browser>[];
    underTermination = true;
    testingServer.underTermination = true;
    for (BrowserStatus status in browserStatus.values) {
      browsers.add(status.browser);
      if (status.nextTestTimeout != null) {
        status.nextTestTimeout.cancel();
        status.nextTestTimeout = null;
      }
    }

    for (var browser in browsers) {
      await browser.close();
    }

    testingServer.errorReportingServer.close();
    printDoubleReportingTests();
  }
}

class BrowserTestingServer {
  final Configuration configuration;

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

  final String localIp;
  final bool requiresFocus;
  BrowserTestRunner testRunner;

  static const String driverPath = "/driver";
  static const String nextTestPath = "/next_test";
  static const String reportPath = "/report";
  static const String statusUpdatePath = "/status_update";
  static const String startedPath = "/started";
  static const String waitSignal = "WAIT";
  static const String terminateSignal = "TERMINATE";

  var testCount = 0;
  HttpServer errorReportingServer;
  bool underTermination = false;

  TestChangedCallback testDoneCallBack;
  TestChangedCallback testStatusUpdateCallBack;
  TestChangedCallback testStartedCallBack;
  NextTestCallback nextTestCallBack;

  BrowserTestingServer(this.configuration, this.localIp, this.requiresFocus);

  Future start() {
    return HttpServer
        .bind(localIp, configuration.testDriverErrorPort)
        .then(setupErrorServer)
        .then(setupDispatchingServer);
  }

  void setupErrorServer(HttpServer server) {
    errorReportingServer = server;
    void errorReportingHandler(HttpRequest request) {
      StringBuffer buffer = new StringBuffer();
      request.transform(UTF8.decoder).listen((data) {
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
      }, onError: (error) {
        print(error);
      });
    }

    void errorHandler(e) {
      if (!underTermination) print("Error occured in httpserver: $e");
    }

    errorReportingServer.listen(errorReportingHandler, onError: errorHandler);
  }

  void setupDispatchingServer(_) {
    var server = configuration.servers.server;
    void noCache(HttpRequest request) {
      request.response.headers
          .set("Cache-Control", "no-cache, no-store, must-revalidate");
    }

    int testId(HttpRequest request) =>
        int.parse(request.uri.queryParameters["id"]);
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
        textResponse = new Future<String>.value(
            getNextTest(browserId(request, nextTestPath)));
        request.response.headers.set('Content-Type', 'text/plain');
      } else {
        textResponse = new Future<String>.value("");
      }
      request.response.done.catchError((error) {
        if (!underTermination) {
          return textResponse.then((String text) {
            print("URI ${request.uri}");
            print("textResponse $textResponse");
            throw "Error returning content to browser: $error";
          });
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
      {bool isStatusUpdate}) {
    StringBuffer buffer = new StringBuffer();
    request.transform(UTF8.decoder).listen((data) {
      buffer.write(data);
    }, onDone: () {
      String back = buffer.toString();
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
    StringBuffer buffer = new StringBuffer();
    // If an error occurs while receiving the data from the request stream,
    // we don't handle it specially. We can safely ignore it, since the started
    // events are not crucial.
    request.transform(UTF8.decoder).listen((data) {
      buffer.write(data);
    }, onDone: () {
      String back = buffer.toString();
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
    if (errorReportingServer == null) {
      print("Bad browser testing server, you are not started yet. Can't "
          "produce driver url");
      exit(1);
      // This should never happen - exit immediately;
    }

    return "http://$localIp:${configuration.servers.port}/driver/$browserId";
  }

  Future<String> getDriverPage(String browserId) async {
    await testRunner.browserStatus[browserId].browser.onDriverPageRequested();
    var errorReportingUrl =
        "http://$localIp:${errorReportingServer.port}/$browserId";
    String driverContent = """
<!DOCTYPE html><html>
<head>
  <title>Driving page</title>
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

      // Object that holds the state of an HTML test
      var html_test;

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
              if (nextTask.isHtmlTest) {
                html_test = {
                  expected_messages: nextTask.expectedMessages,
                  found_message_count: 0,
                  double_received_messages: [],
                  unexpected_messages: [],
                  found_messages: {}
                };
                for (var i = 0; i < html_test.expected_messages.length; ++i) {
                  html_test.found_messages[html_test.expected_messages[i]] = 0;
                }
              } else {
                html_test = null;
              }
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

      function setChildHandlers(e) {
        embedded_iframe.contentWindow.addEventListener('message',
                                                       childMessageHandler,
                                                       false);
        embedded_iframe.contentWindow.onerror = childError;
        reportMessage("First message from html test", true, false);
        html_test.handlers_installed = true;
        sendRepeatingStatusUpdate();
      }

      function checkChildHandlersInstalled() {
        if (!html_test.handlers_installed) {
          reportMessage("First message from html test", true, false);
          reportMessage(
              'FAIL: Html test did not call ' +
              'window.parent.dispatchEvent(new Event("detect_errors")) ' +
              'as its first action', false, false);
        }
      }

      function run(url) {
        number_of_tests++;
        number_div.innerHTML = number_of_tests;
        executing_div.innerHTML = url;
        if (use_iframe) {
          if (html_test) {
            window.addEventListener('detect_errors', setChildHandlers, false);
            embedded_iframe.onload = checkChildHandlersInstalled;
          } else {
            embedded_iframe.onload = null;
          }
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
            'POST', '$startedPath/${browserId}?id=' + current_id,
            function () {}, msg, true);
        } else if (isStatusUpdate) {
            contactBrowserController(
              'POST', '$statusUpdatePath/${browserId}?id=' + current_id,
              function() {}, msg, true);
        } else {
          var is_double_report = test_completed;
          var retry = 0;
          test_completed = true;

          function reportDoneMessage() {
            contactBrowserController(
                'POST', '$reportPath/${browserId}?id=' + current_id,
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
        if (html_test != null) {
          message +=
            '  Messages received multiple times:\\n' +
            '    ' + html_test.double_received_messages + '\\n' +
            '  Unexpected messages:\\n' +
            '    ' + html_test.unexpected_messages + '\\n';
        }
        message += '  DOM:\\n' +
                   '    ' + dom;
        reportMessage(message, false, true);
      }

      function sendRepeatingStatusUpdate() {
        sendStatusUpdate();
        setTimeout(sendRepeatingStatusUpdate, STATUS_UPDATE_INTERVAL);
      }

      // HTML tests post messages to their own window, handled by this handler.
      // This handler is installed on the child window when it sends the
      // 'detect_errors' event.  Every HTML test must send 'detect_errors' to
      // its parent window as its first action, so all errors will be caught.
      function childMessageHandler(e) {
        var msg = e.data;
        if (typeof msg != 'string') return;
        if (msg in html_test.found_messages) {
          html_test.found_messages[msg]++;
          if (html_test.found_messages[msg] == 1) {
            html_test.found_message_count++;
          } else {
            html_test.double_received_messages.push(msg);
            sendStatusUpdate();
          }
        } else {
          html_test.unexpected_messages.push(msg);
          sendStatusUpdate();
        }
        if (html_test.found_message_count ==
            html_test.expected_messages.length) {
          reportMessage('Test done: PASS', false, false);
        }
      }

      if (!html_test) {
        window.addEventListener('message', messageHandler, false);
        waitForDone = false;
      }
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

Future captureInternetExplorerScreenshot(String message) async {
  if (Platform.environment['USERNAME'] != 'chrome-bot') {
    return;
  }

  print('--------------------------------------------------------------------');
  final String date =
      new DateTime.now().toUtc().toIso8601String().replaceAll(':', '_');
  final screenshotName = 'ie_screenshot_${date}.png';

  // The "capture_screen.ps1" script is next to "test.dart" in "tools/"
  final powerShellScript =
      Platform.script.resolve('../../capture_screenshot.ps1').toFilePath();
  final screenshotFile =
      Platform.script.resolve('../../../$screenshotName').toFilePath();

  final args = [
    '-ExecutionPolicy',
    'ByPass',
    '-File',
    powerShellScript,
    screenshotFile
  ];
  final ProcessResult result =
      await Process.run('powershell.exe', args, runInShell: true);
  if (result.exitCode != 0) {
    print('[$message] Failed to capture IE screenshot on windows: '
        'powershell.exe "${args.join(' ')}" returned with:\n'
        'exit code: ${result.exitCode}\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}');
  } else {
    final storageUrl = 'gs://dart-temp-crash-archive/$screenshotName';
    final args = [
      r'e:\b\depot_tools\gsutil.py',
      'cp',
      screenshotFile,
      storageUrl,
    ];
    final ProcessResult result = await Process.run('python', args);
    if (result.exitCode != 0) {
      print('[$message] Failed upload captured IE screenshot to cloud storage: '
          '"${args.join(' ')}" returned with:\n'
          'exit code: ${result.exitCode}\n'
          'stdout: ${result.stdout}\n'
          'stderr: ${result.stderr}');
    } else {
      print('[$message] Successfully uploaded screenshot to $storageUrl');
    }
    new File(screenshotFile).deleteSync();
  }
  print('--------------------------------------------------------------------');
}
