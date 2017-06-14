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


static void DiscoverEnclosingElements(Zone* zone,
                                      const Function& function,
                                      Function* outermost_function,
                                      TreeNode** outermost_node,
                                      Class** klass) {
  // Find out if there is an enclosing kernel class (which will be used to
  // resolve type parameters).
  *outermost_function = function.raw();
  while (outermost_function->parent_function() != Object::null()) {
    *outermost_function = outermost_function->parent_function();
  }
  *outermost_node =
      static_cast<TreeNode*>(outermost_function->kernel_function());
  if (*outermost_node != NULL) {
    TreeNode* parent = NULL;
    if ((*outermost_node)->IsProcedure()) {
      parent = Procedure::Cast(*outermost_node)->parent();
    } else if ((*outermost_node)->IsConstructor()) {
      parent = Constructor::Cast(*outermost_node)->parent();
    } else if ((*outermost_node)->IsField()) {
      parent = Field::Cast(*outermost_node)->parent();
    }
    if (parent != NULL && parent->IsClass()) *klass = Class::Cast(parent);
  }
}


static bool IsStaticInitializer(const Function& function, Zone* zone) {
  return (function.kind() == RawFunction::kImplicitStaticFinalGetter) &&
         dart::String::Handle(zone, function.name())
             .StartsWith(Symbols::InitPrefix());
}


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


