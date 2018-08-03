// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing;

export 'dart:async' show Future;

export 'src/discover.dart';

export 'src/test_description.dart'
    show FileBasedTestDescription, TestDescription;

export 'src/chain.dart' show Chain, ChainContext, Result, Step;

export 'src/stdio_process.dart' show StdioProcess;

export 'src/run.dart' show run, runMe;

export 'src/expectation.dart' show Expectation, ExpectationSet;
