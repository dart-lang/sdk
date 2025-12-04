// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test edge cases where the public name is valid.

// SharedOptions=--enable-experiment=private-named-parameters

import 'package:expect/expect.dart';

/// Can be a built-in identifier.
class BuiltInIdentifier {
  BuiltInIdentifier({
    required this._abstract,
    required this._as,
    required this._covariant,
    required this._deferred,
    required this._dynamic,
    required this._export,
    required this._extension,
    required this._external,
    required this._factory,
    required this._Function,
    required this._get,
    required this._implements,
    required this._import,
    required this._interface,
    required this._late,
    required this._library,
    required this._mixin,
    required this._operator,
    required this._part,
    required this._required,
    required this._set,
    required this._static,
    required this._typedef,
  });

  String? _abstract;
  String? _as;
  String? _covariant;
  String? _deferred;
  String? _dynamic;
  String? _export;
  String? _extension;
  String? _external;
  String? _factory;
  String? _Function;
  String? _get;
  String? _implements;
  String? _import;
  String? _interface;
  String? _late;
  String? _library;
  String? _mixin;
  String? _operator;
  String? _part;
  String? _required;
  String? _set;
  String? _static;
  String? _typedef;
}

/// Can be one of the other contextual keywords.
class OtherIdentifier {
  OtherIdentifier({
    required this._async,
    required this._await,
    required this._hide,
    required this._of,
    required this._on,
    required this._show,
    required this._sync,
    required this._type,
    required this._yield,
  });

  String? _async;
  String? _await;
  String? _hide;
  String? _of;
  String? _on;
  String? _show;
  String? _sync;
  String? _type;
  String? _yield;
}

/// Can start with a dollar sign.
class Dollar {
  Dollar({required this._$, required this._$dollar});

  String? _$;
  String? _$dollar;
}

void main() {
  var b = BuiltInIdentifier(
    abstract: 'abstract',
    as: 'as',
    covariant: 'covariant',
    deferred: 'deferred',
    dynamic: 'dynamic',
    export: 'export',
    extension: 'extension',
    external: 'external',
    factory: 'factory',
    Function: 'Function',
    get: 'get',
    implements: 'implements',
    import: 'import',
    interface: 'interface',
    late: 'late',
    library: 'library',
    mixin: 'mixin',
    operator: 'operator',
    part: 'part',
    required: 'required',
    set: 'set',
    static: 'static',
    typedef: 'typedef',
  );
  Expect.equals(b._abstract, 'abstract');
  Expect.equals(b._as, 'as');
  Expect.equals(b._covariant, 'covariant');
  Expect.equals(b._deferred, 'deferred');
  Expect.equals(b._dynamic, 'dynamic');
  Expect.equals(b._export, 'export');
  Expect.equals(b._extension, 'extension');
  Expect.equals(b._external, 'external');
  Expect.equals(b._factory, 'factory');
  Expect.equals(b._Function, 'Function');
  Expect.equals(b._get, 'get');
  Expect.equals(b._implements, 'implements');
  Expect.equals(b._import, 'import');
  Expect.equals(b._interface, 'interface');
  Expect.equals(b._late, 'late');
  Expect.equals(b._library, 'library');
  Expect.equals(b._mixin, 'mixin');
  Expect.equals(b._operator, 'operator');
  Expect.equals(b._part, 'part');
  Expect.equals(b._required, 'required');
  Expect.equals(b._set, 'set');
  Expect.equals(b._static, 'static');
  Expect.equals(b._typedef, 'typedef');

  var o = OtherIdentifier(
    async: 'async',
    await: 'await',
    hide: 'hide',
    of: 'of',
    on: 'on',
    show: 'show',
    sync: 'sync',
    type: 'type',
    yield: 'yield',
  );
  Expect.equals(o._async, 'async');
  Expect.equals(o._await, 'await');
  Expect.equals(o._hide, 'hide');
  Expect.equals(o._of, 'of');
  Expect.equals(o._on, 'on');
  Expect.equals(o._show, 'show');
  Expect.equals(o._sync, 'sync');
  Expect.equals(o._type, 'type');
  Expect.equals(o._yield, 'yield');

  var d = Dollar($: 'only', $dollar: 'start');
  Expect.equals(d._$, 'only');
  Expect.equals(d._$dollar, 'start');
}
