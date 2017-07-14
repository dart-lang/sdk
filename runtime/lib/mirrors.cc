// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/mirrors.h"

#include "lib/invocation_mirror.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/kernel_to_il.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)

#define PROPAGATE_IF_MALFORMED(type)                                           \
  if (type.IsMalformed()) {                                                    \
    Exceptions::PropagateError(Error::Handle(type.error()));                   \
  }

static RawInstance* CreateMirror(const String& mirror_class_name,
                                 const Array& constructor_arguments) {
  const Library& mirrors_lib = Library::Handle(Library::MirrorsLibrary());
  const String& constructor_name = Symbols::Dot();

  const Object& result = Object::Handle(DartLibraryCalls::InstanceCreate(
      mirrors_lib, mirror_class_name, constructor_name, constructor_arguments));
  ASSERT(!result.IsError());
  return Instance::Cast(result).raw();
}

// Conventions:
// * For throwing a NSM in a class klass we use its runtime type as receiver,
//   i.e., klass.RareType().
// * For throwing a NSM in a library, we just pass the null instance as
//   receiver.
static void ThrowNoSuchMethod(const Instance& receiver,
                              const String& function_name,
                              const Function& function,
                              const Array& arguments,
                              const Array& argument_names,
                              const InvocationMirror::Call call,
                              const InvocationMirror::Type type) {
  const Smi& invocation_type =
      Smi::Handle(Smi::New(InvocationMirror::EncodeType(call, type)));

  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, receiver);
  args.SetAt(1, function_name);
  args.SetAt(2, invocation_type);
  args.SetAt(3, arguments);
  if (!argument_names.IsNull() && (argument_names.Length() > 0)) {
    // Empty and null are treated differently for some reason. Don't pass empty
    // to match the non-reflective error.
    args.SetAt(4, argument_names);
  }
  if (!function.IsNull()) {
    const Array& array = Array::Handle(Array::New(1));
    array.SetAt(0, String::Handle(function.UserVisibleFormalParameters()));
    args.SetAt(5, array);
  }

  const Library& libcore = Library::Handle(Library::CoreLibrary());
  const Class& NoSuchMethodError =
      Class::Handle(libcore.LookupClass(Symbols::NoSuchMethodError()));
  const Function& throwNew = Function::Handle(
      NoSuchMethodError.LookupFunctionAllowPrivate(Symbols::ThrowNew()));
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

static RawInstance* CreateParameterMirrorList(const Function& func,
                                              const Instance& owner_mirror) {
  HANDLESCOPE(Thread::Current());
  const intptr_t implicit_param_count = func.NumImplicitParameters();
  const intptr_t non_implicit_param_count =
      func.NumParameters() - implicit_param_count;
  const intptr_t index_of_first_optional_param =
      non_implicit_param_count - func.NumOptionalParameters();
  const intptr_t index_of_first_named_param =
      non_implicit_param_count - func.NumOptionalNamedParameters();
  const Array& results = Array::Handle(Array::New(non_implicit_param_count));
  const Array& args = Array::Handle(Array::New(9));

  Smi& pos = Smi::Handle();
  String& name = String::Handle();
  Instance& param = Instance::Handle();
  Bool& is_final = Bool::Handle();
  Object& default_value = Object::Handle();
  Object& metadata = Object::Handle();

  // We force compilation of constructors to ensure the types of initializing
  // formals have been corrected. We do not force the compilation of all types
  // of functions because some have no body, e.g. signature functions.
  EnsureConstructorsAreCompiled(func);

  bool has_extra_parameter_info = true;
  if (non_implicit_param_count == 0) {
    has_extra_parameter_info = false;
  }
  if (func.IsImplicitConstructor()) {
    // This covers the default constructor and forwarding constructors.
    has_extra_parameter_info = false;
  }
  if (func.IsSignatureFunction() &&
      (func.token_pos() == TokenPosition::kNoSource)) {
    // Signature functions (except those describing typedefs) get canonicalized,
    // hence do not have a token position, and therefore cannot be reparsed.
    has_extra_parameter_info = false;
  }

  Array& param_descriptor = Array::Handle();
  if (has_extra_parameter_info) {
    // Reparse the function for the following information:
    // * The default value of a parameter.
    // * Whether a parameters has been declared as final.
    // * Any metadata associated with the parameter.
    Object& result = Object::Handle();
    if (func.kernel_offset() > 0) {
      result = kernel::BuildParameterDescriptor(func);
    } else {
      result = Parser::ParseFunctionParameters(func);
    }
    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
    param_descriptor ^= result.raw();
    ASSERT(param_descriptor.Length() ==
           (Parser::kParameterEntrySize * non_implicit_param_count));
  }

  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));
  args.SetAt(2, owner_mirror);

  if (!has_extra_parameter_info) {
    is_final ^= Bool::True().raw();
    default_value = Object::null();
    metadata = Object::null();
  }

  for (intptr_t i = 0; i < non_implicit_param_count; i++) {
    pos ^= Smi::New(i);
    name ^= func.ParameterNameAt(implicit_param_count + i);
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
    param ^= CreateMirror(Symbols::_LocalParameterMirror(), args);
    results.SetAt(i, param);
  }
  results.MakeImmutable();
  return results.raw();
}

static RawInstance* CreateTypeVariableMirror(const TypeParameter& param,
                                             const Instance& owner_mirror) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, param);
  args.SetAt(1, String::Handle(param.name()));
  args.SetAt(2, owner_mirror);
  return CreateMirror(Symbols::_LocalTypeVariableMirror(), args);
}

// We create a list in native code and let Dart code create the type mirror
// object and the ordered map.
static RawInstance* CreateTypeVariableList(const Class& cls) {
  const TypeArguments& args = TypeArguments::Handle(cls.type_parameters());
  if (args.IsNull()) {
    return Object::empty_array().raw();
  }
  const Array& result = Array::Handle(Array::New(args.Length() * 2));
  TypeParameter& type = TypeParameter::Handle();
  String& name = String::Handle();
  for (intptr_t i = 0; i < args.Length(); i++) {
    type ^= args.TypeAt(i);
    ASSERT(type.IsTypeParameter());
    PROPAGATE_IF_MALFORMED(type);
    ASSERT(type.IsFinalized());
    name ^= type.name();
    result.SetAt(2 * i, name);
    result.SetAt(2 * i + 1, type);
  }
  return result.raw();
}

static RawInstance* CreateTypedefMirror(const Class& cls,
                                        const AbstractType& type,
                                        const Bool& is_declaration,
                                        const Instance& owner_mirror) {
  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, type);
  args.SetAt(2, String::Handle(cls.Name()));
  args.SetAt(3, Bool::Get(cls.IsGeneric()));
  args.SetAt(4, cls.IsGeneric() ? is_declaration : Bool::False());
  args.SetAt(5, owner_mirror);
  return CreateMirror(Symbols::_LocalTypedefMirror(), args);
}

