// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leap_server;

import 'dart:io';

class Conversation {
  HttpRequest request;
  HttpResponse response;

  static const String CONTENT_TYPE = HttpHeaders.CONTENT_TYPE;

  static const String LEAP_LANDING_PAGE =
      'sdk/lib/_internal/compiler/samples/leap/index.html';

  static String landingPage = LEAP_LANDING_PAGE;

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

  redirect(String location) {
    response.statusCode = HttpStatus.FOUND;
    response.headers.add(HttpHeaders.LOCATION, location);
    response.close();
  }

  handle() {
    response.done
      .then(onClosed)
      .catchError(onError);

    String path = request.uri.path;
    if (path == '/') return redirect('/$landingPage');
    if (path == '/favicon.ico') {
      path = '/sdk/lib/_internal/dartdoc/static/favicon.ico';
    }
    if (path.contains('..') || path.contains('%')) return notFound(path);
    var f = new File("./$path");
    f.exists().then((bool exists) {
      if (!exists) return notFound(path);
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

  static onRequest(HttpRequest request) {
    new Conversation(request, request.response).handle();
  }

  static onError(error) {
    if (error is HttpException) {
      print('Error: ${error.message}');
    } else {
      print('Error: ${error}');
    }
  }

  String htmlInfo(String title, String text) {
    return """
<!DOCTYPE html>
<html lang='en'>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
<p>$text</p>
</body>
</html>
""";
  }
}

main(List<String> arguments) {
  if (arguments.length > 0) {
    Conversation.landingPage = arguments[0];
  }
  var host = '127.0.0.1';
  if (arguments.length > 1) {
    host = arguments[1];
  }
  int port = 0;
  if (arguments.length > 2) {
    port = int.parse(arguments[2]);
  }
  HttpServer.bind(host, port).then((HttpServer server) {
    print('HTTP server started on http://$host:${server.port}/');
    server.listen(Conversation.onRequest, onError: Conversation.onError);
  }).catchError((e) {
    print("HttpServer.bind error: $e");
    exit(1);
  });
}
