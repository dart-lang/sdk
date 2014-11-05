// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class CodeEmitterHelper {
  OldEmitter emitter;

  Namer get namer => emitter.namer;

  JavaScriptBackend get backend => emitter.backend;

  Compiler get compiler => emitter.compiler;

  String get n => emitter.n;

  String get _ => emitter._;

  String get N => emitter.N;
}
