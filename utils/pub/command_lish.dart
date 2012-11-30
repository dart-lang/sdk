// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_lish;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../pkg/args/lib/args.dart';
import '../../pkg/http/lib/http.dart' as http;
import 'pub.dart';
import 'io.dart';
import 'git.dart' as git;
import 'oauth2.dart' as oauth2;

// TODO(nweiz): Make "publish" the primary name for this command. See issue
// 6949.
/// Handles the `lish` and `publish` pub commands.
class LishCommand extends PubCommand {
  final description = "publish the current package to pub.dartlang.org";
  final usage = "pub publish [options]";
  final aliases = const ["lish", "lush"];

  ArgParser get commandParser {
    var parser = new ArgParser();
    parser.addOption('server', defaultsTo: 'http://pub.dartlang.org',
        help: 'The package server to which to upload this package');
    return parser;
  }

  /// The URL of the server to which to upload the package.
  Uri get server => new Uri.fromString(commandOptions['server']);

  Future onRun() {
    var cloudStorageUrl;
    return oauth2.withClient(cache, (client) {
      // TODO(nweiz): Better error-handling. There are a few cases we need to
      // handle better:
      //
      // * The server can tell us we need new credentials (a 401 error). The
      //   oauth2 package should throw an AuthorizationException in this case
      //   (contingent on issue 6813 and 6275). We should have the user
      //   re-authorize the client, then restart the command. We should also do
      //   this in case of an ExpirationException. See issue 6950.
      //
      // * Cloud Storage can provide an XML-formatted error. We should report
      //   that error and exit.
      return Futures.wait([
        client.get(server.resolve("/packages/versions/new.json")),
        _filesToPublish.transform((files) {
          return createTarGz(files, baseDir: entrypoint.root.dir);
        }).chain(consumeInputStream)
      ]).chain((results) {
        var response = results[0];
        var packageBytes = results[1];
        var parameters = _parseJson(response);

        var url = _expectField(parameters, 'url', response);
        if (url is! String) _invalidServerResponse(response);
        cloudStorageUrl = new Uri.fromString(url);
        var request = new http.MultipartRequest('POST', cloudStorageUrl);

        var fields = _expectField(parameters, 'fields', response);
        if (fields is! Map) _invalidServerResponse(response);
        fields.forEach((key, value) {
          if (value is! String) _invalidServerResponse(response);
          request.fields[key] = value;
        });

        request.followRedirects = false;
        request.files.add(new http.MultipartFile.fromBytes(
            'file', packageBytes, filename: 'package.tar.gz'));
        return client.send(request);
      }).chain(http.Response.fromStream).transform((response) {
        var location = response.headers['location'];
        if (location == null) throw new PubHttpException(response);
        return location;
      }).chain((location) => client.get(location)).transform((response) {
        var parsed = _parseJson(response);
        if (parsed['success'] is! Map ||
            !parsed['success'].containsKey('message') ||
            parsed['success']['message'] is! String) {
          _invalidServerResponse(response);
        }
        print(parsed['success']['message']);
      });
    }).transformException((e) {
      if (e is PubHttpException) {
        var url = e.response.request.url;
        if (url.toString() == cloudStorageUrl.toString()) {
          // TODO(nweiz): the response may have XML-formatted information about
          // the error. Try to parse that out once we have an easily-accessible
          // XML parser.
          throw 'Failed to upload the package.';
        } else if (url.origin == server.origin) {
          var errorMap = _parseJson(e.response);
          if (errorMap['error'] is! Map ||
              !errorMap['error'].containsKey('message') ||
              errorMap['error']['message'] is! String) {
            _invalidServerResponse(e.response);
          }
          throw errorMap['error']['message'];
        }
      }

      if (e is! oauth2.ExpirationException) throw e;

      printError("Pub's authorization to upload packages has expired and can't "
          "be automatically refreshed.");
      return onRun();
    });
  }

  /// The basenames of files that are automatically excluded from archives.
  final _BLACKLISTED_FILES = const ['pubspec.lock'];

  /// The basenames of directories that are automatically excluded from
  /// archives.
  final _BLACKLISTED_DIRECTORIES = const ['packages'];

  /// Returns a list of files that should be included in the published package.
  /// If this is a Git repository, this will respect .gitignore; otherwise, it
  /// will return all non-hidden files.
  Future<List<String>> get _filesToPublish {
    var rootDir = entrypoint.root.dir;
    return Futures.wait([
      dirExists(join(rootDir, '.git')),
      git.isInstalled
    ]).chain((results) {
      if (results[0] && results[1]) {
        // List all files that aren't gitignored, including those not checked in
        // to Git.
        return git.run(["ls-files", "--cached", "--others"]);
      }

      return listDir(rootDir, recursive: true).chain((entries) {
        return Futures.wait(entries.map((entry) {
          return fileExists(entry).transform((isFile) => isFile ? entry : null);
        }));
      });
    }).transform((files) => files.filter((file) {
      if (file == null || _BLACKLISTED_FILES.contains(basename(file))) {
        return false;
      }
      return !splitPath(file).some(_BLACKLISTED_DIRECTORIES.contains);
    }));
  }

  /// Parses a response body, assuming it's JSON-formatted. Throws a
  /// user-friendly error if the response body is invalid JSON, or if it's not a
  /// map.
  Map _parseJson(http.Response response) {
    var value;
    try {
      value = JSON.parse(response.body);
    } catch (e) {
      // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
      _invalidServerResponse(response);
    }
    if (value is! Map) _invalidServerResponse(response);
    return value;
  }

  /// Returns the value associated with [key] in [map]. Throws a user-friendly
  /// error if [map] doens't contain [key].
  _expectField(Map map, String key, http.Response response) {
    if (map.containsKey(key)) return map[key];
    _invalidServerResponse(response);
  }

  /// Throws an error describing an invalid response from the server.
  void _invalidServerResponse(http.Response response) {
    throw 'Invalid server response:\n${response.body}';
  }
}