static RawInstance* CreateFunctionTypeMirror(const AbstractType& type) {
  ASSERT(type.IsFunctionType());
  const Class& cls = Class::Handle(Type::Cast(type).type_class());
  const Function& func = Function::Handle(Type::Cast(type).signature());
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, MirrorReference::Handle(MirrorReference::New(func)));
  args.SetAt(2, type);
  return CreateMirror(Symbols::_LocalFunctionTypeMirror(), args);
}

static RawInstance* CreateMethodMirror(const Function& func,
                                       const Instance& owner_mirror,
                                       const AbstractType& instantiator) {
  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));

  String& name = String::Handle(func.name());
  name = String::ScrubNameRetainPrivate(name);
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, instantiator);
  args.SetAt(4, Bool::Get(func.is_static()));

  intptr_t kind_flags = 0;
  kind_flags |= (func.is_abstract() << Mirrors::kAbstract);
  kind_flags |= (func.IsGetterFunction() << Mirrors::kGetter);
  kind_flags |= (func.IsSetterFunction() << Mirrors::kSetter);
  bool is_ctor = (func.kind() == RawFunction::kConstructor);
  kind_flags |= (is_ctor << Mirrors::kConstructor);
  kind_flags |= ((is_ctor && func.is_const()) << Mirrors::kConstCtor);
  kind_flags |=
      ((is_ctor && func.IsGenerativeConstructor()) << Mirrors::kGenerativeCtor);
  kind_flags |=
      ((is_ctor && func.is_redirecting()) << Mirrors::kRedirectingCtor);
  kind_flags |= ((is_ctor && func.IsFactory()) << Mirrors::kFactoryCtor);
  kind_flags |= (func.is_external() << Mirrors::kExternal);
  args.SetAt(5, Smi::Handle(Smi::New(kind_flags)));

  return CreateMirror(Symbols::_LocalMethodMirror(), args);
}

static RawInstance* CreateVariableMirror(const Field& field,
                                         const Instance& owner_mirror) {
  const MirrorReference& field_ref =
      MirrorReference::Handle(MirrorReference::New(field));

  const String& name = String::Handle(field.name());

  const Array& args = Array::Handle(Array::New(7));
  args.SetAt(0, field_ref);
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, Object::null_instance());  // Null for type.
  args.SetAt(4, Bool::Get(field.is_static()));
  args.SetAt(5, Bool::Get(field.is_final()));
  args.SetAt(6, Bool::Get(field.is_const()));

  return CreateMirror(Symbols::_LocalVariableMirror(), args);
}

static RawInstance* CreateClassMirror(const Class& cls,
                                      const AbstractType& type,
                                      const Bool& is_declaration,
                                      const Instance& owner_mirror) {
  if (type.IsTypeRef()) {
    AbstractType& ref_type = AbstractType::Handle(TypeRef::Cast(type).type());
    ASSERT(!ref_type.IsTypeRef());
    ASSERT(ref_type.IsCanonical());
    return CreateClassMirror(cls, ref_type, is_declaration, owner_mirror);
  }
  ASSERT(!cls.IsDynamicClass() && !cls.IsVoidClass());
  ASSERT(!type.IsNull());
  ASSERT(type.IsFinalized());

  if (cls.IsTypedefClass()) {
    return CreateTypedefMirror(cls, type, is_declaration, owner_mirror);
  }

  const Array& args = Array::Handle(Array::New(9));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, type);
  // Note that the VM does not consider mixin application aliases to be mixin
  // applications, so this only covers anonymous mixin applications. We do not
  // set the names of anonymous mixin applications here because the mirrors
  // use a different naming convention than the VM (lib.S with lib.M and S&M
  // respectively).
  if (!cls.IsMixinApplication()) {
    args.SetAt(2, String::Handle(cls.Name()));
  }
  args.SetAt(3, owner_mirror);
  args.SetAt(4, Bool::Get(cls.is_abstract()));
  args.SetAt(5, Bool::Get(cls.IsGeneric()));
  args.SetAt(6, Bool::Get(cls.is_mixin_app_alias()));
  args.SetAt(7, cls.NumTypeParameters() == 0 ? Bool::False() : is_declaration);
  args.SetAt(8, Bool::Get(cls.is_enum_class()));
  return CreateMirror(Symbols::_LocalClassMirror(), args);
}

static RawInstance* CreateLibraryMirror(Thread* thread, const Library& lib) {
  Zone* zone = thread->zone();
  ASSERT(!lib.IsNull());
  const Array& args = Array::Handle(zone, Array::New(3));
  args.SetAt(0, MirrorReference::Handle(zone, MirrorReference::New(lib)));
  String& str = String::Handle(zone);
  str = lib.name();
  args.SetAt(1, str);
  str = lib.url();
  const char* censored_libraries[] = {
      "dart:_builtin", "dart:_blink", "dart:_vmservice", NULL,
  };
  for (intptr_t i = 0; censored_libraries[i] != NULL; i++) {
    if (str.Equals(censored_libraries[i])) {
      // Censored library (grumble).
      return Instance::null();
    }
  }
  if (str.Equals("dart:io")) {
    // Hack around dart:io being loaded into non-service isolates in Dartium.
    Isolate* isolate = thread->isolate();
    const GrowableObjectArray& libraries =
        GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
    Library& other_lib = Library::Handle(zone);
    String& other_uri = String::Handle(zone);
    for (intptr_t i = 0; i < libraries.Length(); i++) {
      other_lib ^= libraries.At(i);
      other_uri = other_lib.url();
      if (other_uri.Equals("dart:html")) {
        return Instance::null();
      }
    }
  }
  args.SetAt(2, str);
  return CreateMirror(Symbols::_LocalLibraryMirror(), args);
}

static RawInstance* CreateCombinatorMirror(const Object& identifiers,
                                           bool is_show) {
  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, identifiers);
  args.SetAt(1, Bool::Get(is_show));
  return CreateMirror(Symbols::_LocalCombinatorMirror(), args);
}

