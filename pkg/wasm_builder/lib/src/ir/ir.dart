// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// IR types are considered logically immutable.
// TODO(joshualitt): Make all of the ir types full immutable.
library;

export 'data_segments.dart' show DataSegments;
export 'data_segment.dart' show BaseDataSegment, DataSegment;
export 'exports.dart' show Export, Exportable, Exports;
export 'finalizable.dart' show Finalizable, FinalizableIndex;
export 'indexable.dart' show Indexable;
export 'imports.dart' show Import, Imports;
export 'globals.dart' show Globals;
export 'global.dart' show DefinedGlobal, Global, ImportedGlobal, GlobalExport;
export 'functions.dart' show Functions;
export 'function.dart'
    show BaseFunction, DefinedFunction, ImportedFunction, Local, FunctionExport;
export 'memories.dart' show Memories;
export 'memory.dart' show DefinedMemory, ImportedMemory, Memory, MemoryExport;
export 'module.dart' show Module;
export 'tables.dart' show Tables;
export 'table.dart' show DefinedTable, ImportedTable, Table, TableExport;
export 'tags.dart' show DefinedTag, ImportedTag, Tag, Tags, TagExport;
export 'types.dart' show Types;
export 'instructions.dart' show Instructions;
export 'instruction.dart';
export 'type.dart'
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
        ValueType;
