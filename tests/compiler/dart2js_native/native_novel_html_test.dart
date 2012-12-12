// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to see if novel HTML tags are interpreted as HTMLElement.

class Element native "*HTMLElement" {
  String foo(int x) => '[${bar(x+1)}]';
  String bar(int x) native;
}

makeE() native;
makeF() native;

void setup() native """
// A novel HTML element.
function HTMLGoofyElement(){}
HTMLGoofyElement.prototype.bar = function(a){return 'Goofy.foo(' + a  + ')';}
makeE = function(){return new HTMLGoofyElement};

// A non-HTML element with a misleading name.
function HTMLFakeyElement(){}
HTMLFakeyElement.prototype.bar = function(a){return 'Fakey.foo(' + a  + ')';}
makeF = function(){return new HTMLFakeyElement};

// Make the HTMLGoofyElement look like a real host object.
var theRealObjectToString = Object.prototype.toString;
Object.prototype.toString = function() {
  if (this instanceof HTMLGoofyElement) return '[object HTMLGoofyElement]';
  return theRealObjectToString.call(this);
}
""";


main() {
  setup();

  print(123);
  var e = makeE();
  Expect.equals('[Goofy.foo(11)]', e.foo(10));

  var f = makeF();
  expectNoSuchMethod(() => f.foo(20), 'f.foo(20) should fail');
}

expectNoSuchMethod(action, note) {
  bool caught = false;
  try {
    action();
  } catch (ex) {
    caught = true;
    Expect.isTrue(ex is NoSuchMethodError, note);
  }
  Expect.isTrue(caught, note);
}
