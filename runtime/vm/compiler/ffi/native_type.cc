// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_type.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/class_id.h"
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

static bool ContainsHomogenuousFloatsInternal(const NativeTypes& types);

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
  if (!ContainsHomogenuousFloatsInternal(members)) {
    alignment_stack = compiler::target::kWordSize;
  }
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
  }
  const intptr_t size = Utils::RoundUp(offset, alignment_field);

  return *new (zone) NativeStructType(members, member_offsets, size,
                                      alignment_field, alignment_stack);
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
  ASSERT(IsFfiPredefinedClassId(class_id));
  const auto fundamental_rep = TypeRepresentation(class_id);
  return *new (zone) NativePrimitiveType(fundamental_rep);
}

#if !defined(FFI_UNIT_TESTS)
NativeType& NativeType::FromAbstractType(Zone* zone, const AbstractType& type) {
  const classid_t class_id = type.type_class_id();
  if (IsFfiPredefinedClassId(class_id)) {
    return NativeType::FromTypedDataClassId(zone, class_id);
  }

  // User-defined structs.
  const auto& cls = Class::Handle(zone, type.type_class());
  const auto& superClass = Class::Handle(zone, cls.SuperClass());
  const bool is_struct = String::Handle(zone, superClass.UserVisibleName())
                             .Equals(Symbols::Struct());
  ASSERT(is_struct || String::Handle(zone, superClass.UserVisibleName())
                          .Equals(Symbols::Union()));

  auto& pragmas = Object::Handle(zone);
  Library::FindPragma(dart::Thread::Current(), /*only_core=*/false, cls,
                      Symbols::vm_ffi_struct_fields(), /*multiple=*/true,
                      &pragmas);
  ASSERT(!pragmas.IsNull());
  ASSERT(pragmas.IsGrowableObjectArray());
  const auto& pragmas_array = GrowableObjectArray::Cast(pragmas);
  auto& pragma = Instance::Handle(zone);
  auto& clazz = Class::Handle(zone);
  auto& library = Library::Handle(zone);
  for (intptr_t i = 0; i < pragmas_array.Length(); i++) {
    pragma ^= pragmas_array.At(i);
    clazz ^= pragma.clazz();
    library ^= clazz.library();
    if (String::Handle(zone, clazz.UserVisibleName())
            .Equals(Symbols::FfiStructLayout()) &&
        String::Handle(zone, library.url()).Equals(Symbols::DartFfi())) {
      break;
    }
  }

  const auto& struct_layout = pragma;
  const auto& struct_layout_class = clazz;
  ASSERT(String::Handle(zone, struct_layout_class.UserVisibleName())
             .Equals(Symbols::FfiStructLayout()));
  ASSERT(String::Handle(zone, library.url()).Equals(Symbols::DartFfi()));
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
          NativeType::FromAbstractType(zone, field_type);
      field_native_types.Add(&field_native_type);
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
      const auto& element_type = NativeType::FromAbstractType(zone, field_type);
      const auto& field_native_type =
          *new (zone) NativeArrayType(element_type, length.AsInt64Value());
      field_native_types.Add(&field_native_type);
    }
  }

  if (is_struct) {
    return NativeStructType::FromNativeTypes(zone, field_native_types,
                                             member_packing);
  } else {
    return NativeUnionType::FromNativeTypes(zone, field_native_types);
  }
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
  UNREACHABLE();
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

static void ContainsHomogenuousFloatsRecursive(const NativeTypes& types,
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
      ContainsHomogenuousFloatsRecursive(member_type.AsCompound().members(),
                                         only_float, only_double);
    }
  }
}

static bool ContainsHomogenuousFloatsInternal(const NativeTypes& types) {
  bool only_float = true;
  bool only_double = true;
  ContainsHomogenuousFloatsRecursive(types, &only_float, &only_double);
  return (only_double || only_float) && types.length() > 0;
}

bool NativeCompoundType::ContainsHomogenuousFloats() const {
  return ContainsHomogenuousFloatsInternal(this->members());
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
