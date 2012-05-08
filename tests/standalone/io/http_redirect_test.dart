// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:io");
#import("dart:uri");

HttpServer setupServer() {
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, 5);

  void addRedirectHandler(int number, int statusCode) {
    server.addRequestHandler(
       (HttpRequest request) => request.path == "/$number",
       (HttpRequest request, HttpResponse response) {
       response.headers.set(HttpHeaders.LOCATION,
                            "http://127.0.0.1:${server.port}/${number + 1}");
       response.statusCode = statusCode;
       response.outputStream.close();
     });
  }

  // Setup redirect chain.
  int n = 1;
  addRedirectHandler(n++, HttpStatus.MOVED_PERMANENTLY);
  addRedirectHandler(n++, HttpStatus.MOVED_TEMPORARILY);
  addRedirectHandler(n++, HttpStatus.SEE_OTHER);
  addRedirectHandler(n++, HttpStatus.TEMPORARY_REDIRECT);
  for (int i = n; i < 10; i++) {
    addRedirectHandler(i, HttpStatus.MOVED_PERMANENTLY);
  }

  // Setup redirect loop.
  server.addRequestHandler(
     (HttpRequest request) => request.path == "/A",
     (HttpRequest request, HttpResponse response) {
       response.headers.set(HttpHeaders.LOCATION,
                            "http://127.0.0.1:${server.port}/B");
       response.statusCode = HttpStatus.MOVED_PERMANENTLY;
       response.outputStream.close();
     }
  );
  server.addRequestHandler(
     (HttpRequest request) => request.path == "/B",
     (HttpRequest request, HttpResponse response) {
       response.headers.set(HttpHeaders.LOCATION,
                            "http://127.0.0.1:${server.port}/A");
       response.statusCode = HttpStatus.MOVED_TEMPORARILY;
       response.outputStream.close();
     }
  );

  return server;
}

void checkRedirects(int redirectCount, HttpClientConnection conn) {
  if (redirectCount < 2) {
    Expect.isNull(conn.redirects);
  } else {
    Expect.equals(redirectCount - 1, conn.redirects.length);
    for (int i = 0; i < redirectCount - 2; i++) {
      Expect.equals(conn.redirects[i].location.path, "/${i + 2}");
    }
  }
}

void testManualRedirect() {
  HttpServer server = setupServer();
  HttpClient client = new HttpClient();

  int redirectCount = 0;
  HttpClientConnection conn =
     client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/1"));
  conn.followRedirects = false;
  conn.onResponse = (HttpClientResponse response) {
    response.inputStream.onData = () => response.inputStream.read();
    response.inputStream.onClosed = () {
      redirectCount++;
      if (redirectCount < 10) {
        Expect.isTrue(response.isRedirect);
        checkRedirects(redirectCount, conn);
        conn.redirect();
      } else {
        Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
        server.close();
        client.shutdown();
      }
    };
  };
}

void testAutoRedirect() {
  HttpServer server = setupServer();
  HttpClient client = new HttpClient();

  HttpClientConnection conn =
      client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/1"));
  conn.onResponse = (HttpClientResponse response) {
    response.inputStream.onData = () => Expect.fail("Response not expected");
    response.inputStream.onClosed = () => Expect.fail("Response not expected");
  };
  conn.onError = (e) {
    Expect.isTrue(e is RedirectLimitExceeded);
    Expect.equals(5, e.redirects.length);
    server.close();
    client.shutdown();
  };
}

void testRedirectLoop() {
  HttpServer server = setupServer();
  HttpClient client = new HttpClient();

  int redirectCount = 0;
  HttpClientConnection conn =
      client.getUrl(new Uri.fromString("http://127.0.0.1:${server.port}/A"));
  conn.onResponse = (HttpClientResponse response) {
    response.inputStream.onData = () => Expect.fail("Response not expected");
    response.inputStream.onClosed = () => Expect.fail("Response not expected");
  };
  conn.onError = (e) {
    Expect.isTrue(e is RedirectLoop);
    Expect.equals(2, e.redirects.length);
    server.close();
    client.shutdown();
  };
}

main() {
  testManualRedirect();
  testAutoRedirect();
  testRedirectLoop();
}
