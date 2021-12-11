// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/

/*cfe:nnbd.library: nnbd=true*/

/*class: Interface:
 isAbstract,
 kernel-members=[
  Interface.,
  interfaceMethod],
 scope=[interfaceMethod]
*/
/*member: Interface.:initializers=[SuperInitializer]*/
abstract class Interface {
  void interfaceMethod();
}

/*class: Class:
 isAbstract,
 kernel-members=[
  Class.,
  classMethod],
 scope=[classMethod]
*/
/*member: Class.:initializers=[SuperInitializer]*/
abstract class Class implements Interface {
  external void classMethod();
}
