// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  switchStatementBodyScope();
  ifCaseThenScope();

  unsharedPatternVariableShadows();

  sharedPatternVariableShadows(0);
  sharedPatternVariableShadows(1);
}

var topLevel = 'top-level';

/// Pattern variables are in a scope surrounding the body scope.
void switchStatementBodyScope() {
  switch ('pattern') {
    case var x:
      // Not a collision:
      var x = 'local';
      Expect.equals('local', x);
    default:
      Expect.fail('Should not reach this.');
  }
}

/// Pattern variables are in a scope surrounding the if-case then scope.
void ifCaseThenScope() {
  // Not an error: Then statement is in separate scope.
  if ('pattern' case var x) var x = 'local';
}

/// Unshared variables shadow variables in outer scopes.
void unsharedPatternVariableShadows() {
  var local = 'local';

  switch (('pat', 'tern')) {
    case (String topLevel, String local):
      Expect.equals('pat tern', '$topLevel $local');

      // Assign to pattern variable.
      local = 'assigned';
    default:
      Expect.fail('Should not reach this.');
  }

  // Outer local is not assigned.
  Expect.equals('local', local);
}

/// Shared variables shadow variables in outer scopes.
void sharedPatternVariableShadows(Object value) {
  var local = 'local';

  switch (('pat', 'tern')) {
    case (String topLevel, String local) when value == 0:
    case (String topLevel, String local) when value == 1:
      Expect.equals('pat tern', '$topLevel $local');

      // Assign to pattern variable.
      local = 'assigned';
    default:
      Expect.fail('Should not reach this.');
  }

  // Outer local is not assigned.
  Expect.equals('local', local);
}

