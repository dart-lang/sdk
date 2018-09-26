#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dartdevc.dart' as dartdevc;

/// Experimental command line entry point for Dart Development Compiler.
/// Unlike `dartdevc` this version uses the shared front end and IR.
main(List<String> args) => dartdevc.main(args.toList()..add('--kernel'));
