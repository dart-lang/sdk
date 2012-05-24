// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('command_update');

#import('pub.dart');

/** Handles the `update` pub command. */
// TODO(nweiz): Make update do something different than install when we have
// sources for which that makes sense.
class UpdateCommand extends PubCommand {
  String get description() =>
    "update the current package's dependencies to the latest versions";

  Future onRun() {
    print("Not implemented.");
  }
}
