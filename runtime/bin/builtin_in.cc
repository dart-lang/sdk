// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// clang-format off

#include "{{INCLUDE}}" // NOLINT

// This file is used to generate the mapping of standalone dart libraries
// to the corresponding files that implement them.
{{SOURCE_ARRAYS}}
const char* {{VAR_NAME}}[] = {
{{LIBRARY_SOURCE_MAP}}
{{PART_SOURCE_MAP}}
  NULL, NULL, NULL
};
