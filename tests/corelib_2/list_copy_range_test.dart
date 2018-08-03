// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";
import "package:expect/expect.dart";

// Tests of List.copyRange.

void main() {
  var list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  List.copyRange(list, 3, [10, 11, 12, 13], 0, 4);

  Expect.listEquals([0, 1, 2, 10, 11, 12, 13, 7, 8, 9], list);

  List.copyRange(list, 6, [20, 21, 22, 23], 1, 3);

  Expect.listEquals([0, 1, 2, 10, 11, 12, 21, 22, 8, 9], list);

  // Empty ranges won't change anything.
  List.copyRange(list, 7, [30, 31, 32, 33], 3, 3);
  List.copyRange(list, list.length, [30, 31, 32, 33], 3, 3);

  Expect.listEquals([0, 1, 2, 10, 11, 12, 21, 22, 8, 9], list);

  List.copyRange(list, 0, [40, 41, 42, 43], 0, 2);

  Expect.listEquals([40, 41, 2, 10, 11, 12, 21, 22, 8, 9], list);

  // Overlapping self-ranges

  List.copyRange(list, 2, list, 0, 4);

  Expect.listEquals([40, 41, 40, 41, 2, 10, 21, 22, 8, 9], list);

  List.copyRange(list, 4, list, 6, 10);

  Expect.listEquals([40, 41, 40, 41, 21, 22, 8, 9, 8, 9], list);

  // Invalid source ranges.

  Expect.throwsArgumentError(() {
    List.copyRange(list, 0, [0, 0, 0], -1, 1);
  });

  Expect.throwsArgumentError(() {
    List.copyRange(list, 0, [0, 0, 0], 0, 4);
  });

  Expect.throwsArgumentError(() {
    List.copyRange(list, 0, [0, 0, 0], 2, 1);
  });

  Expect.throwsArgumentError(() {
    List.copyRange(list, 0, [], 1, 1);
  });

  // Invalid target range.
  Expect.throwsArgumentError(() {
    List.copyRange(list, list.length - 3, [0, 0, 0, 0], 0, 4);
  });

  // Invalid target range.
  Expect.throwsArgumentError(() {
    List.copyRange(list, list.length + 1, [0, 0, 0, 0], 0, 0);
  });

  // Argument errors throw before changing anything, so list is unchanged.
  Expect.listEquals([40, 41, 40, 41, 21, 22, 8, 9, 8, 9], list);

  // Omitting start/end (or passing null).
  List.copyRange(list, 2, [1, 2, 3]);

  Expect.listEquals([40, 41, 1, 2, 3, 22, 8, 9, 8, 9], list);

  List.copyRange(list, 5, [1, 2, 3], 1);

  Expect.listEquals([40, 41, 1, 2, 3, 2, 3, 9, 8, 9], list);

  // Other kinds of lists.
  var listu8 = new Uint8List.fromList([1, 2, 3, 4]);
  var list16 = new Int16List.fromList([11, 12, -13, -14]);
  List.copyRange(listu8, 2, list16, 1, 3);
  Expect.listEquals([1, 2, 12, 256 - 13], listu8);

  var clist = const <int>[1, 2, 3, 4];
  var flist = new List<int>(4)..setAll(0, [10, 11, 12, 13]);
  List.copyRange(flist, 1, clist, 1, 3);
  Expect.listEquals([10, 2, 3, 13], flist);

  // Invoking with a type parameter that is a supertype of the list types
  // is valid and useful.
  List<int> ilist = <int>[1, 2, 3, 4];
  List<num> nlist = <num>[11, 12, 13, 14];

  List.copyRange<num>(ilist, 1, nlist, 1, 3);
  Expect.listEquals([1, 12, 13, 4], ilist);
  List.copyRange<Object>(ilist, 1, nlist, 0, 2);
  Expect.listEquals([1, 11, 12, 4], ilist);
  List.copyRange<dynamic>(ilist, 1, nlist, 2, 4);
  Expect.listEquals([1, 13, 14, 4], ilist);

  var d = new D();
  List<B> bdlist = <B>[d];
  List<C> cdlist = <C>[null];
  List.copyRange<Object>(cdlist, 0, bdlist, 0, 1);
  Expect.identical(d, cdlist[0]);
}

class B {}

class C {}

class D implements B, C {}
