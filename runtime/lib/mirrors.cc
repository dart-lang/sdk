// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/mirrors.h"

#include "lib/invocation_mirror.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/kernel.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)

#define RETURN_OR_PROPAGATE(expr)                                              \
  ObjectPtr result = expr;                                                     \
  if (IsErrorClassId(result->GetClassIdMayBeSmi())) {                          \
    Exceptions::PropagateError(Error::Handle(Error::RawCast(result)));         \
  }                                                                            \
  return result;

static InstancePtr CreateMirror(const String& mirror_class_name,
                                const Array& constructor_arguments) {
  const Library& mirrors_lib = Library::Handle(Library::MirrorsLibrary());
  const String& constructor_name = Symbols::DotUnder();

  const Object& result = Object::Handle(DartLibraryCalls::InstanceCreate(
      mirrors_lib, mirror_class_name, constructor_name, constructor_arguments));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return Instance::Cast(result).ptr();
}

// Conventions:
// * For throwing a NSM in a class klass we use its runtime type as receiver,
//   i.e., klass.RareType().
// * For throwing a NSM in a library, we just pass the null instance as
//   receiver.
static void ThrowNoSuchMethod(const Instance& receiver,
                              const String& function_name,
                              const Array& arguments,
                              const Array& argument_names,
                              const InvocationMirror::Level level,
                              const InvocationMirror::Kind kind) {
  const Smi& invocation_type =
      Smi::Handle(Smi::New(InvocationMirror::EncodeType(level, kind)));

  const Array& args = Array::Handle(Array::New(7));
  args.SetAt(0, receiver);
  args.SetAt(1, function_name);
  args.SetAt(2, invocation_type);
  args.SetAt(3, Object::smi_zero());  // Type arguments length.
  args.SetAt(4, Object::null_type_arguments());
  args.SetAt(5, arguments);
  args.SetAt(6, argument_names);

  const Library& libcore = Library::Handle(Library::CoreLibrary());
  const Class& cls =
      Class::Handle(libcore.LookupClass(Symbols::NoSuchMethodError()));
  const auto& error = cls.EnsureIsFinalized(Thread::Current());
  ASSERT(error == Error::null());
  const Function& throwNew =
      Function::Handle(cls.LookupFunctionAllowPrivate(Symbols::ThrowNew()));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(throwNew, args));
  ASSERT(result.IsError());
  Exceptions::PropagateError(Error::Cast(result));
  UNREACHABLE();
}

static void EnsureConstructorsAreCompiled(const Function& func) {
  // Only generative constructors can have initializing formals.
  if (!func.IsGenerativeConstructor()) return;

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Class& cls = Class::Handle(zone, func.Owner());
  const Error& error = Error::Handle(zone, cls.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
  func.EnsureHasCode();
}

static InstancePtr CreateParameterMirrorList(const Function& func,
                                             const FunctionType& signature,
                                             const Instance& owner_mirror) {
  Thread* const T = Thread::Current();
  Zone* const Z = T->zone();
  HANDLESCOPE(T);
  const intptr_t implicit_param_count = signature.num_implicit_parameters();
  const intptr_t non_implicit_param_count =
      signature.NumParameters() - implicit_param_count;
  const intptr_t index_of_first_optional_param =
      non_implicit_param_count - signature.NumOptionalParameters();
  const intptr_t index_of_first_named_param =
      non_implicit_param_count - signature.NumOptionalNamedParameters();
  const Array& results = Array::Handle(Z, Array::New(non_implicit_param_count));
  const Array& args = Array::Handle(Z, Array::New(9));

  Smi& pos = Smi::Handle(Z);
  String& name = String::Handle(Z);
  Instance& param = Instance::Handle(Z);
  Bool& is_final = Bool::Handle(Z);
  Object& default_value = Object::Handle(Z);
  Object& metadata = Object::Handle(Z);

  // We force compilation of constructors to ensure the types of initializing
  // formals have been corrected. We do not force the compilation of all types
  // of functions because some have no body, e.g. signature functions.
  if (!func.IsNull()) {
    EnsureConstructorsAreCompiled(func);
  }

  bool has_extra_parameter_info = true;
  if (non_implicit_param_count == 0) {
    has_extra_parameter_info = false;
  }
  if (func.IsNull() || func.IsImplicitConstructor()) {
    // This covers the default constructor and forwarding constructors.
    has_extra_parameter_info = false;
  }
  Array& param_descriptor = Array::Handle();
  if (has_extra_parameter_info) {
    // Reparse the function for the following information:
    // * The default value of a parameter.
    // * Whether a parameters has been declared as final.
    // * Any metadata associated with the parameter.
    Object& result = Object::Handle(kernel::BuildParameterDescriptor(func));
    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
    param_descriptor ^= result.ptr();
    ASSERT(param_descriptor.Length() ==
           (Parser::kParameterEntrySize * non_implicit_param_count));
  }

  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(signature)));
  args.SetAt(2, owner_mirror);

  if (!has_extra_parameter_info) {
    is_final = Bool::True().ptr();
    default_value = Object::null();
    metadata = Object::null();
  }

  for (intptr_t i = 0; i < non_implicit_param_count; i++) {
    pos = Smi::New(i);
    if (i >= index_of_first_named_param) {
      // Named parameters are stored in the signature.
      name = signature.ParameterNameAt(implicit_param_count + i);
    } else if (!func.IsNull()) {
      // Positional parameters are stored in the function.
      name = func.ParameterNameAt(implicit_param_count + i);
    } else {
      // We were not given a function, only the type, so create placeholder
      // names for the positional parameters.
      const char* const placeholder = OS::SCreate(Z, ":param%" Pd "", i);
      name = String::New(placeholder);
    }
    if (has_extra_parameter_info) {
      is_final ^= param_descriptor.At(i * Parser::kParameterEntrySize +
                                      Parser::kParameterIsFinalOffset);
      default_value = param_descriptor.At(i * Parser::kParameterEntrySize +
                                          Parser::kParameterDefaultValueOffset);
      metadata = param_descriptor.At(i * Parser::kParameterEntrySize +
                                     Parser::kParameterMetadataOffset);
    }
    ASSERT(default_value.IsNull() || default_value.IsInstance());

    // Arguments 0 (referent) and 2 (owner) are the same for all parameters. See
    // above.
    args.SetAt(1, name);
    args.SetAt(3, pos);
    args.SetAt(4, Bool::Get(i >= index_of_first_optional_param));
    args.SetAt(5, Bool::Get(i >= index_of_first_named_param));
    args.SetAt(6, is_final);
    args.SetAt(7, default_value);
    args.SetAt(8, metadata);
    param = CreateMirror(Symbols::_ParameterMirror(), args);
    results.SetAt(i, param);
  }
  results.MakeImmutable();
  return results.ptr();
}

