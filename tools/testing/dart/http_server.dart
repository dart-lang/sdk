// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server;

import 'dart:async';
import 'dart:io';

import 'dart:convert' show
    HtmlEscape;

import 'test_suite.dart';  // For TestUtils.
// TODO(efortuna): Rewrite to not use the args library and simply take an
// expected number of arguments, so test.dart doesn't rely on the args library?
// See discussion on https://codereview.chromium.org/11931025/.
import 'vendored_pkg/args/args.dart';
import 'utils.dart';

class DispatchingServer {
  HttpServer server;
  Map<String, Function> _handlers = new Map<String, Function>();
  Function _notFound;

  DispatchingServer(this.server,
                    void onError(e),
                    void this._notFound(HttpRequest request)) {
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
/// /FOO/packages/BAR: This will serve the corresponding file from the packages
///                    directory (i.e. '$BuildDirectory/packages/BAR') or the 
///                    passed-in package root
/// /ws: This will upgrade the connection to a WebSocket connection and echo
///      all data back to the client.
///
/// In case a path does not refer to a file but rather to a directory, a
/// directory listing will be displayed.

const PREFIX_BUILDDIR = 'root_build';
const PREFIX_DARTDIR = 'root_dart';

// TODO(kustermann,ricow): We could change this to the following scheme:
// http://host:port/root_packages/X -> $BuildDir/packages/X
// Issue: 8368

main(List<String> arguments) {
  // This script is in [dart]/tools/testing/dart.
  TestUtils.setDartDirUri(Platform.script.resolve('../../..'));
  /** Convenience method for local testing. */
  var parser = new ArgParser();
  parser.addOption('port', abbr: 'p',
      help: 'The main server port we wish to respond to requests.',
      defaultsTo: '0');
  parser.addOption('crossOriginPort', abbr: 'c',
      help: 'A different port that accepts request from the main server port.',
      defaultsTo: '0');
  parser.addFlag('help', abbr: 'h', negatable: false,
      help: 'Print this usage information.');
  parser.addOption('build-directory', help: 'The build directory to use.');
  parser.addOption('package-root', help: 'The package root to use.');
  parser.addOption('network', help: 'The network interface to use.',
      defaultsTo: '0.0.0.0');
  parser.addFlag('csp', help: 'Use Content Security Policy restrictions.',
      defaultsTo: false);
  parser.addOption('runtime', help: 'The runtime we are using (for csp flags).',
      defaultsTo: 'none');

  var args = parser.parse(arguments);
  if (args['help']) {
    print(parser.getUsage());
  } else {
    var servers = new TestingServers(new Path(args['build-directory']),
                                     args['csp'],
                                     args['runtime'],
                                     null,
                                     args['package-root']);
    var port = int.parse(args['port']);
    var crossOriginPort = int.parse(args['crossOriginPort']);
    servers.startServers(args['network'],
                         port: port,
                         crossOriginPort: crossOriginPort).then((_) {
      DebugLogger.info('Server listening on port ${servers.port}');
      DebugLogger.info('Server listening on port ${servers.crossOriginPort}');
    });
  }
}

/**
 * Runs a set of servers that are initialized specifically for the needs of our
 * test framework, such as dealing with package-root.
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
    "/NonExistingFile.js",
    "/hahaURL",
    "/UNEXISTENT",
    "/missing.png",
    "/NoSuchPart.dart",
    "/Nonexistent_library.dart",
    "/missing_file",
    "/xxx-missing.jpeg",
    "/does-not-exist.css"
  ];

  List _serverList = [];
  Path _buildDirectory = null;
  Path _dartDirectory = null;
  Path _packageRoot;
  final bool useContentSecurityPolicy;
  final String runtime;
  DispatchingServer _server;

  TestingServers(Path buildDirectory,
                 this.useContentSecurityPolicy,
                 [String this.runtime = 'none', String dartDirectory,
                  String packageRoot]) {
    _buildDirectory = TestUtils.absolutePath(buildDirectory);
    _dartDirectory = dartDirectory == null ? TestUtils.dartDir
        : new Path(dartDirectory);
    _packageRoot = packageRoot == null ? 
      _buildDirectory.append('packages') :
      new Path(packageRoot);
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
  Future startServers(String host, {int port: 0, int crossOriginPort: 0}) {
    return _startHttpServer(host, port: port).then((server) {
      _server = server;
      return _startHttpServer(host,
                              port: crossOriginPort,
                              allowedPort:_serverList[0].port);
    });
  }

  String httpServerCommandline() {
    var dart = TestUtils.dartTestExecutable.toNativePath();
    var dartDir = TestUtils.dartDir;
    var script = dartDir.join(new Path("tools/testing/dart/http_server.dart"));
    var buildDirectory = _buildDirectory.toNativePath();
    var csp = useContentSecurityPolicy ? '--csp ' : '';
    return '$dart $script -p $port -c $crossOriginPort $csp'
           '--build-directory=$buildDirectory --runtime=$runtime '
           '--package-root=$_packageRoot';
  }

  void stopServers() {
    for (var server in _serverList) {
      server.close();
    }
  }

  void _onError(e) {
    DebugLogger.error('HttpServer: an error occured', e);
  }

  Future _startHttpServer(String host, {int port: 0, int allowedPort: -1}) {
    return HttpServer.bind(host, port).then((HttpServer httpServer) {
      var server = new DispatchingServer(httpServer, _onError, _sendNotFound);
      server.addHandler('/echo', _handleEchoRequest);
      server.addHandler('/ws', _handleWebSocketRequest);
      fileHandler(request) {
        _handleFileOrDirectoryRequest(request, allowedPort);
      }
      server.addHandler('/$PREFIX_BUILDDIR', fileHandler);
      server.addHandler('/$PREFIX_DARTDIR', fileHandler);
      server.addHandler('/packages', fileHandler);
      _serverList.add(httpServer);
      return server;
    });
  }

  void _handleFileOrDirectoryRequest(HttpRequest request,
                                     int allowedPort) {
    // Enable browsers to cache file/directory responses.
    var response = request.response;
    response.headers.set("Cache-Control",
                         "max-age=$_CACHE_EXPIRATION_IN_SECONDS");
    var path = _getFilePathFromRequestPath(request.uri.path);
    if (path != null) {
      var file = new File(path.toNativePath());
      file.exists().then((exists) {
        if (exists) {
          _sendFileContent(request, response, allowedPort, path, file);
        } else {
          var directory = new Directory(path.toNativePath());
          directory.exists().then((exists) {
            if (exists) {
              _listDirectory(directory).then((entries) {
                _sendDirectoryListing(entries, request, response);
              });
            } else {
              _sendNotFound(request);
            }
          });
        }
      });
    } else {
      if (request.uri.path == '/') {
        var entries = [new _Entry('root_dart', 'root_dart/'),
                       new _Entry('root_build', 'root_build/'),
                       new _Entry('echo', 'echo')];
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
        websocket.close();
      }, onError: (e) {
        DebugLogger.warning('HttpServer: error while echoing to WebSocket', e);
      });
    }).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while transforming to WebSocket', e);
    });
  }

  Path _getFilePathFromRequestPath(String urlRequestPath) {
    // Go to the top of the file to see an explanation of the URL path scheme.
    var requestPath = new Path(urlRequestPath.substring(1)).canonicalize();
    var pathSegments = requestPath.segments();
    if (pathSegments.length > 0) {
      var basePath;
      var relativePath;
      if (pathSegments[0] == PREFIX_BUILDDIR) {
        basePath = _buildDirectory;
        relativePath = new Path(
            pathSegments.skip(1).join('/'));
      } else if (pathSegments[0] == PREFIX_DARTDIR) {
        basePath = _dartDirectory;
        relativePath = new Path(
            pathSegments.skip(1).join('/'));
      }
      var packagesIndex = pathSegments.indexOf('packages');
      if (packagesIndex != -1) {
        var start = packagesIndex + 1;
        basePath = _packageRoot;
        relativePath = new Path(pathSegments.skip(start).join('/'));
      }
      if (basePath != null && relativePath != null) {
        return basePath.join(relativePath);
      }
    }
    return null;
  }

  Future<List<_Entry>> _listDirectory(Directory directory) {
    var completer = new Completer();
    var entries = [];

    directory.list().listen(
      (FileSystemEntity fse) {
        var filename = new Path(fse.path).filename;
        if (fse is File) {
          entries.add(new _Entry(filename, filename));
        } else if (fse is Directory) {
          entries.add(new _Entry(filename, '$filename/'));
        }
      },
      onDone: () {
        completer.complete(entries);
      });
    return completer.future;
  }

  void _sendDirectoryListing(List<_Entry> entries,
                             HttpRequest request,
                             HttpResponse response) {
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
      response.write(
          '<li><a href="${new Path(request.uri.path).append(entry.name)}">'
          '${entry.displayName}</a></li>');
    }
    response.write(footer);
    response.close();
    response.done.catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _sendFileContent(HttpRequest request,
                        HttpResponse response,
                        int allowedPort,
                        Path path,
                        File file) {
    if (allowedPort != -1) {
      var headerOrigin = request.headers.value('Origin');
      var allowedOrigin;
      if (headerOrigin != null) {
        var origin = Uri.parse(headerOrigin);
        // Allow loading from http://*:$allowedPort in browsers.
        allowedOrigin =
          '${origin.scheme}://${origin.host}:${allowedPort}';
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
      for (var header in ["Content-Security-Policy",
                          "X-Content-Security-Policy"]) {
        response.headers.set(header, content_header_value);
      }
      if (const ["safari"].contains(runtime)) {
        response.headers.set("X-WebKit-CSP", content_header_value);
      }
    }
    if (path.filename.endsWith('.html')) {
      response.headers.set('Content-Type', 'text/html');
    } else if (path.filename.endsWith('.js')) {
      response.headers.set('Content-Type', 'application/javascript');
    } else if (path.filename.endsWith('.dart')) {
      response.headers.set('Content-Type', 'application/dart');
    }
    response.headers.removeAll("X-Frame-Options");
    file.openRead().pipe(response).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _sendNotFound(HttpRequest request) {
    bool isHarmlessPath(String path) {
      return _HARMLESS_REQUEST_PATH_ENDINGS.any((ending) {
        return path.endsWith(ending);
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
class _Entry implements Comparable {
  final String name;
  final String displayName;

  _Entry(this.name, this.displayName);

  int compareTo(_Entry other) {
    return name.compareTo(other.name);
  }
}
