// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/invocation_mirror.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/symbols.h"

namespace dart {

static RawInstance* CreateMirror(const String& mirror_class_name,
                                 const Array& constructor_arguments) {
  const Library& mirrors_lib = Library::Handle(Library::MirrorsLibrary());
  const String& constructor_name = Symbols::Dot();

  const Object& result = Object::Handle(
      DartLibraryCalls::InstanceCreate(mirrors_lib,
                                       mirror_class_name,
                                       constructor_name,
                                       constructor_arguments));
  ASSERT(!result.IsError());
  return Instance::Cast(result).raw();
}


// Note a "raw type" is not the same as a RawType.
static RawAbstractType* RawTypeOfClass(const Class& cls) {
  Type& type = Type::Handle(Type::New(cls,
                                      Object::null_abstract_type_arguments(),
                                      Scanner::kDummyTokenIndex));
  return ClassFinalizer::FinalizeType(cls, type, ClassFinalizer::kCanonicalize);
}


static void ThrowMirroredCompilationError(const String& message) {
  Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, message);

  Exceptions::ThrowByType(Exceptions::kMirroredCompilationError, args);
  UNREACHABLE();
}


static void ThrowInvokeError(const Error& error) {
  if (error.IsLanguageError()) {
    // A compilation error that was delayed by lazy compilation.
    const LanguageError& compilation_error = LanguageError::Cast(error);
    String& message = String::Handle(compilation_error.message());
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }
  Exceptions::PropagateError(error);
  UNREACHABLE();
}


// Conventions:
// * For throwing a NSM in a class klass we use its runtime type as receiver,
//   i.e., RawTypeOfClass(klass).
// * For throwing a NSM in a library, we just pass the null instance as
//   receiver.
static void ThrowNoSuchMethod(const Instance& receiver,
                              const String& function_name,
                              const Function& function,
                              const InvocationMirror::Call call,
                              const InvocationMirror::Type type) {
  const Smi& invocation_type = Smi::Handle(Smi::New(
      InvocationMirror::EncodeType(call, type)));

  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, receiver);
  args.SetAt(1, function_name);
  args.SetAt(2, invocation_type);
  // Parameter 3 (actual arguments): We omit this parameter to get the same
  // error message as one would get by invoking the function non-reflectively.
  // Parameter 4 (named arguments): We omit this parameters since we cannot
  // invoke functions with named parameters reflectively (using mirrors).
  if (!function.IsNull()) {
    const int total_num_parameters = function.NumParameters();
    const Array& array = Array::Handle(Array::New(total_num_parameters));
    String& param_name = String::Handle();
    for (int i = 0; i < total_num_parameters; i++) {
      param_name = function.ParameterNameAt(i);
      array.SetAt(i, param_name);
    }
    args.SetAt(5, array);
  }

  Exceptions::ThrowByType(Exceptions::kNoSuchMethod, args);
  UNREACHABLE();
}


DEFINE_NATIVE_ENTRY(Mirrors_isLocalPort, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, port, arguments->NativeArgAt(0));

  // Get the port id from the SendPort instance.
  const Object& id_obj = Object::Handle(DartLibraryCalls::PortGetId(port));
  if (id_obj.IsError()) {
    Exceptions::PropagateError(Error::Cast(id_obj));
    UNREACHABLE();
  }
  ASSERT(id_obj.IsSmi() || id_obj.IsMint());
  Integer& id = Integer::Handle();
  id ^= id_obj.raw();
  Dart_Port port_id = static_cast<Dart_Port>(id.AsInt64Value());
  return Bool::Get(PortMap::IsLocalPort(port_id)).raw();
}