static InstancePtr CreateTypeVariableMirror(const TypeParameter& param,
                                            const Instance& owner_mirror) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, param);
  args.SetAt(1, String::Handle(param.UserVisibleName()));
  args.SetAt(2, owner_mirror);
  return CreateMirror(Symbols::_TypeVariableMirror(), args);
}

// We create a list in native code and let Dart code create the type mirror
// object and the ordered map.
static InstancePtr CreateTypeVariableList(const Class& cls) {
  const intptr_t num_type_params = cls.NumTypeParameters();
  if (num_type_params == 0) {
    return Object::empty_array().ptr();
  }
  const Array& result = Array::Handle(Array::New(num_type_params * 2));
  TypeParameter& type = TypeParameter::Handle();
  String& name = String::Handle();
  for (intptr_t i = 0; i < num_type_params; i++) {
    type = cls.TypeParameterAt(i, Nullability::kLegacy);
    ASSERT(type.IsFinalized());
    name = type.UserVisibleName();
    result.SetAt(2 * i, name);
    result.SetAt(2 * i + 1, type);
  }
  return result.ptr();
}

static InstancePtr CreateFunctionTypeMirror(const AbstractType& type) {
  ASSERT(type.IsFunctionType());
  const Class& closure_class =
      Class::Handle(IsolateGroup::Current()->object_store()->closure_class());
  const FunctionType& sig = FunctionType::Cast(type);
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(closure_class)));
  args.SetAt(1, MirrorReference::Handle(MirrorReference::New(sig)));
  args.SetAt(2, type);
  return CreateMirror(Symbols::_FunctionTypeMirror(), args);
}

static InstancePtr CreateMethodMirror(const Function& func,
                                      const Instance& owner_mirror,
                                      const AbstractType& instantiator) {
  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));

  String& name = String::Handle(func.name());
  name = String::ScrubNameRetainPrivate(name, func.is_extension_member());
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, instantiator);
  args.SetAt(4, Bool::Get(func.is_static()));

  intptr_t kind_flags = 0;
  kind_flags |=
      (static_cast<intptr_t>(func.is_abstract()) << Mirrors::kAbstract);
  kind_flags |=
      (static_cast<intptr_t>(func.IsGetterFunction()) << Mirrors::kGetter);
  kind_flags |=
      (static_cast<intptr_t>(func.IsSetterFunction()) << Mirrors::kSetter);
  bool is_ctor = (func.kind() == UntaggedFunction::kConstructor);
  kind_flags |= (static_cast<intptr_t>(is_ctor) << Mirrors::kConstructor);
  kind_flags |= (static_cast<intptr_t>(is_ctor && func.is_const())
                 << Mirrors::kConstCtor);
  kind_flags |=
      (static_cast<intptr_t>(is_ctor && func.IsGenerativeConstructor())
       << Mirrors::kGenerativeCtor);
  kind_flags |= (static_cast<intptr_t>(false) << Mirrors::kRedirectingCtor);
  kind_flags |= (static_cast<intptr_t>(is_ctor && func.IsFactory())
                 << Mirrors::kFactoryCtor);
  kind_flags |=
      (static_cast<intptr_t>(func.is_external()) << Mirrors::kExternal);
  bool is_synthetic = func.is_synthetic();
  kind_flags |= (static_cast<intptr_t>(is_synthetic) << Mirrors::kSynthetic);
  kind_flags |= (static_cast<intptr_t>(func.is_extension_member())
                 << Mirrors::kExtensionMember);
  args.SetAt(5, Smi::Handle(Smi::New(kind_flags)));

  return CreateMirror(Symbols::_MethodMirror(), args);
}

static InstancePtr CreateVariableMirror(const Field& field,
                                        const Instance& owner_mirror) {
  const MirrorReference& field_ref =
      MirrorReference::Handle(MirrorReference::New(field));

  const String& name = String::Handle(field.name());

  const Array& args = Array::Handle(Array::New(8));
  args.SetAt(0, field_ref);
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, Object::null_instance());  // Null for type.
  args.SetAt(4, Bool::Get(field.is_static()));
  args.SetAt(5, Bool::Get(field.is_final()));
  args.SetAt(6, Bool::Get(field.is_const()));
  args.SetAt(7, Bool::Get(field.is_extension_member()));

  return CreateMirror(Symbols::_VariableMirror(), args);
}

static InstancePtr CreateClassMirror(const Class& cls,
                                     const AbstractType& type,
                                     const Bool& is_declaration,
                                     const Instance& owner_mirror) {
  ASSERT(!cls.IsDynamicClass());
  ASSERT(!cls.IsVoidClass());
  ASSERT(!cls.IsNeverClass());
  ASSERT(!type.IsNull());
  ASSERT(type.IsFinalized());
  ASSERT(type.IsCanonical());
  const Array& args = Array::Handle(Array::New(9));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, type);
  args.SetAt(2, String::Handle(cls.Name()));
  args.SetAt(3, owner_mirror);
  args.SetAt(4, Bool::Get(cls.is_abstract()));
  args.SetAt(5, Bool::Get(cls.IsGeneric()));
  args.SetAt(6, Bool::Get(cls.is_transformed_mixin_application()));
  args.SetAt(7, cls.NumTypeParameters() == 0 ? Bool::False() : is_declaration);
  args.SetAt(8, Bool::Get(cls.is_enum_class()));
  return CreateMirror(Symbols::_ClassMirror(), args);
}

static bool IsCensoredLibrary(const String& url) {
  static const char* const censored_libraries[] = {
      "dart:_builtin",
      "dart:_vmservice",
      "dart:vmservice_io",
  };
  for (const char* censored_library : censored_libraries) {
    if (url.Equals(censored_library)) {
      return true;
    }
  }
  if (!Api::IsFfiEnabled() && url.Equals(Symbols::DartFfi())) {
    return true;
  }
  return false;
}

static InstancePtr CreateLibraryMirror(Thread* thread, const Library& lib) {
  Zone* zone = thread->zone();
  ASSERT(!lib.IsNull());
  const Array& args = Array::Handle(zone, Array::New(3));
  args.SetAt(0, MirrorReference::Handle(zone, MirrorReference::New(lib)));
  String& str = String::Handle(zone);
  str = lib.name();
  args.SetAt(1, str);
  str = lib.url();
  if (IsCensoredLibrary(str)) {
    // Censored library (grumble).
    return Instance::null();
  }
  args.SetAt(2, str);
  return CreateMirror(Symbols::_LibraryMirror(), args);
}

