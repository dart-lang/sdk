// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method1:params=0*/
@pragma('dart2js:noInline')
method1([a]) => /*access=[a],params=0*/ () => a;

class Class {
  /*member: Class.f:emitted*/
  @pragma('dart2js:noElision')
  var f;

  /*member: Class.capture:params=0*/
  @pragma('dart2js:noInline')
  Class.capture([a]) : f = (/*access=[a],params=0*/ () => a);

  // TODO(johnniwinther): Remove the redundant assignment of elided boxed
  // parameters.
  /*member: Class.box:assign=[a,a],params=0*/
  @pragma('dart2js:noInline')
  Class.box([a])
      : f = (/*access=[_box_0],assign=[a],params=0*/ () {
          a = 42;
        });

  Class.internal(this.f);
}

class Subclass extends Class {
  /*member: Subclass.capture:params=0*/
  @pragma('dart2js:noInline')
  Subclass.capture([a]) : super.internal(/*access=[a],params=0*/ () => a);

  /*member: Subclass.box:assign=[a,a],params=0*/
  @pragma('dart2js:noInline')
  Subclass.box([a])
      : super.internal(/*access=[_box_0],assign=[a],params=0*/ () {
          a = 42;
        });
}

/*member: main:calls=*,params=0*/
main() {
  method1();
  new Class.capture();
  new Class.box();
  new Subclass.capture();
  new Subclass.box();
}
