// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var myString;

String ifBailout(test) {
  if (test) {
    // Share the same variable for the type inference.
    var o = myString;
    // Make sure the type inference wants an array.
    if (false) o[1] = 2;
    return '${o[0]} bailout';
  }
  return '${myString[0]} no bailout';
}

String ifElseBailout(test) {
  if (test) {
    // Share the same variable for the type inference.
    var o = myString;
    // Make sure the type inference wants an array.
    if (false) o[1] = 2;
    return '${o[0]} if bailout';
  } else {
    // Share the same variable for the type inference.
    var o = myString;
    // Make sure the type inference wants an array.
    if (false) o[1] = 2;
    return '${o[0]} else bailout';
  }
}

void forBailout() {
  var n = myString.length;
  var res = '';
  for (int i = 0; i < n; i++) {
    var o = myString;
    if (false) o[1] = 2;
    res = res.concat(o[i]);
  }
  return res;
}

void forInBailout() {
  var n = myString.length;
  var res = '';
  for (int i in myString.charCodes()) {
    var o = myString;
    if (false) o[1] = 2;
    res = res.concat(new String.fromCharCodes([i]));
  }
  return res;
}

void innerForBailout() {
  var n = myString.length;
  var res = '';
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < n; j++) {
      var o = myString;
      if (false) o[1] = 2;
      res = res.concat(o[j]);
    }
  }
  return res;
}

void whileBailout() {
  var n = myString.length;
  var res = '';
  var i = 0;
  while (i < n) {
    var o = myString;
    if (false) o[1] = 2;
    res = res.concat(o[i]);
    i++;
  }
  return res;
}

void doWhileBailout() {
  var n = myString.length;
  var res = '';
  var i = 0;
  do {
    var o = myString;
    if (false) o[1] = 2;
    res = res.concat(o[i]);
    i++;
  } while (i < n);
  return res;
}

void phiBailout() {
  var prev = -1;
  bool inside = false;
  for (int i = 0; i < 2; i++) {
    var o = myString;
    // prev will be a phi converted to a local, and if we're not
    // careful, the bailout target may not have the right value for
    // it.
    if (prev != -1) {
      inside = true;
      if (false) o[0] = 1;
      print(o[0]);
      Expect.equals(0, prev);
    }
    prev = i;
  }
  Expect.isTrue(inside);
}

int fibonacci(int n) {
  int a = 0, b = 1, i = 0;
  // i, a, b will become phis, and then locals. The i++ creates a
  // load/store sequence that we must be careful with.
  while (i++ < n) {
    a = a + b;
    b = a - b;
    var o = myString;
    if (false) o[0] = 2;
    print(o[0]);
  }
  return a;
}

void ifPhiBailout1(int bailout) {
  var a = 0;
  var c = 0;

  if (a == 0) c = a++;
  else c = a--;

  if (bailout == 1) {
    var o = myString;
    if (false) o[0] = 2;
    print(o[0]);
  }

  Expect.equals(1, a);
  Expect.equals(0, c);

  if (a == 0) c = a++;
  else c = a--;

  if (bailout == 2) {
    var o = myString;
    if (false) o[0] = 2;
    print(o[0]);
  }

  Expect.equals(0, a);
  Expect.equals(1, c);
}

void ifPhiBailout2(int bailout) {
  var a = 0;
  var c = 0;

  if (a == 0) {
    c = a;
    a = a + 1;
  } else {
    c = a;
    a = a - 1;
  }

  if (bailout == 1) {
    var o = myString;
    if (false) o[0] = 2;
    print(o[0]);
  }

  Expect.equals(1, a);
  Expect.equals(0, c);

  if (a == 0) {
    c = a;
    a = a + 1;
  } else {
    c = a;
    a = a - 1;
  }

  if (bailout == 2) {
    var o = myString;
    if (false) o[0] = 2;
    print(o[0]);
  }

  Expect.equals(0, a);
  Expect.equals(1, c);
}

main() {
  myString = '1';
  Expect.equals('1 no bailout', ifBailout(false));
  Expect.equals('1 bailout', ifBailout(true));

  Expect.equals('1 else bailout', ifElseBailout(false));
  Expect.equals('1 if bailout', ifElseBailout(true));

  myString = '1234';
  Expect.equals('1234', forBailout());
  Expect.equals('1234', forInBailout());
  Expect.equals('12341234', innerForBailout());

  Expect.equals('1234', whileBailout());
  Expect.equals('1234', doWhileBailout());

  Expect.equals(102334155, fibonacci(40));

  phiBailout();
  ifPhiBailout1(1);
  ifPhiBailout1(2);
  ifPhiBailout2(1);
  ifPhiBailout2(2);
}
