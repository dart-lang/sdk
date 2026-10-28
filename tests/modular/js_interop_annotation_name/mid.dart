// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'base.dart';

@JS()
external void eval(String code);

const String topLevelName = '$topLevelNamePrefix$topLevelNameSuffix';
const String topLevelNamePrefix = 'topLevel';
const String topLevelNameSuffix = 'Suffix';

const String topLevelConstantName = 'topLevelConstant';

class Mid {
  static const String memberName = Base.memberName;
  static const String exportName = Base.exportName;
}

// Test that not constant-evaluated string interpolation works as intended.
// Since `main.dart` doesn't use `topLevelName`, this will stay as an
// unevaluated value.
@JS(topLevelName)
external String get topLevel;

// Test that constant-evaluated string works as intended. Since `main.dart` does
// use `topLevelConstantName`, this will be evaluated.
@JS(topLevelConstantName)
external String get topLevelConstant;

@JS()
extension type JSClass._(JSObject _) implements JSObject {
  external JSClass();

  // Test that recursive unevaluated strings work as intended.
  @JS(Base.memberName)
  external String member();
}

class Export {
  // Same test as `member` but for `@JSExport`.
  @JSExport(Mid.exportName)
  String export() => 'baseExport';
}

void addTopLevel() {
  eval("globalThis.$topLevelName = 'topLevel';");
}
