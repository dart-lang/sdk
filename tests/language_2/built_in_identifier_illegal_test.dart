// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// Pseudo keywords are not allowed to be used as class names.
class abstract { } //   //# abstract: syntax error
class as { } //         //# as: syntax error
class dynamic { } //    //# dynamic: compile-time error
class export { } //     //# export: syntax error
class external { } //   //# external: syntax error
class factory { } //    //# factory: syntax error
class get { } //        //# get: syntax error
class interface { } //  //# interface: syntax error
class implements { } // //# implements: syntax error
class import { } //     //# import: syntax error
class mixin { } //      //# mixin: syntax error
class library { } //    //# library: syntax error
class operator { } //   //# operator: syntax error
class part { } //       //# part: syntax error
class set { } //        //# set: syntax error
class static { } //     //# static: syntax error
class typedef { } //    //# typedef: syntax error

main() {}
