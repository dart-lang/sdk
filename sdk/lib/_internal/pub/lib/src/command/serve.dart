// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.serve;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import '../command.dart';
import '../entrypoint.dart';
import '../exit_codes.dart' as exit_codes;
import '../log.dart' as log;
import '../pub_package_provider.dart';
import '../utils.dart';

final _green = getPlatformString('\u001b[32m');
final _red = getPlatformString('\u001b[31m');
final _none = getPlatformString('\u001b[0m');

/// Handles the `serve` pub command.
class ServeCommand extends PubCommand {
  String get description => "Run a local web development server.";
  String get usage => 'pub serve';

  ServeCommand() {
    commandParser.addOption('port', defaultsTo: '8080',
        help: 'The port to listen on.');
  }

  Future onRun() {
    // The completer for the top-level future returned by the command. Only
    // used to keep pub running (by not completing) and to pipe fatal errors
    // to pub's top-level error-handling machinery.
    var completer = new Completer();

    return PubPackageProvider.create(entrypoint).then((provider) {
      var port;
      try {
        port = int.parse(commandOptions['port']);
      } on FormatException catch(_) {
        log.error('Could not parse port "${commandOptions['port']}"');
        this.printUsage();
        exit(exit_codes.USAGE);
      }

      var barback = new Barback(provider);

      barback.results.listen((result) {
        if (result.succeeded) {
          // TODO(rnystrom): Report using growl/inotify-send where available.
          log.message("Build completed ${_green}successfully$_none");
        } else {
          log.message("Build completed with "
              "${_red}${result.errors.length}$_none errors.");
        }
      });

      barback.errors.listen((error) {
        log.error("${_red}Build error:\n$error$_none");
      });

      // TODO(rnystrom): Watch file system and update sources again when they
      // are added or modified.

      HttpServer.bind("localhost", port).then((server) {
        log.message("Serving ${entrypoint.root.name} "
                    "on http://localhost:${server.port}");

        // Add all of the visible files.
        for (var package in provider.packages) {
          barback.updateSources(provider.listAssets(package));
        }

        server.listen((request) {
          var id = getIdFromUri(request.uri);
          if (id == null) {
            return notFound(request, "Path ${request.uri.path} is not valid.");
          }

          barback.getAssetById(id).then((asset) {
            log.message(
                "$_green${request.method}$_none ${request.uri} -> $asset");
            // TODO(rnystrom): Set content-type based on asset type.
            return request.response.addStream(asset.read()).then((_) {
              request.response.close();
            });
            // TODO(rnystrom): Serve up a 500 if we get an error reading the
            // asset.
          }).catchError((error) {
            log.error("$_red${request.method}$_none ${request.uri} -> $error");
            if (error is! AssetNotFoundException) {
              completer.completeError(error);
              return;
            }

            notFound(request, error);
          });
        });
      });

      return completer.future;
    });
  }

  /// Responds to [request] with a 404 response and closes it.
  void notFound(HttpRequest request, message) {
    request.response.statusCode = 404;
    request.response.reasonPhrase = "Not Found";
    request.response.write(message);
    request.response.close();
  }

  AssetId getIdFromUri(Uri uri) {
    var parts = path.url.split(uri.path);

    // Strip the leading "/" from the URL.
    parts.removeAt(0);

    var isSpecial = false;

    // Checks to see if [uri]'s path contains a special directory [name] that
    // identifies an asset within some package. If so, maps the package name
    // and path following that to be within [dir] inside that package.
    AssetId _trySpecialUrl(String name, String dir) {
      // Find the package name and the relative path in the package.
      var index = parts.indexOf(name);
      if (index == -1) return null;

      // If we got here, the path *did* contain the special directory, which
      // means we should not interpret it as a regular path, even if it's
      // missing the package name after it, which makes it invalid here.
      isSpecial = true;
      if (index + 1 >= parts.length) return null;

      var package = parts[index + 1];
      var assetPath = path.url.join(dir,
          path.url.joinAll(parts.skip(index + 2)));
      return new AssetId(package, assetPath);
    }

    // See if it's "packages" URL.
    var id = _trySpecialUrl("packages", "lib");
    if (id != null) return id;

    // See if it's an "assets" URL.
    id = _trySpecialUrl("assets", "asset");
    if (id != null) return id;

    // If we got here, we had a path like "/packages" which is a special
    // directory, but not a valid path since it lacks a following package name.
    if (isSpecial) return null;

    // Otherwise, it's a path in current package's web directory.
    return new AssetId(entrypoint.root.name,
        path.url.join("web", path.url.joinAll(parts)));
  }
}
