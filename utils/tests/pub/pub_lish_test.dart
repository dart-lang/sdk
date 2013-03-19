// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_lish_test;

import 'dart:io';
import 'dart:json' as json;

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/exit_codes.dart' as exit_codes;
import '../../pub/io.dart';

void handleUploadForm(ScheduledServer server, [Map body]) {
  server.handle('GET', '/packages/versions/new.json', (request, response) {
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

      response.headers.contentType = new ContentType("application", "json");
      response.write(json.stringify(body));
      response.close();
    });
  });
}

void handleUpload(ScheduledServer server) {
  server.handle('POST', '/upload', (request, response) {
    // TODO(nweiz): Once a multipart/form-data parser in Dart exists, validate
    // that the request body is correctly formatted. See issue 6952.
    return drainStream(request).then((_) {
      return server.url;
    }).then((url) {
      response.statusCode = 302;
      response.headers.set('location', url.resolve('/create').toString());
      response.close();
    });
  });
}

main() {
  initConfig();
  setUp(() => normalPackage.scheduleCreate());

  integration('archives and uploads a package', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.write(json.stringify({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
      response.close();
    });

    // TODO(rnystrom): The confirm line is run together with this one because
    // in normal usage, the user will have entered a newline on stdin which
    // gets echoed to the terminal. Do something better here?
    expectLater(pub.nextLine(), equals(
        'Looks great! Are you ready to upload your package (y/n)?'
        ' Package test_pkg 1.0.0 uploaded!'));
    pub.shouldExit(0);
  });

  // TODO(nweiz): Once a multipart/form-data parser in Dart exists, we should
  // test that "pub lish" chooses the correct files to publish.

  integration('package validation has an error', () {
    var pkg = package("test_pkg", "1.0.0");
    pkg.remove("homepage");
    dir(appPath, [pubspec(pkg)]).scheduleCreate();

    var server = new ScheduledServer();
    var pub = startPubLish(server);

    pub.shouldExit(0);
    expectLater(pub.remainingStderr(),
        contains("Sorry, your package is missing a requirement and can't be "
            "published yet."));
  });

  integration('preview package validation has a warning', () {
    var pkg = package("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    dir(appPath, [pubspec(pkg)]).scheduleCreate();

    var server = new ScheduledServer();
    var pub = startPubLish(server, args: ['--dry-run']);

    pub.shouldExit(0);
    expectLater(pub.remainingStderr(),
        contains('Suggestions:\n* Author "Nathan Weizenbaum" in pubspec.yaml'
                  ' should have an email address\n'
                  '  (e.g. "name <email>").\n\n'
                  'Package has 1 warning.'));
  });

  integration('preview package validation has no warnings', () {
    var pkg = package("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum <nweiz@google.com>";
    dir(appPath, [pubspec(pkg)]).scheduleCreate();

    var server = new ScheduledServer();
    var pub = startPubLish(server, args: ['--dry-run']);

    pub.shouldExit(0);
    expectLater(pub.remainingStderr(),
        contains('Package has 0 warnings.'));
  });

  integration('package validation has a warning and is canceled', () {
    var pkg = package("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    dir(appPath, [pubspec(pkg)]).scheduleCreate();

    var server = new ScheduledServer();
    var pub = startPubLish(server);

    pub.writeLine("n");
    pub.shouldExit(0);
    expectLater(pub.remainingStderr(), contains("Package upload canceled."));
  });

  integration('package validation has a warning and continues', () {
    var pkg = package("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    dir(appPath, [pubspec(pkg)]).scheduleCreate();

    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    pub.writeLine("y");
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.write(json.stringify({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
      response.close();
    });

    pub.shouldExit(0);
    expectLater(pub.remainingStdout(),
        contains('Package test_pkg 1.0.0 uploaded!'));
  });

  integration('upload form provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      response.statusCode = 400;
      response.write(json.stringify({
        'error': {'message': 'your request sucked'}
      }));
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('your request sucked'));
    pub.shouldExit(1);
  });

  integration('upload form provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      response.write('{not json');
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);
  });

  integration('upload form is missing url', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    var body = {
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('upload form url is not a string', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    var body = {
      'url': 12,
      'fields': {
        'field1': 'value1',
        'field2': 'value2'
      }
    };

    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('upload form is missing fields', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    var body = {'url': 'http://example.com/upload'};
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('upload form fields is not a map', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    var body = {'url': 'http://example.com/upload', 'fields': 12};
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('upload form fields has a non-string value', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    var body = {
      'url': 'http://example.com/upload',
      'fields': {'field': 12}
    };
    handleUploadForm(server, body);
    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('cloud storage upload provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request, response) {
      return drainStream(request).then((_) {
        response.statusCode = 400;
        response.headers.contentType = new ContentType('application', 'xml');
        response.write('<Error><Message>Your request sucked.'
            '</Message></Error>');
        response.close();
      });
    });

    // TODO(nweiz): This should use the server's error message once the client
    // can parse the XML.
    expectLater(pub.nextErrLine(), equals('Failed to upload the package.'));
    pub.shouldExit(1);
  });

  integration("cloud storage upload doesn't redirect", () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request, response) {
      return drainStream(request).then((_) {
        // Don't set the location header.
        response.close();
      });
    });

    expectLater(pub.nextErrLine(), equals('Failed to upload the package.'));
    pub.shouldExit(1);
  });

  integration('package creation provides an error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.statusCode = 400;
      response.write(json.stringify({
        'error': {'message': 'Your package was too boring.'}
      }));
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('Your package was too boring.'));
    pub.shouldExit(1);
  });

  integration('package creation provides invalid JSON', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request, response) {
      response.write('{not json');
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals('{not json'));
    pub.shouldExit(1);
  });

  integration('package creation provides a malformed error', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'error': 'Your package was too boring.'};
    server.handle('GET', '/create', (request, response) {
      response.statusCode = 400;
      response.write(json.stringify(body));
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  integration('package creation provides a malformed success', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    var body = {'success': 'Your package was awesome.'};
    server.handle('GET', '/create', (request, response) {
      response.write(json.stringify(body));
      response.close();
    });

    expectLater(pub.nextErrLine(), equals('Invalid server response:'));
    expectLater(pub.nextErrLine(), equals(json.stringify(body)));
    pub.shouldExit(1);
  });

  group('--force', () {
    setUp(() => normalPackage.scheduleCreate());

    integration('cannot be combined with --dry-run', () {
      schedulePub(args: ['lish', '--force', '--dry-run'],
          error: "Cannot use both --force and --dry-run.",
          exitCode: exit_codes.USAGE);
    });

    integration('publishes if there are no warnings or errors', () {
      var server = new ScheduledServer();
      credentialsFile(server, 'access token').scheduleCreate();
      var pub = startPubLish(server, args: ['--force']);

      handleUploadForm(server);
      handleUpload(server);

      server.handle('GET', '/create', (request, response) {
        response.write(json.stringify({
          'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
        }));
        response.close();
      });

      pub.shouldExit(0);
      expectLater(pub.remainingStdout(), contains(
          'Package test_pkg 1.0.0 uploaded!'));
    });

    integration('publishes if there are warnings', () {
      var pkg = package("test_pkg", "1.0.0");
      pkg["author"] = "Nathan Weizenbaum";
      dir(appPath, [pubspec(pkg)]).scheduleCreate();

      var server = new ScheduledServer();
      credentialsFile(server, 'access token').scheduleCreate();
      var pub = startPubLish(server, args: ['--force']);

      handleUploadForm(server);
      handleUpload(server);

      server.handle('GET', '/create', (request, response) {
        response.write(json.stringify({
          'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
        }));
        response.close();
      });

      pub.shouldExit(0);
      expectLater(pub.remainingStderr(), contains(
          'Suggestions:\n* Author "Nathan Weizenbaum" in pubspec.yaml'
          ' should have an email address\n'
          '  (e.g. "name <email>").'));
      expectLater(pub.remainingStdout(), contains(
          'Package test_pkg 1.0.0 uploaded!'));
    });

    integration('does not publish if there are errors', () {
      var pkg = package("test_pkg", "1.0.0");
      pkg.remove("homepage");
      dir(appPath, [pubspec(pkg)]).scheduleCreate();

      var server = new ScheduledServer();
      var pub = startPubLish(server, args: ['--force']);

      pub.shouldExit(0);
      expectLater(pub.remainingStderr(), contains(
          "Sorry, your package is missing a requirement and can't be "
          "published yet."));
    });
  });
}
