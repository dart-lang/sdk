// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we cannot use a pseudo keyword at the class level code.

// Pseudo keywords are not allowed to be used as class names.
class abstract { } //   //# 01: syntax error
class as { } //         //# 19: syntax error
class dynamic { } //    //# 04: compile-time error
class export { } //     //# 17: syntax error
class external { } //   //# 20: syntax error
class factory { } //    //# 05: syntax error
class get { } //        //# 06: syntax error
class implements { } // //# 07: syntax error
class import { } //     //# 08: syntax error
class library { } //    //# 10: syntax error
class operator { } //   //# 12: syntax error
class part { } //       //# 18: syntax error
class set { } //        //# 13: syntax error
class static { } //     //# 15: syntax error
class typedef { } //    //# 16: syntax error

main() {}
