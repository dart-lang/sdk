// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'data_segments.dart' show DataSegmentBuilder, DataSegmentsBuilder;
export 'exports.dart' show ExportsBuilder;
export 'globals.dart' show GlobalsBuilder, GlobalBuilder;
export 'functions.dart' show FunctionsBuilder, FunctionBuilder;
export 'memories.dart' show MemoriesBuilder;
export 'module.dart' show ModuleBuilder;
export 'tables.dart' show TablesBuilder, TableBuilder;
export 'tags.dart' show TagsBuilder;
export 'types.dart' show TypesBuilder;
export 'instructions.dart' show InstructionsBuilder, Label, ValidationError;

mixin Builder<T> {
  T? _built;

  T build() => _built ??= forceBuild();

  T forceBuild();
}
