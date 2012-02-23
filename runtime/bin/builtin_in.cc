// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "{{INCLUDE}}"

// The string on the next line will be filled in with the contents of the
// builtin.dart file.
// This string forms the content of builtin functionality which is injected
// into standalone dart to provide some test/debug functionality.
const char {{VAR_NAME}}[] = {
  {{DART_SOURCE}}
};
