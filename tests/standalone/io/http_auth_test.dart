// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

class Server {
  late HttpServer server;
  bool passwordChanged = false;

  Future<Server> start() {
    asyncStart();
    var completer = new Completer<Server>();
    HttpServer.bind("127.0.0.1", 0).then((s) {
      server = s;
      server.listen((HttpRequest request) {
        var response = request.response;
        if (request.uri.path == "/passwdchg") {
          passwordChanged = true;
          response.close();
          return;
        }

        if (request.uri.path == "/malformedAuthenticate") {
          response.statusCode = HttpStatus.unauthorized;
          response.headers.set(
            HttpHeaders.wwwAuthenticateHeader,
            'Basic malformed header no commas',
          );
          response.close();
          return;
        }

        String username;
        String password;
        if (request.uri.path == "/") {
          username = "username";
          password = "password";
        } else {
          username = request.uri.path.substring(1, 6);
          password = request.uri.path.substring(1, 6);
        }
        if (passwordChanged) password = "${password}1";
        if (request.headers[HttpHeaders.authorizationHeader] != null) {
          Expect.equals(
            1,
            request.headers[HttpHeaders.authorizationHeader]!.length,
          );
          String authorization =
              request.headers[HttpHeaders.authorizationHeader]![0];
          List<String> tokens = authorization.split(" ");
          Expect.equals("Basic", tokens[0]);
          String auth = base64.encode(utf8.encode("$username:$password"));
          if (passwordChanged && auth != tokens[1]) {
            response.statusCode = HttpStatus.unauthorized;
            response.headers.set(
              HttpHeaders.wwwAuthenticateHeader,
              "Basic, realm=realm",
            );
          } else {
            Expect.equals(auth, tokens[1]);
          }
        } else {
          response.statusCode = HttpStatus.unauthorized;
          response.headers.set(
            HttpHeaders.wwwAuthenticateHeader,
            "Basic, realm=realm",
          );
        }
        response.close();
      });
      completer.complete(this);
    });
    return completer.future;
  }

  void shutdown() {
    server.close().then((_) {
      asyncEnd();
    });
  }

  int get port => server.port;
}

Future<Server> setupServer() {
  return new Server().start();
}

void testUrlUserInfo() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    client
        .getUrl(Uri.parse("http://username:password@127.0.0.1:${server.port}/"))
        .then((request) => request.close())
        .then((HttpClientResponse response) {
          response.listen(
            (_) {},
            onDone: () {
              server.shutdown();
              client.close();
            },
          );
        });
  });
}

void testBasicNoCredentials() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    Future makeRequest(Uri url) {
      return client
          .getUrl(url)
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) {
            Expect.equals(HttpStatus.unauthorized, response.statusCode);
            return response.fold(null, (x, y) {});
          });
    }

    var futures = <Future>[];
    for (int i = 0; i < 5; i++) {
      futures.add(
        makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i")),
      );
      futures.add(
        makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i/xxx")),
      );
    }
    Future.wait(futures).then((_) {
      server.shutdown();
      client.close();
    });
  });
}

void testBasicCredentials() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();

    Future makeRequest(Uri url) {
      return client
          .getUrl(url)
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) {
            Expect.equals(HttpStatus.ok, response.statusCode);
            return response.fold(null, (x, y) {});
          });
    }

    for (int i = 0; i < 5; i++) {
      client.addCredentials(
        Uri.parse("http://127.0.0.1:${server.port}/test$i"),
        "realm",
        new HttpClientBasicCredentials("test$i", "test$i"),
      );
    }

    var futures = <Future>[];
    for (int i = 0; i < 5; i++) {
      futures.add(
        makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i")),
      );
      futures.add(
        makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i/xxx")),
      );
    }
    Future.wait(futures).then((_) {
      server.shutdown();
      client.close();
    });
  });
}

void testBasicAuthenticateCallback() {
  setupServer().then((server) {
    HttpClient client = new HttpClient();
    bool passwordChanged = false;

    client.authenticate = (Uri url, String scheme, String? realm) {
      Expect.equals("Basic", scheme);
      Expect.equals("realm", realm);
      String username = url.path.substring(1, 6);
      String password = url.path.substring(1, 6);
      if (passwordChanged) password = "${password}1";
      final completer = new Completer<bool>();
      new Timer(const Duration(milliseconds: 10), () {
        client.addCredentials(
          url,
          realm!,
          new HttpClientBasicCredentials(username, password),
        );
        completer.complete(true);
      });
      return completer.future;
    };

    Future makeRequest(Uri url) {
      return client
          .getUrl(url)
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) {
            Expect.equals(HttpStatus.ok, response.statusCode);
            return response.fold(null, (x, y) {});
          });
    }

    List<Future> makeRequests() {
      var futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(
          makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i")),
        );
        futures.add(
          makeRequest(Uri.parse("http://127.0.0.1:${server.port}/test$i/xxx")),
        );
      }
      return futures;
    }

    Future.wait(makeRequests()).then((_) {
      makeRequest(Uri.parse("http://127.0.0.1:${server.port}/passwdchg")).then((
        _,
      ) {
        passwordChanged = true;
        Future.wait(makeRequests()).then((_) {
          server.shutdown();
          client.close();
        });
      });
    });
  });
}