static RawInstance* CreateParameterMirrorList(const Function& func,
                                              const Instance& owner_mirror) {
  HANDLESCOPE(Isolate::Current());
  const intptr_t implicit_param_count = func.NumImplicitParameters();
  const intptr_t non_implicit_param_count = func.NumParameters() -
                                            implicit_param_count;
  const intptr_t index_of_first_optional_param =
      non_implicit_param_count - func.NumOptionalParameters();
  const intptr_t index_of_first_named_param =
      non_implicit_param_count - func.NumOptionalNamedParameters();
  const Array& results = Array::Handle(Array::New(non_implicit_param_count));
  const Array& args = Array::Handle(Array::New(8));

  // Return for synthetic functions and getters.
  if (func.IsGetterFunction() ||
      func.IsImplicitConstructor() ||
      func.IsImplicitGetterFunction() ||
      func.IsImplicitSetterFunction()) {
    return results.raw();
  }

  Smi& pos = Smi::Handle();
  String& name = String::Handle();
  Instance& param = Instance::Handle();
  Bool& is_final = Bool::Handle();
  Object& default_value = Object::Handle();

  // Reparse the function for the following information:
  // * The default value of a parameter.
  // * Whether a parameters has been deflared as final.
  const Object& result = Object::Handle(Parser::ParseFunctionParameters(func));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }

  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));
  args.SetAt(2, owner_mirror);

  const Array& param_descriptor = Array::Cast(result);
  ASSERT(param_descriptor.Length() == (2 * non_implicit_param_count));
  for (intptr_t i = 0; i < non_implicit_param_count; i++) {
    pos ^= Smi::New(i);
    name ^= func.ParameterNameAt(implicit_param_count + i);
    is_final ^= param_descriptor.At(i * 2);
    default_value = param_descriptor.At(i * 2 + 1);
    ASSERT(default_value.IsNull() || default_value.IsInstance());

    // Arguments 0 (referent) and 2 (owner) are the same for all parameters. See
    // above.
    args.SetAt(1, name);
    args.SetAt(3, pos);
    args.SetAt(4, Bool::Get(i >= index_of_first_optional_param));
    args.SetAt(5, Bool::Get(i >= index_of_first_named_param));
    args.SetAt(6, is_final);
    args.SetAt(7, default_value);
    param ^= CreateMirror(Symbols::_LocalParameterMirrorImpl(), args);
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
  return CreateMirror(Symbols::_LocalTypeVariableMirrorImpl(), args);
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
    name ^= type.name();
    result.SetAt(2 * i, name);
    result.SetAt(2 * i + 1, type);
  }
  return result.raw();
}


static RawInstance* CreateTypedefMirror(const Class& cls,
                                        const Instance& owner_mirror) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, String::Handle(cls.UserVisibleName()));
  args.SetAt(2, owner_mirror);
  return CreateMirror(Symbols::_LocalTypedefMirrorImpl(), args);
}


static RawInstance* CreateFunctionTypeMirror(const Class& cls,
                                             const AbstractType& type) {
  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, type);
  return CreateMirror(Symbols::_LocalFunctionTypeMirrorImpl(), args);
}


static RawInstance* CreateMethodMirror(const Function& func,
                                       const Instance& owner_mirror) {
  const Array& args = Array::Handle(Array::New(12));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(func)));
  args.SetAt(1, String::Handle(func.UserVisibleName()));
  args.SetAt(2, owner_mirror);
  args.SetAt(3, Bool::Get(func.is_static()));
  args.SetAt(4, Bool::Get(func.is_abstract()));
  args.SetAt(5, Bool::Get(func.IsGetterFunction()));
  args.SetAt(6, Bool::Get(func.IsSetterFunction()));
  args.SetAt(7, Bool::Get(func.kind() == RawFunction::kConstructor));
  // TODO(mlippautz): Implement different constructor kinds.
  args.SetAt(8, Bool::False());
  args.SetAt(9, Bool::False());
  args.SetAt(10, Bool::False());
  args.SetAt(11, Bool::False());
  return CreateMirror(Symbols::_LocalMethodMirrorImpl(), args);
}


static RawInstance* CreateVariableMirror(const Field& field,
                                         const Instance& owner_mirror) {
  const MirrorReference& field_ref =
      MirrorReference::Handle(MirrorReference::New(field));

  const String& name = String::Handle(field.UserVisibleName());

  const Array& args = Array::Handle(Array::New(6));
  args.SetAt(0, field_ref);
  args.SetAt(1, name);
  args.SetAt(2, owner_mirror);
  args.SetAt(3, Instance::Handle());  // Null for type.
  args.SetAt(4, Bool::Get(field.is_static()));
  args.SetAt(5, Bool::Get(field.is_final()));

  return CreateMirror(Symbols::_LocalVariableMirrorImpl(), args);
}

static RawFunction* CallMethod(const Class& cls) {
  if (cls.IsSignatureClass()) {
    return cls.signature_function();
  }

  Class& lookup_cls = Class::Handle(cls.raw());
  Function& call_function = Function::Handle();
  do {
    call_function = lookup_cls.LookupDynamicFunction(Symbols::Call());
    if (!call_function.IsNull()) {
      return call_function.raw();
    }
    lookup_cls = lookup_cls.SuperClass();
  } while (!lookup_cls.IsNull());
  return Function::null();
}

