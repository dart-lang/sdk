// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class {
  @patch
  Class.missingOriginConstructor(); /* Error: missing origin class */

  Class.existingOriginConstructor(); /* Error: conflict with origin class */

  @patch
  void missingOriginMethod() {} /* Error: missing origin method */

  void existingOriginMethod() {} /* Error: conflict with origin method */
}

@patch
void missingOriginMethod() {} /* Error: missing origin method */

@patch
class MissingOriginClass {} /* Error: missing origin class */

@patch
extension MissingOriginExtension on int {} /* Error: missing origin extension */

void existingOriginMethod() {} /* Error: conflict with origin method */

class existingOriginDeclaration {} /* Error: conflict with origin declaration */

class ExistingOriginClass {} /* Error: conflict with origin class */
