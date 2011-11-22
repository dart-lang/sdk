// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ExceptionImplementation implements Exception {
  const ExceptionImplementation([msg = null]) : _msg = msg;
  String toString() => (_msg === null) ? "Exception" : "Exception: $_msg";
  final _msg;
}
