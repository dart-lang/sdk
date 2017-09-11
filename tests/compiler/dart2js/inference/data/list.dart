// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  emptyList();
  nullList();
  constList();
  constNullList();
}

/*element: emptyList:Container mask: [empty] length: 0 type: [exact=JSExtendableArray]*/
emptyList() => [];

/*element: constList:Container mask: [empty] length: 0 type: [exact=JSUnmodifiableArray]*/
constList() => const [];

/*element: nullList:Container mask: [null] length: 1 type: [exact=JSExtendableArray]*/
nullList() => [null];

/*element: constNullList:Container mask: [null] length: 1 type: [exact=JSUnmodifiableArray]*/
constNullList() => const [null];
