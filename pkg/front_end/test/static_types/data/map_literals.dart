// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  // ignore: unused_local_variable
  var a0 =
      /*cfe|dart2js.Map<dynamic,dynamic>*/
      /*cfe:nnbd.Map<dynamic,dynamic>!*/
      {};

  // ignore: unused_local_variable
  var a1 =
      /*cfe|dart2js.Map<int,double>*/
      /*cfe:nnbd.Map<int!,double!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a2 =
      /*cfe|dart2js.Map<double,int>*/
      /*cfe:nnbd.Map<double!,int!>!*/
      {
    /*cfe|dart2js.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        0
  };

  // ignore: unused_local_variable
  var a3 =
      /*cfe|dart2js.Map<int,num>*/
      /*cfe:nnbd.Map<int!,num>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    1:
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        2
  };

  // ignore: unused_local_variable
  var a4 =
      /*cfe|dart2js.Map<num,double>*/
      /*cfe:nnbd.Map<num,double!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a5 =
      /*cfe|dart2js.Map<num,num>*/
      /*cfe:nnbd.Map<num,num>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.double*/
    /*cfe:nnbd.double!*/
    0.5:
        /*cfe|dart2js.int*/
        /*cfe:nnbd.int!*/
        0
  };

  // ignore: unused_local_variable
  var a6 =
      /*cfe|dart2js.Map<int,Object>*/
      /*cfe:nnbd.Map<int!,Object>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    1:
        /*cfe|dart2js.String*/
        /*cfe:nnbd.String!*/
        ''
  };

  // ignore: unused_local_variable
  var a7 =
      /*cfe|dart2js.Map<Object,double>*/
      /*cfe:nnbd.Map<Object,double!>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.String*/
    /*cfe:nnbd.String!*/
    '':
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5
  };

  // ignore: unused_local_variable
  var a8 =
      /*cfe|dart2js.Map<Object,Object>*/
      /*cfe:nnbd.Map<Object,Object>!*/
      {
    /*cfe|dart2js.int*/
    /*cfe:nnbd.int!*/
    0:
        /*cfe|dart2js.double*/
        /*cfe:nnbd.double!*/
        0.5,
    /*cfe|dart2js.String*/
    /*cfe:nnbd.String!*/
    '':
        /*cfe|dart2js.String*/
        /*cfe:nnbd.String!*/
        ''
  };
}
