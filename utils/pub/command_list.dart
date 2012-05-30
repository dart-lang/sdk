// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('command_list');

#import('package.dart');
#import('pub.dart');

/**
 * Handles the `list` pub command. This is mostly just used so we can pull
 * some basic data out of pub in the integration tests. Once pub is more
 * full-featured and has other commands that test everything it does, this
 * may go away.
 */
class ListCommand extends PubCommand {
  String get description() => 'print the contents of repositories';

  Future onRun() {
    // TODO(nweiz): also list the contents of the packages directory when it's
    // able to determine the source of its packages (that is, when we have a
    // lockfile).
    return cache.listAll().transform((ids) {
      _printIds('system cache', ids);
    });
  }

  _printIds(String title, List<PackageId> ids) {
    ids = new List<PackageId>.from(ids);
    ids.sort((a, b) => a.compareTo(b));

    print('From $title:');
    for (var id in ids) {
      print('  $id');
    }
  }
}
