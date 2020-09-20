// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:foo/foo.dart';

// Version comes from the package foo having this file in it's root uri.

/*library: 
 languageVersion=2.5,
 packageUri=package:foo
*/

main() {
  foo();
}