static InstancePtr CreateCombinatorMirror(const Object& identifiers,
                                          bool is_show) {
  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, identifiers);
  args.SetAt(1, Bool::Get(is_show));
  return CreateMirror(Symbols::_CombinatorMirror(), args);
}

static InstancePtr CreateLibraryDependencyMirror(Thread* thread,
                                                 const Instance& importer,
                                                 const Library& importee,
                                                 const Array& show_names,
                                                 const Array& hide_names,
                                                 const Object& metadata,
                                                 const LibraryPrefix& prefix,
                                                 const String& prefix_name,
                                                 const bool is_import,
                                                 const bool is_deferred) {
  const Instance& importee_mirror =
      Instance::Handle(CreateLibraryMirror(thread, importee));
  if (importee_mirror.IsNull()) {
    // Imported library is censored: censor the import.
    return Instance::null();
  }

  intptr_t n = show_names.IsNull() ? 0 : show_names.Length();
  intptr_t m = hide_names.IsNull() ? 0 : hide_names.Length();
  const Array& combinators = Array::Handle(Array::New(n + m));
  Object& t = Object::Handle();
  intptr_t i = 0;
  for (intptr_t j = 0; j < n; j++) {
    t = show_names.At(j);
    t = CreateCombinatorMirror(t, true);
    combinators.SetAt(i++, t);
  }
  for (intptr_t j = 0; j < m; j++) {
    t = hide_names.At(j);
    t = CreateCombinatorMirror(t, false);
    combinators.SetAt(i++, t);
  }

  const Array& args = Array::Handle(Array::New(7));
  args.SetAt(0, importer);
  if (importee.Loaded() || prefix.IsNull()) {
    // A native extension is never "loaded" by the embedder. Use the fact that
    // it doesn't have an prefix where asa  deferred import does to distinguish
    // it from a deferred import. It will appear like an empty library.
    args.SetAt(1, importee_mirror);
  } else {
    args.SetAt(1, prefix);
  }
  args.SetAt(2, combinators);
  args.SetAt(3, prefix_name);
  args.SetAt(4, Bool::Get(is_import));
  args.SetAt(5, Bool::Get(is_deferred));
  args.SetAt(6, metadata);
  return CreateMirror(Symbols::_LibraryDependencyMirror(), args);
}

static InstancePtr CreateLibraryDependencyMirror(Thread* thread,
                                                 const Instance& importer,
                                                 const Namespace& ns,
                                                 const LibraryPrefix& prefix,
                                                 const bool is_import,
                                                 const bool is_deferred) {
  const Library& importee = Library::Handle(ns.target());
  const Array& show_names = Array::Handle(ns.show_names());
  const Array& hide_names = Array::Handle(ns.hide_names());

  const Library& owner = Library::Handle(ns.owner());
  Object& metadata = Object::Handle(owner.GetMetadata(ns));
  if (metadata.IsError()) {
    Exceptions::PropagateError(Error::Cast(metadata));
    UNREACHABLE();
  }

  auto& prefix_name = String::Handle();
  if (!prefix.IsNull()) {
    prefix_name = prefix.name();
  }

  return CreateLibraryDependencyMirror(thread, importer, importee, show_names,
                                       hide_names, metadata, prefix,
                                       prefix_name, is_import, is_deferred);
}

DEFINE_NATIVE_ENTRY(LibraryMirror_fromPrefix, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(LibraryPrefix, prefix,
                               arguments->NativeArgAt(0));
  const Library& deferred_lib = Library::Handle(prefix.GetLibrary(0));
  if (!deferred_lib.Loaded()) {
    return Instance::null();
  }
  return CreateLibraryMirror(thread, deferred_lib);
}

DEFINE_NATIVE_ENTRY(LibraryMirror_libraryDependencies, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, lib_mirror, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& lib = Library::Handle(ref.GetLibraryReferent());

  Array& ports = Array::Handle();
  Namespace& ns = Namespace::Handle();
  Instance& dep = Instance::Handle();
  LibraryPrefix& prefix = LibraryPrefix::Handle();
  GrowableObjectArray& deps =
      GrowableObjectArray::Handle(GrowableObjectArray::New());

  // Unprefixed imports.
  ports = lib.imports();
  for (intptr_t i = 0; i < ports.Length(); i++) {
    ns ^= ports.At(i);
    if (!ns.IsNull()) {
      dep = CreateLibraryDependencyMirror(thread, lib_mirror, ns, prefix, true,
                                          false);
      if (!dep.IsNull()) {
        deps.Add(dep);
      }
    }
  }

  // Exports.
  ports = lib.exports();
  for (intptr_t i = 0; i < ports.Length(); i++) {
    ns ^= ports.At(i);
    dep = CreateLibraryDependencyMirror(thread, lib_mirror, ns, prefix, false,
                                        false);
    if (!dep.IsNull()) {
      deps.Add(dep);
    }
  }

  // Prefixed imports.
  DictionaryIterator entries(lib);
  Object& entry = Object::Handle();
  while (entries.HasNext()) {
    entry = entries.GetNext();
    if (entry.IsLibraryPrefix()) {
      prefix ^= entry.ptr();
      ports = prefix.imports();
      for (intptr_t i = 0; i < ports.Length(); i++) {
        ns ^= ports.At(i);
        if (!ns.IsNull()) {
          dep = CreateLibraryDependencyMirror(thread, lib_mirror, ns, prefix,
                                              true, prefix.is_deferred_load());
          if (!dep.IsNull()) {
            deps.Add(dep);
          }
        }
      }
    }
  }

  return deps.ptr();
}

