// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_lish_test;

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../pub/exit_codes.dart' as exit_codes;
import '../../pub/io.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

void handleUploadForm(ScheduledServer server, [Map body]) {
  server.handle('GET', '/packages/versions/new.json', (request) {
    return server.url.then((url) {
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

      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(json.stringify(body));
      request.response.close();
    });
  });
}

void handleUpload(ScheduledServer server) {
  server.handle('POST', '/upload', (request) {
    // TODO(nweiz): Once a multipart/form-data parser in Dart exists, validate
    // that the request body is correctly formatted. See issue 6952.
    return drainStream(request).then((_) {
      return server.url;
    }).then((url) {
      request.response.statusCode = 302;
      request.response.headers.set(
          'location', url.resolve('/create').toString());
      request.response.close();
    });
  });
}

main() {
  initConfig();
  setUp(() => d.validPackage.create());

  integration('archives and uploads a package', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      request.response.write(json.stringify({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
      request.response.close();
    });

    // TODO(rnystrom): The confirm line is run together with this one because
    // in normal usage, the user will have entered a newline on stdin which
    // gets echoed to the terminal. Do something better here?
    expect(pub.nextLine(), completion(equals(
        'Looks great! Are you ready to upload your package (y/n)?'
        ' Package test_pkg 1.0.0 uploaded!')));
    pub.shouldExit(0);
  });

  // TODO(nweiz): Once a multipart/form-data parser in Dart exists, we should
  // test that "pub lish" chooses the correct files to publish.

  integration('package validation has an error', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg.remove("homepage");
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server);

    pub.shouldExit(0);
    expect(pub.remainingStderr(), completion(contains(
        "Sorry, your package is missing a requirement and can't be published "
        "yet.")));
  });

  integration('preview package validation has a warning', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server, args: ['--dry-run']);

    pub.shouldExit(0);
    expect(pub.remainingStderr(), completion(contains(
        'Suggestions:\n* Author "Nathan Weizenbaum" in pubspec.yaml should '
            'have an email address\n'
        '  (e.g. "name <email>").\n\n'
        'Package has 1 warning.')));
  });

  integration('preview package validation has no warnings', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum <nweiz@google.com>";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server, args: ['--dry-run']);

    pub.shouldExit(0);
    expect(pub.remainingStderr(),
        completion(contains('Package has 0 warnings.')));
  });

  integration('package validation has a warning and is canceled', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server);

    pub.writeLine("n");
    pub.shouldExit(0);
    expect(pub.remainingStderr(),
        completion(contains("Package upload canceled.")));
  });

  integration('package validation has a warning and continues', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    pub.writeLine("y");
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      request.response.write(json.stringify({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
      request.response.close();
    });

    pub.shouldExit(0);
    expect(pub.remainingStdout(),
        completion(contains('Package test_pkg 1.0.0 uploaded!')));
  });

  integration('upload form provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      request.response.statusCode = 400;
      request.response.write(json.stringify({
        'error': {'message': 'your request sucked'}
      }));
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('your request sucked')));
    pub.shouldExit(1);
  });

  integration('upload form provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      request.response.write('{not json');
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals('{not json')));
    pub.shouldExit(1);
  });

  integration('upload form is missing url', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    var body = {
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('upload form url is not a string', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    var body = {
      'url': 12,
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('upload form is missing fields', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    var body = {'url': 'http://example.com/upload'};
    handleUploadForm(server, body);
    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('upload form fields is not a map', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    var body = {'url': 'http://example.com/upload', 'fields': 12};
    handleUploadForm(server, body);
    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('upload form fields has a non-string value', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    var body = {
      'url': 'http://example.com/upload',
      'fields': {'field': 12}
    };
    handleUploadForm(server, body);
    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('cloud storage upload provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request) {
      return drainStream(request).then((_) {
        request.response.statusCode = 400;
        request.response.headers.contentType =
            new ContentType('application', 'xml');
        request.response.write('<Error><Message>Your request sucked.'
            '</Message></Error>');
        request.response.close();
      });
    });

    // TODO(nweiz): This should use the server's error message once the client
    // can parse the XML.
    expect(pub.nextErrLine(),
        completion(equals('Failed to upload the package.')));
    pub.shouldExit(1);
  });

  integration("cloud storage upload doesn't redirect", () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request) {
      return drainStream(request).then((_) {
        // Don't set the location header.
        request.response.close();
      });
    });

    expect(pub.nextErrLine(),
        completion(equals('Failed to upload the package.')));
    pub.shouldExit(1);
  });

  integration('package creation provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      request.response.statusCode = 400;
      request.response.write(json.stringify({
        'error': {'message': 'Your package was too boring.'}
      }));
      request.response.close();
    });

    expect(pub.nextErrLine(),
        completion(equals('Your package was too boring.')));
    pub.shouldExit(1);
  });

  integration('package creation provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      request.response.write('{not json');
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals('{not json')));
    pub.shouldExit(1);
  });

  integration('package creation provides a malformed error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'error': 'Your package was too boring.'};
    server.handle('GET', '/create', (request) {
      request.response.statusCode = 400;
      request.response.write(json.stringify(body));
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  integration('package creation provides a malformed success', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'success': 'Your package was awesome.'};
    server.handle('GET', '/create', (request) {
      request.response.write(json.stringify(body));
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals(json.stringify(body))));
    pub.shouldExit(1);
  });

  group('--force', () {
    setUp(() => d.validPackage.create());

    integration('cannot be combined with --dry-run', () {
      schedulePub(args: ['lish', '--force', '--dry-run'],
          error: "Cannot use both --force and --dry-run.",
          exitCode: exit_codes.USAGE);
    });

    integration('publishes if there are no warnings or errors', () {
      var server = new ScheduledServer();
      d.credentialsFile(server, 'access token').create();
      var pub = startPublish(server, args: ['--force']);

      handleUploadForm(server);
      handleUpload(server);

      server.handle('GET', '/create', (request) {
        request.response.write(json.stringify({
          'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
        }));
        request.response.close();
      });

      pub.shouldExit(0);
      expect(pub.remainingStdout(), completion(contains(
          'Package test_pkg 1.0.0 uploaded!')));
    });

    integration('publishes if there are warnings', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["author"] = "Nathan Weizenbaum";
      d.dir(appPath, [d.pubspec(pkg)]).create();

      var server = new ScheduledServer();
      d.credentialsFile(server, 'access token').create();
      var pub = startPublish(server, args: ['--force']);

      handleUploadForm(server);
      handleUpload(server);

      server.handle('GET', '/create', (request) {
        request.response.write(json.stringify({
          'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
        }));
        request.response.close();
      });

      pub.shouldExit(0);
      expect(pub.remainingStderr(), completion(contains(
          'Suggestions:\n* Author "Nathan Weizenbaum" in pubspec.yaml'
          ' should have an email address\n'
          '  (e.g. "name <email>").')));
      expect(pub.remainingStdout(), completion(contains(
          'Package test_pkg 1.0.0 uploaded!')));
    });

    integration('does not publish if there are errors', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("homepage");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      var server = new ScheduledServer();
      var pub = startPublish(server, args: ['--force']);

      pub.shouldExit(0);
      expect(pub.remainingStderr(), completion(contains(
          "Sorry, your package is missing a requirement and can't be "
          "published yet.")));
    });
  });
}
