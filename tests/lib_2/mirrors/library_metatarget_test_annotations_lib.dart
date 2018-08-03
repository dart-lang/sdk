// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for the combined use of metatargets and library tags.

library annotations;

class UsedOnlyOnLibrary {
  const UsedOnlyOnLibrary();
}

const usedOnlyOnLibrary = const UsedOnlyOnLibrary();

class Reflectable {
  const Reflectable();
}

const Reflectable reflectable = const Reflectable();
