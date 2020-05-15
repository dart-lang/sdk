// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A<T> {}

/*spec:nnbd-off|prod:nnbd-off.class: B:explicit=[B<int>],needsArgs*/
/*spec:nnbd-sdk|prod:nnbd-sdk.class: B:explicit=[B<int*>*],needsArgs*/
class B<T> extends A<T> {}

main() {
  new B<int>() is B<int>;
}
