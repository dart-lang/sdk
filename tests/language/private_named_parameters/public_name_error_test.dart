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
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
  // [cfe] A private named parameter must have a corresponding public name.

  String? _;
}

/// Public name can't start with digit.
class Digit {
  Digit({
    required this._123,
    //            ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._1more,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
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
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.

    required this.__tooPrivate,
    //            ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
  });

  String? __;
  String? __tooPrivate;
}


/// Public name can't be a reserved word.
class Reserved {
  Reserved({
    required this._assert,
    //            ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._break,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._case,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._catch,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._class,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._const,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._continue,
    //            ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._default,
    //            ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._do,
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._else,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._enum,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._extends,
    //            ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._false,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._final,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._finally,
    //            ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._for,
    //            ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._if,
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._in,
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._is,
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._new,
    //            ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._null,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._rethrow,
    //            ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._return,
    //            ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._super,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._switch,
    //            ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._this,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._throw,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._true,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._try,
    //            ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._var,
    //            ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._void,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._while,
    //            ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
    required this._with,
    //            ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME
    // [cfe] A private named parameter must have a corresponding public name.
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
