// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('command_update');

#import('entrypoint.dart');
#import('pub.dart');

/** Handles the `update` pub command. */
class UpdateCommand extends PubCommand {
  String get description() =>
    "update the current package's dependencies to the latest versions";

  String get usage() => 'pub update';

  Future onRun() {
    return entrypoint.updateDependencies().transform((_) {
      print("Dependencies updated!");
    });
  }
}
