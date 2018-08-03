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
deferred as abstract //    //# deferred-abstract: compile-time error
deferred as as //          //# deferred-as: compile-time error
deferred as covariant //   //# deferred-covariant: compile-time error
deferred as deferred //    //# deferred-deferred: compile-time error
deferred as dynamic //     //# deferred-dynamic: compile-time error
deferred as export //      //# deferred-export: compile-time error
deferred as external //    //# deferred-external: compile-time error
deferred as factory //     //# deferred-factory: compile-time error
deferred as get //         //# deferred-get: compile-time error
deferred as implements //  //# deferred-implements: compile-time error
deferred as import //      //# deferred-import: compile-time error
deferred as interface //   //# deferred-interface: compile-time error
deferred as library //     //# deferred-library: compile-time error
deferred as mixin //       //# deferred-mixin: compile-time error
deferred as operator //    //# deferred-operator: compile-time error
deferred as part //        //# deferred-part: compile-time error
deferred as set //         //# deferred-set: compile-time error
deferred as static //      //# deferred-static: compile-time error
deferred as typedef //     //# deferred-typedef: compile-time error
as abstract //             //# abstract: compile-time error
as as //                   //# as: compile-time error
as covariant //            //# covariant: compile-time error
as deferred //             //# deferred: compile-time error
as dynamic //              //# dynamic: compile-time error
as export //               //# export: compile-time error
as external //             //# external: compile-time error
as factory //              //# factory: compile-time error
as get //                  //# get: compile-time error
as implements //           //# implements: compile-time error
as import //               //# import: compile-time error
as interface //            //# interface: compile-time error
as library //              //# library: compile-time error
as mixin //                //# mixin: compile-time error
as operator //             //# operator: compile-time error
as part //                 //# part: compile-time error
as set //                  //# set: compile-time error
as static //               //# static: compile-time error
as typedef //              //# typedef: compile-time error
;

main() {
}
