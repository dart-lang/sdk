#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A straightforward script that builds the SDK.
///
/// This would be easy enough to do in a shell script, as we go through the
/// command line interface. But being able to build from a Dart library means
/// we can call this during code coverage to get more realistic numbers.

import 'dart:io';

import 'package:dev_compiler/src/compiler/command.dart';

main(List<String> arguments) {
  var args = ['--no-source-map', '--no-emit-metadata'];
  args.addAll(arguments);
  args.addAll([
    'dart:_runtime',
    'dart:_debugger',
    'dart:_foreign_helper',
    'dart:_interceptors',
    'dart:_internal',
    'dart:_isolate_helper',
    'dart:_js_embedded_names',
    'dart:_js_helper',
    'dart:_js_mirrors',
    'dart:_js_primitives',
    'dart:_metadata',
    'dart:_native_typed_data',
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:core',
    'dart:developer',
    'dart:io',
    'dart:isolate',
    'dart:js',
    'dart:js_util',
    'dart:math',
    'dart:mirrors',
    'dart:typed_data',
    'dart:indexed_db',
    'dart:html',
    'dart:html_common',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl',
    'dart:web_sql'
  ]);

  var result = compile(args);
  exit(result);
}
