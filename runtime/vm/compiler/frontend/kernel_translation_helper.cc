// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_translation_helper.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/aot/precompiler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/frontend/constant_reader.h"
#include "vm/flags.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/parser.h"  // for ParsedFunction
#include "vm/symbols.h"

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
      allocation_space_(Heap::kNew),
      string_offsets_(TypedData::Handle(Z)),
      string_data_(ExternalTypedData::Handle(Z)),
      canonical_names_(TypedData::Handle(Z)),
      metadata_payloads_(ExternalTypedData::Handle(Z)),
      metadata_mappings_(ExternalTypedData::Handle(Z)),
      constants_(Array::Handle(Z)),
      constants_table_(ExternalTypedData::Handle(Z)),
      info_(KernelProgramInfo::Handle(Z)),
      name_index_handle_(Smi::Handle(Z)) {}

TranslationHelper::TranslationHelper(Thread* thread, Heap::Space space)
    : thread_(thread),
      zone_(thread->zone()),
      isolate_(thread->isolate()),
      allocation_space_(space),
      string_offsets_(TypedData::Handle(Z)),
      string_data_(ExternalTypedData::Handle(Z)),
      canonical_names_(TypedData::Handle(Z)),
      metadata_payloads_(ExternalTypedData::Handle(Z)),
      metadata_mappings_(ExternalTypedData::Handle(Z)),
      constants_(Array::Handle(Z)),
      constants_table_(ExternalTypedData::Handle(Z)),
      info_(KernelProgramInfo::Handle(Z)),
      name_index_handle_(Smi::Handle(Z)) {}

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
  SetConstantsTable(ExternalTypedData::Handle(Z, info.constants_table()));
  SetKernelProgramInfo(info);
}

GrowableObjectArrayPtr TranslationHelper::EnsurePotentialPragmaFunctions() {
  auto& funcs =
      GrowableObjectArray::Handle(Z, info_.potential_pragma_functions());
  if (funcs.IsNull()) {
    funcs = GrowableObjectArray::New(16, Heap::kNew);
    info_.set_potential_pragma_functions(funcs);
  }
  return funcs.raw();
}

void TranslationHelper::AddPotentialExtensionLibrary(const Library& library) {
  if (potential_extension_libraries_ == nullptr) {
    potential_extension_libraries_ =
        &GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  }
  potential_extension_libraries_->Add(library);
}

GrowableObjectArrayPtr TranslationHelper::GetPotentialExtensionLibraries() {
  if (potential_extension_libraries_ != nullptr) {
    GrowableObjectArray* result = potential_extension_libraries_;
    potential_extension_libraries_ = nullptr;
    return result->raw();
  }
  return GrowableObjectArray::null();
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
  ASSERT(Utils::IsAligned(metadata_payloads.DataAddr(0), kWordSize));
  metadata_payloads_ = metadata_payloads.raw();
}

void TranslationHelper::SetMetadataMappings(
    const ExternalTypedData& metadata_mappings) {
  ASSERT(metadata_mappings_.IsNull());
  metadata_mappings_ = metadata_mappings.raw();
}

void TranslationHelper::SetConstants(const Array& constants) {
  ASSERT(constants_.IsNull() ||
         (constants.IsNull() || constants.Length() == 0));
  constants_ = constants.raw();
}

void TranslationHelper::SetConstantsTable(
    const ExternalTypedData& constants_table) {
  ASSERT(constants_table_.IsNull());
  constants_table_ = constants_table.raw();
}

void TranslationHelper::SetKernelProgramInfo(const KernelProgramInfo& info) {
  info_ = info.raw();
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
  return StringEquals(CanonicalNameString(kind), "@fields") ||
         StringEquals(CanonicalNameString(kind), "@=fields");
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

InstancePtr TranslationHelper::Canonicalize(const Instance& instance) {
  if (instance.IsNull()) return instance.raw();

  return instance.Canonicalize(thread());
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

const String& TranslationHelper::DartString(
    const GrowableHandlePtrArray<const String>& pieces) {
  return String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces));
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

// TODO(https://github.com/dart-lang/sdk/issues/37517): Should emit code to
// throw a NoSuchMethodError.
static void CheckStaticLookup(const Object& target) {
  if (target.IsNull()) {
#ifndef PRODUCT
    ASSERT(Isolate::Current()->HasAttemptedReload());
    Report::LongJump(LanguageError::Handle(LanguageError::New(String::Handle(
        String::New("Unimplemented handling of missing static target")))));
#else
    UNREACHABLE();
#endif
  }
}

LibraryPtr TranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex kernel_library) {
  // We only use the string and don't rely on having any particular parent.
  // This ASSERT is just a sanity check.
  ASSERT(IsLibrary(kernel_library) ||
         IsAdministrative(CanonicalNameParent(kernel_library)));
  {
    name_index_handle_ = Smi::New(kernel_library);
    LibraryPtr raw_lib = info_.LookupLibrary(thread_, name_index_handle_);
    NoSafepointScope no_safepoint_scope(thread_);
    if (raw_lib != Library::null()) {
      return raw_lib;
    }
  }

  const String& library_name =
      DartSymbolPlain(CanonicalNameString(kernel_library));
  ASSERT(!library_name.IsNull());
  const Library& library =
      Library::Handle(Z, Library::LookupLibrary(thread_, library_name));
  CheckStaticLookup(library);
  name_index_handle_ = Smi::New(kernel_library);
  return info_.InsertLibrary(thread_, name_index_handle_, library);
}

ClassPtr TranslationHelper::LookupClassByKernelClass(NameIndex kernel_class) {
  ASSERT(IsClass(kernel_class));
  {
    name_index_handle_ = Smi::New(kernel_class);
    ClassPtr raw_class = info_.LookupClass(thread_, name_index_handle_);
    NoSafepointScope no_safepoint_scope(thread_);
    if (raw_class != Class::null()) {
      return raw_class;
    }
  }

  const String& class_name = DartClassName(kernel_class);
  NameIndex kernel_library = CanonicalNameParent(kernel_class);
  Library& library =
      Library::Handle(Z, LookupLibraryByKernelLibrary(kernel_library));
  ASSERT(!library.IsNull());
  const Class& klass =
      Class::Handle(Z, library.LookupClassAllowPrivate(class_name));
  CheckStaticLookup(klass);
  ASSERT(!klass.IsNull());
  name_index_handle_ = Smi::New(kernel_class);
  return info_.InsertClass(thread_, name_index_handle_, klass);
}

FieldPtr TranslationHelper::LookupFieldByKernelField(NameIndex kernel_field) {
  ASSERT(IsField(kernel_field));
  NameIndex enclosing = EnclosingName(kernel_field);

  Class& klass = Class::Handle(Z);
  if (IsLibrary(enclosing)) {
    Library& library =
        Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    klass = library.toplevel_class();
    CheckStaticLookup(klass);
  } else {
    ASSERT(IsClass(enclosing));
    klass = LookupClassByKernelClass(enclosing);
  }
  Field& field = Field::Handle(
      Z, klass.LookupFieldAllowPrivate(
             DartSymbolObfuscate(CanonicalNameString(kernel_field))));
  CheckStaticLookup(field);
  return field.raw();
}

