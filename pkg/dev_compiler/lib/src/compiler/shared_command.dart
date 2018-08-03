// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Shared code between Analyzer and Kernel CLI interfaces.
///
/// This file should only implement functionality that does not depend on
/// Analyzer/Kernel imports.

/// Variables that indicate which libraries are available in dev compiler.
// TODO(jmesserly): provide an option to compile without dart:html & friends?
Map<String, String> sdkLibraryVariables = {
  'dart.isVM': 'false',
  'dart.library.async': 'true',
  'dart.library.core': 'true',
  'dart.library.collection': 'true',
  'dart.library.convert': 'true',
  // TODO(jmesserly): this is not really supported in dart4web other than
  // `debugger()`
  'dart.library.developer': 'true',
  'dart.library.io': 'false',
  'dart.library.isolate': 'false',
  'dart.library.js': 'true',
  'dart.library.js_util': 'true',
  'dart.library.math': 'true',
  'dart.library.mirrors': 'false',
  'dart.library.typed_data': 'true',
  'dart.library.indexed_db': 'true',
  'dart.library.html': 'true',
  'dart.library.html_common': 'true',
  'dart.library.svg': 'true',
  'dart.library.ui': 'false',
  'dart.library.web_audio': 'true',
  'dart.library.web_gl': 'true',
  'dart.library.web_sql': 'true',
};