void testMalformedAuthenticateHeaderNoAuthHandler() {
  setupServer().then((server) async {
    HttpClient client = new HttpClient();
    final uri = Uri.parse(
      'http://${InternetAddress.loopbackIPv4.address}:${server.port}/malformedAuthenticate',
    );

    // Request should resolve normally if no authentication is configured
    await client.getUrl(uri).then((request) => request.close());

    server.shutdown();
    client.close();
  });
}

void testMalformedAuthenticateHeaderWithAuthHandler() {
  setupServer().then((server) async {
    HttpClient client = new HttpClient();
    final uri = Uri.parse(
      'http://${InternetAddress.loopbackIPv4.address}:${server.port}/malformedAuthenticate',
    );

    // Request should throw an exception if the authenticate handler is set
    client.authenticate = (url, scheme, realm) async => false;
    await asyncExpectThrows<HttpException>(
      client.getUrl(uri).then((request) => request.close()),
    );

    server.shutdown();
    client.close();
  });
}

void testMalformedAuthenticateHeaderWithCredentials() {
  setupServer().then((server) async {
    HttpClient client = new HttpClient();
    final uri = Uri.parse(
      'http://${InternetAddress.loopbackIPv4.address}:${server.port}/malformedAuthenticate',
    );

    // Request should throw an exception if credentials have been added
    client.addCredentials(
      uri,
      'realm',
      HttpClientBasicCredentials('dart', 'password'),
    );
    await asyncExpectThrows<HttpException>(
      client.getUrl(uri).then((request) => request.close()),
    );

    server.shutdown();
    client.close();
  });
}

void testLocalServerBasic() {
  HttpClient client = new HttpClient();

  client.authenticate = (Uri url, String scheme, String? realm) {
    client.addCredentials(
      Uri.parse("http://127.0.0.1/basic"),
      "test",
      new HttpClientBasicCredentials("test", "test"),
    );
    return new Future.value(true);
  };

  client
      .getUrl(Uri.parse("http://127.0.0.1/basic/test"))
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        Expect.equals(HttpStatus.ok, response.statusCode);
        response.drain().then((_) {
          client.close();
        });
      });
}

void testLocalServerBearer() async {
  final client = HttpClient();

  client.authenticate = (url, scheme, realm) async {
    final token = base64.encode(utf8.encode("test"));
    client.addCredentials(
      Uri.parse("http://127.0.0.1/bearer"),
      "test",
      HttpClientBearerCredentials(token),
    );
    return true;
  };

  final request = await client.getUrl(
    Uri.parse("http://127.0.0.1/bearer/test"),
  );
  final response = await request.close();
  Expect.equals(HttpStatus.ok, response.statusCode);
  await response.drain();

  client.close();
}

void testLocalServerDigest() {
  HttpClient client = new HttpClient();

  client.authenticate = (Uri url, String scheme, String? realm) {
    print("url: $url, scheme: $scheme, realm: $realm");
    client.addCredentials(
      Uri.parse("http://127.0.0.1/digest"),
      "test",
      new HttpClientDigestCredentials("test", "test"),
    );
    return new Future.value(true);
  };

  client
      .getUrl(Uri.parse("http://127.0.0.1/digest/test"))
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        Expect.equals(HttpStatus.ok, response.statusCode);
        response.drain().then((_) {
          client.close();
        });
      });
}

main() {
  asyncStart();

  testUrlUserInfo();
  testBasicNoCredentials();
  testBasicCredentials();
  testBasicAuthenticateCallback();
  testMalformedAuthenticateHeaderNoAuthHandler();
  testMalformedAuthenticateHeaderWithAuthHandler();
  testMalformedAuthenticateHeaderWithCredentials();
  // These teste are not normally run. They can be used for locally
  // testing with another web server (e.g. Apache).
  //testLocalServerBasic();
  //testLocalServerBearer();
  //testLocalServerDigest();

  asyncEnd();
}
