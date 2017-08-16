// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_H_
#define RUNTIME_VM_KERNEL_H_

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/token_position.h"

namespace dart {

class Field;
class ParsedFunction;
class Zone;

namespace kernel {

class Reader;

class StringIndex {
 public:
  StringIndex() : value_(-1) {}
  explicit StringIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};

class NameIndex {
 public:
  NameIndex() : value_(-1) {}
  explicit NameIndex(int value) : value_(value) {}

  operator int() const { return value_; }

 private:
  int value_;
};

class Field {
 public:
  enum Flags {
    kFlagFinal = 1 << 0,
    kFlagConst = 1 << 1,
    kFlagStatic = 1 << 2,
  };
};

class Constructor {
 public:
  enum Flags {
    kFlagConst = 1 << 0,
    kFlagExternal = 1 << 1,
  };
};

class Procedure {
 public:
  enum Flags {
    kFlagStatic = 1 << 0,
    kFlagAbstract = 1 << 1,
    kFlagExternal = 1 << 2,
    kFlagConst = 1 << 3,  // Only for external const factories.
  };

  // Keep in sync with package:dynamo/lib/ast.dart:ProcedureKind
  enum ProcedureKind {
    kMethod,
    kGetter,
    kSetter,
    kOperator,
    kFactory,

    kIncompleteProcedure = 255
  };
};

class FunctionNode {
 public:
  enum AsyncMarker {
    kSync = 0,
    kSyncStar = 1,
    kAsync = 2,
    kAsyncStar = 3,
    kSyncYielding = 4,
  };
};

class VariableDeclaration {
 public:
  enum Flags {
    kFlagFinal = 1 << 0,
    kFlagConst = 1 << 1,
  };
};

class YieldStatement {
 public:
  enum {
    kFlagYieldStar = 1 << 0,
    kFlagNative = 1 << 1,
  };
};

class LogicalExpression {
 public:
  enum Operator { kAnd, kOr };
};

class Program {
 public:
  ~Program() {
    free(const_cast<uint8_t*>(kernel_data_));
    kernel_data_ = NULL;
  }

  static Program* ReadFrom(Reader* reader);

  NameIndex main_method() { return main_method_reference_; }
  intptr_t string_table_offset() { return string_table_offset_; }
  intptr_t name_table_offset() { return name_table_offset_; }
  const uint8_t* kernel_data() { return kernel_data_; }
  intptr_t kernel_data_size() { return kernel_data_size_; }
  intptr_t library_count() { return library_count_; }

 private:
  Program() : kernel_data_(NULL), kernel_data_size_(-1) {}

  NameIndex main_method_reference_;  // Procedure.
  intptr_t library_count_;

  // The offset from the start of the binary to the start of the string table.
  intptr_t string_table_offset_;

  // The offset from the start of the binary to the canonical name table.
  intptr_t name_table_offset_;

  const uint8_t* kernel_data_;
  intptr_t kernel_data_size_;

  DISALLOW_COPY_AND_ASSIGN(Program);
};

ParsedFunction* ParseStaticFieldInitializer(Zone* zone,
                                            const dart::Field& field);

}  // namespace kernel

kernel::Program* ReadPrecompiledKernelFromBuffer(const uint8_t* buffer,
                                                 intptr_t buffer_length);

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // RUNTIME_VM_KERNEL_H_
