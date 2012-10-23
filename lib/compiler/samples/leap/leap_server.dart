// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

class Conversation {
  HttpRequest request;
  HttpResponse response;

  static const String LEAP_LANDING_PAGE = 'samples/leap/index.html';

  static String landingPage = LEAP_LANDING_PAGE;

  Conversation(this.request, this.response);

  onClosed() {
    if (response.statusCode == HttpStatus.OK) return;
    print('Request for ${request.path} ${response.statusCode}');
  }

  done() {
    response.outputStream.close();
    onClosed();
  }

  notFound() {
    response.statusCode = HttpStatus.NOT_FOUND;
    done();
  }

  redirect(String location) {
    response.statusCode = HttpStatus.FOUND;
    response.headers.add(HttpHeaders.LOCATION, location);
    done();
  }

  handle() {
    String path = request.path;
    if (path == '/') return redirect('/$landingPage');
    if (path == '/favicon.ico') {
      path = '/pkg/dartdoc/static/favicon.ico';
    }
    if (path.contains('..') || path.contains('%')) return notFound();
    var f = new File("./$path");
    f.exists().then((bool exists) {
      if (!exists) return notFound();
      if (path.endsWith('.dart')) {
        response.headers.add(HttpHeaders.CONTENT_TYPE, "application/dart");
      } else if (path.endsWith('.ico')) {
        response.headers.add(HttpHeaders.CONTENT_TYPE, "image/x-icon");
      }
      f.openInputStream().pipe(response.outputStream);
      onClosed();
    });
  }

  static onRequest(HttpRequest request, HttpResponse response) {
    new Conversation(request, response).handle();
  }
}

main() {
  List<String> arguments = new Options().arguments;
  if (arguments.length > 0) {
    Conversation.landingPage = arguments[0];
  }
  var server = new HttpServer();
  var host = '127.0.0.1';
  var port = 8080;
  server.listen(host, port);
  print('HTTP server started on http://$host:$port/');
  server.defaultRequestHandler = Conversation.onRequest;
}