static InstancePtr CreateTypeMirror(const AbstractType& type) {
  ASSERT(type.IsFinalized());
  ASSERT(type.IsCanonical());

  if (type.IsFunctionType()) {
    return CreateFunctionTypeMirror(type);
  }
  if (type.IsRecordType()) {
    const Class& cls =
        Class::Handle(IsolateGroup::Current()->object_store()->record_class());
    return CreateClassMirror(cls, AbstractType::Handle(cls.DeclarationType()),
                             Bool::False(), Object::null_instance());
  }
  if (type.HasTypeClass()) {
    const Class& cls = Class::Handle(type.type_class());
    // Handle void and dynamic types.
    if (cls.IsVoidClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Void());
      return CreateMirror(Symbols::_SpecialTypeMirror(), args);
    } else if (cls.IsDynamicClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Dynamic());
      return CreateMirror(Symbols::_SpecialTypeMirror(), args);
    } else if (cls.IsNeverClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Never());
      return CreateMirror(Symbols::_SpecialTypeMirror(), args);
    }
    // TODO(regis): Until mirrors reflect nullability, force kLegacy, except for
    // Null type, which should remain nullable.
    if (!type.IsNullType()) {
      Type& legacy_type = Type::Handle(
          Type::Cast(type).ToNullability(Nullability::kLegacy, Heap::kOld));
      legacy_type ^= legacy_type.Canonicalize(Thread::Current());
      return CreateClassMirror(cls, legacy_type, Bool::False(),
                               Object::null_instance());
    }
    return CreateClassMirror(cls, type, Bool::False(), Object::null_instance());
  } else if (type.IsTypeParameter()) {
    // TODO(regis): Until mirrors reflect nullability, force kLegacy.
    TypeParameter& legacy_type =
        TypeParameter::Handle(TypeParameter::Cast(type).ToNullability(
            Nullability::kLegacy, Heap::kOld));
    legacy_type ^= legacy_type.Canonicalize(Thread::Current());
    return CreateTypeVariableMirror(legacy_type, Object::null_instance());
  }
  UNREACHABLE();
  return Instance::null();
}

static InstancePtr CreateIsolateMirror() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const String& debug_name = String::Handle(String::New(isolate->name()));
  const Library& root_library = Library::Handle(
      thread->zone(), isolate->group()->object_store()->root_library());
  const Instance& root_library_mirror =
      Instance::Handle(CreateLibraryMirror(thread, root_library));

  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, debug_name);
  args.SetAt(1, root_library_mirror);
  return CreateMirror(Symbols::_IsolateMirror(), args);
}

static void VerifyMethodKindShifts() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& lib = Library::Handle(zone, Library::MirrorsLibrary());
  const Class& cls = Class::Handle(
      zone, lib.LookupClassAllowPrivate(Symbols::_MethodMirror()));
  Error& error = Error::Handle(zone);
  error ^= cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());

  Field& field = Field::Handle(zone);
  Smi& value = Smi::Handle(zone);
  String& fname = String::Handle(zone);

#define CHECK_KIND_SHIFT(name)                                                 \
  fname ^= String::New(#name);                                                 \
  field = cls.LookupField(fname);                                              \
  ASSERT(!field.IsNull());                                                     \
  if (field.IsUninitialized()) {                                               \
    error ^= field.InitializeStatic();                                         \
    ASSERT(error.IsNull());                                                    \
  }                                                                            \
  value ^= field.StaticValue();                                                \
  ASSERT(value.Value() == Mirrors::name);
  MIRRORS_KIND_SHIFT_LIST(CHECK_KIND_SHIFT)
#undef CHECK_KIND_SHIFT
#endif
}

static AbstractTypePtr InstantiateType(const AbstractType& type,
                                       const AbstractType& instantiator) {
  // Generic function type parameters are not reified, but mapped to dynamic,
  // i.e. all function type parameters are free with a null vector.
  ASSERT(type.IsFinalized());
  ASSERT(type.IsCanonical());
  Thread* thread = Thread::Current();

  if (type.IsInstantiated()) {
    return type.Canonicalize(thread);
  }
  TypeArguments& instantiator_type_args = TypeArguments::Handle();
  if (!instantiator.IsNull() && instantiator.IsType()) {
    ASSERT(instantiator.IsFinalized());
    if (instantiator.type_class_id() == kInstanceCid) {
      // Handle types created in ClosureMirror_function.
      instantiator_type_args = instantiator.arguments();
    } else {
      instantiator_type_args =
          Type::Cast(instantiator)
              .GetInstanceTypeArguments(thread, /*canonicalize=*/false);
    }
  }
  AbstractType& result = AbstractType::Handle(type.InstantiateFrom(
      instantiator_type_args, Object::null_type_arguments(), kAllFree,
      Heap::kOld));
  ASSERT(result.IsFinalized());
  return result.Canonicalize(thread);
}

DEFINE_NATIVE_ENTRY(MirrorSystem_libraries, 0, 0) {
  const GrowableObjectArray& libraries = GrowableObjectArray::Handle(
      zone, isolate->group()->object_store()->libraries());

  const intptr_t num_libraries = libraries.Length();
  const GrowableObjectArray& library_mirrors = GrowableObjectArray::Handle(
      zone, GrowableObjectArray::New(num_libraries));
  Library& library = Library::Handle(zone);
  Instance& library_mirror = Instance::Handle(zone);

  for (int i = 0; i < num_libraries; i++) {
    library ^= libraries.At(i);
    library_mirror = CreateLibraryMirror(thread, library);
    if (!library_mirror.IsNull() && library.Loaded()) {
      library_mirrors.Add(library_mirror);
    }
  }
  return library_mirrors.ptr();
}

DEFINE_NATIVE_ENTRY(MirrorSystem_isolate, 0, 0) {
  VerifyMethodKindShifts();

  return CreateIsolateMirror();
}

static void ThrowLanguageError(const char* message) {
  const Error& error =
      Error::Handle(LanguageError::New(String::Handle(String::New(message))));
  Exceptions::PropagateError(error);
}

DEFINE_NATIVE_ENTRY(IsolateMirror_loadUri, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, uri, arguments->NativeArgAt(0));

  if (!isolate->group()->HasTagHandler()) {
    ThrowLanguageError("no library handler registered");
  }

  NoReloadScope no_reload(thread);

  // Canonicalize library URI.
  String& canonical_uri = String::Handle(zone);
  if (uri.StartsWith(Symbols::DartScheme())) {
    canonical_uri = uri.ptr();
  } else {
    isolate->BlockClassFinalization();
    const Object& result = Object::Handle(
        zone, isolate->group()->CallTagHandler(
                  Dart_kCanonicalizeUrl,
                  Library::Handle(
                      zone, isolate->group()->object_store()->root_library()),
                  uri));
    isolate->UnblockClassFinalization();
    if (result.IsError()) {
      if (result.IsLanguageError()) {
        Exceptions::ThrowCompileTimeError(LanguageError::Cast(result));
      }
      Exceptions::PropagateError(Error::Cast(result));
    } else if (!result.IsString()) {
      ThrowLanguageError("library handler failed URI canonicalization");
    }

    canonical_uri ^= result.ptr();
  }

  // Return the existing library if it has already been loaded.
  Library& library =
      Library::Handle(zone, Library::LookupLibrary(thread, canonical_uri));
  if (!library.IsNull()) {
    return CreateLibraryMirror(thread, library);
  }

  // Request the embedder to load the library.
  isolate->BlockClassFinalization();
  Object& result = Object::Handle(
      zone, isolate->group()->CallTagHandler(
                Dart_kImportTag,
                Library::Handle(
                    zone, isolate->group()->object_store()->root_library()),
                canonical_uri));
  isolate->UnblockClassFinalization();
  if (result.IsError()) {
    if (result.IsLanguageError()) {
      Exceptions::ThrowCompileTimeError(LanguageError::Cast(result));
    }
    Exceptions::PropagateError(Error::Cast(result));
  }

  // This code assumes a synchronous tag handler (which dart::bin and tonic
  // provide). Strictly though we should complete a future in response to
  // Dart_FinalizeLoading.

  if (!ClassFinalizer::ProcessPendingClasses()) {
    Exceptions::PropagateError(Error::Handle(thread->sticky_error()));
  }

  // Prefer the tag handler's idea of which library is represented by the URI.
  if (result.IsLibrary()) {
    return CreateLibraryMirror(thread, Library::Cast(result));
  }

  if (result.IsNull()) {
    library = Library::LookupLibrary(thread, canonical_uri);
    if (!library.IsNull()) {
      return CreateLibraryMirror(thread, library);
    }
  }

  FATAL("Non-library from tag handler");
}

