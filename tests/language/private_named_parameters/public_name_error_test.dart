// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A private named parameter must have a corresponding public name that is a
/// valid non-private Dart identifier.

// SharedOptions=--enable-experiment=private-named-parameters

/// Public name can't be empty.
class Empty {
  Empty({required this._});
  //                   ^
  // [analyzer] unspecified
  // [cfe] unspecified

  String? _;
}

/// Public name can't start with digit.
class Digit {
  Digit({
    required this._123,
    //   ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._1more,
    //   ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  });

  String? _123;
  String? _1more;
}

/// The public name derived from a private named parameter can't itself be a
/// private identifier.
class Private {
  Private({
    required this.__,
    //            ^^
    // [analyzer] unspecified
    // [cfe] unspecified

    required this.__tooPrivate,
    //            ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  });

  String? __;
  String? __tooPrivate;
}


/// Public name can't be a reserved word.
class Reserved {
  Reserved({
    required this._assert,
    //            ^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._break,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._case,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._catch,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._class,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._const,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._continue,
    //            ^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._default,
    //            ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._do,
    //            ^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._else,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._enum,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._extends,
    //            ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._false,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._final,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._finally,
    //            ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._for,
    //            ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._if,
    //            ^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._in,
    //            ^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._is,
    //            ^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._new,
    //            ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._null,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._rethrow,
    //            ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._return,
    //            ^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._super,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._switch,
    //            ^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._this,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._throw,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._true,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._try,
    //            ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._var,
    //            ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._void,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._while,
    //            ^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
    required this._with,
    //            ^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  });

  String? _assert;
  String? _break;
  String? _case;
  String? _catch;
  String? _class;
  String? _const;
  String? _continue;
  String? _default;
  String? _do;
  String? _else;
  String? _enum;
  String? _extends;
  String? _false;
  String? _final;
  String? _finally;
  String? _for;
  String? _if;
  String? _in;
  String? _is;
  String? _new;
  String? _null;
  String? _rethrow;
  String? _return;
  String? _super;
  String? _switch;
  String? _this;
  String? _throw;
  String? _true;
  String? _try;
  String? _var;
  String? _void;
  String? _while;
  String? _with;
}

void main() {}
