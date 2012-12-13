// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_lish;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../pkg/args/lib/args.dart';
import '../../pkg/http/lib/http.dart' as http;
import 'directory_tree.dart';
import 'git.dart' as git;
import 'io.dart';
import 'log.dart' as log;
import 'oauth2.dart' as oauth2;
import 'path.dart' as path;
import 'pub.dart';
import 'validator.dart';

/// Handles the `lish` and `publish` pub commands.
class LishCommand extends PubCommand {
  final description = "Publish the current package to pub.dartlang.org.";
  final usage = "pub publish [options]";
  final aliases = const ["lish", "lush"];

  ArgParser get commandParser {
    var parser = new ArgParser();
    parser.addOption('server', defaultsTo: 'https://pub.dartlang.org',
        help: 'The package server to which to upload this package');
    return parser;
  }

  /// The URL of the server to which to upload the package.
  Uri get server => new Uri.fromString(commandOptions['server']);

  Future _publish(packageBytes) {
    var cloudStorageUrl;
    return oauth2.withClient(cache, (client) {
      // TODO(nweiz): Cloud Storage can provide an XML-formatted error. We
      // should report that error and exit.
      var newUri = server.resolve("/packages/versions/new.json");
      return client.get(newUri).chain((response) {
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
        log.message(parsed['success']['message']);
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
      } else if (e is oauth2.ExpirationException) {
        log.error("Pub's authorization to upload packages has expired and "
        "can't be automatically refreshed.");
        return _publish(packageBytes);
      } else if (e is oauth2.AuthorizationException) {
        var message = "OAuth2 authorization failed";
        if (e.description != null) message = "$message (${e.description})";
        log.error("$message.");
        return oauth2.clearCredentials(cache).chain((_) =>
            _publish(packageBytes));
      } else {
        throw e;
      }
    });
  }

  Future onRun() {
    var files;
    return _filesToPublish.transform((f) {
      files = f;
      log.fine('Archiving and publishing ${entrypoint.root}.');
      return createTarGz(files, baseDir: entrypoint.root.dir);
    }).chain(consumeInputStream).chain((packageBytes) {
      // Show the package contents so the user can verify they look OK.
      var package = entrypoint.root;
      log.message(
          'Publishing "${package.name}" ${package.version}:\n'
          '${generateTree(files)}');

      // Validate the package.
      return _validate().chain((_) => _publish(packageBytes));
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

    // TODO(rnystrom): listDir() returns real file paths after symlinks are
    // resolved. This means if libDir contains a symlink, the resulting paths
    // won't appear to be within it, which confuses relativeTo(). Work around
    // that here by making sure we have the real path to libDir. Remove this
    // when #7346 is fixed.
    rootDir = new File(rootDir).fullPathSync();

    return Futures.wait([
      dirExists(join(rootDir, '.git')),
      git.isInstalled
    ]).chain((results) {
      if (results[0] && results[1]) {
        // List all files that aren't gitignored, including those not checked
        // in to Git.
        return git.run(["ls-files", "--cached", "--others",
                        "--exclude-standard"]);
      }

      return listDir(rootDir, recursive: true).chain((entries) {
        return Futures.wait(entries.map((entry) {
          return fileExists(entry).transform((isFile) {
            // Skip directories.
            if (!isFile) return null;

            // TODO(rnystrom): Making these relative will break archive
            // creation if the cwd is ever *not* the package root directory.
            // Should instead only make these relative right before generating
            // the tree display (which is what really needs them to be).
            // Make it relative to the package root.
            entry = relativeTo(entry, rootDir);

            // TODO(rnystrom): dir.list() will include paths with resolved
            // symlinks. In particular, we'll get paths to symlinked files from
            // "packages" that reach outside of this package. Since the path
            // has already been resolved, we don't even see "packages" in that
            // path anymore.
            // These should not be included in the archive. As a hack, ignore
            // any file whose relative path is backing out of the root
            // directory. Should do something cleaner.
            var parts = path.split(entry);
            if (!parts.isEmpty && parts[0] == '..') return null;

            return entry;
          });
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

  /// Validates the package. Throws an exception if it's invalid.
  Future _validate() {
    return Validator.runAll(entrypoint).chain((pair) {
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

      return confirm(message).transform((confirmed) {
        if (!confirmed) throw "Package upload canceled.";
      });
    });
  }
}
