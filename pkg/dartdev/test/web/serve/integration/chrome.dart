// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:webdriver/async_io.dart';

/// Starts headless Chrome through ChromeDriver, and quits both when the test
/// ends.
///
/// Finds the executables in the places where the bots download them:
/// - ChromeDriver: `$CHROMEDRIVER_PATH`, the SDK checkout's
///   `third_party/webdriver/chrome/`, or `chromedriver` on the `PATH`.
/// - Chrome: `$CHROME_EXECUTABLE` or `$CHROME_PATH`, the SDK checkout's
///   `third_party/browsers/chrome/`, or ChromeDriver's default.
Future<WebDriver> startChrome() async {
  final port = await _unusedPort();
  final chromeDriver = await Process.start(_chromeDriverExecutable, [
    '--port=$port',
  ]);
  addTearDown(chromeDriver.kill);
  // ChromeDriver prints a line once it accepts connections. Split the output
  // into lines, so that the line can't be cut in two by chunk boundaries.
  final started = Completer<void>();
  chromeDriver.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        (line) {
          if (!started.isCompleted && line.contains('started successfully')) {
            started.complete();
          }
        },
        onDone: () {
          // The output ends when ChromeDriver exits.
          if (!started.isCompleted) {
            started.completeError(
              StateError('ChromeDriver exited before it started.'),
            );
          }
        },
      );
  chromeDriver.stderr.transform(utf8.decoder).listen(stderr.write);
  await started.future.timeout(const Duration(seconds: 30));

  final driver = await createDriverWithRetry(
    uri: Uri.parse('http://127.0.0.1:$port/'),
    desired: {
      ...Capabilities.chrome,
      Capabilities.chromeOptions: {
        'args': [
          '--headless',
          '--disable-gpu',
          '--disable-extensions',
          '--no-first-run',
          '--no-default-browser-check',
          '--no-sandbox',
        ],
        'binary': ?_chromeExecutable,
      },
    },
  );
  addTearDown(driver.quit);
  return driver;
}

/// Starts a Chrome session through the ChromeDriver at [uri], trying up to
/// [maxAttempts] times, because creating a session sometimes hangs or fails
/// on the bots. Fails with the last attempt's error.
///
/// Like `package:dwds_test_common`'s, which this package doesn't depend on.
// TODO(https://github.com/dart-lang/sdk/issues/64667): Remove once these
// tests use dwds_test_common.
Future<WebDriver> createDriverWithRetry({
  required Uri uri,
  required Map<String, Object?> desired,
  int maxAttempts = 3,
  Duration timeout = const Duration(seconds: 30),
}) async {
  for (var attempt = 1; attempt < maxAttempts; attempt++) {
    try {
      return await _createSession(uri, desired, timeout);
    } catch (_) {
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
  return await _createSession(uri, desired, timeout);
}

/// One attempt to start a Chrome session, which fails after [timeout].
Future<WebDriver> _createSession(
  Uri uri,
  Map<String, Object?> desired,
  Duration timeout,
) => createDriver(
  uri: uri,
  spec: WebDriverSpec.JsonWire,
  desired: desired,
).timeout(timeout);

/// Waits until the page title in [driver] is [title], and fails after
/// [timeout].
Future<void> waitForTitle(
  WebDriver driver,
  String title, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final stopwatch = Stopwatch()..start();
  var current = await driver.title;
  while (current != title) {
    if (stopwatch.elapsed > timeout) {
      fail('Expected the page title "$title" but it is "$current".');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    current = await driver.title;
  }
}

Future<int> _unusedPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// The root of the Dart SDK checkout that contains this package.
final _sdkCheckout = Isolate.resolvePackageUriSync(
  Uri.parse('package:dartdev/'),
)!.resolve('../../../');

String get _chromeDriverExecutable =>
    _executable(
      environment: const ['CHROMEDRIVER_PATH'],
      inSdkCheckout:
          'third_party/webdriver/chrome/'
          '${Platform.isWindows ? 'chromedriver.exe' : 'chromedriver'}',
    ) ??
    'chromedriver';

String? get _chromeExecutable => _executable(
  environment: const ['CHROME_EXECUTABLE', 'CHROME_PATH'],
  // Where the Chrome that the checkout downloads is unpacked, like in
  // tools/test_devtools.py.
  inSdkCheckout: switch (Platform.operatingSystem) {
    'macos' =>
      'third_party/browsers/chrome/Google Chrome.app/Contents/MacOS/'
          'Google Chrome',
    'windows' => r'third_party/browsers/chrome/chrome/Application\chrome.exe',
    _ => 'third_party/browsers/chrome/chrome/google-chrome',
  },
);

/// The executable named by the first set variable in [environment], or the
/// one at the path [inSdkCheckout] if it exists, or `null`.
String? _executable({
  required List<String> environment,
  required String inSdkCheckout,
}) {
  for (final name in environment) {
    if (Platform.environment[name] case final path?) return path;
  }
  final path = _sdkCheckout.resolve(inSdkCheckout).toFilePath();
  return File(path).existsSync() ? path : null;
}
