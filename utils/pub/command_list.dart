// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Handles the `list` pub command. */
void commandList(PubOptions options, List<String> args) {
  // TODO(rnystrom): Validate args. Right now, this just lists the packages in
  // your cache.
  final cache = new PackageCache(options.cacheDir);
  cache.listAll().then((packages) {
    packages.sort((a, b) => a.name.compareTo(b.name));
    for (final package in packages) {
      print(package.name);
    }
  });
}