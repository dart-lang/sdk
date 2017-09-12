// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

/*element: main:[null]*/
main() {
  generativeConstructorCall();
}

/*element: generativeConstructorCall:[exact=Class]*/
generativeConstructorCall() => new Class();
