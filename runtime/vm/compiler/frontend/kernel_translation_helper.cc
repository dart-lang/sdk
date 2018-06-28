// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_translation_helper.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()

namespace dart {
namespace kernel {

TranslationHelper::TranslationHelper(Thread* thread)
    : thread_(thread),
      zone_(thread->zone()),
      isolate_(thread->isolate()),
      allocation_space_(thread->IsMutatorThread() ? Heap::kNew : Heap::kOld),
      string_offsets_(TypedData::Handle(Z)),
      string_data_(ExternalTypedData::Handle(Z)),
      canonical_names_(TypedData::Handle(Z)),
      metadata_payloads_(ExternalTypedData::Handle(Z)),
      metadata_mappings_(ExternalTypedData::Handle(Z)),
      constants_(Array::Handle(Z)) {}

void TranslationHelper::Reset() {
  string_offsets_ = TypedData::null();
  string_data_ = ExternalTypedData::null();
  canonical_names_ = TypedData::null();
  metadata_payloads_ = ExternalTypedData::null();
  metadata_mappings_ = ExternalTypedData::null();
  constants_ = Array::null();
}

void TranslationHelper::InitFromScript(const Script& script) {
  const KernelProgramInfo& info =
      KernelProgramInfo::Handle(Z, script.kernel_program_info());
  if (info.IsNull()) {
    // If there is no kernel data associated with the script, then
    // do not bother initializing!.
    // This can happen with few special functions like
    // NoSuchMethodDispatcher and InvokeFieldDispatcher.
    return;
  }
  InitFromKernelProgramInfo(info);
}

void TranslationHelper::InitFromKernelProgramInfo(
    const KernelProgramInfo& info) {
  SetStringOffsets(TypedData::Handle(Z, info.string_offsets()));
  SetStringData(ExternalTypedData::Handle(Z, info.string_data()));
  SetCanonicalNames(TypedData::Handle(Z, info.canonical_names()));
  SetMetadataPayloads(ExternalTypedData::Handle(Z, info.metadata_payloads()));
  SetMetadataMappings(ExternalTypedData::Handle(Z, info.metadata_mappings()));
  SetConstants(Array::Handle(Z, info.constants()));
}

void TranslationHelper::SetStringOffsets(const TypedData& string_offsets) {
  ASSERT(string_offsets_.IsNull());
  string_offsets_ = string_offsets.raw();
}

void TranslationHelper::SetStringData(const ExternalTypedData& string_data) {
  ASSERT(string_data_.IsNull());
  string_data_ = string_data.raw();
}

void TranslationHelper::SetCanonicalNames(const TypedData& canonical_names) {
  ASSERT(canonical_names_.IsNull());
  canonical_names_ = canonical_names.raw();
}

void TranslationHelper::SetMetadataPayloads(
    const ExternalTypedData& metadata_payloads) {
  ASSERT(metadata_payloads_.IsNull());
  metadata_payloads_ = metadata_payloads.raw();
}

void TranslationHelper::SetMetadataMappings(
    const ExternalTypedData& metadata_mappings) {
  ASSERT(metadata_mappings_.IsNull());
  metadata_mappings_ = metadata_mappings.raw();
}

void TranslationHelper::SetConstants(const Array& constants) {
  ASSERT(constants_.IsNull());
  constants_ = constants.raw();
}

intptr_t TranslationHelper::StringOffset(StringIndex index) const {
  return string_offsets_.GetUint32(index << 2);
}

intptr_t TranslationHelper::StringSize(StringIndex index) const {
  return StringOffset(StringIndex(index + 1)) - StringOffset(index);
}

uint8_t TranslationHelper::CharacterAt(StringIndex string_index,
                                       intptr_t index) {
  ASSERT(index < StringSize(string_index));
  return string_data_.GetUint8(StringOffset(string_index) + index);
}

uint8_t* TranslationHelper::StringBuffer(StringIndex string_index) const {
  // Though this implementation appears like it could be replaced by
  // string_data_.DataAddr(StringOffset(string_index)), it can't quite.  If the
  // last string in the string table is a zero length string, then the latter
  // expression will try to return the address that is one past the backing
  // store of the string_data_ table.  Though this is safe in C++ as long as the
  // address is not dereferenced, it will trigger the assert in
  // ExternalTypedData::DataAddr.
  ASSERT(Thread::Current()->no_safepoint_scope_depth() > 0);
  return reinterpret_cast<uint8_t*>(string_data_.DataAddr(0)) +
         StringOffset(string_index);
}

bool TranslationHelper::StringEquals(StringIndex string_index,
                                     const char* other) {
  intptr_t length = strlen(other);
  if (length != StringSize(string_index)) return false;

  NoSafepointScope no_safepoint;
  return memcmp(StringBuffer(string_index), other, length) == 0;
}

NameIndex TranslationHelper::CanonicalNameParent(NameIndex name) {
  // Canonical names are pairs of 4-byte parent and string indexes, so the size
  // of an entry is 8 bytes.  The parent is biased: 0 represents the root name
  // and N+1 represents the name with index N.
  return NameIndex(static_cast<intptr_t>(canonical_names_.GetUint32(8 * name)) -
                   1);
}

StringIndex TranslationHelper::CanonicalNameString(NameIndex name) {
  return StringIndex(canonical_names_.GetUint32((8 * name) + 4));
}

bool TranslationHelper::IsAdministrative(NameIndex name) {
  // Administrative names start with '@'.
  StringIndex name_string = CanonicalNameString(name);
  return (StringSize(name_string) > 0) && (CharacterAt(name_string, 0) == '@');
}

bool TranslationHelper::IsPrivate(NameIndex name) {
  // Private names start with '_'.
  StringIndex name_string = CanonicalNameString(name);
  return (StringSize(name_string) > 0) && (CharacterAt(name_string, 0) == '_');
}

bool TranslationHelper::IsRoot(NameIndex name) {
  return name == -1;
}

bool TranslationHelper::IsLibrary(NameIndex name) {
  // Libraries are the only canonical names with the root as their parent.
  return !IsRoot(name) && IsRoot(CanonicalNameParent(name));
}

bool TranslationHelper::IsClass(NameIndex name) {
  // Classes have the library as their parent and are not an administrative
  // name starting with @.
  return !IsAdministrative(name) && !IsRoot(name) &&
         IsLibrary(CanonicalNameParent(name));
}

bool TranslationHelper::IsMember(NameIndex name) {
  return IsConstructor(name) || IsField(name) || IsProcedure(name);
}

bool TranslationHelper::IsField(NameIndex name) {
  // Fields with private names have the import URI of the library where they are
  // visible as the parent and the string "@fields" as the parent's parent.
  // Fields with non-private names have the string "@fields' as the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@fields");
}

bool TranslationHelper::IsConstructor(NameIndex name) {
  // Constructors with private names have the import URI of the library where
  // they are visible as the parent and the string "@constructors" as the
  // parent's parent.  Constructors with non-private names have the string
  // "@constructors" as the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@constructors");
}

bool TranslationHelper::IsProcedure(NameIndex name) {
  return IsMethod(name) || IsGetter(name) || IsSetter(name) || IsFactory(name);
}

bool TranslationHelper::IsMethod(NameIndex name) {
  // Methods with private names have the import URI of the library where they
  // are visible as the parent and the string "@methods" as the parent's parent.
  // Methods with non-private names have the string "@methods" as the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@methods");
}

bool TranslationHelper::IsGetter(NameIndex name) {
  // Getters with private names have the import URI of the library where they
  // are visible as the parent and the string "@getters" as the parent's parent.
  // Getters with non-private names have the string "@getters" as the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@getters");
}

bool TranslationHelper::IsSetter(NameIndex name) {
  // Setters with private names have the import URI of the library where they
  // are visible as the parent and the string "@setters" as the parent's parent.
  // Setters with non-private names have the string "@setters" as the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@setters");
}

bool TranslationHelper::IsFactory(NameIndex name) {
  // Factories with private names have the import URI of the library where they
  // are visible as the parent and the string "@factories" as the parent's
  // parent.  Factories with non-private names have the string "@factories" as
  // the parent.
  if (IsRoot(name)) {
    return false;
  }
  NameIndex kind = CanonicalNameParent(name);
  if (IsPrivate(name)) {
    kind = CanonicalNameParent(kind);
  }
  return StringEquals(CanonicalNameString(kind), "@factories");
}

NameIndex TranslationHelper::EnclosingName(NameIndex name) {
  ASSERT(IsField(name) || IsConstructor(name) || IsProcedure(name));
  NameIndex enclosing = CanonicalNameParent(CanonicalNameParent(name));
  if (IsPrivate(name)) {
    enclosing = CanonicalNameParent(enclosing);
  }
  ASSERT(IsLibrary(enclosing) || IsClass(enclosing));
  return enclosing;
}

RawInstance* TranslationHelper::Canonicalize(const Instance& instance) {
  if (instance.IsNull()) return instance.raw();

  const char* error_str = NULL;
  RawInstance* result = instance.CheckAndCanonicalize(thread(), &error_str);
  if (result == Object::null()) {
    ReportError("Invalid const object %s", error_str);
  }
  return result;
}

const String& TranslationHelper::DartString(const char* content,
                                            Heap::Space space) {
  return String::ZoneHandle(Z, String::New(content, space));
}

String& TranslationHelper::DartString(StringIndex string_index,
                                      Heap::Space space) {
  intptr_t length = StringSize(string_index);
  uint8_t* buffer = Z->Alloc<uint8_t>(length);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, StringBuffer(string_index), length);
  }
  return String::ZoneHandle(Z, String::FromUTF8(buffer, length, space));
}

