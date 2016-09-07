// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_final_fields`

class BadImmutable {
  var _label = 'hola mundo! BadImmutable'; // LINT
  var label = 'hola mundo! BadImmutable'; // OK
}

class GoodImmutable {
  final label = 'hola mundo! BadImmutable', bla = 5; // OK
  final _label = 'hola mundo! BadImmutable', _bla = 5; // OK
}

class GoodMutable {
  var _label = 'hola mundo! GoodMutable';
  var _someInt = 0;
  var _otherInt = 1;

  void changeLabel() {
    _label = 'hello world! GoodMutable';
    _someInt++;
    _otherInt += 2;
  }
}

class MultipleMutable {
  var _label = 'hola mundo! GoodMutable', _offender = 'mumble mumble!'; // LINT
  var _someOther; // LINT

  MultipleMutable() : _someOther = 5;

  MultipleMutable(this._someOther);

  void changeLabel() {
    _label = 'hello world! GoodMutable';
  }
}

class C {
  int _f = 0; // LINT
  void m() {
    String _f;
    _f = '';
  }
}
