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
    response.statusCode = HttpStatus.NOT_FOUND;
    response.write(htmlInfo('Not Found',
                            'The file "$path" could not be found.'));
    response.close();
  }

  badRequest(String problem) {
    response.statusCode = HttpStatus.BAD_REQUEST;
    response.write(htmlInfo("Bad request",
                            "Bad request '${request.uri}': $problem"));
    response.close();
  }

  internalError(error, stack) {
    print(error);
    if (stack != null) print(stack);
    response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    response.write(htmlInfo("Internal Server Error",
                            "Internal Server Error: $error\n$stack"));
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
    String dartType = 'application/dart';
    if (path.startsWith('${PACKAGES_PATH}/')) {
      root = packageRoot;
      path = path.substring(PACKAGES_PATH.length);
    }

    String filePath = root.resolve('.$path').toFilePath();
    switch (request.method) {
      case 'GET':
        return handleGet(filePath, dartType);
      default:
        String method = const HtmlEscape().convert(request.method);
        return badRequest("Unsupported method: '$method'");
    }
  }

  void handleGet(String path, String dartType) {
    var f = new File(path);
    f.exists().then((bool exists) {
      if (!exists) return notFound(request.uri);
      if (path.endsWith('.html')) {
        response.headers.set(CONTENT_TYPE, 'text/html');
      } else if (path.endsWith('.dart')) {
        response.headers.set(CONTENT_TYPE, dartType);
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
  if (arguments.length > 0) {
    Conversation.documentRoot = Uri.base.resolve(arguments[0]);
  }
  var host = '127.0.0.1';
  if (arguments.length > 1) {
    host = arguments[1];
  }
  int port = 0;
  if (arguments.length > 2) {
    port = int.parse(arguments[2]);
  }
  if (arguments.length > 3) {
    Conversation.packageRoot = Uri.base.resolve(arguments[4]);
  }
  HttpServer.bind(host, port).then((HttpServer server) {
    print('HTTP server started on http://$host:${server.port}/');
    server.listen(Conversation.onRequest, onError: Conversation.onError);
  }).catchError((e) {
    print("HttpServer.bind error: $e");
    exit(1);
  });
}
