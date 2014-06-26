// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.source_directory;

import 'dart:async';

import 'package:watcher/watcher.dart';

import 'asset_environment.dart';
import 'barback_server.dart';

/// A directory in the entrypoint package whose contents have been made
/// available to barback and that are bound to a server.
class SourceDirectory {
  final AssetEnvironment _environment;

  /// The relative directory path within the package.
  final String directory;

  /// The hostname to serve this directory on.
  final String hostname;

  /// The port to serve this directory on.
  final int port;

  /// The server bound to this directory.
  ///
  /// This is a future that will complete once [serve] has been called and the
  /// server has been successfully spun up.
  Future<BarbackServer> get server => _serverCompleter.future;
  final _serverCompleter = new Completer<BarbackServer>();

  /// The subscription to the [DirectoryWatcher] used to watch this directory
  /// for changes.
  ///
  /// If the directory is not being watched, this will be `null`.
  StreamSubscription<WatchEvent> watchSubscription;

  SourceDirectory(this._environment, this.directory, this.hostname, this.port);

  /// Binds a server running on [hostname]:[port] to this directory.
  Future<BarbackServer> serve() {
    return BarbackServer.bind(_environment, hostname, port,
        rootDirectory: directory).then((server) {
      _serverCompleter.complete(server);
      return server;
    });
  }

  /// Removes the source directory from the build environment.
  ///
  /// Closes the server, removes the assets from barback, and stops watching it.
  Future close() {
    return server.then((server) {
      var futures = [server.close()];

      // Stop watching the directory.
      if (watchSubscription != null) {
        var cancel = watchSubscription.cancel();
        if (cancel != null) futures.add(cancel);
      }

      return Future.wait(futures);
    });
  }
}
