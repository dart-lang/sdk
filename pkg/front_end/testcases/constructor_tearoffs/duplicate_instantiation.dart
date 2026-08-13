// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  Class();
  Class.named();
}

test() {
  Class<int>;
  Class<int>();
  Class<int><int>;
  Class<int><int>();
  Class<int>.named;
  Class<int>.named();
  Class<int>.named<int>;
  Class<int>.named<int>();
  Class<int><int>.named;
  Class<int><int>.named();
  Class<int><int>.named<int>;
  Class<int><int>.named<int>();
  Class<int><int>.named<int><int>;
  Class<int><int>.named<int><int>();
}

main() {}