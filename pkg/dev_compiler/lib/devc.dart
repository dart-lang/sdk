// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The main library for the Dart Dev Compiler.

export 'src/analysis_context.dart'
    show createAnalysisContext, createAnalysisContextWithSources;
export 'src/compiler.dart' show BatchCompiler, setupLogger, createErrorReporter;
export 'src/server/server.dart' show DevServer;

// When updating this version, also update the version in the pubspec.
const devCompilerVersion = '0.1.18';
