// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_translation_helper.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/parser.h"  // for ParsedFunction
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

RawFunction* TranslationHelper::LookupMethodByMember(
    NameIndex target,
    const String& method_name) {
  NameIndex kernel_class = EnclosingName(target);
  Class& klass = Class::Handle(Z, LookupClassByKernelClass(kernel_class));

  RawFunction* function = klass.LookupFunctionAllowPrivate(method_name);
#ifdef DEBUG
  if (function == Object::null()) {
    THR_Print("Unable to find \'%s\' in %s\n", method_name.ToCString(),
              klass.ToCString());
  }
#endif
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
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
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

MetadataHelper::MetadataHelper(KernelReaderHelper* helper,
                               const char* tag,
                               bool precompiler_only)
    : helper_(helper),
      translation_helper_(helper->translation_helper_),
      tag_(tag),
      mappings_scanned_(false),
      precompiler_only_(precompiler_only),
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

void MetadataHelper::ScanMetadataMappings() {
  const intptr_t kUInt32Size = 4;
  Reader reader(H.metadata_mappings());
  if (reader.size() == 0) {
    return;
  }

  // Scan through metadata mappings in reverse direction.

  // Read metadataMappings length.
  intptr_t offset = reader.size() - kUInt32Size;
  uint32_t metadata_num = reader.ReadUInt32At(offset);

  if (metadata_num == 0) {
    ASSERT(H.metadata_mappings().LengthInBytes() == kUInt32Size);
    return;
  }

  // Read metadataMappings elements.
  for (uint32_t i = 0; i < metadata_num; ++i) {
    // Read nodeOffsetToMetadataOffset length.
    offset -= kUInt32Size;
    uint32_t mappings_num = reader.ReadUInt32At(offset);

    // Skip nodeOffsetToMetadataOffset and read tag.
    offset -= mappings_num * 2 * kUInt32Size + kUInt32Size;
    StringIndex tag = StringIndex(reader.ReadUInt32At(offset));

    if (mappings_num == 0) {
      continue;
    }

    if (H.StringEquals(tag, tag_)) {
      if ((!FLAG_precompiled_mode) && precompiler_only_) {
        FATAL1("%s metadata is allowed in precompiled mode only", tag_);
      }
      SetMetadataMappings(offset + kUInt32Size, mappings_num);
      return;
    }
  }
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
  if (!mappings_scanned_) {
    ScanMetadataMappings();
    mappings_scanned_ = true;
  }

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

DirectCallMetadataHelper::DirectCallMetadataHelper(KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

bool DirectCallMetadataHelper::ReadMetadata(intptr_t node_offset,
                                            NameIndex* target_name,
                                            bool* check_receiver_for_null) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return false;
  }

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  *target_name = helper_->ReadCanonicalNameReference();
  *check_receiver_for_null = helper_->ReadBool();
  return true;
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForPropertyGet(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  if (H.IsProcedure(kernel_name) && !H.IsGetter(kernel_name)) {
    // Tear-off. Use method extractor as direct call target.
    const String& method_name = H.DartMethodName(kernel_name);
    const Function& target_method = Function::ZoneHandle(
        helper_->zone_, H.LookupMethodByMember(kernel_name, method_name));
    const String& getter_name = H.DartGetterName(kernel_name);
    return DirectCallMetadata(
        Function::ZoneHandle(helper_->zone_,
                             target_method.GetMethodExtractor(getter_name)),
        check_receiver_for_null);
  } else {
    const String& getter_name = H.DartGetterName(kernel_name);
    const Function& target = Function::ZoneHandle(
        helper_->zone_, H.LookupMethodByMember(kernel_name, getter_name));
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
    return DirectCallMetadata(target, check_receiver_for_null);
  }
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForPropertySet(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  const String& method_name = H.DartSetterName(kernel_name);
  const Function& target = Function::ZoneHandle(
      helper_->zone_, H.LookupMethodByMember(kernel_name, method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  return DirectCallMetadata(target, check_receiver_for_null);
}

DirectCallMetadata DirectCallMetadataHelper::GetDirectTargetForMethodInvocation(
    intptr_t node_offset) {
  NameIndex kernel_name;
  bool check_receiver_for_null = false;
  if (!ReadMetadata(node_offset, &kernel_name, &check_receiver_for_null)) {
    return DirectCallMetadata(Function::null_function(), false);
  }

  const String& method_name = H.DartProcedureName(kernel_name);
  const Function& target = Function::ZoneHandle(
      helper_->zone_, H.LookupMethodByMember(kernel_name, method_name));

  return DirectCallMetadata(target, check_receiver_for_null);
}

InferredTypeMetadataHelper::InferredTypeMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

InferredTypeMetadata InferredTypeMetadataHelper::GetInferredType(
    intptr_t node_offset) {
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return InferredTypeMetadata(kDynamicCid, true);
  }

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  const NameIndex kernel_name = helper_->ReadCanonicalNameReference();
  const bool nullable = helper_->ReadBool();

  if (H.IsRoot(kernel_name)) {
    return InferredTypeMetadata(kDynamicCid, nullable);
  }

  const Class& klass =
      Class::Handle(helper_->zone_, H.LookupClassByKernelClass(kernel_name));
  ASSERT(!klass.IsNull());

  intptr_t cid = klass.id();
  if (cid == kClosureCid) {
    // VM uses more specific function types and doesn't expect instances of
    // _Closure class, so inferred _Closure class doesn't make sense for the VM.
    cid = kDynamicCid;
  }

  return InferredTypeMetadata(cid, nullable);
}

ProcedureAttributesMetadataHelper::ProcedureAttributesMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

bool ProcedureAttributesMetadataHelper::ReadMetadata(
    intptr_t node_offset,
    ProcedureAttributesMetadata* metadata) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return false;
  }

  AlternativeReadingScope alt(&helper_->reader_, &H.metadata_payloads(),
                              md_offset);

  const int kDynamicUsesBit = 1 << 0;
  const int kNonThisUsesBit = 1 << 1;
  const int kTearOffUsesBit = 1 << 2;

  const uint8_t flags = helper_->ReadByte();
  metadata->has_dynamic_invocations =
      (flags & kDynamicUsesBit) == kDynamicUsesBit;
  metadata->has_non_this_uses = (flags & kNonThisUsesBit) == kNonThisUsesBit;
  metadata->has_tearoff_uses = (flags & kTearOffUsesBit) == kTearOffUsesBit;
  return true;
}

ProcedureAttributesMetadata
ProcedureAttributesMetadataHelper::GetProcedureAttributes(
    intptr_t node_offset) {
  ProcedureAttributesMetadata metadata;
  ReadMetadata(node_offset, &metadata);
  return metadata;
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

void KernelReaderHelper::ReadUntilFunctionNode() {
  const Tag tag = PeekTag();
  if (tag == kProcedure) {
    ProcedureHelper procedure_helper(this);
    procedure_helper.ReadUntilExcluding(ProcedureHelper::kFunction);
    if (ReadTag() == kNothing) {  // read function node tag.
      // Running a procedure without a function node doesn't make sense.
      UNREACHABLE();
    }
    // Now at start of FunctionNode.
  } else if (tag == kConstructor) {
    ConstructorHelper constructor_helper(this);
    constructor_helper.ReadUntilExcluding(ConstructorHelper::kFunction);
    // Now at start of FunctionNode.
    // Notice that we also have a list of initializers after that!
  } else if (tag == kFunctionNode) {
    // Already at start of FunctionNode.
  } else {
    ReportUnexpectedTag("a procedure, a constructor or a function node", tag);
    UNREACHABLE();
  }
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

intptr_t ActiveClass::MemberTypeParameterCount(Zone* zone) {
  ASSERT(member != NULL);
  if (member->IsFactory()) {
    TypeArguments& class_types =
        TypeArguments::Handle(zone, klass->type_parameters());
    return class_types.Length();
  } else if (member->IsMethodExtractor()) {
    Function& extracted =
        Function::Handle(zone, member->extracted_method_closure());
    TypeArguments& function_types =
        TypeArguments::Handle(zone, extracted.type_parameters());
    return function_types.Length();
  } else {
    TypeArguments& function_types =
        TypeArguments::Handle(zone, member->type_parameters());
    return function_types.Length();
  }
}

ActiveTypeParametersScope::ActiveTypeParametersScope(ActiveClass* active_class,
                                                     const Function& innermost,
                                                     Zone* Z)
    : active_class_(active_class), saved_(*active_class) {
  active_class_->enclosing = &innermost;

  intptr_t num_params = 0;

  Function& f = Function::Handle(Z);
  TypeArguments& f_params = TypeArguments::Handle(Z);
  for (f = innermost.raw(); f.parent_function() != Object::null();
       f = f.parent_function()) {
    f_params = f.type_parameters();
    num_params += f_params.Length();
  }
  if (num_params == 0) return;

  TypeArguments& params =
      TypeArguments::Handle(Z, TypeArguments::New(num_params));

  intptr_t index = num_params;
  for (f = innermost.raw(); f.parent_function() != Object::null();
       f = f.parent_function()) {
    f_params = f.type_parameters();
    for (intptr_t j = f_params.Length() - 1; j >= 0; --j) {
      params.SetTypeAt(--index, AbstractType::Handle(Z, f_params.TypeAt(j)));
    }
  }

  active_class_->local_type_parameters = &params;
}

ActiveTypeParametersScope::ActiveTypeParametersScope(
    ActiveClass* active_class,
    const Function* function,
    const TypeArguments& new_params,
    Zone* Z)
    : active_class_(active_class), saved_(*active_class) {
  active_class_->enclosing = function;

  if (new_params.IsNull()) return;

  const TypeArguments* old_params = active_class->local_type_parameters;
  const intptr_t old_param_count =
      old_params == NULL ? 0 : old_params->Length();
  const TypeArguments& extended_params = TypeArguments::Handle(
      Z, TypeArguments::New(old_param_count + new_params.Length()));

  intptr_t index = 0;
  for (intptr_t i = 0; i < old_param_count; ++i) {
    extended_params.SetTypeAt(
        index++, AbstractType::ZoneHandle(Z, old_params->TypeAt(i)));
  }
  for (intptr_t i = 0; i < new_params.Length(); ++i) {
    extended_params.SetTypeAt(
        index++, AbstractType::ZoneHandle(Z, new_params.TypeAt(i)));
  }

  active_class_->local_type_parameters = &extended_params;
}

TypeTranslator::TypeTranslator(KernelReaderHelper* helper,
                               ActiveClass* active_class,
                               bool finalize)
    : helper_(helper),
      translation_helper_(helper->translation_helper_),
      active_class_(active_class),
      type_parameter_scope_(NULL),
      zone_(translation_helper_.zone()),
      result_(AbstractType::Handle(translation_helper_.zone())),
      finalize_(finalize) {}

AbstractType& TypeTranslator::BuildType() {
  BuildTypeInternal();

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return AbstractType::ZoneHandle(Z, result_.raw());
}

AbstractType& TypeTranslator::BuildTypeWithoutFinalization() {
  bool saved_finalize = finalize_;
  finalize_ = false;
  BuildTypeInternal();
  finalize_ = saved_finalize;

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return AbstractType::ZoneHandle(Z, result_.raw());
}

AbstractType& TypeTranslator::BuildVariableType() {
  AbstractType& abstract_type = BuildType();

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  AbstractType& type = Type::ZoneHandle(Z);

  if (abstract_type.IsMalformed()) {
    type = AbstractType::dynamic_type().raw();
  } else {
    type = result_.raw();
  }

  return type;
}

void TypeTranslator::BuildTypeInternal(bool invalid_as_dynamic) {
  Tag tag = helper_->ReadTag();
  switch (tag) {
    case kInvalidType:
      if (invalid_as_dynamic) {
        result_ = Object::dynamic_type().raw();
      } else {
        result_ = ClassFinalizer::NewFinalizedMalformedType(
            Error::Handle(Z),  // No previous error.
            Script::Handle(Z, Script::null()), TokenPosition::kNoSource,
            "[InvalidType] in Kernel IR.");
      }
      break;
    case kDynamicType:
      result_ = Object::dynamic_type().raw();
      break;
    case kVoidType:
      result_ = Object::void_type().raw();
      break;
    case kBottomType:
      result_ =
          Class::Handle(Z, I->object_store()->null_class()).CanonicalType();
      break;
    case kInterfaceType:
      BuildInterfaceType(false);
      break;
    case kSimpleInterfaceType:
      BuildInterfaceType(true);
      break;
    case kFunctionType:
      BuildFunctionType(false);
      break;
    case kSimpleFunctionType:
      BuildFunctionType(true);
      break;
    case kTypeParameterType:
      BuildTypeParameterType();
      break;
    default:
      helper_->ReportUnexpectedTag("type", tag);
      UNREACHABLE();
  }
}

void TypeTranslator::BuildInterfaceType(bool simple) {
  // NOTE: That an interface type like `T<A, B>` is considered to be
  // malformed iff `T` is malformed.
  //   => We therefore ignore errors in `A` or `B`.

  NameIndex klass_name =
      helper_->ReadCanonicalNameReference();  // read klass_name.

  intptr_t length;
  if (simple) {
    length = 0;
  } else {
    length = helper_->ReadListLength();  // read type_arguments list length.
  }
  const TypeArguments& type_arguments =
      BuildTypeArguments(length);  // read type arguments.

  Object& klass = Object::Handle(Z, H.LookupClassByKernelClass(klass_name));
  result_ = Type::New(klass, type_arguments, TokenPosition::kNoSource);
  if (finalize_) {
    ASSERT(active_class_->klass != NULL);
    result_ = ClassFinalizer::FinalizeType(*active_class_->klass, result_);
  }
}

void TypeTranslator::BuildFunctionType(bool simple) {
  Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        active_class_->enclosing != NULL
                                            ? *active_class_->enclosing
                                            : Function::Handle(Z),
                                        TokenPosition::kNoSource));

  // Suspend finalization of types inside this one. They will be finalized after
  // the whole function type is constructed.
  //
  // TODO(31213): Test further when nested generic function types
  // are supported by fasta.
  bool finalize = finalize_;
  finalize_ = false;

  if (!simple) {
    LoadAndSetupTypeParameters(active_class_, signature_function,
                               helper_->ReadListLength(), signature_function);
  }

  ActiveTypeParametersScope scope(
      active_class_, &signature_function,
      TypeArguments::Handle(Z, signature_function.type_parameters()), Z);

  intptr_t required_count;
  intptr_t all_count;
  intptr_t positional_count;
  if (!simple) {
    required_count = helper_->ReadUInt();  // read required parameter count.
    all_count = helper_->ReadUInt();       // read total parameter count.
    positional_count =
        helper_->ReadListLength();  // read positional_parameters list length.
  } else {
    positional_count =
        helper_->ReadListLength();  // read positional_parameters list length.
    required_count = positional_count;
    all_count = positional_count;
  }

  const Array& parameter_types =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_types(parameter_types);
  const Array& parameter_names =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_names(parameter_names);

  intptr_t pos = 0;
  parameter_types.SetAt(pos, AbstractType::dynamic_type());
  parameter_names.SetAt(pos, H.DartSymbolPlain("_receiver_"));
  ++pos;
  for (intptr_t i = 0; i < positional_count; ++i, ++pos) {
    BuildTypeInternal();  // read ith positional parameter.
    if (result_.IsMalformed()) {
      result_ = AbstractType::dynamic_type().raw();
    }
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbolPlain("noname"));
  }

  // The additional first parameter is the receiver type (set to dynamic).
  signature_function.set_num_fixed_parameters(1 + required_count);
  signature_function.SetNumOptionalParameters(
      all_count - required_count, positional_count > required_count);

  if (!simple) {
    const intptr_t named_count =
        helper_->ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i, ++pos) {
      // read string reference (i.e. named_parameters[i].name).
      String& name = H.DartSymbolObfuscate(helper_->ReadStringReference());
      BuildTypeInternal();  // read named_parameters[i].type.
      if (result_.IsMalformed()) {
        result_ = AbstractType::dynamic_type().raw();
      }
      parameter_types.SetAt(pos, result_);
      parameter_names.SetAt(pos, name);
    }
  }

  helper_->SkipListOfStrings();  // read positional parameter names.

  if (!simple) {
    helper_->SkipCanonicalNameReference();  // read typedef reference.
  }

  BuildTypeInternal();  // read return type.
  if (result_.IsMalformed()) {
    result_ = AbstractType::dynamic_type().raw();
  }
  signature_function.set_result_type(result_);

  finalize_ = finalize;

  Type& signature_type =
      Type::ZoneHandle(Z, signature_function.SignatureType());

  if (finalize_) {
    signature_type ^=
        ClassFinalizer::FinalizeType(*active_class_->klass, signature_type);
    // Do not refer to signature_function anymore, since it may have been
    // replaced during canonicalization.
    signature_function = Function::null();
  }

  result_ = signature_type.raw();
}

