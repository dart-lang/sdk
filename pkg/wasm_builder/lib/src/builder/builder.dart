// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'data_segment.dart' show DataSegmentBuilder;
export 'data_segments.dart' show DataSegmentsBuilder;
export 'elements.dart' show ElementsBuilder;
export 'exports.dart' show ExportsBuilder;
export 'function.dart' show FunctionBuilder;
export 'functions.dart' show FunctionsBuilder;
export 'global.dart' show GlobalBuilder;
export 'globals.dart' show GlobalsBuilder;
export 'instructions.dart'
    show
        Catch,
        CatchAll,
        CatchAllRef,
        CatchRef,
        InstructionsBuilder,
        Label,
        TryTableCatch,
        ValidationError;
export 'memories.dart' show MemoriesBuilder;
export 'module.dart' show ModuleBuilder;
export 'tables.dart' show TablesBuilder;
export 'tags.dart' show TagsBuilder;
export 'types.dart' show TypesBuilder;

mixin Builder<T> {
  T? _built;

  bool get isBuilt => _built != null;

  T build() => _built ??= forceBuild();

  T forceBuild();
}
