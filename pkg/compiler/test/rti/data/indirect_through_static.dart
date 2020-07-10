// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:implicit=[A]*/
abstract class A {}

class B implements A {}

/*spec.class: C:deps=[lookup],explicit=[C<lookup.T*>*,Map<String*,C*>*],implicit=[C],needsArgs*/
/*prod.class: C:deps=[lookup],explicit=[C<lookup.T*>*],needsArgs*/
class C<T> {}

final Map<String, C> map = {};

void setup() {
  map['x'] = new C<B>();
}

/*member: lookup:direct,explicit=[C<lookup.T*>*],needsArgs*/
C<T> lookup<T>(String key) {
  final value = map[key];
  if (value != null && value is C<T>) {
    return value;
  }
  throw 'Invalid C value for $key: ${value}';
}

void lookupA() {
  lookup<A>('x');
}

main() {
  setup();
  lookupA();
}
