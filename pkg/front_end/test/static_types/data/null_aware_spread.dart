// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe|dart2js.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

nullAwareListSpread(List<String> list) {
  /*cfe|dart2js.update: List<String>*/
  /*cfe:nnbd.update: List<String!>!*/
  list =
      /*cfe|dart2js.List<String>*/
      /*cfe:nnbd.List<String!>!*/
      [
    /*invoke: void*/
    /*cfe|dart2js.String*/
    /*cfe:nnbd.String!*/
    'foo',
    /*invoke: void*/
    /*current: String*/
    ...?
    /*cfe|dart2js.List<String>*/
    /*cfe:nnbd.List<String!>!*/
    list
  ];
}

nullAwareSetSpread(Set<String> set) {
  /*cfe|dart2js.update: Set<String>*/
  /*cfe:nnbd.update: Set<String!>!*/
  set =
      /*invoke: LinkedHashSet<String>*/
      /*cfe|dart2js.<String>*/
      /*cfe:nnbd.<String!>*/
      {
    /*invoke: bool*/
    /*cfe|dart2js.String*/
    /*cfe:nnbd.String!*/
    'foo',
    /*invoke: bool*/
    /*current: String*/
    ...?
    /*cfe|dart2js.Set<String>*/
    /*cfe:nnbd.Set<String!>!*/
    set
  };
}

nullAwareMapSpread(Map<int, String> map) {
  /*cfe|dart2js.update: Map<int,String>*/
  /*cfe:nnbd.update: Map<int!,String!>!*/
  map =
      /*cfe|dart2js.Map<int,String>*/
      /*cfe:nnbd.Map<int!,String!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0 /*update: void*/ :
        /*cfe|dart2js.String*/
        /*cfe:nnbd.String!*/
        'foo',
    ...?
    /*cfe|dart2js.
     Map<int,String>
     |Iterable<MapEntry<int,String>>
     |int
     |String
    */
    /*cfe:nnbd.
     Map<int!,String!>!
     |Iterable<MapEntry<int,String>>
     |int
     |String
    */
    /*current: MapEntry<int,String>*/
    /*update: void*/
    map
  };
}
