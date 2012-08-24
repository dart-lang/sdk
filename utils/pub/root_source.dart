// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('root_source');

#import('package.dart');
#import('pubspec.dart');
#import('source.dart');

/**
 * A source used only for the root package when doing version resolution. It
 * contains only the root package and is unable to install packages.
 *
 * This source cannot be referenced from a pubspec.
 */
class RootSource extends Source {
  final String name = "root";
  final bool shouldCache = false;
  final Package package;

  RootSource(this.package);

  Future<Pubspec> describe(PackageId id) {
    return new Future<Pubspec>.immediate(package.pubspec);
  }

  Future<bool> install(PackageId id, String destPath) {
    throw new UnsupportedOperationException(
        "Can't install from a root source.");
  }
}