String& TranslationHelper::DartString(const uint8_t* utf8_array,
                                      intptr_t len,
                                      Heap::Space space) {
  return String::ZoneHandle(Z, String::FromUTF8(utf8_array, len, space));
}

const String& TranslationHelper::DartSymbolPlain(const char* content) const {
  return String::ZoneHandle(Z, Symbols::New(thread_, content));
}

String& TranslationHelper::DartSymbolPlain(StringIndex string_index) const {
  intptr_t length = StringSize(string_index);
  uint8_t* buffer = Z->Alloc<uint8_t>(length);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, StringBuffer(string_index), length);
  }
  String& result =
      String::ZoneHandle(Z, Symbols::FromUTF8(thread_, buffer, length));
  return result;
}

const String& TranslationHelper::DartSymbolObfuscate(
    const char* content) const {
  String& result = String::ZoneHandle(Z, Symbols::New(thread_, content));
  if (I->obfuscate()) {
    Obfuscator obfuscator(thread_, String::Handle(Z));
    result = obfuscator.Rename(result, true);
  }
  return result;
}

String& TranslationHelper::DartSymbolObfuscate(StringIndex string_index) const {
  intptr_t length = StringSize(string_index);
  uint8_t* buffer = Z->Alloc<uint8_t>(length);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, StringBuffer(string_index), length);
  }
  String& result =
      String::ZoneHandle(Z, Symbols::FromUTF8(thread_, buffer, length));
  if (I->obfuscate()) {
    Obfuscator obfuscator(thread_, String::Handle(Z));
    result = obfuscator.Rename(result, true);
  }
  return result;
}

String& TranslationHelper::DartIdentifier(const Library& lib,
                                          StringIndex string_index) {
  String& name = DartString(string_index);
  ManglePrivateName(lib, &name);
  return name;
}

const String& TranslationHelper::DartClassName(NameIndex kernel_class) {
  ASSERT(IsClass(kernel_class));
  String& name = DartString(CanonicalNameString(kernel_class));
  return ManglePrivateName(CanonicalNameParent(kernel_class), &name);
}

const String& TranslationHelper::DartConstructorName(NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  return DartFactoryName(constructor);
}

const String& TranslationHelper::DartProcedureName(NameIndex procedure) {
  ASSERT(IsProcedure(procedure));
  if (IsSetter(procedure)) {
    return DartSetterName(procedure);
  } else if (IsGetter(procedure)) {
    return DartGetterName(procedure);
  } else if (IsFactory(procedure)) {
    return DartFactoryName(procedure);
  } else {
    return DartMethodName(procedure);
  }
}

const String& TranslationHelper::DartSetterName(NameIndex setter) {
  return DartSetterName(CanonicalNameParent(setter),
                        CanonicalNameString(setter));
}

const String& TranslationHelper::DartSetterName(NameIndex parent,
                                                StringIndex setter) {
  // The names flowing into [setter] are coming from the Kernel file:
  //   * user-defined setters: `fieldname=`
  //   * property-set expressions:  `fieldname`
  //
  // The VM uses `get:fieldname` and `set:fieldname`.
  //
  // => In order to be consistent, we remove the `=` always and adopt the VM
  //    conventions.
  intptr_t size = StringSize(setter);
  ASSERT(size > 0);
  if (CharacterAt(setter, size - 1) == '=') {
    --size;
  }
  uint8_t* buffer = Z->Alloc<uint8_t>(size);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, StringBuffer(setter), size);
  }
  String& name =
      String::ZoneHandle(Z, String::FromUTF8(buffer, size, allocation_space_));
  ManglePrivateName(parent, &name);
  name = Field::SetterSymbol(name);
  return name;
}

const String& TranslationHelper::DartGetterName(NameIndex getter) {
  return DartGetterName(CanonicalNameParent(getter),
                        CanonicalNameString(getter));
}