FunctionPtr TranslationHelper::LookupStaticMethodByKernelProcedure(
    NameIndex procedure) {
  const String& procedure_name = DartProcedureName(procedure);

  // The parent is either a library or a class (in which case the procedure is a
  // static method).
  NameIndex enclosing = EnclosingName(procedure);
  if (IsLibrary(enclosing)) {
    Library& library =
        Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    Function& function =
        Function::Handle(Z, library.LookupFunctionAllowPrivate(procedure_name));
    CheckStaticLookup(function);
    return function.raw();
  } else {
    ASSERT(IsClass(enclosing));
    Class& klass = Class::Handle(Z, LookupClassByKernelClass(enclosing));
    const auto& error = klass.EnsureIsFinalized(thread_);
    ASSERT(error == Error::null());
    Function& function = Function::ZoneHandle(
        Z, klass.LookupFunctionAllowPrivate(procedure_name));
    CheckStaticLookup(function);
    return function.raw();
  }
}

FunctionPtr TranslationHelper::LookupConstructorByKernelConstructor(
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  Class& klass =
      Class::Handle(Z, LookupClassByKernelClass(EnclosingName(constructor)));
  CheckStaticLookup(klass);
  return LookupConstructorByKernelConstructor(klass, constructor);
}

FunctionPtr TranslationHelper::LookupConstructorByKernelConstructor(
    const Class& owner,
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  const auto& error = owner.EnsureIsFinalized(thread_);
  ASSERT(error == Error::null());
  Function& function = Function::Handle(
      Z, owner.LookupConstructorAllowPrivate(DartConstructorName(constructor)));
  CheckStaticLookup(function);
  return function.raw();
}

FunctionPtr TranslationHelper::LookupConstructorByKernelConstructor(
    const Class& owner,
    StringIndex constructor_name) {
  GrowableHandlePtrArray<const String> pieces(Z, 3);
  pieces.Add(String::Handle(Z, owner.Name()));
  pieces.Add(Symbols::Dot());
  String& name = DartSymbolPlain(constructor_name);
  pieces.Add(ManglePrivateName(Library::Handle(owner.library()), &name));

  String& new_name =
      String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces));
  const auto& error = owner.EnsureIsFinalized(thread_);
  ASSERT(error == Error::null());
  FunctionPtr function = owner.LookupConstructorAllowPrivate(new_name);
  ASSERT(function != Object::null());
  return function;
}

FunctionPtr TranslationHelper::LookupMethodByMember(NameIndex target,
                                                    const String& method_name) {
  NameIndex kernel_class = EnclosingName(target);
  Class& klass = Class::Handle(Z, LookupClassByKernelClass(kernel_class));
  Function& function = Function::Handle(Z);
  if (klass.EnsureIsFinalized(thread_) == Error::null()) {
    function = klass.LookupFunctionAllowPrivate(method_name);
  }
#ifdef DEBUG
  if (function.IsNull()) {
    THR_Print("Unable to find \'%s\' in %s\n", method_name.ToCString(),
              klass.ToCString());
  }
#endif
  CheckStaticLookup(function);
  ASSERT(!function.IsNull());
  return function.raw();
}

FunctionPtr TranslationHelper::LookupDynamicFunction(const Class& klass,
                                                     const String& name) {
  // Search the superclass chain for the selector.
  Class& iterate_klass = Class::Handle(Z, klass.raw());
  while (!iterate_klass.IsNull()) {
    FunctionPtr function =
        iterate_klass.LookupDynamicFunctionAllowPrivate(name);
    if (function != Object::null()) {
      return function;
    }
    iterate_klass = iterate_klass.SuperClass();
  }
  return Function::null();
}

Type& TranslationHelper::GetDeclarationType(const Class& klass) {
  ASSERT(!klass.IsNull());
  // Note that if cls is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z);
  if (klass.is_type_finalized()) {
    type = klass.DeclarationType();
  } else {
    // Note that the type argument vector is not yet extended.
    type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                     klass.token_pos());
  }
  return type;
}

void TranslationHelper::SetupFieldAccessorFunction(
    const Class& klass,
    const Function& function,
    const AbstractType& field_type) {
  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  intptr_t parameter_count = (is_method ? 1 : 0) + (is_setter ? 1 : 0);

  function.SetNumOptionalParameters(0, false);
  function.set_num_fixed_parameters(parameter_count);
  function.set_parameter_types(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  function.CreateNameArrayIncludingFlags(Heap::kNew);

  intptr_t pos = 0;
  if (is_method) {
    function.SetParameterTypeAt(pos, GetDeclarationType(klass));
    function.SetParameterNameAt(pos, Symbols::This());
    pos++;
  }
  if (is_setter) {
    function.SetParameterTypeAt(pos, field_type);
    function.SetParameterNameAt(pos, Symbols::Value());
    pos++;
  }
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
      FALL_THROUGH;
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAsyncMarker:
      async_marker_ = static_cast<AsyncMarker>(helper_->ReadByte());
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kDartAsyncMarker:
      dart_async_marker_ = static_cast<AsyncMarker>(
          helper_->ReadByte());  // read dart async marker.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kTypeParameters:
      helper_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kTotalParameterCount:
      total_parameter_count_ =
          helper_->ReadUInt();  // read total parameter count.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kRequiredParameterCount:
      required_parameter_count_ =
          helper_->ReadUInt();  // read required parameter count.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kPositionalParameters:
      helper_->SkipListOfVariableDeclarations();  // read positionals.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kNamedParameters:
      helper_->SkipListOfVariableDeclarations();  // read named.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kReturnType:
      helper_->SkipDartType();  // read return type.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kBody:
      if (helper_->ReadTag() == kSomething)
        helper_->SkipStatement();  // read body.
      if (++next_read_ == field) return;
      FALL_THROUGH;
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
      case kVariance:
        helper_->ReadVariance();
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
      FALL_THROUGH;
    case kEqualPosition:
      equals_position_ = helper_->ReadPosition();  // read equals position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAnnotations:
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kNameIndex:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kType:
      helper_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kInitializer:
      if (helper_->ReadTag() == kSomething)
        helper_->SkipExpression();  // read initializer.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEnd:
      return;
  }
}

FieldHelper::FieldHelper(KernelReaderHelper* helper, intptr_t offset)
    : helper_(helper), next_read_(kStart) {
  helper_->SetOffset(offset);
}

void FieldHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    case kStart: {
      Tag tag = helper_->ReadTag();  // read tag.
      ASSERT(tag == kField);
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kCanonicalNameGetter:
      canonical_name_getter_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name_getter.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kCanonicalNameSetter:
      canonical_name_setter_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name_setter.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFlags:
      flags_ = helper_->ReadUInt();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kType:
      helper_->SkipDartType();  // read type.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kInitializer:
      if (helper_->ReadTag() == kSomething) {
        helper_->SkipExpression();  // read initializer.
      }
      if (++next_read_ == field) return;
      FALL_THROUGH;
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
      FALL_THROUGH;
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kStartPosition:
      start_position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kKind:
      kind_ = static_cast<Kind>(helper_->ReadByte());
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kStubKind:
      stub_kind_ = static_cast<StubKind>(helper_->ReadByte());
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFlags:
      flags_ = helper_->ReadUInt();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kStubTarget:
      if (stub_kind_ == kForwardingSuperStubKind) {
        forwarding_stub_super_target_ = helper_->ReadCanonicalNameReference();
      } else {
        helper_->ReadCanonicalNameReference();
      }
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFunction:
      if (helper_->ReadTag() == kSomething) {
        helper_->SkipFunctionNode();  // read function node.
      }
      if (++next_read_ == field) return;
      FALL_THROUGH;
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
      FALL_THROUGH;
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kStartPosition:
      start_position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFlags:
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kName:
      helper_->SkipName();  // read name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kFunction:
      helper_->SkipFunctionNode();  // read function.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kInitializers: {
      intptr_t list_length =
          helper_->ReadListLength();  // read initializers list length.
      for (intptr_t i = 0; i < list_length; i++) {
        helper_->SkipInitializer();
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
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
      FALL_THROUGH;
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kStartPosition:
      start_position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kPosition:
      position_ = helper_->ReadPosition();  // read position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEndPosition:
      end_position_ = helper_->ReadPosition();  // read end position.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFlags:
      flags_ = helper_->ReadFlags();  // read flags.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kNameIndex:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();  // read list length.
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kTypeParameters:
      helper_->SkipTypeParametersList();  // read type parameters.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSuperClass: {
      Tag type_tag = helper_->ReadTag();  // read super class type (part 1).
      if (type_tag == kSomething) {
        helper_->SkipDartType();  // read super class type (part 2).
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kMixinType: {
      Tag type_tag = helper_->ReadTag();  // read mixin type (part 1).
      if (type_tag == kSomething) {
        helper_->SkipDartType();  // read mixin type (part 2).
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kImplementedClasses:
      helper_->SkipListOfDartTypes();  // read implemented_classes.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kFields: {
      intptr_t list_length =
          helper_->ReadListLength();  // read fields list length.
      for (intptr_t i = 0; i < list_length; i++) {
        FieldHelper field_helper(helper_);
        field_helper.ReadUntilExcluding(FieldHelper::kEnd);  // read field.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
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
      FALL_THROUGH;
    case kProcedures: {
      procedure_count_ = helper_->ReadListLength();  // read procedures #.
      for (intptr_t i = 0; i < procedure_count_; i++) {
        ProcedureHelper procedure_helper(helper_);
        procedure_helper.ReadUntilExcluding(
            ProcedureHelper::kEnd);  // read procedure.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kClassIndex:
      // Read class index.
      for (intptr_t i = 0; i < procedure_count_; ++i) {
        helper_->reader_.ReadUInt32();
      }
      helper_->reader_.ReadUInt32();
      helper_->reader_.ReadUInt32();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kEnd:
      return;
  }
}

void LibraryHelper::ReadUntilExcluding(Field field) {
  if (field <= next_read_) return;

  // Ordered with fall-through.
  switch (next_read_) {
    // Note that this (up to canonical name) needs to be kept in sync with
    // "library_canonical_name" (currently in "kernel_loader.h").
    case kFlags: {
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    }
    case kLanguageVersion: {
      helper_->ReadUInt();  // Read major language version.
      helper_->ReadUInt();  // Read minor language version.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    }
    case kCanonicalName:
      canonical_name_ =
          helper_->ReadCanonicalNameReference();  // read canonical_name.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kName:
      name_index_ = helper_->ReadStringReference();  // read name index.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kSourceUriIndex:
      source_uri_index_ = helper_->ReadUInt();  // read source_uri_index.
      helper_->set_current_script_id(source_uri_index_);
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kProblemsAsJson: {
      intptr_t length = helper_->ReadUInt();  // read length of table.
      for (intptr_t i = 0; i < length; ++i) {
        helper_->SkipBytes(helper_->ReadUInt());  // read strings.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kAnnotations:
      helper_->SkipListOfExpressions();  // read annotations.
      if (++next_read_ == field) return;
      FALL_THROUGH;
    case kDependencies: {
      intptr_t dependency_count = helper_->ReadUInt();  // read list length.
      for (intptr_t i = 0; i < dependency_count; ++i) {
        helper_->SkipLibraryDependency();
      }
      if (++next_read_ == field) return;
    }
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
      FALL_THROUGH;
    }
    case kFlags: {
      flags_ = helper_->ReadFlags();
      if (++next_read_ == field) return;
      FALL_THROUGH;
    }
    case kAnnotations: {
      annotation_count_ = helper_->ReadListLength();
      for (intptr_t i = 0; i < annotation_count_; ++i) {
        helper_->SkipExpression();  // read ith expression.
      }
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kTargetLibrary: {
      target_library_canonical_name_ = helper_->ReadCanonicalNameReference();
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
    case kName: {
      name_index_ = helper_->ReadStringReference();
      if (++next_read_ == field) return;
    }
      FALL_THROUGH;
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
      FALL_THROUGH;
    case kEnd:
      return;
  }
}

#if defined(DEBUG)

void MetadataHelper::VerifyMetadataMappings(
    const ExternalTypedData& metadata_mappings) {
  const intptr_t kUInt32Size = 4;
  Reader reader(metadata_mappings);
  if (reader.size() == 0) {
    return;
  }

  // Scan through metadata mappings in reverse direction.

  // Read metadataMappings length.
  intptr_t offset = reader.size() - kUInt32Size;
  const intptr_t metadata_num = reader.ReadUInt32At(offset);

  if (metadata_num == 0) {
    ASSERT(metadata_mappings.LengthInBytes() == kUInt32Size);
    return;
  }

  // Read metadataMappings elements.
  for (intptr_t i = 0; i < metadata_num; ++i) {
    // Read nodeOffsetToMetadataOffset length.
    offset -= kUInt32Size;
    const intptr_t mappings_num = reader.ReadUInt32At(offset);

    // Skip nodeOffsetToMetadataOffset.
    offset -= mappings_num * 2 * kUInt32Size;

    // Verify that node offsets are sorted.
    intptr_t prev_node_offset = -1;
    reader.set_offset(offset);
    for (intptr_t j = 0; j < mappings_num; ++j) {
      const intptr_t node_offset = reader.ReadUInt32();
      const intptr_t md_offset = reader.ReadUInt32();

      ASSERT(node_offset >= 0 && md_offset >= 0);
      ASSERT(node_offset > prev_node_offset);
      prev_node_offset = node_offset;
    }

    // Skip tag.
    offset -= kUInt32Size;
  }
}

#endif  // defined(DEBUG)

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

intptr_t MetadataHelper::GetComponentMetadataPayloadOffset() {
  const intptr_t kComponentNodeOffset = 0;
  return GetNextMetadataPayloadOffset(kComponentNodeOffset -
                                      helper_->data_program_offset_);
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

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

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
    KernelReaderHelper* helper,
    ConstantReader* constant_reader)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true),
      constant_reader_(constant_reader) {}

InferredTypeMetadata InferredTypeMetadataHelper::GetInferredType(
    intptr_t node_offset,
    bool read_constant) {
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return InferredTypeMetadata(kDynamicCid,
                                InferredTypeMetadata::kFlagNullable);
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  const NameIndex kernel_name = helper_->ReadCanonicalNameReference();
  const uint8_t flags = helper_->ReadByte();

  const Object* constant_value = &Object::null_object();
  if ((flags & InferredTypeMetadata::kFlagConstant) != 0) {
    const intptr_t constant_offset = helper_->ReadUInt();
    if (read_constant) {
      constant_value = &Object::ZoneHandle(
          H.zone(), constant_reader_->ReadConstant(constant_offset));
    }
  }

  if (H.IsRoot(kernel_name)) {
    ASSERT((flags & InferredTypeMetadata::kFlagConstant) == 0);
    return InferredTypeMetadata(kDynamicCid, flags);
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

  return InferredTypeMetadata(cid, flags, *constant_value);
}

void ProcedureAttributesMetadata::InitializeFromFlags(uint8_t flags) {
  const int kMethodOrSetterCalledDynamicallyBit = 1 << 0;
  const int kNonThisUsesBit = 1 << 1;
  const int kTearOffUsesBit = 1 << 2;
  const int kThisUsesBit = 1 << 3;
  const int kGetterCalledDynamicallyBit = 1 << 4;

  method_or_setter_called_dynamically =
      (flags & kMethodOrSetterCalledDynamicallyBit) != 0;
  getter_called_dynamically = (flags & kGetterCalledDynamicallyBit) != 0;
  has_this_uses = (flags & kThisUsesBit) != 0;
  has_non_this_uses = (flags & kNonThisUsesBit) != 0;
  has_tearoff_uses = (flags & kTearOffUsesBit) != 0;
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

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  const uint8_t flags = helper_->ReadByte();
  metadata->InitializeFromFlags(flags);
  metadata->method_or_setter_selector_id = helper_->ReadUInt();
  metadata->getter_selector_id = helper_->ReadUInt();
  return true;
}

ProcedureAttributesMetadata
ProcedureAttributesMetadataHelper::GetProcedureAttributes(
    intptr_t node_offset) {
  ProcedureAttributesMetadata metadata;
  ReadMetadata(node_offset, &metadata);
  return metadata;
}

ObfuscationProhibitionsMetadataHelper::ObfuscationProhibitionsMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

void ObfuscationProhibitionsMetadataHelper::ReadMetadata(intptr_t node_offset) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return;
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);
  Obfuscator O(Thread::Current(), String::Handle());

  intptr_t len = helper_->ReadUInt32();
  for (int i = 0; i < len; ++i) {
    StringIndex name = helper_->ReadStringReference();
    O.PreventRenaming(translation_helper_.DartSymbolPlain(name));
  }
  return;
}

LoadingUnitsMetadataHelper::LoadingUnitsMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

void LoadingUnitsMetadataHelper::ReadMetadata(intptr_t node_offset) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return;
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  intptr_t unit_count = helper_->ReadUInt();
  Array& loading_units = Array::Handle(zone, Array::New(unit_count + 1));
  LoadingUnit& unit = LoadingUnit::Handle(zone);
  LoadingUnit& parent = LoadingUnit::Handle(zone);
  Library& lib = Library::Handle(zone);

  for (int i = 0; i < unit_count; i++) {
    intptr_t id = helper_->ReadUInt();
    unit = LoadingUnit::New();
    unit.set_id(id);

    intptr_t parent_id = helper_->ReadUInt();
    RELEASE_ASSERT(parent_id < id);
    parent ^= loading_units.At(parent_id);
    RELEASE_ASSERT(parent.IsNull() == (parent_id == 0));
    unit.set_parent(parent);

    intptr_t library_count = helper_->ReadUInt();
    for (intptr_t j = 0; j < library_count; j++) {
      const String& uri =
          translation_helper_.DartSymbolPlain(helper_->ReadStringReference());
      lib = Library::LookupLibrary(thread, uri);
      if (lib.IsNull()) {
        FATAL1("Missing library: %s\n", uri.ToCString());
      }
      lib.set_loading_unit(unit);
    }

    loading_units.SetAt(id, unit);
  }

  ObjectStore* object_store = Isolate::Current()->object_store();
  ASSERT(object_store->loading_units() == Array::null());
  object_store->set_loading_units(loading_units);
}

CallSiteAttributesMetadataHelper::CallSiteAttributesMetadataHelper(
    KernelReaderHelper* helper,
    TypeTranslator* type_translator)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ false),
      type_translator_(*type_translator) {}

bool CallSiteAttributesMetadataHelper::ReadMetadata(
    intptr_t node_offset,
    CallSiteAttributesMetadata* metadata) {
  intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return false;
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  metadata->receiver_type = &type_translator_.BuildType();
  return true;
}

CallSiteAttributesMetadata
CallSiteAttributesMetadataHelper::GetCallSiteAttributes(intptr_t node_offset) {
  CallSiteAttributesMetadata metadata;
  ReadMetadata(node_offset, &metadata);
  return metadata;
}

TableSelectorMetadataHelper::TableSelectorMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

TableSelectorMetadata* TableSelectorMetadataHelper::GetTableSelectorMetadata(
    Zone* zone) {
  const intptr_t node_offset = GetComponentMetadataPayloadOffset();
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);
  if (md_offset < 0) {
    return nullptr;
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  const intptr_t num_selectors = helper_->ReadUInt();
  TableSelectorMetadata* metadata =
      new (zone) TableSelectorMetadata(num_selectors);
  for (intptr_t i = 0; i < num_selectors; i++) {
    ReadTableSelectorInfo(&metadata->selectors[i]);
  }
  return metadata;
}

void TableSelectorMetadataHelper::ReadTableSelectorInfo(
    TableSelectorInfo* info) {
  info->call_count = helper_->ReadUInt();
  uint8_t flags = helper_->ReadByte();
  info->called_on_null = (flags & kCalledOnNullBit) != 0;
  info->torn_off = (flags & kTornOffBit) != 0;
}

UnboxingInfoMetadataHelper::UnboxingInfoMetadataHelper(
    KernelReaderHelper* helper)
    : MetadataHelper(helper, tag(), /* precompiler_only = */ true) {}

UnboxingInfoMetadata* UnboxingInfoMetadataHelper::GetUnboxingInfoMetadata(
    intptr_t node_offset) {
  const intptr_t md_offset = GetNextMetadataPayloadOffset(node_offset);

  if (md_offset < 0) {
    return nullptr;
  }

  AlternativeReadingScopeWithNewData alt(&helper_->reader_,
                                         &H.metadata_payloads(), md_offset);

  const intptr_t num_args = helper_->ReadUInt();
  const auto info = new (helper_->zone_) UnboxingInfoMetadata();
  info->SetArgsCount(num_args);
  for (intptr_t i = 0; i < num_args; i++) {
    const auto arg_info = helper_->ReadByte();
    assert(arg_info >= UnboxingInfoMetadata::kBoxed &&
           arg_info < UnboxingInfoMetadata::kUnboxingCandidate);
    info->unboxed_args_info[i] =
        static_cast<UnboxingInfoMetadata::UnboxingInfoTag>(arg_info);
  }
  const auto return_info = helper_->ReadByte();
  assert(return_info >= UnboxingInfoMetadata::kBoxed &&
         return_info < UnboxingInfoMetadata::kUnboxingCandidate);
  info->return_info =
      static_cast<UnboxingInfoMetadata::UnboxingInfoTag>(return_info);
  return info;
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

NameIndex KernelReaderHelper::ReadInterfaceMemberNameReference() {
  NameIndex name_index = reader_.ReadCanonicalNameReference();
  NameIndex origin_name_index = reader_.ReadCanonicalNameReference();
  if (!FLAG_precompiled_mode && origin_name_index != NameIndex::kInvalidName) {
    // Reference to a skipped member signature target, return the origin target.
    return origin_name_index;
  }
  return name_index;
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

void KernelReaderHelper::SkipInterfaceMemberNameReference() {
  SkipCanonicalNameReference();
  SkipCanonicalNameReference();
}

void KernelReaderHelper::ReportUnexpectedTag(const char* variant, Tag tag) {
  FATAL3("Unexpected tag %d (%s) in ?, expected %s", tag, Reader::TagName(tag),
         variant);
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
    case kNeverType:
      ReadNullability();
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
    case kTypedefType:
      ReadNullability();      // read nullability.
      ReadUInt();             // read index for canonical name.
      SkipListOfDartTypes();  // read list of types.
      return;
    case kTypeParameterType:
      ReadNullability();       // read nullability.
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
  ReadNullability();  // read nullability.
  ReadUInt();  // read klass_name.
  if (!simple) {
    SkipListOfDartTypes();  // read list of types.
  }
}

void KernelReaderHelper::SkipFunctionType(bool simple) {
  ReadNullability();  // read nullability.

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
      SkipBytes(1);    // read flags
    }
  }

  if (!simple) {
    SkipOptionalDartType();  // read typedef type.
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
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kRedirectingInitializer:
      ReadPosition();                // read position.
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
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
      return;
    case kPropertySet:
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertyGet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
      return;
    case kSuperPropertySet:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipExpression();              // read value.
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
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
      ReadFlags();                   // read flags.
      ReadPosition();                // read position.
      SkipExpression();              // read receiver.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
      return;
    case kSuperMethodInvocation:
      ReadPosition();                // read position.
      SkipName();                    // read name.
      SkipArguments();               // read arguments.
      SkipInterfaceMemberNameReference();  // read interface_target_reference.
      return;
    case kStaticInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read procedure_reference.
      SkipArguments();               // read arguments.
      return;
    case kConstructorInvocation:
      ReadPosition();                // read position.
      SkipCanonicalNameReference();  // read target_reference.
      SkipArguments();               // read arguments.
      return;
    case kNot:
      SkipExpression();  // read expression.
      return;
    case kNullCheck:
      ReadPosition();    // read position.
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
      if (translation_helper_.info().kernel_binary_version() >= 38) {
        SkipFlags();  // read flags.
      }
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
      return;
    case kAsExpression:
      ReadPosition();    // read position.
      SkipFlags();       // read flags.
      SkipExpression();  // read operand.
      SkipDartType();    // read type.
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
      ReadPosition();           // read position.
      SkipDartType();           // read type.
      SkipListOfExpressions();  // read list of expressions.
      return;
    case kSetLiteral:
      // Set literals are currently desugared in the frontend and will not
      // reach the VM. See http://dartbug.com/35124 for discussion.
      UNREACHABLE();
      return;
    case kMapLiteral: {
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
    case kBlockExpression:
      SkipStatementList();
      SkipExpression();  // read expression.
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
      ReadPosition();  // read position.
      SkipDartType();  // read type.
      SkipConstantReference();
      return;
    case kLoadLibrary:
    case kCheckLibraryIsLoaded:
      ReadUInt();  // skip library index
      return;
    case kConstStaticInvocation:
    case kConstConstructorInvocation:
    case kConstListLiteral:
    case kConstSetLiteral:
    case kConstMapLiteral:
    case kSymbolLiteral:
      // Const invocations and const literals are removed by the
      // constant evaluator.
    case kListConcatenation:
    case kSetConcatenation:
    case kMapConcatenation:
    case kInstanceCreation:
    case kFileUriExpression:
      // Collection concatenation, instance creation operations and
      // in-expression URI changes are internal to the front end and
      // removed by the constant evaluator.
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
      ReadPosition();  // read file offset.
      ReadPosition();  // read file end offset.
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
      ReadPosition();    // read position.
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
  SkipCanonicalNameReference();      // read canonical name.
  ReadUInt();                        // read source_uri_index.
  ReadPosition();                    // read position.
  SkipStringReference();             // read name index.
  SkipListOfExpressions();           // read annotations.
  SkipTypeParametersList();          // read type parameters.
  SkipDartType();                    // read type.
  SkipTypeParametersList();          // read type parameters of function type.
  SkipListOfVariableDeclarations();  // read positional parameters.
  SkipListOfVariableDeclarations();  // read named parameters.
}

TokenPosition KernelReaderHelper::ReadPosition() {
  TokenPosition position = reader_.ReadPosition();
  RecordTokenPosition(position);
  return position;
}

intptr_t KernelReaderHelper::SourceTableFieldCountFromFirstLibraryOffset() {
  return SourceTableFieldCountFromFirstLibraryOffset41Plus;
}

intptr_t KernelReaderHelper::SourceTableSize() {
  AlternativeReadingScope alt(&reader_);
  intptr_t library_count = reader_.ReadFromIndexNoReset(
      reader_.size(), LibraryCountFieldCountFromEnd, 1, 0);

  const intptr_t count_from_first_library_offset =
      SourceTableFieldCountFromFirstLibraryOffset();

  intptr_t source_table_offset = reader_.ReadFromIndexNoReset(
      reader_.size(),
      LibraryCountFieldCountFromEnd + 1 + library_count + 1 +
          count_from_first_library_offset,
      1, 0);
  SetOffset(source_table_offset);  // read source table offset.
  return reader_.ReadUInt32();     // read source table size.
}

intptr_t KernelReaderHelper::GetOffsetForSourceInfo(intptr_t index) {
  AlternativeReadingScope alt(&reader_);
  intptr_t library_count = reader_.ReadFromIndexNoReset(
      reader_.size(), LibraryCountFieldCountFromEnd, 1, 0);

  const intptr_t count_from_first_library_offset =
      SourceTableFieldCountFromFirstLibraryOffset();

  intptr_t source_table_offset = reader_.ReadFromIndexNoReset(
      reader_.size(),
      LibraryCountFieldCountFromEnd + 1 + library_count + 1 +
          count_from_first_library_offset,
      1, 0);
  intptr_t next_field_offset = reader_.ReadUInt32();
  SetOffset(source_table_offset);
  intptr_t size = reader_.ReadUInt32();  // read source table size.

  return reader_.ReadFromIndexNoReset(next_field_offset, 0, size, index);
}

String& KernelReaderHelper::SourceTableUriFor(intptr_t index) {
  AlternativeReadingScope alt(&reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  intptr_t size = ReadUInt();  // read uri List<byte> size.
  return H.DartString(reader_.BufferAt(ReaderOffset()), size, Heap::kOld);
}

const String& KernelReaderHelper::GetSourceFor(intptr_t index) {
  AlternativeReadingScope alt(&reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());       // skip uri.
  intptr_t size = ReadUInt();  // read source List<byte> size.
  ASSERT(size >= 0);
  if (size == 0) {
    return Symbols::Empty();
  } else {
    return H.DartString(reader_.BufferAt(ReaderOffset()), size, Heap::kOld);
  }
}

TypedDataPtr KernelReaderHelper::GetLineStartsFor(intptr_t index) {
  // Line starts are delta encoded. So get the max delta first so that we
  // can store them as tighly as possible.
  AlternativeReadingScope alt(&reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());                         // skip uri.
  SkipBytes(ReadUInt());                         // skip source.
  const intptr_t line_start_count = ReadUInt();
  return reader_.ReadLineStartsData(line_start_count);
}

String& KernelReaderHelper::SourceTableImportUriFor(intptr_t index,
                                                    uint32_t binaryVersion) {
  if (binaryVersion < 22) {
    return SourceTableUriFor(index);
  }

  AlternativeReadingScope alt(&reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());                         // skip uri.
  SkipBytes(ReadUInt());                         // skip source.
  const intptr_t line_start_count = ReadUInt();  // read number of line start
                                                 // entries.
  for (intptr_t i = 0; i < line_start_count; ++i) {
    ReadUInt();
  }

  intptr_t size = ReadUInt();  // read import uri List<byte> size.
  return H.DartString(reader_.BufferAt(ReaderOffset()), size, Heap::kOld);
}

ExternalTypedDataPtr KernelReaderHelper::GetConstantCoverageFor(
    intptr_t index) {
  AlternativeReadingScope alt(&reader_);
  SetOffset(GetOffsetForSourceInfo(index));
  SkipBytes(ReadUInt());                         // skip uri.
  SkipBytes(ReadUInt());                         // skip source.
  const intptr_t line_start_count = ReadUInt();  // read number of line start
                                                 // entries.
  for (intptr_t i = 0; i < line_start_count; ++i) {
    ReadUInt();
  }

  SkipBytes(ReadUInt());  // skip import uri.

  intptr_t start_offset = ReaderOffset();

  // Read past "constant coverage constructors".
  const intptr_t constant_coverage_constructors = ReadUInt();
  for (intptr_t i = 0; i < constant_coverage_constructors; ++i) {
    ReadUInt();
  }

  intptr_t end_offset = ReaderOffset();

  return reader_.ExternalDataFromTo(start_offset, end_offset);
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
                               ConstantReader* constant_reader,
                               ActiveClass* active_class,
                               bool finalize,
                               bool apply_legacy_erasure)
    : helper_(helper),
      constant_reader_(constant_reader),
      translation_helper_(helper->translation_helper_),
      active_class_(active_class),
      type_parameter_scope_(NULL),
      inferred_type_metadata_helper_(helper_, constant_reader_),
      unboxing_info_metadata_helper_(helper_),
      zone_(translation_helper_.zone()),
      result_(AbstractType::Handle(translation_helper_.zone())),
      finalize_(finalize),
      apply_legacy_erasure_(apply_legacy_erasure) {}

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

void TypeTranslator::BuildTypeInternal() {
  Tag tag = helper_->ReadTag();
  switch (tag) {
    case kInvalidType:
    case kDynamicType:
      result_ = Object::dynamic_type().raw();
      break;
    case kVoidType:
      result_ = Object::void_type().raw();
      break;
    case kNeverType: {
      const Nullability nullability = helper_->ReadNullability();
      if (apply_legacy_erasure_) {
        result_ = I->object_store()->null_type();
      } else {
        result_ = Type::Handle(Z, I->object_store()->never_type())
                      .ToNullability(nullability, Heap::kOld);
      }
      break;
    }
    case kBottomType:
      // Map Bottom type to Null type until not emitted by CFE anymore.
      result_ = I->object_store()->null_type();
      ASSERT(result_.IsNullable());
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

  Nullability nullability = helper_->ReadNullability();
  if (apply_legacy_erasure_) {
    nullability = Nullability::kLegacy;
  }

  NameIndex klass_name =
      helper_->ReadCanonicalNameReference();  // read klass_name.

  const Class& klass = Class::Handle(Z, H.LookupClassByKernelClass(klass_name));
  ASSERT(!klass.IsNull());
  if (simple) {
    if (finalize_ || klass.is_type_finalized()) {
      // Fast path for non-generic types: retrieve or populate the class's only
      // canonical type (as long as only one nullability variant is used), which
      // is its declaration type.
      result_ = klass.DeclarationType();
      result_ = Type::Cast(result_).ToNullability(nullability, Heap::kOld);
    } else {
      // Note that the type argument vector is not yet extended.
      result_ = Type::New(klass, Object::null_type_arguments(),
                          klass.token_pos(), nullability);
    }
    return;
  }

  intptr_t length =
      helper_->ReadListLength();  // read type_arguments list length.
  const TypeArguments& type_arguments =
      BuildTypeArguments(length);  // read type arguments.
  result_ =
      Type::New(klass, type_arguments, TokenPosition::kNoSource, nullability);
  result_ = result_.NormalizeFutureOrType(Heap::kOld);
  if (finalize_) {
    ASSERT(active_class_->klass != NULL);
    result_ = ClassFinalizer::FinalizeType(result_);
  }
}

void TypeTranslator::BuildFunctionType(bool simple) {
  Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        active_class_->enclosing != NULL
                                            ? *active_class_->enclosing
                                            : Function::Handle(Z),
                                        TokenPosition::kNoSource));

  Nullability nullability = helper_->ReadNullability();
  if (apply_legacy_erasure_) {
    nullability = Nullability::kLegacy;
  }

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

  // The additional first parameter is the receiver type (set to dynamic).
  signature_function.set_num_fixed_parameters(1 + required_count);
  signature_function.SetNumOptionalParameters(
      all_count - required_count, positional_count > required_count);

  signature_function.set_parameter_types(
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld)));
  signature_function.CreateNameArrayIncludingFlags(Heap::kOld);

  intptr_t pos = 0;
  signature_function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
  signature_function.SetParameterNameAt(pos, H.DartSymbolPlain("_receiver_"));
  ++pos;
  for (intptr_t i = 0; i < positional_count; ++i, ++pos) {
    BuildTypeInternal();  // read ith positional parameter.
    signature_function.SetParameterTypeAt(pos, result_);
    signature_function.SetParameterNameAt(pos, H.DartSymbolPlain("noname"));
  }

  if (!simple) {
    const intptr_t named_count =
        helper_->ReadListLength();  // read named_parameters list length.
    for (intptr_t i = 0; i < named_count; ++i, ++pos) {
      // read string reference (i.e. named_parameters[i].name).
      String& name = H.DartSymbolObfuscate(helper_->ReadStringReference());
      BuildTypeInternal();  // read named_parameters[i].type.
      const uint8_t flags = helper_->ReadFlags();  // read flags
      signature_function.SetParameterTypeAt(pos, result_);
      signature_function.SetParameterNameAt(pos, name);
      if (!apply_legacy_erasure_ &&
          (flags & static_cast<uint8_t>(NamedTypeFlags::kIsRequired)) != 0) {
        signature_function.SetIsRequiredAt(pos);
      }
    }
  }
  signature_function.TruncateUnusedParameterFlags();

  if (!simple) {
    helper_->SkipOptionalDartType();  // read typedef type.
  }

  BuildTypeInternal();  // read return type.
  signature_function.set_result_type(result_);

  finalize_ = finalize;

  Type& signature_type =
      Type::ZoneHandle(Z, signature_function.SignatureType(nullability));

  if (finalize_) {
    signature_type ^= ClassFinalizer::FinalizeType(signature_type);
    // Do not refer to signature_function anymore, since it may have been
    // replaced during canonicalization.
    signature_function = Function::null();
  }

  result_ = signature_type.raw();
}

void TypeTranslator::BuildTypeParameterType() {
  Nullability nullability = helper_->ReadNullability();
  if (apply_legacy_erasure_) {
    nullability = Nullability::kLegacy;
  }

  intptr_t parameter_index = helper_->ReadUInt();  // read parameter index.
  helper_->SkipOptionalDartType();                 // read bound.

  const TypeArguments& class_types =
      TypeArguments::Handle(Z, active_class_->klass->type_parameters());
  if (parameter_index < class_types.Length()) {
    // The index of the type parameter in [parameters] is
    // the same index into the `klass->type_parameters()` array.
    const auto& type_param =
        TypeParameter::CheckedHandle(Z, class_types.TypeAt(parameter_index));
    result_ = type_param.ToNullability(nullability, Heap::kOld);
    active_class_->RecordDerivedTypeParameter(Z, type_param,
                                              TypeParameter::Cast(result_));
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
        const auto& type_param = TypeParameter::CheckedHandle(
            Z, class_types.TypeAt(parameter_index));
        result_ = type_param.ToNullability(nullability, Heap::kOld);
        active_class_->RecordDerivedTypeParameter(Z, type_param,
                                                  TypeParameter::Cast(result_));
        return;
      }
      parameter_index -= class_types.Length();
    }
    // Factory function should not be considered as procedure.
    intptr_t procedure_type_parameter_count =
        (active_class_->MemberIsProcedure() &&
         !active_class_->MemberIsFactoryProcedure())
            ? active_class_->MemberTypeParameterCount(Z)
            : 0;
    if (procedure_type_parameter_count > 0) {
      if (procedure_type_parameter_count > parameter_index) {
        const auto& type_param = TypeParameter::CheckedHandle(
            Z,
            TypeArguments::Handle(Z, active_class_->member->type_parameters())
                .TypeAt(parameter_index));
        result_ = type_param.ToNullability(nullability, Heap::kOld);
        active_class_->RecordDerivedTypeParameter(Z, type_param,
                                                  TypeParameter::Cast(result_));
        if (finalize_) {
          result_ = ClassFinalizer::FinalizeType(result_);
        }
        return;
      }
      parameter_index -= procedure_type_parameter_count;
    }
  }

  if (active_class_->local_type_parameters != NULL) {
    if (parameter_index < active_class_->local_type_parameters->Length()) {
      const auto& type_param = TypeParameter::CheckedHandle(
          Z, active_class_->local_type_parameters->TypeAt(parameter_index));
      result_ = type_param.ToNullability(nullability, Heap::kOld);
      active_class_->RecordDerivedTypeParameter(Z, type_param,
                                                TypeParameter::Cast(result_));
      if (finalize_) {
        result_ = ClassFinalizer::FinalizeType(result_);
      }
      return;
    }
    parameter_index -= active_class_->local_type_parameters->Length();
  }

  if (type_parameter_scope_ != NULL &&
      parameter_index < type_parameter_scope_->outer_parameter_count() +
                            type_parameter_scope_->parameter_count()) {
    result_ = Type::DynamicType();
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
      BuildTypeInternal();  // read ith type.
      type_arguments.SetTypeAt(i, result_);
    }

    if (finalize_) {
      type_arguments = type_arguments.Canonicalize(Thread::Current(), nullptr);
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
    type ^= ClassFinalizer::FinalizeType(type);
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

  const NNBDMode nnbd_mode = set_on.IsClass()
                                 ? Class::Cast(set_on).nnbd_mode()
                                 : Function::Cast(set_on).nnbd_mode();
  const Nullability nullability = (nnbd_mode == NNBDMode::kOptedInLib)
                                      ? Nullability::kNonNullable
                                      : Nullability::kLegacy;

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
          null_bound, helper.IsGenericCovariantImpl(), nullability,
          TokenPosition::kNoSource);
      parameter.SetCanonical();
      parameter.SetDeclaration(true);
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

  // Step b) Fill in the bounds and default arguments of all [TypeParameter]s.
  for (intptr_t i = 0; i < type_parameter_count; i++) {
    TypeParameterHelper helper(helper_);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kBound);

    parameter ^= type_parameters.TypeAt(i);
    AbstractType& bound = BuildTypeWithoutFinalization();  // read ith bound.
    parameter.set_bound(bound);
    helper.ReadUntilExcludingAndSetJustRead(TypeParameterHelper::kDefaultType);
    const AbstractType* default_arg = &Object::dynamic_type();
    if (helper_->ReadTag() == kSomething) {
      default_arg = &BuildTypeWithoutFinalization();
    }
    parameter.set_default_argument(*default_arg);
    helper.Finish();
  }

  if (set_on.IsFunction()) {
    Function::Cast(set_on).UpdateCachedDefaultTypeArguments(Thread::Current());
  }

  // Fix bounds and default arguments in all derived type parameters (with
  // different nullabilities).
  if (active_class->derived_type_parameters != nullptr) {
    auto& derived = TypeParameter::Handle(Z);
    auto& type = AbstractType::Handle(Z);
    for (intptr_t i = 0, n = active_class->derived_type_parameters->Length();
         i < n; ++i) {
      derived ^= active_class->derived_type_parameters->At(i);
      if (derived.bound() == AbstractType::null() &&
          (derived.parameterized_class() == set_on.raw() ||
           derived.parameterized_function() == set_on.raw())) {
        ASSERT(!derived.IsFinalized());
        parameter ^= type_parameters.TypeAt(derived.index());
        type = parameter.bound();
        derived.set_bound(type);
        type = parameter.default_argument();
        derived.set_default_argument(type);
      }
    }
  }
}

const Type& TypeTranslator::ReceiverType(const Class& klass) {
  ASSERT(!klass.IsNull());
  ASSERT(!klass.IsTypedefClass());
  // Note that if klass is _Closure, the returned type will be _Closure,
  // and not the signature type.
  Type& type = Type::ZoneHandle(Z);
  if (finalize_ || klass.is_type_finalized()) {
    type = klass.DeclarationType();
  } else {
    type = Type::New(klass, TypeArguments::Handle(Z, klass.type_parameters()),
                     klass.token_pos(), Nullability::kNonNullable);
  }
  return type;
}

static void SetupUnboxingInfoOfParameter(const Function& function,
                                         intptr_t param_index,
                                         const UnboxingInfoMetadata* metadata) {
  const intptr_t param_pos =
      param_index + (function.HasThisParameter() ? 1 : 0);

  if (param_pos < function.maximum_unboxed_parameter_count()) {
    switch (metadata->unboxed_args_info[param_index]) {
      case UnboxingInfoMetadata::kUnboxedIntCandidate:
        if (FlowGraphCompiler::SupportsUnboxedInt64()) {
          function.set_unboxed_integer_parameter_at(param_pos);
        }
        break;
      case UnboxingInfoMetadata::kUnboxedDoubleCandidate:
        if (FlowGraphCompiler::SupportsUnboxedDoubles()) {
          function.set_unboxed_double_parameter_at(param_pos);
        }
        break;
      case UnboxingInfoMetadata::kUnboxingCandidate:
        UNREACHABLE();
        break;
      case UnboxingInfoMetadata::kBoxed:
        break;
      default:
        UNREACHABLE();
        break;
    }
  }
}

static void SetupUnboxingInfoOfReturnValue(
    const Function& function,
    const UnboxingInfoMetadata* metadata) {
  switch (metadata->return_info) {
    case UnboxingInfoMetadata::kUnboxedIntCandidate:
      if (FlowGraphCompiler::SupportsUnboxedInt64()) {
        function.set_unboxed_integer_return();
      }
      break;
    case UnboxingInfoMetadata::kUnboxedDoubleCandidate:
      if (FlowGraphCompiler::SupportsUnboxedDoubles()) {
        function.set_unboxed_double_return();
      }
      break;
    case UnboxingInfoMetadata::kUnboxingCandidate:
      UNREACHABLE();
      break;
    case UnboxingInfoMetadata::kBoxed:
      break;
    default:
      UNREACHABLE();
      break;
  }
}

void TypeTranslator::SetupUnboxingInfoMetadata(const Function& function,
                                               intptr_t library_kernel_offset) {
  const intptr_t kernel_offset =
      function.kernel_offset() + library_kernel_offset;
  const auto unboxing_info =
      unboxing_info_metadata_helper_.GetUnboxingInfoMetadata(kernel_offset);

  // TODO(dartbug.com/32292): accept unboxed parameters and return value
  // when FLAG_use_table_dispatch == false.
  if (FLAG_precompiled_mode && unboxing_info != nullptr &&
      FLAG_use_table_dispatch && FLAG_use_bare_instructions) {
    for (intptr_t i = 0; i < unboxing_info->unboxed_args_info.length(); i++) {
      SetupUnboxingInfoOfParameter(function, i, unboxing_info);
    }
    SetupUnboxingInfoOfReturnValue(function, unboxing_info);
  }
}

void TypeTranslator::SetupUnboxingInfoMetadataForFieldAccessors(
    const Function& field_accessor,
    intptr_t library_kernel_offset) {
  const intptr_t kernel_offset =
      field_accessor.kernel_offset() + library_kernel_offset;
  const auto unboxing_info =
      unboxing_info_metadata_helper_.GetUnboxingInfoMetadata(kernel_offset);

  // TODO(dartbug.com/32292): accept unboxed parameters and return value
  // when FLAG_use_table_dispatch == false.
  if (FLAG_precompiled_mode && unboxing_info != nullptr &&
      FLAG_use_table_dispatch && FLAG_use_bare_instructions) {
    if (field_accessor.IsImplicitSetterFunction()) {
      for (intptr_t i = 0; i < unboxing_info->unboxed_args_info.length(); i++) {
        SetupUnboxingInfoOfParameter(field_accessor, i, unboxing_info);
      }
    } else {
      ASSERT(field_accessor.IsImplicitGetterFunction() ||
             field_accessor.IsImplicitStaticGetterFunction());
      SetupUnboxingInfoOfReturnValue(field_accessor, unboxing_info);
    }
  }
}

void TypeTranslator::SetupFunctionParameters(
    const Class& klass,
    const Function& function,
    bool is_method,
    bool is_closure,
    FunctionNodeHelper* function_node_helper) {
  ASSERT(!(is_method && is_closure));
  bool is_factory = function.IsFactory();
  intptr_t extra_parameters = (is_method || is_closure || is_factory) ? 1 : 0;

  if (!is_factory) {
    LoadAndSetupTypeParameters(active_class_, function,
                               helper_->ReadListLength(), function);
    function_node_helper->SetJustRead(FunctionNodeHelper::kTypeParameters);
  }

  ActiveTypeParametersScope scope(active_class_, function, Z);

  function_node_helper->ReadUntilExcluding(
      FunctionNodeHelper::kPositionalParameters);

  intptr_t required_parameter_count =
      function_node_helper->required_parameter_count_;
  intptr_t total_parameter_count = function_node_helper->total_parameter_count_;

  intptr_t positional_parameter_count =
      helper_->ReadListLength();  // read list length.

  intptr_t named_parameter_count =
      total_parameter_count - positional_parameter_count;

  function.set_num_fixed_parameters(extra_parameters +
                                    required_parameter_count);
  if (named_parameter_count > 0) {
    function.SetNumOptionalParameters(named_parameter_count, false);
  } else {
    function.SetNumOptionalParameters(
        positional_parameter_count - required_parameter_count, true);
  }
  intptr_t parameter_count = extra_parameters + total_parameter_count;

  function.set_parameter_types(
      Array::Handle(Z, Array::New(parameter_count, Heap::kOld)));
  function.CreateNameArrayIncludingFlags(Heap::kOld);
  intptr_t pos = 0;
  if (is_method) {
    ASSERT(!klass.IsNull());
    function.SetParameterTypeAt(pos, H.GetDeclarationType(klass));
    function.SetParameterNameAt(pos, Symbols::This());
    pos++;
  } else if (is_closure) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::ClosureParameter());
    pos++;
  } else if (is_factory) {
    function.SetParameterTypeAt(pos, AbstractType::dynamic_type());
    function.SetParameterNameAt(pos, Symbols::TypeArgumentsParameter());
    pos++;
  }

  const Library& lib = Library::Handle(Z, active_class_->klass->library());
  for (intptr_t i = 0; i < positional_parameter_count; ++i, ++pos) {
    // Read ith variable declaration.
    VariableDeclarationHelper helper(helper_);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    // The required flag should only be set on named parameters.
    ASSERT(!helper.IsRequired());
    const AbstractType& type = BuildTypeWithoutFinalization();  // read type.
    Tag tag = helper_->ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      helper_->SkipExpression();  // read (actual) initializer.
    }

    function.SetParameterTypeAt(pos, type);
    function.SetParameterNameAt(pos, H.DartIdentifier(lib, helper.name_index_));
  }

  intptr_t named_parameter_count_check =
      helper_->ReadListLength();  // read list length.
  ASSERT(named_parameter_count_check == named_parameter_count);
  for (intptr_t i = 0; i < named_parameter_count; ++i, ++pos) {
    // Read ith variable declaration.
    VariableDeclarationHelper helper(helper_);
    helper.ReadUntilExcluding(VariableDeclarationHelper::kType);
    const AbstractType& type = BuildTypeWithoutFinalization();  // read type.
    Tag tag = helper_->ReadTag();  // read (first part of) initializer.
    if (tag == kSomething) {
      helper_->SkipExpression();  // read (actual) initializer.
    }

    function.SetParameterTypeAt(pos, type);
    function.SetParameterNameAt(pos, H.DartIdentifier(lib, helper.name_index_));
    if (helper.IsRequired()) {
      function.SetIsRequiredAt(pos);
    }
  }
  function.TruncateUnusedParameterFlags();

  function_node_helper->SetJustRead(FunctionNodeHelper::kNamedParameters);

  // The result type for generative constructors has already been set.
  if (!function.IsGenerativeConstructor()) {
    const AbstractType& return_type =
        BuildTypeWithoutFinalization();  // read return type.
    function.set_result_type(return_type);
    function_node_helper->SetJustRead(FunctionNodeHelper::kReturnType);
  }
}

}  // namespace kernel
}  // namespace dart
