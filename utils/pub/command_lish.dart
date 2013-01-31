// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_lish;

import 'dart:async';
import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../pkg/args/lib/args.dart';
import '../../pkg/http/lib/http.dart' as http;
import '../../pkg/path/lib/path.dart' as path;
import 'directory_tree.dart';
import 'git.dart' as git;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'oauth2.dart' as oauth2;
import 'pub.dart';
import 'utils.dart';
import 'validator.dart';

/// Handles the `lish` and `publish` pub commands.
class LishCommand extends PubCommand {
  final description = "Publish the current package to pub.dartlang.org.";
  final usage = "pub publish [options]";
  final aliases = const ["lish", "lush"];

  ArgParser get commandParser {
    var parser = new ArgParser();
    // TODO(nweiz): Use HostedSource.defaultUrl as the default value once we use
    // dart:io for HTTPS requests.
    parser.addOption('server', defaultsTo: 'https://pub.dartlang.org',
        help: 'The package server to which to upload this package');
    return parser;
  }

  /// The URL of the server to which to upload the package.
  Uri get server => Uri.parse(commandOptions['server']);

  Future _publish(packageBytes) {
    var cloudStorageUrl;
    return oauth2.withClient(cache, (client) {
      // TODO(nweiz): Cloud Storage can provide an XML-formatted error. We
      // should report that error and exit.
      var newUri = server.resolve("/packages/versions/new.json");
      return client.get(newUri).then((response) {
        var parameters = parseJsonResponse(response);

        var url = _expectField(parameters, 'url', response);
        if (url is! String) invalidServerResponse(response);
        cloudStorageUrl = Uri.parse(url);
        var request = new http.MultipartRequest('POST', cloudStorageUrl);

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
      }).then((location) => client.get(location))
        .then(handleJsonSuccess);
    }).catchError((asyncError) {
      if (asyncError.error is! PubHttpException) throw asyncError;
      var url = asyncError.error.response.request.url;
      if (url.toString() == cloudStorageUrl.toString()) {
        // TODO(nweiz): the response may have XML-formatted information about
        // the error. Try to parse that out once we have an easily-accessible
        // XML parser.
        throw 'Failed to upload the package.';
      } else if (url.origin == server.origin) {
        handleJsonError(asyncError.error.response);
      }
    });
  }

  Future onRun() {
    var files;
    return _filesToPublish.then((f) {
      files = f;
      log.fine('Archiving and publishing ${entrypoint.root}.');
      return createTarGz(files, baseDir: entrypoint.root.dir);
    }).then(consumeInputStream).then((packageBytes) {
      // Show the package contents so the user can verify they look OK.
      var package = entrypoint.root;
      log.message(
          'Publishing "${package.name}" ${package.version}:\n'
          '${generateTree(files)}');

      // Validate the package.
      return _validate().then((_) => _publish(packageBytes));
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

    return Future.wait([
      dirExists(join(rootDir, '.git')),
      git.isInstalled
    ]).then((results) {
      if (results[0] && results[1]) {
        // List all files that aren't gitignored, including those not checked
        // in to Git.
        return git.run(["ls-files", "--cached", "--others",
                        "--exclude-standard"]);
      }

      return listDir(rootDir, recursive: true).then((entries) {
        return Future.wait(entries.mappedBy((entry) {
          return fileExists(entry).then((isFile) {
            // Skip directories.
            if (!isFile) return null;

            // TODO(rnystrom): Making these relative will break archive
            // creation if the cwd is ever *not* the package root directory.
            // Should instead only make these relative right before generating
            // the tree display (which is what really needs them to be).
            // Make it relative to the package root.
            return relativeTo(entry, rootDir);
          });
        }));
      });
    }).then((files) => files.where((file) {
      if (file == null || _BLACKLISTED_FILES.contains(basename(file))) {
        return false;
      }

      return !splitPath(file).any(_BLACKLISTED_DIRECTORIES.contains);
    }).toList());
  }

  /// Returns the value associated with [key] in [map]. Throws a user-friendly
  /// error if [map] doens't contain [key].
  _expectField(Map map, String key, http.Response response) {
    if (map.containsKey(key)) return map[key];
    invalidServerResponse(response);
  }

  /// Validates the package. Throws an exception if it's invalid.
  Future _validate() {
    return Validator.runAll(entrypoint).then((pair) {
      var errors = pair.first;
      var warnings = pair.last;

      if (!errors.isEmpty) {
        throw "Sorry, your package is missing "
            "${(errors.length > 1) ? 'some requirements' : 'a requirement'} "
            "and can't be published yet.\nFor more information, see: "
            "http://pub.dartlang.org/doc/pub-lish.html.\n";
      }

      var message = 'Looks great! Are you ready to upload your package';

      if (!warnings.isEmpty) {
        var s = warnings.length == 1 ? '' : 's';
        message = "Package has ${warnings.length} warning$s. Upload anyway";
      }

      return confirm(message).then((confirmed) {
        if (!confirmed) throw "Package upload canceled.";
      });
    });
  }
}