DEFINE_NATIVE_ENTRY(Mirrors_makeLocalClassMirror, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  ASSERT(!cls.IsNull());
  if (cls.IsDynamicClass() || cls.IsVoidClass() || cls.IsNeverClass()) {
    Exceptions::ThrowArgumentError(type);
    UNREACHABLE();
  }
  return CreateClassMirror(cls, AbstractType::Handle(cls.DeclarationType()),
                           Bool::True(),  // is_declaration
                           Object::null_instance());
}

DEFINE_NATIVE_ENTRY(Mirrors_makeLocalTypeMirror, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  return CreateTypeMirror(type);
}

DEFINE_NATIVE_ENTRY(Mirrors_instantiateGenericType, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(1));

  const Class& clz = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  if (!clz.IsGeneric()) {
    const Array& error_args = Array::Handle(Array::New(3));
    error_args.SetAt(0, type);
    error_args.SetAt(1, String::Handle(String::New("key")));
    error_args.SetAt(2, String::Handle(String::New(
                            "Type must be a generic class or function.")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, error_args);
    UNREACHABLE();
  }
  if (clz.NumTypeParameters() != args.Length()) {
    const Array& error_args = Array::Handle(Array::New(3));
    error_args.SetAt(0, args);
    error_args.SetAt(1, String::Handle(String::New("typeArguments")));
    error_args.SetAt(2, String::Handle(String::New(
                            "Number of type arguments does not match.")));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, error_args);
    UNREACHABLE();
  }

  intptr_t num_expected_type_arguments = args.Length();
  TypeArguments& type_args_obj = TypeArguments::Handle();
  type_args_obj = TypeArguments::New(num_expected_type_arguments);
  AbstractType& type_arg = AbstractType::Handle();
  Instance& instance = Instance::Handle();
  for (intptr_t i = 0; i < args.Length(); i++) {
    instance ^= args.At(i);
    if (!instance.IsType()) {
      const Array& error_args = Array::Handle(Array::New(3));
      error_args.SetAt(0, args);
      error_args.SetAt(1, String::Handle(String::New("typeArguments")));
      error_args.SetAt(2, String::Handle(String::New(
                              "Type arguments must be instances of Type.")));
      Exceptions::ThrowByType(Exceptions::kArgumentValue, error_args);
      UNREACHABLE();
    }
    type_arg ^= args.At(i);
    type_args_obj.SetTypeAt(i, type_arg);
  }

  Type& instantiated_type = Type::Handle(Type::New(clz, type_args_obj));
  instantiated_type ^= ClassFinalizer::FinalizeType(instantiated_type);
  return instantiated_type.ptr();
}

DEFINE_NATIVE_ENTRY(Mirrors_mangleName, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& lib = Library::Handle(ref.GetLibraryReferent());
  return lib.IsPrivate(name) ? lib.PrivateName(name) : name.ptr();
}

DEFINE_NATIVE_ENTRY(MirrorReference_equals, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, b, arguments->NativeArgAt(1));
  return Bool::Get(a.referent() == b.referent()).ptr();
}

DEFINE_NATIVE_ENTRY(DeclarationMirror_metadata, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(0));
  Object& decl = Object::Handle();
  if (reflectee.IsMirrorReference()) {
    const MirrorReference& decl_ref = MirrorReference::Cast(reflectee);
    decl = decl_ref.referent();
  } else if (reflectee.IsTypeParameter()) {
    decl = reflectee.ptr();
  } else {
    UNREACHABLE();
  }

  Class& klass = Class::Handle();
  Library& library = Library::Handle();

  if (decl.IsClass()) {
    klass ^= decl.ptr();
    library = klass.library();
  } else if (decl.IsFunction()) {
    klass = Function::Cast(decl).Owner();
    library = klass.library();
  } else if (decl.IsField()) {
    klass = Field::Cast(decl).Owner();
    library = klass.library();
  } else if (decl.IsLibrary()) {
    library ^= decl.ptr();
  } else if (decl.IsTypeParameter()) {
    // There is no reference from a canonical type parameter to its declaration.
    return Object::empty_array().ptr();
  } else {
    return Object::empty_array().ptr();
  }

  const Object& metadata = Object::Handle(library.GetMetadata(decl));
  if (metadata.IsError()) {
    Exceptions::PropagateError(Error::Cast(metadata));
  }
  return metadata.ptr();
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_call_method, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  // Return get:call() method on class _Closure.
  const auto& getter_name = Symbols::GetCall();
  const Class& closure_class =
      Class::Handle(IsolateGroup::Current()->object_store()->closure_class());
  const Function& get_call = Function::Handle(
      Resolver::ResolveDynamicAnyArgs(zone, closure_class, getter_name,
                                      /*allow_add=*/false));
  ASSERT(!get_call.IsNull());
  return CreateMethodMirror(get_call, owner_mirror, AbstractType::Handle());
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_parameters, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const FunctionType& sig = FunctionType::Handle(ref.GetFunctionTypeReferent());
  return CreateParameterMirrorList(Object::null_function(), sig, owner);
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_return_type, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const FunctionType& sig = FunctionType::Handle(ref.GetFunctionTypeReferent());
  ASSERT(!sig.IsNull());
  AbstractType& type = AbstractType::Handle(sig.result_type());
  // Signatures of function types are instantiated, but not canonical.
  return type.Canonicalize(thread);
}

DEFINE_NATIVE_ENTRY(ClassMirror_libraryUri, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Library& library = Library::Handle(klass.library());
  ASSERT(!library.IsNull());
  return library.url();
}

