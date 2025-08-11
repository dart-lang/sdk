// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A shared sink for standard error reporting.
StringSink errorSink = stderr;

/// A shared sink for standard out reporting.
StringSink outSink = stdout;

/// Synchronously read the contents of the file at the given [path] as a string.
String readFile(String path) => File(path).readAsStringSync();
