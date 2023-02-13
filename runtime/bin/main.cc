// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/main_impl.h"
#include "platform/assert.h"

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