static RawInstance* CreateLibraryDependencyMirror(Thread* thread,
                                                  const Instance& importer,
                                                  const Namespace& ns,
                                                  const LibraryPrefix& prefix,
                                                  const bool is_import,
                                                  const bool is_deferred) {
  const Library& importee = Library::Handle(ns.library());
  const Instance& importee_mirror =
      Instance::Handle(CreateLibraryMirror(thread, importee));
  if (importee_mirror.IsNull()) {
    // Imported library is censored: censor the import.
    return Instance::null();
  }

  const Array& show_names = Array::Handle(ns.show_names());
  const Array& hide_names = Array::Handle(ns.hide_names());
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

  Object& metadata = Object::Handle(ns.GetMetadata());
  if (metadata.IsError()) {
    Exceptions::PropagateError(Error::Cast(metadata));
    UNREACHABLE();
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
  args.SetAt(3, prefix.IsNull() ? Object::null_object()
                                : String::Handle(prefix.name()));
  args.SetAt(4, Bool::Get(is_import));
  args.SetAt(5, Bool::Get(is_deferred));
  args.SetAt(6, metadata);
  return CreateMirror(Symbols::_LocalLibraryDependencyMirror(), args);
}

DEFINE_NATIVE_ENTRY(LibraryMirror_fromPrefix, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(LibraryPrefix, prefix,
                               arguments->NativeArgAt(0));
  const Library& deferred_lib = Library::Handle(prefix.GetLibrary(0));
  if (!deferred_lib.Loaded()) {
    return Instance::null();
  }
  return CreateLibraryMirror(thread, deferred_lib);
}

DEFINE_NATIVE_ENTRY(LibraryMirror_libraryDependencies, 2) {
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
      prefix ^= entry.raw();
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

  return deps.raw();
}

static RawInstance* CreateTypeMirror(const AbstractType& type) {
  if (type.IsTypeRef()) {
    AbstractType& ref_type = AbstractType::Handle(TypeRef::Cast(type).type());
    ASSERT(!ref_type.IsTypeRef());
    ASSERT(ref_type.IsCanonical());
    return CreateTypeMirror(ref_type);
  }
  ASSERT(type.IsFinalized());
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsCanonical() || type.IsTypeParameter() || type.IsBoundedType());

  if (type.IsFunctionType()) {
    const Class& scope_class = Class::Handle(Type::Cast(type).type_class());
    if (scope_class.IsTypedefClass()) {
      return CreateTypedefMirror(scope_class, type, Bool::False(),
                                 Object::null_instance());
    } else {
      return CreateFunctionTypeMirror(type);
    }
  }
  if (type.HasResolvedTypeClass()) {
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
    }
    return CreateClassMirror(cls, type, Bool::False(), Object::null_instance());
  } else if (type.IsTypeParameter()) {
    return CreateTypeVariableMirror(TypeParameter::Cast(type),
                                    Object::null_instance());
  } else if (type.IsBoundedType()) {
    AbstractType& actual_type =
        AbstractType::Handle(BoundedType::Cast(type).type());
    return CreateTypeMirror(actual_type);
  }
  UNREACHABLE();
  return Instance::null();
}

static RawInstance* CreateIsolateMirror() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  const String& debug_name = String::Handle(String::New(isolate->name()));
  const Library& root_library =
      Library::Handle(thread->zone(), isolate->object_store()->root_library());
  const Instance& root_library_mirror =
      Instance::Handle(CreateLibraryMirror(thread, root_library));

  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, debug_name);
  args.SetAt(1, root_library_mirror);
  return CreateMirror(Symbols::_LocalIsolateMirror(), args);
}

static void VerifyMethodKindShifts() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& lib = Library::Handle(zone, Library::MirrorsLibrary());
  const Class& cls = Class::Handle(
      zone, lib.LookupClassAllowPrivate(Symbols::_LocalMethodMirror()));
  const Error& error = Error::Handle(zone, cls.EnsureIsFinalized(thread));
  ASSERT(error.IsNull());

  Field& field = Field::Handle();
  Smi& value = Smi::Handle();

#define CHECK_KIND_SHIFT(name)                                                 \
  field = cls.LookupField(String::Handle(String::New(#name)));                 \
  ASSERT(!field.IsNull());                                                     \
  value ^= field.StaticValue();                                                \
  ASSERT(value.Value() == Mirrors::name);
  MIRRORS_KIND_SHIFT_LIST(CHECK_KIND_SHIFT)
#undef CHECK_KIND_SHIFT
#endif
}

static RawInstance* ReturnResult(const Object& result) {
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  if (result.IsInstance()) {
    return Instance::Cast(result).raw();
  }
  ASSERT(result.IsNull());
  return Instance::null();
}

// Invoke the function, or noSuchMethod if it is null. Propagate any unhandled
// exceptions. Wrap and propagate any compilation errors.
static RawInstance* InvokeDynamicFunction(const Instance& receiver,
                                          const Function& function,
                                          const String& target_name,
                                          const Array& args,
                                          const Array& args_descriptor_array) {
  // Note "args" is already the internal arguments with the receiver as the
  // first element.
  Object& result = Object::Handle();
  ArgumentsDescriptor args_descriptor(args_descriptor_array);
  if (function.IsNull() || !function.is_reflectable() ||
      !function.AreValidArguments(args_descriptor, NULL)) {
    result = DartEntry::InvokeNoSuchMethod(receiver, target_name, args,
                                           args_descriptor_array);
  } else {
    result = DartEntry::InvokeFunction(function, args, args_descriptor_array);
  }
  return ReturnResult(result);
}

static RawInstance* InvokeLibraryGetter(const Library& library,
                                        const String& getter_name,
                                        const bool throw_nsm_if_absent) {
  // To access a top-level we may need to use the Field or the getter Function.
  // The getter function may either be in the library or in the field's owner
  // class, depending on whether it was an actual getter, or an uninitialized
  // field.
  const Field& field = Field::Handle(library.LookupLocalField(getter_name));
  Function& getter = Function::Handle();
  if (field.IsNull()) {
    // No field found. Check for a getter in the lib.
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = library.LookupLocalFunction(internal_getter_name);
    if (getter.IsNull()) {
      getter = library.LookupLocalFunction(getter_name);
      if (!getter.IsNull()) {
        // Looking for a getter but found a regular method: closurize it.
        const Function& closure_function =
            Function::Handle(getter.ImplicitClosureFunction());
        return closure_function.ImplicitStaticClosure();
      }
    }
  } else {
    if (!field.IsUninitialized()) {
      return field.StaticValue();
    }
    // An uninitialized field was found.  Check for a getter in the field's
    // owner class.
    const Class& klass = Class::Handle(field.Owner());
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = klass.LookupStaticFunction(internal_getter_name);
  }

  if (!getter.IsNull() && getter.is_reflectable()) {
    // Invoke the getter and return the result.
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    return ReturnResult(result);
  }

  if (throw_nsm_if_absent) {
    ThrowNoSuchMethod(Instance::null_instance(), getter_name, getter,
                      Object::null_array(), Object::null_array(),
                      InvocationMirror::kTopLevel, InvocationMirror::kGetter);
    UNREACHABLE();
  }

  // Fall through case: Indicate that we didn't find any function or field using
  // a special null instance. This is different from a field being null. Callers
  // make sure that this null does not leak into Dartland.
  return Object::sentinel().raw();
}

static RawInstance* InvokeClassGetter(const Class& klass,
                                      const String& getter_name,
                                      const bool throw_nsm_if_absent) {
  // Note static fields do not have implicit getters.
  const Field& field = Field::Handle(klass.LookupStaticField(getter_name));
  if (field.IsNull() || field.IsUninitialized()) {
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    Function& getter =
        Function::Handle(klass.LookupStaticFunction(internal_getter_name));

    if (getter.IsNull() || !getter.is_reflectable()) {
      if (getter.IsNull()) {
        getter = klass.LookupStaticFunction(getter_name);
        if (!getter.IsNull()) {
          // Looking for a getter but found a regular method: closurize it.
          const Function& closure_function =
              Function::Handle(getter.ImplicitClosureFunction());
          return closure_function.ImplicitStaticClosure();
        }
      }
      if (throw_nsm_if_absent) {
        ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()), getter_name,
                          getter, Object::null_array(), Object::null_array(),
                          InvocationMirror::kStatic, InvocationMirror::kGetter);
        UNREACHABLE();
      }
      // Fall through case: Indicate that we didn't find any function or field
      // using a special null instance. This is different from a field being
      // null. Callers make sure that this null does not leak into Dartland.
      return Object::sentinel().raw();
    }

    // Invoke the getter and return the result.
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    return ReturnResult(result);
  }
  return field.StaticValue();
}