const String& TranslationHelper::DartGetterName(NameIndex parent,
                                                StringIndex getter) {
  String& name = DartString(getter);
  ManglePrivateName(parent, &name);
  name = Field::GetterSymbol(name);
  return name;
}

const String& TranslationHelper::DartFieldName(NameIndex field) {
  return DartFieldName(CanonicalNameParent(field), CanonicalNameString(field));
}

const String& TranslationHelper::DartFieldName(NameIndex parent,
                                               StringIndex field) {
  String& name = DartString(field);
  return ManglePrivateName(parent, &name);
}

const String& TranslationHelper::DartMethodName(NameIndex method) {
  return DartMethodName(CanonicalNameParent(method),
                        CanonicalNameString(method));
}

const String& TranslationHelper::DartMethodName(NameIndex parent,
                                                StringIndex method) {
  String& name = DartString(method);
  return ManglePrivateName(parent, &name);
}

const String& TranslationHelper::DartFactoryName(NameIndex factory) {
  ASSERT(IsConstructor(factory) || IsFactory(factory));
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(DartClassName(EnclosingName(factory)));
  pieces.Add(Symbols::Dot());
  // [DartMethodName] will mangle the name.
  pieces.Add(DartMethodName(factory));
  return String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces));
}

RawLibrary* TranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex kernel_library) {
  // We only use the string and don't rely on having any particular parent.
  // This ASSERT is just a sanity check.
  ASSERT(IsLibrary(kernel_library) ||
         IsAdministrative(CanonicalNameParent(kernel_library)));
  const String& library_name =
      DartSymbolPlain(CanonicalNameString(kernel_library));
  ASSERT(!library_name.IsNull());
  RawLibrary* library = Library::LookupLibrary(thread_, library_name);
  ASSERT(library != Object::null());
  return library;
}

RawClass* TranslationHelper::LookupClassByKernelClass(NameIndex kernel_class) {
  ASSERT(IsClass(kernel_class));
  const String& class_name = DartClassName(kernel_class);
  NameIndex kernel_library = CanonicalNameParent(kernel_class);
  Library& library =
      Library::Handle(Z, LookupLibraryByKernelLibrary(kernel_library));
  RawClass* klass = library.LookupClassAllowPrivate(class_name);

  ASSERT(klass != Object::null());
  return klass;
}

RawField* TranslationHelper::LookupFieldByKernelField(NameIndex kernel_field) {
  ASSERT(IsField(kernel_field));
  NameIndex enclosing = EnclosingName(kernel_field);

  Class& klass = Class::Handle(Z);
  if (IsLibrary(enclosing)) {
    Library& library =
        Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    klass = library.toplevel_class();
  } else {
    ASSERT(IsClass(enclosing));
    klass = LookupClassByKernelClass(enclosing);
  }
  RawField* field = klass.LookupFieldAllowPrivate(
      DartSymbolObfuscate(CanonicalNameString(kernel_field)));
  ASSERT(field != Object::null());
  return field;
}

RawFunction* TranslationHelper::LookupStaticMethodByKernelProcedure(
    NameIndex procedure) {
  const String& procedure_name = DartProcedureName(procedure);

  // The parent is either a library or a class (in which case the procedure is a
  // static method).
  NameIndex enclosing = EnclosingName(procedure);
  if (IsLibrary(enclosing)) {
    Library& library =
        Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    RawFunction* function = library.LookupFunctionAllowPrivate(procedure_name);
    ASSERT(function != Object::null());
    return function;
  } else {
    ASSERT(IsClass(enclosing));
    Class& klass = Class::Handle(Z, LookupClassByKernelClass(enclosing));
    Function& function = Function::ZoneHandle(
        Z, klass.LookupFunctionAllowPrivate(procedure_name));
    ASSERT(!function.IsNull());

    // TODO(27590): We can probably get rid of this after no longer using
    // core libraries from the source.
    if (function.IsRedirectingFactory()) {
      ClassFinalizer::ResolveRedirectingFactory(klass, function);
      function = function.RedirectionTarget();
    }
    return function.raw();
  }
}

RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  Class& klass =
      Class::Handle(Z, LookupClassByKernelClass(EnclosingName(constructor)));
  return LookupConstructorByKernelConstructor(klass, constructor);
}

RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    const Class& owner,
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  RawFunction* function =
      owner.LookupConstructorAllowPrivate(DartConstructorName(constructor));
  ASSERT(function != Object::null());
  return function;
}

RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    const Class& owner,
    StringIndex constructor_name) {
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(DartString(String::Handle(owner.Name()).ToCString(), Heap::kOld));
  pieces.Add(Symbols::Dot());
  String& name = DartString(constructor_name);
  pieces.Add(ManglePrivateName(Library::Handle(owner.library()), &name));

  String& new_name =
      String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces));
  RawFunction* function = owner.LookupConstructorAllowPrivate(new_name);
  ASSERT(function != Object::null());
  return function;
}

Type& TranslationHelper::GetCanonicalType(const Class& klass) {
  ASSERT(!klass.IsNull());
  // Note that if cls is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, klass.CanonicalType());
  if (!type.IsNull()) {
    return type;
  }
  type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                   klass.token_pos());
  if (klass.is_type_finalized()) {
    type ^= ClassFinalizer::FinalizeType(klass, type);
    // Note that the receiver type may now be a malbounded type.
    klass.SetCanonicalType(type);
  }
  return type;
}

void TranslationHelper::ReportError(const char* format, ...) {
  const Script& null_script = Script::Handle(Z);

  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, null_script, TokenPosition::kNoSource,
                   Report::AtLocation, format, args);
  va_end(args);
  UNREACHABLE();
}

void TranslationHelper::ReportError(const Script& script,
                                    const TokenPosition position,
                                    const char* format,
                                    ...) {
  va_list args;
  va_start(args, format);
  Report::MessageV(Report::kError, script, position, Report::AtLocation, format,
                   args);
  va_end(args);
  UNREACHABLE();
}

void TranslationHelper::ReportError(const Error& prev_error,
                                    const char* format,
                                    ...) {
  const Script& null_script = Script::Handle(Z);

  va_list args;
  va_start(args, format);
  Report::LongJumpV(prev_error, null_script, TokenPosition::kNoSource, format,
                    args);
  va_end(args);
  UNREACHABLE();
}

void TranslationHelper::ReportError(const Error& prev_error,
                                    const Script& script,
                                    const TokenPosition position,
                                    const char* format,
                                    ...) {
  va_list args;
  va_start(args, format);
  Report::LongJumpV(prev_error, script, position, format, args);
  va_end(args);
  UNREACHABLE();
}

