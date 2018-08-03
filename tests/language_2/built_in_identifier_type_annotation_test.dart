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

final // optional type before variable must not be a built-in identifier.
abstract //              //# abstract: syntax error
as //                    //# as: syntax error
covariant //             //# covariant: syntax error
deferred //              //# deferred: syntax error
dynamic //               //# dynamic: ok
export //                //# export: syntax error
external //              //# external: syntax error
factory //               //# factory: syntax error
get //                   //# get: syntax error
implements //            //# implements: syntax error
import //                //# import: syntax error
interface //             //# interface: syntax error
library //               //# library: syntax error
mixin //                 //# mixin: syntax error
operator //              //# operator: syntax error
part //                  //# part: syntax error
set //                   //# set: syntax error
static //                //# static: syntax error
typedef //               //# typedef: syntax error

abstract<int> //         //# abstract-gen: syntax error
as<int> //               //# as-gen: syntax error
covariant<int> //        //# covariant-gen: syntax error
deferred<int> //         //# deferred-gen: syntax error
dynamic<int> //          //# dynamic-gen: compile-time error
export<int> //           //# export-gen: syntax error
external<int> //         //# external-gen: syntax error
factory<int> //          //# factory-gen: syntax error
get<int> //              //# get-gen: syntax error
implements<int> //       //# implements-gen: syntax error
import<int> //           //# import-gen: syntax error
interface<int> //        //# interface-gen: syntax error
library<int> //          //# library-gen: syntax error
mixin<int> //            //# mixin-gen: syntax error
operator<int> //         //# operator-gen: syntax error
part<int> //             //# part-gen: syntax error
set<int> //              //# set-gen: syntax error
static<int> //           //# static-gen: syntax error
typedef<int> //          //# typedef-gen: syntax error

List<abstract> //        //# abstract-list: syntax error
List<as> //              //# as-list: syntax error
List<covariant> //       //# covariant-list: syntax error
List<deferred> //        //# deferred-list: syntax error
List<dynamic> //         //# dynamic-list: ok
List<export> //          //# export-list: syntax error
List<external> //        //# external-list: syntax error
List<factory> //         //# factory-list: syntax error
List<get> //             //# get-list: syntax error
List<implements> //      //# implements-list: syntax error
List<import> //          //# import-list: syntax error
List<interface> //       //# interface-list: syntax error
List<library> //         //# library-list: syntax error
List<mixin> //           //# mixin-list: syntax error
List<operator> //        //# operator-list: syntax error
List<part> //            //# part-list: syntax error
List<set> //             //# set-list: syntax error
List<static> //          //# static-list: syntax error
List<typedef> //         //# typedef-list: syntax error

Function(abstract) //    //# abstract-funarg: syntax error
Function(as) //          //# as-funarg: syntax error
Function(covariant) //   //# covariant-funarg: syntax error
Function(deferred) //    //# deferred-funarg: syntax error
Function(dynamic) //     //# dynamic-funarg: ok
Function(export) //      //# export-funarg: syntax error
Function(external) //    //# external-funarg: syntax error
Function(factory) //     //# factory-funarg: syntax error
Function(get) //         //# get-funarg: syntax error
Function(implements) //  //# implements-funarg: syntax error
Function(import) //      //# import-funarg: syntax error
Function(interface) //   //# interface-funarg: syntax error
Function(library) //     //# library-funarg: syntax error
Function(mixin) //       //# mixin-funarg: syntax error
Function(operator) //    //# operator-funarg: syntax error
Function(part) //        //# part-funarg: syntax error
Function(set) //         //# set-funarg: syntax error
Function(static) //      //# static-funarg: syntax error
Function(typedef) //     //# typedef-funarg: syntax error

abstract Function() //   //# abstract-funret: syntax error
as Function() //         //# as-funret: syntax error
covariant Function() //  //# covariant-funret: syntax error
deferred Function() //   //# deferred-funret: syntax error
dynamic Function() //    //# dynamic-funret: ok
export Function() //     //# export-funret: syntax error
external Function() //   //# external-funret: syntax error
factory Function() //    //# factory-funret: syntax error
get Function() //        //# get-funret: syntax error
implements Function() // //# implements-funret: syntax error
import Function() //     //# import-funret: syntax error
interface Function() //  //# interface-funret: syntax error
library Function() //    //# library-funret: syntax error
mixin Function() //      //# mixin-funret: syntax error
operator Function() //   //# operator-funret: syntax error
part Function() //       //# part-funret: syntax error
set Function() //        //# set-funret: syntax error
static Function() //     //# static-funret: syntax error
typedef Function() //    //# typedef-funret: syntax error

x = null;

main() {
  x.toString();
}