static RawAbstractType* InstantiateType(const AbstractType& type,
                                        const AbstractType& instantiator) {
  ASSERT(type.IsFinalized());
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsCanonical() || type.IsTypeParameter() || type.IsBoundedType());

  // TODO(regis): Support uninstantiated type referring to function type params.
  if (!type.IsInstantiated(kFunctions)) {
    UNIMPLEMENTED();
  }

  if (type.IsInstantiated() || instantiator.IsNull()) {
    // TODO(regis): Shouldn't type parameters be replaced by dynamic?
    return type.Canonicalize();
  }

  ASSERT(!instantiator.IsNull());
  ASSERT(instantiator.IsFinalized());
  PROPAGATE_IF_MALFORMED(instantiator);

  const TypeArguments& instantiator_type_args =
      TypeArguments::Handle(instantiator.arguments());
  Error& bound_error = Error::Handle();
  AbstractType& result = AbstractType::Handle(type.InstantiateFrom(
      instantiator_type_args, Object::null_type_arguments(), &bound_error, NULL,
      NULL, Heap::kOld));
  if (!bound_error.IsNull()) {
    Exceptions::PropagateError(bound_error);
    UNREACHABLE();
  }
  ASSERT(result.IsFinalized());
  return result.Canonicalize();
}

DEFINE_NATIVE_ENTRY(MirrorSystem_libraries, 0) {
  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());

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
  return library_mirrors.raw();
}

DEFINE_NATIVE_ENTRY(MirrorSystem_isolate, 0) {
  VerifyMethodKindShifts();

  return CreateIsolateMirror();
}

DEFINE_NATIVE_ENTRY(Mirrors_makeLocalClassMirror, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  ASSERT(type.HasResolvedTypeClass());
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(!cls.IsNull());
  if (cls.IsDynamicClass() || cls.IsVoidClass() || cls.IsTypedefClass()) {
    Exceptions::ThrowArgumentError(type);
    UNREACHABLE();
  }
  return CreateClassMirror(cls, AbstractType::Handle(cls.DeclarationType()),
                           Bool::True(),  // is_declaration
                           Object::null_instance());
}

DEFINE_NATIVE_ENTRY(Mirrors_makeLocalTypeMirror, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  return CreateTypeMirror(type);
}

DEFINE_NATIVE_ENTRY(Mirrors_instantiateGenericType, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(1));

  ASSERT(type.HasResolvedTypeClass());
  const Class& clz = Class::Handle(type.type_class());
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
  type_args_obj ^= TypeArguments::New(num_expected_type_arguments);
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

  Type& instantiated_type =
      Type::Handle(Type::New(clz, type_args_obj, TokenPosition::kNoSource));
  instantiated_type ^= ClassFinalizer::FinalizeType(clz, instantiated_type);
  if (instantiated_type.IsMalbounded()) {
    const LanguageError& type_error =
        LanguageError::Handle(instantiated_type.error());
    const Array& error_args = Array::Handle(Array::New(3));
    error_args.SetAt(0, args);
    error_args.SetAt(1, String::Handle(String::New("typeArguments")));
    error_args.SetAt(2, String::Handle(type_error.FormatMessage()));
    Exceptions::ThrowByType(Exceptions::kArgumentValue, error_args);
    UNREACHABLE();
  }

  return instantiated_type.raw();
}

DEFINE_NATIVE_ENTRY(Mirrors_mangleName, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& lib = Library::Handle(ref.GetLibraryReferent());
  return lib.IsPrivate(name) ? lib.PrivateName(name) : name.raw();
}

DEFINE_NATIVE_ENTRY(MirrorReference_equals, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, b, arguments->NativeArgAt(1));
  return Bool::Get(a.referent() == b.referent()).raw();
}

DEFINE_NATIVE_ENTRY(DeclarationMirror_metadata, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(0));
  Object& decl = Object::Handle();
  if (reflectee.IsMirrorReference()) {
    const MirrorReference& decl_ref = MirrorReference::Cast(reflectee);
    decl = decl_ref.referent();
  } else if (reflectee.IsTypeParameter()) {
    decl = reflectee.raw();
  } else {
    UNREACHABLE();
  }

  Class& klass = Class::Handle();
  Library& library = Library::Handle();

  if (decl.IsClass()) {
    klass ^= decl.raw();
    library = klass.library();
  } else if (decl.IsFunction() && !Function::Cast(decl).IsSignatureFunction()) {
    klass = Function::Cast(decl).origin();
    library = klass.library();
  } else if (decl.IsField()) {
    klass = Field::Cast(decl).Origin();
    library = klass.library();
  } else if (decl.IsLibrary()) {
    library ^= decl.raw();
  } else if (decl.IsTypeParameter()) {
    klass ^= TypeParameter::Cast(decl).parameterized_class();
    library = klass.library();
  } else {
    return Object::empty_array().raw();
  }

  const Object& metadata = Object::Handle(library.GetMetadata(decl));
  if (metadata.IsError()) {
    Exceptions::PropagateError(Error::Cast(metadata));
  }
  return metadata.raw();
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_call_method, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  // TODO(rmacnak): Return get:call() method on class _Closure instead?
  // This now returns the result of invoking that call getter.
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  ASSERT(!func.IsNull());
  return CreateMethodMirror(func, owner_mirror, AbstractType::Handle());
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_parameters, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return CreateParameterMirrorList(func, owner);
}

DEFINE_NATIVE_ENTRY(FunctionTypeMirror_return_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  ASSERT(!func.IsNull());
  AbstractType& type = AbstractType::Handle(func.result_type());
  // Signatures of function types are instantiated, but not canonical.
  return type.Canonicalize();
}

DEFINE_NATIVE_ENTRY(ClassMirror_libraryUri, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Library& library = Library::Handle(klass.library());
  ASSERT(!library.IsNull());
  return library.url();
}

DEFINE_NATIVE_ENTRY(ClassMirror_supertype, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  ASSERT(super_type.IsNull() || super_type.IsFinalized());
  return super_type.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_supertype_instantiated, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  return InstantiateType(super_type, type);
}

DEFINE_NATIVE_ENTRY(ClassMirror_interfaces, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
  const Error& error = Error::Handle(cls.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
  }

  return cls.interfaces();
}

