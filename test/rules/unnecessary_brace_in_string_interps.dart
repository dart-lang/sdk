// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_brace_in_string_interps`

main(args) {
  print('hello');
  print('hello $args');
  print('hello $args!');
  print('hello ${args}1');
  print('hello ${args}'); //LINT [16:7]
  print('hello ${args}!'); //LINT
  print('hello ${args.length}');
  print('hello _${args}_');
  var $someString = 'Some Value';
  print('Value is: ${$someString}'); //OK
}
