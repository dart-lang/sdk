// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

/// Tests that guarded patterns of the form `identifier when !condition` can be
/// properly parsed.  See https://github.com/dart-lang/sdk/issues/52199.

import 'package:expect/expect.dart';

import 'identifier_when_not_test.dart' as self;

main() {
  {
    // Switch statement: const in scope
    switch (1) {
      case one when !false:
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: prefixed identifier
    switch (1) {
      case self.one when !false:
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: static const
    switch (1) {
      case Values.one when !false:
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch statement: prefixed static const
    switch (1) {
      case self.Values.one when !false:
        break;
      default:
        Expect.fail('Should have matched');
    }
  }

  {
    // Switch expression: const in scope
    (switch (1) { one when !false => 0, _ => throw 'Should have matched' });
  }

  {
    // Switch expression: prefixed identifier
    (switch (1) {
      self.one when !false => 0,
      _ => throw 'Should have matched'
    });
  }

  {
    // Switch expression: static const
    (switch (1) {
      Values.one when !false => 0,
      _ => throw 'Should have matched'
    });
  }

  {
    // Switch expression: prefixed static const
    (switch (1) {
      self.Values.one when !false => 0,
      _ => throw 'Should have matched'
    });
  }

  {
    // If-case statement: const in scope
    if (1 case one when !false) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: prefixed identifier
    if (1 case self.one when !false) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: static const
    if (1 case Values.one when !false) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case statement: prefixed static const
    if (1 case self.Values.one when !false) {
    } else {
      Expect.fail('Should have matched');
    }
  }

  {
    // If-case in list: const in scope
    Expect.listEquals(
        [''], [if (1 case one when !false) '' else 'Should have matched']);
  }

  {
    // If-case in list: prefixed identifier
    Expect.listEquals(
        [''], [if (1 case self.one when !false) '' else 'Should have matched']);
  }

  {
    // If-case in list: static const
    Expect.listEquals([''],
        [if (1 case Values.one when !false) '' else 'Should have matched']);
  }

  {
    // If-case in list: prefixed static const
    Expect.listEquals([
      ''
    ], [
      if (1 case self.Values.one when !false) '' else 'Should have matched'
    ]);
  }

  {
    // If-case in map: const in scope
    Expect.mapEquals({'': ''},
        {if (1 case one when !false) '': '' else '': 'Should have matched'});
  }

  {
    // If-case in map: prefixed identifier
    Expect.mapEquals({
      '': ''
    }, {
      if (1 case self.one when !false) '': '' else '': 'Should have matched'
    });
  }

  {
    // If-case in map: static const
    Expect.mapEquals({
      '': ''
    }, {
      if (1 case Values.one when !false) '': '' else '': 'Should have matched'
    });
  }

  {
    // If-case in map: prefixed static const
    Expect.mapEquals({
      '': ''
    }, {
      if (1 case self.Values.one when !false)
        '': ''
      else
        '': 'Should have matched'
    });
  }

  {
    // If-case in set: const in scope
    Expect.setEquals(
        {''}, {if (1 case one when !false) '' else 'Should have matched'});
  }

  {
    // If-case in set: prefixed identifier
    Expect.setEquals(
        {''}, {if (1 case self.one when !false) '' else 'Should have matched'});
  }

  {
    // If-case in set: static const
    Expect.setEquals({''},
        {if (1 case Values.one when !false) '' else 'Should have matched'});
  }

  {
    // If-case in set: prefixed static const
    Expect.setEquals({
      ''
    }, {
      if (1 case self.Values.one when !false) '' else 'Should have matched'
    });
  }
}

const one = 1;

class Values {
  static const one = 1;
}