DEFINE_NATIVE_ENTRY(ClassMirror_interfaces_instantiated, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
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

  return interfaces_inst.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_mixin, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
  const AbstractType& mixin_type = AbstractType::Handle(cls.mixin());
  ASSERT(mixin_type.IsNull() || mixin_type.IsFinalized());
  return mixin_type.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_mixin_instantiated, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, instantiator,
                               arguments->NativeArgAt(1));
  PROPAGATE_IF_MALFORMED(type);
  ASSERT(type.IsFinalized());
  const Class& cls = Class::Handle(type.type_class());
  const AbstractType& mixin_type = AbstractType::Handle(cls.mixin());
  if (mixin_type.IsNull()) {
    return mixin_type.raw();
  }

  return InstantiateType(mixin_type, instantiator);
}

DEFINE_NATIVE_ENTRY(ClassMirror_members, 3) {
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

  const Array& functions = Array::Handle(klass.functions());
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
        (func.kind() == RawFunction::kRegularFunction ||
         func.kind() == RawFunction::kGetterFunction ||
         func.kind() == RawFunction::kSetterFunction)) {
      member_mirror =
          CreateMethodMirror(func, owner_mirror, owner_instantiator);
      member_mirrors.Add(member_mirror);
    }
  }

  return member_mirrors.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_constructors, 3) {
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

  const Array& functions = Array::Handle(klass.functions());
  const intptr_t num_functions = functions.Length();

  Instance& constructor_mirror = Instance::Handle();
  const GrowableObjectArray& constructor_mirrors =
      GrowableObjectArray::Handle(GrowableObjectArray::New(num_functions));

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.is_reflectable() && func.kind() == RawFunction::kConstructor) {
      constructor_mirror =
          CreateMethodMirror(func, owner_mirror, owner_instantiator);
      constructor_mirrors.Add(constructor_mirror);
    }
  }

  return constructor_mirrors.raw();
}

DEFINE_NATIVE_ENTRY(LibraryMirror_members, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());

  Instance& member_mirror = Instance::Handle();
  const GrowableObjectArray& member_mirrors =
      GrowableObjectArray::Handle(GrowableObjectArray::New());

  Object& entry = Object::Handle();
  DictionaryIterator entries(library);

  AbstractType& type = AbstractType::Handle();

  while (entries.HasNext()) {
    entry = entries.GetNext();
    if (entry.IsClass()) {
      const Class& klass = Class::Cast(entry);
      // We filter out mixin application classes and dynamic.
      // TODO(12478): Should not need to filter out dynamic.
      // Note that the VM does not consider mixin application aliases to be
      // mixin applications.
      if (!klass.IsDynamicClass() && !klass.IsMixinApplication()) {
        type = klass.DeclarationType();
        member_mirror = CreateClassMirror(klass, type,
                                          Bool::True(),  // is_declaration
                                          owner_mirror);
        member_mirrors.Add(member_mirror);
      }
    } else if (entry.IsField()) {
      const Field& field = Field::Cast(entry);
      if (field.is_reflectable()) {
        member_mirror = CreateVariableMirror(field, owner_mirror);
        member_mirrors.Add(member_mirror);
      }
    } else if (entry.IsFunction()) {
      const Function& func = Function::Cast(entry);
      if (func.is_reflectable() &&
          (func.kind() == RawFunction::kRegularFunction ||
           func.kind() == RawFunction::kGetterFunction ||
           func.kind() == RawFunction::kSetterFunction)) {
        member_mirror =
            CreateMethodMirror(func, owner_mirror, AbstractType::Handle());
        member_mirrors.Add(member_mirror);
      }
    }
  }

  return member_mirrors.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_type_variables, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }
  return CreateTypeVariableList(klass);
}

DEFINE_NATIVE_ENTRY(ClassMirror_type_arguments, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));

  const Class& cls = Class::Handle(type.type_class());
  const intptr_t num_params = cls.NumTypeParameters();

  if (num_params == 0) {
    return Object::empty_array().raw();
  }

  const Array& result = Array::Handle(Array::New(num_params));
  AbstractType& arg_type = AbstractType::Handle();
  Instance& type_mirror = Instance::Handle();
  const TypeArguments& args = TypeArguments::Handle(type.arguments());

  // Handle argument lists that have been optimized away, because either no
  // arguments have been provided, or all arguments are dynamic. Return a list
  // of typemirrors on dynamic in this case.
  if (args.IsNull()) {
    arg_type ^= Object::dynamic_type().raw();
    type_mirror ^= CreateTypeMirror(arg_type);
    for (intptr_t i = 0; i < num_params; i++) {
      result.SetAt(i, type_mirror);
    }
    return result.raw();
  }

  ASSERT(args.Length() >= num_params);
  const intptr_t num_inherited_args = args.Length() - num_params;
  for (intptr_t i = 0; i < num_params; i++) {
    arg_type ^= args.TypeAt(i + num_inherited_args);
    type_mirror = CreateTypeMirror(arg_type);
    result.SetAt(i, type_mirror);
  }
  return result.raw();
}

DEFINE_NATIVE_ENTRY(TypeVariableMirror_owner, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypeParameter, param, arguments->NativeArgAt(0));
  const Class& owner = Class::Handle(param.parameterized_class());
  const AbstractType& type = AbstractType::Handle(owner.DeclarationType());
  return CreateClassMirror(owner, type,
                           Bool::True(),  // is_declaration
                           Instance::null_instance());
}

DEFINE_NATIVE_ENTRY(TypeVariableMirror_upper_bound, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypeParameter, param, arguments->NativeArgAt(0));
  return param.bound();
}

DEFINE_NATIVE_ENTRY(Mirrors_evalInLibraryWithPrivateKey, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, expression, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(String, private_key, arguments->NativeArgAt(1));

  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  const int num_libraries = libraries.Length();
  Library& each_library = Library::Handle();
  Library& ctxt_library = Library::Handle();
  String& library_key = String::Handle();

  if (private_key.IsNull()) {
    ctxt_library = Library::CoreLibrary();
  } else {
    for (int i = 0; i < num_libraries; i++) {
      each_library ^= libraries.At(i);
      library_key = each_library.private_key();
      if (library_key.Equals(private_key)) {
        ctxt_library = each_library.raw();
        break;
      }
    }
  }
  ASSERT(!ctxt_library.IsNull());
  const Object& result = Object::Handle(ctxt_library.Evaluate(
      expression, Array::empty_array(), Array::empty_array()));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }

  // Because we currently only use this native for building field extractors and
  // setters, assume the result is a closure and mark its function as invisible,
  // so it will not appear in stack traces. Whenever we support
  // ObjectMirror.evaluate this will need to be separated.
  ASSERT(result.IsClosure());
  const Function& func = Function::Handle(Closure::Cast(result).function());
  func.set_is_visible(false);
  func.set_is_debuggable(false);

  return result.raw();
}

