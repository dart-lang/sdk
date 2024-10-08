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

import "dart:core" // Fine unless imported with a built-in identifier as prefix.
deferred as abstract //    //# deferred-abstract: syntax error
deferred as as //          //# deferred-as: syntax error
deferred as covariant //   //# deferred-covariant: syntax error
deferred as deferred //    //# deferred-deferred: syntax error
deferred as dynamic //     //# deferred-dynamic: compile-time error
deferred as export //      //# deferred-export: syntax error
deferred as external //    //# deferred-external: syntax error
deferred as factory //     //# deferred-factory: syntax error
deferred as get //         //# deferred-get: syntax error
deferred as implements //  //# deferred-implements: syntax error
deferred as import //      //# deferred-import: syntax error
deferred as interface //   //# deferred-interface: syntax error
deferred as library //     //# deferred-library: syntax error
deferred as mixin //       //# deferred-mixin: syntax error
deferred as operator //    //# deferred-operator: syntax error
deferred as part //        //# deferred-part: syntax error
deferred as set //         //# deferred-set: syntax error
deferred as static //      //# deferred-static: syntax error
deferred as typedef //     //# deferred-typedef: syntax error
as abstract //             //# abstract: syntax error
as as //                   //# as: syntax error
as covariant //            //# covariant: syntax error
as deferred //             //# deferred: syntax error
as dynamic //              //# dynamic: compile-time error
as export //               //# export: syntax error
as external //             //# external: syntax error
as factory //              //# factory: syntax error
as get //                  //# get: syntax error
as implements //           //# implements: syntax error
as import //               //# import: syntax error
as interface //            //# interface: syntax error
as library //              //# library: syntax error
as mixin //                //# mixin: syntax error
as operator //             //# operator: syntax error
as part //                 //# part: syntax error
as set //                  //# set: syntax error
as static //               //# static: syntax error
as typedef //              //# typedef: syntax error
;

main() {
}
