// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

nullAwareListSpread(List<String> list) {
  /*cfe.update: List<String>*/
  /*cfe:nnbd.update: List<String!>!*/
  list =
      /*cfe.List<String>*/
      /*cfe:nnbd.List<String!>!*/
      [
    /*cfe.String*/
    /*cfe:nnbd.String!*/
    'foo',
    ...?
    /*cfe.List<String>*/
    /*cfe:nnbd.List<String!>!*/
    /*invoke: void*/ list
  ];
}

nullAwareSetSpread(Set<String> set) {
  /*cfe.update: Set<String>*/
  /*cfe:nnbd.update: Set<String!>!*/
  set =
      /*cfe.Set<String>*/
      /*cfe:nnbd.Set<String!>!*/
      {
    /*cfe.String*/
    /*cfe:nnbd.String!*/
    'foo',
    ...?
    /*cfe.Set<String>*/
    /*cfe:nnbd.Set<String!>!*/
    /*invoke: void*/ set
  };
}

nullAwareMapSpread(Map<int, String> map) {
  /*cfe.update: Map<int,String>*/
  /*cfe:nnbd.update: Map<int!,String!>!*/
  map =
      /*cfe.Map<int,String>*/
      /*cfe:nnbd.Map<int!,String!>!*/
      {
    /*cfe.int*/
    /*cfe:nnbd.int!*/
    0 /*update: void*/ :
        /*cfe.String*/
        /*cfe:nnbd.String!*/
        'foo',
    ...?
    /*cfe.Map<int,String>|Iterable<MapEntry<int,String>!>!|int|String*/
    /*cfe:nnbd.Map<int!,String!>!|Iterable<MapEntry<int!,String!>!>!|int!|String!*/
    /*cfe.current: MapEntry<int,String>!*/
    /*cfe:nnbd.current: MapEntry<int!,String!>!*/
    /*update: void*/
    map
  };
}
