// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.lish;

import 'dart:async';

import 'package:http/http.dart' as http;

import '../command.dart';
import '../ascii_tree.dart' as tree;
import '../http.dart';
import '../io.dart';
import '../log.dart' as log;
import '../oauth2.dart' as oauth2;
import '../source/hosted.dart';
import '../utils.dart';
import '../validator.dart';

/// Handles the `lish` and `publish` pub commands.
class LishCommand extends PubCommand {
  String get description => "Publish the current package to pub.dartlang.org.";
  String get usage => "pub publish [options]";
  List<String> get aliases => const ["lish", "lush"];

  /// The URL of the server to which to upload the package.
  Uri get server => Uri.parse(commandOptions['server']);

  /// Whether the publish is just a preview.
  bool get dryRun => commandOptions['dry-run'];

  /// Whether the publish requires confirmation.
  bool get force => commandOptions['force'];

  LishCommand() {
    commandParser.addFlag('dry-run', abbr: 'n', negatable: false,
        help: 'Validate but do not publish the package.');
    commandParser.addFlag('force', abbr: 'f', negatable: false,
        help: 'Publish without confirmation if there are no errors.');
    commandParser.addOption('server', defaultsTo: HostedSource.defaultUrl,
        help: 'The package server to which to upload this package.');
  }

  Future _publish(packageBytes) {
    var cloudStorageUrl;
    return oauth2.withClient(cache, (client) {
      return log.progress('Uploading', () {
        // TODO(nweiz): Cloud Storage can provide an XML-formatted error. We
        // should report that error and exit.
        var newUri = server.resolve("/api/packages/versions/new");
        return client.get(newUri, headers: PUB_API_HEADERS).then((response) {
          var parameters = parseJsonResponse(response);

          var url = _expectField(parameters, 'url', response);
          if (url is! String) invalidServerResponse(response);
          cloudStorageUrl = Uri.parse(url);
          var request = new http.MultipartRequest('POST', cloudStorageUrl);
          request.headers['Pub-Request-Timeout'] = 'None';

          var fields = _expectField(parameters, 'fields', response);
          if (fields is! Map) invalidServerResponse(response);
          fields.forEach((key, value) {
            if (value is! String) invalidServerResponse(response);
            request.fields[key] = value;
          });

          request.followRedirects = false;
          request.files.add(new http.MultipartFile.fromBytes(
              'file', packageBytes, filename: 'package.tar.gz'));
          return client.send(request);
        }).then(http.Response.fromStream).then((response) {
          var location = response.headers['location'];
          if (location == null) throw new PubHttpException(response);
          return location;
        }).then((location) => client.get(location, headers: PUB_API_HEADERS))
          .then(handleJsonSuccess);
      });
    }).catchError((error) {
      if (error is! PubHttpException) throw error;
      var url = error.response.request.url;
      if (urisEqual(url, cloudStorageUrl)) {
        // TODO(nweiz): the response may have XML-formatted information about
        // the error. Try to parse that out once we have an easily-accessible
        // XML parser.
        throw new ApplicationException('Failed to upload the package.');
      } else if (urisEqual(Uri.parse(url.origin), Uri.parse(server.origin))) {
        handleJsonError(error.response);
      } else {
        throw error;
      }
    });
  }

  Future onRun() {
    if (force && dryRun) {
      usageError('Cannot use both --force and --dry-run.');
    }

    var files = entrypoint.packageFiles();
    log.fine('Archiving and publishing ${entrypoint.root}.');

    // Show the package contents so the user can verify they look OK.
    var package = entrypoint.root;
    log.message(
        'Publishing ${package.name} ${package.version} to $server:\n'
        '${tree.fromFiles(files, baseDir: entrypoint.root.dir)}');

    var packageBytesFuture = createTarGz(files, baseDir: entrypoint.root.dir)
        .toBytes();

    // Validate the package.
    return _validate(packageBytesFuture.then((bytes) => bytes.length))
        .then((isValid) {
       if (isValid) return packageBytesFuture.then(_publish);
    });
  }

  /// Returns the value associated with [key] in [map]. Throws a user-friendly
  /// error if [map] doens't contain [key].
  _expectField(Map map, String key, http.Response response) {
    if (map.containsKey(key)) return map[key];
    invalidServerResponse(response);
  }

  /// Validates the package. Completes to false if the upload should not
  /// proceed.
  Future<bool> _validate(Future<int> packageSize) {
    return Validator.runAll(entrypoint, packageSize).then((pair) {
      var errors = pair.first;
      var warnings = pair.last;

      if (!errors.isEmpty) {
        log.error("Sorry, your package is missing "
            "${(errors.length > 1) ? 'some requirements' : 'a requirement'} "
            "and can't be published yet.\nFor more information, see: "
            "http://pub.dartlang.org/doc/pub-lish.html.\n");
        return false;
      }

      if (force) return true;

      if (dryRun) {
        var s = warnings.length == 1 ? '' : 's';
        log.warning("\nPackage has ${warnings.length} warning$s.");
        return false;
      }

      var message = '\nLooks great! Are you ready to upload your package';

      if (!warnings.isEmpty) {
        var s = warnings.length == 1 ? '' : 's';
        message = "\nPackage has ${warnings.length} warning$s. Upload anyway";
      }

      return confirm(message).then((confirmed) {
        if (!confirmed) {
          log.error("Package upload canceled.");
          return false;
        }
        return true;
      });
    });
  }
}