DEFINE_NATIVE_ENTRY(TypedefMirror_declaration, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFunctionType());
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(cls.IsTypedefClass());
  return CreateTypedefMirror(cls, AbstractType::Handle(cls.DeclarationType()),
                             Bool::True(),  // is_declaration
                             Object::null_instance());
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invoke, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));

  Class& klass = Class::Handle(reflectee.clazz());
  Function& function = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, function_name));

  // TODO(regis): Support invocation of generic functions with type arguments.
  const int kTypeArgsLen = 0;
  const Array& args_descriptor = Array::Handle(
      zone, ArgumentsDescriptor::New(kTypeArgsLen, args.Length(), arg_names));

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const String& getter_name =
        String::Handle(zone, Field::GetterName(function_name));
    function = Resolver::ResolveDynamicAnyArgs(zone, klass, getter_name);
    if (!function.IsNull()) {
      ASSERT(function.kind() != RawFunction::kMethodExtractor);
      // Invoke the getter.
      const int kNumArgs = 1;
      const Array& getter_args = Array::Handle(zone, Array::New(kNumArgs));
      getter_args.SetAt(0, reflectee);
      const Array& getter_args_descriptor = Array::Handle(
          zone, ArgumentsDescriptor::New(kTypeArgsLen, getter_args.Length()));
      const Instance& getter_result = Instance::Handle(
          zone, InvokeDynamicFunction(reflectee, function, getter_name,
                                      getter_args, getter_args_descriptor));
      // Replace the closure as the receiver in the arguments list.
      args.SetAt(0, getter_result);
      // Call the closure.
      const Object& call_result =
          Object::Handle(zone, DartEntry::InvokeClosure(args, args_descriptor));
      if (call_result.IsError()) {
        Exceptions::PropagateError(Error::Cast(call_result));
        UNREACHABLE();
      }
      return call_result.raw();
    }
  }

  // Found an ordinary method.
  return InvokeDynamicFunction(reflectee, function, function_name, args,
                               args_descriptor);
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));
  Class& klass = Class::Handle(reflectee.clazz());

  const String& internal_getter_name =
      String::Handle(Field::GetterName(getter_name));
  Function& function = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, internal_getter_name));

  // Check for method extraction when method extractors are not created.
  if (function.IsNull() && !FLAG_lazy_dispatchers) {
    function = Resolver::ResolveDynamicAnyArgs(zone, klass, getter_name);
    if (!function.IsNull()) {
      const Function& closure_function =
          Function::Handle(zone, function.ImplicitClosureFunction());
      return closure_function.ImplicitInstanceClosure(reflectee);
    }
  }

  const int kTypeArgsLen = 0;
  const int kNumArgs = 1;
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, reflectee);
  const Array& args_descriptor = Array::Handle(
      zone, ArgumentsDescriptor::New(kTypeArgsLen, args.Length()));

  // InvokeDynamic invokes NoSuchMethod if the provided function is null.
  return InvokeDynamicFunction(reflectee, function, internal_getter_name, args,
                               args_descriptor);
}

DEFINE_NATIVE_ENTRY(InstanceMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  const Class& klass = Class::Handle(zone, reflectee.clazz());
  const String& internal_setter_name =
      String::Handle(zone, Field::SetterName(setter_name));
  const Function& setter = Function::Handle(
      zone, Resolver::ResolveDynamicAnyArgs(zone, klass, internal_setter_name));

  const int kTypeArgsLen = 0;
  const int kNumArgs = 2;
  const Array& args = Array::Handle(zone, Array::New(kNumArgs));
  args.SetAt(0, reflectee);
  args.SetAt(1, value);
  const Array& args_descriptor = Array::Handle(
      zone, ArgumentsDescriptor::New(kTypeArgsLen, args.Length()));

  return InvokeDynamicFunction(reflectee, setter, internal_setter_name, args,
                               args_descriptor);
}

DEFINE_NATIVE_ENTRY(InstanceMirror_computeType, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0));
  const AbstractType& type = AbstractType::Handle(instance.GetType(Heap::kNew));
  // The static type of null is specified to be the bottom type, however, the
  // runtime type of null is the Null type, which we correctly return here.
  return type.Canonicalize();
}

DEFINE_NATIVE_ENTRY(ClosureMirror_function, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  ASSERT(!closure.IsNull());

  Function& function = Function::Handle();
  bool callable = closure.IsCallable(&function);
  if (callable) {
    if (function.IsImplicitClosureFunction()) {
      // The VM uses separate Functions for tear-offs, but the mirrors consider
      // the tear-offs to be the same as the torn-off methods. Avoid handing out
      // a reference to the tear-off here to avoid a special case in the
      // the equality test.
      function = function.parent_function();
    }

    Type& instantiator = Type::Handle();
    if (closure.IsClosure()) {
      const TypeArguments& arguments = TypeArguments::Handle(
          Closure::Cast(closure).instantiator_type_arguments());
      // TODO(regis): Mirrors need work to properly support generic functions.
      // The 'instantiator' created below should not be a type, but two type
      // argument vectors: instantiator_type_arguments and
      // function_type_arguments.
      const Class& cls =
          Class::Handle(Isolate::Current()->object_store()->object_class());
      instantiator = Type::New(cls, arguments, TokenPosition::kNoSource);
      instantiator.SetIsFinalized();
    }
    return CreateMethodMirror(function, Instance::null_instance(),
                              instantiator);
  }
  return Instance::null();
}

DEFINE_NATIVE_ENTRY(ClassMirror_invoke, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));

  // TODO(regis): Support invocation of generic functions with type arguments.
  const int kTypeArgsLen = 0;
  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  Function& function =
      Function::Handle(klass.LookupStaticFunction(function_name));

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const String& getter_name =
        String::Handle(Field::GetterName(function_name));
    function = klass.LookupStaticFunction(getter_name);
    if (!function.IsNull()) {
      // Invoke the getter.
      const Object& getter_result = Object::Handle(
          DartEntry::InvokeFunction(function, Object::empty_array()));
      if (getter_result.IsError()) {
        Exceptions::PropagateError(Error::Cast(getter_result));
        UNREACHABLE();
      }
      // Make room for the closure (receiver) in the argument list.
      const intptr_t num_args = args.Length();
      const Array& call_args = Array::Handle(Array::New(num_args + 1));
      Object& temp = Object::Handle();
      for (int i = 0; i < num_args; i++) {
        temp = args.At(i);
        call_args.SetAt(i + 1, temp);
      }
      call_args.SetAt(0, getter_result);
      const Array& call_args_descriptor_array =
          Array::Handle(ArgumentsDescriptor::New(
              kTypeArgsLen, call_args.Length(), arg_names));
      // Call the closure.
      const Object& call_result = Object::Handle(
          DartEntry::InvokeClosure(call_args, call_args_descriptor_array));
      if (call_result.IsError()) {
        Exceptions::PropagateError(Error::Cast(call_result));
        UNREACHABLE();
      }
      return call_result.raw();
    }
  }

  const Array& args_descriptor_array = Array::Handle(
      ArgumentsDescriptor::New(kTypeArgsLen, args.Length(), arg_names));

  ArgumentsDescriptor args_descriptor(args_descriptor_array);

  if (function.IsNull() || !function.AreValidArguments(args_descriptor, NULL) ||
      !function.is_reflectable()) {
    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()), function_name,
                      function, args, arg_names, InvocationMirror::kStatic,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, args, args_descriptor_array));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeGetter, 3) {
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
  return InvokeClassGetter(klass, getter_name, true);
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  // Check for real fields and user-defined setters.
  const Field& field = Field::Handle(klass.LookupStaticField(setter_name));
  Function& setter = Function::Handle();
  const String& internal_setter_name =
      String::Handle(Field::SetterName(setter_name));

  if (field.IsNull()) {
    setter = klass.LookupStaticFunction(internal_setter_name);

    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    if (setter.IsNull() || !setter.is_reflectable()) {
      ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                        internal_setter_name, setter, args,
                        Object::null_array(), InvocationMirror::kStatic,
                        InvocationMirror::kSetter);
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    Object& result = Object::Handle(DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final() || !field.is_reflectable()) {
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                      internal_setter_name, setter, args, Object::null_array(),
                      InvocationMirror::kStatic, InvocationMirror::kSetter);
    UNREACHABLE();
  }

  field.SetStaticValue(value);
  return value.raw();
}

