// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  /*member: Class._#new#tearOff:
   tearoffConstructor,
   tearoffLowering
  */
  Class();

  /*member: Class._#fact#tearOff:
   tearoffConstructor,
   tearoffLowering
  */
  factory Class.fact() => new Class();

  /*member: Class._#redirect#tearOff:
   tearoffConstructor,
   tearoffLowering
  */
  factory Class.redirect() = Class;
}

/*member: _#Typedef#new#tearOff:
 tearoffLowering,
 tearoffTypedef
*/
/*member: _#Typedef#fact#tearOff:
tearoffLowering,
tearoffTypedef
*/
/*member: _#Typedef#redirect#tearOff:
 tearoffLowering,
 tearoffTypedef
*/
typedef Typedef<T extends num> = Class<T>;

main() {}
