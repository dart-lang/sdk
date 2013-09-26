// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_test;

import 'dart:mirrors';

import 'dart:async' show Future;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

class C {
  var field;
  C() : this.field = 'default';
  C.named(this.field);

  get getter => 'get $field';
  set setter(v) => field = 'set $v';
  method(x, y, z) => '$x+$y+$z';
  toString() => 'a C';

  noSuchMethod(invocation) => 'DNU';

  static var staticField = 'initial';
  static get staticGetter => 'sget $staticField';
  static set staticSetter(v) => staticField = 'sset $v';
  static staticFunction(x, y) => "($x,$y)";
}

var libraryField = 'a priori';
get libraryGetter => 'lget $libraryField';
set librarySetter(v) => libraryField = 'lset $v';
libraryFunction(x,y) => '$x$y';

Future expectValueThen(Future future, Function onValue) {
  asyncStart();
  wrappedOnValue(resultIn) {
    var resultOut = onValue(resultIn);
    asyncEnd();
    return resultOut;
  }
  onError(e) {
    Expect.fail("Value expected. ($e)");
  }
  return future.then(wrappedOnValue, onError: onError);
}

Future expectError(Future future, Function errorPredicate, String reason) {
  asyncStart();
  onValue(result) {
    Expect.fail("Error expected ($reason)");
  }
  onError(e) {
    asyncEnd();
    if (!errorPredicate(e)) {
      Expect.fail("Unexpected error ($reason)");
    }
  }
  return future.then(onValue, onError: onError);
}

bool isNoSuchMethodError(e) {
  return e is NoSuchMethodError;
}

testSync() {
  var result;

  // InstanceMirror invoke
  C c = new C();
  InstanceMirror im = reflect(c);
  result = im.invoke(const Symbol('method'), [2,4,8]);
  Expect.equals('2+4+8', result.reflectee);
  result = im.invoke(const Symbol('doesntExist'), [2,4,8]);
  Expect.equals('DNU', result.reflectee);
  result = im.invoke(const Symbol('method'), [2,4]);  // Wrong arity.
  Expect.equals('DNU', result.reflectee);

  // InstanceMirror invokeGetter
  result = im.getField(const Symbol('getter'));
  Expect.equals('get default', result.reflectee);
  result = im.getField(const Symbol('field'));
  Expect.equals('default', result.reflectee);
  result = im.getField(const Symbol('doesntExist'));
  Expect.equals('DNU', result.reflectee);

  // InstanceMirror invokeSetter
  result = im.setField(const Symbol('setter'), 'foo');
  Expect.equals('foo', result.reflectee);
  Expect.equals('set foo', c.field);
  Expect.equals('set foo', im.getField(const Symbol('field')).reflectee);
  result = im.setField(const Symbol('field'), 'bar');
  Expect.equals('bar', result.reflectee);
  Expect.equals('bar', c.field);
  Expect.equals('bar', im.getField(const Symbol('field')).reflectee);
  result = im.setField(const Symbol('doesntExist'), 'bar');
  Expect.equals('bar', result.reflectee);

  // ClassMirror invoke
  ClassMirror cm = reflectClass(C);
  result = cm.invoke(const Symbol('staticFunction'),[3,4]);
  Expect.equals('(3,4)', result.reflectee);
  Expect.throws(() => cm.invoke(const Symbol('doesntExist'),[3,4]),
                isNoSuchMethodError,
                'Not defined');
  Expect.throws(() => cm.invoke(const Symbol('staticFunction'),[3]),
                isNoSuchMethodError,
                'Wrong arity');

  // ClassMirror invokeGetter
  result = cm.getField(const Symbol('staticGetter'));
  Expect.equals('sget initial', result.reflectee);
  result = cm.getField(const Symbol('staticField'));
  Expect.equals('initial', result.reflectee);
  Expect.throws(() => cm.getField(const Symbol('doesntExist')),
                isNoSuchMethodError,
                'Not defined');

  // ClassMirror invokeSetter
  result = cm.setField(const Symbol('staticSetter'), 'sfoo');
  Expect.equals('sfoo', result.reflectee);
  Expect.equals('sset sfoo', C.staticField);
  Expect.equals('sset sfoo',
                cm.getField(const Symbol('staticField')).reflectee);
  result = cm.setField(const Symbol('staticField'), 'sbar');
  Expect.equals('sbar', result.reflectee);
  Expect.equals('sbar', C.staticField);
  Expect.equals('sbar', cm.getField(const Symbol('staticField')).reflectee);
  Expect.throws(() => cm.setField(const Symbol('doesntExist'), 'sbar'),
                isNoSuchMethodError,
                'Not defined');

  // ClassMirror invokeConstructor
  result = cm.newInstance(const Symbol(''), []);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('default', result.reflectee.field);
  result = cm.newInstance(const Symbol('named'), ['my value']);
  Expect.isTrue(result.reflectee is C);
  Expect.equals('my value', result.reflectee.field);
  Expect.throws(() => cm.newInstance(const Symbol('doesntExist'), ['my value']),
                isNoSuchMethodError,
                'Not defined');
  Expect.throws(() => cm.newInstance(const Symbol('named'), []),
                isNoSuchMethodError,
                'Wrong arity');

  // LibraryMirror invoke
  LibraryMirror lm = cm.owner;
  result = lm.invoke(const Symbol('libraryFunction'),[':',')']);
  Expect.equals(':)', result.reflectee);
  Expect.throws(() => lm.invoke(const Symbol('doesntExist'), [':',')']),
                isNoSuchMethodError,
                'Not defined');
  Expect.throws(() => lm.invoke(const Symbol('libraryFunction'), [':']),
                isNoSuchMethodError,
                'Wrong arity');

  // LibraryMirror invokeGetter
  result = lm.getField(const Symbol('libraryGetter'));
  Expect.equals('lget a priori', result.reflectee);
  result = lm.getField(const Symbol('libraryField'));
  Expect.equals('a priori', result.reflectee);
  Expect.throws(() => lm.getField(const Symbol('doesntExist')),
                isNoSuchMethodError,
                'Not defined');

  // LibraryMirror invokeSetter
  result = lm.setField(const Symbol('librarySetter'), 'lfoo');
  Expect.equals('lfoo', result.reflectee);
  Expect.equals('lset lfoo', libraryField);
  Expect.equals('lset lfoo',
                lm.getField(const Symbol('libraryField')).reflectee);
  result = lm.setField(const Symbol('libraryField'), 'lbar');
  Expect.equals('lbar', result.reflectee);
  Expect.equals('lbar', libraryField);
  Expect.equals('lbar', lm.getField(const Symbol('libraryField')).reflectee);
  Expect.throws(() => lm.setField(const Symbol('doesntExist'), 'lbar'),
                isNoSuchMethodError,
                'Not defined');
}

