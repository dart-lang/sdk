// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The Dart Front End contains logic to build summaries and kernel programs
/// from Dart sources. The APIs exposed here are designed for tools in the Dart
/// ecosystem that need to load sources and convert them to these formats.
library front_end.front_end;

export 'compiler_options.dart';
export 'compilation_message.dart';
export 'kernel_generator.dart';
export 'summary_generator.dart';
export 'file_system.dart';
