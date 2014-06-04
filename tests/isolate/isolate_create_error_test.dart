// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make multitest copy and compile these files too.
// OtherScripts=isolate_create_error_helper_echo.dart
// OtherScripts=isolate_create_error_helper_syntax_error.dart
// OtherScripts=isolate_create_error_helper_lib.dart
// OtherScripts=isolate_create_error_helper_lib2.dart
// OtherScripts=isolate_create_error_helper_lib3.dart
// OtherScripts=isolate_create_error_helper_lib4.dart
// OtherScripts=isolate_create_error_helper_lib5.dart

library isolate.create.error;

import "dart:async";
import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  asyncStart();
  isolateSpawnSuccess();
  isolateBadUriScheme();     /// 01: ok
  isolateBadServerUri();     /// 02: ok
  isolate404Uri();           /// 03: ok
  isolateMissingFileUri();   /// 04: ok
  isolateBadParse();         /// 05: ok
  isolateNoMain();           /// 06: ok
  isolateBadMain();          /// 07: ok
  isolateBoolMain();         /// 08: ok
  isolateFuncGetMain();      /// 09: ok
  isolateFuncConstMain();    /// 10: ok
  asyncEnd();
}

badSuccess(x) {
  Expect.fail("Unexpected non-error: $x");
}

void isolateSpawnSuccess() {
  // Canary case. If this case fails, either spawnUri isn't supported, or
  // relative URI references don't work.
  asyncStart();
  ReceivePort r = new ReceivePort();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("isolate_create_error_helper_echo.dart"), ["echo"], r.sendPort);
  result.then((Isolate isolate) {
    r.first.then((m) {
      asyncEnd();
      Expect.equals("echo", m);
    });
  });
}

void isolateBadUriScheme() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("wtf://example.com/NOT"), ["A"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateBadServerUri() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("http://nosuchserver-dartlang.org/index.html"), ["B"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolate404Uri() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("http://dartlang.org/THISPAGENOTFOUND"), ["C"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateMissingFileUri() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./THISFILENOTFOUND"), ["D"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateBadParse() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_syntax_error.dart"),
                ["E"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateNoMain() {
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_lib.dart"), ["F"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateBadMain() {
  // Spawned library has a main method expecting three arguments.
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_lib2.dart"), ["G"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateBoolMain() {
  // Spawned library has a bool main field.
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_lib3.dart"), ["H"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateFuncGetMain() {
  // Spawned library has a lazy final main field with a function type.
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_lib4.dart"), ["I"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}

void isolateFuncConstMain() {
  // Spawned library has a const main field with a function type.
  asyncStart();
  Future<Isolate> result = Isolate.spawnUri(
      Uri.parse("./isolate_create_error_helper_lib5.dart"), ["J"], null);
  result.then(badSuccess, onError: (e) {
    Expect.isTrue(e is IsolateSpawnException);
    asyncEnd();
  });
}


