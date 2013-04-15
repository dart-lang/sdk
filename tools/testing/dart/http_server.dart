// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:uri';
import 'test_suite.dart';  // For TestUtils.
// TODO(efortuna): Rewrite to not use the args library and simply take an
// expected number of arguments, so test.dart doesn't rely on the args library?
// See discussion on https://codereview.chromium.org/11931025/.
import 'vendored_pkg/args/args.dart';
import 'utils.dart';


/// Interface of the HTTP server:
///
/// /echo: This will stream the data received in the request stream back
///        to the client.
/// /root_dart/X: This will serve the corresponding file from the dart
///               directory (i.e. '$DartDirectory/X').
/// /root_build/X: This will serve the corresponding file from the build
///                directory (i.e. '$BuildDirectory/X').
/// /FOO/packages/BAR: This will serve the corresponding file from the packages
///                    directory (i.e. '$BuildDirectory/packages/BAR')
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

main() {
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
  parser.addOption('network', help: 'The network interface to use.',
      defaultsTo: '127.0.0.1');
  parser.addFlag('csp', help: 'Use Content Security Policy restrictions.',
      defaultsTo: false);
  var args = parser.parse(new Options().arguments);
  if (args['help']) {
    print(parser.getUsage());
  } else {
    // Pretend we're running test.dart so that TestUtils doesn't get confused
    // about the "current directory." This is only used if we're trying to run
    // this file independently for local testing.
    TestUtils.testScriptPath = new Path(new Options().script)
        .directoryPath
        .join(new Path('../../test.dart'))
        .canonicalize()
        .toNativePath();
    var servers = new TestingServers(new Path(args['build-directory']),
                                     args['csp']);
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
  List _serverList = [];
  Path _buildDirectory = null;
  final bool useContentSecurityPolicy;

  TestingServers(Path buildDirectory, this.useContentSecurityPolicy) {
    _buildDirectory = TestUtils.absolutePath(buildDirectory);
  }

  int get port => _serverList[0].port;
  int get crossOriginPort => _serverList[1].port;

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
      return _startHttpServer(host,
                              port: crossOriginPort,
                              allowedPort:_serverList[0].port);
    });
  }

  String httpServerCommandline() {
    var dart = TestUtils.dartTestExecutable.toNativePath();
    var dartDir = TestUtils.dartDir();
    var script = dartDir.join(new Path("tools/testing/dart/http_server.dart"));
    var buildDirectory = _buildDirectory.toNativePath();
    var csp = useContentSecurityPolicy ? '--csp ' : '';

    return '$dart $script -p $port -c $crossOriginPort $csp'
           '--build-directory=$buildDirectory';
  }

  void stopServers() {
    for (var server in _serverList) {
      server.close();
    }
  }

  Future _startHttpServer(String host, {int port: 0, int allowedPort: -1}) {
    return HttpServer.bind(host, port).then((HttpServer httpServer) {
      httpServer.listen((HttpRequest request) {
        if (request.uri.path == "/echo") {
          _handleEchoRequest(request, request.response);
        } else if (request.uri.path == '/ws') {
          _handleWebSocketRequest(request);
        } else {
          _handleFileOrDirectoryRequest(
              request, request.response, allowedPort);
        }
      },
      onError: (e) {
        DebugLogger.error('HttpServer: an error occured', e);
      });
      _serverList.add(httpServer);
    });
  }

  void _handleFileOrDirectoryRequest(HttpRequest request,
                                     HttpResponse response,
                                     int allowedPort) {
    var path = _getFilePathFromRequestPath(request.uri.path);
    if (path != null) {
      var file = new File.fromPath(path);
      file.exists().then((exists) {
        if (exists) {
          _sendFileContent(request, response, allowedPort, path, file);
        } else {
          var directory = new Directory.fromPath(path);
          directory.exists().then((exists) {
            if (exists) {
              _listDirectory(directory).then((entries) {
                _sendDirectoryListing(entries, request, response);
              });
            } else {
              _sendNotFound(request, response);
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
        _sendNotFound(request, response);
      }
    }
  }

  void _handleEchoRequest(HttpRequest request, HttpResponse response) {
    response.headers.set("Access-Control-Allow-Origin", "*");
    request.pipe(response).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _handleWebSocketRequest(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((websocket) {
      websocket.listen((data) {
        websocket.send(data);
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
        basePath = TestUtils.dartDir();
        relativePath = new Path(
            pathSegments.skip(1).join('/'));
      }
      var packagesDirName = 'packages';
      var packagesIndex = pathSegments.indexOf(packagesDirName);
      if (packagesIndex != -1) {
        var start = packagesIndex + 1;
        basePath = _buildDirectory.append(packagesDirName);
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
        var origin = new Uri(headerOrigin);
        // Allow loading from http://*:$allowedPort in browsers.
        allowedOrigin =
          '${origin.scheme}://${origin.domain}:${allowedPort}';
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
      for (var header in ["Content-Security-Policy",
                          "X-Content-Security-Policy",
                          "X-WebKit-CSP"]) {
        response.headers.set(header, "script-src 'self'; object-src 'self'");
      }
    }
    if (path.filename.endsWith('.html')) {
      response.headers.set('Content-Type', 'text/html');
    } else if (path.filename.endsWith('.js')) {
      response.headers.set('Content-Type', 'application/javascript');
    } else if (path.filename.endsWith('.dart')) {
      response.headers.set('Content-Type', 'application/dart');
    }
    file.openRead().pipe(response).catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }

  void _sendNotFound(HttpRequest request, HttpResponse response) {
    // NOTE: Since some tests deliberately try to access non-existent files.
    // We might want to remove this warning (otherwise it will show
    // up in the debug.log every time).
    if (request.uri.path != "/favicon.ico") {
      DebugLogger.warning('HttpServer: could not find file for request path: '
                          '"${request.uri.path}"');
    }
    response.statusCode = HttpStatus.NOT_FOUND;
    response.close();
    response.done.catchError((e) {
      DebugLogger.warning(
          'HttpServer: error while closing the response stream', e);
    });
  }
}

// Helper class for displaying directory listings.
class _Entry {
  final String name;
  final String displayName;

  _Entry(this.name, this.displayName);

  int compareTo(_Entry other) {
    return name.compareTo(other.name);
  }
}
