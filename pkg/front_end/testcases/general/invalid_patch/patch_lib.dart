// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class InvalidClassTypeParameterCount1<T> /* Error */ {}

@patch
class InvalidClassTypeParameterCount2 /* Error */ {}

@patch
class InvalidClassTypeParameterCount3<T> /* Error */ {}

@patch
extension InvalidExtensionTypeParameterCount1<T> on int /* Error */ {}

@patch
extension InvalidExtensionTypeParameterCount2 on int /* Error */ {}

@patch
extension InvalidExtensionTypeParameterCount3<T> on int /* Error */ {}
