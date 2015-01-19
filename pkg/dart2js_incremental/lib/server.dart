// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.server;

import 'dart:io';

import 'dart:async' show
    Future,
    Stream;

import 'dart:convert' show
    HtmlEscape,
    JSON,
    UTF8;

import 'src/options.dart';

class Conversation {
  HttpRequest request;
  HttpResponse response;

  static const String PACKAGES_PATH = '/packages';

  static const String CONTENT_TYPE = HttpHeaders.CONTENT_TYPE;

  static Uri documentRoot = Uri.base;

  static Uri packageRoot = Uri.base.resolve('packages/');

  Conversation(this.request, this.response);

  onClosed(_) {
    if (response.statusCode == HttpStatus.OK) return;
    print('Request for ${request.uri} ${response.statusCode}');
  }

  notFound(path) {
    response.headers.set(CONTENT_TYPE, 'text/html');
    response.statusCode = HttpStatus.NOT_FOUND;
    response.write(htmlInfo('Not Found',
                            'The file "$path" could not be found.'));
    response.close();
  }

  badRequest(String problem) {
    response.headers.set(CONTENT_TYPE, 'text/html');
    response.statusCode = HttpStatus.BAD_REQUEST;
    response.write(htmlInfo("Bad request",
                            "Bad request '${request.uri}': $problem"));
    response.close();
  }

  handleSocket() {
    if (false && request.uri.path == '/ws/watch') {
      WebSocketTransformer.upgrade(request).then((WebSocket socket) {
        socket.add(JSON.encode({'create': []}));
        // WatchHandler handler = new WatchHandler(socket, files);
        // handlers.add(handler);
        // socket.listen(
        //     handler.onData, cancelOnError: true, onDone: handler.onDone);
      });
    } else {
      response.done
          .then(onClosed)
          .catchError(onError);
      notFound(request.uri.path);
    }
  }

  handle() {
    response.done
      .then(onClosed)
      .catchError(onError);

    Uri uri = request.uri;
    if (uri.path.endsWith('/')) {
      uri = uri.resolve('index.html');
    }
    if (uri.path.contains('..') || uri.path.contains('%')) {
      return notFound(uri.path);
    }
    String path = uri.path;
    Uri root = documentRoot;
    if (path.startsWith('${PACKAGES_PATH}/')) {
      root = packageRoot;
      path = path.substring(PACKAGES_PATH.length);
    }

    Uri resolvedRequest = root.resolve('.$path');
    switch (request.method) {
      case 'GET':
        return handleGet(resolvedRequest);
      default:
        String method = const HtmlEscape().convert(request.method);
        return badRequest("Unsupported method: '$method'");
    }
  }

  void handleGet(Uri uri) {
    String path = uri.path;
    var f = new File.fromUri(uri);
    f.exists().then((bool exists) {
      if (!exists) {
        if (path.endsWith('.dart.js')) {
          Uri dartScript = uri.resolve(path.substring(0, path.length - 3));
          new File.fromUri(dartScript).exists().then((bool exists) {
            if (exists) {
              compileToJavaScript(dartScript);
            } else {
              notFound(request.uri);
            }
          });
          return;
        }
        notFound(request.uri);
        return;
      }
      if (path.endsWith('.html')) {
        response.headers.set(CONTENT_TYPE, 'text/html');
      } else if (path.endsWith('.dart')) {
        response.headers.set(CONTENT_TYPE, 'application/dart');
      } else if (path.endsWith('.js')) {
        response.headers.set(CONTENT_TYPE, 'application/javascript');
      } else if (path.endsWith('.ico')) {
        response.headers.set(CONTENT_TYPE, 'image/x-icon');
      } else if (path.endsWith('.appcache')) {
        response.headers.set(CONTENT_TYPE, 'text/cache-manifest');
      }
      f.openRead().pipe(response).catchError(onError);
    });
  }

  void compileToJavaScript(Uri dartScript) {
    Uri outputUri = request.uri;
    print("Compiling $dartScript to $outputUri");
    // TODO(ahe): Implement this.
    notFound(request.uri);
  }

  static onRequest(HttpRequest request) {
    Conversation conversation = new Conversation(request, request.response);
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      conversation.handleSocket();
    } else {
      conversation.handle();
    }
  }

  static onError(error) {
    if (error is HttpException) {
      print('Error: ${error.message}');
    } else {
      print('Error: ${error}');
    }
  }

  String htmlInfo(String title, String text) {
    // No script injection, please.
    title = const HtmlEscape().convert(title);
    text = const HtmlEscape().convert(text);
    return """
<!DOCTYPE html>
<html lang='en'>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
<p style='white-space:pre'>$text</p>
</body>
</html>
""";
  }
}

main(List<String> arguments) {
  Options options = Options.parse(arguments);
  if (options == null) {
    exit(1);
  }
  if (!options.arguments.isEmpty) {
    Conversation.documentRoot = Uri.base.resolve(options.arguments.single);
  }
  Conversation.packageRoot = options.packageRoot;
  String host = options.host;
  int port = options.port;
  HttpServer.bind(host, port).then((HttpServer server) {
    print('HTTP server started on http://$host:${server.port}/');
    server.listen(Conversation.onRequest, onError: Conversation.onError);
  }).catchError((e) {
    print("HttpServer.bind error: $e");
    exit(1);
  });
}
