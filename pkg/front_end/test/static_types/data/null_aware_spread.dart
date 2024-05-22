// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
nullAwareListSpread(List<String> list) {
  /*update: List<String!>!*/
  list =
      /*List<String!>!*/
      [
    /*String!*/
    'foo',
    ...?
    /*List<String!>!*/
    /*invoke: void*/ list
  ];
}

nullAwareSetSpread(Set<String> set) {
  /*update: Set<String!>!*/
  set =
      /*Set<String!>!*/
      {
    /*String!*/
    'foo',
    ...?
    /*Set<String!>!*/
    /*invoke: void*/ set
  };
}

nullAwareMapSpread(Map<int, String> map) {
  /*update: Map<int!,String!>!*/
  map =
      /*Map<int!,String!>!*/
      {
    /*int!*/
    0 /*update: void*/ :
        /*String!*/
        'foo',
    ...?
    /*Map<int!,String!>!*/
    /*invoke: void*/ map
  };
}
