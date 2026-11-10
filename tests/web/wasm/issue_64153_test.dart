// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS('Constraint')
@staticInterop
abstract class ConstraintJsImpl {}

@JS('Query')
@staticInterop
abstract class QueryJsImpl {}

@JS('query')
external QueryJsImpl queryRaw(QueryJsImpl q, ConstraintJsImpl c);

@JS('createConstraint')
external ConstraintJsImpl createConstraintRaw(JSString name);

abstract class JsWrapper<T extends Object> {
  final T jsObject;
  JsWrapper(this.jsObject);
}

class Query<T extends QueryJsImpl> extends JsWrapper<T> {
  Query(super.jsObject);

  ConstraintJsImpl _createConstraint(String name) {
    return createConstraintRaw(name.toJS);
  }

  Query filter(String name) {
    return Query(queryRaw(jsObject, _createConstraint(name)));
  }
}

class SubQuery<T extends QueryJsImpl> extends Query<T> {
  SubQuery(super.jsObject);
}

void main() {
  eval(r'''
    globalThis.createConstraint = function(name) {
      return { kind: "constraint", name: name };
    };
    globalThis.query = function(q, c) {
      return { kind: "query", base: q, constraint: c };
    };
    globalThis.rootQuery = { kind: "root" };
  ''');

  eval(r'''
    globalThis.getRootQuery = function() {
      return globalThis.rootQuery;
    };
  ''');

  final root = SubQuery<QueryJsImpl>(_getRootQuery());
  final filtered = root.filter('test');
  Expect.isNotNull(filtered);
}

@JS('getRootQuery')
external QueryJsImpl _getRootQuery();
