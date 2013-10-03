// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class CodeEmitterHelper {
  CodeEmitterTask task;

  Namer get namer => task.namer;

  JavaScriptBackend get backend => task.backend;

  Compiler get compiler => task.compiler;

  String get n => task.n;

  String get _ => task._;

  String get N => task.N;
}
