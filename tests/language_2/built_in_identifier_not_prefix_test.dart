// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From The Dart Programming Language Specification, section 16.33
// "Identifier Reference":
//
// "A built-in identifier is one of the identifiers produced by the
// production BUILT_IN_IDENTIFIER. It is a compile-time error if a
// built-in identifier is used as the declared name of a prefix, class,
// type parameter or type alias. It is a compile-time error to use a
// built-in identifier other than dynamic in a type annotation or type
// parameter."
//
// Observation: it is illegal to use a built-in identifier as a library
// prefix.

// Dart test for using a built-in identifier as a library prefix.

import 'dart:core' deferred as abstract; //    //# 01: compile-time error
import 'dart:core' deferred as as; //          //# 02: compile-time error
import 'dart:core' deferred as covariant; //   //# 03: compile-time error
import 'dart:core' deferred as deferred; //    //# 04: compile-time error
import 'dart:core' deferred as dynamic; //     //# 05: compile-time error
import 'dart:core' deferred as export; //      //# 06: compile-time error
import 'dart:core' deferred as external; //    //# 07: compile-time error
import 'dart:core' deferred as factory; //     //# 08: compile-time error
import 'dart:core' deferred as get; //         //# 09: compile-time error
import 'dart:core' deferred as implements; //  //# 10: compile-time error
import 'dart:core' deferred as import; //      //# 11: compile-time error
import 'dart:core' deferred as library; //     //# 12: compile-time error
import 'dart:core' deferred as operator; //    //# 13: compile-time error
import 'dart:core' deferred as part; //        //# 14: compile-time error
import 'dart:core' deferred as set; //         //# 15: compile-time error
import 'dart:core' deferred as static; //      //# 16: compile-time error
import 'dart:core' deferred as typedef; //     //# 17: compile-time error
import 'dart:core' as abstract; //             //# 18: syntax error
import 'dart:core' as as; //                   //# 19: syntax error
import 'dart:core' as covariant; //            //# 20: syntax error
import 'dart:core' as deferred; //             //# 21: syntax error
import 'dart:core' as dynamic; //              //# 22: compile-time error
import 'dart:core' as export; //               //# 23: syntax error
import 'dart:core' as external; //             //# 24: syntax error
import 'dart:core' as factory; //              //# 25: syntax error
import 'dart:core' as get; //                  //# 26: syntax error
import 'dart:core' as implements; //           //# 27: syntax error
import 'dart:core' as import; //               //# 28: syntax error
import 'dart:core' as library; //              //# 29: syntax error
import 'dart:core' as operator; //             //# 30: syntax error
import 'dart:core' as part; //                 //# 31: syntax error
import 'dart:core' as set; //                  //# 32: syntax error
import 'dart:core' as static; //               //# 33: syntax error
import 'dart:core' as typedef; //              //# 34: syntax error

main() {
  abstract.loadLibrary(); //   //# 01: continued
  as.loadLibrary(); //         //# 02: continued
  covariant.loadLibrary(); //  //# 03: continued
  deferred.loadLibrary(); //   //# 04: continued
  dynamic.loadLibrary(); //    //# 05: continued
  export.loadLibrary(); //     //# 06: continued
  external.loadLibrary(); //   //# 07: continued
  factory.loadLibrary(); //    //# 08: continued
  get.loadLibrary(); //        //# 09: continued
  implements.loadLibrary(); // //# 10: continued
  import.loadLibrary(); //     //# 11: continued
  library.loadLibrary(); //    //# 12: continued
  operator.loadLibrary(); //   //# 13: continued
  part.loadLibrary(); //       //# 14: continued
  set.loadLibrary(); //        //# 15: continued
  static.loadLibrary(); //     //# 16: continued
  typedef.loadLibrary(); //    //# 17: continued

  abstract.int x = 42; //      //# 18: continued
  as.int x = 42; //            //# 19: continued
  covariant.int x = 42; //     //# 20: continued
  deferred.int x = 42; //      //# 21: continued
  dynamic.int x = 42; //       //# 22: continued
  export.int x = 42; //        //# 23: continued
  external.int x = 42; //      //# 24: continued
  factory.int x = 42; //       //# 25: continued
  get.int x = 42; //           //# 26: continued
  implements.int x = 42; //    //# 27: continued
  import.int x = 42; //        //# 28: continued
  library.int x = 42; //       //# 29: continued
  operator.int x = 42; //      //# 30: continued
  part.int x = 42; //          //# 31: continued
  set.int x = 42; //           //# 32: continued
  static.int x = 42; //        //# 33: continued
  typedef.int x = 42; //       //# 34: continued
}
