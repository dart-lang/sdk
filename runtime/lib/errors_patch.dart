// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class NoSuchMethodError {
  /* patch */ static String _objectToString(Object object) {
    return Object._toString(object);
  }
}

// Exceptions that should be NoSuchMethodError instead.

class _ClosureArgumentMismatchException implements Exception {
  const _ClosureArgumentMismatchException();
  String toString() => "Closure argument mismatch";
}


class _ObjectNotClosureException implements Exception {
  const _ObjectNotClosureException();
  String toString() => "Object is not closure";
}
