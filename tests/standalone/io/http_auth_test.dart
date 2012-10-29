// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:isolate");
#import("dart:crypto");
#import("dart:io");
#import("dart:uri");
#import("dart:utf");

class Server {
  HttpServer server;
  bool passwordChanged = false;

  Server() : server = new HttpServer();

  void start() {
    server.listen("127.0.0.1", 0);
    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
          String username;
          String password;
          if (request.path == "/") {
            username = "username";
            password = "password";
          } else {
            username = request.path.substring(1, 6);
            password = request.path.substring(1, 6);
          }
          if (passwordChanged) password = "${password}1";
          if (request.headers[HttpHeaders.AUTHORIZATION] != null) {
            Expect.equals(1, request.headers[HttpHeaders.AUTHORIZATION].length);
            String authorization =
              request.headers[HttpHeaders.AUTHORIZATION][0];
            List<String> tokens = authorization.split(" ");
            Expect.equals("Basic", tokens[0]);
            String auth =
                CryptoUtils.bytesToBase64(encodeUtf8("$username:$password"));
            if (passwordChanged && auth != tokens[1]) {
              response.statusCode = HttpStatus.UNAUTHORIZED;
              response.headers.set(HttpHeaders.WWW_AUTHENTICATE,
                                   "Basic, realm=realm");
            } else {
              Expect.equals(auth, tokens[1]);
            }
          } else {
            response.statusCode = HttpStatus.UNAUTHORIZED;
            response.headers.set(HttpHeaders.WWW_AUTHENTICATE,
                                 "Basic, realm=realm");
          }
          response.outputStream.close();
        };
    server.addRequestHandler(
        (HttpRequest request) => request.path == "/passwdchg",
        (HttpRequest request, HttpResponse response) {
          passwordChanged = true;
          response.outputStream.close();
        });
  }

  void shutdown() {
    server.close();
  }

  int get port => server.port;
}

Server setupServer() {
  Server server = new Server();
  server.start();
  return server;
}

void testUrlUserInfo() {
  Server server = setupServer();
  HttpClient client = new HttpClient();

  HttpClientConnection conn =
      client.getUrl(
          new Uri.fromString(
              "http://username:password@127.0.0.1:${server.port}/"));
  conn.onResponse = (HttpClientResponse response) {
    server.shutdown();
    client.shutdown();
  };
}

void testBasicNoCredentials() {
  Server server = setupServer();
  HttpClient client = new HttpClient();

  Future makeRequest(Uri url) {
    Completer completer = new Completer();
    HttpClientConnection conn = client.getUrl(url);
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.UNAUTHORIZED, response.statusCode);
      completer.complete(null);
    };
    return completer.future;
  }

  var futures = [];
  for (int i = 0; i < 5; i++) {
    futures.add(
        makeRequest(
            new Uri.fromString("http://127.0.0.1:${server.port}/test$i")));
    futures.add(
        makeRequest(
            new Uri.fromString("http://127.0.0.1:${server.port}/test$i/xxx")));
  }
  Futures.wait(futures).then((_) {
    server.shutdown();
    client.shutdown();
  });
}

void testBasicCredentials() {
  Server server = setupServer();
  HttpClient client = new HttpClient();

  Future makeRequest(Uri url) {
    Completer completer = new Completer();
    HttpClientConnection conn = client.getUrl(url);
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      completer.complete(null);
    };
    return completer.future;
  }

  for (int i = 0; i < 5; i++) {
    client.addCredentials(
        new Uri.fromString("http://127.0.0.1:${server.port}/test$i"),
        "realm",
        new HttpClientBasicCredentials("test$i", "test$i"));
  }

  var futures = [];
  for (int i = 0; i < 5; i++) {
    futures.add(
        makeRequest(
            new Uri.fromString("http://127.0.0.1:${server.port}/test$i")));
    futures.add(
        makeRequest(
            new Uri.fromString("http://127.0.0.1:${server.port}/test$i/xxx")));
  }
  Futures.wait(futures).then((_) {
    server.shutdown();
    client.shutdown();
  });
}

void testBasicAuthenticateCallback() {
  Server server = setupServer();
  HttpClient client = new HttpClient();
  bool passwordChanged = false;

  client.authenticate = (Uri url, String scheme, String realm) {
    Expect.equals("Basic", scheme);
    Expect.equals("realm", realm);
    String username = url.path.substring(1, 6);
    String password = url.path.substring(1, 6);
    if (passwordChanged) password = "${password}1";
    Completer completer = new Completer();
    new Timer(10, (_) {
      client.addCredentials(
          url, realm, new HttpClientBasicCredentials(username, password));
      completer.complete(true);
    });
    return completer.future;
  };

  Future makeRequest(Uri url) {
    Completer completer = new Completer();
    HttpClientConnection conn = client.getUrl(url);
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      completer.complete(null);
    };
    return completer.future;
  }

  List<Future> makeRequests() {
    var futures = [];
    for (int i = 0; i < 5; i++) {
      futures.add(
          makeRequest(
              new Uri.fromString("http://127.0.0.1:${server.port}/test$i")));
      futures.add(
          makeRequest(
              new Uri.fromString(
                  "http://127.0.0.1:${server.port}/test$i/xxx")));
    }
    return futures;
  }

  Futures.wait(makeRequests()).then((_) {
    makeRequest(
        new Uri.fromString(
            "http://127.0.0.1:${server.port}/passwdchg")).then((_) {
      passwordChanged = true;
      Futures.wait(makeRequests()).then((_) {
        server.shutdown();
        client.shutdown();
      });
    });
  });
}

void testLocalServerBasic() {
  HttpClient client = new HttpClient();

  client.authenticate = (Uri url, String scheme, String realm) {
    client.addCredentials(
        new Uri.fromString("http://127.0.0.1/basic"),
        "test",
        new HttpClientBasicCredentials("test", "test"));
    return new Future.immediate(true);
  };

  HttpClientConnection conn =
      client.getUrl(new Uri.fromString("http://127.0.0.1/basic/test"));
  conn.onResponse = (HttpClientResponse response) {
    Expect.equals(HttpStatus.OK, response.statusCode);
    response.inputStream.onData = () => response.inputStream.read();
    response.inputStream.onClosed = () {
      client.shutdown();
    };
  };
}

void testLocalServerDigest() {
  HttpClient client = new HttpClient();

  client.authenticate = (Uri url, String scheme, String realm) {
    print("url: $url, scheme: $scheme, realm: $realm");
    client.addCredentials(
        new Uri.fromString("http://127.0.0.1/digest"),
        "test",
        new HttpClientDigestCredentials("test", "test"));
    return new Future.immediate(true);
  };

  HttpClientConnection conn =
      client.getUrl(new Uri.fromString("http://127.0.0.1/digest/test"));
  conn.onResponse = (HttpClientResponse response) {
    Expect.equals(HttpStatus.OK, response.statusCode);
    response.inputStream.onData = () => response.inputStream.read();
    response.inputStream.onClosed = () {
      client.shutdown();
    };
  };
}

main() {
  testUrlUserInfo();
  testBasicNoCredentials();
  testBasicCredentials();
  testBasicAuthenticateCallback();
  // These teste are not normally run. They can be used for locally
  // testing with another web server (e.g. Apache).
  //testLocalServerBasic();
  //testLocalServerDigest();
}
