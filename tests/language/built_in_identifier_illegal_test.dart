// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// Pseudo keywords are not allowed to be used as class names.
class abstract { } //   //# 01: compile-time error
class as { } //         //# 19: compile-time error
class dynamic { } //    //# 04: compile-time error
class export { } //     //# 17: compile-time error
class external { } //   //# 20: compile-time error
class factory { } //    //# 05: compile-time error
class get { } //        //# 06: compile-time error
class implements { } // //# 07: compile-time error
class import { } //     //# 08: compile-time error
class library { } //    //# 10: compile-time error
class operator { } //   //# 12: compile-time error
class part { } //       //# 18: compile-time error
class set { } //        //# 13: compile-time error
class static { } //     //# 15: compile-time error
class typedef { } //    //# 16: compile-time error

main() {}
