// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_type.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/runtime_api.h"
#include "vm/growable_array.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/locations.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

namespace compiler {

namespace ffi {

const NativePrimitiveType& NativeType::AsPrimitive() const {
  ASSERT(IsPrimitive());
  return static_cast<const NativePrimitiveType&>(*this);
}

bool NativePrimitiveType::IsInt() const {
  switch (representation_) {
    case kInt8:
    case kUint8:
    case kInt16:
    case kUint16:
    case kInt32:
    case kUint32:
    case kInt64:
    case kUint64:
      return true;
    default:
      return false;
  }
}

bool NativePrimitiveType::IsFloat() const {
  return representation_ == kFloat || representation_ == kDouble ||
         representation_ == kHalfDouble;
}

bool NativePrimitiveType::IsVoid() const {
  return representation_ == kVoid;
}

bool NativePrimitiveType::IsSigned() const {
  ASSERT(IsInt() || IsFloat());
  switch (representation_) {
    case kInt8:
    case kInt16:
    case kInt32:
    case kInt64:
    case kFloat:
    case kDouble:
    case kHalfDouble:
      return true;
    case kUint8:
    case kUint16:
    case kUint32:
    case kUint64:
    default:
      return false;
  }
}

static const intptr_t fundamental_size_in_bytes[kVoid + 1] = {
    1,  // kInt8,
    1,  // kUint8,
    2,  // kInt16,
    2,  // kUint16,
    4,  // kInt32,
    4,  // kUint32,
    8,  // kInt64,
    8,  // kUint64,
    4,  // kFloat,
    8,  // kDouble,
    4,  // kHalfDouble
    0,  // kVoid,
};

intptr_t NativePrimitiveType::SizeInBytes() const {
  return fundamental_size_in_bytes[representation_];
}

intptr_t NativePrimitiveType::AlignmentInBytesStack() const {
  switch (CallingConventions::kArgumentStackAlignment) {
    case kAlignedToWordSize:
      // The default is to align stack arguments to word size.
      return compiler::target::kWordSize;
    case kAlignedToWordSizeBut8AlignedTo8: {
      // However, arm32 deviates slightly.
      if (SizeInBytes() == 8) {
        return 8;
      }
      return compiler::target::kWordSize;
    }
    case kAlignedToValueSize:
      // iOS on arm64 only aligns to size.
      return SizeInBytes();
    default:
      UNREACHABLE();
  }
}

intptr_t NativePrimitiveType::AlignmentInBytesField() const {
  switch (CallingConventions::kFieldAlignment) {
    case kAlignedToValueSize:
      // The default is to align fields to their own size.
      return SizeInBytes();
    case kAlignedToValueSizeBut8AlignedTo4: {
      // However, on some 32-bit architectures, 8-byte fields are only aligned
      // to 4 bytes.
      if (SizeInBytes() == 8) {
        return 4;
      }
      return SizeInBytes();
    }
    default:
      UNREACHABLE();
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
bool NativePrimitiveType::IsExpressibleAsRepresentation() const {
  switch (representation_) {
    case kInt8:
    case kUint8:
    case kInt16:
    case kUint16:
    case kHalfDouble:
      return false;
    case kInt32:
    case kUint32:
    case kInt64:
    case kUint64:
    case kFloat:
    case kDouble:
      return true;
    case kVoid:
      return true;
    default:
      UNREACHABLE();  // Make MSVC happy.
  }
}

Representation NativePrimitiveType::AsRepresentation() const {
  ASSERT(IsExpressibleAsRepresentation());
  switch (representation_) {
    case kInt32:
      return kUnboxedInt32;
    case kUint32:
      return kUnboxedUint32;
    case kInt64:
    case kUint64:
      return kUnboxedInt64;
    case kFloat:
      return kUnboxedFloat;
    case kDouble:
      return kUnboxedDouble;
    case kVoid:
      return kUnboxedFfiIntPtr;
    default:
      UNREACHABLE();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

bool NativePrimitiveType::Equals(const NativeType& other) const {
  if (!other.IsPrimitive()) {
    return false;
  }
  return other.AsPrimitive().representation_ == representation_;
}

static PrimitiveType split_fundamental(PrimitiveType in) {
  switch (in) {
    case kInt16:
      return kInt8;
    case kInt32:
      return kInt16;
    case kInt64:
      return kInt32;
    case kUint16:
      return kUint8;
    case kUint32:
      return kUint16;
    case kUint64:
      return kUint32;
    case kDouble:
      return kHalfDouble;
    default:
      UNREACHABLE();
  }
}

NativePrimitiveType& NativePrimitiveType::Split(Zone* zone,
                                                intptr_t index) const {
  ASSERT(index == 0 || index == 1);
  auto new_rep = split_fundamental(representation());
  return *new (zone) NativePrimitiveType(new_rep);
}

static PrimitiveType TypeRepresentation(classid_t class_id) {
  switch (class_id) {
    case kFfiInt8Cid:
      return kInt8;
    case kFfiInt16Cid:
      return kInt16;
    case kFfiInt32Cid:
      return kInt32;
    case kFfiUint8Cid:
      return kUint8;
    case kFfiUint16Cid:
      return kUint16;
    case kFfiUint32Cid:
      return kUint32;
    case kFfiInt64Cid:
    case kFfiUint64Cid:
      return kInt64;
    case kFfiIntPtrCid:
      return compiler::target::kWordSize == 4 ? kInt32 : kInt64;
    case kFfiFloatCid:
      return kFloat;
    case kFfiDoubleCid:
      return kDouble;
    case kFfiPointerCid:
      return compiler::target::kWordSize == 4 ? kUint32 : kInt64;
    case kFfiVoidCid:
      return kVoid;
    case kFfiHandleCid:
      // We never expose this pointer as a Dart int, so no need to make it
      // unsigned on 32 bit architectures.
      return compiler::target::kWordSize == 4 ? kInt32 : kInt64;
    default:
      UNREACHABLE();
  }
}

NativeType& NativeType::FromTypedDataClassId(Zone* zone, classid_t class_id) {
  // TODO(36730): Support composites.
  const auto fundamental_rep = TypeRepresentation(class_id);
  return *new (zone) NativePrimitiveType(fundamental_rep);
}

NativeType& NativeType::FromAbstractType(Zone* zone, const AbstractType& type) {
  // TODO(36730): Support composites.
  return NativeType::FromTypedDataClassId(zone, type.type_class_id());
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static PrimitiveType fundamental_rep(Representation rep) {
  switch (rep) {
    case kUnboxedDouble:
      return kDouble;
    case kUnboxedFloat:
      return kFloat;
    case kUnboxedInt32:
      return kInt32;
    case kUnboxedUint32:
      return kUint32;
    case kUnboxedInt64:
      return kInt64;
    default:
      break;
  }
  UNREACHABLE();
}

NativePrimitiveType& NativeType::FromUnboxedRepresentation(Zone* zone,
                                                           Representation rep) {
  return *new (zone) NativePrimitiveType(fundamental_rep(rep));
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

const char* NativeType::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

static const char* PrimitiveTypeToCString(PrimitiveType rep) {
  switch (rep) {
    case kInt8:
      return "int8";
    case kUint8:
      return "uint8";
    case kInt16:
      return "int16";
    case kUint16:
      return "uint16";
    case kInt32:
      return "int32";
    case kUint32:
      return "uint32";
    case kInt64:
      return "int64";
    case kUint64:
      return "uint64";
    case kFloat:
      return "float";
    case kDouble:
      return "double";
    case kHalfDouble:
      return "half-double";
    case kVoid:
      return "void";
    default:
      UNREACHABLE();
  }
}

void NativeType::PrintTo(BaseTextBuffer* f) const {
  f->AddString("I");
}

void NativePrimitiveType::PrintTo(BaseTextBuffer* f) const {
  f->Printf("%s", PrimitiveTypeToCString(representation_));
}

const char* NativeFunctionType::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void NativeFunctionType::PrintTo(BaseTextBuffer* f) const {
  f->AddString("(");
  for (intptr_t i = 0; i < argument_types_.length(); i++) {
    if (i > 0) {
      f->AddString(", ");
    }
    argument_types_[i]->PrintTo(f);
  }
  f->AddString(") => ");
  return_type_.PrintTo(f);
}

const NativeType& NativeType::WidenTo4Bytes(Zone* zone) const {
  if (IsInt() && SizeInBytes() <= 2) {
    if (IsSigned()) {
      return *new (zone) NativePrimitiveType(kInt32);
    } else {
      return *new (zone) NativePrimitiveType(kUint32);
    }
  }
  return *this;
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
