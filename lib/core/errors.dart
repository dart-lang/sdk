// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Error {
  const Error();
}

class AssertionError implements Error {
}

class TypeError implements AssertionError {
}

// TODO(lrn): Rename to CastError according to specification.
class CastException implements Error {
}

class FallThroughError implements Error {
  const FallThroughError();
}

class AbstractClassInstantiationError {
}
