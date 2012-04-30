// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Handles the `list` pub command. This is mostly just used so we can pull
 * some basic data out of pub in the integration tests. Once pub is more
 * full-featured and has other commands that test everything it does, this
 * may go away.
 */
class ListCommand extends PubCommand {
  String get description() => 'print the contents of repositories';

  void onRun() {
    cache.listAll().then((packages) {
      packages.sort((a, b) => a.name.compareTo(b.name));
      for (final package in packages) {
        print(package.name);
      }
    });
  }
}
