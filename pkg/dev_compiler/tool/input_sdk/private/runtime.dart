// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._runtime;

import 'dart:async';
import 'dart:collection';

import 'dart:_foreign_helper' show JS, JSExportName, rest, spread;
import 'dart:_interceptors' show JSArray;
import 'dart:_js_helper' show SyncIterable, CastErrorImplementation, getTraceFromException;

part 'classes.dart';
part 'errors.dart';
part 'generators.dart';
part 'operations.dart';
part 'rtti.dart';
part 'types.dart';
part 'utils.dart';

// From dart_utils
final defineLazyClass = JS('', '$defineLazy');
final defineLazyProperties = JS('', '$defineLazy');
final defineLazyClassGeneric = JS('', '$defineLazyProperty');

// Renames
@JSExportName('as')
final as_ = JS('', '$cast');

@JSExportName('is')
final is_ = JS('', '$instanceOf');

@JSExportName('global')
final global_ = JS('', 'typeof window == "undefined" ? global : window');
final JsSymbol = JS('', 'Symbol');

// TODO(vsm): This is referenced (as init.globalState) from
// isolate_helper.dart.  Where should it go?
// See: https://github.com/dart-lang/dev_compiler/issues/164
// exports.globalState = null;
// TODO(ochafik).
// _js_helper.checkNum = operations.notNull;
