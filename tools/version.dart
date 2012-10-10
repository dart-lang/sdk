// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("testing/dart/version.dart");

void main() {
  Version version = new Version("tools/VERSION");
  Future f = version.getVersion();
  f.then((currentVersion) {
    print(currentVersion);
  });
  f.handleException((e) {
    print("Could not create version number, failed with: $e");
    return true;
  });
}
