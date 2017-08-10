// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show HtmlEscape;
import 'dart:io';

import 'configuration.dart';
import 'vendored_pkg/args/args.dart';
import 'utils.dart';

class DispatchingServer {
  HttpServer server;
  Map<String, Function> _handlers = new Map<String, Function>();
  Function _notFound;

  DispatchingServer(
      this.server, void onError(e), void this._notFound(HttpRequest request)) {
    server.listen(_dispatchRequest, onError: onError);
  }

  void addHandler(String prefix, void handler(HttpRequest request)) {
    _handlers[prefix] = handler;
  }

  void _dispatchRequest(HttpRequest request) {
    // If the request path matches a prefix in _handlers, send it to that
    // handler.  Otherwise, run the notFound handler.
    for (String prefix in _handlers.keys) {
      if (request.uri.path.startsWith(prefix)) {
        _handlers[prefix](request);
        return;
      }
    }
    _notFound(request);
  }
}

/// Interface of the HTTP server:
///
/// /echo: This will stream the data received in the request stream back
///        to the client.
/// /root_dart/X: This will serve the corresponding file from the dart
///               directory (i.e. '$DartDirectory/X').
/// /root_build/X: This will serve the corresponding file from the build
///                directory (i.e. '$BuildDirectory/X').
/// /ws: This will upgrade the connection to a WebSocket connection and echo
///      all data back to the client.
///
/// In case a path does not refer to a file but rather to a directory, a
/// directory listing will be displayed.

const PREFIX_BUILDDIR = 'root_build';
const PREFIX_DARTDIR = 'root_dart';

void main(List<String> arguments) {
  // This script is in [dart]/tools/testing/dart.
  TestUtils.setDartDirUri(Platform.script.resolve('../../..'));
  /** Convenience method for local testing. */
  var parser = new ArgParser();
  parser.addOption('port',
      abbr: 'p',
      help: 'The main server port we wish to respond to requests.',
      defaultsTo: '0');
  parser.addOption('crossOriginPort',
      abbr: 'c',
      help: 'A different port that accepts request from the main server port.',
      defaultsTo: '0');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Print this usage information.');
  parser.addOption('build-directory', help: 'The build directory to use.');
  parser.addOption('package-root', help: 'Obsolete unsupported option');
  parser.addOption('packages', help: 'Obsolete unsupported option');
  parser.addOption('network',
      help: 'The network interface to use.', defaultsTo: '0.0.0.0');
  parser.addFlag('csp',
      help: 'Use Content Security Policy restrictions.', defaultsTo: false);
  parser.addOption('runtime',
      help: 'The runtime we are using (for csp flags).', defaultsTo: 'none');

  var args = parser.parse(arguments);
  if (args['help'] as bool) {
    print(parser.getUsage());
  } else {
    var servers = new TestingServers(args['build-directory'] as String,
        args['csp'] as bool, Runtime.find(args['runtime'] as String), null);
    var port = int.parse(args['port'] as String);
    var crossOriginPort = int.parse(args['crossOriginPort'] as String);
    servers
        .startServers(args['network'] as String,
            port: port, crossOriginPort: crossOriginPort)
        .then((_) {
      DebugLogger.info('Server listening on port ${servers.port}');
      DebugLogger.info('Server listening on port ${servers.crossOriginPort}');
    });
  }
}

/**
 * Runs a set of servers that are initialized specifically for the needs of our
 * test framework.
 */
class TestingServers {
  static final _CACHE_EXPIRATION_IN_SECONDS = 30;
  static final _HARMLESS_REQUEST_PATH_ENDINGS = [
    "/apple-touch-icon.png",
    "/apple-touch-icon-precomposed.png",
    "/favicon.ico",
    "/foo",
    "/bar",
    "/NonExistingFile",
    "IntentionallyMissingFile",
  ];

  final List<HttpServer> _serverList = [];
  Uri _buildDirectory;
  Uri _dartDirectory;
  final bool useContentSecurityPolicy;
  final Runtime runtime;
  DispatchingServer _server;

  TestingServers(String buildDirectory, this.useContentSecurityPolicy,
      [this.runtime = Runtime.none, String dartDirectory]) {
    _buildDirectory = Uri.base.resolveUri(new Uri.directory(buildDirectory));
    if (dartDirectory == null) {
      _dartDirectory = TestUtils.dartDirUri;
    } else {
      _dartDirectory = Uri.base.resolveUri(new Uri.directory(dartDirectory));
    }
  }

  int get port => _serverList[0].port;
  int get crossOriginPort => _serverList[1].port;
  DispatchingServer get server => _server;

