// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_adjacent_string_concatenation`

main() {
  String string1 = 'hola means' + // LINT
      ' hello in spanish';

  String string2 = 'hola means' // OK
      ' hello in spanish';

  List<String> list = ['this is' + // LINT
      ' not allowed'
  ];

  String prefix = 'this is';

  String string3 = prefix + ' perfectly fine'; // OK

  String string4 = prefix + 'really' + string3; // OK

  String string5 = 'but this' + ' not'; // LINT
}
