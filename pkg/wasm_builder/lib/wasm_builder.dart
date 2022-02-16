// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/module.dart'
    show
        DataSegment,
        DefinedFunction,
        DefinedGlobal,
        BaseFunction,
        Global,
        ImportedFunction,
        ImportedGlobal,
        Local,
        Memory,
        Module,
        Table;
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
        Rtt,
        StorageType,
        StructType,
        ValueType;
export 'src/instructions.dart' show Instructions, Label, ValidationError;
