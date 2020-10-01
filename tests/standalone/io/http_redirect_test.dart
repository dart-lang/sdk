// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

Future<HttpServer> setupServer() {
  final completer = new Completer<HttpServer>();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var handlers = new Map<String, Function>();
    addRequestHandler(
        String path, void handler(HttpRequest request, HttpResponse response)) {
      handlers[path] = handler;
    }

    server.listen((HttpRequest request) {
      if (handlers.containsKey(request.uri.path)) {
        handlers[request.uri.path]!(request, request.response);
      } else {
        request.listen((_) {}, onDone: () {
          request.response.statusCode = 404;
          request.response.close();
        });
      }
    });

    void addRedirectHandler(int number, int statusCode) {
      addRequestHandler("/$number",
          (HttpRequest request, HttpResponse response) {
        response.redirect(
            Uri.parse("http://127.0.0.1:${server.port}/${number + 1}"));
      });
    }

    // Setup simple redirect.
    addRequestHandler("/redirect",
        (HttpRequest request, HttpResponse response) {
      response.redirect(Uri.parse("http://127.0.0.1:${server.port}/location"),
          status: HttpStatus.movedPermanently);
    });
    addRequestHandler("/location",
        (HttpRequest request, HttpResponse response) {
      response.close();
    });

    // Setup redirects with relative url.
    addRequestHandler("/redirectUrl",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(HttpHeaders.locationHeader, "/some/relativeUrl");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    addRequestHandler("/some/redirectUrl",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(HttpHeaders.locationHeader, "relativeUrl");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    addRequestHandler("/some/relativeUrl",
        (HttpRequest request, HttpResponse response) {
      response.close();
    });

    addRequestHandler("/some/relativeToAbsolute",
        (HttpRequest request, HttpResponse response) {
      response.redirect(Uri.parse("xxx"), status: HttpStatus.seeOther);
    });

    addRequestHandler("/redirectUrl2",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(HttpHeaders.locationHeader, "location");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    addRequestHandler("/redirectUrl3",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(HttpHeaders.locationHeader, "./location");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    addRequestHandler("/redirectUrl4",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(HttpHeaders.locationHeader, "./a/b/../../location");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    addRequestHandler("/redirectUrl5",
        (HttpRequest request, HttpResponse response) {
      response.headers.set(
          HttpHeaders.locationHeader, "//127.0.0.1:${server.port}/location");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });

    // Setup redirect chain.
    int n = 1;
    addRedirectHandler(n++, HttpStatus.movedPermanently);
    addRedirectHandler(n++, HttpStatus.movedTemporarily);
    addRedirectHandler(n++, HttpStatus.seeOther);
    addRedirectHandler(n++, HttpStatus.temporaryRedirect);
    addRedirectHandler(n++, HttpStatus.permanentRedirect);
    for (int i = n; i < 10; i++) {
      addRedirectHandler(i, HttpStatus.movedPermanently);
    }

    // Setup redirect loop.
    addRequestHandler("/A", (HttpRequest request, HttpResponse response) {
      response.headers
          .set(HttpHeaders.locationHeader, "http://127.0.0.1:${server.port}/B");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });
    addRequestHandler("/B", (HttpRequest request, HttpResponse response) {
      response.headers
          .set(HttpHeaders.locationHeader, "http://127.0.0.1:${server.port}/A");
      response.statusCode = HttpStatus.movedTemporarily;
      response.close();
    });

    // Setup redirect checking headers.
    addRequestHandler("/src", (HttpRequest request, HttpResponse response) {
      Expect.equals("value", request.headers.value("X-Request-Header"));
      response.headers.set(
          HttpHeaders.locationHeader, "http://127.0.0.1:${server.port}/target");
      response.statusCode = HttpStatus.movedPermanently;
      response.close();
    });
    addRequestHandler("/target", (HttpRequest request, HttpResponse response) {
      Expect.equals("value", request.headers.value("X-Request-Header"));
      response.close();
    });

    // Setup redirect for 301 where POST should not redirect.
    addRequestHandler("/301src", (HttpRequest request, HttpResponse response) {
      Expect.equals("POST", request.method);
      request.listen((_) {}, onDone: () {
        response.headers.set(HttpHeaders.locationHeader,
            "http://127.0.0.1:${server.port}/301target");
        response.statusCode = HttpStatus.movedPermanently;
        response.close();
      });
    });
    addRequestHandler("/301target",
        (HttpRequest request, HttpResponse response) {
      Expect.fail("Redirect of POST should not happen");
    });

    // Setup redirect for 303 where POST should turn into GET.
    addRequestHandler("/303src", (HttpRequest request, HttpResponse response) {
      request.listen((_) {}, onDone: () {
        Expect.equals("POST", request.method);
        response.headers.set(HttpHeaders.locationHeader,
            "http://127.0.0.1:${server.port}/303target");
        response.statusCode = HttpStatus.seeOther;
        response.close();
      });
    });
    addRequestHandler("/303target",
        (HttpRequest request, HttpResponse response) {
      Expect.equals("GET", request.method);
      response.close();
    });

    // Setup redirect where we close the connection.
    addRequestHandler("/closing", (HttpRequest request, HttpResponse response) {
      response.headers
          .set(HttpHeaders.locationHeader, "http://127.0.0.1:${server.port}/");
      response.statusCode = HttpStatus.found;
      response.persistentConnection = false;
      response.close();
    });

    completer.complete(server);
  });
  return completer.future;
}

void checkRedirects(int redirectCount, HttpClientResponse response) {
  if (redirectCount < 2) {
    Expect.isTrue(response.redirects.isEmpty);
  } else {
    Expect.equals(redirectCount - 1, response.redirects.length);
    for (int i = 0; i < redirectCount - 2; i++) {
      Expect.equals(response.redirects[i].location.path, "/${i + 2}");
    }
  }
}

void testManualRedirect() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    int redirectCount = 0;
    handleResponse(HttpClientResponse response) {
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        redirectCount++;
        if (redirectCount < 10) {
          Expect.isTrue(response.isRedirect);
          checkRedirects(redirectCount, response);
          response.redirect().then(handleResponse);
        } else {
          Expect.equals(HttpStatus.notFound, response.statusCode);
          server.close();
          client.close();
        }
      });
    }

    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}/1"))
        .then((HttpClientRequest request) {
      request.followRedirects = false;
      return request.close();
    }).then(handleResponse);
  });
}

