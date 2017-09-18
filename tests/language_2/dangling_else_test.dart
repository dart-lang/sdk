// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests dangling else. The VM should not have any problems, but dart2js or
// dart2dart could get this wrong.

import "package:expect/expect.dart";

nestedIf1(notTrue) {
  if (notTrue) return 'bad input';
  if (notTrue) {
    if (notTrue) {
      return 'bad';
    }
  } else {
    return 'good';
  }
  return 'bug';
}

nestedIf2(notTrue) {
  if (notTrue) return 'bad input';
  if (notTrue) {
    if (notTrue) {
      return 'bad';
    } else {
      if (notTrue) {
        return 'bad';
      }
    }
  } else {
    return 'good';
  }
  return 'bug';
}

nestedWhile(notTrue) {
  if (notTrue) return 'bad input';
  if (notTrue) {
    while (notTrue) {
      if (notTrue) {
        return 'bad';
      }
    }
  } else {
    return 'good';
  }
  return 'bug';
}

nestedFor(notTrue) {
  if (notTrue) return 'bad input';
  if (notTrue) {
    for (int i = 0; i < 3; i++) {
      if (i == 0) {
        return 'bad';
      }
    }
  } else {
    return 'good';
  }
  return 'bug';
}

nestedLabeledStatement(notTrue) {
  if (notTrue) return 'bad input';
  if (notTrue) {
    label:
    if (notTrue) {
      break label;
    }
  } else {
    return 'good';
  }
  return 'bug';
}

main() {
  Expect.equals('good', nestedIf1(false));
  Expect.equals('good', nestedIf2(false));
  Expect.equals('good', nestedWhile(false));
  Expect.equals('good', nestedFor(false));
  Expect.equals('good', nestedLabeledStatement(false));
}
