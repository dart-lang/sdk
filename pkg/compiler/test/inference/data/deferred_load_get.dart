// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart' deferred as expect;

// Synthetic getter added by kernel.

/*member: _#loadLibrary_expect:[exact=_Future|powerset=0]*/

/*member: main:[null|powerset=1]*/
main() {
  tearOffLoadLibrary();
}

/*member: tearOffLoadLibrary:[subclass=Closure|powerset=0]*/
tearOffLoadLibrary() => expect.loadLibrary;
