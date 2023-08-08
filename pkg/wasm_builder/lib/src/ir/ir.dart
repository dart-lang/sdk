// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// IR types are considered logically immutable.
// TODO(joshualitt): Make all of the ir types full immutable.

export 'data_segments.dart' show BaseDataSegment, DataSegment, DataSegments;
export 'exports.dart' show Export, Exportable, Exports;
export 'finalizable.dart' show Finalizable, FinalizableIndex;
export 'indexable.dart' show Indexable;
export 'imports.dart' show Import;
export 'globals.dart' show DefinedGlobal, Global, Globals, ImportedGlobal;
export 'functions.dart'
    show BaseFunction, DefinedFunction, Functions, ImportedFunction, Local;
export 'memories.dart' show DefinedMemory, ImportedMemory, Memories, Memory;
export 'module.dart' show Module;
export 'tables.dart' show DefinedTable, ImportedTable, Table, Tables;
export 'tags.dart' show Tag, Tags;
export 'types.dart'
    show
        ArrayType,
        DataType,
        DefType,
        FieldType,
        FunctionType,
        GlobalType,
        HeapType,
        NumType,
        PackedType,
        RefType,
        StorageType,
        StructType,
        Types,
        ValueType;
export 'instructions.dart';