String& TranslationHelper::ManglePrivateName(NameIndex parent,
                                             String* name_to_modify,
                                             bool symbolize,
                                             bool obfuscate) {
  if (name_to_modify->Length() >= 1 && name_to_modify->CharAt(0) == '_') {
    const Library& library =
        Library::Handle(Z, LookupLibraryByKernelLibrary(parent));
    *name_to_modify = library.PrivateName(*name_to_modify);
    if (obfuscate && I->obfuscate()) {
      const String& library_key = String::Handle(library.private_key());
      Obfuscator obfuscator(thread_, library_key);
      *name_to_modify = obfuscator.Rename(*name_to_modify);
    }
  } else if (symbolize) {
    *name_to_modify = Symbols::New(thread_, *name_to_modify);
    if (obfuscate && I->obfuscate()) {
      const String& library_key = String::Handle();
      Obfuscator obfuscator(thread_, library_key);
      *name_to_modify = obfuscator.Rename(*name_to_modify);
    }
  }
  return *name_to_modify;
}

String& TranslationHelper::ManglePrivateName(const Library& library,
                                             String* name_to_modify,
                                             bool symbolize,
                                             bool obfuscate) {
  if (name_to_modify->Length() >= 1 && name_to_modify->CharAt(0) == '_') {
    *name_to_modify = library.PrivateName(*name_to_modify);
    if (obfuscate && I->obfuscate()) {
      const String& library_key = String::Handle(library.private_key());
      Obfuscator obfuscator(thread_, library_key);
      *name_to_modify = obfuscator.Rename(*name_to_modify);
    }
  } else if (symbolize) {
    *name_to_modify = Symbols::New(thread_, *name_to_modify);
    if (obfuscate && I->obfuscate()) {
      const String& library_key = String::Handle();
      Obfuscator obfuscator(thread_, library_key);
      *name_to_modify = obfuscator.Rename(*name_to_modify);
    }
  }
  return *name_to_modify;
}

void FunctionNodeHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kFunctionNode);
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      /* Falls through */
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAsyncMarker:
      async_marker_ = static_cast<AsyncMarker>(helper_->ReadByte());
      if (++next_read_ == field) return;
      /* Falls through */
    case kDartAsyncMarker:
      dart_async_marker_ = static_cast<AsyncMarker>(
          helper_->ReadByte());  // read dart async marker.
      if (++next_read_ == field) return;
      /* Falls through */
    case kTypeParameters:
      helper_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
      /* Falls through */
    case kTotalParameterCount:
      total_parameter_count_ =
          helper_->ReadUInt();  // read total parameter count.
      if (++next_read_ == field) return;
      /* Falls through */
    case kRequiredParameterCount:
      required_parameter_count_ =
          helper_->ReadUInt();  // read required parameter count.
      if (++next_read_ == field) return;
      /* Falls through */
    case kPositionalParameters:
      helper_->SkipListOfVariableDeclarations();  // read positionals.
      if (++next_read_ == field) return;
      /* Falls through */
    case kNamedParameters:
      helper_->SkipListOfVariableDeclarations();  // read named.
      if (++next_read_ == field) return;
      /* Falls through */
    case kReturnType:
      helper_->SkipDartType();  // read return type.
      if (++next_read_ == field) return;
      /* Falls through */
    case kBody:
      if (helper_->ReadTag() == kSomething)
        helper_->SkipStatement();  // read body.
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

void TypeParameterHelper::ReadUntilExcluding(Field field) {
  for (; next_read_ < field; ++next_read_) {
    switch (next_read_) {
      case kFlags:
        flags_ = helper_->ReadFlags();
        break;
      case kAnnotations:
        helper_->SkipListOfExpressions();  // read annotations.
        break;
      case kName:
        name_index_ = helper_->ReadStringReference();  // read name index.
        break;
      case kBound:
        helper_->SkipDartType();
        break;
      case kDefaultType:
        if (helper_->ReadTag() == kSomething) {
          helper_->SkipDartType();
        }
        break;
      case kEnd:
        return;
    }
  }
}

void VariableDeclarationHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      /* Falls through */
    case kEqualPosition:
      equals_position_ = helper_->ReadPosition();  // read equals position.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations:
      helper_->SkipListOfExpressions();  // read annotations.
      if (++next_read_ == field) return;
      /* Falls through */
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      /* Falls through */
    case kNameIndex:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      /* Falls through */
    case kType:
      helper_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
      /* Falls through */
    case kInitializer:
      if (helper_->ReadTag() == kSomething)
        helper_->SkipExpression();  // read initializer.
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

FieldHelper::FieldHelper(KernelReaderHelper* helper, intptr_t offset)
    : helper_(helper),
      next_read_(kStart),
      has_function_literal_initializer_(false) {
  helper_->SetOffset(offset);
}

