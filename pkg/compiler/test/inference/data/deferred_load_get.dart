// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart' deferred as expect;

// Synthetic getter added by kernel.

/*member: _#loadLibrary_expect:[exact=_Future]*/

/*member: main:[null]*/
main() {
  tearOffLoadLibrary();
}

/*member: tearOffLoadLibrary:[subclass=Closure]*/
tearOffLoadLibrary() => expect.loadLibrary;
