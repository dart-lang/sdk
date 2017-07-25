// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.mocks;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:mockito/mockito.dart';

class MockAnalysisError extends Mock implements AnalysisError {}

class MockAnalysisErrorInfo extends Mock implements AnalysisErrorInfo {}

class MockCommandLineOptions extends Mock implements CommandLineOptions {}

class MockErrorCode extends Mock implements ErrorCode {}

class MockErrorType extends Mock implements ErrorType {}

class MockLineInfo extends Mock implements LineInfo {}

class MockLineInfo_Location extends Mock implements LineInfo_Location {}

class MockSource extends Mock implements Source {}