static RawInstance* CreateClassMirror(const Class& cls,
                                      const AbstractType& type,
                                      const Instance& owner_mirror) {
  ASSERT(!cls.IsDynamicClass() && !cls.IsVoidClass());

  if (cls.IsSignatureClass()) {
    if (cls.IsCanonicalSignatureClass()) {
      // We represent function types as canonical signature classes.
      return CreateFunctionTypeMirror(cls, type);
    } else {
      // We represent typedefs as non-canonical signature classes.
      return CreateTypedefMirror(cls, owner_mirror);
    }
  }

  const Bool& is_generic = Bool::Get(cls.NumTypeParameters() != 0);
  const Bool& is_mixin_typedef = Bool::Get(cls.is_mixin_typedef());

  // If the class is not generic, the mirror must have a non-null runtime type.
  // If the class is generic, the mirror will have a null runtime type if it
  // represents the declaration or a non-null runtime type if it represents an
  // instantiation.
  ASSERT(!(cls.NumTypeParameters() == 0) || !type.IsNull());

  const Array& args = Array::Handle(Array::New(5));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(cls)));
  args.SetAt(1, type);
  // We do not set the names of anonymous mixin applications because the mirrors
  // use a different naming convention than the VM (lib.S with lib.M and S&M
  // respectively).
  if ((cls.mixin() == Type::null()) || cls.is_mixin_typedef()) {
    args.SetAt(2, String::Handle(cls.UserVisibleName()));
  }
  args.SetAt(3, is_generic);
  args.SetAt(4, is_mixin_typedef);
  return CreateMirror(Symbols::_LocalClassMirrorImpl(), args);
}


static RawInstance* CreateLibraryMirror(const Library& lib) {
  const Array& args = Array::Handle(Array::New(3));
  args.SetAt(0, MirrorReference::Handle(MirrorReference::New(lib)));
  String& str = String::Handle();
  str = lib.name();
  args.SetAt(1, str);
  str = lib.url();
  args.SetAt(2, str);
  return CreateMirror(Symbols::_LocalLibraryMirrorImpl(), args);
}


static RawInstance* CreateTypeMirror(const AbstractType& type) {
  ASSERT(!type.IsMalformed());
  if (type.HasResolvedTypeClass()) {
    const Class& cls = Class::Handle(type.type_class());
    // Handle void and dynamic types.
    if (cls.IsVoidClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Void());
      // TODO(mlippautz): Create once in the VM isolate and retrieve from there.
      return CreateMirror(Symbols::_SpecialTypeMirrorImpl(), args);
    } else if (cls.IsDynamicClass()) {
      Array& args = Array::Handle(Array::New(1));
      args.SetAt(0, Symbols::Dynamic());
      // TODO(mlippautz): Create once in the VM isolate and retrieve from there.
      return CreateMirror(Symbols::_SpecialTypeMirrorImpl(), args);
    }
    return CreateClassMirror(cls, type, Object::null_instance());
  } else if (type.IsTypeParameter()) {
    return CreateTypeVariableMirror(TypeParameter::Cast(type),
                                    Object::null_instance());
  }
  UNREACHABLE();
  return Instance::null();
}


static RawInstance* CreateIsolateMirror() {
  Isolate* isolate = Isolate::Current();
  const String& debug_name = String::Handle(String::New(isolate->name()));
  const Library& root_library =
      Library::Handle(isolate, isolate->object_store()->root_library());
  const Instance& root_library_mirror =
      Instance::Handle(CreateLibraryMirror(root_library));

  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, debug_name);
  args.SetAt(1, root_library_mirror);
  return CreateMirror(Symbols::_LocalIsolateMirrorImpl(), args);
}


static RawInstance* CreateMirrorSystem() {
  Isolate* isolate = Isolate::Current();
  const GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());

  const int num_libraries = libraries.Length();
  const Array& library_mirrors = Array::Handle(Array::New(num_libraries));
  Library& library = Library::Handle();
  Instance& library_mirror = Instance::Handle();

  for (int i = 0; i < num_libraries; i++) {
    library ^= libraries.At(i);
    library_mirror = CreateLibraryMirror(library);
    library_mirrors.SetAt(i, library_mirror);
  }

  const Instance& isolate_mirror = Instance::Handle(CreateIsolateMirror());

  const Array& args = Array::Handle(Array::New(2));
  args.SetAt(0, library_mirrors);
  args.SetAt(1, isolate_mirror);
  return CreateMirror(Symbols::_LocalMirrorSystemImpl(), args);
}


DEFINE_NATIVE_ENTRY(Mirrors_makeLocalMirrorSystem, 0) {
  return CreateMirrorSystem();
}


DEFINE_NATIVE_ENTRY(Mirrors_makeLocalClassMirror, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Type, type, arguments->NativeArgAt(0));
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(!cls.IsNull());
  if (cls.IsDynamicClass() || cls.IsVoidClass()) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, type);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
    UNREACHABLE();
  }
  // Strip the type for generics only.
  if (cls.NumTypeParameters() == 0) {
    return CreateClassMirror(cls,
                             type,
                             Object::null_instance());
  } else {
    return CreateClassMirror(cls,
                             AbstractType::Handle(),
                             Object::null_instance());
  }
}


DEFINE_NATIVE_ENTRY(Mirrors_makeLocalTypeMirror, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(AbstractType, type, arguments->NativeArgAt(0));
  return CreateTypeMirror(type);
}


