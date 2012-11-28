// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_lish_test;

import 'dart:io';
import 'dart:json';

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/io.dart';

void handleUploadForm(ScheduledServer server, [Map body]) {
  server.handle('GET', '/packages/versions/new.json', (request, response) {
    return server.url.chain((url) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      if (body == null) {
        body = {
          'url': url.resolve('/upload').toString(),
          'fields': {
            'field1': 'value1',
            'field2': 'value2'
          }
        };
      }

      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(JSON.stringify(body));
      return closeHttpResponse(request, response);
    });
  });
}

void handleUpload(ScheduledServer server) {
  server.handle('POST', '/upload', (request, response) {
    // TODO(nweiz): Once a multipart/form-data parser in Dart exists, validate
    // that the request body is correctly formatted. See issue 6952.
    return server.url.chain((url) {
      response.statusCode = 302;
      response.headers.set('location', url.resolve('/create').toString());
      return closeHttpResponse(request, response);
    });
  });
}

main() {
  setUp(() => dir(appPath, [libPubspec("test_pkg", "1.0.0")]).scheduleCreate());

  test('archives and uploads a package', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.outputStream.writeString(JSON.stringify({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextLine(), equals('Package test_pkg 1.0.0 uploaded!'));
    pub.shouldExit(0);

    run();
  });

  // TODO(nweiz): Once a multipart/form-data parser in Dart exists, we should
  // test that "pub lish" chooses the correct files to publish.

  // TODO(nweiz): Once issue 6813 is fixed, test that OAuth2 authentication
  // errors cause the client to try re-authenticating.

  test('upload form provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      response.statusCode = 400;
      response.outputStream.writeString(JSON.stringify({
        'error': {'message': 'your request sucked'}
      }));
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('your request sucked'));
    pub.shouldExit(1);

    run();
  });

  test('upload form provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      response.outputStream.writeString('{not json');
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);

    run();
  });

  test('upload form is missing url', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    var body = {
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('upload form url is not a string', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    var body = {
      'url': 12,
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('upload form is missing fields', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    var body = {'url': 'http://example.com/upload'};
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('upload form fields is not a map', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    var body = {'url': 'http://example.com/upload', 'fields': 12};
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('upload form fields has a non-string value', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    var body = {
      'url': 'http://example.com/upload',
      'fields': {'field': 12}
    };
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('cloud storage upload provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request, response) {
      response.statusCode = 400;
      response.headers.contentType = new ContentType('application', 'xml');
      response.outputStream.writeString('<Error><Message>Your request sucked.'
          '</Message></Error>');
      return closeHttpResponse(request, response);
    });

    // TODO(nweiz): This should use the server's error message once the client
    // can parse the XML.
    expectLater(pub.nextErrLine(), equals('Failed to upload the package.'));
    pub.shouldExit(1);

    run();
  });

  test("cloud storage upload doesn't redirect", () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request, response) {
      // don't set the location header
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Failed to upload the package.'));
    pub.shouldExit(1);

    run();
  });

  test('package creation provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.outputStream.writeString(JSON.stringify({
        'error': {'message': 'Your package was too boring.'}
      }));
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Your package was too boring.'));
    pub.shouldExit(1);

    run();
  });

  test('package creation provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.outputStream.writeString('{not json');
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);

    run();
  });

  test('package creation provides a malformed error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'error': 'Your package was too boring.'};
    server.handle('GET', '/create', (request, response) {
      response.statusCode = 400;
      response.outputStream.writeString(JSON.stringify(body));
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });

  test('package creation provides a malformed success', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'success': 'Your package was awesome.'};
    server.handle('GET', '/create', (request, response) {
      response.outputStream.writeString(JSON.stringify(body));
      return closeHttpResponse(request, response);
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(JSON.stringify(body)));
    pub.shouldExit(1);

    run();
  });
}
