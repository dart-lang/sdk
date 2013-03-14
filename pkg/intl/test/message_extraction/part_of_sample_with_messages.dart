// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.part of sample;

part of sample;

class YouveGotMessages {

  // A static message, rather than a standalone function.
  static staticMessage() => Intl.message("This comes from a static method",
      name: 'staticMessage');

  // An instance method, rather than a standalone function.
  method() => Intl.message("This comes from a method", name: 'method');

  // A non-lambda, i.e. not using => syntax, and with an additional statement
  // before the Intl.message call.
  nonLambda() {
    // TODO(alanknight): I'm really not sure that this shouldn't be disallowed.
    var x = 'something';
    return Intl.message("This method is not a lambda", name: 'nonLambda');
  }

// TODO(alanknight): Support plurals and named arguments.
//  plurals(num) => Intl.message("""
//One of the tricky things is ${Intl.plural(num,
//      {
//        '0' : 'the plural form',
//        '1' : 'the plural form',
//        'other' : 'plural forms'})}""",
//    name: "plurals");
//
//namedArgs({thing}) => Intl.message("The thing is, $thing", name: "namedArgs");
}
