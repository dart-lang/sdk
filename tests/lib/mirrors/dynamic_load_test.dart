// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:expect/expect.dart';

main() async {
  IsolateMirror isolate = currentMirrorSystem().isolate;
  print(isolate);

  LibraryMirror success =
      await isolate.loadUri(Uri.parse("dynamic_load_success.dart"));
  print(success);
  InstanceMirror result = success.invoke(#advanceCounter, []);
  print(result);
  Expect.equals(1, result.reflectee);
  result = success.invoke(#advanceCounter, []);
  print(result);
  Expect.equals(2, result.reflectee);

  LibraryMirror success2 =
      await isolate.loadUri(Uri.parse("dynamic_load_success.dart"));
  print(success2);
  Expect.equals(success, success2);
  result = success2.invoke(#advanceCounter, []);
  print(result);
  Expect.equals(3, result.reflectee); // Same library, same state.

  LibraryMirror math = await isolate.loadUri(Uri.parse("dart:math"));
  result = math.invoke(#max, [3, 4]);
  print(result);
  Expect.equals(4, result.reflectee);

  Future<LibraryMirror> bad_load = isolate.loadUri(Uri.parse("DOES_NOT_EXIST"));
  var error;
  try {
    await bad_load;
  } catch (e) {
    error = e;
  }
  print(error);
  Expect.isTrue(error.toString().contains("Cannot open file") ||
      error.toString().contains("file not found") ||
      error.toString().contains("No such file or directory") ||
      error.toString().contains("The system cannot find the file specified"));
  Expect.isTrue(error.toString().contains("DOES_NOT_EXIST"));

  Future<LibraryMirror> bad_load2 = isolate.loadUri(Uri.parse("dart:_builtin"));
  var error2;
  try {
    await bad_load2;
  } catch (e) {
    error2 = e;
  }
  print(error2);
  Expect.isTrue(error2.toString().contains("Cannot load"));
  Expect.isTrue(error2.toString().contains("dart:_builtin"));

  // Check error is not sticky.
  LibraryMirror success3 =
      await isolate.loadUri(Uri.parse("dynamic_load_success.dart"));
  print(success3);
  Expect.equals(success, success3);
  result = success3.invoke(#advanceCounter, []);
  print(result);
  Expect.equals(4, result.reflectee); // Same library, same state.

  Future<LibraryMirror> bad_load3 =
      isolate.loadUri(Uri.parse("dynamic_load_error.dart"));
  var error3;
  try {
    await bad_load3;
  } catch (e) {
    error3 = e;
  }
  print(error3);
  Expect.isTrue(error3.toString().contains("library url expected") ||
      error3.toString().contains("Error: Expected a String"));
  Expect.isTrue(error3.toString().contains("dynamic_load_error.dart"));
}
