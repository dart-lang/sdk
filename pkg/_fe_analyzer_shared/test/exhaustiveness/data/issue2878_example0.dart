// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  List<int> list = [1, 2, 3];

  (/*
   checkingOrder={List<int>,<int>[...]},
   subtypes={<int>[...]},
   type=List<int>
  */
      switch (list) {
    [...] /*space=<[...List<int>]>*/ => 1,
  });

  (/*
   checkingOrder={List<int>,<int>[],<int>[(), ...]},
   subtypes={<int>[],<int>[(), ...]},
   type=List<int>
  */
      switch (list) {
    [] /*space=<[]>*/ => 1,
    [_, ...] /*space=<[int, ...List<int>]>*/ => 2,
  });

  (/*
   checkingOrder={List<int>,<int>[],<int>[()],<int>[(), (), ...]},
   subtypes={<int>[],<int>[()],<int>[(), (), ...]},
   type=List<int>
  */
      switch (list) {
    [] /*space=<[]>*/ => 1,
    [_] /*space=<[int]>*/ => 2,
    [_, ..., _] /*space=<[int, ...List<int>, int]>*/ => 3,
  });
}
