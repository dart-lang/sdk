// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test reproduces https://github.com/dart-lang/sdk/issues/29709.

library dart.async;

part 'dart:async/future.dart';
//   ^
// [cfe] Can't use 'org-dartlang-untranslatable-uri:dart%3Aasync%2Ffuture.dart' as a part, because it has no 'part of' declaration.
//   ^
// [cfe] Not found: 'dart:async/future.dart'

main() {}