DEFINE_NATIVE_ENTRY(ClassMirror_invokeConstructor, 5) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, constructor_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, explicit_args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));

  const Error& error = Error::Handle(zone, klass.EnsureIsFinalized(thread));
  if (!error.IsNull()) {
    Exceptions::PropagateError(error);
    UNREACHABLE();
  }

  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  const String& klass_name = String::Handle(klass.Name());
  String& external_constructor_name = String::Handle(klass_name.raw());
  String& internal_constructor_name =
      String::Handle(String::Concat(klass_name, Symbols::Dot()));
  if (!constructor_name.IsNull() && constructor_name.Length() > 0) {
    internal_constructor_name =
        String::Concat(internal_constructor_name, constructor_name);
    external_constructor_name = internal_constructor_name.raw();
  }

  Function& lookup_constructor =
      Function::Handle(klass.LookupFunction(internal_constructor_name));

  if (lookup_constructor.IsNull() ||
      (lookup_constructor.kind() != RawFunction::kConstructor) ||
      !lookup_constructor.is_reflectable()) {
    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                      external_constructor_name, lookup_constructor,
                      explicit_args, arg_names, InvocationMirror::kConstructor,
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
  TypeArguments& type_arguments = TypeArguments::Handle(type.arguments());
  if (!type.IsInstantiated()) {
    // Must have been a declaration type.
    AbstractType& rare_type = AbstractType::Handle(klass.RareType());
    ASSERT(rare_type.IsInstantiated());
    type_arguments = rare_type.arguments();
  }

  Class& redirected_klass = Class::Handle(klass.raw());
  Function& redirected_constructor = Function::Handle(lookup_constructor.raw());
  if (lookup_constructor.IsRedirectingFactory()) {
    ClassFinalizer::ResolveRedirectingFactory(klass, lookup_constructor);
    Type& redirect_type = Type::Handle(lookup_constructor.RedirectionType());

    if (!redirect_type.IsInstantiated()) {
      // The type arguments of the redirection type are instantiated from the
      // type arguments of the type reflected by the class mirror.
      ASSERT(redirect_type.IsInstantiated(kFunctions));
      Error& bound_error = Error::Handle();
      redirect_type ^= redirect_type.InstantiateFrom(
          type_arguments, Object::null_type_arguments(), &bound_error, NULL,
          NULL, Heap::kOld);
      if (!bound_error.IsNull()) {
        Exceptions::PropagateError(bound_error);
        UNREACHABLE();
      }
      redirect_type ^= redirect_type.Canonicalize();
    }

    type = redirect_type.raw();
    type_arguments = redirect_type.arguments();

    redirected_constructor = lookup_constructor.RedirectionTarget();
    ASSERT(!redirected_constructor.IsNull());
    redirected_klass = type.type_class();
  }

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
      ArgumentsDescriptor::New(kTypeArgsLen, args.Length(), arg_names));

  ArgumentsDescriptor args_descriptor(args_descriptor_array);
  if (!redirected_constructor.AreValidArguments(args_descriptor, NULL)) {
    external_constructor_name = redirected_constructor.name();
    ThrowNoSuchMethod(AbstractType::Handle(klass.RareType()),
                      external_constructor_name, redirected_constructor,
                      explicit_args, arg_names, InvocationMirror::kConstructor,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  Instance& new_object = Instance::Handle();
  if (redirected_constructor.IsGenerativeConstructor()) {
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
      redirected_constructor, args, args_descriptor_array));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }

  // Factories may return null.
  ASSERT(result.IsInstance() || result.IsNull());

  if (redirected_constructor.IsGenerativeConstructor()) {
    return new_object.raw();
  } else {
    return result.raw();
  }
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invoke, 5) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, function_name,
                               arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, args, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, arg_names, arguments->NativeArgAt(4));

  // TODO(regis): Support invocation of generic functions with type arguments.
  const int kTypeArgsLen = 0;
  Function& function =
      Function::Handle(library.LookupLocalFunction(function_name));

  if (function.IsNull()) {
    // Didn't find a method: try to find a getter and invoke call on its result.
    const Instance& getter_result =
        Instance::Handle(InvokeLibraryGetter(library, function_name, false));
    if (getter_result.raw() != Object::sentinel().raw()) {
      // Make room for the closure (receiver) in arguments.
      intptr_t numArgs = args.Length();
      const Array& call_args = Array::Handle(Array::New(numArgs + 1));
      Object& temp = Object::Handle();
      for (int i = 0; i < numArgs; i++) {
        temp = args.At(i);
        call_args.SetAt(i + 1, temp);
      }
      call_args.SetAt(0, getter_result);
      const Array& call_args_descriptor_array =
          Array::Handle(ArgumentsDescriptor::New(
              kTypeArgsLen, call_args.Length(), arg_names));
      // Call closure.
      const Object& call_result = Object::Handle(
          DartEntry::InvokeClosure(call_args, call_args_descriptor_array));
      if (call_result.IsError()) {
        Exceptions::PropagateError(Error::Cast(call_result));
        UNREACHABLE();
      }
      return call_result.raw();
    }
  }

  const Array& args_descriptor_array = Array::Handle(
      ArgumentsDescriptor::New(kTypeArgsLen, args.Length(), arg_names));
  ArgumentsDescriptor args_descriptor(args_descriptor_array);

  if (function.IsNull() || !function.AreValidArguments(args_descriptor, NULL) ||
      !function.is_reflectable()) {
    ThrowNoSuchMethod(Instance::null_instance(), function_name, function, args,
                      arg_names, InvocationMirror::kTopLevel,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, args, args_descriptor_array));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));
  return InvokeLibraryGetter(library, getter_name, true);
}