const dart::String& TranslationHelper::DartSetterName(Name* setter_name) {
  return DartSetterName(setter_name->library(), setter_name->string_index());
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


const dart::String& TranslationHelper::DartGetterName(Name* getter_name) {
  return DartGetterName(getter_name->library(), getter_name->string_index());
}


const dart::String& TranslationHelper::DartGetterName(NameIndex parent,
                                                      StringIndex getter) {
  dart::String& name = DartString(getter);
  ManglePrivateName(parent, &name, false);
  name = dart::Field::GetterSymbol(name);
  return name;
}


const dart::String& TranslationHelper::DartFieldName(Name* kernel_name) {
  dart::String& name = DartString(kernel_name->string_index());
  return ManglePrivateName(kernel_name->library(), &name);
}


const dart::String& TranslationHelper::DartInitializerName(Name* kernel_name) {
  // The [DartFieldName] will take care of mangling the name.
  dart::String& name =
      dart::String::Handle(Z, DartFieldName(kernel_name).raw());
  name = Symbols::FromConcat(thread_, Symbols::InitPrefix(), name);
  return name;
}


const dart::String& TranslationHelper::DartMethodName(NameIndex method) {
  return DartMethodName(CanonicalNameParent(method),
                        CanonicalNameString(method));
}


const dart::String& TranslationHelper::DartMethodName(Name* method_name) {
  return DartMethodName(method_name->library(), method_name->string_index());
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


const Array& TranslationHelper::ArgumentNames(List<NamedExpression>* named) {
  if (named->length() == 0) return Array::ZoneHandle(Z);

  const Array& names =
      Array::ZoneHandle(Z, Array::New(named->length(), Heap::kOld));
  for (intptr_t i = 0; i < named->length(); ++i) {
    names.SetAt(i, DartSymbol((*named)[i]->name()));
  }
  return names;
}

ConstantEvaluator::ConstantEvaluator(FlowGraphBuilder* builder,
                                     Zone* zone,
                                     TranslationHelper* h,
                                     DartTypeTranslator* type_translator)
    : builder_(builder),
      isolate_(Isolate::Current()),
      zone_(zone),
      translation_helper_(*h),
      type_translator_(*type_translator),
      script_(Script::Handle(
          zone,
          builder == NULL ? Script::null()
                          : builder_->parsed_function_->function().script())),
      result_(Instance::Handle(zone)) {}


Instance& ConstantEvaluator::EvaluateExpression(Expression* expression) {
  if (!GetCachedConstant(expression, &result_)) {
    expression->AcceptExpressionVisitor(this);
    CacheConstantValue(expression, result_);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}


Object& ConstantEvaluator::EvaluateExpressionSafe(Expression* expression) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    return EvaluateExpression(expression);
  } else {
    Thread* thread = H.thread();
    Error& error = Error::Handle(Z);
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error;
  }
}


Instance& ConstantEvaluator::EvaluateConstructorInvocation(
    ConstructorInvocation* node) {
  if (!GetCachedConstant(node, &result_)) {
    VisitConstructorInvocation(node);
    CacheConstantValue(node, result_);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}


Instance& ConstantEvaluator::EvaluateListLiteral(ListLiteral* node) {
  if (!GetCachedConstant(node, &result_)) {
    VisitListLiteral(node);
    CacheConstantValue(node, result_);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}


Instance& ConstantEvaluator::EvaluateMapLiteral(MapLiteral* node) {
  if (!GetCachedConstant(node, &result_)) {
    VisitMapLiteral(node);
    CacheConstantValue(node, result_);
  }
  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return Instance::ZoneHandle(Z, result_.raw());
}


void ConstantEvaluator::VisitBigintLiteral(BigintLiteral* node) {
  const dart::String& value = H.DartString(node->value());
  result_ = Integer::New(value, Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitBoolLiteral(BoolLiteral* node) {
  result_ = Bool::Get(node->value()).raw();
}


void ConstantEvaluator::VisitDoubleLiteral(DoubleLiteral* node) {
  result_ = Double::New(H.DartString(node->value()), Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitIntLiteral(IntLiteral* node) {
  result_ = Integer::New(node->value(), Heap::kOld);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitNullLiteral(NullLiteral* node) {
  result_ = Instance::null();
}


void ConstantEvaluator::VisitStringLiteral(StringLiteral* node) {
  result_ = H.DartSymbol(node->value()).raw();
}


void ConstantEvaluator::VisitTypeLiteral(TypeLiteral* node) {
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    H.ReportError("Malformed type literal in constant expression.");
  }
  result_ = type.raw();
}


RawObject* ConstantEvaluator::EvaluateConstConstructorCall(
    const dart::Class& type_class,
    const TypeArguments& type_arguments,
    const Function& constructor,
    const Object& argument) {
  // Factories have one extra argument: the type arguments.
  // Constructors have 1 extra arguments: receiver.
  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  const int kNumExtraArgs = 1;
  const int num_arguments = kNumArgs + kNumExtraArgs;
  const Array& arg_values =
      Array::Handle(Z, Array::New(num_arguments, Heap::kOld));
  Instance& instance = Instance::Handle(Z);
  if (!constructor.IsFactory()) {
    instance = Instance::New(type_class, Heap::kOld);
    if (!type_arguments.IsNull()) {
      ASSERT(type_arguments.IsInstantiated());
      instance.SetTypeArguments(
          TypeArguments::Handle(Z, type_arguments.Canonicalize()));
    }
    arg_values.SetAt(0, instance);
  } else {
    // Prepend type_arguments to list of arguments to factory.
    ASSERT(type_arguments.IsZoneHandle());
    arg_values.SetAt(0, type_arguments);
  }
  arg_values.SetAt((0 + kNumExtraArgs), argument);
  const Array& args_descriptor =
      Array::Handle(Z, ArgumentsDescriptor::New(kTypeArgsLen, num_arguments,
                                                Object::empty_array()));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(constructor, arg_values, args_descriptor));
  ASSERT(!result.IsError());
  if (constructor.IsFactory()) {
    // The factory method returns the allocated object.
    instance ^= result.raw();
  }
  return H.Canonicalize(instance);
}


bool ConstantEvaluator::GetCachedConstant(TreeNode* node, Instance* value) {
  if (builder_ == NULL) return false;

  const Function& function = builder_->parsed_function_->function();
  if (function.kind() == RawFunction::kImplicitStaticFinalGetter) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return false;
  }

  bool is_present = false;
  ASSERT(!script_.InVMHeap());
  if (script_.compile_time_constants() == Array::null()) {
    return false;
  }
  KernelConstantsMap constants(script_.compile_time_constants());
  *value ^= constants.GetOrNull(node->kernel_offset(), &is_present);
  // Mutator compiler thread may add constants while background compiler
  // is running, and thus change the value of 'compile_time_constants';
  // do not assert that 'compile_time_constants' has not changed.
  constants.Release();
  if (FLAG_compiler_stats && is_present) {
    H.thread()->compiler_stats()->num_const_cache_hits++;
  }
  return is_present;
}


void ConstantEvaluator::CacheConstantValue(TreeNode* node,
                                           const Instance& value) {
  ASSERT(Thread::Current()->IsMutatorThread());

  if (builder_ == NULL) return;

  const Function& function = builder_->parsed_function_->function();
  if (function.kind() == RawFunction::kImplicitStaticFinalGetter) {
    // Don't cache constants in initializer expressions. They get
    // evaluated only once.
    return;
  }
  const intptr_t kInitialConstMapSize = 16;
  ASSERT(!script_.InVMHeap());
  if (script_.compile_time_constants() == Array::null()) {
    const Array& array = Array::Handle(
        HashTables::New<KernelConstantsMap>(kInitialConstMapSize, Heap::kNew));
    script_.set_compile_time_constants(array);
  }
  KernelConstantsMap constants(script_.compile_time_constants());
  constants.InsertNewOrGetValue(node->kernel_offset(), value);
  script_.set_compile_time_constants(constants.Release());
}


void ConstantEvaluator::VisitSymbolLiteral(SymbolLiteral* node) {
  const dart::String& symbol_value = H.DartSymbol(node->value());

  const dart::Class& symbol_class =
      dart::Class::ZoneHandle(Z, I->object_store()->symbol_class());
  ASSERT(!symbol_class.IsNull());
  const Function& symbol_constructor = Function::ZoneHandle(
      Z, symbol_class.LookupConstructor(Symbols::SymbolCtor()));
  ASSERT(!symbol_constructor.IsNull());
  result_ ^= EvaluateConstConstructorCall(
      symbol_class, TypeArguments::Handle(Z), symbol_constructor, symbol_value);
}


void ConstantEvaluator::VisitListLiteral(ListLiteral* node) {
  DartType* types[] = {node->type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 1);

  intptr_t length = node->expressions().length();
  const Array& const_list =
      Array::ZoneHandle(Z, Array::New(length, Heap::kOld));
  const_list.SetTypeArguments(type_arguments);
  for (intptr_t i = 0; i < length; i++) {
    const Instance& expression = EvaluateExpression(node->expressions()[i]);
    const_list.SetAt(i, expression);
  }
  const_list.MakeImmutable();
  result_ = H.Canonicalize(const_list);
}


void ConstantEvaluator::VisitMapLiteral(MapLiteral* node) {
  DartType* types[] = {node->key_type(), node->value_type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 2);

  intptr_t length = node->entries().length();

  Array& const_kv_array =
      Array::ZoneHandle(Z, Array::New(2 * length, Heap::kOld));
  for (intptr_t i = 0; i < length; i++) {
    const_kv_array.SetAt(2 * i + 0,
                         EvaluateExpression(node->entries()[i]->key()));
    const_kv_array.SetAt(2 * i + 1,
                         EvaluateExpression(node->entries()[i]->value()));
  }

  const_kv_array.MakeImmutable();
  const_kv_array ^= H.Canonicalize(const_kv_array);

  const dart::Class& map_class = dart::Class::Handle(
      Z, dart::Library::LookupCoreClass(Symbols::ImmutableMap()));
  ASSERT(!map_class.IsNull());
  ASSERT(map_class.NumTypeArguments() == 2);

  const dart::Field& field = dart::Field::Handle(
      Z, map_class.LookupInstanceFieldAllowPrivate(H.DartSymbol("_kvPairs")));
  ASSERT(!field.IsNull());

  // NOTE: This needs to be kept in sync with `runtime/lib/immutable_map.dart`!
  result_ = Instance::New(map_class, Heap::kOld);
  ASSERT(!result_.IsNull());
  result_.SetTypeArguments(type_arguments);
  result_.SetField(field, const_kv_array);
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitConstructorInvocation(
    ConstructorInvocation* node) {
  Arguments* kernel_arguments = node->arguments();

  const Function& constructor = Function::Handle(
      Z, H.LookupConstructorByKernelConstructor(node->target()));
  dart::Class& klass = dart::Class::Handle(Z, constructor.Owner());

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(constructor, &klass, kernel_arguments);

  // Prepare either the instance or the type argument vector for the constructor
  // call.
  Instance* receiver = NULL;
  const TypeArguments* type_arguments_argument = NULL;
  if (!constructor.IsFactory()) {
    receiver = &Instance::ZoneHandle(Z, Instance::New(klass, Heap::kOld));
    if (type_arguments != NULL) {
      receiver->SetTypeArguments(*type_arguments);
    }
  } else {
    type_arguments_argument = type_arguments;
  }

  const Object& result = RunFunction(constructor, kernel_arguments, receiver,
                                     type_arguments_argument);
  if (constructor.IsFactory()) {
    // Factories return the new object.
    result_ ^= result.raw();
    result_ = H.Canonicalize(result_);
  } else {
    ASSERT(!receiver->IsNull());
    result_ = H.Canonicalize(*receiver);
  }
}


void ConstantEvaluator::VisitMethodInvocation(MethodInvocation* node) {
  Arguments* kernel_arguments = node->arguments();

  // Dart does not support generic methods yet.
  ASSERT(kernel_arguments->types().length() == 0);

  const Instance& receiver = EvaluateExpression(node->receiver());
  dart::Class& klass = dart::Class::Handle(
      Z, isolate_->class_table()->At(receiver.GetClassId()));
  ASSERT(!klass.IsNull());

  // Search the superclass chain for the selector.
  Function& function = Function::Handle(Z);
  const dart::String& method_name = H.DartMethodName(node->name());
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunctionAllowPrivate(method_name);
    if (!function.IsNull()) break;
    klass = klass.SuperClass();
  }

  // The frontend should guarantee that [MethodInvocation]s inside constant
  // expressions are always valid.
  ASSERT(!function.IsNull());

  // Run the method and canonicalize the result.
  const Object& result = RunFunction(function, kernel_arguments, &receiver);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitStaticGet(StaticGet* node) {
  NameIndex target = node->target();
  if (H.IsField(target)) {
    const dart::Field& field =
        dart::Field::Handle(Z, H.LookupFieldByKernelField(target));
    if (field.StaticValue() == Object::sentinel().raw() ||
        field.StaticValue() == Object::transition_sentinel().raw()) {
      field.EvaluateInitializer();
      result_ = field.StaticValue();
      result_ = H.Canonicalize(result_);
      field.SetStaticValue(result_, true);
    } else {
      result_ = field.StaticValue();
    }
  } else if (H.IsProcedure(target)) {
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));

    if (H.IsMethod(target)) {
      Function& closure_function =
          Function::ZoneHandle(Z, function.ImplicitClosureFunction());
      closure_function.set_kernel_function(function.kernel_function());
      result_ = closure_function.ImplicitStaticClosure();
      result_ = H.Canonicalize(result_);
    } else if (H.IsGetter(target)) {
      UNIMPLEMENTED();
    } else {
      UNIMPLEMENTED();
    }
  }
}


void ConstantEvaluator::VisitVariableGet(VariableGet* node) {
  // When we see a [VariableGet] the corresponding [VariableDeclaration] must've
  // been executed already. It therefore must have a constant object associated
  // with it.
  LocalVariable* variable = builder_->LookupVariable(node->variable());
  ASSERT(variable->IsConst());
  result_ = variable->ConstValue()->raw();
}


void ConstantEvaluator::VisitLet(Let* node) {
  VariableDeclaration* variable = node->variable();
  LocalVariable* local = builder_->LookupVariable(variable);
  local->SetConstValue(EvaluateExpression(variable->initializer()));
  node->body()->AcceptExpressionVisitor(this);
}


void ConstantEvaluator::VisitStaticInvocation(StaticInvocation* node) {
  const Function& function = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(node->procedure()));
  dart::Class& klass = dart::Class::Handle(Z, function.Owner());

  // Build the type arguments vector (if necessary).
  const TypeArguments* type_arguments =
      TranslateTypeArguments(function, &klass, node->arguments());

  const Object& result =
      RunFunction(function, node->arguments(), NULL, type_arguments);
  result_ ^= result.raw();
  result_ = H.Canonicalize(result_);
}


void ConstantEvaluator::VisitStringConcatenation(StringConcatenation* node) {
  intptr_t length = node->expressions().length();

  bool all_string = true;
  const Array& strings = Array::Handle(Z, Array::New(length));
  for (intptr_t i = 0; i < length; i++) {
    EvaluateExpression(node->expressions()[i]);
    strings.SetAt(i, result_);
    all_string = all_string && result_.IsString();
  }
  if (all_string) {
    result_ = dart::String::ConcatAll(strings, Heap::kOld);
    result_ = H.Canonicalize(result_);
  } else {
    // Get string interpolation function.
    const dart::Class& cls = dart::Class::Handle(
        Z, dart::Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& func = Function::Handle(
        Z, cls.LookupStaticFunction(
               dart::Library::PrivateCoreLibName(Symbols::Interpolate())));
    ASSERT(!func.IsNull());

    // Build argument array to pass to the interpolation function.
    const Array& interpolate_arg = Array::Handle(Z, Array::New(1, Heap::kOld));
    interpolate_arg.SetAt(0, strings);

    // Run and canonicalize.
    const Object& result =
        RunFunction(func, interpolate_arg, Array::null_array());
    result_ = H.Canonicalize(dart::String::Cast(result));
  }
}


void ConstantEvaluator::VisitConditionalExpression(
    ConditionalExpression* node) {
  if (EvaluateBooleanExpression(node->condition())) {
    EvaluateExpression(node->then());
  } else {
    EvaluateExpression(node->otherwise());
  }
}


void ConstantEvaluator::VisitLogicalExpression(LogicalExpression* node) {
  if (node->op() == LogicalExpression::kAnd) {
    if (EvaluateBooleanExpression(node->left())) {
      EvaluateBooleanExpression(node->right());
    }
  } else {
    ASSERT(node->op() == LogicalExpression::kOr);
    if (!EvaluateBooleanExpression(node->left())) {
      EvaluateBooleanExpression(node->right());
    }
  }
}


void ConstantEvaluator::VisitNot(Not* node) {
  result_ ^= Bool::Get(!EvaluateBooleanExpression(node->expression())).raw();
}


void ConstantEvaluator::VisitPropertyGet(PropertyGet* node) {
  StringIndex string_index = node->name()->string_index();
  if (H.StringEquals(string_index, "length")) {
    node->receiver()->AcceptExpressionVisitor(this);
    if (result_.IsString()) {
      const dart::String& str =
          dart::String::Handle(Z, dart::String::RawCast(result_.raw()));
      result_ = Integer::New(str.Length());
    } else {
      H.ReportError(
          "Constant expressions can only call "
          "'length' on string constants.");
    }
  } else {
    VisitDefaultExpression(node);
  }
}


const TypeArguments* ConstantEvaluator::TranslateTypeArguments(
    const Function& target,
    dart::Class* target_klass,
    Arguments* kernel_arguments) {
  List<DartType>& kernel_type_arguments = kernel_arguments->types();

  const TypeArguments* type_arguments = NULL;
  if (kernel_type_arguments.length() > 0) {
    type_arguments = &T.TranslateInstantiatedTypeArguments(
        *target_klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());

    if (!(type_arguments->IsNull() || type_arguments->IsInstantiated())) {
      H.ReportError("Type must be constant in const constructor.");
    }
  } else if (target.IsFactory() && type_arguments == NULL) {
    // All factories take a type arguments vector as first argument (independent
    // of whether the class is generic or not).
    type_arguments = &TypeArguments::ZoneHandle(Z, TypeArguments::null());
  }
  return type_arguments;
}


const Object& ConstantEvaluator::RunFunction(const Function& function,
                                             Arguments* kernel_arguments,
                                             const Instance* receiver,
                                             const TypeArguments* type_args) {
  // We do not support generic methods yet.
  ASSERT((receiver == NULL) || (type_args == NULL));
  intptr_t extra_arguments =
      (receiver != NULL ? 1 : 0) + (type_args != NULL ? 1 : 0);

  // Build up arguments.
  const Array& arguments = Array::ZoneHandle(
      Z, Array::New(extra_arguments + kernel_arguments->count()));
  const Array& names =
      Array::ZoneHandle(Z, Array::New(kernel_arguments->named().length()));
  intptr_t pos = 0;
  if (receiver != NULL) {
    arguments.SetAt(pos++, *receiver);
  }
  if (type_args != NULL) {
    arguments.SetAt(pos++, *type_args);
  }
  for (intptr_t i = 0; i < kernel_arguments->positional().length(); i++) {
    EvaluateExpression(kernel_arguments->positional()[i]);
    arguments.SetAt(pos++, result_);
  }
  for (intptr_t i = 0; i < kernel_arguments->named().length(); i++) {
    NamedExpression* named_expression = kernel_arguments->named()[i];
    EvaluateExpression(named_expression->expression());
    arguments.SetAt(pos++, result_);
    names.SetAt(i, H.DartSymbol(named_expression->name()));
  }
  return RunFunction(function, arguments, names);
}


const Object& ConstantEvaluator::RunFunction(const Function& function,
                                             const Array& arguments,
                                             const Array& names) {
  const int kTypeArgsLen = 0;  // Generic functions not yet supported.
  const Array& args_descriptor = Array::Handle(
      Z, ArgumentsDescriptor::New(kTypeArgsLen, arguments.Length(), names));
  const Object& result = Object::Handle(
      Z, DartEntry::InvokeFunction(function, arguments, args_descriptor));
  if (result.IsError()) {
    H.ReportError(Error::Cast(result), "error evaluating constant constructor");
  }
  return result;
}


FlowGraphBuilder::FlowGraphBuilder(
    TreeNode* node,
    ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    ZoneGrowableArray<intptr_t>* context_level_array,
    InlineExitCollector* exit_collector,
    intptr_t osr_id,
    intptr_t first_block_id)
    : translation_helper_(Thread::Current()),
      thread_(translation_helper_.thread()),
      zone_(translation_helper_.zone()),
      node_(node),
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
      type_translator_(&translation_helper_,
                       &active_class_,
                       /* finalize= */ true),
      constant_evaluator_(this, zone_, &translation_helper_, &type_translator_),
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

    Statement* finalizer = try_finally_block_->finalizer();
    intptr_t finalizer_kernel_offset =
        try_finally_block_->finalizer_kernel_offset();
    try_finally_block_ = try_finally_block_->outer();
    if (finalizer != NULL) {
      // This will potentially have exceptional cases as described in
      // [VisitTryFinally] and will handle them.
      instructions += TranslateStatement(finalizer);
    } else {
      instructions += streaming_flow_graph_builder_->BuildStatementAt(
          finalizer_kernel_offset);
    }

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


Fragment FlowGraphBuilder::EnterScope(TreeNode* node, bool* new_context) {
  return EnterScope(node->kernel_offset(), new_context);
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


Fragment FlowGraphBuilder::ExitScope(TreeNode* node) {
  return ExitScope(node->kernel_offset());
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
             active_class_.kernel_class != NULL &&
             active_class_.kernel_class->type_parameters().length() > 0) {
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


Fragment FlowGraphBuilder::AllocateObject(const dart::Class& klass,
                                          intptr_t argument_count) {
  ArgumentArray arguments = GetArguments(argument_count);
  AllocateObjectInstr* allocate =
      new (Z) AllocateObjectInstr(TokenPosition::kNoSource, klass, arguments);
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
                                        intptr_t num_args_checked) {
  return InstanceCall(position, name, kind, argument_count, Array::null_array(),
                      num_args_checked);
}


Fragment FlowGraphBuilder::InstanceCall(TokenPosition position,
                                        const dart::String& name,
                                        Token::Kind kind,
                                        intptr_t argument_count,
                                        const Array& argument_names,
                                        intptr_t num_args_checked) {
  ArgumentArray arguments = GetArguments(argument_count);
  const intptr_t kTypeArgsLen = 0;  // Generic instance calls not yet supported.
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      position, name, kind, arguments, kTypeArgsLen, argument_names,
      num_args_checked, ic_data_array_, GetNextDeoptId());
  Push(call);
  return Fragment(call);
}


Fragment FlowGraphBuilder::ClosureCall(int argument_count,
                                       const Array& argument_names) {
  Value* function = Pop();
  ArgumentArray arguments = GetArguments(argument_count);
  const intptr_t kTypeArgsLen = 0;  // Generic closures not yet supported.
  ClosureCallInstr* call = new (Z)
      ClosureCallInstr(function, arguments, kTypeArgsLen, argument_names,
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
  instructions += AllocateObject(klass, 0);
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


LocalVariable* FlowGraphBuilder::LookupVariable(VariableDeclaration* var) {
  LocalVariable* local = scopes_->locals.Lookup(var->kernel_offset_no_tag());
  ASSERT(local != NULL);
  return local;
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

  TreeNode* library_node = node_;
  if (node_ != NULL) {
    const Function* parent = &function;
    while (true) {
      library_node = static_cast<kernel::TreeNode*>(parent->kernel_function());
      while (library_node != NULL && !library_node->IsLibrary()) {
        if (library_node->IsMember()) {
          library_node = Member::Cast(library_node)->parent();
        } else if (library_node->IsClass()) {
          library_node = Class::Cast(library_node)->parent();
          break;
        } else {
          library_node = NULL;
          break;
        }
      }
      if (library_node != NULL) break;
      parent = &Function::Handle(parent->parent_function());
    }
  }
  if (streaming_flow_graph_builder_ != NULL) {
    delete streaming_flow_graph_builder_;
    streaming_flow_graph_builder_ = NULL;
  }
  if (library_node != NULL && library_node->IsLibrary()) {
    Library* library = Library::Cast(library_node);
    streaming_flow_graph_builder_ = new StreamingFlowGraphBuilder(
        this, library->kernel_data(), library->kernel_data_size());
  }

  dart::Class& klass =
      dart::Class::Handle(zone_, parsed_function_->function().Owner());

  Function& outermost_function = Function::Handle(Z);
  TreeNode* outermost_node = NULL;
  Class* kernel_class = NULL;
  DiscoverEnclosingElements(Z, function, &outermost_function, &outermost_node,
                            &kernel_class);

  // Mark that we are using [klass]/[kernell_klass] as active class.  Resolving
  // of type parameters will get resolved via [kernell_klass] unless we are
  // nested inside a static factory in which case we will use [member].
  ActiveClassScope active_class_scope(&active_class_, kernel_class, &klass);
  Member* member = ((outermost_node != NULL) && outermost_node->IsMember())
                       ? Member::Cast(outermost_node)
                       : NULL;
  ActiveMemberScope active_member(&active_class_, member);

  // The IR builder will create its own local variables and scopes, and it
  // will not need an AST.  The code generator will assume that there is a
  // local variable stack slot allocated for the current context and (I
  // think) that the runtime will expect it to be at a fixed offset which
  // requires allocating an unused expression temporary variable.
  scopes_ = parsed_function_->EnsureKernelScopes();

  switch (function.kind()) {
    case RawFunction::kClosureFunction:
    case RawFunction::kRegularFunction:
    case RawFunction::kGetterFunction:
    case RawFunction::kSetterFunction: {
      FunctionNode* kernel_function = node_->IsProcedure()
                                          ? Procedure::Cast(node_)->function()
                                          : FunctionNode::Cast(node_);
      return function.IsImplicitClosureFunction()
                 ? BuildGraphOfImplicitClosureFunction(kernel_function,
                                                       function)
                 : BuildGraphOfFunction(kernel_function);
    }
    case RawFunction::kConstructor: {
      bool is_factory = function.IsFactory();
      if (is_factory) {
        Procedure* procedure = Procedure::Cast(node_);
        FunctionNode* function = procedure->function();
        return BuildGraphOfFunction(function, NULL);
      } else {
        Constructor* constructor = Constructor::Cast(node_);
        FunctionNode* function = constructor->function();
        return BuildGraphOfFunction(function, constructor);
      }
    }
    case RawFunction::kImplicitGetter:
    case RawFunction::kImplicitStaticFinalGetter:
    case RawFunction::kImplicitSetter: {
      Field* field = Field::Cast(node_);
      return IsStaticInitializer(function, Z)
                 ? BuildGraphOfStaticFieldInitializer(field)
                 : BuildGraphOfFieldAccessor(field, scopes_->setter_value);
    }
    case RawFunction::kMethodExtractor:
      return BuildGraphOfMethodExtractor(function);
    case RawFunction::kNoSuchMethodDispatcher:
      return BuildGraphOfNoSuchMethodDispatcher(function);
    case RawFunction::kInvokeFieldDispatcher:
      return BuildGraphOfInvokeFieldDispatcher(function);
    case RawFunction::kSignatureFunction:
    case RawFunction::kIrregexpFunction:
      break;
  }
  UNREACHABLE();
  return NULL;
}


FlowGraph* FlowGraphBuilder::BuildGraphOfFunction(FunctionNode* function,
                                                  Constructor* constructor) {
  const Function& dart_function = parsed_function_->function();
  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ =
      new (Z) GraphEntryInstr(*parsed_function_, normal_entry, osr_id_);

  SetupDefaultParameterValues(function);

  Fragment body;
  if (!dart_function.is_native()) body += CheckStackOverflowInPrologue();
  intptr_t context_size =
      parsed_function_->node_sequence()->scope()->num_context_variables();
  if (context_size > 0) {
    body += PushContext(context_size);
    LocalVariable* context = MakeTemporary();

    // Copy captured parameters from the stack into the context.
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    intptr_t parameter_count = dart_function.NumParameters();
    intptr_t parameter_index = parsed_function_->first_parameter_index();
    for (intptr_t i = 0; i < parameter_count; ++i, --parameter_index) {
      LocalVariable* variable = scope->VariableAt(i);
      if (variable->is_captured()) {
        // There is no LocalVariable describing the on-stack parameter so
        // create one directly and use the same type.
        LocalVariable* parameter = new (Z)
            LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                          Symbols::TempParam(), variable->type());
        parameter->set_index(parameter_index);
        // Mark the stack variable so it will be ignored by the code for
        // try/catch.
        parameter->set_is_captured_parameter(true);

        // Copy the parameter from the stack to the context.  Overwrite it
        // with a null constant on the stack so the original value is
        // eligible for garbage collection.
        body += LoadLocal(context);
        body += LoadLocal(parameter);
        body += StoreInstanceField(TokenPosition::kNoSource,
                                   Context::variable_offset(variable->index()));
        body += NullConstant();
        body += StoreLocal(TokenPosition::kNoSource, parameter);
        body += Drop();
      }
    }
    body += Drop();  // The context.
  }
  if (constructor != NULL) {
    // TODO(27590): Currently the [VariableDeclaration]s from the
    // initializers will be visible inside the entire body of the constructor.
    // We should make a separate scope for them.
    Class* kernel_class = Class::Cast(constructor->parent());
    body += TranslateInitializers(kernel_class, &constructor->initializers());
  }

  // The specification defines the result of `a == b` to be:
  //
  //   a) if either side is `null` then the result is `identical(a, b)`.
  //   b) else the result is `a.operator==(b)`
  //
  // For user-defined implementations of `operator==` we need therefore
  // implement the handling of a).
  //
  // The default `operator==` implementation in `Object` is implemented in terms
  // of identical (which we assume here!) which means that case a) is actually
  // included in b).  So we just use the normal implementation in the body.
  if ((dart_function.NumParameters() == 2) &&
      (dart_function.name() == Symbols::EqualOperator().raw()) &&
      (dart_function.Owner() != I->object_store()->object_class())) {
    LocalVariable* parameter =
        LookupVariable(function->positional_parameters()[0]);

    TargetEntryInstr* null_entry;
    TargetEntryInstr* non_null_entry;

    body += LoadLocal(parameter);
    body += BranchIfNull(&null_entry, &non_null_entry);

    // The argument was `null` and the receiver is not the null class (we only
    // go into this branch for user-defined == operators) so we can return
    // false.
    Fragment null_fragment(null_entry);
    null_fragment += Constant(Bool::False());
    null_fragment += Return(dart_function.end_token_pos());

    body = Fragment(body.entry, non_null_entry);
  }

  // If we run in checked mode, we have to check the type of the passed
  // arguments.
  if (I->type_checks()) {
    List<VariableDeclaration>& positional = function->positional_parameters();
    List<VariableDeclaration>& named = function->named_parameters();

    for (intptr_t i = 0; i < positional.length(); i++) {
      VariableDeclaration* variable = positional[i];
      body += LoadLocal(LookupVariable(variable));
      body += CheckVariableTypeInCheckedMode(variable);
      body += Drop();
    }
    for (intptr_t i = 0; i < named.length(); i++) {
      VariableDeclaration* variable = named[i];
      body += LoadLocal(LookupVariable(variable));
      body += CheckVariableTypeInCheckedMode(variable);
      body += Drop();
    }
  }

  if (FLAG_causal_async_stacks &&
      (dart_function.IsAsyncFunction() || dart_function.IsAsyncGenerator())) {
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    // :async_stack_trace = _asyncStackTraceHelper(:async_op);
    const dart::Library& async_lib =
        dart::Library::Handle(dart::Library::AsyncLibrary());
    const Function& target = Function::ZoneHandle(
        Z,
        async_lib.LookupFunctionAllowPrivate(Symbols::AsyncStackTraceHelper()));
    ASSERT(!target.IsNull());

    // TODO(johnmccutchan): Why does this have the null value?
    LocalVariable* async_op =
        scope->child()->LookupVariable(Symbols::AsyncOperation(), false);
    ASSERT(async_op != NULL);
    ASSERT(async_op->is_captured());
    body += LoadLocal(async_op);
    body += PushArgument();
    body += StaticCall(TokenPosition::kNoSource, target, 1);
    LocalVariable* async_stack_trace_var =
        scope->LookupVariable(Symbols::AsyncStackTraceVar(), false);
    ASSERT(async_stack_trace_var != NULL);
    body += StoreLocal(TokenPosition::kNoSource, async_stack_trace_var);
    body += Drop();
  }

  if (dart_function.is_native()) {
    body += NativeFunctionBody(function, dart_function);
  } else if (function->body() != NULL) {
    body += TranslateStatement(function->body());
  }
  if (body.is_open()) {
    body += NullConstant();
    body += Return(dart_function.end_token_pos());
  }

  // If functions body contains any yield points build switch statement that
  // selects a continuation point based on the value of :await_jump_var.
  if (!yield_continuations_.is_empty()) {
    // The code we are building will be executed right after we enter
    // the function and before any nested contexts are allocated.
    // Reset current context_depth_ to match this.
    const intptr_t current_context_depth = context_depth_;
    context_depth_ = scopes_->yield_jump_variable->owner()->context_level();

    // Prepend an entry corresponding to normal entry to the function.
    yield_continuations_.InsertAt(
        0, YieldContinuation(new (Z) DropTempsInstr(0, NULL),
                             CatchClauseNode::kInvalidTryIndex));
    yield_continuations_[0].entry->LinkTo(body.entry);

    // Build a switch statement.
    Fragment dispatch;

    // Load :await_jump_var into a temporary.
    dispatch += LoadLocal(scopes_->yield_jump_variable);
    dispatch += StoreLocal(TokenPosition::kNoSource, scopes_->switch_variable);
    dispatch += Drop();

    BlockEntryInstr* block = NULL;
    for (intptr_t i = 0; i < yield_continuations_.length(); i++) {
      if (i == 1) {
        // This is not a normal entry but a resumption.  Restore
        // :current_context_var from :await_ctx_var.
        // Note: after this point context_depth_ does not match current context
        // depth so we should not access any local variables anymore.
        dispatch += LoadLocal(scopes_->yield_context_variable);
        dispatch += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->current_context_var());
        dispatch += Drop();
      }
      if (i == (yield_continuations_.length() - 1)) {
        // We reached the last possility, no need to build more ifs.
        // Continue to the last continuation.
        // Note: continuations start with nop DropTemps instruction
        // which acts like an anchor, so we need to skip it.
        block->set_try_index(yield_continuations_[i].try_index);
        dispatch <<= yield_continuations_[i].entry->next();
        break;
      }

      // Build comparison:
      //
      //   if (:await_ctx_var == i) {
      //     -> yield_continuations_[i]
      //   } else ...
      //
      TargetEntryInstr* then;
      TargetEntryInstr* otherwise;
      dispatch += LoadLocal(scopes_->switch_variable);
      dispatch += IntConstant(i);
      dispatch += BranchIfStrictEqual(&then, &otherwise);

      // True branch is linked to appropriate continuation point.
      // Note: continuations start with nop DropTemps instruction
      // which acts like an anchor, so we need to skip it.
      then->LinkTo(yield_continuations_[i].entry->next());
      then->set_try_index(yield_continuations_[i].try_index);
      // False branch will contain the next comparison.
      dispatch = Fragment(dispatch.entry, otherwise);
      block = otherwise;
    }
    body = dispatch;

    context_depth_ = current_context_depth;
  }

  if (FLAG_causal_async_stacks &&
      (dart_function.IsAsyncClosure() || dart_function.IsAsyncGenClosure())) {
    // The code we are building will be executed right after we enter
    // the function and before any nested contexts are allocated.
    // Reset current context_depth_ to match this.
    const intptr_t current_context_depth = context_depth_;
    context_depth_ = scopes_->yield_jump_variable->owner()->context_level();

    Fragment instructions;
    LocalScope* scope = parsed_function_->node_sequence()->scope();

    const Function& target = Function::ZoneHandle(
        Z, I->object_store()->async_set_thread_stack_trace());
    ASSERT(!target.IsNull());

    // Fetch and load :async_stack_trace
    LocalVariable* async_stack_trace_var =
        scope->LookupVariable(Symbols::AsyncStackTraceVar(), false);
    ASSERT((async_stack_trace_var != NULL) &&
           async_stack_trace_var->is_captured());
    instructions += LoadLocal(async_stack_trace_var);
    instructions += PushArgument();

    // Call _asyncSetThreadStackTrace
    instructions += StaticCall(TokenPosition::kNoSource, target, 1);
    instructions += Drop();

    // TODO(29737): This sequence should be generated in order.
    body = instructions + body;
    context_depth_ = current_context_depth;
  }

  if (NeedsDebugStepCheck(dart_function, function->position())) {
    const intptr_t current_context_depth = context_depth_;
    context_depth_ = 0;

    // If a switch was added above: Start the switch by injecting a debuggable
    // safepoint so stepping over an await works.
    // If not, still start the body with a debuggable safepoint to ensure
    // breaking on a method always happens, even if there are no
    // assignments/calls/runtimecalls in the first basic block.
    // Place this check at the last parameter to ensure parameters
    // are in scope in the debugger at method entry.
    const int num_params = dart_function.NumParameters();
    TokenPosition check_pos = TokenPosition::kNoSource;
    if (num_params > 0) {
      LocalScope* scope = parsed_function_->node_sequence()->scope();
      const LocalVariable& parameter = *scope->VariableAt(num_params - 1);
      check_pos = parameter.token_pos();
    }
    if (!check_pos.IsDebugPause()) {
      // No parameters or synthetic parameters.
      check_pos = function->position();
      ASSERT(check_pos.IsDebugPause());
    }

    // TODO(29737): This sequence should be generated in order.
    body = DebugStepCheck(check_pos) + body;
    context_depth_ = current_context_depth;
  }

  normal_entry->LinkTo(body.entry);

  // When compiling for OSR, use a depth first search to prune instructions
  // unreachable from the OSR entry. Catch entries are always considered
  // reachable, even if they become unreachable after OSR.
  if (osr_id_ != Compiler::kNoOSRDeoptId) {
    BitVector* block_marks = new (Z) BitVector(Z, next_block_id_);
    bool found = graph_entry_->PruneUnreachable(graph_entry_, NULL, osr_id_,
                                                block_marks);
    ASSERT(found);
  }
  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


Fragment FlowGraphBuilder::NativeFunctionBody(FunctionNode* kernel_function,
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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
      body += LoadLocal(
          LookupVariable(kernel_function->positional_parameters()[0]));
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


FlowGraph* FlowGraphBuilder::BuildGraphOfFieldAccessor(
    Field* kernel_field,
    LocalVariable* setter_value) {
  const Function& function = parsed_function_->function();

  bool is_setter = function.IsImplicitSetterFunction();
  bool is_method = !function.IsStaticFunction();
  dart::Field& field = dart::Field::ZoneHandle(
      Z, H.LookupFieldByKernelField(kernel_field->canonical_name()));

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  if (is_setter) {
    if (is_method) {
      body += LoadLocal(scopes_->this_variable);
      body += LoadLocal(setter_value);
      body += StoreInstanceFieldGuarded(field, false);
    } else {
      body += LoadLocal(setter_value);
      body += StoreStaticField(TokenPosition::kNoSource, field);
    }
    body += NullConstant();
  } else if (is_method) {
    body += LoadLocal(scopes_->this_variable);
    body += LoadField(field);
  } else if (field.is_const()) {
    // If the parser needs to know the value of an uninitialized constant field
    // it will set the value to the transition sentinel (used to detect circular
    // initialization) and then call the implicit getter.  Thus, the getter
    // cannot contain the InitStaticField instruction that normal static getters
    // contain because it would detect spurious circular initialization when it
    // checks for the transition sentinel.
    Expression* initializer = kernel_field->initializer();
    ASSERT(initializer != NULL);
    body += Constant(constant_evaluator_.EvaluateExpression(initializer));
  } else {
    // The field always has an initializer because static fields without
    // initializers are initialized eagerly and do not have implicit getters.
    ASSERT(field.has_initializer());
    body += Constant(field);
    body += InitStaticField(field);
    body += Constant(field);
    body += LoadStaticField();
  }
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


FlowGraph* FlowGraphBuilder::BuildGraphOfStaticFieldInitializer(
    Field* kernel_field) {
  ASSERT(kernel_field->IsStatic());

  Expression* initializer = kernel_field->initializer();

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();
  if (kernel_field->IsConst()) {
    body += Constant(constant_evaluator_.EvaluateExpression(initializer));
  } else {
    body += TranslateExpression(initializer);
  }
  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
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
    VariableDeclaration* variable) {
  if (I->type_checks()) {
    const AbstractType& dst_type = T.TranslateType(variable->type());
    if (dst_type.IsMalformed()) {
      return ThrowTypeError();
    }
    return CheckAssignableInCheckedMode(dst_type,
                                        H.DartSymbol(variable->name()));
  }
  return Fragment();
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


FlowGraph* FlowGraphBuilder::BuildGraphOfImplicitClosureFunction(
    FunctionNode* kernel_function,
    const Function& function) {
  const Function& target = Function::ZoneHandle(Z, function.parent_function());

  TargetEntryInstr* normal_entry = BuildTargetEntry();
  graph_entry_ = new (Z)
      GraphEntryInstr(*parsed_function_, normal_entry, Compiler::kNoOSRDeoptId);
  SetupDefaultParameterValues(kernel_function);

  Fragment body(normal_entry);
  body += CheckStackOverflowInPrologue();

  // Load all the arguments.
  if (!target.is_static()) {
    // The context has a fixed shape: a single variable which is the
    // closed-over receiver.
    body += LoadLocal(parsed_function_->current_context_var());
    body += LoadField(Context::variable_offset(0));
    body += PushArgument();
  }
  intptr_t positional_argument_count =
      kernel_function->positional_parameters().length();
  for (intptr_t i = 0; i < positional_argument_count; i++) {
    body +=
        LoadLocal(LookupVariable(kernel_function->positional_parameters()[i]));
    body += PushArgument();
  }
  intptr_t named_argument_count = kernel_function->named_parameters().length();
  Array& argument_names = Array::ZoneHandle(Z);
  if (named_argument_count > 0) {
    argument_names = Array::New(named_argument_count);
    for (intptr_t i = 0; i < named_argument_count; i++) {
      VariableDeclaration* variable = kernel_function->named_parameters()[i];
      body += LoadLocal(LookupVariable(variable));
      body += PushArgument();
      argument_names.SetAt(i, H.DartSymbol(variable->name()));
    }
  }
  // Forward them to the target.
  intptr_t argument_count = positional_argument_count + named_argument_count;
  if (!target.is_static()) ++argument_count;
  body += StaticCall(TokenPosition::kNoSource, target, argument_count,
                     argument_names);

  // Return the result.
  body += Return(kernel_function->end_position());

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

    body += ClosureCall(descriptor.Count(), argument_names);
  } else {
    body += InstanceCall(TokenPosition::kMinSource, Symbols::Call(),
                         Token::kILLEGAL, descriptor.Count(), argument_names);
  }

  body += Return(TokenPosition::kNoSource);

  return new (Z) FlowGraph(*parsed_function_, graph_entry_, next_block_id_ - 1);
}


void FlowGraphBuilder::SetupDefaultParameterValues(FunctionNode* function) {
  intptr_t num_optional_parameters =
      parsed_function_->function().NumOptionalParameters();
  if (num_optional_parameters > 0) {
    ZoneGrowableArray<const Instance*>* default_values =
        new ZoneGrowableArray<const Instance*>(Z, num_optional_parameters);

    if (parsed_function_->function().HasOptionalNamedParameters()) {
      ASSERT(!parsed_function_->function().HasOptionalPositionalParameters());
      for (intptr_t i = 0; i < num_optional_parameters; i++) {
        VariableDeclaration* variable = function->named_parameters()[i];
        Instance* default_value;
        if (variable->initializer() != NULL) {
          default_value =
              &constant_evaluator_.EvaluateExpression(variable->initializer());
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    } else {
      ASSERT(parsed_function_->function().HasOptionalPositionalParameters());
      intptr_t required = function->required_parameter_count();
      for (intptr_t i = 0; i < num_optional_parameters; i++) {
        VariableDeclaration* variable =
            function->positional_parameters()[required + i];
        Instance* default_value;
        if (variable->initializer() != NULL) {
          default_value =
              &constant_evaluator_.EvaluateExpression(variable->initializer());
        } else {
          default_value = &Instance::ZoneHandle(Z, Instance::null());
        }
        default_values->Add(default_value);
      }
    }
    parsed_function_->set_default_parameter_values(default_values);
  }
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


Fragment FlowGraphBuilder::TranslateFieldInitializer(NameIndex canonical_name,
                                                     Expression* init) {
  dart::Field& field =
      dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(canonical_name));
  if (init->IsNullLiteral()) {
    field.RecordStore(Object::null_object());
    return Fragment();
  }
  Fragment instructions;
  instructions += LoadLocal(scopes_->this_variable);
  instructions += TranslateExpression(init);
  instructions += StoreInstanceFieldGuarded(field, true);
  return instructions;
}


Fragment FlowGraphBuilder::TranslateInitializers(
    Class* kernel_class,
    List<Initializer>* initializers) {
  Fragment instructions;

  // These come from:
  //   class A {
  //     var x = (expr);
  //   }
  for (intptr_t i = 0; i < kernel_class->fields().length(); i++) {
    Field* kernel_field = kernel_class->fields()[i];
    Expression* init = kernel_field->initializer();
    if (!kernel_field->IsStatic() && init != NULL) {
      EnterScope(kernel_field);
      instructions +=
          TranslateFieldInitializer(kernel_field->canonical_name(), init);
      ExitScope(kernel_field);
    }
  }

  // These to come from:
  //   class A {
  //     var x;
  //     var y;
  //     A(this.x) : super(expr), y = (expr);
  //   }
  for (intptr_t i = 0; i < initializers->length(); i++) {
    Initializer* initializer = (*initializers)[i];
    if (initializer->IsFieldInitializer()) {
      FieldInitializer* init = FieldInitializer::Cast(initializer);
      instructions += TranslateFieldInitializer(init->field(), init->value());
    } else if (initializer->IsSuperInitializer()) {
      SuperInitializer* init = SuperInitializer::Cast(initializer);

      instructions += LoadLocal(scopes_->this_variable);
      instructions += PushArgument();

      ASSERT(init->arguments()->types().length() == 0);
      Array& argument_names = Array::ZoneHandle(Z);
      instructions += TranslateArguments(init->arguments(), &argument_names);

      const Function& target = Function::ZoneHandle(
          Z, H.LookupConstructorByKernelConstructor(init->target()));
      intptr_t argument_count = init->arguments()->count() + 1;
      instructions += StaticCall(TokenPosition::kNoSource, target,
                                 argument_count, argument_names);
      instructions += Drop();
    } else if (initializer->IsRedirectingInitializer()) {
      RedirectingInitializer* init = RedirectingInitializer::Cast(initializer);

      instructions += LoadLocal(scopes_->this_variable);
      instructions += PushArgument();

      ASSERT(init->arguments()->types().length() == 0);
      Array& argument_names = Array::ZoneHandle(Z);
      instructions += TranslateArguments(init->arguments(), &argument_names);

      const Function& target = Function::ZoneHandle(
          Z, H.LookupConstructorByKernelConstructor(init->target()));
      intptr_t argument_count = init->arguments()->count() + 1;
      instructions += StaticCall(TokenPosition::kNoSource, target,
                                 argument_count, argument_names);
      instructions += Drop();
    } else if (initializer->IsLocalInitializer()) {
      // The other initializers following this one might read the variable. This
      // is used e.g. for evaluating the arguments to a super call first, run
      // normal field initializers next and then make the actual super call:
      //
      //   The frontend converts
      //
      //      class A {
      //        var x;
      //        A(a, b) : super(a + b), x = 2*b {}
      //      }
      //
      //   to
      //
      //      class A {
      //        var x;
      //        A(a, b) : tmp = a + b, x = 2*b, super(tmp) {}
      //      }
      //
      // (This is strictly speaking not what one should do in terms of the
      //  specification but that is how it is currently implemented.)
      LocalInitializer* init = LocalInitializer::Cast(initializer);

      VariableDeclaration* declaration = init->variable();
      LocalVariable* variable = LookupVariable(declaration);
      Expression* initializer = init->variable()->initializer();
      ASSERT(initializer != NULL);
      ASSERT(!declaration->IsConst());

      instructions += TranslateExpression(initializer);
      instructions += StoreLocal(TokenPosition::kNoSource, variable);
      instructions += Drop();

      fragment_ = instructions;
    } else {
      UNIMPLEMENTED();
    }
  }
  return instructions;
}


Fragment FlowGraphBuilder::TranslateStatement(Statement* statement) {
#ifdef DEBUG
  intptr_t original_context_depth = context_depth_;
#endif

  // TODO(jensj): VariableDeclaration doesn't necessarily have a tag.
  if (statement->can_stream() &&
      statement->Type() != Node::kTypeVariableDeclaration) {
    fragment_ = streaming_flow_graph_builder_->BuildStatementAt(
        statement->kernel_offset());
  } else {
    statement->AcceptStatementVisitor(this);
  }
  DEBUG_ASSERT(context_depth_ == original_context_depth);
  return fragment_;
}


Fragment FlowGraphBuilder::TranslateCondition(Expression* expression,
                                              bool* negate) {
  *negate = expression->IsNot();
  Fragment instructions;
  if (*negate) {
    instructions += TranslateExpression(Not::Cast(expression)->expression());
  } else {
    instructions += TranslateExpression(expression);
  }
  instructions += CheckBooleanInCheckedMode();
  return instructions;
}


Fragment FlowGraphBuilder::TranslateExpression(Expression* expression) {
  if (expression->can_stream()) {
    fragment_ = streaming_flow_graph_builder_->BuildExpressionAt(
        expression->kernel_offset());
  } else {
    expression->AcceptExpressionVisitor(this);
  }
  return fragment_;
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


#define STREAM_EXPRESSION_IF_POSSIBLE(node)                                    \
  if (node->can_stream()) {                                                    \
    fragment_ = streaming_flow_graph_builder_->BuildExpressionAt(              \
        node->kernel_offset());                                                \
    return;                                                                    \
  }


void FlowGraphBuilder::VisitInvalidExpression(InvalidExpression* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitNullLiteral(NullLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitBoolLiteral(BoolLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitIntLiteral(IntLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitBigintLiteral(BigintLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitDoubleLiteral(DoubleLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitStringLiteral(StringLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitSymbolLiteral(SymbolLiteral* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


AbstractType& DartTypeTranslator::TranslateType(DartType* node) {
  node->AcceptDartTypeVisitor(this);

  // We return a new `ZoneHandle` here on purpose: The intermediate language
  // instructions do not make a copy of the handle, so we do it.
  return AbstractType::ZoneHandle(Z, result_.raw());
}


AbstractType& DartTypeTranslator::TranslateTypeWithoutFinalization(
    DartType* node) {
  bool saved_finalize = finalize_;
  finalize_ = false;
  AbstractType& result = TranslateType(node);
  finalize_ = saved_finalize;
  return result;
}


const AbstractType& DartTypeTranslator::TranslateVariableType(
    VariableDeclaration* variable) {
  AbstractType& abstract_type = TranslateType(variable->type());

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


void DartTypeTranslator::VisitInvalidType(InvalidType* node) {
  result_ = ClassFinalizer::NewFinalizedMalformedType(
      Error::Handle(Z),  // No previous error.
      Script::Handle(Z, Script::null()), TokenPosition::kNoSource,
      "[InvalidType] in Kernel IR.");
}


void DartTypeTranslator::VisitFunctionType(FunctionType* node) {
  // The spec describes in section "19.1 Static Types":
  //
  //     Any use of a malformed type gives rise to a static warning. A
  //     malformed type is then interpreted as dynamic by the static type
  //     checker and the runtime unless explicitly specified otherwise.
  //
  // So we convert malformed return/parameter types to `dynamic`.
  TypeParameterScope scope(this, &node->type_parameters());

  Function& signature_function = Function::ZoneHandle(
      Z, Function::NewSignatureFunction(*active_class_->klass,
                                        TokenPosition::kNoSource));

  node->return_type()->AcceptDartTypeVisitor(this);
  if (result_.IsMalformed()) {
    result_ = AbstractType::dynamic_type().raw();
  }
  signature_function.set_result_type(result_);

  const intptr_t positional_count = node->positional_parameters().length();
  const intptr_t named_count = node->named_parameters().length();
  const intptr_t all_count = positional_count + named_count;
  const intptr_t required_count = node->required_parameter_count();

  // The additional first parameter is the receiver type (set to dynamic).
  signature_function.set_num_fixed_parameters(1 + required_count);
  signature_function.SetNumOptionalParameters(
      all_count - required_count, positional_count > required_count);

  const Array& parameter_types =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_types(parameter_types);
  const Array& parameter_names =
      Array::Handle(Z, Array::New(1 + all_count, Heap::kOld));
  signature_function.set_parameter_names(parameter_names);

  intptr_t pos = 0;
  parameter_types.SetAt(pos, AbstractType::dynamic_type());
  parameter_names.SetAt(pos, H.DartSymbol("_receiver_"));
  pos++;
  for (intptr_t i = 0; i < positional_count; i++, pos++) {
    node->positional_parameters()[i]->AcceptDartTypeVisitor(this);
    if (result_.IsMalformed()) {
      result_ = AbstractType::dynamic_type().raw();
    }
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbol("noname"));
  }
  for (intptr_t i = 0; i < named_count; i++, pos++) {
    NamedParameter* parameter = node->named_parameters()[i];
    parameter->type()->AcceptDartTypeVisitor(this);
    if (result_.IsMalformed()) {
      result_ = AbstractType::dynamic_type().raw();
    }
    parameter_types.SetAt(pos, result_);
    parameter_names.SetAt(pos, H.DartSymbol(parameter->name()));
  }

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


static intptr_t FindTypeParameterIndex(List<TypeParameter>* parameters,
                                       TypeParameter* param) {
  for (intptr_t i = 0; i < parameters->length(); i++) {
    if (param == (*parameters)[i]) {
      return i;
    }
  }
  return -1;
}


void DartTypeTranslator::VisitTypeParameterType(TypeParameterType* node) {
  for (TypeParameterScope* scope = type_parameter_scope_; scope != NULL;
       scope = scope->outer()) {
    const intptr_t index =
        FindTypeParameterIndex(scope->parameters(), node->parameter());
    if (index >= 0) {
      result_ ^= dart::Type::DynamicType();
      return;
    }
  }

  if ((active_class_->member != NULL) && active_class_->member->IsProcedure()) {
    Procedure* procedure = Procedure::Cast(active_class_->member);
    if ((procedure->function() != NULL) &&
        (procedure->function()->type_parameters().length() > 0)) {
      //
      // WARNING: This is a little hackish:
      //
      // We have a static factory constructor. The kernel IR gives the factory
      // constructor function it's own type parameters (which are equal in name
      // and number to the ones of the enclosing class).
      // I.e.,
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
      const intptr_t index = FindTypeParameterIndex(
          &procedure->function()->type_parameters(), node->parameter());
      if (index >= 0) {
        if (procedure->kind() == Procedure::kFactory) {
          // The index of the type parameter in [parameters] is
          // the same index into the `klass->type_parameters()` array.
          result_ ^=
              TypeArguments::Handle(Z, active_class_->klass->type_parameters())
                  .TypeAt(index);
        } else {
          result_ ^= dart::Type::DynamicType();
        }
        return;
      }
    }
  }

  ASSERT(active_class_->kernel_class != NULL);
  List<TypeParameter>* parameters =
      &active_class_->kernel_class->type_parameters();
  const intptr_t index = FindTypeParameterIndex(parameters, node->parameter());
  if (index >= 0) {
    // The index of the type parameter in [parameters] is
    // the same index into the `klass->type_parameters()` array.
    result_ ^= TypeArguments::Handle(Z, active_class_->klass->type_parameters())
                   .TypeAt(index);
    return;
  }

  UNREACHABLE();
}


void DartTypeTranslator::VisitInterfaceType(InterfaceType* node) {
  // NOTE: That an interface type like `T<A, B>` is considered to be
  // malformed iff `T` is malformed.
  //   => We therefore ignore errors in `A` or `B`.
  const TypeArguments& type_arguments = TranslateTypeArguments(
      node->type_arguments().raw_array(), node->type_arguments().length());


  Object& klass = Object::Handle(Z, H.LookupClassByKernelClass(node->klass()));
  result_ = Type::New(klass, type_arguments, TokenPosition::kNoSource);
  if (finalize_) {
    ASSERT(active_class_->klass != NULL);
    result_ = ClassFinalizer::FinalizeType(*active_class_->klass, result_);
  }
}


void DartTypeTranslator::VisitDynamicType(DynamicType* node) {
  result_ = Object::dynamic_type().raw();
}


void DartTypeTranslator::VisitVoidType(VoidType* node) {
  result_ = Object::void_type().raw();
}


void DartTypeTranslator::VisitBottomType(BottomType* node) {
  result_ =
      dart::Class::Handle(Z, I->object_store()->null_class()).CanonicalType();
}


const TypeArguments& DartTypeTranslator::TranslateTypeArguments(
    DartType** dart_types,
    intptr_t length) {
  bool only_dynamic = true;
  for (intptr_t i = 0; i < length; i++) {
    if (!dart_types[i]->IsDynamicType()) {
      only_dynamic = false;
      break;
    }
  }
  TypeArguments& type_arguments = TypeArguments::ZoneHandle(Z);
  if (!only_dynamic) {
    type_arguments = TypeArguments::New(length);
    for (intptr_t i = 0; i < length; i++) {
      dart_types[i]->AcceptDartTypeVisitor(this);
      if (result_.IsMalformed()) {
        type_arguments = TypeArguments::null();
        return type_arguments;
      }
      type_arguments.SetTypeAt(i, result_);
    }
    if (finalize_) {
      type_arguments = type_arguments.Canonicalize();
    }
  }
  return type_arguments;
}


const TypeArguments& DartTypeTranslator::TranslateInstantiatedTypeArguments(
    const dart::Class& receiver_class,
    DartType** receiver_type_arguments,
    intptr_t length) {
  const TypeArguments& type_arguments =
      TranslateTypeArguments(receiver_type_arguments, length);
  if (type_arguments.IsNull()) return type_arguments;

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


const Type& DartTypeTranslator::ReceiverType(const dart::Class& klass) {
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

void FlowGraphBuilder::VisitTypeLiteral(TypeLiteral* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) H.ReportError("Malformed type literal");

  Fragment instructions;
  if (type.IsInstantiated()) {
    instructions += Constant(type);
  } else {
    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += InstantiateType(type);
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitVariableGet(VariableGet* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitVariableSet(VariableSet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->expression());
  if (NeedsDebugStepCheck(stack_, node->position())) {
    instructions = DebugStepCheck(node->position()) + instructions;
  }
  instructions += CheckVariableTypeInCheckedMode(node->variable());
  instructions +=
      StoreLocal(node->position(), LookupVariable(node->variable()));
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitStaticGet(StaticGet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  // A StaticGet will always have a kernel_offset, except for the StaticGet that
  // was manually created for _getMainClosure in dart:_builtin.  Compile that
  // one specially here.
  const dart::Library& builtin =
      dart::Library::Handle(Z, I->object_store()->builtin_library());
  const Object& main =
      Object::Handle(Z, builtin.LookupObjectAllowPrivate(dart::String::Handle(
                            Z, dart::String::New("main"))));
  if (main.IsField()) {
    UNIMPLEMENTED();
  } else if (main.IsFunction()) {
    const Function& function = Function::Cast(main);
    if (function.kind() == RawFunction::kRegularFunction) {
      const Function& closure_function =
          Function::Handle(Z, function.ImplicitClosureFunction());
      closure_function.set_kernel_function(function.kernel_function());
      const Instance& closure =
          Instance::ZoneHandle(Z, closure_function.ImplicitStaticClosure());
      fragment_ = Constant(closure);
    } else {
      UNIMPLEMENTED();
    }
  } else {
    UNIMPLEMENTED();
  }
}


void FlowGraphBuilder::VisitStaticSet(StaticSet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  NameIndex target = node->target();
  if (H.IsField(target)) {
    const dart::Field& field =
        dart::Field::ZoneHandle(Z, H.LookupFieldByKernelField(target));
    const AbstractType& dst_type = AbstractType::ZoneHandle(Z, field.type());
    Fragment instructions = TranslateExpression(node->expression());
    if (NeedsDebugStepCheck(stack_, node->position())) {
      instructions = DebugStepCheck(node->position()) + instructions;
    }
    instructions += CheckAssignableInCheckedMode(
        dst_type, dart::String::ZoneHandle(Z, field.name()));
    LocalVariable* variable = MakeTemporary();
    instructions += LoadLocal(variable);
    fragment_ = instructions + StoreStaticField(node->position(), field);
  } else {
    ASSERT(H.IsProcedure(target));

    // Evaluate the expression on the right hand side.
    Fragment instructions = TranslateExpression(node->expression());
    LocalVariable* variable = MakeTemporary();

    // Prepare argument.
    instructions += LoadLocal(variable);
    instructions += PushArgument();

    // Invoke the setter function.
    const Function& function =
        Function::ZoneHandle(Z, H.LookupStaticMethodByKernelProcedure(target));
    instructions += StaticCall(node->position(), function, 1);

    // Drop the unused result & leave the stored value on the stack.
    fragment_ = instructions + Drop();
  }
}


void FlowGraphBuilder::VisitPropertyGet(PropertyGet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  const dart::String& getter_name = H.DartGetterName(node->name());
  fragment_ = instructions +
              InstanceCall(node->position(), getter_name, Token::kGET, 1);
}


void FlowGraphBuilder::VisitPropertySet(PropertySet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions(NullConstant());
  LocalVariable* variable = MakeTemporary();
  instructions += TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateExpression(node->value());
  instructions += StoreLocal(TokenPosition::kNoSource, variable);
  instructions += PushArgument();

  const dart::String& setter_name = H.DartSetterName(node->name());
  instructions += InstanceCall(node->position(), setter_name, Token::kSET, 2);
  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitDirectPropertyGet(DirectPropertyGet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Function& target = Function::ZoneHandle(Z);
  NameIndex kernel_name = node->target();
  if (H.IsProcedure(kernel_name)) {
    if (H.IsGetter(kernel_name)) {
      target = LookupMethodByMember(kernel_name, H.DartGetterName(kernel_name));
    } else {
      target = LookupMethodByMember(kernel_name, H.DartMethodName(kernel_name));
      target = target.ImplicitClosureFunction();
      ASSERT(!target.IsNull());
      fragment_ = BuildImplicitClosureCreation(target);
      return;
    }
  } else {
    ASSERT(H.IsField(kernel_name));
    const dart::String& getter_name = H.DartGetterName(kernel_name);
    target = LookupMethodByMember(kernel_name, getter_name);
    ASSERT(target.IsGetterFunction() || target.IsImplicitGetterFunction());
  }

  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  fragment_ = instructions + StaticCall(node->position(), target, 1);
}


void FlowGraphBuilder::VisitDirectPropertySet(DirectPropertySet* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  const dart::String& method_name = H.DartSetterName(node->target());
  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(node->target(), method_name));
  ASSERT(target.IsSetterFunction() || target.IsImplicitSetterFunction());

  Fragment instructions(NullConstant());
  LocalVariable* value = MakeTemporary();
  instructions += TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateExpression(node->value());
  instructions += StoreLocal(TokenPosition::kNoSource, value);
  instructions += PushArgument();
  instructions += StaticCall(node->position(), target, 2);

  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitStaticInvocation(StaticInvocation* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  const Function& target = Function::ZoneHandle(
      Z, H.LookupStaticMethodByKernelProcedure(node->procedure()));
  const dart::Class& klass = dart::Class::ZoneHandle(Z, target.Owner());
  intptr_t argument_count = node->arguments()->count();
  if (target.IsGenerativeConstructor() || target.IsFactory()) {
    // The VM requires a TypeArguments object as first parameter for
    // every factory constructor.
    ++argument_count;
  }

  List<NamedExpression>& named = node->arguments()->named();
  const Array& argument_names = H.ArgumentNames(&named);

  // The frontend ensures we the [StaticInvocation] has matching arguments.
  const intptr_t kTypeArgsLen = 0;  // Generic functions not yet supported.
  ASSERT(target.AreValidArguments(kTypeArgsLen, argument_count, argument_names,
                                  NULL));

  Fragment instructions;
  LocalVariable* instance_variable = NULL;

  // If we cross the Kernel -> VM core library boundary, a [StaticInvocation]
  // can appear, but the thing we're calling is not a static method, but a
  // factory constructor.
  // The `H.LookupStaticmethodByKernelProcedure` will potentially resolve to the
  // forwarded constructor.
  // In that case we'll make an instance and pass it as first argument.
  //
  // TODO(27590): Get rid of this after we're using core libraries compiled
  // into Kernel.
  if (target.IsGenerativeConstructor()) {
    if (klass.NumTypeArguments() > 0) {
      List<DartType>& kernel_type_arguments = node->arguments()->types();
      const TypeArguments& type_arguments =
          T.TranslateInstantiatedTypeArguments(
              klass, kernel_type_arguments.raw_array(),
              kernel_type_arguments.length());
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
      instructions += PushArgument();
      instructions += AllocateObject(klass, 1);
    } else {
      instructions += AllocateObject(klass, 0);
    }

    instance_variable = MakeTemporary();

    instructions += LoadLocal(instance_variable);
    instructions += PushArgument();
  } else if (target.IsFactory()) {
    // The VM requires currently a TypeArguments object as first parameter for
    // every factory constructor :-/ !
    //
    // TODO(27590): Get rid of this after we're using core libraries compiled
    // into Kernel.
    List<DartType>& kernel_type_arguments = node->arguments()->types();

    const TypeArguments& type_arguments = T.TranslateInstantiatedTypeArguments(
        klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());

    instructions += TranslateInstantiatedTypeArguments(type_arguments);
    instructions += PushArgument();
  } else {
    // TODO(28109) Support generic methods in the VM or reify them away.
  }

  // Special case identical(x, y) call.
  // TODO(27590) consider moving this into the inliner and force inline it
  // there.
  if (klass.IsTopLevel() && (klass.library() == dart::Library::CoreLibrary()) &&
      (target.name() == Symbols::Identical().raw())) {
    ASSERT(argument_count == 2);

    List<Expression>& positional = node->arguments()->positional();
    for (intptr_t i = 0; i < positional.length(); ++i) {
      instructions += TranslateExpression(positional[i]);
    }
    instructions += StrictCompare(Token::kEQ_STRICT, /*number_check=*/true);
  } else {
    instructions += TranslateArguments(node->arguments(), NULL);
    instructions +=
        StaticCall(node->position(), target, argument_count, argument_names);

    if (target.IsGenerativeConstructor()) {
      // Drop the result of the constructor call and leave [instance_variable]
      // on top-of-stack.
      instructions += Drop();
    }
  }

  fragment_ = instructions;
}


static bool IsNumberLiteral(Node* node) {
  return node->IsIntLiteral() || node->IsDoubleLiteral();
}

template <class Invocation>
bool FlowGraphBuilder::RecognizeComparisonWithNull(Token::Kind token_kind,
                                                   Invocation* node) {
  if (token_kind == Token::kEQ || token_kind == Token::kNE) {
    if (node->arguments()->positional().length() != 1) return false;
    Fragment instructions;
    Expression* left = node->receiver();
    Expression* right = node->arguments()->positional()[0];
    if (left->IsNullLiteral() || right->IsNullLiteral()) {
      instructions += TranslateExpression(left);
      instructions += TranslateExpression(right);
      Token::Kind strict_cmp_kind =
          token_kind == Token::kEQ ? Token::kEQ_STRICT : Token::kNE_STRICT;
      fragment_ = instructions + StrictCompare(strict_cmp_kind,
                                               /*number_check = */ true);
      return true;
    }
  }
  return false;
}


void FlowGraphBuilder::VisitMethodInvocation(MethodInvocation* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  const dart::String& name = H.DartMethodName(node->name());
  const intptr_t argument_count = node->arguments()->count() + 1;
  const Token::Kind token_kind = MethodKind(name);
  if (IsNumberLiteral(node->receiver())) {
    if ((argument_count == 1) && (token_kind == Token::kNEGATE)) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(node);
      if (!result.IsError()) {
        fragment_ = Constant(result);
        return;
      }
    } else if ((argument_count == 2) &&
               Token::IsBinaryArithmeticOperator(token_kind) &&
               IsNumberLiteral(node->arguments()->positional()[0])) {
      const Object& result = constant_evaluator_.EvaluateExpressionSafe(node);
      if (!result.IsError()) {
        fragment_ = Constant(result);
        return;
      }
    }
  }

  if (RecognizeComparisonWithNull(token_kind, node)) return;

  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();

  // TODO(28109) Support generic methods in the VM or reify them away.
  Array& argument_names = Array::ZoneHandle(Z);
  instructions += TranslateArguments(node->arguments(), &argument_names);

  intptr_t num_args_checked = 1;
  // If we have a special operation (e.g. +/-/==) we mark both arguments as
  // to be checked.
  if (token_kind != Token::kILLEGAL) {
    ASSERT(argument_count <= 2);
    num_args_checked = argument_count;
  }

  fragment_ = instructions + InstanceCall(node->position(), name, token_kind,
                                          argument_count, argument_names,
                                          num_args_checked);
  // Later optimization passes assume that result of a x.[]=(...) call is not
  // used. We must guarantee this invariant because violation will lead to an
  // illegal IL once we replace x.[]=(...) with a sequence that does not
  // actually produce any value. See http://dartbug.com/29135 for more details.
  if (name.raw() == Symbols::AssignIndexToken().raw()) {
    fragment_ += Drop();
    fragment_ += NullConstant();
  }
}


void FlowGraphBuilder::VisitDirectMethodInvocation(
    DirectMethodInvocation* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  const dart::String& method_name = H.DartProcedureName(node->target());
  const Token::Kind token_kind = MethodKind(method_name);

  if (RecognizeComparisonWithNull(token_kind, node)) return;

  const Function& target = Function::ZoneHandle(
      Z, LookupMethodByMember(node->target(), method_name));

  intptr_t argument_count = node->arguments()->count() + 1;
  Array& argument_names = Array::ZoneHandle(Z);

  // TODO(28109) Support generic methods in the VM or reify them away.
  Fragment instructions = TranslateExpression(node->receiver());
  instructions += PushArgument();
  instructions += TranslateArguments(node->arguments(), &argument_names);
  fragment_ = instructions + StaticCall(node->position(), target,
                                        argument_count, argument_names);
}


void FlowGraphBuilder::VisitConstructorInvocation(ConstructorInvocation* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  if (node->is_const()) {
    fragment_ =
        Constant(constant_evaluator_.EvaluateConstructorInvocation(node));
    return;
  }

  dart::Class& klass = dart::Class::ZoneHandle(
      Z, H.LookupClassByKernelClass(H.EnclosingName(node->target())));

  Fragment instructions;

  // Check for malbounded-ness of type.
  if (I->type_checks()) {
    List<DartType>& kernel_type_arguments = node->arguments()->types();
    const TypeArguments& type_arguments = T.TranslateTypeArguments(
        kernel_type_arguments.raw_array(), kernel_type_arguments.length());

    AbstractType& type = AbstractType::Handle(
        Z, Type::New(klass, type_arguments, TokenPosition::kNoSource));
    type = ClassFinalizer::FinalizeType(klass, type);

    if (type.IsMalbounded()) {
      // Evaluate expressions for correctness.
      List<Expression>& positional = node->arguments()->positional();
      List<NamedExpression>& named = node->arguments()->named();
      for (intptr_t i = 0; i < positional.length(); ++i) {
        instructions += TranslateExpression(positional[i]);
        instructions += Drop();
      }
      for (intptr_t i = 0; i < named.length(); ++i) {
        instructions += TranslateExpression(named[i]->expression());
        instructions += Drop();
      }

      // Throw an error & keep the [Value] on the stack.
      instructions += ThrowTypeError();

      // Bail out early.
      fragment_ = instructions;
      return;
    }
  }

  if (klass.NumTypeArguments() > 0) {
    List<DartType>& kernel_type_arguments = node->arguments()->types();
    const TypeArguments& type_arguments = T.TranslateInstantiatedTypeArguments(
        klass, kernel_type_arguments.raw_array(),
        kernel_type_arguments.length());
    if (!klass.IsGeneric()) {
      Type& type = Type::ZoneHandle(Z, T.ReceiverType(klass).raw());

      // TODO(27590): Can we move this code into [ReceiverType]?
      type ^= ClassFinalizer::FinalizeType(*active_class_.klass, type,
                                           ClassFinalizer::kFinalize);
      ASSERT(!type.IsMalformedOrMalbounded());

      TypeArguments& canonicalized_type_arguments =
          TypeArguments::ZoneHandle(Z, type.arguments());
      canonicalized_type_arguments =
          canonicalized_type_arguments.Canonicalize();
      instructions += Constant(canonicalized_type_arguments);
    } else {
      instructions += TranslateInstantiatedTypeArguments(type_arguments);
    }

    instructions += PushArgument();
    instructions += AllocateObject(klass, 1);
  } else {
    instructions += AllocateObject(klass, 0);
  }
  LocalVariable* variable = MakeTemporary();

  instructions += LoadLocal(variable);
  instructions += PushArgument();

  Array& argument_names = Array::ZoneHandle(Z);
  instructions += TranslateArguments(node->arguments(), &argument_names);

  const Function& target = Function::ZoneHandle(
      Z, H.LookupConstructorByKernelConstructor(klass, node->target()));
  intptr_t argument_count = node->arguments()->count() + 1;
  instructions +=
      StaticCall(node->position(), target, argument_count, argument_names);
  fragment_ = instructions + Drop();
}


void FlowGraphBuilder::VisitIsExpression(IsExpression* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->operand());

  // The VM does not like an instanceOf call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    fragment_ = instructions;
    return;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // Evaluate the expression on the left but ignore it's result.
    instructions += Drop();

    // Let condition be always true.
    instructions += Constant(Bool::True());
  } else {
    instructions += PushArgument();

    // See if simple instanceOf is applicable.
    if (dart::FlowGraphBuilder::SimpleInstanceOfType(type)) {
      instructions += Constant(type);
      instructions += PushArgument();  // Type.
      instructions += InstanceCall(
          node->position(),
          dart::Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()),
          Token::kIS, 2, 2);  // 2 checked arguments.
      fragment_ = instructions;
      return;
    }

    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Instantiator type arguments.

    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Function type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions +=
        InstanceCall(node->position(),
                     dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
                     Token::kIS, 4);
  }

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitAsExpression(AsExpression* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->operand());

  // The VM does not like an Object_as call with a dynamic type. We need to
  // special case this situation.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  const AbstractType& type = T.TranslateType(node->type());
  if (type.IsMalformed()) {
    instructions += Drop();
    instructions += ThrowTypeError();
    fragment_ = instructions;
    return;
  }

  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // We already evaluated the operand on the left and just leave it there as
    // the result of the `obj as dynamic` expression.
  } else {
    instructions += PushArgument();

    if (!type.IsInstantiated(kCurrentClass)) {
      instructions += LoadInstantiatorTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Instantiator type arguments.

    if (!type.IsInstantiated(kFunctions)) {
      instructions += LoadFunctionTypeArguments();
    } else {
      instructions += NullConstant();
    }
    instructions += PushArgument();  // Function type arguments.

    instructions += Constant(type);
    instructions += PushArgument();  // Type.

    instructions += InstanceCall(
        node->position(), dart::Library::PrivateCoreLibName(Symbols::_as()),
        Token::kAS, 4);
  }

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitConditionalExpression(ConditionalExpression* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  bool negate;
  Fragment instructions = TranslateCondition(node->condition(), &negate);

  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Value* top = stack_;
  Fragment then_fragment(then_entry);
  then_fragment += TranslateExpression(node->then());
  then_fragment += StoreLocal(TokenPosition::kNoSource,
                              parsed_function_->expression_temp_var());
  then_fragment += Drop();
  ASSERT(stack_ == top);

  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += TranslateExpression(node->otherwise());
  otherwise_fragment += StoreLocal(TokenPosition::kNoSource,
                                   parsed_function_->expression_temp_var());
  otherwise_fragment += Drop();
  ASSERT(stack_ == top);

  JoinEntryInstr* join = BuildJoinEntry();
  then_fragment += Goto(join);
  otherwise_fragment += Goto(join);

  fragment_ = Fragment(instructions.entry, join) +
              LoadLocal(parsed_function_->expression_temp_var());
}


void FlowGraphBuilder::VisitLogicalExpression(LogicalExpression* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  bool negate;
  Fragment instructions = TranslateCondition(node->left(), &negate);
  TargetEntryInstr* right_entry;
  TargetEntryInstr* constant_entry;

  if (node->op() == LogicalExpression::kAnd) {
    instructions += BranchIfTrue(&right_entry, &constant_entry, negate);
  } else {
    instructions += BranchIfTrue(&constant_entry, &right_entry, negate);
  }

  Value* top = stack_;
  Fragment right_fragment(right_entry);
  right_fragment += TranslateCondition(node->right(), &negate);
  right_fragment += Constant(Bool::True());
  right_fragment +=
      StrictCompare(negate ? Token::kNE_STRICT : Token::kEQ_STRICT);
  right_fragment += StoreLocal(TokenPosition::kNoSource,
                               parsed_function_->expression_temp_var());
  right_fragment += Drop();

  ASSERT(top == stack_);
  Fragment constant_fragment(constant_entry);
  constant_fragment +=
      Constant(Bool::Get(node->op() == LogicalExpression::kOr));
  constant_fragment += StoreLocal(TokenPosition::kNoSource,
                                  parsed_function_->expression_temp_var());
  constant_fragment += Drop();

  JoinEntryInstr* join = BuildJoinEntry();
  right_fragment += Goto(join);
  constant_fragment += Goto(join);

  fragment_ = Fragment(instructions.entry, join) +
              LoadLocal(parsed_function_->expression_temp_var());
}


void FlowGraphBuilder::VisitNot(Not* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->expression());
  instructions += CheckBooleanInCheckedMode();
  instructions += BooleanNegate();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitThisExpression(ThisExpression* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitStringConcatenation(StringConcatenation* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  List<Expression>& expressions = node->expressions();

  Fragment instructions;

  if (node->expressions().length() == 1) {
    instructions += TranslateExpression(node->expressions()[0]);
    instructions += StringInterpolateSingle(node->position());
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(TypeArguments::ZoneHandle(Z));
    instructions += IntConstant(expressions.length());
    instructions += CreateArray();
    LocalVariable* array = MakeTemporary();

    for (intptr_t i = 0; i < node->expressions().length(); i++) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += TranslateExpression(node->expressions()[i]);
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }

    instructions += StringInterpolate(node->position());
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitListLiteral(ListLiteral* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  if (node->is_const()) {
    fragment_ = Constant(constant_evaluator_.EvaluateListLiteral(node));
    return;
  }

  DartType* types[] = {node->type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 1);

  // The type argument for the factory call.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();
  List<Expression>& expressions = node->expressions();
  if (expressions.length() == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for CreateArray.
    instructions += Constant(TypeArguments::ZoneHandle(Z));
    instructions += IntConstant(expressions.length());
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < expressions.length(); ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(i);
      instructions += TranslateExpression(expressions[i]);
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  const dart::Class& factory_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::List()));
  const Function& factory_method = Function::ZoneHandle(
      Z, factory_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::ListLiteralFactory())));
  fragment_ = instructions + StaticCall(node->position(), factory_method, 2);
}


void FlowGraphBuilder::VisitMapLiteral(MapLiteral* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  if (node->is_const()) {
    fragment_ = Constant(constant_evaluator_.EvaluateMapLiteral(node));
    return;
  }

  const dart::Class& map_class =
      dart::Class::Handle(Z, dart::Library::LookupCoreClass(Symbols::Map()));
  const Function& factory_method = Function::ZoneHandle(
      Z, map_class.LookupFactory(
             dart::Library::PrivateCoreLibName(Symbols::MapLiteralFactory())));

  DartType* types[] = {node->key_type(), node->value_type()};
  const TypeArguments& type_arguments = T.TranslateTypeArguments(types, 2);

  // The type argument for the factory call `new Map<K, V>._fromLiteral(List)`.
  Fragment instructions = TranslateInstantiatedTypeArguments(type_arguments);
  instructions += PushArgument();

  List<MapEntry>& entries = node->entries();
  if (entries.length() == 0) {
    instructions += Constant(Object::empty_array());
  } else {
    // The type arguments for `new List<X>(int len)`.
    instructions += Constant(TypeArguments::ZoneHandle(Z));

    // We generate a list of tuples, i.e. [key1, value1, ..., keyN, valueN].
    instructions += IntConstant(2 * entries.length());
    instructions += CreateArray();

    LocalVariable* array = MakeTemporary();
    for (intptr_t i = 0; i < entries.length(); ++i) {
      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i);
      instructions += TranslateExpression(entries[i]->key());
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();

      instructions += LoadLocal(array);
      instructions += IntConstant(2 * i + 1);
      instructions += TranslateExpression(entries[i]->value());
      instructions += StoreIndexed(kArrayCid);
      instructions += Drop();
    }
  }
  instructions += PushArgument();  // The array.

  fragment_ = instructions + StaticCall(node->position(), factory_method, 2);
}


void FlowGraphBuilder::VisitFunctionExpression(FunctionExpression* node) {
  fragment_ = TranslateFunctionNode(node->function(), node);
}


void FlowGraphBuilder::VisitLet(Let* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions = TranslateStatement(node->variable());
  instructions += TranslateExpression(node->body());
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitThrow(Throw* node) {
  STREAM_EXPRESSION_IF_POSSIBLE(node);

  Fragment instructions;

  instructions += TranslateExpression(node->expression());
  if (NeedsDebugStepCheck(stack_, node->position())) {
    instructions = DebugStepCheck(node->position()) + instructions;
  }
  instructions += PushArgument();
  instructions += ThrowException(node->position());
  ASSERT(instructions.is_closed());

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitRethrow(Rethrow* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildExpressionAt(node->kernel_offset());
}


Fragment FlowGraphBuilder::TranslateArguments(Arguments* node,
                                              Array* argument_names) {
  Fragment instructions;

  List<Expression>& positional = node->positional();
  for (intptr_t i = 0; i < positional.length(); ++i) {
    instructions += TranslateExpression(positional[i]);
    instructions += PushArgument();
  }

  List<NamedExpression>& named = node->named();
  if (argument_names != NULL) {
    *argument_names = H.ArgumentNames(&named).raw();
  }
  for (intptr_t i = 0; i < named.length(); ++i) {
    NamedExpression* named_expression = named[i];
    instructions += TranslateExpression(named_expression->expression());
    instructions += PushArgument();
  }
  return instructions;
}

#define STREAM_STATEMENT_IF_POSSIBLE(node)                                     \
  if (node->can_stream()) {                                                    \
    fragment_ = streaming_flow_graph_builder_->BuildStatementAt(               \
        node->kernel_offset());                                                \
    return;                                                                    \
  }


void FlowGraphBuilder::VisitInvalidStatement(InvalidStatement* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildStatementAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitEmptyStatement(EmptyStatement* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildStatementAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitBlock(Block* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  Fragment instructions;

  instructions += EnterScope(node);
  List<Statement>& statements = node->statements();
  for (intptr_t i = 0; (i < statements.length()) && instructions.is_open();
       ++i) {
    instructions += TranslateStatement(statements[i]);
  }
  instructions += ExitScope(node);

  fragment_ = instructions;
}


void FlowGraphBuilder::VisitReturnStatement(ReturnStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  bool inside_try_finally = try_finally_block_ != NULL;

  Fragment instructions = node->expression() == NULL
                              ? NullConstant()
                              : TranslateExpression(node->expression());
  if (instructions.is_open()) {
    if (inside_try_finally) {
      ASSERT(scopes_->finally_return_variable != NULL);
      const Function& function = parsed_function_->function();
      if (NeedsDebugStepCheck(function, node->position())) {
        instructions += DebugStepCheck(node->position());
      }
      instructions +=
          StoreLocal(node->position(), scopes_->finally_return_variable);
      instructions += Drop();
      instructions += TranslateFinallyFinalizers(NULL, -1);
      if (instructions.is_open()) {
        instructions += LoadLocal(scopes_->finally_return_variable);
        instructions += Return(TokenPosition::kNoSource);
      }
    } else {
      instructions += Return(node->position());
    }
  } else {
    Pop();
  }
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitExpressionStatement(ExpressionStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->expression());
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitVariableDeclaration(VariableDeclaration* node) {
  LocalVariable* variable = LookupVariable(node);
  Expression* initializer = node->initializer();

  Fragment instructions;
  if (initializer == NULL) {
    instructions += NullConstant();
  } else {
    if (node->IsConst()) {
      const Instance& constant_value =
          constant_evaluator_.EvaluateExpression(initializer);
      variable->SetConstValue(constant_value);
      instructions += Constant(constant_value);
    } else {
      instructions += TranslateExpression(initializer);
      instructions += CheckVariableTypeInCheckedMode(node);
    }
  }
  // Use position of equal sign if it exists. If the equal sign does not exist
  // use the position of the identifier.
  TokenPosition debug_position =
      Utils::Maximum(node->position(), node->equals_position());
  if (NeedsDebugStepCheck(stack_, debug_position)) {
    instructions = DebugStepCheck(debug_position) + instructions;
  }
  instructions += StoreLocal(node->position(), variable);
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitFunctionDeclaration(FunctionDeclaration* node) {
  Fragment instructions = DebugStepCheck(node->position());
  instructions += TranslateFunctionNode(node->function(), node);
  instructions +=
      StoreLocal(node->position(), LookupVariable(node->variable()));
  instructions += Drop();
  fragment_ = instructions;
}


void FlowGraphBuilder::VisitIfStatement(IfStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  bool negate;
  Fragment instructions = TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* then_entry;
  TargetEntryInstr* otherwise_entry;
  instructions += BranchIfTrue(&then_entry, &otherwise_entry, negate);

  Fragment then_fragment(then_entry);
  then_fragment += TranslateStatement(node->then());

  Fragment otherwise_fragment(otherwise_entry);
  otherwise_fragment += TranslateStatement(node->otherwise());

  if (then_fragment.is_open()) {
    if (otherwise_fragment.is_open()) {
      JoinEntryInstr* join = BuildJoinEntry();
      then_fragment += Goto(join);
      otherwise_fragment += Goto(join);
      fragment_ = Fragment(instructions.entry, join);
    } else {
      fragment_ = Fragment(instructions.entry, then_fragment.current);
    }
  } else if (otherwise_fragment.is_open()) {
    fragment_ = Fragment(instructions.entry, otherwise_fragment.current);
  } else {
    fragment_ = instructions.closed();
  }
}


void FlowGraphBuilder::VisitWhileStatement(WhileStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  ++loop_depth_;
  bool negate;
  Fragment condition = TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment body(body_entry);
  body += TranslateStatement(node->body());

  Instruction* entry;
  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
    entry = new (Z) GotoInstr(join, GetNextDeoptId());
  } else {
    entry = condition.entry;
  }


  fragment_ = Fragment(entry, loop_exit);
  --loop_depth_;
}


void FlowGraphBuilder::VisitDoStatement(DoStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  ++loop_depth_;
  Fragment body = TranslateStatement(node->body());

  if (body.is_closed()) {
    fragment_ = body;
    --loop_depth_;
    return;
  }

  bool negate;
  JoinEntryInstr* join = BuildJoinEntry();
  Fragment loop(join);
  loop += CheckStackOverflow();
  loop += body;
  loop += TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* loop_repeat;
  TargetEntryInstr* loop_exit;
  loop += BranchIfTrue(&loop_repeat, &loop_exit, negate);

  Fragment repeat(loop_repeat);
  repeat += Goto(join);

  fragment_ = Fragment(new (Z) GotoInstr(join, GetNextDeoptId()), loop_exit);
  --loop_depth_;
}


void FlowGraphBuilder::VisitForStatement(ForStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  Fragment declarations;

  bool new_context = false;
  declarations += EnterScope(node, &new_context);

  List<VariableDeclaration>& variables = node->variables();
  for (intptr_t i = 0; i < variables.length(); ++i) {
    declarations += TranslateStatement(variables[i]);
  }

  ++loop_depth_;
  bool negate = false;
  Fragment condition = node->condition() == NULL
                           ? Constant(Bool::True())
                           : TranslateCondition(node->condition(), &negate);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit, negate);

  Fragment body(body_entry);
  body += TranslateStatement(node->body());

  if (body.is_open()) {
    // We allocated a fresh context before the loop which contains captured
    // [ForStatement] variables.  Before jumping back to the loop entry we clone
    // the context object (at same depth) which ensures the next iteration of
    // the body gets a fresh set of [ForStatement] variables (with the old
    // (possibly updated) values).
    if (new_context) body += CloneContext();

    List<Expression>& updates = node->updates();
    for (intptr_t i = 0; i < updates.length(); ++i) {
      body += TranslateExpression(updates[i]);
      body += Drop();
    }
    JoinEntryInstr* join = BuildJoinEntry();
    declarations += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    declarations += condition;
  }

  Fragment loop(declarations.entry, loop_exit);
  --loop_depth_;

  loop += ExitScope(node);

  fragment_ = loop;
}


void FlowGraphBuilder::VisitForInStatement(ForInStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  Fragment instructions = TranslateExpression(node->iterable());
  instructions += PushArgument();

  const dart::String& iterator_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Iterator()));
  instructions += InstanceCall(node->iterable()->position(), iterator_getter,
                               Token::kGET, 1);
  LocalVariable* iterator = scopes_->iterator_variables[for_in_depth_];
  instructions += StoreLocal(TokenPosition::kNoSource, iterator);
  instructions += Drop();

  ++for_in_depth_;
  ++loop_depth_;
  Fragment condition = LoadLocal(iterator);
  condition += PushArgument();
  condition += InstanceCall(node->iterable()->position(), Symbols::MoveNext(),
                            Token::kILLEGAL, 1);
  TargetEntryInstr* body_entry;
  TargetEntryInstr* loop_exit;
  condition += BranchIfTrue(&body_entry, &loop_exit);

  Fragment body(body_entry);
  body += EnterScope(node);
  body += LoadLocal(iterator);
  body += PushArgument();
  const dart::String& current_getter = dart::String::ZoneHandle(
      Z, dart::Field::GetterSymbol(Symbols::Current()));
  body += InstanceCall(node->position(), current_getter, Token::kGET, 1);
  body +=
      StoreLocal(TokenPosition::kNoSource, LookupVariable(node->variable()));
  body += Drop();
  body += TranslateStatement(node->body());
  body += ExitScope(node);

  if (body.is_open()) {
    JoinEntryInstr* join = BuildJoinEntry();
    instructions += Goto(join);
    body += Goto(join);

    Fragment loop(join);
    loop += CheckStackOverflow();
    loop += condition;
  } else {
    instructions += condition;
  }

  fragment_ = Fragment(instructions.entry, loop_exit);
  --loop_depth_;
  --for_in_depth_;
}


void FlowGraphBuilder::VisitLabeledStatement(LabeledStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  // There can be serveral cases:
  //
  //   * the body contains a break
  //   * the body doesn't contain a break
  //
  //   * translating the body results in a closed fragment
  //   * translating the body results in a open fragment
  //
  // => We will only know which case we are in after the body has been
  //    traversed.

  BreakableBlock block(this);
  Fragment instructions = TranslateStatement(node->body());
  if (block.HadJumper()) {
    if (instructions.is_open()) {
      instructions += Goto(block.destination());
    }
    fragment_ = Fragment(instructions.entry, block.destination());
  } else {
    fragment_ = instructions;
  }
}


void FlowGraphBuilder::VisitBreakStatement(BreakStatement* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildStatementAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitSwitchStatement(SwitchStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  SwitchBlock block(this, node->cases().length());

  // Instead of using a variable we should reuse the expression on the stack,
  // since it won't be assigned again, we don't need phi nodes.
  Fragment head_instructions = TranslateExpression(node->condition());
  head_instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes_->switch_variable);
  head_instructions += Drop();

  // Phase 1: Generate bodies and try to find out whether a body will be target
  // of a jump due to:
  //   * `continue case_label`
  //   * `case e1: case e2: body`
  Fragment* body_fragments = new Fragment[node->cases().length()];

  intptr_t num_cases = node->cases().length();
  for (intptr_t i = 0; i < num_cases; i++) {
    SwitchCase* switch_case = node->cases()[i];
    Fragment& body_fragment = body_fragments[i] =
        TranslateStatement(switch_case->body());

    if (body_fragment.entry == NULL) {
      // Make a NOP in order to ensure linking works properly.
      body_fragment = NullConstant();
      body_fragment += Drop();
    }

    // The Dart language specification mandates fall-throughs in [SwitchCase]es
    // to be runtime errors.
    if (!switch_case->is_default() && body_fragment.is_open() &&
        (i < (node->cases().length() - 1))) {
      const dart::Class& klass = dart::Class::ZoneHandle(
          Z, dart::Library::LookupCoreClass(Symbols::FallThroughError()));
      ASSERT(!klass.IsNull());
      const Function& constructor = Function::ZoneHandle(
          Z, klass.LookupConstructorAllowPrivate(
                 H.DartSymbol("FallThroughError._create")));
      ASSERT(!constructor.IsNull());
      const dart::String& url = H.DartString(
          parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
          Heap::kOld);

      // Create instance of _FallThroughError
      body_fragment += AllocateObject(klass, 0);
      LocalVariable* instance = MakeTemporary();

      // Call _FallThroughError._create constructor.
      body_fragment += LoadLocal(instance);
      body_fragment += PushArgument();  // this

      body_fragment += Constant(url);
      body_fragment += PushArgument();  // url

      body_fragment += NullConstant();
      body_fragment += PushArgument();  // line

      body_fragment += StaticCall(TokenPosition::kNoSource, constructor, 3);
      body_fragment += Drop();

      // Throw the exception
      body_fragment += PushArgument();
      body_fragment += ThrowException(TokenPosition::kNoSource);
      body_fragment += Drop();
    }

    // If there is an implicit fall-through we have one [SwitchCase] and
    // multiple expressions, e.g.
    //
    //    switch(expr) {
    //      case a:
    //      case b:
    //        <stmt-body>
    //    }
    //
    // This means that the <stmt-body> will have more than 1 incoming edge (one
    // from `a == expr` and one from `a != expr && b == expr`). The
    // `block.Destination()` records the additional jump.
    if (switch_case->expressions().length() > 1) {
      block.DestinationDirect(i);
    }
  }

  // Phase 2: Generate everything except the real bodies:
  //   * jump directly to a body (if there is no jumper)
  //   * jump to a wrapper block which jumps to the body (if there is a jumper)
  Fragment current_instructions = head_instructions;
  for (intptr_t i = 0; i < num_cases; i++) {
    SwitchCase* switch_case = node->cases()[i];

    if (switch_case->is_default()) {
      ASSERT(i == (node->cases().length() - 1));

      // Evaluate the conditions for the default [SwitchCase] just for the
      // purpose of potentially triggering a compile-time error.
      for (intptr_t k = 0; k < switch_case->expressions().length(); k++) {
        constant_evaluator_.EvaluateExpression(switch_case->expressions()[k]);
      }

      if (block.HadJumper(i)) {
        // There are several branches to the body, so we will make a goto to
        // the join block (and prepend a join instruction to the real body).
        JoinEntryInstr* join = block.DestinationDirect(i);
        current_instructions += Goto(join);

        current_instructions = Fragment(current_instructions.entry, join);
        current_instructions += body_fragments[i];
      } else {
        current_instructions += body_fragments[i];
      }
    } else {
      JoinEntryInstr* body_join = NULL;
      if (block.HadJumper(i)) {
        body_join = block.DestinationDirect(i);
        body_fragments[i] = Fragment(body_join) + body_fragments[i];
      }

      for (intptr_t j = 0; j < switch_case->expressions().length(); j++) {
        TargetEntryInstr* then;
        TargetEntryInstr* otherwise;

        Expression* expression = switch_case->expressions()[j];
        current_instructions +=
            Constant(constant_evaluator_.EvaluateExpression(expression));
        current_instructions += PushArgument();
        current_instructions += LoadLocal(scopes_->switch_variable);
        current_instructions += PushArgument();
        current_instructions += InstanceCall(
            expression->position(), Symbols::EqualOperator(), Token::kEQ,
            /*argument_count=*/2,
            /*num_args_checked=*/2);
        current_instructions += BranchIfTrue(&then, &otherwise);

        Fragment then_fragment(then);

        if (body_join != NULL) {
          // There are several branches to the body, so we will make a goto to
          // the join block (the real body has already been prepended with a
          // join instruction).
          then_fragment += Goto(body_join);
        } else {
          // There is only a signle branch to the body, so we will just append
          // the body fragment.
          then_fragment += body_fragments[i];
        }

        current_instructions = Fragment(otherwise);
      }
    }
  }

  bool has_no_default =
      num_cases > 0 && !node->cases()[num_cases - 1]->is_default();
  if (has_no_default) {
    // There is no default, which means we have an open [current_instructions]
    // (which is a [TargetEntryInstruction] for the last "otherwise" branch).
    //
    // Furthermore the last [SwitchCase] can be open as well.  If so, we need
    // to join these two.
    Fragment& last_body = body_fragments[node->cases().length() - 1];
    if (last_body.is_open()) {
      ASSERT(current_instructions.is_open());
      ASSERT(current_instructions.current->IsTargetEntry());

      // Join the last "otherwise" branch and the last [SwitchCase] fragment.
      JoinEntryInstr* join = BuildJoinEntry();
      current_instructions += Goto(join);
      last_body += Goto(join);

      current_instructions = Fragment(join);
    }
  } else {
    // All non-default cases will be closed (i.e. break/continue/throw/return)
    // So it is fine to just let more statements after the switch append to the
    // default case.
  }

  delete[] body_fragments;

  fragment_ = Fragment(head_instructions.entry, current_instructions.current);
}


void FlowGraphBuilder::VisitContinueSwitchStatement(
    ContinueSwitchStatement* node) {
  fragment_ =
      streaming_flow_graph_builder_->BuildStatementAt(node->kernel_offset());
}


void FlowGraphBuilder::VisitAssertStatement(AssertStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  if (!I->asserts()) {
    fragment_ = Fragment();
    return;
  }

  TargetEntryInstr* then;
  TargetEntryInstr* otherwise;

  Fragment instructions;
  // Asserts can be of the following two kinds:
  //
  //    * `assert(expr)`
  //    * `assert(() { ... })`
  //
  // The call to `_AssertionError._evaluateAssertion()` will take care of both
  // and returns a boolean.
  instructions += TranslateExpression(node->condition());
  instructions += PushArgument();
  instructions += EvaluateAssertion();
  instructions += CheckBooleanInCheckedMode();
  instructions += Constant(Bool::True());
  instructions += BranchIfEqual(&then, &otherwise, false);

  const dart::Class& klass = dart::Class::ZoneHandle(
      Z, dart::Library::LookupCoreClass(Symbols::AssertionError()));
  ASSERT(!klass.IsNull());
  const Function& constructor =
      Function::ZoneHandle(Z, klass.LookupConstructorAllowPrivate(
                                  H.DartSymbol("_AssertionError._create")));
  ASSERT(!constructor.IsNull());

  const dart::String& url = H.DartString(
      parsed_function_->function().ToLibNamePrefixedQualifiedCString(),
      Heap::kOld);

  // Create instance of _AssertionError
  Fragment otherwise_fragment(otherwise);
  otherwise_fragment += AllocateObject(klass, 0);
  LocalVariable* instance = MakeTemporary();

  // Call _AssertionError._create constructor.
  otherwise_fragment += LoadLocal(instance);
  otherwise_fragment += PushArgument();  // this

  otherwise_fragment += Constant(H.DartString("<no message>", Heap::kOld));
  otherwise_fragment += PushArgument();  // failedAssertion

  otherwise_fragment += Constant(url);
  otherwise_fragment += PushArgument();  // url

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // line

  otherwise_fragment += IntConstant(0);
  otherwise_fragment += PushArgument();  // column

  otherwise_fragment +=
      node->message() != NULL
          ? TranslateExpression(node->message())
          : Constant(H.DartString("<no message>", Heap::kOld));
  otherwise_fragment += PushArgument();  // message

  otherwise_fragment += StaticCall(TokenPosition::kNoSource, constructor, 6);
  otherwise_fragment += Drop();

  // Throw _AssertionError exception.
  otherwise_fragment += PushArgument();
  otherwise_fragment += ThrowException(TokenPosition::kNoSource);
  otherwise_fragment += Drop();

  fragment_ = Fragment(instructions.entry, then);
}


void FlowGraphBuilder::VisitTryFinally(TryFinally* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  InlineBailout("kernel::FlowgraphBuilder::VisitTryFinally");

  // There are 5 different cases where we need to execute the finally block:
  //
  //  a) 1/2/3th case: Special control flow going out of `node->body()`:
  //
  //   * [BreakStatement] transfers control to a [LabledStatement]
  //   * [ContinueSwitchStatement] transfers control to a [SwitchCase]
  //   * [ReturnStatement] returns a value
  //
  //   => All three cases will automatically append all finally blocks
  //      between the branching point and the destination (so we don't need to
  //      do anything here).
  //
  //  b) 4th case: Translating the body resulted in an open fragment (i.e. body
  //               executes without any control flow out of it)
  //
  //   => We are responsible for jumping out of the body to a new block (with
  //      different try index) and execute the finalizer.
  //
  //  c) 5th case: An exception occured inside the body.
  //
  //   => We are responsible for catching it, executing the finally block and
  //      rethrowing the exception.
  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  ++try_depth_;
  {
    TryFinallyBlock tfb(this, node->finalizer(), -1);
    TryCatchBlock tcb(this, try_handler_index);
    try_body += TranslateStatement(node->body());
  }
  --try_depth_;

  if (try_body.is_open()) {
    // Please note: The try index will be on level out of this block,
    // thereby ensuring if there's an exception in the finally block we
    // won't run it twice.
    JoinEntryInstr* finally_entry = BuildJoinEntry();

    try_body += Goto(finally_entry);

    Fragment finally_body(finally_entry);
    finally_body += TranslateStatement(node->finalizer());
    finally_body += Goto(after_try);
  }

  // Fill in the body of the catch.
  ++catch_depth_;
  const Array& handler_types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
  handler_types.SetAt(0, Object::dynamic_type());
  // Note: rethrow will actually force mark the handler as needing a stacktrace.
  Fragment finally_body = CatchBlockEntry(handler_types, try_handler_index,
                                          /* needs_stacktrace = */ false);
  finally_body += TranslateStatement(node->finalizer());
  if (finally_body.is_open()) {
    finally_body += LoadLocal(CurrentException());
    finally_body += PushArgument();
    finally_body += LoadLocal(CurrentStackTrace());
    finally_body += PushArgument();
    finally_body +=
        RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  --catch_depth_;

  fragment_ = Fragment(try_body.entry, after_try);
}


void FlowGraphBuilder::VisitTryCatch(class TryCatch* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  InlineBailout("kernel::FlowgraphBuilder::VisitTryCatch");

  intptr_t try_handler_index = AllocateTryIndex();
  Fragment try_body = TryCatch(try_handler_index);
  JoinEntryInstr* after_try = BuildJoinEntry();

  // Fill in the body of the try.
  ++try_depth_;
  {
    TryCatchBlock block(this, try_handler_index);
    try_body += TranslateStatement(node->body());
    try_body += Goto(after_try);
  }
  --try_depth_;

  ++catch_depth_;
  const Array& handler_types =
      Array::ZoneHandle(Z, Array::New(node->catches().length(), Heap::kOld));
  bool needs_stacktrace = false;
  for (intptr_t i = 0; i < node->catches().length(); i++) {
    if (node->catches()[i]->stack_trace() != NULL) {
      needs_stacktrace = true;
      break;
    }
  }
  Fragment catch_body =
      CatchBlockEntry(handler_types, try_handler_index, needs_stacktrace);
  // Fill in the body of the catch.
  for (intptr_t i = 0; i < node->catches().length(); i++) {
    Catch* catch_clause = node->catches()[i];

    Fragment catch_handler_body;

    catch_handler_body += EnterScope(catch_clause);

    if (catch_clause->exception() != NULL) {
      catch_handler_body += LoadLocal(CurrentException());
      catch_handler_body += StoreLocal(
          TokenPosition::kNoSource, LookupVariable(catch_clause->exception()));
      catch_handler_body += Drop();
    }
    if (catch_clause->stack_trace() != NULL) {
      catch_handler_body += LoadLocal(CurrentStackTrace());
      catch_handler_body +=
          StoreLocal(TokenPosition::kNoSource,
                     LookupVariable(catch_clause->stack_trace()));
      catch_handler_body += Drop();
    }
    AbstractType* type_guard = NULL;
    if (catch_clause->guard() != NULL &&
        !catch_clause->guard()->IsDynamicType()) {
      type_guard = &T.TranslateType(catch_clause->guard());
      handler_types.SetAt(i, *type_guard);
    } else {
      handler_types.SetAt(i, Object::dynamic_type());
    }

    {
      CatchBlock block(this, CurrentException(), CurrentStackTrace(),
                       try_handler_index);

      catch_handler_body += TranslateStatement(catch_clause->body());

      // Note: ExitScope adjusts context_depth_ so even if catch_handler_body
      // is closed we still need to execute ExitScope for its side effect.
      catch_handler_body += ExitScope(catch_clause);
      if (catch_handler_body.is_open()) {
        catch_handler_body += Goto(after_try);
      }
    }

    if (type_guard != NULL) {
      if (type_guard->IsMalformed()) {
        catch_body += ThrowTypeError();
        catch_body += Drop();
      } else {
        catch_body += LoadLocal(CurrentException());
        catch_body += PushArgument();  // exception
        catch_body += NullConstant();
        catch_body += PushArgument();  // instantiator type arguments
        catch_body += NullConstant();
        catch_body += PushArgument();  // function type arguments
        catch_body += Constant(*type_guard);
        catch_body += PushArgument();  // guard type
        catch_body += InstanceCall(
            TokenPosition::kNoSource,
            dart::Library::PrivateCoreLibName(Symbols::_instanceOf()),
            Token::kIS, 4);

        TargetEntryInstr* catch_entry;
        TargetEntryInstr* next_catch_entry;
        catch_body += BranchIfTrue(&catch_entry, &next_catch_entry);

        Fragment(catch_entry) + catch_handler_body;
        catch_body = Fragment(next_catch_entry);
      }
    } else {
      catch_body += catch_handler_body;
    }
  }

  // In case the last catch body was not handling the exception and branching to
  // after the try block, we will rethrow the exception (i.e. no default catch
  // handler).
  if (catch_body.is_open()) {
    catch_body += LoadLocal(CurrentException());
    catch_body += PushArgument();
    catch_body += LoadLocal(CurrentStackTrace());
    catch_body += PushArgument();
    catch_body += RethrowException(TokenPosition::kNoSource, try_handler_index);
    Drop();
  }
  --catch_depth_;

  fragment_ = Fragment(try_body.entry, after_try);
}


void FlowGraphBuilder::VisitYieldStatement(YieldStatement* node) {
  STREAM_STATEMENT_IF_POSSIBLE(node);

  ASSERT(node->is_native());  // Must have been desugared.
  // Setup yield/continue point:
  //
  //   ...
  //   :await_jump_var = index;
  //   :await_ctx_var = :current_context_var
  //   return <expr>
  //
  // Continuation<index>:
  //   Drop(1)
  //   ...
  //
  // BuildGraphOfFunction will create a dispatch that jumps to
  // Continuation<:await_jump_var> upon entry to the function.
  //
  Fragment instructions = IntConstant(yield_continuations_.length() + 1);
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes_->yield_jump_variable);
  instructions += Drop();
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions +=
      StoreLocal(TokenPosition::kNoSource, scopes_->yield_context_variable);
  instructions += Drop();
  instructions += TranslateExpression(node->expression());
  instructions += Return(TokenPosition::kNoSource);

  // Note: DropTempsInstr serves as an anchor instruction. It will not
  // be linked into the resulting graph.
  DropTempsInstr* anchor = new (Z) DropTempsInstr(0, NULL);
  yield_continuations_.Add(YieldContinuation(anchor, CurrentTryIndex()));

  Fragment continuation(instructions.entry, anchor);

  if (parsed_function_->function().IsAsyncClosure() ||
      parsed_function_->function().IsAsyncGenClosure()) {
    // If function is async closure or async gen closure it takes three
    // parameters where the second and the third are exception and stack_trace.
    // Check if exception is non-null and rethrow it.
    //
    //   :async_op([:result, :exception, :stack_trace]) {
    //     ...
    //     Continuation<index>:
    //       if (:exception != null) rethrow(:exception, :stack_trace);
    //     ...
    //   }
    //
    LocalScope* scope = parsed_function_->node_sequence()->scope();
    LocalVariable* exception_var = scope->VariableAt(2);
    LocalVariable* stack_trace_var = scope->VariableAt(3);
    ASSERT(exception_var->name().raw() == Symbols::ExceptionParameter().raw());
    ASSERT(stack_trace_var->name().raw() ==
           Symbols::StackTraceParameter().raw());

    TargetEntryInstr* no_error;
    TargetEntryInstr* error;

    continuation += LoadLocal(exception_var);
    continuation += BranchIfNull(&no_error, &error);

    Fragment rethrow(error);
    rethrow += LoadLocal(exception_var);
    rethrow += PushArgument();
    rethrow += LoadLocal(stack_trace_var);
    rethrow += PushArgument();
    rethrow +=
        RethrowException(node->position(), CatchClauseNode::kInvalidTryIndex);
    Drop();


    continuation = Fragment(continuation.entry, no_error);
  }

  fragment_ = continuation;
}


Fragment FlowGraphBuilder::TranslateFunctionNode(FunctionNode* node,
                                                 TreeNode* parent) {
  // The VM has a per-isolate table of functions indexed by the enclosing
  // function and token position.
  Function& function = Function::ZoneHandle(Z);
  for (intptr_t i = 0; i < scopes_->function_scopes.length(); ++i) {
    if (scopes_->function_scopes[i].kernel_offset != node->kernel_offset()) {
      continue;
    }

    TokenPosition position = node->position();
    if (parent->IsFunctionDeclaration()) {
      position = FunctionDeclaration::Cast(parent)->position();
    }
    if (!position.IsReal()) {
      // Positions has to be unique in regards to the parent.
      // A non-real at this point is probably -1, we cannot blindly use that
      // as others might use it too. Create a new dummy non-real TokenPosition.
      position = TokenPosition(i).ToSynthetic();
    }

    // NOTE: This is not TokenPosition in the general sense!
    function = I->LookupClosureFunction(parsed_function_->function(), position);
    if (function.IsNull()) {
      const dart::String* name;
      if (parent->IsFunctionExpression()) {
        name = &Symbols::AnonymousClosure();
      } else {
        ASSERT(parent->IsFunctionDeclaration());
        name = &H.DartSymbol(
            FunctionDeclaration::Cast(parent)->variable()->name());
      }
      // NOTE: This is not TokenPosition in the general sense!
      function = Function::NewClosureFunction(
          *name, parsed_function_->function(), position);

      function.set_is_debuggable(node->dart_async_marker() ==
                                 FunctionNode::kSync);
      switch (node->dart_async_marker()) {
        case FunctionNode::kSyncStar:
          function.set_modifier(RawFunction::kSyncGen);
          break;
        case FunctionNode::kAsync:
          function.set_modifier(RawFunction::kAsync);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        case FunctionNode::kAsyncStar:
          function.set_modifier(RawFunction::kAsyncGen);
          function.set_is_inlinable(!FLAG_causal_async_stacks);
          break;
        default:
          // no special modifier
          break;
      }
      function.set_is_generated_body(node->async_marker() ==
                                     FunctionNode::kSyncYielding);
      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        function.set_is_inlinable(!FLAG_causal_async_stacks);
      }

      function.set_end_token_pos(node->end_position());
      LocalScope* scope = scopes_->function_scopes[i].scope;
      const ContextScope& context_scope =
          ContextScope::Handle(Z, scope->PreserveOuterScope(context_depth_));
      function.set_context_scope(context_scope);
      function.set_kernel_function(node);
      KernelReader::SetupFunctionParameters(H, T, dart::Class::Handle(Z),
                                            function, node,
                                            false,  // is_method
                                            true);  // is_closure
      // Finalize function type.
      Type& signature_type = Type::Handle(Z, function.SignatureType());
      signature_type ^=
          ClassFinalizer::FinalizeType(*active_class_.klass, signature_type);
      function.SetSignatureType(signature_type);

      I->AddClosureFunction(function);
    }
    break;
  }

  const dart::Class& closure_class =
      dart::Class::ZoneHandle(Z, I->object_store()->closure_class());
  ASSERT(!closure_class.IsNull());
  Fragment instructions = AllocateObject(closure_class, function);
  LocalVariable* closure = MakeTemporary();

  // The function signature can have uninstantiated class type parameters.
  //
  // TODO(regis): Also handle the case of a function signature that has
  // uninstantiated function type parameters.
  if (!function.HasInstantiatedSignature(kCurrentClass)) {
    instructions += LoadLocal(closure);
    instructions += LoadInstantiatorTypeArguments();
    instructions +=
        StoreInstanceField(TokenPosition::kNoSource,
                           Closure::instantiator_type_arguments_offset());
  }

  // Store the function and the context in the closure.
  instructions += LoadLocal(closure);
  instructions += Constant(function);
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::function_offset());

  instructions += LoadLocal(closure);
  instructions += LoadLocal(parsed_function_->current_context_var());
  instructions +=
      StoreInstanceField(TokenPosition::kNoSource, Closure::context_offset());

  return instructions;
}


RawObject* EvaluateMetadata(const dart::Field& metadata_field) {
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    Thread* thread = Thread::Current();
    Zone* zone_ = thread->zone();

    TreeNode* kernel_node =
        reinterpret_cast<TreeNode*>(metadata_field.kernel_field());
    List<Expression>* metadata_expressions = NULL;
    if (kernel_node->IsClass()) {
      metadata_expressions = &Class::Cast(kernel_node)->annotations();
    } else if (kernel_node->IsProcedure()) {
      metadata_expressions = &Procedure::Cast(kernel_node)->annotations();
    } else if (kernel_node->IsField()) {
      metadata_expressions = &Field::Cast(kernel_node)->annotations();
    } else if (kernel_node->IsConstructor()) {
      metadata_expressions = &Constructor::Cast(kernel_node)->annotations();
    } else {
      FATAL1("No support for metadata on this type of kernel node %p\n",
             kernel_node);
    }

    TranslationHelper helper(thread);
    Script& script = Script::Handle(Z, metadata_field.Script());
    helper.SetStringOffsets(
        TypedData::Handle(Z, script.kernel_string_offsets()));
    helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
    helper.SetCanonicalNames(
        TypedData::Handle(Z, script.kernel_canonical_names()));
    DartTypeTranslator type_translator(&helper, NULL, true);
    ConstantEvaluator constant_evaluator(/* flow_graph_builder = */ NULL, Z,
                                         &helper, &type_translator);

    const Array& metadata_values =
        Array::Handle(Z, Array::New(metadata_expressions->length()));

    for (intptr_t i = 0; i < metadata_expressions->length(); i++) {
      const Instance& value =
          constant_evaluator.EvaluateExpression((*metadata_expressions)[i]);
      metadata_values.SetAt(i, value);
    }

    return metadata_values.raw();
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
    TreeNode* kernel_node =
        reinterpret_cast<TreeNode*>(function.kernel_function());
    FunctionNode* function_node = NULL;
    if (kernel_node->IsProcedure()) {
      function_node = Procedure::Cast(kernel_node)->function();
    } else if (kernel_node->IsConstructor()) {
      function_node = Constructor::Cast(kernel_node)->function();
    } else if (kernel_node->IsFunctionNode()) {
      function_node = FunctionNode::Cast(kernel_node);
    } else {
      UNIMPLEMENTED();
      return NULL;
    }

    Thread* thread = Thread::Current();
    Zone* zone_ = thread->zone();
    TranslationHelper helper(thread);
    Script& script = Script::Handle(Z, function.script());
    helper.SetStringOffsets(
        TypedData::Handle(Z, script.kernel_string_offsets()));
    helper.SetStringData(TypedData::Handle(Z, script.kernel_string_data()));
    helper.SetCanonicalNames(
        TypedData::Handle(Z, script.kernel_canonical_names()));
    DartTypeTranslator type_translator(&helper, NULL, true);
    ConstantEvaluator constant_evaluator(/* flow_graph_builder = */ NULL, Z,
                                         &helper, &type_translator);

    const intptr_t positional_count =
        function_node->positional_parameters().length();
    const intptr_t param_count =
        positional_count + function_node->named_parameters().length();
    const Array& param_descriptor = Array::Handle(
        Array::New(param_count * Parser::kParameterEntrySize, Heap::kOld));
    for (intptr_t i = 0; i < param_count; ++i) {
      const intptr_t entry_start = i * Parser::kParameterEntrySize;

      VariableDeclaration* variable;
      if (i < positional_count) {
        variable = function_node->positional_parameters()[i];
      } else {
        variable = function_node->named_parameters()[i - positional_count];
      }

      param_descriptor.SetAt(
          entry_start + Parser::kParameterIsFinalOffset,
          variable->IsFinal() ? Bool::True() : Bool::False());

      if (variable->initializer() != NULL) {
        param_descriptor.SetAt(
            entry_start + Parser::kParameterDefaultValueOffset,
            constant_evaluator.EvaluateExpression(variable->initializer()));
      } else {
        param_descriptor.SetAt(
            entry_start + Parser::kParameterDefaultValueOffset,
            Object::null_instance());
      }

      param_descriptor.SetAt(entry_start + Parser::kParameterMetadataOffset,
                             /* Issue(28434): Missing parameter metadata. */
                             Object::null_instance());
    }
    return param_descriptor.raw();
  } else {
    Thread* thread = Thread::Current();
    Error& error = Error::Handle();
    error = thread->sticky_error();
    thread->clear_sticky_error();
    return error.raw();
  }
}


}  // namespace kernel
}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
