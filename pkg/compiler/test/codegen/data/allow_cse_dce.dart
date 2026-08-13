// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:ignore*/
void main() {
  for (final functions in [
    [cse_000, cse_001, cse_010, cse_011, cse_100, cse_101, cse_110, cse_111],
    [dce_000, dce_001, dce_010, dce_011, dce_100, dce_101, dce_110, dce_111],
    [cse_dce_000, cse_dce_001, cse_dce_010, cse_dce_011],
    [cse_dce_100, cse_dce_101, cse_dce_110, cse_dce_111],
  ]) {
    for (final f in functions) {
      f(123);
      f('x');
    }
  }
  print([sink1, sink2]);
}

Object? sink1;
Object? sink2;
int gI = 0;

/// [source] is not idempotent so would normally not be eligible for CSE or DCE.
/*member: source:ignore*/
@pragma('dart2js:never-inline')
Object? source(Object? o) {
  ++gI;
  sink1 = o;
  return o is num ? gI : o;
}

/// Basic 'f' functions are the same function body that calls [source] and casts
/// the result, but with all combinations of inlining and allow-cse and
/// allow-dce annotations.
///
/// fABC:
///  A:    1: inlined (0 not inlined)
///   B:    1: has allow-dce
///    C:    1: has allow-cse
///
/// So f000 and f100 serve as a baseline for comparing the effects of the
/// allow-cse and allow-dce annotations.
///
/// These functions are used in three ways:
///
///        cse_ABC calls fABC twice and uses the results
///        dce_ABC calls fABC once and ignores the result
///    cse_dce_ABC calls fABC twice and ignores both results

@pragma('dart2js:never-inline')
/*member: f000:function(o) {
  return A._asInt(A.source(o));
}*/
int f000(o) => source(o) as int;

@pragma('dart2js:never-inline')
@pragma('dart2js:allow-cse')
/*member: f001:function(o) {
  return A._asInt(A.source(o));
}*/
int f001(o) => source(o) as int;

@pragma('dart2js:never-inline')
@pragma('dart2js:allow-dce')
/*member: f010:function(o) {
  return A._asInt(A.source(o));
}*/
int f010(o) => source(o) as int;

@pragma('dart2js:never-inline')
@pragma('dart2js:allow-cse')
@pragma('dart2js:allow-dce')
/*member: f011:function(o) {
  return A._asInt(A.source(o));
}*/
int f011(o) => source(o) as int;

@pragma('dart2js:prefer-inline')
int f100(o) => source(o) as int;

@pragma('dart2js:prefer-inline')
@pragma('dart2js:allow-cse')
/*member: f101:function(o) {
  return A._asInt(A.source(o));
}*/
int f101(o) => source(o) as int;

@pragma('dart2js:prefer-inline')
@pragma('dart2js:allow-dce')
/*member: f110:function(o) {
  return A._asInt(A.source(o));
}*/
int f110(o) => source(o) as int;

@pragma('dart2js:prefer-inline')
@pragma('dart2js:allow-cse')
@pragma('dart2js:allow-dce')
/*member: f111:function(o) {
  return A._asInt(A.source(o));
}*/
int f111(o) => source(o) as int;

/*member: cse_000:function(x) {
  $.sink1 = A.f000(x);
  $.sink2 = A.f000(x);
}*/
void cse_000(x) {
  // Expect two uninlined calls.
  sink1 = f000(x);
  sink2 = f000(x);
}

/*member: cse_001:function(x) {
  $.sink2 = $.sink1 = A.f001(x);
}*/
void cse_001(x) {
  // Expect one call that is reused.
  sink1 = f001(x);
  sink2 = f001(x);
}

/*member: cse_010:function(x) {
  $.sink1 = A.f010(x);
  $.sink2 = A.f010(x);
}*/
void cse_010(x) {
  sink1 = f010(x);
  sink2 = f010(x);
}

/*member: cse_011:function(x) {
  $.sink2 = $.sink1 = A.f011(x);
}*/
void cse_011(x) {
  // Expect one call that is reused.
  sink1 = f011(x);
  sink2 = f011(x);
}

/*member: cse_100:function(x) {
  $.sink1 = A._asInt(A.source(x));
  $.sink2 = A._asInt(A.source(x));
}*/
void cse_100(x) {
  // Expect two inlined calls with no shared subexpressions.
  sink1 = f100(x);
  sink2 = f100(x);
}

/*member: cse_101:function(x) {
  $.sink2 = $.sink1 = A.f101(x);
}*/
void cse_101(x) {
  // Expect one call, possibly inlined.
  sink1 = f101(x);
  sink2 = f101(x);
}

/*member: cse_110:function(x) {
  $.sink1 = A.f110(x);
  $.sink2 = A.f110(x);
}*/
void cse_110(x) {
  // Expect two calls; possibly inlined, with no shared subexpressions.
  sink1 = f110(x);
  sink2 = f110(x);
}

/*member: cse_111:function(x) {
  $.sink2 = $.sink1 = A.f111(x);
}*/
void cse_111(x) {
  // Expect one call.
  sink1 = f111(x);
  sink2 = f111(x);
}

/*member: dce_000:function(x) {
  A.f000(x);
}*/
void dce_000(x) {
  f000(x);
}

/*member: dce_001:function(x) {
  A.f001(x);
}*/
void dce_001(x) {
  f001(x);
}

/*member: dce_010:function(x) {
}*/
void dce_010(x) {
  // Expect deleted call.
  f010(x);
}

/*member: dce_011:function(x) {
}*/
void dce_011(x) {
  // Expect deleted call.
  f011(x);
}

/*member: dce_100:function(x) {
  A._asInt(A.source(x));
}*/
void dce_100(x) {
  // Expect inlined call.
  f100(x);
}

/*member: dce_101:function(x) {
  A.f101(x);
}*/
void dce_101(x) {
  // Expect one call, possibly inlined.
  f101(x);
}

/*member: dce_110:function(x) {
}*/
void dce_110(x) {
  // Expect deleted call.
  f110(x);
}

/*member: dce_111:function(x) {
}*/
void dce_111(x) {
  // Expect deleted call.
  f111(x);
}

/*member: cse_dce_000:function(x) {
  A.f000(x);
  A.f000(x);
}*/
void cse_dce_000(x) {
  // Expect two calls.
  f000(x);
  f000(x);
}

/*member: cse_dce_001:function(x) {
  A.f001(x);
}*/
void cse_dce_001(x) {
  // Expect one call.
  f001(x);
  f001(x);
}

/*member: cse_dce_010:function(x) {
}*/
void cse_dce_010(x) {
  // Expect empty body - both calls deleted.
  f010(x);
  f010(x);
}

/*member: cse_dce_011:function(x) {
}*/
void cse_dce_011(x) {
  // Expect empty body - both calls deleted.
  f011(x);
  f011(x);
}

/*member: cse_dce_100:function(x) {
  A._asInt(A.source(x));
  A._asInt(A.source(x));
}*/
void cse_dce_100(x) {
  // Expect both calls inlined.
  f100(x);
  f100(x);
}

/*member: cse_dce_101:function(x) {
  A.f101(x);
}*/
void cse_dce_101(x) {
  // Expect call or one copy of inlined function.
  f101(x);
  f101(x);
}

/*member: cse_dce_110:function(x) {
}*/
void cse_dce_110(x) {
  // Expect empty body - both calls deleted.
  f110(x);
  f110(x);
}

/*member: cse_dce_111:function(x) {
}*/
void cse_dce_111(x) {
  // Expect empty body - both calls deleted.
  f111(x);
  f111(x);
}