testAsync() {
  var future;

  // InstanceMirror invoke
  C c = new C();
  InstanceMirror im = reflect(c);
  future = im.invokeAsync(const Symbol('method'), [2,4,8]);
  expectValueThen(future, (result) {
    Expect.equals('2+4+8', result.reflectee);
  });
  future = im.invokeAsync(const Symbol('method'), [im,im,im]);
  expectValueThen(future, (result) {
    Expect.equals('a C+a C+a C', result.reflectee);
  });
  future = im.invokeAsync(const Symbol('doesntExist'), [2,4,8]);
  expectValueThen(future, (result) {
    Expect.equals('DNU', result.reflectee);
  });
  future = im.invokeAsync(const Symbol('method'), [2, 4]);  // Wrong arity.
  expectValueThen(future, (result) {
    Expect.equals('DNU', result.reflectee);
  });

  // InstanceMirror invokeGetter
  future = im.getFieldAsync(const Symbol('getter'));
  expectValueThen(future, (result) {
    Expect.equals('get default', result.reflectee);
  });
  future = im.getFieldAsync(const Symbol('field'));
  expectValueThen(future, (result) {
    Expect.equals('default', result.reflectee);
  });
  future = im.getFieldAsync(const Symbol('doesntExist'));
  expectValueThen(future, (result) {
    Expect.equals('DNU', result.reflectee);
  });

  // InstanceMirror invokeSetter
  future = im.setFieldAsync(const Symbol('setter'), 'foo');
  expectValueThen(future, (result) {
    Expect.equals('foo', result.reflectee);
    Expect.equals('set foo', c.field);
    return im.setFieldAsync(const Symbol('field'), 'bar');
  }).then((result) {
    Expect.equals('bar', result.reflectee);
    Expect.equals('bar', c.field);
    return im.setFieldAsync(const Symbol('field'), im);
  }).then((result) {
    Expect.equals(im.reflectee, result.reflectee);
    Expect.equals(c, c.field);
  });
  future = im.setFieldAsync(const Symbol('doesntExist'), 'bar');
  expectValueThen(future, (result) {
      Expect.equals('bar', result.reflectee);
  });


  // ClassMirror invoke
  ClassMirror cm = reflectClass(C);
  future = cm.invokeAsync(const Symbol('staticFunction'),[3,4]);
  expectValueThen(future, (result) {
    Expect.equals('(3,4)', result.reflectee);
  });
  future = cm.invokeAsync(const Symbol('staticFunction'),[im,im]);
  expectValueThen(future, (result) {
    Expect.equals('(a C,a C)', result.reflectee);
  });
  future = cm.invokeAsync(const Symbol('doesntExist'),[im,im]);
  expectError(future, isNoSuchMethodError, 'Not defined');
  future = cm.invokeAsync(const Symbol('staticFunction'),[3]);
  expectError(future, isNoSuchMethodError, 'Wrong arity');

  // ClassMirror invokeGetter
  C.staticField = 'initial';  // Reset from synchronous test.
  future = cm.getFieldAsync(const Symbol('staticGetter'));
  expectValueThen(future, (result) {
    Expect.equals('sget initial', result.reflectee);
  });
  future = cm.getFieldAsync(const Symbol('staticField'));
  expectValueThen(future, (result) {
    Expect.equals('initial', result.reflectee);
  });
  future = cm.getFieldAsync(const Symbol('doesntExist'));
  expectError(future, isNoSuchMethodError, 'Not defined');

  // ClassMirror invokeSetter
  future = cm.setFieldAsync(const Symbol('staticSetter'), 'sfoo');
  expectValueThen(future, (result) {
    Expect.equals('sfoo', result.reflectee);
    Expect.equals('sset sfoo', C.staticField);
    return cm.setFieldAsync(const Symbol('staticField'), 'sbar');
  }).then((result) {
    Expect.equals('sbar', result.reflectee);
    Expect.equals('sbar', C.staticField);
    return cm.setFieldAsync(const Symbol('staticField'), im);
  }).then((result) {
    Expect.equals(im.reflectee, result.reflectee);
    Expect.equals(c, C.staticField);
  });
  future = cm.setFieldAsync(const Symbol('doesntExist'), 'sbar');
  expectError(future, isNoSuchMethodError, 'Not defined');

  // ClassMirror invokeConstructor
  future = cm.newInstanceAsync(const Symbol(''), []);
  expectValueThen(future, (result) {
    Expect.isTrue(result.reflectee is C);
    Expect.equals('default', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('named'), ['my value']);
  expectValueThen(future, (result) {
    Expect.isTrue(result.reflectee is C);
    Expect.equals('my value', result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('named'), [im]);
  expectValueThen(future, (result) {
    Expect.isTrue(result.reflectee is C);
    Expect.equals(c, result.reflectee.field);
  });
  future = cm.newInstanceAsync(const Symbol('doesntExist'), ['my value']);
  expectError(future, isNoSuchMethodError, 'Not defined');
  future = cm.newInstanceAsync(const Symbol('named'), []);
  expectError(future, isNoSuchMethodError, 'Wrong arity');


  // LibraryMirror invoke
  LibraryMirror lm = cm.owner;
  future = lm.invokeAsync(const Symbol('libraryFunction'),[':',')']);
  expectValueThen(future, (result) {
    Expect.equals(':)', result.reflectee);
  });
  future = lm.invokeAsync(const Symbol('libraryFunction'),[im,im]);
  expectValueThen(future, (result) {
    Expect.equals('a Ca C', result.reflectee);
  });
  future = lm.invokeAsync(const Symbol('doesntExist'),[im,im]);
  expectError(future, isNoSuchMethodError, 'Not defined');
  future = lm.invokeAsync(const Symbol('libraryFunction'),[':']);
  expectError(future, isNoSuchMethodError, 'Wrong arity');

  // LibraryMirror invokeGetter
  libraryField = 'a priori'; // Reset from synchronous test.
  future = lm.getFieldAsync(const Symbol('libraryGetter'));
  expectValueThen(future, (result) {
    Expect.equals('lget a priori', result.reflectee);
  });
  future = lm.getFieldAsync(const Symbol('libraryField'));
  expectValueThen(future, (result) {
    Expect.equals('a priori', result.reflectee);
  });
  future = lm.getFieldAsync(const Symbol('doesntExist'));
  expectError(future, isNoSuchMethodError, 'Not defined');

  // LibraryMirror invokeSetter
  future = lm.setFieldAsync(const Symbol('librarySetter'), 'lfoo');
  expectValueThen(future, (result) {
    Expect.equals('lfoo', result.reflectee);
    Expect.equals('lset lfoo', libraryField);
    return lm.setFieldAsync(const Symbol('libraryField'), 'lbar');
  }).then((result) {
    Expect.equals('lbar', result.reflectee);
    Expect.equals('lbar', libraryField);
    return lm.setFieldAsync(const Symbol('libraryField'), im);
  }).then((result) {
    Expect.equals(im.reflectee, result.reflectee);
    Expect.equals(c, libraryField);
  });
  future = lm.setFieldAsync(const Symbol('doesntExist'), 'lbar');
  expectError(future, isNoSuchMethodError, 'Not defined');
}

main() {
  testSync();
  testAsync();
}
