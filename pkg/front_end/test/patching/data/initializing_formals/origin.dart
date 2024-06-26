// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: PatchedClass:
 kernel-members=[
  PatchedClass.,
  _privateField,
  publicField],
 scope=[
  _privateField,
  publicField]
*/
class PatchedClass {
  int publicField;

  external PatchedClass(publicField, privateField);
}
