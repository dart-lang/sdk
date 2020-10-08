// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests verify that the kinds of constructs we expect to cause type
// promotion continue to function properly even when used inside unreachable
// code.

abstract class C {
  void f(Object x, Object y);
}

andExpression_alwaysFalse(Object o) {
  return;
  o is! int && (throw 'x');
  /*int*/ o;
}

andExpression_alwaysTrue(Object o) {
  return;
  true && (o is int || (throw 'x'));
  /*int*/ o;
}

andExpression_lhsAlwaysTrue(Object o) {
  return;
  if (true && o is! int) {
    o;
  } else {
    /*int*/ o;
  }
}

andExpression_rhsAlwaysTrue(Object o) {
  return;
  if (o is! int && true) {
    o;
  } else {
    /*int*/ o;
  }
}

conditionalIs(Object o) {
  return;
  o is int ? null : throw 'bad';
  /*int*/ o;
}

conditionalIsNot(Object o) {
  return;
  o is! int ? throw 'bad' : null;
  /*int*/ o;
}

conditionalJoinFalse(Object o, bool b) {
  return;
  if (b ? o is! int : o is! int) return;
  /*int*/ o;
}

conditionalJoinTrue(Object o, bool b) {
  return;
  if (!(b ? o is int : o is int)) return;
  /*int*/ o;
}

doBreak(Object o) {
  return;
  do {
    if (o is int) break;
  } while (true);
  /*int*/ o;
}

doContinue(Object o) {
  return;
  do {
    if (o is int) continue;
    return;
  } while (false);
  /*int*/ o;
}

doCondition(Object o) {
  return;
  do {} while (o is! int);
  /*int*/ o;
}

forBreak(Object o) {
  return;
  for (;;) {
    if (o is int) break;
  }
  /*int*/ o;
}

forContinue(Object o) {
  return;
  for (;; /*int*/ o) {
    if (o is int) continue;
    return;
  }
}

ifIsNot(Object o) {
  return;
  if (o is! int) return;
  /*int*/ o;
}

ifIsNot_listElement(Object o) {
  return;
  [if (o is! int) throw 'x'];
  /*int*/ o;
}

ifIsNot_setElement(Object o) {
  return;
  ({if (o is! int) throw 'x'});
  /*int*/ o;
}

ifIsNot_mapElement(Object o) {
  return;
  ({if (o is! int) 0: throw 'x'});
  /*int*/ o;
}

ifNull(Object o, Object? p, Object q, void Function(Object, Object) f) {
  return;
  (o is int ? p : throw 'x') ?? f(o = q, throw 'x');
  /*int*/ o;
}

labeledStatement(Object o) {
  return;
  label:
  {
    if (o is int) break label;
    return;
  }
  /*int*/ o;
}

nullAwareAccess(Object o, C? p, Object q) {
  return;
  (o is int ? p : throw 'x')?.f(o = q, throw 'x');
  /*int*/ o;
}

orExpression_alwaysFalse(Object o) {
  return;
  false || (o is! int && (throw 'x'));
  /*int*/ o;
}

orExpression_alwaysTrue(Object o) {
  return;
  o is int || (throw 'x');
  /*int*/ o;
}

orExpression_lhsAlwaysFalse(Object o) {
  return;
  if (false || o is int) {
    /*int*/ o;
  } else {
    o;
  }
}

orExpression_rhsAlwaysFalse(Object o) {
  return;
  if (o is int || false) {
    /*int*/ o;
  } else {
    o;
  }
}