DEFINE_NATIVE_ENTRY(ClassMirror_supertype, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  ASSERT(super_type.IsNull() || super_type.IsFinalized());
  return super_type.ptr();
}

DEFINE_NATIVE_ENTRY(ClassMirror_supertype_instantiated, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  return InstantiateType(super_type, type);
}

DEFINE_NATIVE_ENTRY(ClassMirror_interfaces, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  const Error& error = Error::Handle(cls.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  return cls.interfaces();
}

DEFINE_NATIVE_ENTRY(ClassMirror_interfaces_instantiated, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  const Error& error = Error::Handle(cls.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  Array& interfaces = Array::Handle(cls.interfaces());
  Array& interfaces_inst = Array::Handle(Array::New(interfaces.Length()));
  AbstractType& interface = AbstractType::Handle();

  for (int i = 0; i < interfaces.Length(); i++) {
    interface ^= interfaces.At(i);
    interface = InstantiateType(interface, type);
    interfaces_inst.SetAt(i, interface);
  }

  return interfaces_inst.ptr();
}

DEFINE_NATIVE_ENTRY(ClassMirror_mixin, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  AbstractType& mixin_type = AbstractType::Handle();
  if (cls.is_transformed_mixin_application()) {
    const Array& interfaces = Array::Handle(cls.interfaces());
    mixin_type ^= interfaces.At(interfaces.Length() - 1);
  }
  ASSERT(mixin_type.IsNull() || mixin_type.IsFinalized());
  return mixin_type.ptr();
}

DEFINE_NATIVE_ENTRY(ClassMirror_mixin_instantiated, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, instantiator,
                               arguments->NativeArgAt(1));
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  AbstractType& mixin_type = AbstractType::Handle();
  if (cls.is_transformed_mixin_application()) {
    const Array& interfaces = Array::Handle(cls.interfaces());
    mixin_type ^= interfaces.At(interfaces.Length() - 1);
  }
  if (mixin_type.IsNull()) {
    return mixin_type.ptr();
  }

  return InstantiateType(mixin_type, instantiator);
}

DEFINE_NATIVE_ENTRY(ClassMirror_members, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(AbstractType, owner_instantiator,
                      arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(2));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Error& error = Error::Handle(klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  const Array& fields = Array::Handle(klass.fields());
  const intptr_t num_fields = fields.Length();

  const Array& functions = Array::Handle(klass.current_functions());
  const intptr_t num_functions = functions.Length();

  Instance& member_mirror = Instance::Handle();
  const GrowableObjectArray& member_mirrors = GrowableObjectArray::Handle(
      GrowableObjectArray::New(num_fields + num_functions));

  Field& field = Field::Handle();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= fields.At(i);
    if (field.is_reflectable()) {
      member_mirror = CreateVariableMirror(field, owner_mirror);
      member_mirrors.Add(member_mirror);
    }
  }

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.is_reflectable() &&
        (func.kind() == UntaggedFunction::kRegularFunction ||
         func.kind() == UntaggedFunction::kGetterFunction ||
         func.kind() == UntaggedFunction::kSetterFunction)) {
      member_mirror =
          CreateMethodMirror(func, owner_mirror, owner_instantiator);
      member_mirrors.Add(member_mirror);
    }
  }

  return member_mirrors.ptr();
}

DEFINE_NATIVE_ENTRY(ClassMirror_constructors, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(AbstractType, owner_instantiator,
                      arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(2));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Error& error = Error::Handle(klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  const Array& functions = Array::Handle(klass.current_functions());
  const intptr_t num_functions = functions.Length();

  Instance& constructor_mirror = Instance::Handle();
  const GrowableObjectArray& constructor_mirrors =
      GrowableObjectArray::Handle(GrowableObjectArray::New(num_functions));

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.is_reflectable() &&
        func.kind() == UntaggedFunction::kConstructor) {
      constructor_mirror =
          CreateMethodMirror(func, owner_mirror, owner_instantiator);
      constructor_mirrors.Add(constructor_mirror);
    }
  }

  return constructor_mirrors.ptr();
}

DEFINE_NATIVE_ENTRY(LibraryMirror_members, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(zone, ref.GetLibraryReferent());

  library.EnsureTopLevelClassIsFinalized();

  Instance& member_mirror = Instance::Handle(zone);
  const GrowableObjectArray& member_mirrors =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());

  Object& entry = Object::Handle(zone);
  DictionaryIterator entries(library);

  Error& error = Error::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);

  while (entries.HasNext()) {
    entry = entries.GetNext();
    if (entry.IsClass()) {
      const Class& klass = Class::Cast(entry);
      ASSERT(!klass.IsDynamicClass());
      ASSERT(!klass.IsVoidClass());
      ASSERT(!klass.IsNeverClass());
      error = klass.EnsureIsFinalized(thread);
      if (!error.IsNull()) {
        Exceptions::PropagateError(error);
      }
      type = klass.DeclarationType();
      member_mirror = CreateClassMirror(klass, type,
                                        Bool::True(),  // is_declaration
                                        owner_mirror);
      member_mirrors.Add(member_mirror);
    } else if (entry.IsField()) {
      const Field& field = Field::Cast(entry);
      if (field.is_reflectable()) {
        member_mirror = CreateVariableMirror(field, owner_mirror);
        member_mirrors.Add(member_mirror);
      }
    } else if (entry.IsFunction()) {
      const Function& func = Function::Cast(entry);
      if (func.is_reflectable() &&
          (func.kind() == UntaggedFunction::kRegularFunction ||
           func.kind() == UntaggedFunction::kGetterFunction ||
           func.kind() == UntaggedFunction::kSetterFunction)) {
        member_mirror =
            CreateMethodMirror(func, owner_mirror, AbstractType::Handle());
        member_mirrors.Add(member_mirror);
      }
    }
  }

  return member_mirrors.ptr();
}

DEFINE_NATIVE_ENTRY(ClassMirror_type_variables, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
  return CreateTypeVariableList(klass);
}

