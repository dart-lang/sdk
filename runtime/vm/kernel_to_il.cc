// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <set>

#include "vm/kernel_to_il.h"

#include "vm/compiler.h"
#include "vm/intermediate_language.h"
#include "vm/kernel_reader.h"
#include "vm/kernel_binary_flowgraph.h"
#include "vm/longjump.h"
#include "vm/method_recognizer.h"
#include "vm/object_store.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
namespace dart {

DECLARE_FLAG(bool, support_externalizable_strings);

namespace kernel {

#define Z (zone_)
#define H (translation_helper_)
#define T (type_translator_)
#define I Isolate::Current()


Fragment& Fragment::operator+=(const Fragment& other) {
  if (entry == NULL) {
    entry = other.entry;
    current = other.current;
  } else if (current != NULL && other.entry != NULL) {
    current->LinkTo(other.entry);
    current = other.current;
  }
  return *this;
}


Fragment& Fragment::operator<<=(Instruction* next) {
  if (entry == NULL) {
    entry = current = next;
  } else if (current != NULL) {
    current->LinkTo(next);
    current = next;
  }
  return *this;
}


Fragment Fragment::closed() {
  ASSERT(entry != NULL);
  return Fragment(entry, NULL);
}


Fragment operator+(const Fragment& first, const Fragment& second) {
  Fragment result = first;
  result += second;
  return result;
}


Fragment operator<<(const Fragment& fragment, Instruction* next) {
  Fragment result = fragment;
  result <<= next;
  return result;
}


TranslationHelper::TranslationHelper(Thread* thread)
    : thread_(thread),
      zone_(thread->zone()),
      isolate_(thread->isolate()),
      allocation_space_(thread->IsMutatorThread() ? Heap::kNew : Heap::kOld),
      string_offsets_(TypedData::Handle(Z)),
      string_data_(TypedData::Handle(Z)),
      canonical_names_(TypedData::Handle(Z)) {}


void TranslationHelper::SetStringOffsets(const TypedData& string_offsets) {
  ASSERT(string_offsets_.IsNull());
  string_offsets_ = string_offsets.raw();
}


void TranslationHelper::SetStringData(const TypedData& string_data) {
  ASSERT(string_data_.IsNull());
  string_data_ = string_data.raw();
}


void TranslationHelper::SetCanonicalNames(const TypedData& canonical_names) {
  ASSERT(canonical_names_.IsNull());
  canonical_names_ = canonical_names.raw();
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


bool TranslationHelper::StringEquals(StringIndex string_index,
                                     const char* other) {
  NoSafepointScope no_safepoint;
  intptr_t length = strlen(other);
  return (length == StringSize(string_index)) &&
         (memcmp(string_data_.DataAddr(StringOffset(string_index)), other,
                 length) == 0);
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


const dart::String& TranslationHelper::DartString(const char* content,
                                                  Heap::Space space) {
  return dart::String::ZoneHandle(Z, dart::String::New(content, space));
}


dart::String& TranslationHelper::DartString(StringIndex string_index,
                                            Heap::Space space) {
  intptr_t length = StringSize(string_index);
  uint8_t* buffer = Z->Alloc<uint8_t>(length);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, string_data_.DataAddr(StringOffset(string_index)), length);
  }
  return dart::String::ZoneHandle(
      Z, dart::String::FromUTF8(buffer, length, space));
}


dart::String& TranslationHelper::DartString(const uint8_t* utf8_array,
                                            intptr_t len,
                                            Heap::Space space) {
  return dart::String::ZoneHandle(
      Z, dart::String::FromUTF8(utf8_array, len, space));
}


const dart::String& TranslationHelper::DartSymbol(const char* content) const {
  return dart::String::ZoneHandle(Z, Symbols::New(thread_, content));
}


dart::String& TranslationHelper::DartSymbol(StringIndex string_index) const {
  intptr_t length = StringSize(string_index);
  uint8_t* buffer = Z->Alloc<uint8_t>(length);
  {
    NoSafepointScope no_safepoint;
    memmove(buffer, string_data_.DataAddr(StringOffset(string_index)), length);
  }
  return dart::String::ZoneHandle(Z,
                                  Symbols::FromUTF8(thread_, buffer, length));
}

dart::String& TranslationHelper::DartSymbol(const uint8_t* utf8_array,
                                            intptr_t len) const {
  return dart::String::ZoneHandle(Z,
                                  Symbols::FromUTF8(thread_, utf8_array, len));
}

const dart::String& TranslationHelper::DartClassName(NameIndex kernel_class) {
  ASSERT(IsClass(kernel_class));
  dart::String& name = DartString(CanonicalNameString(kernel_class));
  return ManglePrivateName(CanonicalNameParent(kernel_class), &name);
}


const dart::String& TranslationHelper::DartConstructorName(
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  return DartFactoryName(constructor);
}


const dart::String& TranslationHelper::DartProcedureName(NameIndex procedure) {
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


const dart::String& TranslationHelper::DartSetterName(NameIndex setter) {
  return DartSetterName(CanonicalNameParent(setter),
                        CanonicalNameString(setter));
}


const dart::String& TranslationHelper::DartSetterName(NameIndex parent,
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
    memmove(buffer, string_data_.DataAddr(StringOffset(setter)), size);
  }
  dart::String& name = dart::String::ZoneHandle(
      Z, dart::String::FromUTF8(buffer, size, allocation_space_));
  ManglePrivateName(parent, &name, false);
  name = dart::Field::SetterSymbol(name);
  return name;
}


const dart::String& TranslationHelper::DartGetterName(NameIndex getter) {
  return DartGetterName(CanonicalNameParent(getter),
                        CanonicalNameString(getter));
}


const dart::String& TranslationHelper::DartGetterName(NameIndex parent,
                                                      StringIndex getter) {
  dart::String& name = DartString(getter);
  ManglePrivateName(parent, &name, false);
  name = dart::Field::GetterSymbol(name);
  return name;
}


const dart::String& TranslationHelper::DartFieldName(NameIndex parent,
                                                     StringIndex field) {
  dart::String& name = DartString(field);
  return ManglePrivateName(parent, &name);
}


const dart::String& TranslationHelper::DartMethodName(NameIndex method) {
  return DartMethodName(CanonicalNameParent(method),
                        CanonicalNameString(method));
}


const dart::String& TranslationHelper::DartMethodName(NameIndex parent,
                                                      StringIndex method) {
  dart::String& name = DartString(method);
  return ManglePrivateName(parent, &name);
}


const dart::String& TranslationHelper::DartFactoryName(NameIndex factory) {
  ASSERT(IsConstructor(factory) || IsFactory(factory));
  GrowableHandlePtrArray<const dart::String> pieces(Z, 3);
  pieces.Add(DartClassName(EnclosingName(factory)));
  pieces.Add(Symbols::Dot());
  // [DartMethodName] will mangle the name.
  pieces.Add(DartMethodName(factory));
  return dart::String::ZoneHandle(Z, Symbols::FromConcatAll(thread_, pieces));
}


RawLibrary* TranslationHelper::LookupLibraryByKernelLibrary(
    NameIndex kernel_library) {
  // We only use the string and don't rely on having any particular parent.
  // This ASSERT is just a sanity check.
  ASSERT(IsLibrary(kernel_library) ||
         IsAdministrative(CanonicalNameParent(kernel_library)));
  const dart::String& library_name =
      DartSymbol(CanonicalNameString(kernel_library));
  ASSERT(!library_name.IsNull());
  RawLibrary* library = dart::Library::LookupLibrary(thread_, library_name);
  ASSERT(library != Object::null());
  return library;
}


RawClass* TranslationHelper::LookupClassByKernelClass(NameIndex kernel_class) {
  ASSERT(IsClass(kernel_class));
  const dart::String& class_name = DartClassName(kernel_class);
  NameIndex kernel_library = CanonicalNameParent(kernel_class);
  dart::Library& library =
      dart::Library::Handle(Z, LookupLibraryByKernelLibrary(kernel_library));
  RawClass* klass = library.LookupClassAllowPrivate(class_name);

  ASSERT(klass != Object::null());
  return klass;
}


RawField* TranslationHelper::LookupFieldByKernelField(NameIndex kernel_field) {
  ASSERT(IsField(kernel_field));
  NameIndex enclosing = EnclosingName(kernel_field);

  dart::Class& klass = dart::Class::Handle(Z);
  if (IsLibrary(enclosing)) {
    dart::Library& library =
        dart::Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    klass = library.toplevel_class();
  } else {
    ASSERT(IsClass(enclosing));
    klass = LookupClassByKernelClass(enclosing);
  }
  RawField* field = klass.LookupFieldAllowPrivate(
      DartSymbol(CanonicalNameString(kernel_field)));
  ASSERT(field != Object::null());
  return field;
}


RawFunction* TranslationHelper::LookupStaticMethodByKernelProcedure(
    NameIndex procedure) {
  const dart::String& procedure_name = DartProcedureName(procedure);

  // The parent is either a library or a class (in which case the procedure is a
  // static method).
  NameIndex enclosing = EnclosingName(procedure);
  if (IsLibrary(enclosing)) {
    dart::Library& library =
        dart::Library::Handle(Z, LookupLibraryByKernelLibrary(enclosing));
    RawFunction* function = library.LookupFunctionAllowPrivate(procedure_name);
    ASSERT(function != Object::null());
    return function;
  } else {
    ASSERT(IsClass(enclosing));
    dart::Class& klass =
        dart::Class::Handle(Z, LookupClassByKernelClass(enclosing));
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
  dart::Class& klass = dart::Class::Handle(
      Z, LookupClassByKernelClass(EnclosingName(constructor)));
  return LookupConstructorByKernelConstructor(klass, constructor);
}


RawFunction* TranslationHelper::LookupConstructorByKernelConstructor(
    const dart::Class& owner,
    NameIndex constructor) {
  ASSERT(IsConstructor(constructor));
  RawFunction* function =
      owner.LookupConstructorAllowPrivate(DartConstructorName(constructor));
  ASSERT(function != Object::null());
  return function;
}


dart::Type& TranslationHelper::GetCanonicalType(const dart::Class& klass) {
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


dart::String& TranslationHelper::ManglePrivateName(NameIndex parent,
                                                   dart::String* name_to_modify,
                                                   bool symbolize) {
  if (name_to_modify->Length() >= 1 && name_to_modify->CharAt(0) == '_') {
    const dart::Library& library =
        dart::Library::Handle(Z, LookupLibraryByKernelLibrary(parent));
    *name_to_modify = library.PrivateName(*name_to_modify);
  } else if (symbolize) {
    *name_to_modify = Symbols::New(thread_, *name_to_modify);
  }
  return *name_to_modify;
}


FlowGraphBuilder::FlowGraphBuilder(
    intptr_t kernel_offset,
    ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    ZoneGrowableArray<intptr_t>* context_level_array,
    InlineExitCollector* exit_collector,
    intptr_t osr_id,
    intptr_t first_block_id)
    : translation_helper_(Thread::Current()),
      thread_(translation_helper_.thread()),
      zone_(translation_helper_.zone()),
      kernel_offset_(kernel_offset),
      parsed_function_(parsed_function),
      osr_id_(osr_id),
      ic_data_array_(ic_data_array),
      context_level_array_(context_level_array),
      exit_collector_(exit_collector),
      next_block_id_(first_block_id),
      next_function_id_(0),
      context_depth_(0),
      loop_depth_(0),
      try_depth_(0),
      catch_depth_(0),
      for_in_depth_(0),
      stack_(NULL),
      pending_argument_count_(0),
      graph_entry_(NULL),
      scopes_(NULL),
      breakable_block_(NULL),
      switch_block_(NULL),
      try_finally_block_(NULL),
      try_catch_block_(NULL),
      next_used_try_index_(0),
      catch_block_(NULL),
      streaming_flow_graph_builder_(NULL) {
  Script& script = Script::Handle(Z, parsed_function->function().script());
  H.SetStringOffsets(TypedData::Handle(Z, script.kernel_string_offsets()));
  H.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
  H.SetCanonicalNames(TypedData::Handle(Z, script.kernel_canonical_names()));
}


FlowGraphBuilder::~FlowGraphBuilder() {
  if (streaming_flow_graph_builder_ != NULL) {
    delete streaming_flow_graph_builder_;
  }
}


Fragment FlowGraphBuilder::TranslateFinallyFinalizers(
    TryFinallyBlock* outer_finally,
    intptr_t target_context_depth) {
  TryFinallyBlock* const saved_block = try_finally_block_;
  TryCatchBlock* const saved_try_catch_block = try_catch_block_;
  const intptr_t saved_depth = context_depth_;
  const intptr_t saved_try_depth = try_depth_;

  Fragment instructions;

  // While translating the body of a finalizer we need to set the try-finally
  // block which is active when translating the body.
  while (try_finally_block_ != outer_finally) {
    // Set correct try depth (in case there are nested try statements).
    try_depth_ = try_finally_block_->try_depth();

    // Potentially restore the context to what is expected for the finally
    // block.
    instructions += AdjustContextTo(try_finally_block_->context_depth());

    // The to-be-translated finalizer has to have the correct try-index (namely
    // the one outside the try-finally block).
    bool changed_try_index = false;
    intptr_t target_try_index = try_finally_block_->try_index();
    while (CurrentTryIndex() != target_try_index) {
      try_catch_block_ = try_catch_block_->outer();
      changed_try_index = true;
    }
    if (changed_try_index) {
      JoinEntryInstr* entry = BuildJoinEntry();
      instructions += Goto(entry);
      instructions = Fragment(instructions.entry, entry);
    }

    intptr_t finalizer_kernel_offset =
        try_finally_block_->finalizer_kernel_offset();
    try_finally_block_ = try_finally_block_->outer();
    instructions += streaming_flow_graph_builder_->BuildStatementAt(
        finalizer_kernel_offset);

    // We only need to make sure that if the finalizer ended normally, we
    // continue towards the next outer try-finally.
    if (!instructions.is_open()) break;
  }

  if (instructions.is_open() && target_context_depth != -1) {
    // A target context depth of -1 indicates that the code after this
    // will not care about the context chain so we can leave it any way we
    // want after the last finalizer.  That is used when returning.
    instructions += AdjustContextTo(target_context_depth);
  }

  try_finally_block_ = saved_block;
  try_catch_block_ = saved_try_catch_block;
  context_depth_ = saved_depth;
  try_depth_ = saved_try_depth;

  return instructions;
}


Fragment FlowGraphBuilder::EnterScope(intptr_t kernel_offset,
                                      bool* new_context) {
  Fragment instructions;
  const intptr_t context_size =
      scopes_->scopes.Lookup(kernel_offset)->num_context_variables();
  if (context_size > 0) {
    instructions += PushContext(context_size);
    instructions += Drop();
    if (new_context != NULL) {
      *new_context = true;
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::ExitScope(intptr_t kernel_offset) {
  Fragment instructions;
  const intptr_t context_size =
      scopes_->scopes.Lookup(kernel_offset)->num_context_variables();
  if (context_size > 0) {
    instructions += PopContext();
  }
  return instructions;
}


Fragment FlowGraphBuilder::LoadContextAt(int depth) {
  intptr_t delta = context_depth_ - depth;
  ASSERT(delta >= 0);
  Fragment instructions = LoadLocal(parsed_function_->current_context_var());
  while (delta-- > 0) {
    instructions += LoadField(Context::parent_offset());
  }
  return instructions;
}


Fragment FlowGraphBuilder::AdjustContextTo(int depth) {
  ASSERT(depth <= context_depth_ && depth >= 0);
  Fragment instructions;
  if (depth < context_depth_) {
    instructions += LoadContextAt(depth);
    instructions += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->current_context_var());
    instructions += Drop();
    context_depth_ = depth;
  }
  return instructions;
}


Fragment FlowGraphBuilder::PushContext(int size) {
  ASSERT(size > 0);
  Fragment instructions = AllocateContext(size);
  LocalVariable* context = MakeTemporary();
  instructions += LoadLocal(context);
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Context::parent_offset());
  instructions += StoreLocal(TokenPosition::kNoSource,
                             parsed_function_->current_context_var());
  ++context_depth_;
  return instructions;
}


Fragment FlowGraphBuilder::PopContext() {
  return AdjustContextTo(context_depth_ - 1);
}


Fragment FlowGraphBuilder::LoadInstantiatorTypeArguments() {
  // TODO(27590): We could use `active_class_->IsGeneric()`.
  Fragment instructions;
  if (scopes_->type_arguments_variable != NULL) {
#ifdef DEBUG
    Function& function =
        Function::Handle(Z, parsed_function_->function().raw());
    while (function.IsClosureFunction()) {
      function = function.parent_function();
    }
    ASSERT(function.IsFactory());
#endif
    instructions += LoadLocal(scopes_->type_arguments_variable);
  } else if (scopes_->this_variable != NULL &&
             active_class_.class_type_parameters > 0) {
    ASSERT(!parsed_function_->function().IsFactory());
    intptr_t type_arguments_field_offset =
        active_class_.klass->type_arguments_field_offset();
    ASSERT(type_arguments_field_offset != dart::Class::kNoTypeArguments);

    instructions += LoadLocal(scopes_->this_variable);
    instructions += LoadField(type_arguments_field_offset);
  } else {
    instructions += NullConstant();
  }
  return instructions;
}


Fragment FlowGraphBuilder::LoadFunctionTypeArguments() {
  UNIMPLEMENTED();  // TODO(regis)
  return Fragment(NULL);
}


Fragment FlowGraphBuilder::InstantiateType(const AbstractType& type) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  InstantiateTypeInstr* instr = new (Z) InstantiateTypeInstr(
      TokenPosition::kNoSource, type, instantiator_type_args,
      function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}


Fragment FlowGraphBuilder::InstantiateTypeArguments(
    const TypeArguments& type_arguments) {
  Value* function_type_args = Pop();
  Value* instantiator_type_args = Pop();
  InstantiateTypeArgumentsInstr* instr = new (Z) InstantiateTypeArgumentsInstr(
      TokenPosition::kNoSource, type_arguments, *active_class_.klass,
      instantiator_type_args, function_type_args, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}


Fragment FlowGraphBuilder::TranslateInstantiatedTypeArguments(
    const TypeArguments& type_arguments) {
  Fragment instructions;

  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    // There are no type references to type parameters so we can just take it.
    instructions += Constant(type_arguments);
  } else {
    // The [type_arguments] vector contains a type reference to a type
    // parameter we need to resolve it.
    const bool use_instantiator =
        type_arguments.IsUninstantiatedIdentity() ||
        type_arguments.CanShareInstantiatorTypeArguments(*active_class_.klass);
    if (use_instantiator) {
      // If the instantiator type arguments are just passed on, we don't need to
      // resolve the type parameters.
      //
      // This is for example the case here:
      //     class Foo<T> {
      //       newList() => new List<T>();
      //     }
      // We just use the type argument vector from the [Foo] object and pass it
      // directly to the `new List<T>()` factory constructor.
      instructions += LoadInstantiatorTypeArguments();
    } else {
      // Otherwise we need to resolve [TypeParameterType]s in the type
      // expression based on the current instantiator type argument vector.
      if (!type_arguments.IsInstantiated(kCurrentClass)) {
        instructions += LoadInstantiatorTypeArguments();
      } else {
        instructions += NullConstant();
      }
      if (!type_arguments.IsInstantiated(kFunctions)) {
        instructions += LoadFunctionTypeArguments();
      } else {
        instructions += NullConstant();
      }
      instructions += InstantiateTypeArguments(type_arguments);
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::AllocateContext(int size) {
  AllocateContextInstr* allocate =
      new (Z) AllocateContextInstr(TokenPosition::kNoSource, size);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::AllocateObject(TokenPosition position,
                                          const dart::Class& klass,
                                          intptr_t argument_count) {
  ArgumentArray arguments = GetArguments(argument_count);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(position, klass, arguments);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::AllocateObject(const dart::Class& klass,
                                          const Function& closure_function) {
  ArgumentArray arguments = new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, 0);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(TokenPosition::kNoSource, klass, arguments);
  allocate->set_closure_function(closure_function);
  Push(allocate);
  return Fragment(allocate);
}


Fragment FlowGraphBuilder::BooleanNegate() {
  BooleanNegateInstr* negate = new (Z) BooleanNegateInstr(Pop());
  Push(negate);
  return Fragment(negate);
}


Fragment FlowGraphBuilder::StrictCompare(Token::Kind kind,
                                         bool number_check /* = false */) {
  Value* right = Pop();
  Value* left = Pop();
  StrictCompareInstr* compare =
      new (Z) StrictCompareInstr(TokenPosition::kNoSource, kind, left, right,
                                 number_check, GetNextDeoptId());
  Push(compare);
  return Fragment(compare);
}


Fragment FlowGraphBuilder::BranchIfTrue(TargetEntryInstr** then_entry,
                                        TargetEntryInstr** otherwise_entry,
                                        bool negate) {
  Fragment instructions = Constant(Bool::True());
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}


Fragment FlowGraphBuilder::BranchIfNull(TargetEntryInstr** then_entry,
                                        TargetEntryInstr** otherwise_entry,
                                        bool negate) {
  Fragment instructions = NullConstant();
  return instructions + BranchIfEqual(then_entry, otherwise_entry, negate);
}

Fragment FlowGraphBuilder::BranchIfEqual(TargetEntryInstr** then_entry,
                                         TargetEntryInstr** otherwise_entry,
                                         bool negate) {
  Value* right_value = Pop();
  Value* left_value = Pop();
  StrictCompareInstr* compare = new (Z) StrictCompareInstr(
      TokenPosition::kNoSource, negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
      left_value, right_value, false, GetNextDeoptId());
  BranchInstr* branch = new (Z) BranchInstr(compare, GetNextDeoptId());
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}


Fragment FlowGraphBuilder::BranchIfStrictEqual(
    TargetEntryInstr** then_entry,
    TargetEntryInstr** otherwise_entry) {
  Value* rhs = Pop();
  Value* lhs = Pop();
  StrictCompareInstr* compare =
      new (Z) StrictCompareInstr(TokenPosition::kNoSource, Token::kEQ_STRICT,
                                 lhs, rhs, false, GetNextDeoptId());
  BranchInstr* branch = new (Z) BranchInstr(compare, GetNextDeoptId());
  *then_entry = *branch->true_successor_address() = BuildTargetEntry();
  *otherwise_entry = *branch->false_successor_address() = BuildTargetEntry();
  return Fragment(branch).closed();
}


Fragment FlowGraphBuilder::CatchBlockEntry(const Array& handler_types,
                                           intptr_t handler_index,
                                           bool needs_stacktrace) {
  ASSERT(CurrentException()->is_captured() ==
         CurrentStackTrace()->is_captured());
  const bool should_restore_closure_context =
      CurrentException()->is_captured() || CurrentCatchContext()->is_captured();
  CatchBlockEntryInstr* entry = new (Z) CatchBlockEntryInstr(
      TokenPosition::kNoSource,  // Token position of catch block.
      false,                     // Not an artifact of compilation.
      AllocateBlockId(), CurrentTryIndex(), graph_entry_, handler_types,
      handler_index, *CurrentException(), *CurrentStackTrace(),
      needs_stacktrace, GetNextDeoptId(), should_restore_closure_context);
  graph_entry_->AddCatchEntry(entry);
  Fragment instructions(entry);

  // :saved_try_context_var can be captured in the context of
  // of the closure, in this case CatchBlockEntryInstr restores
  // :current_context_var to point to closure context in the
  // same way as normal function prologue does.
  // Update current context depth to reflect that.
  const intptr_t saved_context_depth = context_depth_;
  ASSERT(!CurrentCatchContext()->is_captured() ||
         CurrentCatchContext()->owner()->context_level() == 0);
  context_depth_ = 0;
  instructions += LoadLocal(CurrentCatchContext());
  instructions += StoreLocal(TokenPosition::kNoSource,
                             parsed_function_->current_context_var());
  instructions += Drop();
  context_depth_ = saved_context_depth;

  return instructions;
}


Fragment FlowGraphBuilder::TryCatch(int try_handler_index) {
  // The body of the try needs to have it's own block in order to get a new try
  // index.
  //
  // => We therefore create a block for the body (fresh try index) and another
  //    join block (with current try index).
  Fragment body;
  JoinEntryInstr* entry = new (Z)
      JoinEntryInstr(AllocateBlockId(), try_handler_index, GetNextDeoptId());
  body += LoadLocal(parsed_function_->current_context_var());
  body += StoreLocal(TokenPosition::kNoSource, CurrentCatchContext());
  body += Drop();
  body += Goto(entry);
  return Fragment(body.entry, entry);
}


Fragment FlowGraphBuilder::CheckStackOverflowInPrologue() {
  if (IsInlining()) {
    // If we are inlining don't actually attach the stack check.  We must still
    // create the stack check in order to allocate a deopt id.
    CheckStackOverflow();
    return Fragment();
  }
  return CheckStackOverflow();
}


Fragment FlowGraphBuilder::CheckStackOverflow() {
  return Fragment(new (Z) CheckStackOverflowInstr(
      TokenPosition::kNoSource, loop_depth_, GetNextDeoptId()));
}


Fragment FlowGraphBuilder::CloneContext() {
  LocalVariable* context_variable = parsed_function_->current_context_var();

  Fragment instructions = LoadLocal(context_variable);

  CloneContextInstr* clone_instruction = new (Z)
      CloneContextInstr(TokenPosition::kNoSource, Pop(), GetNextDeoptId());
  instructions <<= clone_instruction;
  Push(clone_instruction);

  instructions += StoreLocal(TokenPosition::kNoSource, context_variable);
  instructions += Drop();
  return instructions;
}


Fragment FlowGraphBuilder::Constant(const Object& value) {
  ASSERT(value.IsNotTemporaryScopedHandle());
  ConstantInstr* constant = new (Z) ConstantInstr(value);
  Push(constant);
  return Fragment(constant);
}


Fragment FlowGraphBuilder::CreateArray() {
  Value* element_count = Pop();
  CreateArrayInstr* array =
      new (Z) CreateArrayInstr(TokenPosition::kNoSource,
                               Pop(),  // Element type.
                               element_count, GetNextDeoptId());
  Push(array);
  return Fragment(array);
}


Fragment FlowGraphBuilder::Goto(JoinEntryInstr* destination) {
  return Fragment(new (Z) GotoInstr(destination, GetNextDeoptId())).closed();
}


Fragment FlowGraphBuilder::IntConstant(int64_t value) {
  return Fragment(
      Constant(Integer::ZoneHandle(Z, Integer::New(value, Heap::kOld))));
}


Fragment FlowGraphBuilder::InstanceCall(TokenPosition position,
                                        const dart::String& name,
                                        Token::Kind kind,
                                        intptr_t argument_count,
                                        intptr_t checked_argument_count) {
  const intptr_t kTypeArgsLen = 0;
  return InstanceCall(position, name, kind, kTypeArgsLen, argument_count,
                      Array::null_array(), checked_argument_count);
}


Fragment FlowGraphBuilder::InstanceCall(TokenPosition position,
                                        const dart::String& name,
                                        Token::Kind kind,
                                        intptr_t type_args_len,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        intptr_t checked_argument_count) {
  const intptr_t total_count = argument_count + (type_args_len > 0 ? 1 : 0);
  ArgumentArray arguments = GetArguments(total_count);
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position, name, kind, arguments, type_args_len, argument_names,
      checked_argument_count, ic_data_array_, GetNextDeoptId());
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::ClosureCall(intptr_t type_args_len,
                                       intptr_t argument_count,
                                       const Array& argument_names) {
  Value* function = Pop();
  const intptr_t total_count = argument_count + (type_args_len > 0 ? 1 : 0);
  ArgumentArray arguments = GetArguments(total_count);
  ClosureCallInstr* call = new (Z)
      ClosureCallInstr(function, arguments, type_args_len, argument_names,
                       TokenPosition::kNoSource, GetNextDeoptId());
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::ThrowException(TokenPosition position) {
  Fragment instructions;
  instructions += Drop();
  instructions +=
      Fragment(new (Z) ThrowInstr(position, GetNextDeoptId())).closed();
  // Use it's side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  pending_argument_count_ -= 1;

  return instructions;
}


Fragment FlowGraphBuilder::RethrowException(TokenPosition position,
                                            int catch_try_index) {
  Fragment instructions;
  instructions += Drop();
  instructions += Drop();
  instructions += Fragment(new (Z) ReThrowInstr(position, catch_try_index,
                                                GetNextDeoptId()))
                      .closed();
  // Use it's side effect of leaving a constant on the stack (does not change
  // the graph).
  NullConstant();

  pending_argument_count_ -= 2;

  return instructions;
}


Fragment FlowGraphBuilder::LoadClassId() {
  LoadClassIdInstr* load = new (Z) LoadClassIdInstr(Pop());
  Push(load);
  return Fragment(load);
}


const dart::Field& MayCloneField(Zone* zone, const dart::Field& field) {
  if ((Compiler::IsBackgroundCompilation() ||
       FLAG_force_clone_compiler_objects) &&
      field.IsOriginal()) {
    return dart::Field::ZoneHandle(zone, field.CloneFromOriginal());
  } else {
    ASSERT(field.IsZoneHandle());
    return field;
  }
}


Fragment FlowGraphBuilder::LoadField(const dart::Field& field) {
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(Pop(), &MayCloneField(Z, field),
                             AbstractType::ZoneHandle(Z, field.type()),
                             TokenPosition::kNoSource, parsed_function_);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadField(intptr_t offset, intptr_t class_id) {
  LoadFieldInstr* load = new (Z) LoadFieldInstr(
      Pop(), offset, AbstractType::ZoneHandle(Z), TokenPosition::kNoSource);
  load->set_result_cid(class_id);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadNativeField(MethodRecognizer::Kind kind,
                                           intptr_t offset,
                                           const Type& type,
                                           intptr_t class_id,
                                           bool is_immutable) {
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(Pop(), offset, type, TokenPosition::kNoSource);
  load->set_recognized_kind(kind);
  load->set_result_cid(class_id);
  load->set_is_immutable(is_immutable);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::LoadLocal(LocalVariable* variable) {
  Fragment instructions;
  if (variable->is_captured()) {
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions += LoadField(Context::variable_offset(variable->index()));
  } else {
    LoadLocalInstr* load =
        new (Z) LoadLocalInstr(*variable, TokenPosition::kNoSource);
    instructions <<= load;
    Push(load);
  }
  return instructions;
}


Fragment FlowGraphBuilder::InitStaticField(const dart::Field& field) {
  InitStaticFieldInstr* init = new (Z)
      InitStaticFieldInstr(Pop(), MayCloneField(Z, field), GetNextDeoptId());
  return Fragment(init);
}


Fragment FlowGraphBuilder::LoadStaticField() {
  LoadStaticFieldInstr* load =
      new (Z) LoadStaticFieldInstr(Pop(), TokenPosition::kNoSource);
  Push(load);
  return Fragment(load);
}


Fragment FlowGraphBuilder::NullConstant() {
  return Constant(Instance::ZoneHandle(Z, Instance::null()));
}


Fragment FlowGraphBuilder::NativeCall(const dart::String* name,
                                      const Function* function) {
  InlineBailout("kernel::FlowGraphBuilder::NativeCall");
  NativeCallInstr* call = new (Z) NativeCallInstr(
      name, function, FLAG_link_natives_lazily, TokenPosition::kNoSource);
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::PushArgument() {
  PushArgumentInstr* argument = new (Z) PushArgumentInstr(Pop());
  Push(argument);

  argument->set_temp_index(argument->temp_index() - 1);
  ++pending_argument_count_;

  return Fragment(argument);
}


Fragment FlowGraphBuilder::Return(TokenPosition position) {
  Fragment instructions;

  instructions += CheckReturnTypeInCheckedMode();

  Value* value = Pop();
  ASSERT(stack_ == NULL);

  const Function& function = parsed_function_->function();
  if (NeedsDebugStepCheck(function, position)) {
    instructions += DebugStepCheck(position);
  }

  if (FLAG_causal_async_stacks &&
      (function.IsAsyncClosure() || function.IsAsyncGenClosure())) {
    // We are returning from an asynchronous closure. Before we do that, be
    // sure to clear the thread's asynchronous stack trace.
    const Function& target = Function::ZoneHandle(
        Z, I->object_store()->async_clear_thread_stack_trace());
    ASSERT(!target.IsNull());
    instructions += StaticCall(TokenPosition::kNoSource, target, 0);
    instructions += Drop();
  }

  ReturnInstr* return_instr =
      new (Z) ReturnInstr(position, value, GetNextDeoptId());
  if (exit_collector_ != NULL) exit_collector_->AddExit(return_instr);

  instructions <<= return_instr;

  return instructions.closed();
}


Fragment FlowGraphBuilder::StaticCall(TokenPosition position,
                                      const Function& target,
                                      intptr_t argument_count) {
  return StaticCall(position, target, argument_count, Array::null_array());
}


static intptr_t GetResultCidOfListFactory(Zone* zone,
                                          const Function& function,
                                          intptr_t argument_count) {
  if (!function.IsFactory()) {
    return kDynamicCid;
  }

  const dart::Class& owner = dart::Class::Handle(zone, function.Owner());
  if ((owner.library() != dart::Library::CoreLibrary()) &&
      (owner.library() != dart::Library::TypedDataLibrary())) {
    return kDynamicCid;
  }

  if ((owner.Name() == Symbols::List().raw()) &&
      (function.name() == Symbols::ListFactory().raw())) {
    ASSERT(argument_count == 1 || argument_count == 2);
    return (argument_count == 1) ? kGrowableObjectArrayCid : kArrayCid;
  }
  return FactoryRecognizer::ResultCid(function);
}


Fragment FlowGraphBuilder::StaticCall(TokenPosition position,
                                      const Function& target,
                                      intptr_t argument_count,
                                      const Array& argument_names) {
  ArgumentArray arguments = GetArguments(argument_count);
  const intptr_t kTypeArgsLen = 0;  // Generic static calls not yet supported.
  StaticCallInstr* call =
      new (Z) StaticCallInstr(position, target, kTypeArgsLen, argument_names,
                              arguments, ic_data_array_, GetNextDeoptId());
  const intptr_t list_cid =
      GetResultCidOfListFactory(Z, target, argument_count);
  if (list_cid != kDynamicCid) {
    call->set_result_cid(list_cid);
    call->set_is_known_list_constructor(true);
  } else if (target.recognized_kind() != MethodRecognizer::kUnknown) {
    call->set_result_cid(MethodRecognizer::ResultCid(target));
  }
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::StoreIndexed(intptr_t class_id) {
  Value* value = Pop();
  Value* index = Pop();
  const StoreBarrierType emit_store_barrier =
      value->BindsToConstant() ? kNoStoreBarrier : kEmitStoreBarrier;
  StoreIndexedInstr* store = new (Z) StoreIndexedInstr(
      Pop(),  // Array.
      index, value, emit_store_barrier, Instance::ElementSizeFor(class_id),
      class_id, kAlignedAccess, Thread::kNoDeoptId, TokenPosition::kNoSource);
  Push(store);
  return Fragment(store);
}


Fragment FlowGraphBuilder::StoreInstanceField(
    const dart::Field& field,
    bool is_initialization_store,
    StoreBarrierType emit_store_barrier) {
  Fragment instructions;

  const AbstractType& dst_type = AbstractType::ZoneHandle(Z, field.type());
  instructions += CheckAssignableInCheckedMode(
      dst_type, dart::String::ZoneHandle(Z, field.name()));

  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }

  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(MayCloneField(Z, field), Pop(), value,
                              emit_store_barrier, TokenPosition::kNoSource);
  store->set_is_initialization(is_initialization_store);
  instructions <<= store;

  return instructions;
}


Fragment FlowGraphBuilder::StoreInstanceFieldGuarded(
    const dart::Field& field,
    bool is_initialization_store) {
  Fragment instructions;
  const dart::Field& field_clone = MayCloneField(Z, field);
  if (I->use_field_guards()) {
    LocalVariable* store_expression = MakeTemporary();
    instructions += LoadLocal(store_expression);
    instructions += GuardFieldClass(field_clone, GetNextDeoptId());
    instructions += LoadLocal(store_expression);
    instructions += GuardFieldLength(field_clone, GetNextDeoptId());
  }
  instructions += StoreInstanceField(field_clone, is_initialization_store);
  return instructions;
}


Fragment FlowGraphBuilder::StoreInstanceField(
    TokenPosition position,
    intptr_t offset,
    StoreBarrierType emit_store_barrier) {
  Value* value = Pop();
  if (value->BindsToConstant()) {
    emit_store_barrier = kNoStoreBarrier;
  }
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      offset, Pop(), value, emit_store_barrier, position);
  return Fragment(store);
}


Fragment FlowGraphBuilder::StoreLocal(TokenPosition position,
                                      LocalVariable* variable) {
  Fragment instructions;
  if (variable->is_captured()) {
    LocalVariable* value = MakeTemporary();
    instructions += LoadContextAt(variable->owner()->context_level());
    instructions += LoadLocal(value);
    instructions += StoreInstanceField(
        position, Context::variable_offset(variable->index()));
  } else {
    Value* value = Pop();
    StoreLocalInstr* store =
        new (Z) StoreLocalInstr(*variable, value, position);
    instructions <<= store;
    Push(store);
  }
  return instructions;
}


Fragment FlowGraphBuilder::StoreStaticField(TokenPosition position,
                                            const dart::Field& field) {
  return Fragment(
      new (Z) StoreStaticFieldInstr(MayCloneField(Z, field), Pop(), position));
}


Fragment FlowGraphBuilder::StringInterpolate(TokenPosition position) {
  Value* array = Pop();
  StringInterpolateInstr* interpolate =
      new (Z) StringInterpolateInstr(array, position, GetNextDeoptId());
  Push(interpolate);
  return Fragment(interpolate);
}


Fragment FlowGraphBuilder::StringInterpolateSingle(TokenPosition position) {
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  const dart::Class& cls = dart::Class::Handle(
      dart::Library::LookupCoreClass(Symbols::StringBase()));
  ASSERT(!cls.IsNull());
  const Function& function = Function::ZoneHandle(
      Z,
      Resolver::ResolveStatic(
          cls, dart::Library::PrivateCoreLibName(Symbols::InterpolateSingle()),
          kTypeArgsLen, kNumberOfArguments, kNoArgumentNames));
  Fragment instructions;
  instructions += PushArgument();
  instructions += StaticCall(position, function, 1);
  return instructions;
}


Fragment FlowGraphBuilder::ThrowTypeError() {
  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::TypeError()));
  ASSERT(!klass.IsNull());
  const Function& constructor = Function::ZoneHandle(
      Z,
      klass.LookupConstructorAllowPrivate(H.DartSymbol("_TypeError._create")));
  ASSERT(!constructor.IsNull());

  const dart::String& url = H.DartString(
      parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  Fragment instructions;

  // Create instance of _FallThroughError
  instructions += AllocateObject(TokenPosition::kNoSource, klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _TypeError._create constructor.
  instructions += LoadLocal(instance);
  instructions += PushArgument();  // this

  instructions += Constant(url);
  instructions += PushArgument();  // url

  instructions += NullConstant();
  instructions += PushArgument();  // line

  instructions += IntConstant(0);
  instructions += PushArgument();  // column

  instructions += Constant(H.DartSymbol("Malformed type."));
  instructions += PushArgument();  // message

  instructions += StaticCall(TokenPosition::kNoSource, constructor, 5);
  instructions += Drop();

  // Throw the exception
  instructions += PushArgument();
  instructions += ThrowException(TokenPosition::kNoSource);

  return instructions;
}


Fragment FlowGraphBuilder::ThrowNoSuchMethodError() {
  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::NoSuchMethodError()));
  ASSERT(!klass.IsNull());
  const Function& throw_function = Function::ZoneHandle(
      Z, klass.LookupStaticFunctionAllowPrivate(Symbols::ThrowNew()));
  ASSERT(!throw_function.IsNull());

  Fragment instructions;

  // Call NoSuchMethodError._throwNew static function.
  instructions += NullConstant();
  instructions += PushArgument();  // receiver

  instructions += Constant(H.DartString("<unknown>", Heap::kOld));
  instructions += PushArgument();  // memberName

  instructions += IntConstant(-1);
  instructions += PushArgument();  // invocation_type

  instructions += NullConstant();
  instructions += PushArgument();  // arguments

  instructions += NullConstant();
  instructions += PushArgument();  // argumentNames

  instructions += NullConstant();
  instructions += PushArgument();  // existingArgumentNames

  instructions += StaticCall(TokenPosition::kNoSource, throw_function, 6);
  // Leave "result" on the stack since callers expect it to be there (even
  // though the function will result in an exception).

  return instructions;
}


RawFunction* FlowGraphBuilder::LookupMethodByMember(
    NameIndex target,
    const dart::String& method_name) {
  NameIndex kernel_class = H.EnclosingName(target);
  dart::Class& klass =
      dart::Class::Handle(Z, H.LookupClassByKernelClass(kernel_class));

  RawFunction* function = klass.LookupFunctionAllowPrivate(method_name);
  ASSERT(function != Object::null());
  return function;
}


LocalVariable* FlowGraphBuilder::MakeTemporary() {
  char name[64];
  intptr_t index = stack_->definition()->temp_index();
  OS::SNPrint(name, 64, ":temp%" Pd, index);
  LocalVariable* variable =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            H.DartSymbol(name), Object::dynamic_type());
  // Set the index relative to the base of the expression stack including
  // outgoing arguments.
  variable->set_index(parsed_function_->first_stack_local_index() -
                      parsed_function_->num_stack_locals() -
                      pending_argument_count_ - index);

  // The value has uses as if it were a local variable.  Mark the definition
  // as used so that its temp index will not be cleared (causing it to never
  // be materialized in the expression stack).
  stack_->definition()->set_ssa_temp_index(0);

  return variable;
}


intptr_t FlowGraphBuilder::CurrentTryIndex() {
  if (try_catch_block_ == NULL) {
    return CatchClauseNode::kInvalidTryIndex;
  } else {
    return try_catch_block_->try_index();
  }
}


dart::LocalVariable* FlowGraphBuilder::LookupVariable(intptr_t kernel_offset) {
  LocalVariable* local = scopes_->locals.Lookup(kernel_offset);
  ASSERT(local != NULL);
  return local;
}


void FlowGraphBuilder::SetTempIndex(Definition* definition) {
  definition->set_temp_index(
      stack_ == NULL ? 0 : stack_->definition()->temp_index() + 1);
}


void FlowGraphBuilder::Push(Definition* definition) {
  SetTempIndex(definition);
  Value::AddToList(new (Z) Value(definition), &stack_);
}


Value* FlowGraphBuilder::Pop() {
  ASSERT(stack_ != NULL);
  Value* value = stack_;
  stack_ = value->next_use();
  if (stack_ != NULL) stack_->set_previous_use(NULL);

  value->set_next_use(NULL);
  value->set_previous_use(NULL);
  value->definition()->ClearSSATempIndex();
  return value;
}


Fragment FlowGraphBuilder::Drop() {
  ASSERT(stack_ != NULL);
  Fragment instructions;
  Definition* definition = stack_->definition();
  // The SSA renaming implementation doesn't like [LoadLocal]s without a
  // tempindex.
  if (definition->HasSSATemp() || definition->IsLoadLocal()) {
    instructions <<= new (Z) DropTempsInstr(1, NULL);
  } else {
    definition->ClearTempIndex();
  }

  Pop();
  return instructions;
}


// TODO(27590): This method should be shared with
// runtime/vm/object.cc:RecognizeArithmeticOp.
Token::Kind FlowGraphBuilder::MethodKind(const dart::String& name) {
  ASSERT(name.IsSymbol());
  if (name.raw() == Symbols::Plus().raw()) {
    return Token::kADD;
  } else if (name.raw() == Symbols::Minus().raw()) {
    return Token::kSUB;
  } else if (name.raw() == Symbols::Star().raw()) {
    return Token::kMUL;
  } else if (name.raw() == Symbols::Slash().raw()) {
    return Token::kDIV;
  } else if (name.raw() == Symbols::TruncDivOperator().raw()) {
    return Token::kTRUNCDIV;
  } else if (name.raw() == Symbols::Percent().raw()) {
    return Token::kMOD;
  } else if (name.raw() == Symbols::BitOr().raw()) {
    return Token::kBIT_OR;
  } else if (name.raw() == Symbols::Ampersand().raw()) {
    return Token::kBIT_AND;
  } else if (name.raw() == Symbols::Caret().raw()) {
    return Token::kBIT_XOR;
  } else if (name.raw() == Symbols::LeftShiftOperator().raw()) {
    return Token::kSHL;
  } else if (name.raw() == Symbols::RightShiftOperator().raw()) {
    return Token::kSHR;
  } else if (name.raw() == Symbols::Tilde().raw()) {
    return Token::kBIT_NOT;
  } else if (name.raw() == Symbols::UnaryMinus().raw()) {
    return Token::kNEGATE;
  } else if (name.raw() == Symbols::EqualOperator().raw()) {
    return Token::kEQ;
  } else if (name.raw() == Symbols::Token(Token::kNE).raw()) {
    return Token::kNE;
  } else if (name.raw() == Symbols::LAngleBracket().raw()) {
    return Token::kLT;
  } else if (name.raw() == Symbols::RAngleBracket().raw()) {
    return Token::kGT;
  } else if (name.raw() == Symbols::LessEqualOperator().raw()) {
    return Token::kLTE;
  } else if (name.raw() == Symbols::GreaterEqualOperator().raw()) {
    return Token::kGTE;
  } else if (dart::Field::IsGetterName(name)) {
    return Token::kGET;
  } else if (dart::Field::IsSetterName(name)) {
    return Token::kSET;
  }
  return Token::kILLEGAL;
}


void FlowGraphBuilder::InlineBailout(const char* reason) {
  bool is_inlining = exit_collector_ != NULL;
  if (is_inlining) {
    parsed_function_->function().set_is_inlinable(false);
    parsed_function_->Bailout("kernel::FlowGraphBuilder", reason);
  }
}


FlowGraph* FlowGraphBuilder::BuildGraph() {
  const Function& function = parsed_function_->function();

  if (function.IsConstructorClosureFunction()) return NULL;

  if (streaming_flow_graph_builder_ != NULL) {
    delete streaming_flow_graph_builder_;
    streaming_flow_graph_builder_ = NULL;
  }

  Script& script = Script::Handle(Z, function.script());
  streaming_flow_graph_builder_ = new StreamingFlowGraphBuilder(
      this, script.kernel_data(), script.kernel_data_size());

  return streaming_flow_graph_builder_->BuildGraph(kernel_offset_);
}


Fragment FlowGraphBuilder::NativeFunctionBody(intptr_t first_positional_offset,
                                              const Function& function) {
  ASSERT(function.is_native());
  // We explicitly build the graph for native functions in the same way that the
  // from-source backend does.  We should find a way to have a single component
  // to build these graphs so that this code is not duplicated.

  Fragment body;
  MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(function);
  switch (kind) {
    case MethodRecognizer::kObjectEquals:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StrictCompare(Token::kEQ_STRICT);
      break;
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty:
      // Depending on FLAG_support_externalizable_strings, treat string length
      // loads as mutable so that the class check that precedes them will not be
      // hoisted.  This is unsafe because string externalization can change the
      // class.
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(MethodRecognizer::kStringBaseLength,
                              dart::String::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid,
                              !FLAG_support_externalizable_strings);
      if (kind == MethodRecognizer::kStringBaseIsEmpty) {
        body += IntConstant(0);
        body += StrictCompare(Token::kEQ_STRICT);
      }
      break;
    case MethodRecognizer::kGrowableArrayLength:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, GrowableObjectArray::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
      body += LoadLocal(scopes_->this_variable);
      body +=
          LoadNativeField(kind, Array::length_offset(),
                          Type::ZoneHandle(Z, Type::SmiType()), kSmiCid, true);
      break;
    case MethodRecognizer::kTypedDataLength:
      body += LoadLocal(scopes_->this_variable);
      body +=
          LoadNativeField(kind, TypedData::length_offset(),
                          Type::ZoneHandle(Z, Type::SmiType()), kSmiCid, true);
      break;
    case MethodRecognizer::kClassIDgetID:
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += LoadClassId();
      break;
    case MethodRecognizer::kGrowableArrayCapacity:
      body += LoadLocal(scopes_->this_variable);
      body += LoadField(Array::data_offset(), kArrayCid);
      body += LoadNativeField(MethodRecognizer::kObjectArrayLength,
                              Array::length_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kObjectArrayAllocate:
      body += LoadLocal(scopes_->type_arguments_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += CreateArray();
      break;
    case MethodRecognizer::kBigint_getDigits:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::digits_offset(),
                              Object::dynamic_type(), kTypedDataUint32ArrayCid);
      break;
    case MethodRecognizer::kBigint_getUsed:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::used_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_getIndex:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::index_offset(),
                              Object::dynamic_type(), kDynamicCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setIndex:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 LinkedHashMap::index_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::data_offset(),
                              Object::dynamic_type(), kArrayCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 LinkedHashMap::data_offset());
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getHashMask:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::hash_mask_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setHashMask:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 LinkedHashMap::hash_mask_offset(),
                                 kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getUsedData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::used_data_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setUsedData:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 LinkedHashMap::used_data_offset(),
                                 kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kLinkedHashMap_getDeletedKeys:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, LinkedHashMap::deleted_keys_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
      break;
    case MethodRecognizer::kLinkedHashMap_setDeletedKeys:
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(LookupVariable(first_positional_offset));
      body += StoreInstanceField(TokenPosition::kNoSource,
                                 LinkedHashMap::deleted_keys_offset(),
                                 kNoStoreBarrier);
      body += NullConstant();
      break;
    case MethodRecognizer::kBigint_getNeg:
      body += LoadLocal(scopes_->this_variable);
      body += LoadNativeField(kind, Bigint::neg_offset(),
                              Type::ZoneHandle(Z, Type::BoolType()), kBoolCid);
      break;
    default: {
      dart::String& name = dart::String::ZoneHandle(Z, function.native_name());
      body += NativeCall(&name, &function);
      break;
    }
  }
  return body + Return(TokenPosition::kNoSource);
}


Fragment FlowGraphBuilder::BuildImplicitClosureCreation(
    const Function& target) {
  Fragment fragment;
  const dart::Class& closure_class =
      dart::Class::ZoneHandle(Z, I->object_store()->closure_class());
  fragment += AllocateObject(closure_class, target);
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  //
  // TODO(regis): Also handle the case of a function signature that has
  // uninstantiated function type parameters.
  if (!target.HasInstantiatedSignature(kCurrentClass)) {
    fragment += LoadLocal(closure);
    fragment += LoadInstantiatorTypeArguments();
    fragment +=
        StoreInstanceField(TokenPosition::kNoSource,
                           Closure::instantiator_type_arguments_offset());
  }

  // Allocate a context that closes over `this`.
  fragment += AllocateContext(1);
  LocalVariable* context = MakeTemporary();

  // Store the function and the context in the closure.
  fragment += LoadLocal(closure);
  fragment += Constant(target);
  fragment +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::function_offset());

  fragment += LoadLocal(closure);
  fragment += LoadLocal(context);
  fragment +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::context_offset());

  // The context is on top of the operand stack.  Store `this`.  The context
  // doesn't need a parent pointer because it doesn't close over anything
  // else.
  fragment += LoadLocal(scopes_->this_variable);
  fragment +=
      StoreInstanceField(TokenPosition::kNoSource, Context::variable_offset(0));

  return fragment;
}


Fragment FlowGraphBuilder::GuardFieldLength(const dart::Field& field,
                                            intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldLengthInstr(Pop(), field, deopt_id));
}


Fragment FlowGraphBuilder::GuardFieldClass(const dart::Field& field,
                                           intptr_t deopt_id) {
  return Fragment(new (Z) GuardFieldClassInstr(Pop(), field, deopt_id));
}


Fragment FlowGraphBuilder::CheckVariableTypeInCheckedMode(
    const AbstractType& dst_type,
    const dart::String& name_symbol) {
  if (I->type_checks()) {
    if (dst_type.IsMalformed()) {
      return ThrowTypeError();
    }
    return CheckAssignableInCheckedMode(dst_type, name_symbol);
  }
  return Fragment();
}


bool FlowGraphBuilder::NeedsDebugStepCheck(const Function& function,
                                           TokenPosition position) {
  return FLAG_support_debugger && position.IsDebugPause() &&
         !function.is_native() && function.is_debuggable();
}


bool FlowGraphBuilder::NeedsDebugStepCheck(Value* value,
                                           TokenPosition position) {
  if (!FLAG_support_debugger || !position.IsDebugPause()) return false;
  Definition* definition = value->definition();
  if (definition->IsConstant() || definition->IsLoadStaticField()) return true;
  if (definition->IsAllocateObject()) {
    return !definition->AsAllocateObject()->closure_function().IsNull();
  }
  return definition->IsLoadLocal() &&
         !definition->AsLoadLocal()->local().IsInternal();
}

Fragment FlowGraphBuilder::DebugStepCheck(TokenPosition position) {
  return Fragment(new (Z) DebugStepCheckInstr(
      position, RawPcDescriptors::kRuntimeCall, GetNextDeoptId()));
}


Fragment FlowGraphBuilder::EvaluateAssertion() {
  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const Function& target =
      Function::ZoneHandle(Z, klass.LookupStaticFunctionAllowPrivate(
                                  H.DartSymbol("_evaluateAssertion")));
  ASSERT(!target.IsNull());
  return StaticCall(TokenPosition::kNoSource, target, 1);
}


Fragment FlowGraphBuilder::CheckReturnTypeInCheckedMode() {
  if (I->type_checks()) {
    const AbstractType& return_type =
        AbstractType::Handle(Z, parsed_function_->function().result_type());
    return CheckAssignableInCheckedMode(return_type, Symbols::FunctionResult());
  }
  return Fragment();
}


Fragment FlowGraphBuilder::CheckBooleanInCheckedMode() {
  Fragment instructions;
  if (I->type_checks()) {
    LocalVariable* top_of_stack = MakeTemporary();
    instructions += LoadLocal(top_of_stack);
    instructions += AssertBool();
    instructions += Drop();
  }
  return instructions;
}


Fragment FlowGraphBuilder::CheckAssignableInCheckedMode(
    const AbstractType& dst_type,
    const dart::String& dst_name) {
  Fragment instructions;
  if (I->type_checks() && !dst_type.IsDynamicType() &&
      !dst_type.IsObjectType() && !dst_type.IsVoidType()) {
    LocalVariable* top_of_stack = MakeTemporary();
    instructions += LoadLocal(top_of_stack);
    instructions += AssertAssignable(dst_type, dst_name);
    instructions += Drop();
  }
  return instructions;
}


Fragment FlowGraphBuilder::AssertBool() {
  Value* value = Pop();
  AssertBooleanInstr* instr = new (Z)
      AssertBooleanInstr(TokenPosition::kNoSource, value, GetNextDeoptId());
  Push(instr);
  return Fragment(instr);
}


Fragment FlowGraphBuilder::AssertAssignable(const AbstractType& dst_type,
                                            const dart::String& dst_name) {
  Fragment instructions;
  Value* value = Pop();

  if (!dst_type.IsInstantiated(kCurrentClass)) {
    instructions += LoadInstantiatorTypeArguments();
  } else {
    instructions += NullConstant();
  }
  Value* instantiator_type_args = Pop();

  if (!dst_type.IsInstantiated(kFunctions)) {
    instructions += LoadFunctionTypeArguments();
  } else {
    instructions += NullConstant();
  }
  Value* function_type_args = Pop();

  AssertAssignableInstr* instr = new (Z) AssertAssignableInstr(
      TokenPosition::kNoSource, value, instantiator_type_args,
      function_type_args, dst_type, dst_name, GetNextDeoptId());
  Push(instr);

  instructions += Fragment(instr);

  return instructions;
}


FlowGraph* FlowGraphBuilder::BuildGraphOfMethodExtractor(
    const Function& method) {
  // A method extractor is the implicit getter for a method.
  const Function& function =
      Function::ZoneHandle(Z, method.extracted_method_closure());

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);
  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();
  body += BuildImplicitClosureCreation(function);
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfNoSuchMethodDispatcher(
    const Function& function) {
  // This function is specialized for a receiver class, a method name, and
  // the arguments descriptor at a call site.

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  // The backend will expect an array of default values for all the named
  // parameters, even if they are all known to be passed at the call site
  // because the call site matches the arguments descriptor.  Use null for
  // the default values.
  const Array& descriptor_array =
      Array::ZoneHandle(Z, function.saved_args_desc());
  ArgumentsDescriptor descriptor(descriptor_array);
  ZoneGrowableArray<const Instance*>* default_values =
      new ZoneGrowableArray<const Instance*>(Z, descriptor.NamedCount());
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    default_values->Add(&Object::null_instance());
  }
  parsed_function_->set_default_parameter_values(default_values);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  // TODO(regis): Check if a type argument vector is passed.

  // The receiver is the first argument to noSuchMethod, and it is the first
  // argument passed to the dispatcher function.
  LocalScope* scope = parsed_function_->node_sequence()->scope();
  body += LoadLocal(scope->VariableAt(0));
  body += PushArgument();

  // The second argument to noSuchMethod is an invocation mirror.  Push the
  // arguments for allocating the invocation mirror.  First, the name.
  body += Constant(dart::String::ZoneHandle(Z, function.name()));
  body += PushArgument();

  // Second, the arguments descriptor.
  body += Constant(descriptor_array);
  body += PushArgument();

  // Third, an array containing the original arguments.  Create it and fill
  // it in.
  body += Constant(TypeArguments::ZoneHandle(Z, TypeArguments::null()));
  body += IntConstant(descriptor.Count());
  body += CreateArray();
  LocalVariable* array = MakeTemporary();
  for (intptr_t i = 0; i < descriptor.PositionalCount(); ++i) {
    body += LoadLocal(array);
    body += IntConstant(i);
    body += LoadLocal(scope->VariableAt(i));
    body += StoreIndexed(kArrayCid);
    body += Drop();
  }
  dart::String& name = dart::String::Handle(Z);
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    intptr_t parameter_index = descriptor.PositionalCount() + i;
    name = descriptor.NameAt(i);
    name = Symbols::New(H.thread(), name);
    body += LoadLocal(array);
    body += IntConstant(descriptor.PositionAt(i));
    body += LoadLocal(scope->VariableAt(parameter_index));
    body += StoreIndexed(kArrayCid);
    body += Drop();
  }
  body += PushArgument();

  // Fourth, false indicating this is not a super NoSuchMethod.
  body += Constant(Bool::False());
  body += PushArgument();

  const dart::Class& mirror_class = dart::Class::Handle(
      Z, dart::Library::LookupCoreClass(Symbols::InvocationMirror()));
  ASSERT(!mirror_class.IsNull());
  const Function& allocation_function = Function::ZoneHandle(
      Z, mirror_class.LookupStaticFunction(dart::Library::PrivateCoreLibName(
             Symbols::AllocateInvocationMirror())));
  ASSERT(!allocation_function.IsNull());
  body += StaticCall(TokenPosition::kMinSource, allocation_function, 4);
  body += PushArgument();  // For the call to noSuchMethod.

  const int kTypeArgsLen = 0;
  ArgumentsDescriptor two_arguments(
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, 2)));
  Function& no_such_method =
      Function::ZoneHandle(Z, Resolver::ResolveDynamicForReceiverClass(
                                  dart::Class::Handle(Z, function.Owner()),
                                  Symbols::NoSuchMethod(), two_arguments));
  if (no_such_method.IsNull()) {
    // If noSuchMethod is not found on the receiver class, call
    // Object.noSuchMethod.
    no_such_method = Resolver::ResolveDynamicForReceiverClass(
        dart::Class::Handle(Z, I->object_store()->object_class()),
        Symbols::NoSuchMethod(), two_arguments);
  }
  body += StaticCall(TokenPosition::kMinSource, no_such_method, 2);
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfInvokeFieldDispatcher(
    const Function& function) {
  // Find the name of the field we should dispatch to.
  const dart::Class& owner = dart::Class::Handle(Z, function.Owner());
  ASSERT(!owner.IsNull());
  const dart::String& field_name = dart::String::Handle(Z, function.name());
  const dart::String& getter_name = dart::String::ZoneHandle(
      Z,
      Symbols::New(H.thread(), dart::String::Handle(
                                   Z, dart::Field::GetterSymbol(field_name))));

  // Determine if this is `class Closure { get call => this; }`
  const dart::Class& closure_class =
      dart::Class::Handle(Z, I->object_store()->closure_class());
  const bool is_closure_call = (owner.raw() == closure_class.raw()) &&
                               field_name.Equals(Symbols::Call());

  // Set default parameters & construct argument names array.
  //
  // The backend will expect an array of default values for all the named
  // parameters, even if they are all known to be passed at the call site
  // because the call site matches the arguments descriptor.  Use null for
  // the default values.
  const Array& descriptor_array =
      Array::ZoneHandle(Z, function.saved_args_desc());
  ArgumentsDescriptor descriptor(descriptor_array);
  const Array& argument_names =
      Array::ZoneHandle(Z, Array::New(descriptor.NamedCount(), Heap::kOld));
  ZoneGrowableArray<const Instance*>* default_values =
      new ZoneGrowableArray<const Instance*>(Z, descriptor.NamedCount());
  dart::String& string_handle = dart::String::Handle(Z);
  for (intptr_t i = 0; i < descriptor.NamedCount(); ++i) {
    default_values->Add(&Object::null_instance());
    string_handle = descriptor.NameAt(i);
    argument_names.SetAt(i, string_handle);
  }
  parsed_function_->set_default_parameter_values(default_values);

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  LocalScope* scope = parsed_function_->node_sequence()->scope();

  if (descriptor.TypeArgsLen() > 0) {
    LocalVariable* type_args = parsed_function_->function_type_arguments();
    ASSERT(type_args != NULL);
    body += LoadLocal(type_args);
    body += PushArgument();
  }

  LocalVariable* closure = NULL;
  if (is_closure_call) {
    closure = scope->VariableAt(0);

    // The closure itself is the first argument.
    body += LoadLocal(closure);
  } else {
    // Invoke the getter to get the field value.
    body += LoadLocal(scope->VariableAt(0));
    body += PushArgument();
    body +=
        InstanceCall(TokenPosition::kMinSource, getter_name, Token::kGET, 1);
  }

  body += PushArgument();

  // Push all arguments onto the stack.
  intptr_t pos = 1;
  for (; pos < descriptor.Count(); pos++) {
    body += LoadLocal(scope->VariableAt(pos));
    body += PushArgument();
  }

  if (is_closure_call) {
    // Lookup the function in the closure.
    body += LoadLocal(closure);
    body += LoadField(Closure::function_offset());

    body += ClosureCall(descriptor.TypeArgsLen(), descriptor.Count(),
                        argument_names);
  } else {
    body += InstanceCall(TokenPosition::kMinSource, Symbols::Call(),
                         Token::kILLEGAL, descriptor.TypeArgsLen(),
                         descriptor.Count(), argument_names);
  }

  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


TargetEntryInstr* FlowGraphBuilder::BuildTargetEntry() {
  return new (Z)
      TargetEntryInstr(AllocateBlockId(), CurrentTryIndex(), GetNextDeoptId());
}


JoinEntryInstr* FlowGraphBuilder::BuildJoinEntry(intptr_t try_index) {
  return new (Z) JoinEntryInstr(AllocateBlockId(), try_index, GetNextDeoptId());
}


JoinEntryInstr* FlowGraphBuilder::BuildJoinEntry() {
  return new (Z)
      JoinEntryInstr(AllocateBlockId(), CurrentTryIndex(), GetNextDeoptId());
}

ArgumentArray FlowGraphBuilder::GetArguments(int count) {
  ArgumentArray arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(Z, count);
  arguments->SetLength(count);
  for (intptr_t i = count - 1; i >= 0; --i) {
    ASSERT(stack_->definition()->IsPushArgument());
    ASSERT(!stack_->definition()->HasSSATemp());
    arguments->data()[i] = stack_->definition()->AsPushArgument();
    Drop();
  }
  pending_argument_count_ -= count;
  ASSERT(pending_argument_count_ >= 0);
  return arguments;
}


RawObject* EvaluateMetadata(const dart::Field& metadata_field) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    Zone* zone_ = thread->zone();
    TranslationHelper helper(thread);
    Script& script = Script::Handle(Z, metadata_field.Script());
    helper.SetStringOffsets(
        TypedData::Handle(Z, script.kernel_string_offsets()));
    helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
    helper.SetCanonicalNames(
        TypedData::Handle(Z, script.kernel_canonical_names()));

    StreamingFlowGraphBuilder streaming_flow_graph_builder(
        &helper, zone_, script.kernel_data(), script.kernel_data_size());
    return streaming_flow_graph_builder.EvaluateMetadata(
        metadata_field.kernel_offset());
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
}


RawObject* BuildParameterDescriptor(const Function& function) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    Zone* zone_ = thread->zone();
    TranslationHelper helper(thread);
    Script& script = Script::Handle(Z, function.script());
    helper.SetStringOffsets(
        TypedData::Handle(Z, script.kernel_string_offsets()));
    helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
    helper.SetCanonicalNames(
        TypedData::Handle(Z, script.kernel_canonical_names()));

    StreamingFlowGraphBuilder streaming_flow_graph_builder(
        &helper, zone_, script.kernel_data(), script.kernel_data_size());
    return streaming_flow_graph_builder.BuildParameterDescriptor(
        function.kernel_offset());
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
}

static int LowestFirst(const intptr_t* a, const intptr_t* b) {
  return *a - *b;
}

/**
 * If index exists as sublist in list, sort the sublist from lowest to highest,
 * then copy it, as Smis and without duplicates,
 * to a new Array in Heap::kOld which is returned.
 * Note that the source list is both sorted and de-duplicated as well, but will
 * possibly contain duplicate and unsorted data at the end.
 * Otherwise (when sublist doesn't exist in list) return new empty array.
 */
static RawArray* AsSortedDuplicateFreeArray(GrowableArray<intptr_t>* source) {
  intptr_t size = source->length();
  if (size == 0) {
    return Array::New(0);
  }

  source->Sort(LowestFirst);

  intptr_t last = 0;
  for (intptr_t current = 1; current < size; ++current) {
    if (source->At(last) != source->At(current)) {
      (*source)[++last] = source->At(current);
    }
  }
  Array& array_object = Array::Handle();
  array_object = Array::New(last + 1, Heap::kOld);
  Smi& smi_value = Smi::Handle();
  for (intptr_t i = 0; i <= last; ++i) {
    smi_value = Smi::New(source->At(i));
    array_object.SetAt(i, smi_value);
  }
  return array_object.raw();
}

void CollectTokenPositionsFor(const Script& const_script) {
  Thread* thread = Thread::Current();
  Zone* zone_ = thread->zone();
  Script& script = Script::Handle(Z, const_script.raw());
  TranslationHelper helper(thread);
  helper.SetStringOffsets(TypedData::Handle(Z, script.kernel_string_offsets()));
  helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
  helper.SetCanonicalNames(
      TypedData::Handle(Z, script.kernel_canonical_names()));

  GrowableArray<intptr_t> token_positions(10);
  GrowableArray<intptr_t> yield_positions(1);
  StreamingFlowGraphBuilder streaming_flow_graph_builder(
      &helper, zone_, script.kernel_data(), script.kernel_data_size());
  streaming_flow_graph_builder.CollectTokenPositionsFor(
      script.kernel_script_index(), &token_positions, &yield_positions);
  Array& array_object = Array::Handle(Z);
  array_object = AsSortedDuplicateFreeArray(&token_positions);
  script.set_debug_positions(array_object);
  array_object = AsSortedDuplicateFreeArray(&yield_positions);
  script.set_yield_positions(array_object);
}

String& GetSourceFor(const Script& const_script) {
  Thread* thread = Thread::Current();
  Zone* zone_ = thread->zone();
  Script& script = Script::Handle(Z, const_script.raw());
  TranslationHelper helper(thread);
  helper.SetStringOffsets(TypedData::Handle(Z, script.kernel_string_offsets()));
  helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
  helper.SetCanonicalNames(
      TypedData::Handle(Z, script.kernel_canonical_names()));

  StreamingFlowGraphBuilder streaming_flow_graph_builder(
      &helper, zone_, script.kernel_data(), script.kernel_data_size());
  return streaming_flow_graph_builder.GetSourceFor(
      script.kernel_script_index());
}

Array& GetLineStartsFor(const Script& const_script) {
  Thread* thread = Thread::Current();
  Zone* zone_ = thread->zone();
  Script& script = Script::Handle(Z, const_script.raw());
  TranslationHelper helper(thread);
  helper.SetStringOffsets(TypedData::Handle(Z, script.kernel_string_offsets()));
  helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
  helper.SetCanonicalNames(
      TypedData::Handle(Z, script.kernel_canonical_names()));

  StreamingFlowGraphBuilder streaming_flow_graph_builder(
      &helper, zone_, script.kernel_data(), script.kernel_data_size());
  return streaming_flow_graph_builder.GetLineStartsFor(
      script.kernel_script_index());
}

}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
