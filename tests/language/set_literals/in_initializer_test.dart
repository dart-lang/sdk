// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bag {
  final Set<Object> things;
  Bag({Set<Object>? things}) : this.things = things ?? <Object>{};
  Bag.full({Set<Object> this.things = const {"cat"}});
}

main() {
  new Bag();
  new Bag(things: {});
  new Bag.full();
  new Bag.full(things: {});
}
