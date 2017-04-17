// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test to see if novel HTML tags are interpreted as HTMLElement.

@Native("HTMLElement")
class Element {
  String dartMethod(int x) => 'dartMethod(${nativeMethod(x+1)})';
  String nativeMethod(int x) native;
}

makeE() native;
makeF() native;

void setup() native """
// A novel HTML element.
function HTMLGoofyElement(){}
HTMLGoofyElement.prototype.nativeMethod = function(a) {
  return 'Goofy.nativeMethod(' + a  + ')';
};
makeE = function(){return new HTMLGoofyElement};

// A non-HTML element with a misleading name.
function HTMLFakeyElement(){}
HTMLFakeyElement.prototype.nativeMethod = function(a) {
  return 'Fakey.nativeMethod(' + a  + ')';
};
makeF = function(){return new HTMLFakeyElement};

self.nativeConstructor(HTMLGoofyElement);
""";

main() {
  nativeTesting();
  setup();

  var e = makeE();
  Expect.equals('Goofy.nativeMethod(10)', e.nativeMethod(10));
  Expect.equals('dartMethod(Goofy.nativeMethod(11))', e.dartMethod(10));

  var f = makeF();
  Expect.throws(() => f.nativeMethod(20), (e) => e is NoSuchMethodError,
      'fake HTML Element must not run Dart method on native class');
  Expect.throws(() => f.dartMethod(20), (e) => e is NoSuchMethodError,
      'fake HTML Element must not run native method on native class');
}
