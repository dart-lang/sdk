// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/web/serve/handler.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_utils.dart';

/// Tests the HTTP handler's routing, caching, and security rules without a
/// network.
void main() {
  late Handler handler;
  late String bootstrap;

  setUp(() async {
    final dartSources = await createServeProject();
    bootstrap = 'bootstrap';
    handler = createAppHandler(
      lookupFile: (path) => switch (path) {
        'main.dart.js' => utf8.encode(bootstrap),
        'web/main.dart.lib.js.map' => utf8.encode('{}'),
        'ddc_module_loader.js' => utf8.encode('loader'),
        'dart_stack_trace_mapper.js' => utf8.encode('mapper'),
        'dart_sdk.js' => utf8.encode('sdk-bytes'),
        'dart_sdk.js.map' => utf8.encode('{"version":3}'),
        _ => null,
      },
      webDirectory: dartSources.webDirectory,
      dartSources: dartSources,
    );
  });

  Future<Response> send(
    String path, {
    String method = 'GET',
    String? host = 'localhost:8080',
    Map<String, Object>? headers,
    Handler? target,
  }) async {
    final mergedHeaders = <String, Object>{
      HttpHeaders.hostHeader: ?host,
      ...?headers,
    };
    return await (target ?? handler)(
      Request(
        method,
        Uri.parse('http://localhost:8080$path'),
        headers: mergedHeaders,
      ),
    );
  }

  test('serves generated JavaScript with an ETag and no-cache', () async {
    final response = await send('/main.dart.js');
    expect(response.statusCode, HttpStatus.ok);
    expect(await response.readAsString(), 'bootstrap');
    final etag = response.headers[HttpHeaders.etagHeader]!;
    expect(response.headers, {
      HttpHeaders.contentTypeHeader: 'application/javascript; charset=utf-8',
      HttpHeaders.cacheControlHeader: 'no-cache',
      HttpHeaders.etagHeader: etag,
      HttpHeaders.contentLengthHeader: '9',
      'cross-origin-resource-policy': 'same-site',
    });

    final head = await send('/main.dart.js', method: 'HEAD');
    expect(head.statusCode, HttpStatus.ok);
    expect(head.headers[HttpHeaders.contentLengthHeader], '9');
    expect(head.headers[HttpHeaders.etagHeader], etag);
    expect(await head.readAsString(), isEmpty);

    final revalidated = await send(
      '/main.dart.js',
      headers: {HttpHeaders.ifNoneMatchHeader: etag},
    );
    expect(revalidated.statusCode, HttpStatus.notModified);
    expect(await revalidated.readAsString(), isEmpty);

    // A recompile replaces the file, so the browser's copy is out of date.
    bootstrap = 'recompiled';
    final recompiled = await send(
      '/main.dart.js',
      headers: {HttpHeaders.ifNoneMatchHeader: etag},
    );
    expect(recompiled.statusCode, HttpStatus.ok);
    expect(await recompiled.readAsString(), 'recompiled');
    expect(recompiled.headers[HttpHeaders.etagHeader], isNot(etag));
  });

  test('serves generated source maps as JSON', () async {
    final response = await send('/web/main.dart.lib.js.map');
    expect(
      response.headers[HttpHeaders.contentTypeHeader],
      'application/json; charset=utf-8',
    );
    expect(response.headers[HttpHeaders.cacheControlHeader], 'no-cache');
    expect(response.headers[HttpHeaders.etagHeader], isNotNull);
  });

  test(
    'caches immutable SDK files with strong ETag and Cache-Control: no-cache',
    () async {
      for (final sdkPath in [
        '/ddc_module_loader.js',
        '/dart_stack_trace_mapper.js',
        '/dart_sdk.js',
        '/dart_sdk.js.map',
      ]) {
        final first = await send(sdkPath);
        expect(first.statusCode, HttpStatus.ok, reason: sdkPath);
        expect(first.headers[HttpHeaders.cacheControlHeader], 'no-cache');
        final etag = first.headers[HttpHeaders.etagHeader];
        expect(etag, isNotNull, reason: sdkPath);
        expect(etag, startsWith('"'));
        expect(etag, isNot(startsWith('W/')));
      }

      final initial = await send('/dart_sdk.js');
      final etag = initial.headers[HttpHeaders.etagHeader]!;
      expect(await initial.readAsString(), 'sdk-bytes');

      for (final ifNoneMatch in [etag, '"other", $etag', '*', 'W/$etag']) {
        final notModified = await send(
          '/dart_sdk.js',
          headers: {HttpHeaders.ifNoneMatchHeader: ifNoneMatch},
        );
        expect(
          notModified.statusCode,
          HttpStatus.notModified,
          reason: ifNoneMatch,
        );
        expect(notModified.headers[HttpHeaders.etagHeader], etag);
        expect(notModified.headers[HttpHeaders.cacheControlHeader], 'no-cache');
        expect(
          notModified.headers['cross-origin-resource-policy'],
          'same-site',
        );
        expect(await notModified.readAsString(), isEmpty);
      }

      final stale = await send(
        '/dart_sdk.js',
        headers: {HttpHeaders.ifNoneMatchHeader: '"stale-etag"'},
      );
      expect(stale.statusCode, HttpStatus.ok);
      expect(await stale.readAsString(), 'sdk-bytes');

      final head = await send('/dart_sdk.js', method: 'HEAD');
      expect(head.statusCode, HttpStatus.ok);
      expect(head.headers[HttpHeaders.etagHeader], etag);
      expect(head.headers[HttpHeaders.contentLengthHeader], '9');
      expect(await head.readAsString(), isEmpty);
    },
  );

  test('serves index.html for directories', () async {
    expect(await (await send('/')).readAsString(), 'index.html');
    expect(await (await send('/sub/')).readAsString(), 'sub/index.html');
  });

  test(
    'serves static files from web/ with Cache-Control: no-cache and 304',
    () async {
      final response = await send('/style.css');
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'style.css');
      expect(response.headers[HttpHeaders.contentTypeHeader], 'text/css');
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-cache');
      expect(response.headers['cross-origin-resource-policy'], 'same-site');

      final etag = response.headers[HttpHeaders.etagHeader]!;
      final revalidated = await send(
        '/style.css',
        headers: {HttpHeaders.ifNoneMatchHeader: etag},
      );
      expect(revalidated.statusCode, HttpStatus.notModified);
      expect(revalidated.headers[HttpHeaders.cacheControlHeader], 'no-cache');
      expect(revalidated.headers['cross-origin-resource-policy'], 'same-site');
    },
  );

  test('serves Dart sources with their size, an ETag and no-cache', () async {
    for (final (path, contents) in [
      ('/web/my%20file.dart', 'my file.dart'),
      ('/packages/app/my%20lib.dart', 'my lib.dart'),
      ('/dart-sdk/lib/core/core.dart', 'core.dart'),
    ]) {
      final response = await send(path);
      expect(response.statusCode, HttpStatus.ok, reason: path);
      expect(await response.readAsString(), contents);
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-cache');
      expect(
        response.headers[HttpHeaders.contentLengthHeader],
        '${contents.length}',
        reason: path,
      );
      final etag = response.headers[HttpHeaders.etagHeader]!;
      expect(etag, startsWith('"'));

      final head = await send(path, method: 'HEAD');
      expect(head.statusCode, HttpStatus.ok, reason: path);
      expect(
        head.headers[HttpHeaders.contentLengthHeader],
        '${contents.length}',
        reason: path,
      );
      expect(head.headers[HttpHeaders.etagHeader], etag);
      expect(await head.readAsString(), isEmpty);

      final revalidated = await send(
        path,
        headers: {HttpHeaders.ifNoneMatchHeader: etag},
      );
      expect(revalidated.statusCode, HttpStatus.notModified, reason: path);
      expect(await revalidated.readAsString(), isEmpty);
    }

    // Invalid package names return 404 rather than throwing 500.
    expect((await send('/packages/bad%3Aname/a.dart')).statusCode, 404);
    expect((await send('/packages/%20/a.dart')).statusCode, 404);
  });

  test('serves an edited Dart source instead of a 304', () async {
    final first = await send('/web/main.dart');
    final etag = first.headers[HttpHeaders.etagHeader]!;

    File(
      p.join(d.sandbox, 'app', 'web', 'main.dart'),
    ).writeAsStringSync('edited main.dart');
    final edited = await send(
      '/web/main.dart',
      headers: {HttpHeaders.ifNoneMatchHeader: etag},
    );
    expect(edited.statusCode, HttpStatus.ok);
    expect(await edited.readAsString(), 'edited main.dart');
    expect(edited.headers[HttpHeaders.contentLengthHeader], '16');
    expect(edited.headers[HttpHeaders.etagHeader], isNot(etag));
  });

  test('answers a missing file with a plain-text 404', () async {
    final response = await send('/missing.js');
    expect(response.statusCode, HttpStatus.notFound);
    expect(await response.readAsString(), 'Not found: /missing.js');
  });

  test('only answers GET and HEAD', () async {
    expect((await send('/', method: 'HEAD')).statusCode, HttpStatus.ok);
    final post = await send('/', method: 'POST');
    expect(post.statusCode, HttpStatus.methodNotAllowed);
    expect(post.headers[HttpHeaders.allowHeader], 'GET, HEAD');
    expect(post.headers['cross-origin-resource-policy'], 'same-site');
  });

  test('holds requests until ready', () async {
    final ready = Completer<void>();
    handler = createAppHandler(
      lookupFile: (_) => null,
      webDirectory: p.join(d.sandbox, 'app', 'web'),
      ready: ready.future,
    );
    var answered = false;
    final response = send('/').then((_) => answered = true);
    await pumpEventQueue();
    expect(answered, isFalse);
    ready.complete();
    await response;
    expect(answered, isTrue);
  });

  group('security middleware', () {
    test('validates Host header against DNS rebinding', () async {
      for (final allowedHost in [
        'localhost',
        'localhost:8080',
        'LOCALHOST:8080',
        'sub.localhost:8080',
        '127.0.0.1:8080',
        '[::1]:8080',
        '[::1]',
      ]) {
        final response = await send('/style.css', host: allowedHost);
        expect(response.statusCode, HttpStatus.ok, reason: allowedHost);
      }

      for (final rejectedHost in <String?>[
        null,
        '',
        'attacker.example:8080',
        'evil-localhost:8080',
        '.localhost:8080',
        'user@localhost:8080',
        'localhost/bad',
        'localhost?q=1',
        'localhost#frag',
      ]) {
        final response = await send('/style.css', host: rejectedHost);
        expect(
          response.statusCode,
          HttpStatus.forbidden,
          reason: '$rejectedHost',
        );
        expect(response.headers['cross-origin-resource-policy'], 'same-site');
      }

      // Duplicate Host headers are rejected.
      final duplicateHost = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost:8080/style.css'),
          headers: {
            HttpHeaders.hostHeader: ['localhost:8080', 'attacker.example:8080'],
          },
        ),
      );
      expect(duplicateHost.statusCode, HttpStatus.forbidden);

      // A custom configured hostname is allowed, while 'any' does not match a
      // literal `Host: any`.
      final customHostHandler = createAppHandler(
        lookupFile: (_) => null,
        webDirectory: p.join(d.sandbox, 'app', 'web'),
        hostname: 'devbox.internal',
      );
      expect(
        (await send(
          '/style.css',
          host: 'devbox.internal:8080',
          target: customHostHandler,
        )).statusCode,
        HttpStatus.ok,
      );
      final anyHostHandler = createAppHandler(
        lookupFile: (_) => null,
        webDirectory: p.join(d.sandbox, 'app', 'web'),
        hostname: 'any',
      );
      expect(
        (await send(
          '/style.css',
          host: 'any:8080',
          target: anyHostHandler,
        )).statusCode,
        HttpStatus.forbidden,
      );
      expect(
        (await send(
          '/style.css',
          host: '192.168.1.50:8080',
          target: anyHostHandler,
        )).statusCode,
        HttpStatus.ok,
      );
    });

    test('blocks cross-site subresource loads via Sec-Fetch-Site', () async {
      // Non-browser clients (no Sec-Fetch-Site) and same-origin / same-site /
      // direct user-initiated loads succeed.
      for (final site in <String?>[null, 'same-origin', 'same-site', 'none']) {
        final response = await send(
          '/main.dart.js',
          headers: {'Sec-Fetch-Site': ?site},
        );
        expect(response.statusCode, HttpStatus.ok, reason: '$site');
      }

      // Cross-site top-level and iframe GET/HEAD navigations succeed.
      for (final dest in ['document', 'iframe']) {
        final response = await send(
          '/',
          headers: {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Dest': dest,
          },
        );
        expect(response.statusCode, HttpStatus.ok, reason: dest);
      }

      // Cross-site <script>, fetch(), <object>, <embed>, and POST fail (403).
      for (final (method, headers) in <(String, Map<String, String>)>[
        (
          'GET',
          {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'no-cors',
            'Sec-Fetch-Dest': 'script',
          },
        ),
        (
          'GET',
          {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Dest': 'empty',
          },
        ),
        (
          'GET',
          {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Dest': 'object',
          },
        ),
        (
          'GET',
          {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Dest': 'embed',
          },
        ),
        (
          'POST',
          {
            'Sec-Fetch-Site': 'cross-site',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Dest': 'document',
          },
        ),
      ]) {
        final response = await send(
          '/main.dart.js',
          method: method,
          headers: headers,
        );
        expect(
          response.statusCode,
          HttpStatus.forbidden,
          reason: '$method $headers',
        );
        expect(response.headers['cross-origin-resource-policy'], 'same-site');
      }
    });

    test('rejects unsafe path segments before ready/staticHandler, '
        'while allowing .well-known', () async {
      final neverReady = Completer<void>();
      final unreadyHandler = createAppHandler(
        lookupFile: (_) => null,
        webDirectory: p.join(d.sandbox, 'app', 'web'),
        ready: neverReady.future,
      );

      for (final unsafePath in [
        '/%5C%5Cattacker.example%5Cshare%5Cx.png',
        '/C%3A/secret.dart',
        '/%2Fetc%2Fpasswd',
        '/%00.txt',
        '/.env',
        '/.git/config',
        '/..hidden',
        '/sub//index.html',
        '//index.html',
      ]) {
        final response = await send(unsafePath, target: unreadyHandler);
        expect(response.statusCode, HttpStatus.notFound, reason: unsafePath);
        expect(response.headers['cross-origin-resource-policy'], 'same-site');
      }

      // URI-normalized `..` stays clamped to `/` and cannot read
      // `../secret.dart`.
      expect((await send('/../secret.dart')).statusCode, HttpStatus.notFound);
      expect(
        (await send('/%2e%2e/secret.dart')).statusCode,
        HttpStatus.notFound,
      );

      final wellKnown = await send('/.well-known/assetlinks.json');
      expect(wellKnown.statusCode, HttpStatus.ok);
      expect(await wellKnown.readAsString(), 'assetlinks.json');
    });
  });
}
