// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--disable_privacy
//
// Dart test program checking that library privacy can be disabled.

#library('DisablePrivacyTest');
#import("disable_privacy_lib.dart");

main() {
  Expect.equals(1, _fooForTesting);
}