void TypeTranslator::BuildTypeParameterType() {
  intptr_t parameter_index = helper_->ReadUInt();  // read parameter index.
  helper_->SkipOptionalDartType();                 // read bound.

  const TypeArguments& class_types =
      TypeArguments::Handle(Z, active_class_->klass->type_parameters());
  if (parameter_index < class_types.Length()) {
    // The index of the type parameter in [parameters] is
    // the same index into the `klass->type_parameters()` array.
    result_ ^= class_types.TypeAt(parameter_index);
    return;
  }
  parameter_index -= class_types.Length();

  if (active_class_->HasMember()) {
    if (active_class_->MemberIsFactoryProcedure()) {
      //
      // WARNING: This is a little hackish:
      //
      // We have a static factory constructor. The kernel IR gives the factory
      // constructor function its own type parameters (which are equal in name
      // and number to the ones of the enclosing class). I.e.,
      //
      //   class A<T> {
      //     factory A.x() { return new B<T>(); }
      //   }
      //
      //  is basically translated to this:
      //
      //   class A<T> {
      //     static A.x<T'>() { return new B<T'>(); }
      //   }
      //
      if (class_types.Length() > parameter_index) {
        result_ ^= class_types.TypeAt(parameter_index);
        return;
      }
      parameter_index -= class_types.Length();
    }

    intptr_t procedure_type_parameter_count =
        active_class_->MemberIsProcedure()
            ? active_class_->MemberTypeParameterCount(Z)
            : 0;
    if (procedure_type_parameter_count > 0) {
      if (procedure_type_parameter_count > parameter_index) {
        if (I->reify_generic_functions()) {
          result_ ^=
              TypeArguments::Handle(Z, active_class_->member->type_parameters())
                  .TypeAt(parameter_index);
        } else {
          result_ ^= Type::DynamicType();
        }
        return;
      }
      parameter_index -= procedure_type_parameter_count;
    }
  }

  if (active_class_->local_type_parameters != NULL) {
    if (parameter_index < active_class_->local_type_parameters->Length()) {
      if (I->reify_generic_functions()) {
        result_ ^=
            active_class_->local_type_parameters->TypeAt(parameter_index);
      } else {
        result_ ^= Type::DynamicType();
      }
      return;
    }
    parameter_index -= active_class_->local_type_parameters->Length();
  }

  if (type_parameter_scope_ != NULL &&
      parameter_index < type_parameter_scope_->outer_parameter_count() +
                            type_parameter_scope_->parameter_count()) {
    result_ ^= Type::DynamicType();
    return;
  }

  H.ReportError(
      helper_->script(), TokenPosition::kNoSource,
      "Unbound type parameter found in %s.  Please report this at dartbug.com.",
      active_class_->ToCString());
}

