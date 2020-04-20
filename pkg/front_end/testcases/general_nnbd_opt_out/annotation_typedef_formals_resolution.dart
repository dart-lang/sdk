// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This test checks that the annotation on a formal parameter of a typedef is
// resolved to the top-level constant, and not to the parameter itself in case
// of a name match.

const int app = 0;

typedef int F(@app int app);

main() {}
