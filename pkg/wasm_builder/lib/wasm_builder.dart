// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/module.dart'
    show
        DataSegment,
        DefinedFunction,
        DefinedGlobal,
        DefinedMemory,
        DefinedTable,
        BaseFunction,
        Global,
        Import,
        ImportedFunction,
        ImportedGlobal,
        ImportedMemory,
        ImportedTable,
        Local,
        Memory,
        Module,
        Table,
        Tag;
export 'src/types.dart'
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
export 'src/instructions.dart' show Instructions, Label, ValidationError;