const TypeArguments& TypeTranslator::BuildTypeArguments(intptr_t length) {
  bool only_dynamic = true;
  intptr_t offset = helper_->ReaderOffset();
  for (intptr_t i = 0; i < length; ++i) {
    if (helper_->ReadTag() != kDynamicType) {  // Read the ith types tag.
      only_dynamic = false;
      helper_->SetOffset(offset);
      break;
    }
  }
  TypeArguments& type_arguments = TypeArguments::ZoneHandle(Z);
  if (!only_dynamic) {
    type_arguments = TypeArguments::New(length);
    for (intptr_t i = 0; i < length; ++i) {
      BuildTypeInternal(true);  // read ith type.
      type_arguments.SetTypeAt(i, result_);
    }

    if (finalize_) {
      type_arguments = type_arguments.Canonicalize();
    }
  }
  return type_arguments;
}

const TypeArguments& TypeTranslator::BuildInstantiatedTypeArguments(
    const Class& receiver_class,
    intptr_t length) {
  const TypeArguments& type_arguments = BuildTypeArguments(length);

  // If type_arguments is null all arguments are dynamic.
  // If, however, this class doesn't specify all the type arguments directly we
  // still need to finalize the type below in order to get any non-dynamic types
  // from any super. See http://www.dartbug.com/29537.
  if (type_arguments.IsNull() && receiver_class.NumTypeArguments() == length) {
    return type_arguments;
  }

  // We make a temporary [Type] object and use `ClassFinalizer::FinalizeType` to
  // finalize the argument types.
  // (This can for example make the [type_arguments] vector larger)
  Type& type = Type::Handle(
      Z, Type::New(receiver_class, type_arguments, TokenPosition::kNoSource));
  if (finalize_) {
    type ^= ClassFinalizer::FinalizeType(*active_class_->klass, type);
  }

  const TypeArguments& instantiated_type_arguments =
      TypeArguments::ZoneHandle(Z, type.arguments());
  return instantiated_type_arguments;
}

