// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that guarded patterns of the form `identifier when () {}()` are parsed
/// as a pattern and a guard, not as a function named `when`.  See
/// https://github.com/dart-lang/sdk/issues/64831.

import 'package:expect/expect.dart';

import 'identifier_when_function_literal_test.dart' as self;

main() {
  {
    // Switch statement: const in scope
    switch (1) {
      case one
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: the guard is evaluated
    switch (1) {
      case one
          when () {
            return false;
          }():
        Expect.fail('Should not have matched');
      default:
        break;
    }
  }

  {
    // Switch statement: prefixed identifier
    switch (1) {
      case self.one
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: static const
    switch (1) {
      case Values.one
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: relational pattern
    switch (1) {
      case == one
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: null-check pattern
    switch (nullableOne()) {
      case one?
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: logical-or pattern
    switch (1) {
      case 0 || one
          when () {
            return true;
          }():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: generic function literal
    switch (1) {
      case one
          when <T>() {
            return true;
          }<int>():
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: generator function literal
    switch (1) {
      case one
          when () sync* {
            yield 0;
          }().isNotEmpty:
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: const in scope
    if (1 case one
        when () {
          return true;
        }()) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: the guard is evaluated
    if (1 case one
        when () {
          return false;
        }()) {
      Expect.fail('Should not have matched');
    }
  }

  {
    // If-case statement: type literal, from the issue
    Object o = int;
    if (o case int
        when () {
          return true;
        }()) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: prefixed identifier
    if (1 case self.one
        when () {
          return true;
        }()) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: static const
    if (1 case Values.one
        when () {
          return true;
        }()) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case in list: const in scope
    Expect.listEquals(
      [''],
      [
        if (1 case one
            when () {
              return true;
            }())
          ''
        else
          'Should have matched',
      ],
    );
  }

  {
    // If-case in map: const in scope
    Expect.mapEquals(
      {'': ''},
      {
        if (1 case one
            when () {
              return true;
            }())
          '': ''
        else
          '': 'Should have matched',
      },
    );
  }

  {
    // If-case in set: const in scope
    Expect.setEquals(
      {''},
      {
        if (1 case one
            when () {
              return true;
            }())
          ''
        else
          'Should have matched',
      },
    );
  }
}

const one = 1;

int? nullableOne() => one;

class Values {
  static const one = 1;
}