void testManualRedirectWithHeaders() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    int redirectCount = 0;

    handleResponse(HttpClientResponse response) {
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        redirectCount++;
        if (redirectCount < 2) {
          Expect.isTrue(response.isRedirect);
          response.redirect().then(handleResponse);
        } else {
          Expect.equals(HttpStatus.ok, response.statusCode);
          server.close();
          client.close();
        }
      });
    }

    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}/src"))
        .then((HttpClientRequest request) {
      request.followRedirects = false;
      request.headers.add("X-Request-Header", "value");
      return request.close();
    }).then(handleResponse);
  });
}

void testAutoRedirect() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}/redirect"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        Expect.equals(1, response.redirects.length);
        server.close();
        client.close();
      });
    });
  });
}

void testAutoRedirectWithHeaders() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}/src"))
        .then((HttpClientRequest request) {
      request.headers.add("X-Request-Header", "value");
      return request.close();
    }).then((HttpClientResponse response) {
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        Expect.equals(1, response.redirects.length);
        server.close();
        client.close();
      });
    });
  });
}

void testAutoRedirect301POST() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .postUrl(Uri.parse("http://127.0.0.1:${server.port}/301src"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      Expect.equals(HttpStatus.movedPermanently, response.statusCode);
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        Expect.equals(0, response.redirects.length);
        server.close();
        client.close();
      });
    });
  });
}

void testAutoRedirect303POST() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .postUrl(Uri.parse("http://127.0.0.1:${server.port}/303src"))
        .then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      Expect.equals(HttpStatus.ok, response.statusCode);
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        Expect.equals(1, response.redirects.length);
        server.close();
        client.close();
      });
    });
  });
}

void testAutoRedirectLimit() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    Future<HttpClientResponse?>.value(client
            .getUrl(Uri.parse("http://127.0.0.1:${server.port}/1"))
            .then((HttpClientRequest request) => request.close()))
        .catchError((error) {
      Expect.equals(5, error.redirects.length);
      server.close();
      client.close();
    }, test: (e) => e is RedirectException);
  });
}

void testRedirectLoop() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    int redirectCount = 0;
    Future<HttpClientResponse?>.value(client
            .getUrl(Uri.parse("http://127.0.0.1:${server.port}/A"))
            .then((HttpClientRequest request) => request.close()))
        .catchError((error) {
      Expect.equals(2, error.redirects.length);
      server.close();
      client.close();
    }, test: (e) => e is RedirectException);
  });
}

void testRedirectClosingConnection() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}/closing"))
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}, onDone: () {
        Expect.equals(1, response.redirects.length);
        server.close();
        client.close();
      });
    });
  });
}

void testRedirectRelativeUrl() {
  testPath(String path) {
    setupServer().then((server) {
      HttpClient client = new HttpClient();

      print(path);
      client
          .getUrl(Uri.parse("http://127.0.0.1:${server.port}$path"))
          .then((request) => request.close())
          .then((response) {
        response.listen((_) {}, onDone: () {
          Expect.equals(HttpStatus.ok, response.statusCode);
          Expect.equals(1, response.redirects.length);
          server.close();
          client.close();
        });
      });
    });
  }

  testPath("/redirectUrl");
  testPath("/some/redirectUrl");
  testPath("/redirectUrl2");
  testPath("/redirectUrl3");
  testPath("/redirectUrl4");
  testPath("/redirectUrl5");
}

void testRedirectRelativeToAbsolute() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    int redirectCount = 0;
    handleResponse(HttpClientResponse response) {
      response.listen((_) => Expect.fail("Response data not expected"),
          onDone: () {
        Expect.equals(HttpStatus.seeOther, response.statusCode);
        Expect.equals("xxx", response.headers["Location"]![0]);
        Expect.isTrue(response.isRedirect);
        server.close();
        client.close();
      });
    }

    client
        .getUrl(Uri.parse(
            "http://127.0.0.1:${server.port}/some/relativeToAbsolute"))
        .then((HttpClientRequest request) {
      request.followRedirects = false;
      return request.close();
    }).then(handleResponse);
  });
}

main() {
  testManualRedirect();
  testManualRedirectWithHeaders();
  testAutoRedirect();
  testAutoRedirectWithHeaders();
  testAutoRedirect301POST();
  testAutoRedirect303POST();
  testAutoRedirectLimit();
  testRedirectLoop();
  testRedirectClosingConnection();
  testRedirectRelativeUrl();
  testRedirectRelativeToAbsolute();
}