DEFINE_NATIVE_ENTRY(ClassMirror_type_arguments, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));

  const Class& cls = Class::Handle(
      type.IsFunctionType()
          ? IsolateGroup::Current()->object_store()->closure_class()
          : type.type_class());
  const intptr_t num_params = cls.NumTypeParameters();

  if (num_params == 0) {
    return Object::empty_array().ptr();
  }

  const Array& result = Array::Handle(Array::New(num_params));
  AbstractType& arg_type = AbstractType::Handle();
  Instance& type_mirror = Instance::Handle();
  const TypeArguments& args =
      TypeArguments::Handle(Type::Cast(type).arguments());

  // Handle argument lists that have been optimized away, because either no
  // arguments have been provided, or all arguments are dynamic. Return a list
  // of typemirrors on dynamic in this case.
  if (args.IsNull()) {
    arg_type = Object::dynamic_type().ptr();
    type_mirror = CreateTypeMirror(arg_type);
    for (intptr_t i = 0; i < num_params; i++) {
      result.SetAt(i, type_mirror);
    }
    return result.ptr();
  }

  ASSERT(args.Length() == num_params);
  for (intptr_t i = 0; i < num_params; i++) {
    arg_type = args.TypeAt(i);
    type_mirror = CreateTypeMirror(arg_type);
    result.SetAt(i, type_mirror);
  }
  return result.ptr();
}

DEFINE_NATIVE_ENTRY(TypeVariableMirror_owner, 0, 1) {
  // Type parameters do not have a reference to their owner anymore.
  const AbstractType& type = AbstractType::Handle(Type::NullType());
  Class& owner = Class::Handle(type.type_class());
  return CreateClassMirror(owner, type,
                           Bool::True(),  // is_declaration
                           Instance::null_instance());
}

DEFINE_NATIVE_ENTRY(TypeVariableMirror_upper_bound, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypeParameter, param, arguments->NativeArgAt(0));
  return param.bound();
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invoke, 0, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));
  RETURN_OR_PROPAGATE(reflectee.Invoke(function_name, args, arg_names));
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invokeGetter, 0, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));
  RETURN_OR_PROPAGATE(reflectee.InvokeGetter(getter_name));
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invokeSetter, 0, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));
  RETURN_OR_PROPAGATE(reflectee.InvokeSetter(setter_name, value));
}

DEFINE_NATIVE_ENTRY(InstanceMirror_computeType, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0));
  const AbstractType& type = AbstractType::Handle(instance.GetType(Heap::kNew));
  // The static type of null is specified to be the bottom type, however, the
  // runtime type of null is the Null type, which we correctly return here.
  return type.Canonicalize(thread);
}

DEFINE_NATIVE_ENTRY(ClosureMirror_function, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  ASSERT(!closure.IsNull());

  Function& function = Function::Handle();
  bool callable = closure.IsCallable(&function);
  if (callable) {
    const Function& parent = Function::Handle(function.parent_function());
    if (function.IsImplicitClosureFunction() || parent.is_extension_member()) {
      // The VM uses separate Functions for tear-offs, but the mirrors consider
      // the tear-offs to be the same as the torn-off methods. Avoid handing out
      // a reference to the tear-off here to avoid a special case in the
      // the equality test.
      // In the case of extension methods also we avoid handing out a reference
      // to the tear-off and instead get the parent function of the
      // anonymous closure.
      function = parent.ptr();
    }

    Type& instantiator = Type::Handle();
    if (closure.IsClosure()) {
      const TypeArguments& arguments = TypeArguments::Handle(
          Closure::Cast(closure).instantiator_type_arguments());
      // TODO(regis): Mirrors need work to properly support generic functions.
      // The 'instantiator' created below should not be a type, but two type
      // argument vectors: instantiator_type_arguments and
      // function_type_arguments.
      const Class& cls = Class::Handle(
          IsolateGroup::Current()->object_store()->object_class());
      instantiator = Type::New(cls, arguments);
      instantiator.SetIsFinalized();
    }
    return CreateMethodMirror(function, Instance::null_instance(),
                              instantiator);
  }
  return Instance::null();
}

DEFINE_NATIVE_ENTRY(ClassMirror_invoke, 0, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));
  RETURN_OR_PROPAGATE(klass.Invoke(function_name, args, arg_names));
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeGetter, 0, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));
  RETURN_OR_PROPAGATE(klass.InvokeGetter(getter_name, true));
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeSetter, 0, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));
  RETURN_OR_PROPAGATE(klass.InvokeSetter(setter_name, value));
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeConstructor, 0, 5) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, constructor_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, explicit_args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));

  const Error& error =
      Error::Handle(zone, klass.EnsureIsAllocateFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  const String& klass_name = String::Handle(klass.Name());
  String& external_constructor_name = String::Handle(klass_name.ptr());
  String& internal_constructor_name =
      String::Handle(String::Concat(klass_name, Symbols::Dot()));
  if (!constructor_name.IsNull() && constructor_name.Length() > 0) {
    internal_constructor_name =
        String::Concat(internal_constructor_name, constructor_name);
    external_constructor_name = internal_constructor_name.ptr();
  }

  Function& lookup_constructor = Function::Handle(
      Resolver::ResolveFunction(zone, klass, internal_constructor_name));

  if (lookup_constructor.IsNull() ||
      (lookup_constructor.kind() != UntaggedFunction::kConstructor) ||
      !lookup_constructor.is_reflectable()) {
    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                      external_constructor_name, explicit_args, arg_names,
                      InvocationMirror::kConstructor,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  if (klass.is_abstract() && !lookup_constructor.IsFactory()) {
    const Array& error_args = Array::Handle(Array::New(3));
    error_args.SetAt(0, klass_name);
    // 1 = script url
    // 2 = token position
    Exceptions::ThrowByType(Exceptions::kAbstractClassInstantiation,
                            error_args);
    UNREACHABLE();
  }

  ASSERT(!type.IsNull());
  TypeArguments& type_arguments = TypeArguments::Handle();
  if (!type.IsInstantiated()) {
    // Must have been a declaration type.
    const Type& rare_type = Type::Handle(klass.RareType());
    ASSERT(rare_type.IsInstantiated());
    type_arguments = rare_type.GetInstanceTypeArguments(thread);
  } else {
    type_arguments = type.GetInstanceTypeArguments(thread);
  }

  Class& redirected_klass = Class::Handle(klass.ptr());
  const intptr_t num_explicit_args = explicit_args.Length();
  const intptr_t num_implicit_args = 1;
  const Array& args =
      Array::Handle(Array::New(num_implicit_args + num_explicit_args));

  // Copy over the explicit arguments.
  Object& explicit_argument = Object::Handle();
  for (int i = 0; i < num_explicit_args; i++) {
    explicit_argument = explicit_args.At(i);
    args.SetAt(i + num_implicit_args, explicit_argument);
  }

  const int kTypeArgsLen = 0;
  const Array& args_descriptor_array = Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, args.Length(), arg_names));

  ArgumentsDescriptor args_descriptor(args_descriptor_array);
  if (!lookup_constructor.AreValidArguments(args_descriptor, nullptr)) {
    external_constructor_name = lookup_constructor.name();
    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                      external_constructor_name, explicit_args, arg_names,
                      InvocationMirror::kConstructor,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }
#if defined(DEBUG)
  // Make sure the receiver is the null value, so that DoArgumentTypesMatch does
  // not attempt to retrieve the instantiator type arguments from the receiver.
  explicit_argument = args.At(args_descriptor.FirstArgIndex());
  ASSERT(explicit_argument.IsNull());
#endif
  const Object& type_error =
      Object::Handle(lookup_constructor.DoArgumentTypesMatch(
          args, args_descriptor, type_arguments));
  if (!type_error.IsNull()) {
    Exceptions::PropagateError(Error::Cast(type_error));
    UNREACHABLE();
  }

  Instance& new_object = Instance::Handle();
  if (lookup_constructor.IsGenerativeConstructor()) {
    // Constructors get the uninitialized object.
    // Note we have delayed allocation until after the function
    // type and argument matching checks.
    new_object = Instance::New(redirected_klass);
    if (!type_arguments.IsNull()) {
      // The type arguments will be null if the class has no type parameters, in
      // which case the following call would fail because there is no slot
      // reserved in the object for the type vector.
      new_object.SetTypeArguments(type_arguments);
    }
    args.SetAt(0, new_object);
  } else {
    // Factories get type arguments.
    args.SetAt(0, type_arguments);
  }

  // Invoke the constructor and return the new object.
  const Object& result = Object::Handle(DartEntry::InvokeFunction(
      lookup_constructor, args, args_descriptor_array));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }

  // Factories may return null.
  ASSERT(result.IsInstance() || result.IsNull());

  if (lookup_constructor.IsGenerativeConstructor()) {
    return new_object.ptr();
  } else {
    return result.ptr();
  }
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invoke, 0, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));
  RETURN_OR_PROPAGATE(library.Invoke(function_name, args, arg_names));
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invokeGetter, 0, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));
  RETURN_OR_PROPAGATE(library.InvokeGetter(getter_name, true));
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invokeSetter, 0, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));
  RETURN_OR_PROPAGATE(library.InvokeSetter(setter_name, value));
}

DEFINE_NATIVE_ENTRY(MethodMirror_owner, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  if (func.IsNonImplicitClosureFunction()) {
    return CreateMethodMirror(Function::Handle(func.parent_function()),
                              Object::null_instance(), instantiator);
  }
  const Class& owner = Class::Handle(func.Owner());
  if (owner.IsTopLevel()) {
    return CreateLibraryMirror(thread, Library::Handle(owner.library()));
  }

  AbstractType& type = AbstractType::Handle(owner.DeclarationType());
  return CreateClassMirror(owner, type, Bool::True(), Object::null_instance());
}

DEFINE_NATIVE_ENTRY(MethodMirror_parameters, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  const FunctionType& sig = FunctionType::Handle(func.signature());
  return CreateParameterMirrorList(func, sig, owner);
}

DEFINE_NATIVE_ENTRY(MethodMirror_return_type, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(1));
  // We handle constructors in Dart code.
  ASSERT(!func.IsGenerativeConstructor());
  AbstractType& type = AbstractType::Handle(func.result_type());
  type =
      type.Canonicalize(thread);  // Instantiated signatures are not canonical.
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(MethodMirror_source, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return func.GetSource();
}

static InstancePtr CreateSourceLocation(const String& uri,
                                        intptr_t line,
                                        intptr_t column) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, uri);
  args.SetAt(1, Smi::Handle(Smi::New(line)));
  args.SetAt(2, Smi::Handle(Smi::New(column)));
  return CreateMirror(Symbols::_SourceLocation(), args);
}

DEFINE_NATIVE_ENTRY(DeclarationMirror_location, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(0));
  Object& decl = Object::Handle(zone);
  if (reflectee.IsMirrorReference()) {
    const MirrorReference& decl_ref = MirrorReference::Cast(reflectee);
    decl = decl_ref.referent();
  } else if (reflectee.IsTypeParameter()) {
    decl = reflectee.ptr();
  } else {
    UNREACHABLE();
  }

  Script& script = Script::Handle(zone);
  TokenPosition token_pos = TokenPosition::kNoSource;

  if (decl.IsFunction()) {
    const Function& func = Function::Cast(decl);
    if (func.IsImplicitConstructor()) {
      // These are synthetic methods; they have no source.
      return Instance::null();
    }
    script = func.script();
    token_pos = func.token_pos();
  } else if (decl.IsClass()) {
    const Class& cls = Class::Cast(decl);
    if (cls.is_synthesized_class() && !cls.is_enum_class()) {
      return Instance::null();  // Synthetic.
    }
    script = cls.script();
    token_pos = cls.token_pos();
  } else if (decl.IsField()) {
    const Field& field = Field::Cast(decl);
    script = field.Script();
    token_pos = field.token_pos();
  } else if (decl.IsTypeParameter()) {
    return Instance::null();
  } else if (decl.IsLibrary()) {
    const Library& lib = Library::Cast(decl);
    if (lib.ptr() == Library::NativeWrappersLibrary()) {
      return Instance::null();  // No source.
    }
    const Array& scripts = Array::Handle(zone, lib.LoadedScripts());
    ASSERT(scripts.Length() > 0);
    script ^= scripts.At(scripts.Length() - 1);
    ASSERT(!script.IsNull());
    const String& uri = String::Handle(zone, script.url());
    return CreateSourceLocation(uri, 1, 1);
  } else {
    FATAL("Unexpected declaration type: %s", decl.ToCString());
  }

  ASSERT(!script.IsNull());
  if (token_pos == TokenPosition::kNoSource) {
    return Instance::null();
  }

  const String& uri = String::Handle(zone, script.url());
  intptr_t from_line = 0, from_col = 0;
  script.GetTokenLocation(token_pos, &from_line, &from_col);
  return CreateSourceLocation(uri, from_line, from_col);
}

DEFINE_NATIVE_ENTRY(ParameterMirror_type, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, pos, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(2));
  const FunctionType& signature =
      FunctionType::Handle(ref.GetFunctionTypeReferent());
  AbstractType& type = AbstractType::Handle(signature.ParameterTypeAt(
      signature.num_implicit_parameters() + pos.Value()));
  type =
      type.Canonicalize(thread);  // Instantiated signatures are not canonical.
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(VariableMirror_type, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Field& field = Field::Handle(ref.GetFieldReferent());
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(1));
  const AbstractType& type = AbstractType::Handle(field.type());
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(TypeMirror_subtypeTest, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, b, arguments->NativeArgAt(1));
  return Bool::Get(a.IsSubtypeOf(b, Heap::kNew)).ptr();
}

#endif  // !DART_PRECOMPILED_RUNTIME

}  // namespace dart
