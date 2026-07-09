// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods containing jumps.
// SharedOptions=--enable-experiment=anonymous-methods

import '../../static_type_helper.dart';

void testBreak() {
  Object? o;

  if (o is int || o is String); // Make them types of interest.

  o = "a";
  do {
    o = 1;
    break;
    o = "b"; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<int>>;

  o = "a";
  do {
    o = 1;
    null.{ break; };
    o = "b"; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<int>>;

  o = "a";
  do {
    null.{
      o = 1;
      break;
      o = "b"; // ignore: dead_code
    };
  } while (false);
  o.expectStaticType<Exactly<int>>;
}

void testBreakL() {
  Object? o;

  if (o is int || o is String); // Make them types of interest.

  o = "a";
  L: {
    o = 1;
    break L;
    o = "b"; // ignore: dead_code
  }
  o.expectStaticType<Exactly<int>>;

  o = "a";
  L: {
    o = 1;
    null.{ break L; };
    o = "b"; // ignore: dead_code
  }
  o.expectStaticType<Exactly<int>>;

  o = "a";
  L: {
    null.{
      o = 1;
      break L;
      o = "b"; // ignore: dead_code
    };
  }
  o.expectStaticType<Exactly<int>>;

  o = "a";
  L: null.{
    o = 1;
    break L;
    o = "b"; // ignore: dead_code
  };
  o.expectStaticType<Exactly<int>>;

  Iterable<Object?> f() sync* {
    Object? o;
    if (o is int || o is String);
    o = "a";
    L: yield null.{
      o = 1;
      break L;
      o = "b"; // ignore: dead_code
    };
    o.expectStaticType<Exactly<int>>;
  }
  f().isEmpty;
}

void testContinue() {
  Object? o;
  bool doContinue = true;

  if (o is int || o is String); // Make them types of interest.

  o = "a";  
  do {
    if (doContinue) {
      doContinue = false;
      continue;
    } else {
      break;
    }
    o = 1; // ignore: dead_code
  } while (false);
  // Loop flow analysis is conservative, so `o = 1` might have occurred.
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  do {
    if (doContinue) {
      doContinue = false;
      null.{ continue; };
    } else {
      null.{ break; };
    }
    o = 1; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  do {
    null.{
      if (doContinue) {
        doContinue = false;
        continue;
      } else {
        break;
      }
      o = 1; // ignore: dead_code
    };
  } while (false);
  o.expectStaticType<Exactly<Object?>>;
}

void testContinueL() {
  Object? o;
  bool doContinue = true;

  if (o is int || o is String); // Make them types of interest.

  o = "a";  
  L: do {
    if (doContinue) {
      doContinue = false;
      continue L;
    } else {
      break;
    }
    o = 1; // ignore: dead_code
  } while (false);
  // Loop flow analysis is conservative, so `o = 1` might have occurred.
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  L: do {
    if (doContinue) {
      doContinue = false;
      null.{ continue L; };
    } else {
      null.{ break; };
    }
    o = 1; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  L: do {
    null.{
      if (doContinue) {
        doContinue = false;
        continue L;
      } else {
        break;
      }
      o = 1; // ignore: dead_code
    };
  } while (false);
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  L: do {
    do {
      if (doContinue) {
        doContinue = false;
        continue L;
      } else {
        break L;
      }
    } while (false);
    o = 1; // ignore: dead_code
  } while (false);
  // Loop flow analysis is conservative, so `o = 1` might have occurred.
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  L: do {
    do {
      if (doContinue) {
        doContinue = false;
        null.{ continue L; };
      } else {
        null.{ break L; };
      }
    } while (false);
    o = 1; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<Object?>>;

  o = "a";  
  L: do {
    do {
      null.{
        if (doContinue) {
          doContinue = false;
          continue L;
        } else {
          break L;
        }
      };
    } while (false);
    o = 1; // ignore: dead_code
  } while (false);
  o.expectStaticType<Exactly<Object?>>;
}

void main() {
  testBreak();
  testBreakL();
  testContinue();
  testContinueL();
}
