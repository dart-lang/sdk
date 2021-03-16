// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Tests for simplifying that we know a condition is true in the then-branch and
// false in the else-branch, and sometimes after join when a diamond exits.

/*member: check0:ConditionValue=[]*/
check0(int x) {
  if (x != 1) {
    return 200;
  } else {
    return 400;
  }
}

/*member: check1:ConditionValue=[count=1&value=false&where=else,count=1&value=true&where=then]*/
check1(int x) {
  if (x == 1) {
    if (x == 1) return 100;
    return 200;
  } else {
    if (x == 1) return 300;
    return 400;
  }
}

/*member: check2:ConditionValue=[count=1&value=false&where=then,count=1&value=true&where=else]*/
check2(int x) {
  if (x != 1) {
    if (x == 1) return 100;
    return 200;
  } else {
    if (x == 1) return 300;
    return 400;
  }
}

/*member: check3:ConditionValue=[count=1&value=false&where=else,count=1&value=true&where=then]*/
check3(int x) {
  if (x == 1) {
    if (x != 1) return 100;
    return 200;
  } else {
    if (x != 1) return 300;
    return 400;
  }
}

/*member: check4:ConditionValue=[count=1&value=false&where=else,count=1&value=true&where=then]*/
check4(int x) {
  if (x != 1) {
    if (x != 1) return 100;
    return 200;
  } else {
    if (x != 1) return 300;
    return 400;
  }
}

// The first throw is in statement position, so it has an exit edge, leaving the
// rest of the method in the first branch 'else'.
/*member: join0Else:ConditionValue=[count=2&value=false&where=else]*/
join0Else(int x) {
  int a = 0, b = 0, c = 0;
  if (x == 1)
    throw 'bad';
  else
    a = x + 1;
  if (x == 1)
    throw 'bad';
  else
    b = x + 2;
  if (x == 1)
    throw 'bad';
  else
    c = x + 3;
  return a * b * c;
}

/*member: join1:ConditionValue=[count=2&value=false&where=else-join]*/
join1(int x) {
  int a = (x == 1 ? throw 'bad' : x) + 1;
  int b = (x == 1 ? throw 'bad' : x) + 2;
  int c = (x == 1 ? throw 'bad' : x) + 3;
  return a * b * c;
}

/*member: join2:ConditionValue=[count=2&value=true&where=then-join]*/
join2(int x) {
  int a = (x == 1 ? x : throw 'bad') + 1;
  int b = (x == 1 ? x : throw 'bad') + 2;
  int c = (x == 1 ? x : throw 'bad') + 3;
  return a * b * c;
}

/*member: join3:ConditionValue=[count=2&value=false&where=else-join]*/
join3(int x) {
  int a = (x != 1 ? throw 'bad' : x) + 1;
  int b = (x != 1 ? throw 'bad' : x) + 2;
  int c = (x != 1 ? throw 'bad' : x) + 3;
  return a * b * c;
}

/*member: join4:ConditionValue=[count=2&value=true&where=then-join]*/
join4(int x) {
  int a = (x != 1 ? x : throw 'bad') + 1;
  int b = (x != 1 ? x : throw 'bad') + 2;
  int c = (x != 1 ? x : throw 'bad') + 3;
  return a * b * c;
}

/*member: loop1:ConditionValue=[count=1&value=true&where=then]*/
loop1(int x) {
  for (int i = 0; i < 10; i++) {
    if (x == 1) {
      sink = x == 1;
    }
  }
}

/*member: loop2HoistedThen:ConditionValue=[count=1&value=false&where=hoisted-then]*/
loop2HoistedThen(int x) {
  //   t1 = x == 1;
  //   t2 = !t1;
  //   loop:
  //     if (t1)
  //       sink = t2; // replaced with `false`.
  for (int i = 0; i < 10; i++) {
    if (x == 1) {
      sink = x != 1;
    }
  }
}

/*member: loop3:ConditionValue=[count=1&value=false&where=then]*/
loop3(int x) {
  for (int i = 0; i < 10; i++) {
    if (x != 1) {
      sink = x == 1;
    }
  }
}

/*member: loop4:ConditionValue=[count=1&value=true&where=then]*/
loop4(int x) {
  for (int i = 0; i < 10; i++) {
    if (x != 1) {
      sink = x != 1;
    }
  }
}

/*member: loop5HoistedElseJoin:ConditionValue=[count=1&value=true&where=hoisted-else-join]*/
loop5HoistedElseJoin(int x) {
  for (int i = 0; i < 10; i++) {
    sink = (x == 1 ? throw 'bad' : x) + 1;
    sink = x != 1;
  }
}

// Unlike loop5, this is not 'hoisted'. GVN is not required to match the
// condition with its use, so the subsitution happens in a simplify pass before
// GVN/LICM can hoist the negation.
/*member: loop6ElseJoin:ConditionValue=[count=1&value=false&where=else-join]*/
loop6ElseJoin(bool x) {
  for (int i = 0; i < 10; i++) {
    sink = (x ? throw 'bad' : i) + 1;
    sink = !x;
  }
}

dynamic sink;

void main() {
  check0(1);
  check0(2);

  check1(1);
  check1(2);
  check2(1);
  check2(2);
  check3(1);
  check3(2);
  check4(1);
  check4(2);

  join0Else(1);
  join0Else(2);
  join1(1);
  join1(2);
  join2(1);
  join2(2);
  join3(1);
  join3(2);
  join4(1);
  join4(2);

  loop1(1);
  loop1(2);
  loop2HoistedThen(1);
  loop2HoistedThen(2);
  loop3(1);
  loop3(2);
  loop4(1);
  loop4(2);
  loop5HoistedElseJoin(1);
  loop5HoistedElseJoin(2);
  loop6ElseJoin(true);
  loop6ElseJoin(false);

  print(sink);
}
