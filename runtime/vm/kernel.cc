// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel.h"
#include "vm/compiler/frontend/kernel_binary_flowgraph.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {

namespace kernel {

bool FieldHasFunctionLiteralInitializer(const Field& field,
                                        TokenPosition* start,
                                        TokenPosition* end) {
  Zone* zone = Thread::Current()->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(Thread::Current());
  translation_helper.InitFromScript(script);

  StreamingFlowGraphBuilder builder(&translation_helper,
                                    Script::Handle(zone, field.Script()), zone,
                                    TypedData::Handle(zone, field.KernelData()),
                                    field.KernelDataProgramOffset());
  builder.SetOffset(field.kernel_offset());
  kernel::FieldHelper field_helper(&builder);
  field_helper.ReadUntilExcluding(kernel::FieldHelper::kEnd, true);
  return field_helper.FieldHasFunctionLiteralInitializer(start, end);
}

uint32_t KernelSourceFingerprintHelper::CalculateClassFingerprint(
    const Class& klass) {
  Zone* zone = Thread::Current()->zone();

  // Handle typedefs.
  if (klass.IsTypedefClass()) {
    const Function& func = Function::Handle(zone, klass.signature_function());
    return CalculateFunctionFingerprint(func);
  }

  String& name = String::Handle(zone, klass.Name());
  const Array& fields = Array::Handle(zone, klass.fields());
  const Array& functions = Array::Handle(zone, klass.functions());
  const Array& interfaces = Array::Handle(zone, klass.interfaces());
  AbstractType& type = AbstractType::Handle(zone);

  uint32_t hash = 0;
  hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());

  type ^= klass.super_type();
  if (!type.IsNull()) {
    name ^= type.Name();
    hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());
  }

  type ^= klass.mixin();
  if (!type.IsNull()) {
    name ^= type.Name();
    hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());
  }

  Field& field = Field::Handle(zone);
  // Calculate fingerprint for the class fields.
  for (intptr_t i = 0; i < fields.Length(); ++i) {
    field ^= fields.At(i);
    uint32_t fingerprint = CalculateFieldFingerprint(field);
    hash = KernelFingerprintHelper::CalculateHash(hash, fingerprint);
  }

  // Calculate fingerprint for the class functions.
  Function& func = Function::Handle(zone);
  for (intptr_t i = 0; i < functions.Length(); ++i) {
    func ^= functions.At(i);
    uint32_t fingerprint = CalculateFunctionFingerprint(func);
    hash = KernelFingerprintHelper::CalculateHash(hash, fingerprint);
  }

  // Calculate fingerprint for the interfaces.
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    name ^= type.Name();
    hash = KernelFingerprintHelper::CalculateHash(hash, name.Hash());
  }

  return hash;
}

uint32_t KernelSourceFingerprintHelper::CalculateFieldFingerprint(
    const Field& field) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& script = Script::Handle(zone, field.Script());

  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  KernelFingerprintHelper helper(zone, &translation_helper, script,
                                 TypedData::Handle(zone, field.KernelData()),
                                 field.KernelDataProgramOffset());
  helper.SetOffset(field.kernel_offset());
  return helper.CalculateFieldFingerprint();
}

uint32_t KernelSourceFingerprintHelper::CalculateFunctionFingerprint(
    const Function& func) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Script& script = Script::Handle(zone, func.script());

  TranslationHelper translation_helper(thread);
  translation_helper.InitFromScript(script);

  KernelFingerprintHelper helper(zone, &translation_helper, script,
                                 TypedData::Handle(zone, func.KernelData()),
                                 func.KernelDataProgramOffset());
  helper.SetOffset(func.kernel_offset());
  return helper.CalculateFunctionFingerprint();
}

KernelLineStartsReader::KernelLineStartsReader(
    const dart::TypedData& line_starts_data,
    dart::Zone* zone)
    : line_starts_data_(line_starts_data) {
  TypedDataElementType type = line_starts_data_.ElementType();
  if (type == kInt8ArrayElement) {
    helper_ = new KernelInt8LineStartsHelper();
  } else if (type == kInt16ArrayElement) {
    helper_ = new KernelInt16LineStartsHelper();
  } else if (type == kInt32ArrayElement) {
    helper_ = new KernelInt32LineStartsHelper();
  } else {
    UNREACHABLE();
  }
}

intptr_t KernelLineStartsReader::LineNumberForPosition(
    intptr_t position) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      // If current_start is greater than the desired position, it means that
      // it is for the line after |position|. However, since line numbers
      // start at 1, we just return |i|.
      return i;
    }

    if (current_start == position) {
      return i + 1;
    }
  }
  return line_count;
}

void KernelLineStartsReader::LocationForPosition(intptr_t position,
                                                 intptr_t* line,
                                                 intptr_t* col) const {
  intptr_t line_count = line_starts_data_.Length();
  intptr_t current_start = 0;
  intptr_t previous_start = 0;
  for (intptr_t i = 0; i < line_count; ++i) {
    current_start += helper_->At(line_starts_data_, i);
    if (current_start > position) {
      *line = i;
      if (col != NULL) {
        *col = position - previous_start + 1;
      }
      return;
    }
    if (current_start == position) {
      *line = i + 1;
      if (col != NULL) {
        *col = 1;
      }
      return;
    }
    previous_start = current_start;
  }

  // If the start of any of the lines did not cross |position|,
  // then it means the position falls on the last line.
  *line = line_count;
  if (col != NULL) {
    *col = position - current_start + 1;
  }
}

void KernelLineStartsReader::TokenRangeAtLine(
    intptr_t source_length,
    intptr_t line_number,
    TokenPosition* first_token_index,
    TokenPosition* last_token_index) const {
  ASSERT(line_number <= line_starts_data_.Length());
  intptr_t cumulative = 0;
  for (intptr_t i = 0; i < line_number; ++i) {
    cumulative += helper_->At(line_starts_data_, i);
  }
  *first_token_index = dart::TokenPosition(cumulative);
  if (line_number == line_starts_data_.Length()) {
    *last_token_index = dart::TokenPosition(source_length);
  } else {
    *last_token_index = dart::TokenPosition(
        cumulative + helper_->At(line_starts_data_, line_number) - 1);
  }
}

int32_t KernelLineStartsReader::KernelInt8LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt8(index);
}

int32_t KernelLineStartsReader::KernelInt16LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt16(index << 1);
}

int32_t KernelLineStartsReader::KernelInt32LineStartsHelper::At(
    const dart::TypedData& data,
    intptr_t index) const {
  return data.GetInt32(index << 2);
}

}  // namespace kernel

}  // namespace dart
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