void TypeTranslator::LoadAndSetupTypeParameters(
    ActiveClass* active_class,
    const Object& set_on,
    intptr_t type_parameter_count,
    const Function& parameterized_function) {
  ASSERT(type_parameter_count >= 0);
  if (type_parameter_count == 0) {
    return;
  }
  ASSERT(set_on.IsClass() || set_on.IsFunction());
  bool set_on_class = set_on.IsClass();
  ASSERT(set_on_class == parameterized_function.IsNull());

  // First setup the type parameters, so if any of the following code uses it
  // (in a recursive way) we're fine.
  TypeArguments& type_parameters = TypeArguments::Handle(Z);
  TypeParameter& parameter = TypeParameter::Handle(Z);
  const Type& null_bound = Type::Handle(Z);

  // Step a) Create array of [TypeParameter] objects (without bound).
  type_parameters = TypeArguments::New(type_parameter_count);
  const Library& lib = Library::Handle(Z, active_class->klass->library());
  {
    AlternativeReadingScope alt(&helper_->reader_);
    for (intptr_t i = 0; i < type_parameter_count; i++) {
      TypeParameterHelper helper(helper_);
      helper.Finish();
      parameter = TypeParameter::New(
          set_on_class ? *active_class->klass : Class::Handle(Z),
          parameterized_function, i,
          H.DartIdentifier(lib, helper.name_index_),  // read ith name index.
          null_bound, TokenPosition::kNoSource);
      type_parameters.SetTypeAt(i, parameter);
    }
  }

  if (set_on.IsClass()) {
    Class::Cast(set_on).set_type_parameters(type_parameters);
  } else {
    Function::Cast(set_on).set_type_parameters(type_parameters);
  }

  const Function* enclosing = NULL;
  if (!parameterized_function.IsNull()) {
    enclosing = &parameterized_function;
  }
  ActiveTypeParametersScope scope(active_class, enclosing, type_parameters, Z);

  // Step b) Fill in the bounds of all [TypeParameter]s.
  for (intptr_t i = 0; i < type_parameter_count; i++) {
    TypeParameterHelper helper(helper_);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);

    // TODO(github.com/dart-lang/kernel/issues/42): This should be handled
    // by the frontend.
    parameter ^= type_parameters.TypeAt(i);
    const Tag tag = helper_->PeekTag();  // peek ith bound type.
    if (tag == kDynamicType) {
      helper_->SkipDartType();  // read ith bound.
      parameter.set_bound(Type::Handle(Z, I->object_store()->object_type()));
    } else {
      AbstractType& bound = BuildTypeWithoutFinalization();  // read ith bound.
      if (bound.IsMalformedOrMalbounded()) {
        bound = I->object_store()->object_type();
      }
      parameter.set_bound(bound);
    }

    helper.Finish();
  }
}

const Type& TypeTranslator::ReceiverType(const Class& klass) {
  ASSERT(!klass.IsNull());
  ASSERT(!klass.IsTypedefClass());
  // Note that if klass is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z, klass.CanonicalType());
  if (!type.IsNull()) {
    return type;
  }
  type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                   klass.token_pos());
  if (klass.is_type_finalized()) {
    type ^= ClassFinalizer::FinalizeType(klass, type);
    klass.SetCanonicalType(type);
  }
  return type;
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
