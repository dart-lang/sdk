// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program to test check that we don't fail to compile when an
// inlinable method contains a throw.

var x = false;

bool called;

bool callMeTrue() {
  called = true;
  return true;
}

bool callMeFalse() {
  called = true;
  return false;
}

void callMe() {
  called = true;
}

testCallThenThrow(fn) {
  called = false;
  Expect.throws(() => fn());
  Expect.isTrue(called);
}

testCall(fn) {
  called = false;
  fn();
  Expect.isTrue(called);
}

testNoThrow(fn) {
  called = false;
  Expect.throws(() => fn());
  Expect.isFalse(called);
}

kast(x) {
  throw x;
}

ternary(a, b, c) {
  if (x == 2) throw "ternary";
}

hest() => kast("hest");
hest2() { return kast("hest2"); }
foo() => true || kast("foo");
bar() => false || kast("foo");
barc() => callMeTrue() || kast("foo");
barCallThrow() => callMeFalse() || kast("foo");
baz(x) => x ? kast("baz") : 0;
bazc() => callMeFalse() ? kast("baz") : 0;
bazCallThrow() => callMeTrue() ? kast("baz") : 0;
fizz(x) => x ? 0 : kast("baz");
fizzc() => callMeTrue() ? 0 : kast("baz");
fizzCallThrow() => callMeFalse() ? 0 : kast("baz");
fuzz() => kast("baz") ? 0 : 1;
farce() => !kast("baz");
unary() => ~(kast("baz"));
boo() {
  callMe();
  x = kast("boo");
}
yo() {
  throw kast("yo");
}
hoo() {
  x[kast("hoo")] = 0;
  x[kast("hoo")];
  kast("hoo").x = 0;
  kast("hoo").x;
}

switcheroo(x) {
  switch (kast("switcheroo")) {
    case 0:
      boo();
  }
}
switchertoo(x) {
  switch (kast("switcheroo")) {
    case boo():
      foo();
  }
}

switchenoo(x) {
  switch (x) {
    case callMeTrue():
      break;
    case kast("switchenoo"):
      break;
    case 42:
      return 42;
  }
}

interpole() => "inter${kast('tada!')}pole";
interpoleCallThrow() => "inter${callMeTrue()}...${kast('tada!')}pole";

call1() => ternary(0, kast("call1"), 1);
call2() => ternary(kast("call2"), 0, 1);
call3() => ternary(0, 1, kast("call3"));
call1c() => ternary(callMe(), kast("call1"), 1);
call3c() => ternary(callMeTrue(), 1, kast("call3"));
call4c() => ternary(0, callMeTrue(), kast("call3"));

sendSet() {
  var x = kast("sendSet");
}

sendSetCallThrow() {
  var x = callMe(), y = kast("sendSet");
}

isSend() => kast("isSend") is int;

vile() {
  while (kast("vile")) {
    callMe();
  }
}

dovile() {
  var x = 0;
  do {
    callMe();
    x = 1;
  } while (kast("vile"));
  print(x);
}

dovileBreak() {
  var x = 0;
  do {
    callMe();
    x = 1;
    break;
  } while (kast("vile"));
  return(x);
}

dovileContinue() {
  var x = 0;
  do {
    callMe();
    x = 1;
    continue;
  } while (kast("vile"));
  return(x);
}

main() {
  Expect.throws(hest);
  Expect.throws(hest2);
  foo();
  Expect.throws(bar);
  testCall(barc);
  testCallThenThrow(barCallThrow);
  Expect.equals(0, baz(false));
  Expect.throws(() => baz(true));
  testCall(bazc);
  testCallThenThrow(bazCallThrow);
  Expect.throws(() => fizz(false));
  testCall(fizzc);
  testCallThenThrow(fizzCallThrow);
  Expect.throws(fuzz);
  Expect.throws(farce);
  Expect.throws(unary);
  testCallThenThrow(boo);
  Expect.throws(yo);
  Expect.throws(hoo);
  Expect.throws(switcheroo);
  Expect.throws(switchertoo);
  testCallThenThrow(() => switchenoo(false));
  switchenoo(true);
  testCall(() { try { switchenoo(x); } catch(e) { } });
  Expect.throws(interpole);
  testCallThenThrow(interpoleCallThrow);
  Expect.throws(call1);
  Expect.throws(call2);
  Expect.throws(call3);
  testCallThenThrow(call1c);
  testCallThenThrow(call3c);
  testCallThenThrow(call4c);
  Expect.throws(sendSet);
  testCallThenThrow(sendSetCallThrow);
  Expect.throws(isSend);
  testNoThrow(vile);
  testCallThenThrow(dovile);
  testCall(dovileBreak);
  testCallThenThrow(dovileContinue);
}
