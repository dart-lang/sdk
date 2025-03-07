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

  Future<Server> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4.address, 0);
    server.listen((request) {
      final response = request.response;

      // WARNING: this authenticate header is malformed because of missing
      // commas between the arguments
      if (request.uri.path == "/malformedAuthenticate") {
        response.statusCode = HttpStatus.unauthorized;
        response.headers.set(HttpHeaders.wwwAuthenticateHeader, "Bearer realm=\"realm\" error=\"invalid_token\"");
        response.close();
        return;
      }

      // NOTE: see RFC6750 section 3 regarding the authenticate response header
      // field
      // https://www.rfc-editor.org/rfc/rfc6750.html#section-3
      if (request.headers[HttpHeaders.authorizationHeader] != null) {
        final token = base64.encode(utf8.encode(request.uri.path.substring(1)));
        Expect.equals(
            1, request.headers[HttpHeaders.authorizationHeader]!.length);
        final authorizationHeaderParts =
            request.headers[HttpHeaders.authorizationHeader]![0].split(" ");
        Expect.equals("Bearer", authorizationHeaderParts[0]);
        if (token != authorizationHeaderParts[1]) {
          response.statusCode = HttpStatus.unauthorized;
          response.headers.set(HttpHeaders.wwwAuthenticateHeader,
              "Bearer realm=\"realm\", error=\"invalid_token\"");
        }
      } else {
        response.statusCode = HttpStatus.unauthorized;
        response.headers
            .set(HttpHeaders.wwwAuthenticateHeader, "Bearer realm=\"realm\"");
      }
      response.close();
    });
    return this;
  }

  void shutdown() {
    server.close();
  }

  String get host => server.address.address;

  int get port => server.port;
}

void testValidBearerTokens() {
  HttpClientBearerCredentials("977ce44bc56dc5000c9d2c329e682547");
  HttpClientBearerCredentials("dGVzdHRlc3R0ZXN0dGVzdA==");
  HttpClientBearerCredentials("dGVzdHRl_3R0ZXN-dGVzdA==");
  HttpClientBearerCredentials("dGVzdHRl/3R0ZXN+dGVzdA==");
}

void testInvalidBearerTokens() {
  Expect.throws(() => HttpClientBearerCredentials("§(&%)"));
  Expect.throws(() => HttpClientBearerCredentials("áéîöü"));
  Expect.throws(() => HttpClientBearerCredentials("あいうえお"));
  Expect.throws(() => HttpClientBearerCredentials("     "));
}

void testBearerWithoutCredentials() async {
  final server = await Server().start();
  final client = HttpClient();

  Future makeRequest(Uri url) async {
    final request = await client.getUrl(url);
    final response = await request.close();
    Expect.equals(HttpStatus.unauthorized, response.statusCode);
    return response.drain();
  }

  await Future.wait([
    for (int i = 0; i < 5; i++) ...[
      makeRequest(Uri.parse("http://${server.host}:${server.port}/test$i")),
    ],
  ]);

  server.shutdown();
  client.close();
}

void testBearerWithCredentials() async {
  final server = await Server().start();
  final client = HttpClient();

  Future makeRequest(Uri url) async {
    final request = await client.getUrl(url);
    final response = await request.close();
    Expect.equals(HttpStatus.ok, response.statusCode);
    return response.drain();
  }

  for (int i = 0; i < 5; i++) {
    final token = base64.encode(utf8.encode("test$i"));
    client.addCredentials(
        Uri.parse("http://${server.host}:${server.port}/test$i"),
        "realm",
        HttpClientBearerCredentials(token));
  }

  await Future.wait([
    for (int i = 0; i < 5; i++) ...[
      makeRequest(Uri.parse("http://${server.host}:${server.port}/test$i")),
    ],
  ]);

  server.shutdown();
  client.close();
}

void testBearerWithAuthenticateCallback() async {
  final server = await Server().start();
  final client = HttpClient();

  client.authenticate = (url, scheme, realm) async {
    Expect.equals("Bearer", scheme);
    Expect.equals("realm", realm);
    String token = base64.encode(utf8.encode(url.path.substring(1)));
    await Future.delayed(const Duration(milliseconds: 10));
    client.addCredentials(url, realm!, new HttpClientBearerCredentials(token));
    return true;
  };

  Future makeRequest(Uri url) async {
    final request = await client.getUrl(url);
    final response = await request.close();
    Expect.equals(HttpStatus.ok, response.statusCode);
    return response.drain();
  }

  await Future.wait([
    for (int i = 0; i < 5; i++) ...[
      makeRequest(Uri.parse("http://${server.host}:${server.port}/test$i")),
    ],
  ]);

  server.shutdown();
  client.close();
}

void testMalformedAuthenticateHeaderWithoutCredentials() async {
  final server = await Server().start();
  final client = HttpClient();
  final uri =
      Uri.parse("http://${server.host}:${server.port}/malformedAuthenticate");

  // the request should resolve normally if no authentication is configured
  final request = await client.getUrl(uri);
  final response = await request.close();

  server.shutdown();
  client.close();
}

void testMalformedAuthenticateHeaderWithCredentials() async {
  final server = await Server().start();
  final client = HttpClient();
  final uri =
      Uri.parse("http://${server.host}:${server.port}/malformedAuthenticate");
  final token = base64.encode(utf8.encode("test"));

  // the request should throw an exception if credentials have been added
  client.addCredentials(uri, "realm", HttpClientBearerCredentials(token));
  await asyncExpectThrows<HttpException>(Future(() async {
    final request = await client.getUrl(uri);
    final response = await request.close();
  }));

  server.shutdown();
  client.close();
}

void testMalformedAuthenticateHeaderWithAuthenticateCallback() async {
  final server = await Server().start();
  final client = HttpClient();
  final uri =
      Uri.parse("http://${server.host}:${server.port}/malformedAuthenticate");

  // the request should throw an exception if the authenticate handler is set
  client.authenticate = (url, scheme, realm) async => false;
  await asyncExpectThrows<HttpException>(Future(() async {
    final request = await client.getUrl(uri);
    final response = await request.close();
  }));

  server.shutdown();
  client.close();
}

void testLocalServerBearer() async {
  final client = HttpClient();

  client.authenticate = (url, scheme, realm) async {
    final token = base64.encode(utf8.encode("test"));
    client.addCredentials(Uri.parse("http://127.0.0.1/bearer"), "test",
        HttpClientBearerCredentials(token));
    return true;
  };

  final request =
      await client.getUrl(Uri.parse("http://127.0.0.1/bearer/test"));
  final response = await request.close();
  Expect.equals(HttpStatus.ok, response.statusCode);
  await response.drain();

  client.close();
}

main() {
  testValidBearerTokens();
  testInvalidBearerTokens();
  testBearerWithoutCredentials();
  testBearerWithCredentials();
  testBearerWithAuthenticateCallback();
  testMalformedAuthenticateHeaderWithoutCredentials();
  testMalformedAuthenticateHeaderWithCredentials();
  testMalformedAuthenticateHeaderWithAuthenticateCallback();
  // These tests are not normally run. They can be used for locally
  // testing with another web server (e.g. Apache).
  //testLocalServerBearer();
}
