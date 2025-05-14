// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
/*member: foo1:function(x) {
  return x;
}*/
Object? foo1(Object? x) {
  final Object? y;
  if (x is int) {
    y = x;
  } else if (x is String) {
    y = x;
  } else if (x is List) {
    y = x;
  } else {
    y = x;
  }
  return y;
}

@pragma('dart2js:never-inline')
/*member: foo2:function(x) {
  $label0$0: {
    break $label0$0;
  }
  return x;
}*/
Object? foo2(Object? x) {
  final Object? y;
  L:
  {
    if (x is int) {
      y = x;
      break L;
    }
    if (x is String) {
      if (x == 'hello') {
        y = x;
        break L;
      } else {
        y = x;
      }
      break L;
    }
    if (x is List) {
      y = x;
      break L;
    }
    y = x;
  }
  return y;
}

@pragma('dart2js:never-inline')
/*member: foo3:function(x) {
  A.inscrutableBool(x);
  return x;
}*/
Object? foo3(Object? x) {
  final Object? y;
  if (inscrutableBool(x)) {
    switch (x) {
      case 1:
      case 2:
      case 3:
        y = x;
      case 4:
      case 5:
        y = x;
      case 6:
        y = x;
      default:
        y = x;
    }
  } else {
    y = x;
  }
  return y;
}

@pragma('dart2js:never-inline')
/*member: foo4:function(x) {
  if (A._isInt(x))
    switch (x) {
      case 1:
      case 2:
      case 3:
        break;
      case 4:
      case 5:
        break;
      case 6:
        break;
    }
  return x;
}*/
Object? foo4(Object? x) {
  final Object? y;
  if (x is int) {
    switch (x) {
      case 1:
      case 2:
      case 3:
        y = x;
      case 4:
      case 5:
        y = x;
      case 6:
        y = x;
      default:
        y = x;
    }
  } else {
    y = x;
  }
  return y;
}

@pragma('dart2js:never-inline')
/*member: foo5:function(x) {
  switch (x) {
    case 1:
    case 2:
    case 3:
      break;
    case 4:
    case 5:
      break;
    case 6:
      break;
  }
  return x;
}*/
Object? foo5(Object? x) {
  final Object? y;
  switch (x) {
    case 1:
    case 2:
    case 3:
      if (2 == x) {
        y = x;
      } else {
        y = x;
      }
    case 4:
    case 5:
      y = x;
    case 6:
      y = x;
    default:
      y = x;
  }
  return y;
}

/*member: inscrutableBool:ignore*/
@pragma('dart2js:never-inline')
bool inscrutableBool(Object? x) {
  return x is int || x is bool;
}

/*member: main:ignore*/
main() {
  for (final value in [
    null,
    1,
    3.5,
    true,
    'a',
    [],
    {},
    {1},
    'x'.codeUnits,
  ]) {
    print(foo1(value));
    print(foo2(value));
    print(foo3(value));
    print(foo4(value));
    print(foo5(value));
  }
}