DEFINE_NATIVE_ENTRY(MirrorReference_equals, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, a, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, b, arguments->NativeArgAt(1));
  return Bool::Get(a.referent() == b.referent()).raw();
}


DEFINE_NATIVE_ENTRY(DeclarationMirror_metadata, 1) {
  const MirrorReference& decl_ref =
      MirrorReference::CheckedHandle(arguments->NativeArgAt(0));
  const Object& decl = Object::Handle(decl_ref.referent());

  Class& klass = Class::Handle();
  Library& library = Library::Handle();

  if (decl.IsClass()) {
    klass ^= decl.raw();
    library = klass.library();
  } else if (decl.IsFunction()) {
    klass = Function::Cast(decl).origin();
    library = klass.library();
  } else if (decl.IsField()) {
    klass = Field::Cast(decl).origin();
    library = klass.library();
  } else if (decl.IsLibrary()) {
    library ^= decl.raw();
  } else {
    return Object::empty_array().raw();
  }

  const Object& metadata = Object::Handle(library.GetMetadata(decl));
  if (metadata.IsError()) {
    ThrowInvokeError(Error::Cast(metadata));
  }
  return metadata.raw();
}


DEFINE_NATIVE_ENTRY(FunctionTypeMirror_call_method, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance,
                               owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& cls = Class::Handle(ref.GetClassReferent());
  const Function& func = Function::Handle(CallMethod(cls));
  ASSERT(!func.IsNull());
  return CreateMethodMirror(func, owner_mirror);
}


DEFINE_NATIVE_ENTRY(FunctionTypeMirror_parameters, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& cls = Class::Handle(ref.GetClassReferent());
  const Function& func = Function::Handle(cls.signature_function());
  return CreateParameterMirrorList(func, owner);
}


DEFINE_NATIVE_ENTRY(FunctionTypeMirror_return_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& cls = Class::Handle(ref.GetClassReferent());
  const Function& func = Function::Handle(CallMethod(cls));
  ASSERT(!func.IsNull());
  return func.result_type();
}


static bool FieldIsUninitialized(const Field& field) {
  ASSERT(!field.IsNull());

  // Return getter method for uninitialized fields, rather than the
  // field object, since the value in the field object will not be
  // initialized until the first time the getter is invoked.
  const Instance& value = Instance::Handle(field.value());
  ASSERT(value.raw() != Object::transition_sentinel().raw());
  return value.raw() == Object::sentinel().raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_name, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  return klass.UserVisibleName();
}


DEFINE_NATIVE_ENTRY(ClassMirror_library, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  const Library& library = Library::Handle(klass.library());
  ASSERT(!library.IsNull());
  return CreateLibraryMirror(library);
}


DEFINE_NATIVE_ENTRY(ClassMirror_supertype, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  return klass.super_type();
}


DEFINE_NATIVE_ENTRY(ClassMirror_interfaces, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Error& error = Error::Handle(klass.EnsureIsFinalized(isolate));
  if (!error.IsNull()) {
    ThrowInvokeError(error);
  }

  return klass.interfaces();
}


DEFINE_NATIVE_ENTRY(ClassMirror_mixin, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  return klass.mixin();
}


DEFINE_NATIVE_ENTRY(ClassMirror_members, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance,
                               owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Error& error = Error::Handle(klass.EnsureIsFinalized(isolate));
  if (!error.IsNull()) {
    ThrowInvokeError(error);
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
    member_mirror = CreateVariableMirror(field, owner_mirror);
    member_mirrors.Add(member_mirror);
  }

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.is_visible() &&
        (func.kind() == RawFunction::kRegularFunction ||
        func.kind() == RawFunction::kGetterFunction ||
        func.kind() == RawFunction::kSetterFunction)) {
      member_mirror = CreateMethodMirror(func, owner_mirror);
      member_mirrors.Add(member_mirror);
    }
  }

  return member_mirrors.raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_constructors, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance,
                               owner_mirror,
                               arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());

  const Error& error = Error::Handle(klass.EnsureIsFinalized(isolate));
  if (!error.IsNull()) {
    ThrowInvokeError(error);
  }

  const Array& functions = Array::Handle(klass.functions());
  const intptr_t num_functions = functions.Length();

  Instance& constructor_mirror = Instance::Handle();
  const GrowableObjectArray& constructor_mirrors = GrowableObjectArray::Handle(
      GrowableObjectArray::New(num_functions));

  Function& func = Function::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.kind() == RawFunction::kConstructor) {
      constructor_mirror = CreateMethodMirror(func, owner_mirror);
      constructor_mirrors.Add(constructor_mirror);
    }
  }

  return constructor_mirrors.raw();
}


