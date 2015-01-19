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

  Future notFound(Uri uri) {
    response
        ..headers.set(CONTENT_TYPE, 'text/html')
        ..statusCode = HttpStatus.NOT_FOUND
        ..write(htmlInfo("Not Found", "The file '$uri' could not be found."));
    return response.close();
  }

  Future badRequest(String problem) {
    response
        ..headers.set(CONTENT_TYPE, 'text/html')
        ..statusCode = HttpStatus.BAD_REQUEST
        ..write(
            htmlInfo("Bad request", "Bad request '${request.uri}': $problem"));
    return response.close();
  }

  Future handleSocket() {
    if (false && request.uri.path == '/ws/watch') {
      return WebSocketTransformer.upgrade(request).then((WebSocket socket) {
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
      return notFound(request.uri);
    }
  }

  Future handle() {
    response.done
      .then(onClosed)
      .catchError(onError);

    Uri uri = request.uri;
    if (uri.path.endsWith('/')) {
      uri = uri.resolve('index.html');
    }
    if (uri.path.contains('..') || uri.path.contains('%')) {
      return notFound(uri);
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

  Future handleGet(Uri uri) {
    String path = uri.path;
    var f = new File.fromUri(uri);
    return f.exists().then((bool exists) {
      if (!exists) {
        if (path.endsWith('.dart.js')) {
          Uri dartScript = uri.resolve(path.substring(0, path.length - 3));
          return new File.fromUri(dartScript).exists().then((bool exists) {
            if (exists) {
              return compileToJavaScript(dartScript);
            } else {
              return notFound(request.uri);
            }
          });
        }
        return notFound(request.uri);
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
      return f.openRead().pipe(response);
    });
  }

  Future compileToJavaScript(Uri dartScript) {
    Uri outputUri = request.uri;
    print("Compiling $dartScript to $outputUri");
    // TODO(ahe): Implement this.
    throw new UnimplementedError("compileToJavaScript");
    return notFound(request.uri);
  }

  Future dispatch() {
    return new Future.sync(() {
      return WebSocketTransformer.isUpgradeRequest(request)
          ? handleSocket()
          : handle();
    }).catchError(onError);
  }

  static Future onRequest(HttpRequest request) {
    HttpResponse response = request.response;
    return
        new Future.sync(() => new Conversation(request, response).dispatch())
        .catchError((error, [stack]) {
          onStaticError(error, stack);
          return
              new Future.sync(() => response.close()).catchError(onStaticError);
        });
  }

  void onError(error, [stack]) {
    onStaticError(error, stack);
    new Future.sync(() => response.close()).catchError(onStaticError);
  }

  static void onStaticError(error, [stack]) {
    if (error is HttpException) {
      print('Error: ${error.message}');
    } else {
      print('Error: ${error}');
    }
    if (stack != null) {
      print(stack);
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
    server.listen(Conversation.onRequest, onError: Conversation.onStaticError);
  }).catchError((e) {
    print("HttpServer.bind error: $e");
    exit(1);
  });
}
