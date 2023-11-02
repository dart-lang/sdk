// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_type.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
#include "vm/compiler/ffi/abi.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
#include "vm/compiler/backend/locations.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

#if !defined(FFI_UNIT_TESTS)
#include "vm/symbols.h"
#endif

namespace dart {

namespace compiler {

namespace ffi {

PrimitiveType PrimitiveTypeFromSizeInBytes(intptr_t size) {
  ASSERT(size <= 8);
  ASSERT(size > 0);
  switch (size) {
    case 1:
      return kUint8;
    case 2:
      return kUint16;
    case 4:
      return kUint32;
    case 8:
      // Dart unboxed Representation for unsigned and signed is equal.
      return kInt64;
  }
  UNREACHABLE();
}

const NativePrimitiveType& NativeType::AsPrimitive() const {
  ASSERT(IsPrimitive());
  return static_cast<const NativePrimitiveType&>(*this);
}

const NativeArrayType& NativeType::AsArray() const {
  ASSERT(IsArray());
  return static_cast<const NativeArrayType&>(*this);
}

const NativeCompoundType& NativeType::AsCompound() const {
  ASSERT(IsCompound());
  return static_cast<const NativeCompoundType&>(*this);
}

const NativeStructType& NativeType::AsStruct() const {
  ASSERT(IsStruct());
  return static_cast<const NativeStructType&>(*this);
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

intptr_t NativePrimitiveType::AlignmentInBytesStack(bool is_vararg) const {
  switch (CallingConventions::kArgumentStackAlignment) {
    case kAlignedToWordSize:
      // The default is to align stack arguments to word size.
      return compiler::target::kWordSize;
    case kAlignedToWordSizeAndValueSize:
      // However, arm32+riscv32 align to the greater of word size or value size.
      return Utils::Maximum(SizeInBytes(),
                            static_cast<intptr_t>(compiler::target::kWordSize));
    case kAlignedToValueSize:
      // iOS on arm64 only aligns to size.
      return SizeInBytes();
    default:
      UNREACHABLE_THIS();
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
      UNREACHABLE_THIS();
  }
}

static bool ContainsHomogeneousFloatsInternal(const NativeTypes& types);

// Keep consistent with
// pkg/vm/lib/transformations/ffi_definitions.dart:StructLayout:_calculateLayout.
NativeStructType& NativeStructType::FromNativeTypes(Zone* zone,
                                                    const NativeTypes& members,
                                                    intptr_t member_packing) {
  intptr_t offset = 0;

  const intptr_t kAtLeast1ByteAligned = 1;
  // If this struct is nested in another struct, it should be aligned to the
  // largest alignment of its members.
  intptr_t alignment_field = kAtLeast1ByteAligned;
  // If this struct is passed on the stack, it should be aligned to the largest
  // alignment of its members when passing those members on the stack.
  intptr_t alignment_stack = kAtLeast1ByteAligned;
  intptr_t alignment_stack_vararg = kAtLeast1ByteAligned;
#if (defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS)) &&    \
    defined(TARGET_ARCH_ARM64)
  // On iOS64 and MacOS arm64 stack values can be less aligned than wordSize,
  // which deviates from the arm64 ABI.
  ASSERT(CallingConventions::kArgumentStackAlignment == kAlignedToValueSize);
  // Because the arm64 ABI aligns primitives to word size on the stack, every
  // struct will be automatically aligned to word size. iOS64 does not align
  // the primitives to word size, so we set structs to align to word size for
  // iOS64.
  // However, homogenous structs are treated differently. They are aligned to
  // their member alignment. (Which is 4 in case of a homogenous float).
  // Source: manual testing.
  if (!ContainsHomogeneousFloatsInternal(members)) {
    alignment_stack = compiler::target::kWordSize;
  }
  alignment_stack_vararg = compiler::target::kWordSize;
#endif

  auto& member_offsets =
      *new (zone) ZoneGrowableArray<intptr_t>(zone, members.length());
  for (intptr_t i = 0; i < members.length(); i++) {
    const NativeType& member = *members[i];
    const intptr_t member_size = member.SizeInBytes();
    const intptr_t member_align_field =
        Utils::Minimum(member.AlignmentInBytesField(), member_packing);
    intptr_t member_align_stack = member.AlignmentInBytesStack();
    if (member_align_stack > member_packing &&
        member_packing < compiler::target::kWordSize) {
      member_align_stack = compiler::target::kWordSize;
    }
    offset = Utils::RoundUp(offset, member_align_field);
    member_offsets.Add(offset);
    offset += member_size;
    alignment_field = Utils::Maximum(alignment_field, member_align_field);
    alignment_stack = Utils::Maximum(alignment_stack, member_align_stack);
    alignment_stack_vararg =
        Utils::Maximum(alignment_stack_vararg, member_align_stack);
  }
  const intptr_t size = Utils::RoundUp(offset, alignment_field);

  return *new (zone)
      NativeStructType(members, member_offsets, size, alignment_field,
                       alignment_stack, alignment_stack_vararg);
}

// Keep consistent with
// pkg/vm/lib/transformations/ffi_definitions.dart:StructLayout:_calculateLayout.
NativeUnionType& NativeUnionType::FromNativeTypes(Zone* zone,
                                                  const NativeTypes& members) {
  intptr_t size = 0;

  const intptr_t kAtLeast1ByteAligned = 1;
  // If this union is nested in a struct, it should be aligned to the
  // largest alignment of its members.
  intptr_t alignment_field = kAtLeast1ByteAligned;
  // If this union is passed on the stack, it should be aligned to the largest
  // alignment of its members when passing those members on the stack.
  intptr_t alignment_stack = kAtLeast1ByteAligned;

  for (intptr_t i = 0; i < members.length(); i++) {
    const NativeType& member = *members[i];
    const intptr_t member_size = member.SizeInBytes();
    const intptr_t member_align_field = member.AlignmentInBytesField();
    const intptr_t member_align_stack = member.AlignmentInBytesStack();
    size = Utils::Maximum(size, member_size);
    alignment_field = Utils::Maximum(alignment_field, member_align_field);
    alignment_stack = Utils::Maximum(alignment_stack, member_align_stack);
  }
  size = Utils::RoundUp(size, alignment_field);

  return *new (zone)
      NativeUnionType(members, size, alignment_field, alignment_stack);
}

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
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
    case kUint64:  // We don't actually have a kUnboxedUint64.
    case kFloat:
    case kDouble:
      return true;
    case kVoid:
      return true;
    default:
      UNREACHABLE_THIS();  // Make MSVC happy.
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
      UNREACHABLE_THIS();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

bool NativePrimitiveType::Equals(const NativeType& other) const {
  if (!other.IsPrimitive()) {
    return false;
  }
  return other.AsPrimitive().representation_ == representation_;
}

bool NativeArrayType::Equals(const NativeType& other) const {
  if (!other.IsArray()) {
    return false;
  }
  return other.AsArray().length_ == length_ &&
         other.AsArray().element_type_.Equals(element_type_);
}

bool NativeCompoundType::Equals(const NativeType& other) const {
  if (!other.IsCompound()) {
    return false;
  }
  const auto& other_compound = other.AsCompound();
  const auto& other_members = other_compound.members_;
  if (other_members.length() != members_.length()) {
    return false;
  }
  for (intptr_t i = 0; i < members_.length(); i++) {
    if (!members_[i]->Equals(*other_members[i])) {
      return false;
    }
  }
  return true;
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
    case kFfiBoolCid:
    case kFfiUint8Cid:
      return kUint8;
    case kFfiUint16Cid:
      return kUint16;
    case kFfiUint32Cid:
      return kUint32;
    case kFfiInt64Cid:
    case kFfiUint64Cid:
      return kInt64;
    case kFfiFloatCid:
      return kFloat;
    case kFfiDoubleCid:
      return kDouble;
    case kPointerCid:
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

const NativeType& NativeType::FromTypedDataClassId(Zone* zone,
                                                   classid_t class_id) {
  ASSERT(IsFfiPredefinedClassId(class_id));
  const auto fundamental_rep = TypeRepresentation(class_id);
  return *new (zone) NativePrimitiveType(fundamental_rep);
}

#if !defined(FFI_UNIT_TESTS)
static const NativeType* CompoundFromPragma(Zone* zone,
                                            const Instance& pragma,
                                            bool is_struct,
                                            const char** error) {
  const auto& struct_layout = pragma;
  const auto& clazz = Class::Handle(zone, struct_layout.clazz());
  ASSERT(String::Handle(zone, clazz.UserVisibleName())
             .Equals(Symbols::FfiStructLayout()));
  const auto& struct_layout_fields = Array::Handle(zone, clazz.fields());
  ASSERT(struct_layout_fields.Length() == 2);
  const auto& types_field =
      Field::Handle(zone, Field::RawCast(struct_layout_fields.At(0)));
  ASSERT(String::Handle(zone, types_field.name())
             .Equals(Symbols::FfiFieldTypes()));
  const auto& field_types =
      Array::Handle(zone, Array::RawCast(struct_layout.GetField(types_field)));
  const auto& packed_field =
      Field::Handle(zone, Field::RawCast(struct_layout_fields.At(1)));
  ASSERT(String::Handle(zone, packed_field.name())
             .Equals(Symbols::FfiFieldPacking()));
  const auto& packed_value = Integer::Handle(
      zone, Integer::RawCast(struct_layout.GetField(packed_field)));
  const intptr_t member_packing =
      packed_value.IsNull() ? kMaxInt32 : packed_value.AsInt64Value();

  auto& field_instance = Instance::Handle(zone);
  auto& field_type = AbstractType::Handle(zone);
  auto& field_native_types = *new (zone) ZoneGrowableArray<const NativeType*>(
      zone, field_types.Length());
  for (intptr_t i = 0; i < field_types.Length(); i++) {
    field_instance ^= field_types.At(i);
    if (field_instance.IsAbstractType()) {
      // Subtype of NativeType: Struct, native integer or native float.
      field_type ^= field_types.At(i);
      const auto& field_native_type =
          NativeType::FromAbstractType(zone, field_type, error);
      if (*error != nullptr) {
        return nullptr;
      }
      field_native_types.Add(field_native_type);
    } else {
      // Inline array.
      const auto& struct_layout_array_class =
          Class::Handle(zone, field_instance.clazz());
      ASSERT(String::Handle(zone, struct_layout_array_class.UserVisibleName())
                 .Equals(Symbols::FfiStructLayoutArray()));
      const auto& struct_layout_array_fields =
          Array::Handle(zone, struct_layout_array_class.fields());
      ASSERT(struct_layout_array_fields.Length() == 2);
      const auto& element_type_field =
          Field::Handle(zone, Field::RawCast(struct_layout_array_fields.At(0)));
      ASSERT(String::Handle(zone, element_type_field.UserVisibleName())
                 .Equals(Symbols::FfiElementType()));
      field_type ^= field_instance.GetField(element_type_field);
      const auto& length_field =
          Field::Handle(zone, Field::RawCast(struct_layout_array_fields.At(1)));
      ASSERT(String::Handle(zone, length_field.UserVisibleName())
                 .Equals(Symbols::Length()));
      const auto& length = Smi::Handle(
          zone, Smi::RawCast(field_instance.GetField(length_field)));
      const auto element_type =
          NativeType::FromAbstractType(zone, field_type, error);
      if (*error != nullptr) {
        return nullptr;
      }
      const auto field_native_type =
          new (zone) NativeArrayType(*element_type, length.AsInt64Value());
      field_native_types.Add(field_native_type);
    }
  }

  if (is_struct) {
    return &NativeStructType::FromNativeTypes(zone, field_native_types,
                                              member_packing);
  } else {
    return &NativeUnionType::FromNativeTypes(zone, field_native_types);
  }
}

static const NativeType* AbiSpecificFromPragma(Zone* zone,
                                               const Instance& pragma,
                                               const Class& abi_specific_int,
                                               const char** error) {
  const auto& clazz = Class::Handle(zone, pragma.clazz());
  const auto& fields = Array::Handle(zone, clazz.fields());
  ASSERT(fields.Length() == 1);
  const auto& native_types_field =
      Field::Handle(zone, Field::RawCast(fields.At(0)));
  ASSERT(String::Handle(zone, native_types_field.name())
             .Equals(Symbols::FfiNativeTypes()));
  const auto& native_types =
      Array::Handle(zone, Array::RawCast(pragma.GetField(native_types_field)));

  ASSERT(native_types.Length() == num_abis);
  const int64_t abi_index = static_cast<int64_t>(TargetAbi());
  const auto& abi_abstract_type = AbstractType::Handle(
      zone, AbstractType::RawCast(native_types.At(abi_index)));
  if (abi_abstract_type.IsNull()) {
    *error = zone->PrintToString(
        "AbiSpecificInteger '%s' is missing mapping for '%s'.",
        abi_specific_int.UserVisibleNameCString(), target_abi_name);
    return nullptr;
  }
  return NativeType::FromAbstractType(zone, abi_abstract_type, error);
}

const NativeType* NativeType::FromAbstractType(Zone* zone,
                                               const AbstractType& type,
                                               const char** error) {
  const classid_t class_id = type.type_class_id();
  if (IsFfiPredefinedClassId(class_id)) {
    return &NativeType::FromTypedDataClassId(zone, class_id);
  }

  // User-defined structs, unions, or Abi-specific integers.
  const auto& cls = Class::Handle(zone, type.type_class());
  const auto& superClass = Class::Handle(zone, cls.SuperClass());
  const bool is_struct = String::Handle(zone, superClass.UserVisibleName())
                             .Equals(Symbols::Struct());
  const bool is_union = String::Handle(zone, superClass.UserVisibleName())
                            .Equals(Symbols::Union());
  const bool is_abi_specific_int =
      String::Handle(zone, superClass.UserVisibleName())
          .Equals(Symbols::AbiSpecificInteger());
  RELEASE_ASSERT(is_struct || is_union || is_abi_specific_int);

  auto& pragmas = Object::Handle(zone);
  String& pragma_name = String::Handle(zone);
  if (is_struct || is_union) {
    pragma_name = Symbols::vm_ffi_struct_fields().ptr();
  } else {
    ASSERT(is_abi_specific_int);
    pragma_name = Symbols::vm_ffi_abi_specific_mapping().ptr();
  }
  Library::FindPragma(dart::Thread::Current(), /*only_core=*/false, cls,
                      pragma_name, /*multiple=*/true, &pragmas);
  ASSERT(!pragmas.IsNull());
  ASSERT(pragmas.IsGrowableObjectArray());
  const auto& pragmas_array = GrowableObjectArray::Cast(pragmas);
  auto& pragma = Instance::Handle(zone);
  auto& clazz = Class::Handle(zone);
  auto& library = Library::Handle(zone);
  String& class_symbol = String::Handle(zone);
  if (is_struct || is_union) {
    class_symbol = Symbols::FfiStructLayout().ptr();
  } else {
    ASSERT(is_abi_specific_int);
    class_symbol = Symbols::FfiAbiSpecificMapping().ptr();
  }
  for (intptr_t i = 0; i < pragmas_array.Length(); i++) {
    pragma ^= pragmas_array.At(i);
    clazz ^= pragma.clazz();
    library ^= clazz.library();
    if (String::Handle(zone, clazz.UserVisibleName()).Equals(class_symbol) &&
        String::Handle(zone, library.url()).Equals(Symbols::DartFfi())) {
      break;
    }
  }

  if (is_struct || is_union) {
    return CompoundFromPragma(zone, pragma, is_struct, error);
  }
  ASSERT(is_abi_specific_int);
  return AbiSpecificFromPragma(zone, pragma, cls, error);
}
#endif

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
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

const NativeFunctionType* NativeFunctionType::FromUnboxedRepresentation(
    Zone* zone,
    intptr_t num_arguments,
    Representation representation) {
  const auto& intptr_type =
      compiler::ffi::NativePrimitiveType::FromUnboxedRepresentation(
          zone, representation);
  auto& argument_representations =
      *new (zone) ZoneGrowableArray<const compiler::ffi::NativeType*>(
          zone, num_arguments);
  for (intptr_t i = 0; i < num_arguments; i++) {
    argument_representations.Add(&intptr_type);
  }
  return new (zone)
      compiler::ffi::NativeFunctionType(argument_representations, intptr_type);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

const char* NativeType::ToCString(Zone* zone,
                                  bool multi_line,
                                  bool verbose) const {
  ZoneTextBuffer textBuffer(zone);
  PrintTo(&textBuffer, multi_line, verbose);
  return textBuffer.buffer();
}

#if !defined(FFI_UNIT_TESTS)
const char* NativeType::ToCString() const {
  return ToCString(Thread::Current()->zone());
}
#endif

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

void NativeType::PrintTo(BaseTextBuffer* f,
                         bool multi_line,
                         bool verbose) const {
  f->AddString("I");
}

void NativePrimitiveType::PrintTo(BaseTextBuffer* f,
                                  bool multi_line,
                                  bool verbose) const {
  f->Printf("%s", PrimitiveTypeToCString(representation_));
}

const char* NativeFunctionType::ToCString(Zone* zone) const {
  ZoneTextBuffer textBuffer(zone);
  PrintTo(&textBuffer);
  return textBuffer.buffer();
}

void NativeArrayType::PrintTo(BaseTextBuffer* f,
                              bool multi_line,
                              bool verbose) const {
  f->AddString("Array(");
  f->Printf("element type: ");
  element_type_.PrintTo(f, /*multi_line*/ false, verbose);
  f->Printf(", length: %" Pd "", length_);
  f->AddString(")");
}

void NativeCompoundType::PrintTo(BaseTextBuffer* f,
                                 bool multi_line,
                                 bool verbose) const {
  PrintCompoundType(f);
  f->AddString("(");
  f->Printf("size: %" Pd "", SizeInBytes());
  if (verbose) {
    f->Printf(", field alignment: %" Pd ", ", AlignmentInBytesField());
    f->Printf("stack alignment: %" Pd ", ", AlignmentInBytesStack());
    f->AddString("members: {");
    if (multi_line) {
      f->AddString("\n  ");
    }
    for (intptr_t i = 0; i < members_.length(); i++) {
      if (i > 0) {
        if (multi_line) {
          f->AddString(",\n  ");
        } else {
          f->AddString(", ");
        }
      }
      PrintMemberOffset(f, i);
      members_[i]->PrintTo(f);
    }
    if (multi_line) {
      f->AddString("\n");
    }
    f->AddString("}");
  }
  f->AddString(")");
  if (multi_line) {
    f->AddString("\n");
  }
}

void NativeStructType::PrintCompoundType(BaseTextBuffer* f) const {
  f->AddString("Struct");
}

void NativeUnionType::PrintCompoundType(BaseTextBuffer* f) const {
  f->AddString("Union");
}

void NativeStructType::PrintMemberOffset(BaseTextBuffer* f,
                                         intptr_t member_index) const {
  f->Printf("%" Pd ": ", member_offsets_[member_index]);
}

#if !defined(FFI_UNIT_TESTS)
const char* NativeFunctionType::ToCString() const {
  return ToCString(Thread::Current()->zone());
}
#endif

void NativeFunctionType::PrintTo(BaseTextBuffer* f) const {
  f->AddString("(");
  for (intptr_t i = 0; i < argument_types_.length(); i++) {
    if (i > 0) {
      f->AddString(", ");
    }
    if (i == variadic_arguments_index_) {
      f->AddString("varargs: ");
    }
    argument_types_[i]->PrintTo(f);
  }
  f->AddString(") => ");
  return_type_.PrintTo(f);
}

intptr_t NativePrimitiveType::NumPrimitiveMembersRecursive() const {
  return 1;
}

intptr_t NativeArrayType::NumPrimitiveMembersRecursive() const {
  return element_type_.NumPrimitiveMembersRecursive() * length_;
}

intptr_t NativeStructType::NumPrimitiveMembersRecursive() const {
  intptr_t count = 0;
  for (intptr_t i = 0; i < members_.length(); i++) {
    count += members_[i]->NumPrimitiveMembersRecursive();
  }
  return count;
}

intptr_t NativeUnionType::NumPrimitiveMembersRecursive() const {
  intptr_t count = 0;
  for (intptr_t i = 0; i < members_.length(); i++) {
    count = Utils::Maximum(count, members_[i]->NumPrimitiveMembersRecursive());
  }
  return count;
}

const NativePrimitiveType& NativePrimitiveType::FirstPrimitiveMember() const {
  return *this;
}

const NativePrimitiveType& NativeArrayType::FirstPrimitiveMember() const {
  return element_type_.FirstPrimitiveMember();
}

const NativePrimitiveType& NativeCompoundType::FirstPrimitiveMember() const {
  ASSERT(NumPrimitiveMembersRecursive() >= 1);
  for (intptr_t i = 0; i < members().length(); i++) {
    if (members_[i]->NumPrimitiveMembersRecursive() >= 1) {
      return members_[i]->FirstPrimitiveMember();
    }
  }
  UNREACHABLE_THIS();
}

intptr_t NativePrimitiveType::PrimitivePairMembers(
    const NativePrimitiveType** first,
    const NativePrimitiveType** second,
    intptr_t offset_in_members) const {
  if (offset_in_members == 0) *first = this;
  if (offset_in_members == 1) *second = this;
  return offset_in_members + 1;
}

intptr_t NativeArrayType::PrimitivePairMembers(
    const NativePrimitiveType** first,
    const NativePrimitiveType** second,
    intptr_t offset_in_members) const {
  for (intptr_t i = 0; i < length_; i++) {
    offset_in_members =
        element_type_.PrimitivePairMembers(first, second, offset_in_members);
  }
  return offset_in_members;
}

intptr_t NativeCompoundType::PrimitivePairMembers(
    const NativePrimitiveType** first,
    const NativePrimitiveType** second,
    intptr_t offset_in_members) const {
  for (intptr_t i = 0; i < members().length(); i++) {
    offset_in_members =
        members_[i]->PrimitivePairMembers(first, second, offset_in_members);
  }
  return offset_in_members;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
bool NativePrimitiveType::ContainsOnlyFloats(Range range) const {
  const auto this_range = Range::StartAndEnd(0, SizeInBytes());
  ASSERT(this_range.Contains(range));

  return IsFloat();
}

bool NativeArrayType::ContainsOnlyFloats(Range range) const {
  const auto this_range = Range::StartAndEnd(0, SizeInBytes());
  ASSERT(this_range.Contains(range));

  const intptr_t element_size_in_bytes = element_type_.SizeInBytes();

  // Assess how many elements are (partially) covered by the range.
  const intptr_t first_element_start = range.start() / element_size_in_bytes;
  const intptr_t last_element_index =
      range.end_inclusive() / element_size_in_bytes;
  const intptr_t num_elements = last_element_index - first_element_start + 1;
  ASSERT(num_elements >= 1);

  if (num_elements > 2) {
    // At least one full element covered.
    return element_type_.ContainsOnlyFloats(
        Range::StartAndLength(0, element_size_in_bytes));
  }

  // Check first element, which falls (partially) in range.
  const intptr_t first_start = first_element_start * element_size_in_bytes;
  const auto first_range =
      Range::StartAndLength(first_start, element_size_in_bytes);
  const auto first_range_clipped = range.Intersect(first_range);
  const auto range_in_first = first_range_clipped.Translate(-first_start);
  if (!element_type_.ContainsOnlyFloats(range_in_first)) {
    // First element contains not only floats in specified range.
    return false;
  }

  if (num_elements == 2) {
    // Check the second (and last) element, which falls (partially) in range.
    const intptr_t second_element_index = first_element_start + 1;
    const intptr_t second_start = second_element_index * element_size_in_bytes;
    const auto second_range =
        Range::StartAndLength(second_start, element_size_in_bytes);
    const auto second_range_clipped = range.Intersect(second_range);
    const auto range_in_second = second_range_clipped.Translate(-second_start);
    return element_type_.ContainsOnlyFloats(range_in_second);
  }

  return true;
}

bool NativeStructType::ContainsOnlyFloats(Range range) const {
  const auto this_range = Range::StartAndEnd(0, SizeInBytes());
  ASSERT(this_range.Contains(range));

  for (intptr_t i = 0; i < members_.length(); i++) {
    const auto& member = *members_[i];
    const intptr_t member_offset = member_offsets_[i];
    const intptr_t member_size = member.SizeInBytes();
    const auto member_range = Range::StartAndLength(member_offset, member_size);
    if (range.Overlaps(member_range)) {
      const auto member_range_clipped = member_range.Intersect(range);
      const auto range_in_member =
          member_range_clipped.Translate(-member_offset);
      if (!member.ContainsOnlyFloats(range_in_member)) {
        // Member contains not only floats in specified range.
        return false;
      }
    }
    if (member_range.After(range)) {
      // None of the remaining members fits the range.
      break;
    }
  }
  return true;
}

bool NativeUnionType::ContainsOnlyFloats(Range range) const {
  for (intptr_t i = 0; i < members_.length(); i++) {
    const auto& member = *members_[i];
    const intptr_t member_size = member.SizeInBytes();
    const auto member_range = Range::StartAndLength(0, member_size);
    if (member_range.Overlaps(range)) {
      const auto member_range_clipped = member_range.Intersect(range);
      if (!member.ContainsOnlyFloats(member_range_clipped)) {
        return false;
      }
    }
  }
  return true;
}

intptr_t NativeCompoundType::NumberOfWordSizeChunksOnlyFloat() const {
  // O(n^2) implementation, but only invoked for small structs.
  ASSERT(SizeInBytes() <= 16);
  const auto this_range = Range::StartAndEnd(0, SizeInBytes());
  const intptr_t size = SizeInBytes();
  intptr_t float_only_chunks = 0;
  for (intptr_t offset = 0; offset < size;
       offset += compiler::target::kWordSize) {
    const auto chunk_range =
        Range::StartAndLength(offset, compiler::target::kWordSize);
    if (ContainsOnlyFloats(chunk_range.Intersect(this_range))) {
      float_only_chunks++;
    }
  }
  return float_only_chunks;
}

intptr_t NativeCompoundType::NumberOfWordSizeChunksNotOnlyFloat() const {
  const intptr_t total_chunks =
      Utils::RoundUp(SizeInBytes(), compiler::target::kWordSize) /
      compiler::target::kWordSize;
  return total_chunks - NumberOfWordSizeChunksOnlyFloat();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

bool NativePrimitiveType::ContainsUnalignedMembers(intptr_t offset) const {
  return offset % AlignmentInBytesField() != 0;
}

bool NativeArrayType::ContainsUnalignedMembers(intptr_t offset) const {
  const intptr_t element_size = element_type_.SizeInBytes();
  // We're only checking the first two elements of the array.
  //
  // If the element size is divisible by the alignment of the largest type
  // contained within the element type, the alignment of all elements is the
  // same. If not, either the first or the second element is unaligned.
  const intptr_t max_check = 2;
  for (intptr_t i = 0; i < Utils::Minimum(length_, max_check); i++) {
    const intptr_t element_offset = i * element_size;
    if (element_type_.ContainsUnalignedMembers(offset + element_offset)) {
      return true;
    }
  }
  return false;
}

bool NativeStructType::ContainsUnalignedMembers(intptr_t offset) const {
  for (intptr_t i = 0; i < members_.length(); i++) {
    const auto& member = *members_.At(i);
    const intptr_t member_offset = member_offsets_.At(i);
    if (member.ContainsUnalignedMembers(offset + member_offset)) {
      return true;
    }
  }
  return false;
}

bool NativeUnionType::ContainsUnalignedMembers(intptr_t offset) const {
  for (intptr_t i = 0; i < members_.length(); i++) {
    const auto& member = *members_.At(i);
    if (member.ContainsUnalignedMembers(offset)) {
      return true;
    }
  }
  return false;
}

static void ContainsHomogeneousFloatsRecursive(const NativeTypes& types,
                                               bool* only_float,
                                               bool* only_double) {
  for (intptr_t i = 0; i < types.length(); i++) {
    const auto& type = *types.At(i);
    const auto& member_type =
        type.IsArray() ? type.AsArray().element_type() : type;
    if (member_type.IsPrimitive()) {
      PrimitiveType type = member_type.AsPrimitive().representation();
      *only_float = *only_float && (type == kFloat);
      *only_double = *only_double && (type == kDouble);
    }
    if (member_type.IsCompound()) {
      ContainsHomogeneousFloatsRecursive(member_type.AsCompound().members(),
                                         only_float, only_double);
    }
  }
}

static bool ContainsHomogeneousFloatsInternal(const NativeTypes& types) {
  bool only_float = true;
  bool only_double = true;
  ContainsHomogeneousFloatsRecursive(types, &only_float, &only_double);
  return (only_double || only_float) && types.length() > 0;
}

bool NativeCompoundType::ContainsHomogeneousFloats() const {
  return ContainsHomogeneousFloatsInternal(this->members());
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
