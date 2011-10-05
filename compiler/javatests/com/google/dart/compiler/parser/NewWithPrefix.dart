// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NewWithPrefix {
  foo() {
    var a = new prefix.Set<String>.named();
    a = new prefix.Set<String>();
    a = const prefix.Set<String>.named();
    a = const prefix.Set<String>();

    a = new prefix.Set.named();
    a = new prefix.Set();
    a = const prefix.Set.named();
    a = const prefix.Set();

    a = new Set<String>.named();
    a = new Set<String>();
    a = const Set<String>.named();
    a = const Set<String>();

    a = new Set.named();
    a = new Set();
    a = const Set.named();
    a = const Set();
  }
}
