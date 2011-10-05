// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exceptions thrown by the VM.

class AssertionError {
  const AssertionError();
}

class TypeError extends AssertionError {
  const TypeError() : super();
}

class FallThroughError {
  const FallThroughError() : super();
}

