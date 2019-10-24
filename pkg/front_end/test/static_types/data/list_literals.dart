// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

main() {
  /*List<dynamic>*/ [];

  /*cfe|dart2js.List<int>*/
  /*cfe:nnbd.List<int!>*/
  [/*int*/ 0];

  /*List<num>*/ [/*int*/ 0, /*double*/ 0.5];

  /*List<Object>*/ [/*int*/ 0, /*String*/ ''];
}
