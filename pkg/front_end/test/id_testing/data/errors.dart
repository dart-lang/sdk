// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: file=main.dart*/

/*cfe.member: main:main*/
main() {
  // ignore: undefined_function
  /*error: Method not found: 'foo'.*/ foo();
}
