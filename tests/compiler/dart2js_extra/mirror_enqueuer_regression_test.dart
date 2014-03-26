// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for 'staged' reflection.  MirrorsUsed pulls in static
// functions, that pulls in more reflection.  This used to trigger a bug in
// Enqueuer where the second set of pulled in definitions were unresolved.

@MirrorsUsed(targets: const ["foo"])
import 'dart:mirrors';

final foo = reflect(reflect(9)).getField(#getField);

void main() {}