DEFINE_NATIVE_ENTRY(LibraryMirror_members, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance,
                               owner_mirror,
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
      // We filter out implementation classes like Smi, Mint, Bignum,
      // OneByteString; function signature classes; and dynamic.
      if (!klass.IsCanonicalSignatureClass() &&
          !klass.IsDynamicClass() &&
          !RawObject::IsImplementationClassId(klass.id())) {
        if (klass.NumTypeParameters() == 0) {
          // Include runtime type for non-generics only.
          type = RawTypeOfClass(klass);
        } else {
          type = AbstractType::null();
        }
        member_mirror = CreateClassMirror(klass, type, owner_mirror);
        member_mirrors.Add(member_mirror);
      }
    } else if (entry.IsField()) {
      const Field& field = Field::Cast(entry);
      member_mirror = CreateVariableMirror(field, owner_mirror);
      member_mirrors.Add(member_mirror);
    } else if (entry.IsFunction()) {
      const Function& func = Function::Cast(entry);
      if (func.kind() == RawFunction::kRegularFunction ||
          func.kind() == RawFunction::kGetterFunction ||
          func.kind() == RawFunction::kSetterFunction) {
        member_mirror = CreateMethodMirror(func, owner_mirror);
        member_mirrors.Add(member_mirror);
      }
    }
  }

  return member_mirrors.raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_type_variables, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
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
  const AbstractTypeArguments& args =
      AbstractTypeArguments::Handle(type.arguments());

  // Handle argument lists that have been optimized away, because either no
  // arguments have been provided, or all arguments are dynamic. Return a list
  // of typemirrors on dynamic in this case.
  if (args.IsNull()) {
    arg_type ^= Object::dynamic_type();
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
  // The owner of a type variable must be a generic class: pass a null runtime
  // type to get a mirror on the declaration.
  ASSERT(owner.NumTypeParameters() != 0);
  return CreateClassMirror(owner,
                           AbstractType::Handle(),
                           Instance::null_instance());
}


DEFINE_NATIVE_ENTRY(TypeVariableMirror_upper_bound, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypeParameter, param, arguments->NativeArgAt(0));
  return param.bound();
}


// Invoke the function, or noSuchMethod if it is null. Propagate any unhandled
// exceptions. Wrap and propagate any compilation errors.
static RawObject* ReflectivelyInvokeDynamicFunction(const Instance& receiver,
                                                    const Function& function,
                                                    const String& target_name,
                                                    const Array& arguments) {
  // Note "arguments" is already the internal arguments with the receiver as
  // the first element.
  Object& result = Object::Handle();
  if (function.IsNull() || !function.is_visible()) {
    const Array& arguments_descriptor =
        Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
    result = DartEntry::InvokeNoSuchMethod(receiver,
                                           target_name,
                                           arguments,
                                           arguments_descriptor);
  } else {
    result = DartEntry::InvokeFunction(function, arguments);
  }

  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  const Array& args =
      Array::Handle(Array::New(number_of_arguments + 1));  // Plus receiver.
  Object& arg = Object::Handle();
  args.SetAt(0, reflectee);
  for (int i = 0; i < number_of_arguments; i++) {
    arg = positional_args.At(i);
    args.SetAt(i + 1, arg);  // Plus receiver.
  }

  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(args.Length())));

  Class& klass = Class::Handle(reflectee.clazz());
  Function& function = Function::Handle();
  while (!klass.IsNull()) {
    function = klass.LookupDynamicFunctionAllowPrivate(function_name);
    if (!function.IsNull()) {
      break;
    }
    klass = klass.SuperClass();
  }

  if (!function.IsNull() &&
      !function.AreValidArguments(args_desc, NULL)) {
    function = Function::null();
  }

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           function,
                                           function_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invokeGetter, 3) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));

  // Every instance field has a getter Function.  Try to find the
  // getter in any superclass and use that function to access the
  // field.
  // NB: We do not use Resolver::ResolveDynamic because we want to find private
  // members.
  Class& klass = Class::Handle(reflectee.clazz());
  String& internal_getter_name = String::Handle(Field::GetterName(getter_name));
  Function& getter = Function::Handle();
  while (!klass.IsNull()) {
    getter = klass.LookupDynamicFunctionAllowPrivate(internal_getter_name);
    if (!getter.IsNull()) {
      break;
    }
    klass = klass.SuperClass();
  }

  const int kNumArgs = 1;
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, reflectee);

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           getter,
                                           internal_getter_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(InstanceMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NATIVE_ARGUMENT(Instance, reflectee, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  String& internal_setter_name =
      String::Handle(Field::SetterName(setter_name));
  Function& setter = Function::Handle();

  Class& klass = Class::Handle(reflectee.clazz());
  Field& field = Field::Handle();

  while (!klass.IsNull()) {
    field = klass.LookupInstanceField(setter_name);
    if (!field.IsNull() && field.is_final()) {
      const String& message = String::Handle(
          String::NewFormatted("%s: cannot set final field '%s'.",
                               "InstanceMirror_invokeSetter",
                               setter_name.ToCString()));
      ThrowMirroredCompilationError(message);
      UNREACHABLE();
    }
    setter = klass.LookupDynamicFunctionAllowPrivate(internal_setter_name);
    if (!setter.IsNull()) {
      break;
    }
    klass = klass.SuperClass();
  }

  // Invoke the setter and return the result.
  const int kNumArgs = 2;
  const Array& args = Array::Handle(Array::New(kNumArgs));
  args.SetAt(0, reflectee);
  args.SetAt(1, value);

  return ReflectivelyInvokeDynamicFunction(reflectee,
                                           setter,
                                           internal_setter_name,
                                           args);
}


DEFINE_NATIVE_ENTRY(ClosureMirror_apply, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  ASSERT(!closure.IsNull() && closure.IsCallable(NULL, NULL));

  const Array& positional_args =
      Array::CheckedHandle(arguments->NativeArgAt(1));
  intptr_t number_of_arguments = positional_args.Length();

  // Set up arguments to include the closure as the first argument.
  const Array& args = Array::Handle(Array::New(number_of_arguments + 1));
  Object& obj = Object::Handle();
  args.SetAt(0, closure);
  for (int i = 0; i < number_of_arguments; i++) {
    obj = positional_args.At(i);
    args.SetAt(i + 1, obj);
  }

  obj = DartEntry::InvokeClosure(args);
  if (obj.IsError()) {
    ThrowInvokeError(Error::Cast(obj));
    UNREACHABLE();
  }
  return obj.raw();
}


DEFINE_NATIVE_ENTRY(ClosureMirror_function, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, closure, arguments->NativeArgAt(0));
  ASSERT(!closure.IsNull());

  Function& function = Function::Handle();
  bool callable = closure.IsCallable(&function, NULL);
  ASSERT(callable);

  return CreateMethodMirror(function, Instance::null_instance());
}