void FieldHelper::ReadUntilExcluding(Field field,
                                     bool detect_function_literal_initializer) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kField);
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kPosition:
      position_ = helper_->ReadPosition(false);  // read position.
      helper_->RecordTokenPosition(position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kEndPosition:
      end_position_ = helper_->ReadPosition(false);  // read end position.
      helper_->RecordTokenPosition(end_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      /* Falls through */
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kType:
      helper_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
      /* Falls through */
    case kInitializer:
      if (helper_->ReadTag() == kSomething) {
        if (detect_function_literal_initializer &&
            helper_->PeekTag() == kFunctionExpression) {
          AlternativeReadingScope alt(&helper_->reader_);
          Tag tag = helper_->ReadTag();
          ASSERT(tag == kFunctionExpression);
          helper_->ReadPosition();  // read position.

          FunctionNodeHelper helper(helper_);
          helper.ReadUntilIncluding(FunctionNodeHelper::kEndPosition);

          has_function_literal_initializer_ = true;
          function_literal_start_ = helper.position_;
          function_literal_end_ = helper.end_position_;
        }
        helper_->SkipExpression();  // read initializer.
      }
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

void ProcedureHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kProcedure);
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kStartPosition:
      start_position_ = helper_->ReadPosition(false);  // read position.
      helper_->RecordTokenPosition(start_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kPosition:
      position_ = helper_->ReadPosition(false);  // read position.
      helper_->RecordTokenPosition(position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kEndPosition:
      end_position_ = helper_->ReadPosition(false);  // read end position.
      helper_->RecordTokenPosition(end_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kKind:
      kind_ = static_cast<Kind>(helper_->ReadByte());
      if (++next_read_ == field) return;
      /* Falls through */
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      /* Falls through */
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kForwardingStubSuperTarget:
      if (helper_->ReadTag() == kSomething) {
        forwarding_stub_super_target_ = helper_->ReadCanonicalNameReference();
      }
      if (++next_read_ == field) return;
      /* Falls through */
    case kForwardingStubInterfaceTarget:
      if (helper_->ReadTag() == kSomething) {
        helper_->ReadCanonicalNameReference();
      }
      if (++next_read_ == field) return;
      /* Falls through */
    case kFunction:
      if (helper_->ReadTag() == kSomething)
        helper_->SkipFunctionNode();  // read function node.
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

void ConstructorHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kConstructor);
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kStartPosition:
      start_position_ = helper_->ReadPosition();  // read position.
      helper_->RecordTokenPosition(start_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      helper_->RecordTokenPosition(position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      helper_->RecordTokenPosition(end_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      /* Falls through */
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kFunction:
      helper_->SkipFunctionNode();  // read function.
      if (++next_read_ == field) return;
      /* Falls through */
    case kInitializers: {
      intptr_t list_length =
          helper_->ReadListLength();  // read initializers list length.
      for (intptr_t i = 0; i < list_length; i++) {
        helper_->SkipInitializer();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kEnd:
      return;
  }
}

void ClassHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kClass);
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kStartPosition:
      start_position_ = helper_->ReadPosition(false);  // read position.
      helper_->RecordTokenPosition(start_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kPosition:
      position_ = helper_->ReadPosition(false);  // read position.
      helper_->RecordTokenPosition(position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      helper_->RecordTokenPosition(end_position_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kFlags:
      flags_ = helper_->ReadFlags();  // read flags.
      if (++next_read_ == field) return;
      /* Falls through */
    case kNameIndex:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kTypeParameters:
      helper_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSuperClass: {
      Tag type_tag = helper_->ReadTag();  // read super class type (part 1).
      if (type_tag == kSomething) {
        helper_->SkipDartType();  // read super class type (part 2).
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kMixinType: {
      Tag type_tag = helper_->ReadTag();  // read mixin type (part 1).
      if (type_tag == kSomething) {
        helper_->SkipDartType();  // read mixin type (part 2).
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kImplementedClasses:
      helper_->SkipListOfDartTypes();  // read implemented_classes.
      if (++next_read_ == field) return;
      /* Falls through */
    case kFields: {
      intptr_t list_length =
          helper_->ReadListLength();  // read fields list length.
      for (intptr_t i = 0; i < list_length; i++) {
        FieldHelper field_helper(helper_);
        field_helper.ReadUntilExcluding(FieldHelper::kEnd);  // read field.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kConstructors: {
      intptr_t list_length =
          helper_->ReadListLength();  // read constructors list length.
      for (intptr_t i = 0; i < list_length; i++) {
        ConstructorHelper constructor_helper(helper_);
        constructor_helper.ReadUntilExcluding(
            ConstructorHelper::kEnd);  // read constructor.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kProcedures: {
      procedure_count_ = helper_->ReadListLength();  // read procedures #.
      for (intptr_t i = 0; i < procedure_count_; i++) {
        ProcedureHelper procedure_helper(helper_);
        procedure_helper.ReadUntilExcluding(
            ProcedureHelper::kEnd);  // read procedure.
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kClassIndex:
      // Read class index.
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        helper_->reader_.ReadUInt32();
      }
      helper_->reader_.ReadUInt32();
      helper_->reader_.ReadUInt32();
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

void LibraryHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kFlags: {
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      /* Falls through */
    case kName:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      /* Falls through */
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      /* Falls through */
    case kAnnotations:
      helper_->SkipListOfExpressions();  // read annotations.
      if (++next_read_ == field) return;
      /* Falls through */
    case kDependencies: {
      intptr_t dependency_count = helper_->ReadUInt();  // read list length.
      for (intptr_t i = 0; i < dependency_count; ++i) {
        helper_->SkipLibraryDependency();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kAdditionalExports: {
      intptr_t name_count = helper_->ReadUInt();
      for (intptr_t i = 0; i < name_count; ++i) {
        helper_->SkipCanonicalNameReference();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kParts: {
      intptr_t part_count = helper_->ReadUInt();  // read list length.
      for (intptr_t i = 0; i < part_count; ++i) {
        helper_->SkipLibraryPart();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kTypedefs: {
      intptr_t typedef_count = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < typedef_count; i++) {
        helper_->SkipLibraryTypedef();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kClasses: {
      class_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < class_count_; ++i) {
        ClassHelper class_helper(helper_);
        class_helper.ReadUntilExcluding(ClassHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kToplevelField: {
      intptr_t field_count = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < field_count; ++i) {
        FieldHelper field_helper(helper_);
        field_helper.ReadUntilExcluding(FieldHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kToplevelProcedures: {
      procedure_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        ProcedureHelper procedure_helper(helper_);
        procedure_helper.ReadUntilExcluding(ProcedureHelper::kEnd);
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kLibraryIndex:
      // Read library index.
      for (intptr_t i = 0; i < class_count_; ++i) {
        helper_->reader_.ReadUInt32();
      }
      helper_->reader_.ReadUInt32();
      helper_->reader_.ReadUInt32();
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        helper_->reader_.ReadUInt32();
      }
      helper_->reader_.ReadUInt32();
      helper_->reader_.ReadUInt32();
      if (++next_read_ == field) return;
      /* Falls through */
    case kEnd:
      return;
  }
}

void LibraryDependencyHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kFileOffset: {
      helper_->ReadPosition();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kFlags: {
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kAnnotations: {
      helper_->SkipListOfExpressions();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kTargetLibrary: {
      target_library_canonical_name_ = helper_->ReadCanonicalNameReference();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kName: {
      name_index_ = helper_->ReadStringReference();
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kCombinators: {
      intptr_t count = helper_->ReadListLength();
      for (intptr_t i = 0; i < count; ++i) {
        // Skip flags
        helper_->SkipBytes(1);
        // Skip list of names.
        helper_->SkipListOfStrings();
      }
      if (++next_read_ == field) return;
    }
      /* Falls through */
    case kEnd:
      return;
  }
}

MetadataHelper::MetadataHelper(KernelReaderHelper* helper)
    : helper_(helper),
      translation_helper_(helper->translation_helper_),
      mappings_offset_(0),
      mappings_num_(0),
      last_node_offset_(0),
      last_mapping_index_(0) {}

void MetadataHelper::SetMetadataMappings(intptr_t mappings_offset,
                                         intptr_t mappings_num) {
  ASSERT((mappings_offset_ == 0) && (mappings_num_ == 0));
  ASSERT((mappings_offset != 0) && (mappings_num != 0));
  mappings_offset_ = mappings_offset;
  mappings_num_ = mappings_num;

#ifdef DEBUG
  // Verify that node offsets are sorted.
  {
    Reader reader(H.metadata_mappings());
    reader.set_offset(mappings_offset);

    intptr_t prev_node_offset = 0;
    for (intptr_t i = 0; i < mappings_num; ++i) {
      intptr_t node_offset = reader.ReadUInt32();
      intptr_t md_offset = reader.ReadUInt32();

      ASSERT((node_offset > 0) && (md_offset >= 0));
      ASSERT(node_offset > prev_node_offset);
      prev_node_offset = node_offset;
    }
  }
#endif  // DEBUG

  last_node_offset_ = kIntptrMax;
  last_mapping_index_ = 0;
}

intptr_t MetadataHelper::FindMetadataMapping(intptr_t node_offset) {
  const intptr_t kUInt32Size = 4;
  ASSERT(mappings_num_ > 0);

  Reader reader(H.metadata_mappings());

  intptr_t left = 0;
  intptr_t right = mappings_num_ - 1;
  while (left < right) {
    intptr_t mid = ((right - left) / 2) + left;
    intptr_t mid_node_offset =
        reader.ReadUInt32At(mappings_offset_ + mid * 2 * kUInt32Size);

    if (node_offset < mid_node_offset) {
      right = mid - 1;
    } else if (node_offset > mid_node_offset) {
      left = mid + 1;
    } else {
      return mid;  // Exact match found.
    }
  }
  ASSERT((0 <= left) && (left <= mappings_num_));

  // Approximate match is found. Make sure it has an offset greater or equal
  // to the given node offset.
  if (left < mappings_num_) {
    intptr_t found_node_offset =
        reader.ReadUInt32At(mappings_offset_ + left * 2 * kUInt32Size);

    if (found_node_offset < node_offset) {
      ++left;
    }
  }
  ASSERT((left == mappings_num_) ||
         static_cast<intptr_t>(reader.ReadUInt32At(
             mappings_offset_ + left * 2 * kUInt32Size)) >= node_offset);

  return left;
}

intptr_t MetadataHelper::GetNextMetadataPayloadOffset(intptr_t node_offset) {
  helper_->EnsureMetadataIsScanned();

  if (mappings_num_ == 0) {
    return -1;  // No metadata.
  }

  node_offset += helper_->data_program_offset_;

  // Nodes are parsed in linear order most of the time, so do the search
  // only if looking back.
  if (node_offset < last_node_offset_) {
    last_mapping_index_ = FindMetadataMapping(node_offset);
  }

  intptr_t index = last_mapping_index_;
  intptr_t mapping_node_offset = 0;
  intptr_t mapping_md_offset = -1;

  Reader reader(H.metadata_mappings());
  const intptr_t kUInt32Size = 4;
  reader.set_offset(mappings_offset_ + index * 2 * kUInt32Size);

  for (; index < mappings_num_; ++index) {
    mapping_node_offset = reader.ReadUInt32();
    mapping_md_offset = reader.ReadUInt32();

    if (mapping_node_offset >= node_offset) {
      break;
    }
  }

  last_mapping_index_ = index;
  last_node_offset_ = node_offset;

  if ((index < mappings_num_) && (mapping_node_offset == node_offset)) {
    ASSERT(mapping_md_offset >= 0);
    return mapping_md_offset;
  } else {
    return -1;
  }
}

intptr_t KernelReaderHelper::ReaderOffset() const {
  return reader_.offset();
}

void KernelReaderHelper::SetOffset(intptr_t offset) {
  reader_.set_offset(offset);
}

void KernelReaderHelper::SkipBytes(intptr_t bytes) {
  reader_.set_offset(ReaderOffset() + bytes);
}

bool KernelReaderHelper::ReadBool() {
  return reader_.ReadBool();
}

uint8_t KernelReaderHelper::ReadByte() {
  return reader_.ReadByte();
}

uint32_t KernelReaderHelper::ReadUInt() {
  return reader_.ReadUInt();
}

uint32_t KernelReaderHelper::ReadUInt32() {
  return reader_.ReadUInt32();
}

uint32_t KernelReaderHelper::PeekUInt() {
  AlternativeReadingScope alt(&reader_);
  return reader_.ReadUInt();
}

double KernelReaderHelper::ReadDouble() {
  return reader_.ReadDouble();
}

uint32_t KernelReaderHelper::PeekListLength() {
  AlternativeReadingScope alt(&reader_);
  return reader_.ReadListLength();
}

intptr_t KernelReaderHelper::ReadListLength() {
  return reader_.ReadListLength();
}

StringIndex KernelReaderHelper::ReadStringReference() {
  return StringIndex(ReadUInt());
}

NameIndex KernelReaderHelper::ReadCanonicalNameReference() {
  return reader_.ReadCanonicalNameReference();
}

StringIndex KernelReaderHelper::ReadNameAsStringIndex() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    ReadUInt();  // read library index.
  }
  return name_index;
}

const String& KernelReaderHelper::ReadNameAsMethodName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartMethodName(library_reference, name_index);
  } else {
    return H.DartMethodName(NameIndex(), name_index);
  }
}

const String& KernelReaderHelper::ReadNameAsSetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartSetterName(library_reference, name_index);
  } else {
    return H.DartSetterName(NameIndex(), name_index);
  }
}

const String& KernelReaderHelper::ReadNameAsGetterName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartGetterName(library_reference, name_index);
  } else {
    return H.DartGetterName(NameIndex(), name_index);
  }
}

const String& KernelReaderHelper::ReadNameAsFieldName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    NameIndex library_reference =
        ReadCanonicalNameReference();  // read library index.
    return H.DartFieldName(library_reference, name_index);
  } else {
    return H.DartFieldName(NameIndex(), name_index);
  }
}

void KernelReaderHelper::SkipFlags() {
  ReadFlags();
}

void KernelReaderHelper::SkipStringReference() {
  ReadUInt();
}

void KernelReaderHelper::SkipConstantReference() {
  ReadUInt();
}

void KernelReaderHelper::SkipCanonicalNameReference() {
  ReadUInt();
}

void KernelReaderHelper::ReportUnexpectedTag(const char* variant, Tag tag) {
  H.ReportError(script_, TokenPosition::kNoSource,
                "Unexpected tag %d (%s) in ?, expected %s", tag,
                Reader::TagName(tag), variant);
}

void KernelReaderHelper::SkipDartType() {
  Tag tag = ReadTag();
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
    case kVoidType:
    case kBottomType:
      // those contain nothing.
      return;
    case kInterfaceType:
      SkipInterfaceType(false);
      return;
    case kSimpleInterfaceType:
      SkipInterfaceType(true);
      return;
    case kFunctionType:
      SkipFunctionType(false);
      return;
    case kSimpleFunctionType:
      SkipFunctionType(true);
      return;
    case kTypeParameterType:
      ReadUInt();              // read index for parameter.
      SkipOptionalDartType();  // read bound bound.
      return;
    default:
      ReportUnexpectedTag("type", tag);
      UNREACHABLE();
  }
}

void KernelReaderHelper::SkipOptionalDartType() {
  Tag tag = ReadTag();  // read tag.
  if (tag == kNothing) {
    return;
  }
  ASSERT(tag == kSomething);

  SkipDartType();  // read type.
}

void KernelReaderHelper::SkipInterfaceType(bool simple) {
  ReadUInt();  // read klass_name.
  if (!simple) {
    SkipListOfDartTypes();  // read list of types.
  }
}

void KernelReaderHelper::SkipFunctionType(bool simple) {
  if (!simple) {
    SkipTypeParametersList();  // read type_parameters.
    ReadUInt();                // read required parameter count.
    ReadUInt();                // read total parameter count.
  }

  SkipListOfDartTypes();  // read positional_parameters types.

  if (!simple) {
    const intptr_t named_count =
        ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i) {
      // read string reference (i.e. named_parameters[i].name).
      SkipStringReference();
      SkipDartType();  // read named_parameters[i].type.
    }
  }

  SkipListOfStrings();  // read positional parameter names.

  if (!simple) {
    SkipCanonicalNameReference();  // read typedef reference.
  }

  SkipDartType();  // read return type.
}

void KernelReaderHelper::SkipStatementList() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStatement();  // read ith expression.
  }
}

void KernelReaderHelper::SkipListOfExpressions() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipExpression();  // read ith expression.
  }
}

void KernelReaderHelper::SkipListOfDartTypes() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipDartType();  // read ith type.
  }
}

void KernelReaderHelper::SkipListOfStrings() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStringReference();  // read ith string index.
  }
}

void KernelReaderHelper::SkipListOfVariableDeclarations() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipVariableDeclaration();  // read ith variable declaration.
  }
}

void KernelReaderHelper::SkipTypeParametersList() {
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    TypeParameterHelper helper(this);
    helper.Finish();
  }
}

void KernelReaderHelper::SkipInitializer() {
  Tag tag = ReadTag();
  ReadByte();  // read isSynthetic flag.
  switch (tag) {
    case kInvalidInitializer:
      return;
    case kFieldInitializer:
      SkipCanonicalNameReference();  // read field_reference.
      SkipExpression();              // read value.
      return;
    case kSuperInitializer:
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kRedirectingInitializer:
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kLocalInitializer:
      SkipVariableDeclaration();  // read variable.
      return;
    case kAssertInitializer:
      SkipStatement();
      return;
    default:
      ReportUnexpectedTag("initializer", tag);
      UNREACHABLE();
  }
}

void KernelReaderHelper::SkipExpression() {
  uint8_t payload = 0;
  Tag tag = ReadTag(&payload);
  switch (tag) {
    case kInvalidExpression:
      ReadPosition();
      SkipStringReference();
      return;
    case kVariableGet:
      ReadPosition();          // read position.
      ReadUInt();              // read kernel position.
      ReadUInt();              // read relative variable index.
      SkipOptionalDartType();  // read promoted type.
      return;
    case kSpecializedVariableGet:
      ReadPosition();  // read position.
      ReadUInt();      // read kernel position.
      return;
    case kVariableSet:
      ReadPosition();    // read position.
      ReadUInt();        // read kernel position.
      ReadUInt();        // read relative variable index.
      SkipExpression();  // read expression.
      return;
    case kSpecializedVariableSet:
      ReadPosition();    // read position.
      ReadUInt();        // read kernel position.
      SkipExpression();  // read expression.
      return;
    case kPropertyGet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kPropertySet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertyGet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertySet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kDirectPropertyGet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      return;
    case kDirectPropertySet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      SkipExpression();              // read value·
      return;
    case kStaticGet:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      return;
    case kStaticSet:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipExpression();              // read expression.
      return;
    case kMethodInvocation:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kSuperMethodInvocation:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipCanonicalNameReference();  // read interface_target_reference.
      return;
    case kDirectMethodInvocation:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kStaticInvocation:
    case kConstStaticInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read procedure_reference.
      SkipArguments();               // read arguments.
      return;
    case kConstructorInvocation:
    case kConstConstructorInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kNot:
      SkipExpression();  // read expression.
      return;
    case kLogicalExpression:
      SkipExpression();  // read left.
      SkipBytes(1);      // read operator.
      SkipExpression();  // read right.
      return;
    case kConditionalExpression:
      SkipExpression();        // read condition.
      SkipExpression();        // read then.
      SkipExpression();        // read otherwise.
      SkipOptionalDartType();  // read unused static type.
      return;
    case kStringConcatenation:
      ReadPosition();           // read position.
      SkipListOfExpressions();  // read list of expressions.
      return;
    case kIsExpression:
      ReadPosition();    // read position.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kAsExpression:
      ReadPosition();    // read position.
      SkipFlags();       // read flags.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kSymbolLiteral:
      SkipStringReference();  // read index into string table.
      return;
    case kTypeLiteral:
      SkipDartType();  // read type.
      return;
    case kThisExpression:
      return;
    case kRethrow:
      ReadPosition();  // read position.
      return;
    case kThrow:
      ReadPosition();    // read position.
      SkipExpression();  // read expression.
      return;
    case kListLiteral:
    case kConstListLiteral:
      ReadPosition();           // read position.
      SkipDartType();           // read type.
      SkipListOfExpressions();  // read list of expressions.
      return;
    case kMapLiteral:
    case kConstMapLiteral: {
      ReadPosition();                           // read position.
      SkipDartType();                           // read key type.
      SkipDartType();                           // read value type.
      intptr_t list_length = ReadListLength();  // read list length.
      for (intptr_t i = 0; i < list_length; ++i) {
        SkipExpression();  // read ith key.
        SkipExpression();  // read ith value.
      }
      return;
    }
    case kFunctionExpression:
      ReadPosition();      // read position.
      SkipFunctionNode();  // read function node.
      return;
    case kLet:
      SkipVariableDeclaration();  // read variable declaration.
      SkipExpression();           // read expression.
      return;
    case kInstantiation:
      SkipExpression();       // read expression.
      SkipListOfDartTypes();  // read type arguments.
      return;
    case kBigIntLiteral:
      SkipStringReference();  // read string reference.
      return;
    case kStringLiteral:
      SkipStringReference();  // read string reference.
      return;
    case kSpecializedIntLiteral:
      return;
    case kNegativeIntLiteral:
      ReadUInt();  // read value.
      return;
    case kPositiveIntLiteral:
      ReadUInt();  // read value.
      return;
    case kDoubleLiteral:
      ReadDouble();  // read value.
      return;
    case kTrueLiteral:
      return;
    case kFalseLiteral:
      return;
    case kNullLiteral:
      return;
    case kConstantExpression:
      SkipConstantReference();
      return;
    case kLoadLibrary:
    case kCheckLibraryIsLoaded:
      ReadUInt();  // skip library index
      return;
    default:
      ReportUnexpectedTag("expression", tag);
      UNREACHABLE();
  }
}

void KernelReaderHelper::SkipStatement() {
  Tag tag = ReadTag();  // read tag.
  switch (tag) {
    case kExpressionStatement:
      SkipExpression();  // read expression.
      return;
    case kBlock:
      SkipStatementList();
      return;
    case kEmptyStatement:
      return;
    case kAssertBlock:
      SkipStatementList();
      return;
    case kAssertStatement:
      SkipExpression();  // Read condition.
      ReadPosition();    // read condition start offset.
      ReadPosition();    // read condition end offset.
      if (ReadTag() == kSomething) {
        SkipExpression();  // read (rest of) message.
      }
      return;
    case kLabeledStatement:
      SkipStatement();  // read body.
      return;
    case kBreakStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kWhileStatement:
      ReadPosition();    // read position.
      SkipExpression();  // read condition.
      SkipStatement();   // read body.
      return;
    case kDoStatement:
      ReadPosition();    // read position.
      SkipStatement();   // read body.
      SkipExpression();  // read condition.
      return;
    case kForStatement: {
      ReadPosition();                    // read position.
      SkipListOfVariableDeclarations();  // read variables.
      Tag tag = ReadTag();               // Read first part of condition.
      if (tag == kSomething) {
        SkipExpression();  // read rest of condition.
      }
      SkipListOfExpressions();  // read updates.
      SkipStatement();          // read body.
      return;
    }
    case kForInStatement:
    case kAsyncForInStatement:
      ReadPosition();             // read position.
      ReadPosition();             // read body position.
      SkipVariableDeclaration();  // read variable.
      SkipExpression();           // read iterable.
      SkipStatement();            // read body.
      return;
    case kSwitchStatement: {
      ReadPosition();                     // read position.
      SkipExpression();                   // read condition.
      int case_count = ReadListLength();  // read number of cases.
      for (intptr_t i = 0; i < case_count; ++i) {
        int expression_count = ReadListLength();  // read number of expressions.
        for (intptr_t j = 0; j < expression_count; ++j) {
          ReadPosition();    // read jth position.
          SkipExpression();  // read jth expression.
        }
        ReadBool();       // read is_default.
        SkipStatement();  // read body.
      }
      return;
    }
    case kContinueSwitchStatement:
      ReadPosition();  // read position.
      ReadUInt();      // read target_index.
      return;
    case kIfStatement:
      ReadPosition();    // read position.
      SkipExpression();  // read condition.
      SkipStatement();   // read then.
      SkipStatement();   // read otherwise.
      return;
    case kReturnStatement: {
      ReadPosition();       // read position
      Tag tag = ReadTag();  // read (first part of) expression.
      if (tag == kSomething) {
        SkipExpression();  // read (rest of) expression.
      }
      return;
    }
    case kTryCatch: {
      SkipStatement();                          // read body.
      ReadByte();                               // read flags
      intptr_t catch_count = ReadListLength();  // read number of catches.
      for (intptr_t i = 0; i < catch_count; ++i) {
        ReadPosition();   // read position.
        SkipDartType();   // read guard.
        tag = ReadTag();  // read first part of exception.
        if (tag == kSomething) {
          SkipVariableDeclaration();  // read exception.
        }
        tag = ReadTag();  // read first part of stack trace.
        if (tag == kSomething) {
          SkipVariableDeclaration();  // read stack trace.
        }
        SkipStatement();  // read body.
      }
      return;
    }
    case kTryFinally:
      SkipStatement();  // read body.
      SkipStatement();  // read finalizer.
      return;
    case kYieldStatement: {
      TokenPosition position = ReadPosition();  // read position.
      RecordYieldPosition(position);
      ReadByte();        // read flags.
      SkipExpression();  // read expression.
      return;
    }
    case kVariableDeclaration:
      SkipVariableDeclaration();  // read variable declaration.
      return;
    case kFunctionDeclaration:
      ReadPosition();             // read position.
      SkipVariableDeclaration();  // read variable.
      SkipFunctionNode();         // read function node.
      return;
    default:
      ReportUnexpectedTag("statement", tag);
      UNREACHABLE();
  }
}

void KernelReaderHelper::SkipFunctionNode() {
  FunctionNodeHelper function_node_helper(this);
  function_node_helper.ReadUntilExcluding(FunctionNodeHelper::kEnd);
}

void KernelReaderHelper::SkipName() {
  StringIndex name_index = ReadStringReference();  // read name index.
  if ((H.StringSize(name_index) >= 1) && H.CharacterAt(name_index, 0) == '_') {
    SkipCanonicalNameReference();  // read library index.
  }
}

void KernelReaderHelper::SkipArguments() {
  ReadUInt();  // read argument count.

  SkipListOfDartTypes();    // read list of types.
  SkipListOfExpressions();  // read positionals.

  // List of named.
  intptr_t list_length = ReadListLength();  // read list length.
  for (intptr_t i = 0; i < list_length; ++i) {
    SkipStringReference();  // read ith name index.
    SkipExpression();       // read ith expression.
  }
}

void KernelReaderHelper::SkipVariableDeclaration() {
  VariableDeclarationHelper helper(this);
  helper.ReadUntilExcluding(VariableDeclarationHelper::kEnd);
}

void KernelReaderHelper::SkipLibraryCombinator() {
  ReadBool();                        // read is_show.
  intptr_t name_count = ReadUInt();  // read list length.
  for (intptr_t j = 0; j < name_count; ++j) {
    ReadUInt();  // read ith entry of name_indices.
  }
}

void KernelReaderHelper::SkipLibraryDependency() {
  ReadPosition();  // read file offset.
  ReadFlags();
  SkipListOfExpressions();  // Annotations.
  ReadCanonicalNameReference();
  ReadStringReference();  // Name.
  intptr_t combinator_count = ReadListLength();
  for (intptr_t i = 0; i < combinator_count; ++i) {
    SkipLibraryCombinator();
  }
}

void KernelReaderHelper::SkipLibraryPart() {
  SkipListOfExpressions();  // Read annotations.
  SkipStringReference();    // Read part URI index.
}

void KernelReaderHelper::SkipLibraryTypedef() {
  SkipCanonicalNameReference();  // read canonical name.
  ReadUInt();                    // read source_uri_index.
  ReadPosition();                // read position.
  SkipStringReference();         // read name index.
  SkipListOfExpressions();       // read annotations.
  SkipTypeParametersList();      // read type parameters.
  SkipDartType();                // read type.
}

TokenPosition KernelReaderHelper::ReadPosition(bool record) {
  TokenPosition position = reader_.ReadPosition();
  if (record) {
    RecordTokenPosition(position);
  }
  return position;
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
