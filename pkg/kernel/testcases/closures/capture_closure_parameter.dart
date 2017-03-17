// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main(List<String> arguments) {
  foo(x) {
    bar() {
      print(x);
    }

    return bar;
  }

  foo(arguments[0])();
}
