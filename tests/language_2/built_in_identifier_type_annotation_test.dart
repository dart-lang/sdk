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
// Observation: it is illegal to use a built-in identifier other than
// `dynamic` in a type annotation. A type annotation is not fully defined
// in the specification, so we assume this means that the grammar
// production "type" cannot be a built-in identifier, and it cannot contain
// a built-in identifier at a location where it must denote a type.
//
// Note that we have several ways to use built-in identifiers other than
// `dynamic` in other locations in a type, e.g., `Function(int set)`.

abstract x = null; //              //# 01: syntax error
as x = null; //                    //# 02: syntax error
covariant x = null; //             //# 03: syntax error
deferred x = null; //              //# 04: syntax error
dynamic x = null; //               //# 05: ok
export x = null; //                //# 06: syntax error
external x = null; //              //# 07: syntax error
factory x = null; //               //# 08: syntax error
get x = null; //                   //# 09: syntax error
implements x = null; //            //# 10: syntax error
import x = null; //                //# 11: syntax error
library x = null; //               //# 12: syntax error
operator x = null; //              //# 13: syntax error
part x = null; //                  //# 14: syntax error
set x = null; //                   //# 15: syntax error
static x = null; //                //# 16: syntax error
typedef x = null; //               //# 17: syntax error

abstract<int> x = null; //         //# 18: syntax error
as<int> x = null; //               //# 19: syntax error
covariant<int> x = null; //        //# 20: syntax error
deferred<int> x = null; //         //# 21: syntax error
dynamic<int> x = null; //          //# 22: compile-time error
export<int> x = null; //           //# 23: syntax error
external<int> x = null; //         //# 24: syntax error
factory<int> x = null; //          //# 25: syntax error
get<int> x = null; //              //# 26: syntax error
implements<int> x = null; //       //# 27: syntax error
import<int> x = null; //           //# 28: syntax error
library<int> x = null; //          //# 29: syntax error
operator<int> x = null; //         //# 30: syntax error
part<int> x = null; //             //# 31: syntax error
set<int> x = null; //              //# 32: syntax error
static<int> x = null; //           //# 33: syntax error
typedef<int> x = null; //          //# 34: syntax error

List<abstract> x = null; //        //# 35: syntax error
List<as> x = null; //              //# 36: syntax error
List<covariant> x = null; //       //# 37: syntax error
List<deferred> x = null; //        //# 38: syntax error
List<dynamic> x = null; //         //# 39: ok
List<export> x = null; //          //# 40: syntax error
List<external> x = null; //        //# 41: syntax error
List<factory> x = null; //         //# 42: syntax error
List<get> x = null; //             //# 43: syntax error
List<implements> x = null; //      //# 44: syntax error
List<import> x = null; //          //# 45: syntax error
List<library> x = null; //         //# 46: syntax error
List<operator> x = null; //        //# 47: syntax error
List<part> x = null; //            //# 48: syntax error
List<set> x = null; //             //# 49: syntax error
List<static> x = null; //          //# 50: syntax error
List<typedef> x = null; //         //# 51: syntax error

Function(abstract) x = null; //    //# 52: syntax error
Function(as) x = null; //          //# 53: syntax error
Function(covariant) x = null; //   //# 54: syntax error
Function(deferred) x = null; //    //# 55: syntax error
Function(dynamic) x = null; //     //# 56: ok
Function(export) x = null; //      //# 57: syntax error
Function(external) x = null; //    //# 58: syntax error
Function(factory) x = null; //     //# 59: syntax error
Function(get) x = null; //         //# 60: syntax error
Function(implements) x = null; //  //# 61: syntax error
Function(import) x = null; //      //# 62: syntax error
Function(library) x = null; //     //# 63: syntax error
Function(operator) x = null; //    //# 64: syntax error
Function(part) x = null; //        //# 65: syntax error
Function(set) x = null; //         //# 66: syntax error
Function(static) x = null; //      //# 67: syntax error
Function(typedef) x = null; //     //# 68: syntax error

abstract Function() x = null; //   //# 69: syntax error
as Function() x = null; //         //# 70: syntax error
covariant Function() x = null; //  //# 71: syntax error
deferred Function() x = null; //   //# 72: syntax error
dynamic Function() x = null; //    //# 73: ok
export Function() x = null; //     //# 74: syntax error
external Function() x = null; //   //# 75: syntax error
factory Function() x = null; //    //# 76: syntax error
get Function() x = null; //        //# 77: syntax error
implements Function() x = null; // //# 78: syntax error
import Function() x = null; //     //# 79: syntax error
library Function() x = null; //    //# 80: syntax error
operator Function() x = null; //   //# 81: syntax error
part Function() x = null; //       //# 82: syntax error
set Function() x = null; //        //# 83: syntax error
static Function() x = null; //     //# 84: syntax error
typedef Function() x = null; //    //# 85: syntax error

main() {
  var x = null; //                 //# none: ok
  x.toString();
}