  /**
   * [startServers] will start two Http servers.
   * The first server listens on [port] and sets
   *   "Access-Control-Allow-Origin: *"
   * The second server listens on [crossOriginPort] and sets
   *   "Access-Control-Allow-Origin: client:port1
   *   "Access-Control-Allow-Credentials: true"
   */
  Future startServers(String host,
      {int port: 0, int crossOriginPort: 0}) async {
    _server = await _startHttpServer(host, port: port);
    await _startHttpServer(host,
        port: crossOriginPort, allowedPort: _serverList[0].port);
  }

  String httpServerCommandLine() {
    var dart = Platform.resolvedExecutable;
    var script = _dartDirectory.resolve('tools/testing/dart/http_server.dart');
    var buildDirectory = _buildDirectory.toFilePath();
    var command = [
      dart,
      script.toFilePath(),
      '-p',
      port,
      '-c',
      crossOriginPort,
      '--build-directory=$buildDirectory',
      '--runtime=${runtime.name}'
    ];
    if (useContentSecurityPolicy) {
      command.add('--csp');
    }
    return command.join(' ');
  }

  void stopServers() {
    for (var server in _serverList) {
      server.close();
    }
  }

  void _onError(e) {
    DebugLogger.error('HttpServer: an error occured', e);
  }

  Future<DispatchingServer> _startHttpServer(String host,
      {int port: 0, int allowedPort: -1}) {
    return HttpServer.bind(host, port).then((HttpServer httpServer) {
      var server = new DispatchingServer(httpServer, _onError, _sendNotFound);
      server.addHandler('/echo', _handleEchoRequest);
      server.addHandler('/ws', _handleWebSocketRequest);
      fileHandler(HttpRequest request) {
        _handleFileOrDirectoryRequest(request, allowedPort);
      }

      server.addHandler('/$PREFIX_BUILDDIR', fileHandler);
      server.addHandler('/$PREFIX_DARTDIR', fileHandler);
      _serverList.add(httpServer);
      return server;
    });
  }

  Future _handleFileOrDirectoryRequest(
      HttpRequest request, int allowedPort) async {
    // Enable browsers to cache file/directory responses.
    var response = request.response;
    response.headers
        .set("Cache-Control", "max-age=$_CACHE_EXPIRATION_IN_SECONDS");
    var path = _getFileUriFromRequestUri(request.uri);
    if (path != null) {
      var file = new File.fromUri(path);
      var directory = new Directory.fromUri(path);
      if (await file.exists()) {
        _sendFileContent(request, response, allowedPort, file);
      } else if (await directory.exists()) {
        _sendDirectoryListing(
            await _listDirectory(directory), request, response);
      } else {
        _sendNotFound(request);
      }
    } else {
      if (request.uri.path == '/') {
        var entries = [
          new _Entry('root_dart', 'root_dart/'),
          new _Entry('root_build', 'root_build/'),
          new _Entry('echo', 'echo')
        ];
        _sendDirectoryListing(entries, request, response);
      } else {
        _sendNotFound(request);
      }
    }
  }