DEFINE_NATIVE_ENTRY(ClassMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  const Function& function = Function::Handle(
      klass.LookupStaticFunctionAllowPrivate(function_name));

  if (function.IsNull() ||
      !function.AreValidArgumentCounts(number_of_arguments,
                                       /* named_args */ 0,
                                       NULL) ||
      !function.is_visible()) {
    ThrowNoSuchMethod(AbstractType::Handle(RawTypeOfClass(klass)),
                      function_name,
                      function,
                      InvocationMirror::kStatic,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                            positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
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
  GET_NON_NULL_NATIVE_ARGUMENT(String, getter_name, arguments->NativeArgAt(2));

  // Note static fields do not have implicit getters.
  const Field& field = Field::Handle(klass.LookupStaticField(getter_name));
  if (field.IsNull() || FieldIsUninitialized(field)) {
    const String& internal_getter_name = String::Handle(
        Field::GetterName(getter_name));
    const Function& getter = Function::Handle(
        klass.LookupStaticFunctionAllowPrivate(internal_getter_name));

    if (getter.IsNull() || !getter.is_visible()) {
      ThrowNoSuchMethod(AbstractType::Handle(RawTypeOfClass(klass)),
                        getter_name,
                        getter,
                        InvocationMirror::kStatic,
                        InvocationMirror::kGetter);
      UNREACHABLE();
    }

    // Invoke the getter and return the result.
    Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }
  return field.value();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invokeSetter, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(String, setter_name, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(3));

  // Check for real fields and user-defined setters.
  const Field& field = Field::Handle(klass.LookupStaticField(setter_name));
  if (field.IsNull()) {
    const String& internal_setter_name = String::Handle(
      Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
      klass.LookupStaticFunctionAllowPrivate(internal_setter_name));

    if (setter.IsNull() || !setter.is_visible()) {
      ThrowNoSuchMethod(AbstractType::Handle(RawTypeOfClass(klass)),
                        setter_name,
                        setter,
                        InvocationMirror::kStatic,
                        InvocationMirror::kSetter);
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);

    Object& result = Object::Handle(
        DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final()) {
    const String& message = String::Handle(
        String::NewFormatted("%s: cannot set final field '%s'.",
                             "ClassMirror_invokeSetter",
                             setter_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }

  field.set_value(value);
  return value.raw();
}


DEFINE_NATIVE_ENTRY(ClassMirror_invokeConstructor, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& klass = Class::Handle(ref.GetClassReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, constructor_name, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(2));

  intptr_t number_of_arguments = positional_args.Length();

  // By convention, the static function implementing a named constructor 'C'
  // for class 'A' is labeled 'A.C', and the static function implementing the
  // unnamed constructor for class 'A' is labeled 'A.'.
  // This convention prevents users from explicitly calling constructors.
  const String& klass_name = String::Handle(klass.Name());
  String& internal_constructor_name =
      String::Handle(String::Concat(klass_name, Symbols::Dot()));
  if (!constructor_name.IsNull()) {
    internal_constructor_name =
        String::Concat(internal_constructor_name, constructor_name);
  }

  Function& constructor = Function::Handle(
      klass.LookupFunctionAllowPrivate(internal_constructor_name));

  if (constructor.IsNull() ||
     (!constructor.IsConstructor() && !constructor.IsFactory()) ||
     !constructor.AreValidArgumentCounts(number_of_arguments +
                                         constructor.NumImplicitParameters(),
                                         /* named args */ 0,
                                         NULL) ||
     !constructor.is_visible()) {
    // Pretend we didn't find the constructor at all when the arity is wrong
    // so as to produce the same NoSuchMethodError as the non-reflective case.
    constructor = Function::null();
    ThrowNoSuchMethod(AbstractType::Handle(RawTypeOfClass(klass)),
                      internal_constructor_name,
                      constructor,
                      InvocationMirror::kConstructor,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  const Object& result =
      Object::Handle(DartEntry::InvokeConstructor(klass,
                                                  constructor,
                                                  positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
    UNREACHABLE();
  }
  // Factories may return null.
  ASSERT(result.IsInstance() || result.IsNull());
  return result.raw();
}


DEFINE_NATIVE_ENTRY(LibraryMirror_invoke, 4) {
  // Argument 0 is the mirror, which is unused by the native. It exists
  // because this native is an instance method in order to be polymorphic
  // with its cousins.
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Library& library = Library::Handle(ref.GetLibraryReferent());
  GET_NON_NULL_NATIVE_ARGUMENT(
      String, function_name, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(
      Array, positional_args, arguments->NativeArgAt(3));

  intptr_t number_of_arguments = positional_args.Length();

  String& ambiguity_error_msg = String::Handle(isolate);
  const Function& function = Function::Handle(
      library.LookupFunctionAllowPrivate(function_name, &ambiguity_error_msg));

  if (function.IsNull() && !ambiguity_error_msg.IsNull()) {
    ThrowMirroredCompilationError(ambiguity_error_msg);
    UNREACHABLE();
  }

  if (function.IsNull() ||
     !function.AreValidArgumentCounts(number_of_arguments,
                                      0,
                                      NULL) ||
     !function.is_visible()) {
    ThrowNoSuchMethod(Instance::null_instance(),
                      function_name,
                      function,
                      InvocationMirror::kTopLevel,
                      InvocationMirror::kMethod);
    UNREACHABLE();
  }

  const Object& result = Object::Handle(
      DartEntry::InvokeFunction(function, positional_args));
  if (result.IsError()) {
    ThrowInvokeError(Error::Cast(result));
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

  // To access a top-level we may need to use the Field or the
  // getter Function.  The getter function may either be in the
  // library or in the field's owner class, depending.
  String& ambiguity_error_msg = String::Handle(isolate);
  const Field& field = Field::Handle(
      library.LookupFieldAllowPrivate(getter_name, &ambiguity_error_msg));
  Function& getter = Function::Handle();
  if (field.IsNull() && ambiguity_error_msg.IsNull()) {
    // No field found and no ambiguity error.  Check for a getter in the lib.
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = library.LookupFunctionAllowPrivate(internal_getter_name,
                                                &ambiguity_error_msg);
  } else if (!field.IsNull() && FieldIsUninitialized(field)) {
    // A field was found.  Check for a getter in the field's owner classs.
    const Class& klass = Class::Handle(field.owner());
    const String& internal_getter_name =
        String::Handle(Field::GetterName(getter_name));
    getter = klass.LookupStaticFunctionAllowPrivate(internal_getter_name);
  }

  if (!getter.IsNull() && getter.is_visible()) {
    // Invoke the getter and return the result.
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(getter, Object::empty_array()));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }
  if (!field.IsNull()) {
    return field.value();
  }
  if (ambiguity_error_msg.IsNull()) {
    ThrowNoSuchMethod(Instance::null_instance(),
                      getter_name,
                      getter,
                      InvocationMirror::kTopLevel,
                      InvocationMirror::kGetter);
  } else {
    ThrowMirroredCompilationError(ambiguity_error_msg);
  }
  UNREACHABLE();
  return Instance::null();
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
  String& ambiguity_error_msg = String::Handle(isolate);
  const Field& field = Field::Handle(
      library.LookupFieldAllowPrivate(setter_name, &ambiguity_error_msg));

  if (field.IsNull() && ambiguity_error_msg.IsNull()) {
    const String& internal_setter_name =
        String::Handle(Field::SetterName(setter_name));
    const Function& setter = Function::Handle(
        library.LookupFunctionAllowPrivate(internal_setter_name,
                                           &ambiguity_error_msg));
    if (setter.IsNull() || !setter.is_visible()) {
      if (ambiguity_error_msg.IsNull()) {
        ThrowNoSuchMethod(Instance::null_instance(),
                          setter_name,
                          setter,
                          InvocationMirror::kTopLevel,
                          InvocationMirror::kSetter);
      } else {
        ThrowMirroredCompilationError(ambiguity_error_msg);
      }
      UNREACHABLE();
    }

    // Invoke the setter and return the result.
    const int kNumArgs = 1;
    const Array& args = Array::Handle(Array::New(kNumArgs));
    args.SetAt(0, value);
    const Object& result = Object::Handle(
        DartEntry::InvokeFunction(setter, args));
    if (result.IsError()) {
      ThrowInvokeError(Error::Cast(result));
      UNREACHABLE();
    }
    return result.raw();
  }

  if (field.is_final()) {
    const String& message = String::Handle(
      String::NewFormatted("%s: cannot set final top-level variable '%s'.",
                           "LibraryMirror_invokeSetter",
                           setter_name.ToCString()));
    ThrowMirroredCompilationError(message);
    UNREACHABLE();
  }

  field.set_value(value);
  return value.raw();
}


DEFINE_NATIVE_ENTRY(MethodMirror_owner, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  if (func.IsNonImplicitClosureFunction()) {
    return CreateMethodMirror(Function::Handle(
        func.parent_function()), Object::null_instance());
  }
  const Class& owner = Class::Handle(func.Owner());
  if (owner.IsTopLevel()) {
    return CreateLibraryMirror(Library::Handle(owner.library()));
  }

  AbstractType& type = AbstractType::Handle();
  if (owner.NumTypeParameters() == 0) {
    // Include runtime type for non-generics only.
    type = RawTypeOfClass(owner);
  }
  return CreateClassMirror(owner, type, Object::null_instance());
}


DEFINE_NATIVE_ENTRY(MethodMirror_parameters, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, owner, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return CreateParameterMirrorList(func, owner);
}


DEFINE_NATIVE_ENTRY(MethodMirror_return_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  // We handle constructors in Dart code.
  ASSERT(!func.IsConstructor());
  return func.result_type();
}


DEFINE_NATIVE_ENTRY(MethodMirror_source, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  const Script& script = Script::Handle(func.script());
  const TokenStream& stream = TokenStream::Handle(script.tokens());
  const TokenStream::Iterator tkit(stream, func.end_token_pos());
  intptr_t from_line;
  intptr_t from_col;
  intptr_t to_line;
  intptr_t to_col;
  script.GetTokenLocation(func.token_pos(), &from_line, &from_col);
  script.GetTokenLocation(func.end_token_pos(), &to_line, &to_col);
  intptr_t last_tok_len = String::Handle(tkit.CurrentLiteral()).Length();
  // Handle special cases for end tokens of closures (where we exclude the last
  // token):
  // (1) "foo(() => null, bar);": End token is `,', but we don't print it.
  // (2) "foo(() => null);": End token is ')`, but we don't print it.
  // (3) "var foo = () => null;": End token is `;', but in this case the token
  // semicolon belongs to the assignment so we skip it.
  if ((tkit.CurrentTokenKind() == Token::kCOMMA) ||                   // Case 1.
      (tkit.CurrentTokenKind() == Token::kRPAREN) ||                  // Case 2.
      (tkit.CurrentTokenKind() == Token::kSEMICOLON &&
       String::Handle(func.name()).Equals("<anonymous closure>"))) {  // Case 3.
    last_tok_len = 0;
  }
  return script.GetSnippet(from_line, from_col, to_line, to_col + last_tok_len);
}


DEFINE_NATIVE_ENTRY(TypedefMirror_referent, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Class& cls = Class::Handle(ref.GetClassReferent());
  const Function& sig_func = Function::Handle(cls.signature_function());
  const Class& sig_cls = Class::Handle(sig_func.signature_class());
  return MirrorReference::New(sig_cls);
}


DEFINE_NATIVE_ENTRY(ParameterMirror_type, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, pos, arguments->NativeArgAt(1));
  const Function& func = Function::Handle(ref.GetFunctionReferent());
  return func.ParameterTypeAt(func.NumImplicitParameters() + pos.Value());
}


DEFINE_NATIVE_ENTRY(VariableMirror_type, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(MirrorReference, ref, arguments->NativeArgAt(0));
  const Field& field = Field::Handle(ref.GetFieldReferent());
  return field.type();
}

}  // namespace dart
