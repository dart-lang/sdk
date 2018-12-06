// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N empty_statements`

bar() {
  if (foo()); //LINT
    bar();

  if (foo()); //LINT
  {
    bar();
  }

  if (foo()) {
    //OK
  }

  while(foo()); //LINT

  while(foo()) {
    //OK
  }

  for ( ; foo(); ); //LINT

}

bool foo() => true;