  void _handleEchoRequest(HttpRequest request) {
    request.response.headers.set("Access-Control-Allow-Origin", "*");
    request.pipe(request.response).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _handleWebSocketRequest(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((websocket) {
      // We ignore failures to write to the socket, this happens if the browser
      // closes the connection.
      websocket.done.catchError((_) {});
      websocket.listen((data) {
        websocket.add(data);
        if (data == 'close-with-error') {
          // Note: according to the web-sockets spec, a reason longer than 123
          // bytes will produce a SyntaxError on the client.
          websocket.close(WebSocketStatus.UNSUPPORTED_DATA, 'X' * 124);
        } else {
          websocket.close();
        }
      }, onError: (e) {
        DebugLogger.warning('HttpServer: error while echoing to WebSocket', e);
      });
    }).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while transforming to WebSocket', e);
    });
  }

  Uri _getFileUriFromRequestUri(Uri request) {
    // Go to the top of the file to see an explanation of the URL path scheme.
    List<String> pathSegments = request.normalizePath().pathSegments;
    if (pathSegments.length == 0) return null;
    if (pathSegments[0] == PREFIX_BUILDDIR) {
      return _buildDirectory.resolve(pathSegments.skip(1).join('/'));
    }
    if (pathSegments[0] == PREFIX_DARTDIR) {
      return _dartDirectory.resolve(pathSegments.skip(1).join('/'));
    }
    return null;
  }

  Future<List<_Entry>> _listDirectory(Directory directory) {
    var completer = new Completer<List<_Entry>>();
    var entries = <_Entry>[];

    directory.list().listen((FileSystemEntity fse) {
      var segments = fse.uri.pathSegments;
      if (fse is File) {
        var filename = segments.last;
        entries.add(new _Entry(filename, filename));
      } else if (fse is Directory) {
        var dirname = segments[segments.length - 2];
        entries.add(new _Entry(dirname, '$dirname/'));
      }
    }, onDone: () {
      completer.complete(entries);
    });
    return completer.future;
  }

  void _sendDirectoryListing(
      List<_Entry> entries, HttpRequest request, HttpResponse response) {
    response.headers.set('Content-Type', 'text/html');
    var header = '''<!DOCTYPE html>
    <html>
    <head>
      <title>${request.uri.path}</title>
    </head>
    <body>
      <code>
        <div>${request.uri.path}</div>
        <hr/>
        <ul>''';
    var footer = '''
        </ul>
      </code>
    </body>
    </html>''';

    entries.sort();
    response.write(header);
    for (var entry in entries) {
      response.write('<li><a href="${request.uri}/${entry.name}">'
          '${entry.displayName}</a></li>');
    }
    response.write(footer);
    response.close();
    response.done.catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _sendFileContent(
      HttpRequest request, HttpResponse response, int allowedPort, File file) {
    if (allowedPort != -1) {
      var headerOrigin = request.headers.value('Origin');
      String allowedOrigin;
      if (headerOrigin != null) {
        var origin = Uri.parse(headerOrigin);
        // Allow loading from http://*:$allowedPort in browsers.
        allowedOrigin = '${origin.scheme}://${origin.host}:${allowedPort}';
      } else {
        // IE10 appears to be bugged and is not sending the Origin header
        // when making CORS requests to the same domain but different port.
        allowedOrigin = '*';
      }

      response.headers.set("Access-Control-Allow-Origin", allowedOrigin);
      response.headers.set('Access-Control-Allow-Credentials', 'true');
    } else {
      // No allowedPort specified. Allow from anywhere (but cross-origin
      // requests *with credentials* will fail because you can't use "*").
      response.headers.set("Access-Control-Allow-Origin", "*");
    }
    if (useContentSecurityPolicy) {
      // Chrome respects the standardized Content-Security-Policy header,
      // whereas Firefox and IE10 use X-Content-Security-Policy. Safari
      // still uses the WebKit- prefixed version.
      var content_header_value = "script-src 'self'; object-src 'self'";
      for (var header in [
        "Content-Security-Policy",
        "X-Content-Security-Policy"
      ]) {
        response.headers.set(header, content_header_value);
      }
      if (const ["safari"].contains(runtime)) {
        response.headers.set("X-WebKit-CSP", content_header_value);
      }
    }
    if (file.path.endsWith('.html')) {
      response.headers.set('Content-Type', 'text/html');
    } else if (file.path.endsWith('.js')) {
      response.headers.set('Content-Type', 'application/javascript');
    } else if (file.path.endsWith('.dart')) {
      response.headers.set('Content-Type', 'application/dart');
    } else if (file.path.endsWith('.css')) {
      response.headers.set('Content-Type', 'text/css');
    } else if (file.path.endsWith('.xml')) {
      response.headers.set('Content-Type', 'text/xml');
    }
    response.headers.removeAll("X-Frame-Options");
    file.openRead().pipe(response).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _sendNotFound(HttpRequest request) {
    bool isHarmlessPath(String path) {
      return _HARMLESS_REQUEST_PATH_ENDINGS.any((pattern) {
        return path.contains(pattern);
      });
    }

    if (!isHarmlessPath(request.uri.path)) {
      DebugLogger.warning('HttpServer: could not find file for request path: '
          '"${request.uri.path}"');
    }
    var response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;

    // Send a nice HTML page detailing the error message.  Most browsers expect
    // this, for example, Chrome will simply display a blank page if you don't
    // provide any information.  A nice side effect of this is to work around
    // Firefox bug 1016313
    // (https://bugzilla.mozilla.org/show_bug.cgi?id=1016313).
    response.headers.set(HttpHeaders.CONTENT_TYPE, 'text/html');
    String escapedPath = const HtmlEscape().convert(request.uri.path);
    response.write("""
<!DOCTYPE html>
<html lang='en'>
<head>
<title>Not Found</title>
</head>
<body>
<h1>Not Found</h1>
<p style='white-space:pre'>The file '$escapedPath\' could not be found.</p>
</body>
</html>
""");
    response.close();
    response.done.catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }
}

// Helper class for displaying directory listings.
class _Entry implements Comparable<_Entry> {
  final String name;
  final String displayName;

  _Entry(this.name, this.displayName);

  int compareTo(_Entry other) {
    return name.compareTo(other.name);
  }
}
