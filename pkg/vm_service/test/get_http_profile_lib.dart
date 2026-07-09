// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'common/test_helper.dart';

final rng = Random();

// Enable to test redirects.
const shouldTestRedirects = false;

const maxRequestDelayMs = 3000;
const maxResponseDelayMs = 500;
const serverShutdownDelayMs = 2000;

void randomlyAddCookie(HttpResponse response) {
  if (rng.nextInt(3) == 0) {
    response.cookies.add(Cookie('Cookie-Monster', 'Me-want-cookie!'));
  }
}

Future<bool> randomlyRedirect(HttpServer server, HttpResponse response) async {
  if (shouldTestRedirects && rng.nextInt(5) == 0) {
    final redirectUri = Uri(host: 'www.google.com', port: 80);
    await response.redirect(redirectUri);
    return true;
  }
  return false;
}

// Execute HTTP requests with random delays so requests have some overlap. This
// way we can be certain that timeline events are matching up properly even when
// connections are interrupted or can't be established.
Future<void> executeWithRandomDelay(Function f) =>
    Future<void>.delayed(Duration(milliseconds: rng.nextInt(maxRequestDelayMs)))
        .then((_) async {
      try {
        await f();
      } on HttpException catch (_) {
      } on SocketException catch (_) {
      } on StateError catch (_) {
      } on OSError catch (_) {}
    });

Uri randomlyAddRequestParams(Uri uri) {
  const possiblePathSegments = <String>['foo', 'bar', 'baz', 'foobar'];
  final segmentSubset =
      possiblePathSegments.sublist(0, rng.nextInt(possiblePathSegments.length));
  uri = uri.replace(pathSegments: segmentSubset);
  if (rng.nextInt(3) == 0) {
    uri = uri.replace(
      queryParameters: {
        'foo': 'bar',
        'year': '2019',
      },
    );
  }
  return uri;
}

Future<HttpServer> startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    // Randomly delay starting the response.
    await Future.delayed(
      Duration(milliseconds: rng.nextInt(maxResponseDelayMs) + 1),
    );
    final response = request.response;
    response.write(request.method);
    randomlyAddCookie(response);
    if (await randomlyRedirect(server, response)) {
      // Redirect calls close() on the response.
      return;
    }
    // Randomly delay finishing the response.
    await Future.delayed(
      Duration(milliseconds: rng.nextInt(maxResponseDelayMs) + 1),
    );
    await response.close();
  });
  return server;
}

Future<void> testMain() async {
  final server = await startServer();
  HttpClient.enableTimelineLogging = true;
  final client = HttpClient();
  final requests = <Future>[];
  final address =
      Uri(scheme: 'http', host: server.address.host, port: server.port);

  // HTTP DELETE
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.deleteUrl(randomlyAddRequestParams(address));
      final string = 'DELETE $address';
      r.headers.add(HttpHeaders.contentLengthHeader, string.length);
      r.write(string);
      final response = await r.close();
      response.listen((_) {});
    });
    requests.add(future);
  }

  // HTTP GET
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.getUrl(randomlyAddRequestParams(address));
      r.headers.add('cookie-eater', 'Cookie-Monster !');
      final response = await r.close();
      await response.drain();
    });
    requests.add(future);
  }
  // HTTP HEAD
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.headUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP CONNECT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r =
          await client.openUrl('connect', randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PATCH
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.patchUrl(randomlyAddRequestParams(address));
      final response = await r.close();
      response.listen(null);
    });
    requests.add(future);
  }

  // HTTP POST
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.postUrl(randomlyAddRequestParams(address));
      r.add(Uint8List.fromList([0, 1, 2]));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PUT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.putUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // Purposefully close server before some connections can be made to ensure
  // that refused / interrupted connections correctly create finish timeline
  // events.
  await Future.delayed(Duration(milliseconds: serverShutdownDelayMs));
  await server.close();

  // Ensure all requests complete before finishing.
  await Future.wait(requests);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: testMain);
}
