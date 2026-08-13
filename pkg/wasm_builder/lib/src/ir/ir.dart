// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// IR types are considered logically immutable.
// TODO(joshualitt): Make all of the ir types full immutable.
library;

export 'data_segment.dart' show BaseDataSegment, DataSegment;
export 'data_segments.dart' show DataSegments;
export 'element.dart'
    show
        ActiveElementSegment,
        ActiveExpressionElementSegment,
        ActiveFunctionElementSegment,
        DeclarativeElementSegment,
        ElementSegment;
export 'elements.dart' show Elements;
export 'exports.dart' show Export, Exportable, Exports;
export 'finalizable.dart' show Finalizable, FinalizableIndex;
export 'function.dart'
    show BaseFunction, DefinedFunction, FunctionExport, ImportedFunction, Local;
export 'functions.dart' show Functions;
export 'global.dart' show DefinedGlobal, Global, GlobalExport, ImportedGlobal;
export 'globals.dart' show Globals;
export 'imports.dart' show Import, Imports;
export 'indexable.dart' show Indexable;
export 'instruction.dart';
export 'instructions.dart' show Instructions;
export 'memories.dart' show Memories;
export 'memory.dart' show DefinedMemory, ImportedMemory, Memory, MemoryExport;
export 'module.dart' show Module;
export 'table.dart' show DefinedTable, ImportedTable, Table, TableExport;
export 'tables.dart' show Tables;
export 'tags.dart' show DefinedTag, ImportedTag, Tag, TagExport, Tags;
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
export 'types.dart' show Types;
