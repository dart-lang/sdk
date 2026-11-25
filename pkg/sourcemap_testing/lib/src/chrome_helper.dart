// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for running compiled JavaScript in Chrome under the debugger.
///
/// This mirrors the setup used by the DDC expression evaluation tests in
/// `pkg/dev_compiler/test/expression_compiler/expression_compiler_e2e_suite.dart`.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' show pow;

import 'package:browser_launcher/browser_launcher.dart' as browser;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

/// A Chrome instance with a debugger connection to a single tab.
class ChromeSession {
  final browser.Chrome _chrome;
  final Directory _userDataDir;

  /// The connection to the tab that was opened on `about:blank`.
  final wip.WipConnection connection;

  ChromeSession._(this._chrome, this._userDataDir, this.connection);

  /// Launches Chrome and connects to its initial tab.
  ///
  /// The executable is located by `package:browser_launcher`, which honors the
  /// `CHROME_EXECUTABLE` and `CHROME_PATH` environment variables (set by
  /// test.py when it is passed `--chrome`) before falling back to the default
  /// install location.
  static Future<ChromeSession> start() async {
    var userDataDir = Directory.systemTemp.createTempSync(
      'sourcemap_testing_chrome',
    );
    browser.Chrome? chrome;
    var maxAttempts = 3;
    var attempt = 0;
    // Chrome can start and be ready while still printing messages to stderr,
    // which results in an exception being thrown. Check `chrome == null` so we
    // don't accidentally start multiple instances.
    while (chrome == null && attempt++ < maxAttempts) {
      try {
        chrome = await browser.Chrome.startWithDebugPort(
          ['about:blank'],
          userDataDir: userDataDir.path,
          // TODO(#45713): Headless Chrome crashes the Windows bots, so run in
          // standard mode there until it's fixed.
          headless: !Platform.isWindows,
          // Disabling to avoid issues with the AppArmor security features in
          // Ubuntu "Resolute".
          additionalArguments: ['--no-sandbox'],
        );
      } catch (e) {
        if (attempt == maxAttempts) {
          await deleteDirectoryWithRetries(userDataDir);
          rethrow;
        }
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
    if (chrome == null) {
      await deleteDirectoryWithRetries(userDataDir);
      throw Exception('Unable to launch Chrome.');
    }

    try {
      var tab = await chrome.chromeConnection.getTab(
        (tab) => !tab.isBackgroundPage && !tab.isChromeExtension,
        retryFor: const Duration(seconds: 5),
      );
      if (tab == null) throw Exception('Unable to connect to Chrome tab.');
      var connection = await tab.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Unable to connect to WIP tab.'),
      );
      return ChromeSession._(chrome, userDataDir, connection);
    } catch (_) {
      await chrome.close();
      await deleteDirectoryWithRetries(userDataDir);
      rethrow;
    }
  }

  /// Closes the connection, kills Chrome and deletes its profile directory.
  Future<void> close() async {
    try {
      await connection.close();
    } catch (_) {
      // The connection may already be gone if Chrome crashed.
    }
    await _chrome.close();
    await deleteDirectoryWithRetries(_userDataDir);
  }
}

/// Deletes [dir], retrying with exponential backoff.
///
/// On Windows, Chrome may not have released its files yet right after it has
/// been closed.
Future<void> deleteDirectoryWithRetries(Directory dir) async {
  var maxAttempts = 4;
  var attempt = 0;
  while (await dir.exists()) {
    attempt++;
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      if (attempt == maxAttempts) {
        print('Unable to delete ${dir.path}: $e');
        return;
      }
      var delayMs = pow(10, attempt).floor();
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}

/// A static file server on `127.0.0.1`, built on `package:shelf_static`.
///
/// Each root directory is served under a single-segment URL prefix, e.g. with
/// `{'root_build': '/tmp/out'}` the file `/tmp/out/js.js` is served at
/// `/root_build/js.js`. `shelf_static` refuses paths outside the roots.
class StaticFileServer {
  final HttpServer _server;

  /// The URL path prefixes that [start] was called with.
  final Set<String> _prefixes;

  StaticFileServer._(this._server, this._prefixes);

  /// Starts a server on an ephemeral port.
  static Future<StaticFileServer> start(Map<String, String> roots) async {
    var handlers = {
      for (var MapEntry(:key, :value) in roots.entries)
        key: createStaticHandler(value),
    };
    Future<Response> handler(Request request) async {
      var prefix = request.url.pathSegments.firstOrNull;
      var rootHandler = handlers[prefix];
      if (rootHandler == null) return Response.notFound(null);
      return rootHandler(request.change(path: prefix));
    }

    return StaticFileServer._(
      await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0),
      roots.keys.toSet(),
    );
  }

  /// The URL of [path] on this server.
  ///
  /// [path] is a URL path that starts with one of the prefixes passed to
  /// [start], e.g. `/root_build/js.js`.
  Uri urlFor(String path) {
    var url = Uri(
      scheme: 'http',
      host: _server.address.address,
      port: _server.port,
      path: path,
    );
    if (!_prefixes.contains(url.pathSegments.firstOrNull)) {
      throw ArgumentError.value(
        path,
        'path',
        'Must start with one of ${_prefixes.map((prefix) => '/$prefix/')}',
      );
    }
    return url;
  }

  Future<void> close() => _server.close(force: true);
}