DEFINE_NATIVE_ENTRY(LibraryMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  // To access a top-level we may need to use the Field or the
  // setter Function.  The setter function may either be in the
  // library or in the field's owner class, depending.
  const Field& field = Field::Handle(library.LookupLocalField(setter_name));
  Function& setter = Function::Handle();
  const String& internal_setter_name =
      String::Handle(Field::SetterName(setter_name));

  if (field.IsNull()) {
    setter = library.LookupLocalFunction(internal_setter_name);

    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    if (setter.IsNull() || !setter.is_reflectable()) {
      ThrowNoSuchMethod(Instance::null_instance(), internal_setter_name, setter,
                        args, Object::null_array(), InvocationMirror::kTopLevel,
                        InvocationMirror::kSetter);
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    const Object& result =
        Object::Handle(DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final() || !field.is_reflectable()) {
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    ThrowNoSuchMethod(Instance::null_instance(), internal_setter_name, setter,
                      args, Object::null_array(), InvocationMirror::kTopLevel,
                      InvocationMirror::kSetter);
    UNREACHABLE();
  }

  field.SetStaticValue(value);
  return value.raw();
}

DEFINE_NATIVE_ENTRY(MethodMirror_owner, 2) {
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

DEFINE_NATIVE_ENTRY(MethodMirror_parameters, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return CreateParameterMirrorList(func, owner);
}

DEFINE_NATIVE_ENTRY(MethodMirror_return_type, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(1));
  // We handle constructors in Dart code.
  ASSERT(!func.IsGenerativeConstructor());
  AbstractType& type = AbstractType::Handle(func.result_type());
  type ^= type.Canonicalize();  // Instantiated signatures are not canonical.
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(MethodMirror_source, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return func.GetSource();
}

static RawInstance* CreateSourceLocation(const String& uri,
                                         intptr_t line,
                                         intptr_t column) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, uri);
  args.SetAt(1, Smi::Handle(Smi::New(line)));
  args.SetAt(2, Smi::Handle(Smi::New(column)));
  return CreateMirror(Symbols::_SourceLocation(), args);
}

DEFINE_NATIVE_ENTRY(DeclarationMirror_location, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(0));
  Object& decl = Object::Handle(zone);
  if (reflectee.IsMirrorReference()) {
    const MirrorReference& decl_ref = MirrorReference::Cast(reflectee);
    decl = decl_ref.referent();
  } else if (reflectee.IsTypeParameter()) {
    decl = reflectee.raw();
  } else {
    UNREACHABLE();
  }

  Script& script = Script::Handle(zone);
  TokenPosition token_pos = TokenPosition::kNoSource;

  if (decl.IsFunction()) {
    const Function& func = Function::Cast(decl);
    if (func.IsImplicitConstructor() || func.IsSignatureFunction()) {
      // These are synthetic methods; they have no source.
      return Instance::null();
    }
    script = func.script();
    token_pos = func.token_pos();
  } else if (decl.IsClass()) {
    const Class& cls = Class::Cast(decl);
    const bool is_typedef = cls.IsTypedefClass();
    if (cls.is_synthesized_class() && !is_typedef &&
        !cls.is_mixin_app_alias() && !cls.is_enum_class()) {
      return Instance::null();  // Synthetic.
    }
    script = cls.script();
    token_pos = cls.token_pos();
  } else if (decl.IsField()) {
    const Field& field = Field::Cast(decl);
    script = field.Script();
    token_pos = field.token_pos();
  } else if (decl.IsTypeParameter()) {
    const TypeParameter& type_var = TypeParameter::Cast(decl);
    const Class& owner = Class::Handle(zone, type_var.parameterized_class());
    script = owner.script();
    token_pos = type_var.token_pos();
  } else if (decl.IsLibrary()) {
    const Library& lib = Library::Cast(decl);
    if (lib.raw() == Library::NativeWrappersLibrary()) {
      return Instance::null();  // No source.
    }
    const Array& scripts = Array::Handle(zone, lib.LoadedScripts());
    for (intptr_t i = 0; i < scripts.Length(); i++) {
      script ^= scripts.At(i);
      if (script.kind() == RawScript::kLibraryTag) break;
    }
    ASSERT(!script.IsNull());
    const String& libname = String::Handle(zone, lib.name());
    if (libname.Length() == 0) {
      // No library declaration.
      const String& uri = String::Handle(zone, script.url());
      return CreateSourceLocation(uri, 1, 1);
    }
    const TokenStream& stream = TokenStream::Handle(zone, script.tokens());
    TokenStream::Iterator tkit(zone, stream, TokenPosition::kMinSource);
    if (tkit.CurrentTokenKind() == Token::kSCRIPTTAG) tkit.Advance();
    token_pos = tkit.CurrentPosition();
  }

  ASSERT(!script.IsNull());
  ASSERT(token_pos != TokenPosition::kNoSource);

  const String& uri = String::Handle(zone, script.url());
  intptr_t from_line = 0;
  intptr_t from_col = 0;
  if (script.HasSource()) {
    script.GetTokenLocation(token_pos, &from_line, &from_col);
  } else {
    // Avoid the slow path of printing the token stream when precise source
    // information is not available.
    script.GetTokenLocation(token_pos, &from_line, NULL);
  }
  // We should always have at least the line number.
  ASSERT(from_line != 0);
  return CreateSourceLocation(uri, from_line, from_col);
}

DEFINE_NATIVE_ENTRY(TypedefMirror_referent, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(0));
  ASSERT(type.IsFunctionType());
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(cls.IsTypedefClass());
  const Function& sig_func = Function::Handle(cls.signature_function());
  Type& referent_type = Type::Handle(sig_func.SignatureType());
  ASSERT(cls.raw() == referent_type.type_class());
  referent_type ^= InstantiateType(referent_type, type);
  return CreateFunctionTypeMirror(referent_type);
}

DEFINE_NATIVE_ENTRY(ParameterMirror_type, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, pos, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(2));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  AbstractType& type = AbstractType::Handle(
      func.ParameterTypeAt(func.NumImplicitParameters() + pos.Value()));
  type ^= type.Canonicalize();  // Instantiated signatures are not canonical.
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(VariableMirror_type, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Field& field = Field::Handle(ref.GetFieldReferent());
  GET_NATIVE_ARGUMENT(AbstractType, instantiator, arguments->NativeArgAt(1));
  const AbstractType& type = AbstractType::Handle(field.type());
  return InstantiateType(type, instantiator);
}

DEFINE_NATIVE_ENTRY(TypeMirror_subtypeTest, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, b, arguments->NativeArgAt(1));
  return Bool::Get(a.IsSubtypeOf(b, NULL, NULL, Heap::kNew)).raw();
}

#endif  // !DART_PRECOMPILED_RUNTIME

}  // namespace dart
