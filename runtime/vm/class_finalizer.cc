// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_finalizer.h"

#include "vm/flags.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/object_store.h"

namespace dart {

DEFINE_FLAG(bool, print_classes, false, "Prints details about loaded classes.");
DEFINE_FLAG(bool, trace_class_finalization, false, "Trace class finalization.");
DEFINE_FLAG(bool, verify_implements, false,
    "Verify that all classes implement their interface.");
DECLARE_FLAG(bool, enable_type_checks);

void ClassFinalizer::AddPendingClasses(
    const GrowableArray<const Class*>& classes) {
  if (!classes.is_empty()) {
    ObjectStore* object_store = Isolate::Current()->object_store();
    const Array& old_array = Array::Handle(object_store->pending_classes());
    const intptr_t old_length = old_array.Length();
    const int new_length = old_length + classes.length();
    const Array& new_array = Array::Handle(Array::Grow(old_array, new_length));
    // Add new classes.
    for (int i = 0; i < classes.length(); i++) {
      new_array.SetAt(i + old_length, *classes[i]);
    }
    object_store->set_pending_classes(new_array);
  }
}


bool ClassFinalizer::AllClassesFinalized() {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const Array& classes = Array::Handle(object_store->pending_classes());
  return classes.Length() == 0;
}


// Class finalization occurs:
// a) when bootstrap process completes (VerifyBootstrapClasses).
// b) after the user classes are loaded (dart_api).
bool ClassFinalizer::FinalizePendingClasses() {
  bool retval = true;
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ObjectStore* object_store = isolate->object_store();
  const String& error = String::Handle(object_store->sticky_error());
  if (!error.IsNull()) {
    return false;
  }
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    const Array& class_array = Array::Handle(object_store->pending_classes());
    ASSERT(!class_array.IsNull());
    Class& cls = Class::Handle();
    // First resolve all superclasses.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      if (FLAG_trace_class_finalization) {
        OS::Print("Resolving super and default: %s\n", cls.ToCString());
      }
      ResolveSuperClass(cls);
      if (cls.is_interface()) {
        ResolveDefaultClass(cls);
      }
    }
    // Finalize all classes.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      FinalizeClass(cls);
    }
    if (FLAG_print_classes) {
      for (intptr_t i = 0; i < class_array.Length(); i++) {
        cls ^= class_array.At(i);
        PrintClassInformation(cls);
      }
    }
    if (FLAG_verify_implements) {
      for (intptr_t i = 0; i < class_array.Length(); i++) {
        cls ^= class_array.At(i);
        if (!cls.is_interface()) {
          VerifyClassImplements(cls);
        }
      }
    }
    // Clear pending classes array.
    object_store->set_pending_classes(Array::Handle(Array::Empty()));

    // Check to ensure there are no duplicate definitions in the library
    // hierarchy.
    const String& str = String::Handle(Library::CheckForDuplicateDefinition());
    if (!str.IsNull()) {
      ReportError("Duplicate definition : %s\n", str.ToCString());
    }
  } else {
    retval = false;
  }
  isolate->set_long_jump_base(base);
  return retval;
}


#if defined (DEBUG)
// Adds all interfaces of cls into 'collected'. Duplicate entries may occur.
// No cycles are allowed.
void ClassFinalizer::CollectInterfaces(const Class& cls,
                                       GrowableArray<const Class*>* collected) {
  const Array& interface_array = Array::ZoneHandle(cls.interfaces());
  for (intptr_t i = 0; i < interface_array.Length(); i++) {
    Type& interface = Type::Handle();
    interface ^= interface_array.At(i);
    const Class& interface_class = Class::ZoneHandle(interface.type_class());
    collected->Add(&interface_class);
    CollectInterfaces(interface_class, collected);
  }
}


// Collect all interfaces of the class 'cls' and check that every function
// defined in each interface can be found in the class.
// No need to check instance fields since they have been turned into
// getters/setters.
void ClassFinalizer::VerifyClassImplements(const Class& cls) {
  ASSERT(!cls.is_interface());
  GrowableArray<const Class*> interfaces;
  CollectInterfaces(cls, &interfaces);
  const String& class_name = String::Handle(cls.Name());
  for (int i = 0; i < interfaces.length(); i++) {
    const String& interface_name = String::Handle(interfaces[i]->Name());
    const Array& interface_functions =
        Array::Handle(interfaces[i]->functions());
    for (intptr_t f = 0; f < interface_functions.Length(); f++) {
      Function& interface_function = Function::Handle();
      interface_function ^= interface_functions.At(f);
      const String& function_name = String::Handle(interface_function.name());
      // Check for constructor/factory.
      if (function_name.StartsWith(interface_name)) {
        // TODO(srdjan): convert 'InterfaceName.' to 'ClassName.' and check.
        continue;
      }
      if (interface_function.kind() == RawFunction::kConstImplicitGetter) {
        // This interface constants are not overridable.
        continue;
      }
      // Lookup function in 'cls' and all its super classes.
      Class& test_class = Class::Handle(cls.raw());
      Function& class_function =
          Function::Handle(test_class.LookupDynamicFunction(function_name));
      while (class_function.IsNull()) {
        test_class = test_class.SuperClass();
        if (test_class.IsNull()) break;
        class_function = test_class.LookupDynamicFunction(function_name);
      }
      if (class_function.IsNull()) {
        OS::Print("%s implements '%s' missing: '%s'\n",
            class_name.ToCString(),
            interface_name.ToCString(),
            function_name.ToCString());
      } else if (class_function.IsSubtypeOf(TypeArguments::Handle(),
                                            interface_function,
                                            TypeArguments::Handle())) {
        OS::Print("The type of instance method '%s' in class '%s' is not a "
                  "subtype of the type of '%s' in interface '%s'\n",
                  function_name.ToCString(),
                  class_name.ToCString(),
                  function_name.ToCString(),
                  interface_name.ToCString());
      }
    }
  }
}
#else

void ClassFinalizer::VerifyClassImplements(const Class& cls) {}

#endif


void ClassFinalizer::VerifyBootstrapClasses() {
  if (FLAG_trace_class_finalization) {
    OS::Print("VerifyBootstrapClasses START.\n");
  }
  ObjectStore* object_store = Isolate::Current()->object_store();

  Class& cls = Class::Handle();
#if defined(DEBUG)
  // Basic checking.
  cls = object_store->object_class();
  ASSERT(Instance::InstanceSize() == cls.instance_size());
  cls = object_store->smi_class();
  ASSERT(Smi::InstanceSize() == cls.instance_size());
  cls = object_store->one_byte_string_class();
  ASSERT(OneByteString::InstanceSize() == cls.instance_size());
  cls = object_store->two_byte_string_class();
  ASSERT(TwoByteString::InstanceSize() == cls.instance_size());
  cls = object_store->four_byte_string_class();
  ASSERT(FourByteString::InstanceSize() == cls.instance_size());
  cls = object_store->double_class();
  ASSERT(Double::InstanceSize() == cls.instance_size());
  cls = object_store->mint_class();
  ASSERT(Mint::InstanceSize() == cls.instance_size());
  cls = object_store->bigint_class();
  ASSERT(Bigint::InstanceSize() == cls.instance_size());
  cls = object_store->bool_class();
  ASSERT(Bool::InstanceSize() == cls.instance_size());
  cls = object_store->array_class();
  ASSERT(Array::InstanceSize() == cls.instance_size());
  cls = object_store->immutable_array_class();
  ASSERT(Array::InstanceSize() == cls.instance_size());
#endif  // defined(DEBUG)

  // Remember the currently pending classes.
  const Array& class_array = Array::Handle(object_store->pending_classes());
  for (intptr_t i = 0; i < class_array.Length(); i++) {
    // TODO(iposva): Add real checks.
    cls ^= class_array.At(i);
    if (cls.is_finalized() || cls.is_prefinalized()) {
      // Pre-finalized bootstrap classes must not define any fields.
      ASSERT(Array::Handle(cls.fields()).Length() == 0);
    }
  }

  // Finalize classes that aren't pre-finalized by Object::Init().
  if (!FinalizePendingClasses()) {
    // TODO(srdjan): Exit like a real VM instead.
    const String& err = String::Handle(object_store->sticky_error());
    OS::PrintErr("Could not verify bootstrap classes : %s\n", err.ToCString());
    OS::Exit(255);
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("VerifyBootstrapClasses END.\n");
  }
  Isolate::Current()->heap()->Verify();
}


// Resolve unresolved superclasses (String -> Class).
void ClassFinalizer::ResolveSuperClass(const Class& cls) {
  if (cls.is_finalized()) {
    return;
  }
  Type& super_type = Type::Handle(cls.super_type());
  if (super_type.IsNull()) {
    return;
  }
  // Resolve failures lead to a longjmp.
  super_type = ResolveType(cls, super_type);
  cls.set_super_type(super_type);
  const Class& super_class = Class::Handle(super_type.type_class());
  if (cls.is_interface() != super_class.is_interface()) {
    String& class_name = String::Handle(cls.Name());
    String& super_class_name = String::Handle(super_class.Name());
    ReportError("class '%s' and superclass '%s' are not "
                "both classes or both interfaces.\n",
                class_name.ToCString(),
                super_class_name.ToCString());
  }
  return;
}


void ClassFinalizer::ResolveDefaultClass(const Class& interface) {
  ASSERT(interface.is_interface());
  if (interface.is_finalized()) {
    return;
  }
  Type& factory_type = Type::Handle(interface.factory_type());
  if (factory_type.IsNull()) {
    // No resolving needed.
    return;
  }
  // Resolve failures lead to a longjmp.
  factory_type = ResolveType(interface, factory_type);
  interface.set_factory_type(factory_type);
  if (factory_type.IsInterfaceType()) {
    const String& interface_name = String::Handle(interface.Name());
    ReportError("default clause of interface '%s' does not name a class\n",
                interface_name.ToCString());
  }
}


RawType* ClassFinalizer::ResolveType(const Class& cls, const Type& type) {
  if (type.IsResolved()) {
    return type.raw();
  }

  // Resolve the type class.
  if (!type.HasResolvedTypeClass()) {
    const UnresolvedClass& unresolved_class =
        UnresolvedClass::Handle(type.unresolved_class());
    const String& type_class_name = String::Handle(unresolved_class.ident());

    // The type class name may be a type parameter of cls that was not resolved
    // by the parser because it appeared as part of the declaration
    // as T1 in B<T1, T2 extends A<T1>> or
    // as T2 in B<T1 extends A<T2>, T2>>.
    const TypeParameter& type_parameter = TypeParameter::Handle(
        cls.LookupTypeParameter(type_class_name));
    if (!type_parameter.IsNull()) {
      // No need to check for proper instance scoping, since another type
      // parameter must be involved for the type to still be unresolved.
      // The scope checking was performed for the other type parameter already.

      // A type parameter cannot be parameterized, so report an error if type
      // arguments have previously been parsed.
      if (type.arguments() != TypeArguments::null()) {
        ReportError("type parameter '%s' cannot be parameterized",
                    type_class_name.ToCString());
      }
      return type_parameter.raw();
    }

    // Lookup the type class.
    Class& type_class = Class::Handle();
    Library& lib = Library::Handle();
    if (unresolved_class.qualifier() == String::null()) {
      lib = cls.library();
    } else {
      const String& qualifier = String::Handle(unresolved_class.qualifier());
      LibraryPrefix& lib_prefix = LibraryPrefix::Handle();
      lib_prefix = cls.LookupLibraryPrefix(qualifier);
      if (lib_prefix.IsNull()) {
        const Script& script = Script::Handle(cls.script());
        ReportError(script, unresolved_class.token_index(),
                    "cannot resolve name '%s'\n",
                    String::Handle(unresolved_class.Name()).ToCString());
      }
      lib = lib_prefix.library();
    }
    ASSERT(!lib.IsNull());
    type_class = lib.LookupClass(type_class_name);
    if (type_class.IsNull()) {
      const Script& script = Script::Handle(cls.script());
      ReportError(script, unresolved_class.token_index(),
                  "cannot resolve class name '%s' from '%s'\n",
                  String::Handle(unresolved_class.Name()).ToCString(),
                  String::Handle(cls.Name()).ToCString());
    }
    // Replace unresolved class with resolved type class.
    ASSERT(type.IsParameterizedType());
    ParameterizedType& parameterized_type = ParameterizedType::Handle();
    parameterized_type ^= type.raw();
    parameterized_type.set_type_class(Object::Handle(type_class.raw()));
  }

  // Resolve type arguments, if any.
  const TypeArguments& arguments = TypeArguments::Handle(type.arguments());
  if (!arguments.IsNull()) {
    intptr_t num_arguments = arguments.Length();
    Type& type_argument = Type::Handle();
    for (intptr_t i = 0; i < num_arguments; i++) {
      type_argument = arguments.TypeAt(i);
      type_argument = ResolveType(cls, type_argument);
      arguments.SetTypeAt(i, type_argument);
    }
  }
  return type.raw();
}


// Finalize the type argument vector 'arguments' of the type defined by the
// class 'cls' parameterized with the type arguments 'cls_args'.
// The vector 'cls_args' is already initialized as a subvector at the correct
// position in the passed in 'arguments' vector.
// The subvector 'cls_args' has length cls.NumTypeParameters() and starts at
// offset cls.NumTypeArguments() - cls.NumTypeParameters() of the 'arguments'
// vector.
// Example:
//   Declared: class C<K, V> extends B<V> { ... }
//             class B<T> extends Array<int> { ... }
//   Input:    C<String, double> expressed as
//             cls = C, arguments = [null, null, String, double],
//             i.e. cls_args = [String, double], offset = 2, length = 2.
//   Output:   arguments = [int, double, String, double]
void ClassFinalizer::FinalizeTypeArguments(const Class& cls,
                                           const TypeArguments& arguments) {
  ASSERT(arguments.Length() >= cls.NumTypeArguments());
  // If type checks are enabled, verify the subtyping constraints.
  if (FLAG_enable_type_checks) {
    const intptr_t num_type_params = cls.NumTypeParameters();
    const intptr_t offset = cls.NumTypeArguments() - num_type_params;
    Type& type = Type::Handle();
    Type& type_extends = Type::Handle();
    const TypeArguments& extends_array =
        TypeArguments::Handle(cls.type_parameter_extends());
    ASSERT((extends_array.IsNull() && (num_type_params == 0)) ||
           (extends_array.Length() == num_type_params));
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_extends = extends_array.TypeAt(i);
      if (!type_extends.IsDynamicType()) {
        type = arguments.TypeAt(offset + i);
        if (type.IsInstantiated()) {
          if (!type_extends.IsInstantiated()) {
            type_extends = type_extends.InstantiateFrom(arguments, offset);
          }
          // TODO(regis): Where do we check the constraints when the type is
          // generic?
          if (!type.IsSubtypeOf(type_extends)) {
            const String& type_name = String::Handle(type.Name());
            const String& extends_name = String::Handle(type_extends.Name());
            ReportError("type argument '%s' does not extend type '%s'\n",
                        type_name.ToCString(),
                        extends_name.ToCString());
          }
        }
      }
    }
  }
  const Type& super_type = Type::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    FinalizeType(super_type);
    const Class& super_class = Class::Handle(super_type.type_class());
    const TypeArguments& super_type_args =
        TypeArguments::Handle(super_type.arguments());
    const intptr_t num_super_type_params = super_class.NumTypeParameters();
    const intptr_t offset = super_class.NumTypeArguments();
    const intptr_t super_offset = offset - num_super_type_params;
    ASSERT(offset == (cls.NumTypeArguments() - cls.NumTypeParameters()));
    Type& super_type_arg = Type::Handle();
    for (intptr_t i = 0; i < num_super_type_params; i++) {
      super_type_arg = super_type_args.TypeAt(super_offset + i);
      if (!super_type_arg.IsInstantiated()) {
        super_type_arg = super_type_arg.InstantiateFrom(arguments, offset);
      }
      arguments.SetTypeAt(super_offset + i, super_type_arg);
    }
    FinalizeTypeArguments(super_class, arguments);
  }
}


void ClassFinalizer::FinalizeType(const Type& type) {
  ASSERT(type.IsResolved());
  if (type.IsFinalized()) {
    return;
  }

  // At this point, we can only have a parameterized_type.
  ParameterizedType& parameterized_type = ParameterizedType::Handle();
  parameterized_type ^= type.raw();

  if (parameterized_type.IsBeingFinalized()) {
    ReportError("type '%s' illegally refers to itself\n",
                String::Handle(parameterized_type.Name()).ToCString());
  }

  // Mark type as being finalized in order to detect illegal self reference.
  parameterized_type.set_is_being_finalized();

  // Finalize the current type arguments of the type, which are still the
  // parsed type arguments.
  TypeArguments& arguments =
      TypeArguments::Handle(parameterized_type.arguments());
  if (!arguments.IsNull()) {
    intptr_t num_arguments = arguments.Length();
    for (intptr_t i = 0; i < num_arguments; i++) {
      Type& type_argument = Type::Handle(arguments.TypeAt(i));
      FinalizeType(type_argument);
    }
  }

  // The type class does not need to be finalized in order to finalize the type,
  // however, it must at least be resolved. This was done as part of resolving
  // the type itself.
  Class& type_class = Class::Handle(parameterized_type.type_class());

  // The finalized type argument vector needs num_type_arguments types.
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  // The type class has num_type_parameters type parameters.
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // Initialize the type argument vector.
  // Check the number of parsed type arguments, if any.
  // Specifying no type arguments indicates a raw type, which is not an error.
  // However, subtyping constraints are checked below, even for a raw type.
  if (!arguments.IsNull() && (arguments.Length() != num_type_parameters)) {
    // TODO(regis): We need to store the token_index in each type.
    ReportError("wrong number of type arguments in type '%s'\n",
                String::Handle(type.Name()).ToCString());
  }
  // The full type argument vector consists of the type arguments of the
  // super types of type_class, which may be initialized from the parsed
  // type arguments, followed by the parsed type arguments.
  if (num_type_arguments > 0) {
    const TypeArguments& full_arguments = TypeArguments::Handle(
        TypeArguments::NewTypeArray(num_type_arguments));
    // Copy the parsed type arguments at the correct offset in the full type
    // argument vector.
    const intptr_t offset = num_type_arguments - num_type_parameters;
    Type& type = Type::Handle(Type::DynamicType());
    for (intptr_t i = 0; i < num_type_parameters; i++) {
      // If no type parameters were provided, a raw type is desired, so we
      // create a vector of DynamicType.
      if (!arguments.IsNull()) {
        type = arguments.TypeAt(i);
      }
      full_arguments.SetTypeAt(offset + i, type);
    }
    FinalizeTypeArguments(type_class, full_arguments);
    parameterized_type.set_arguments(full_arguments);
  }

  // If the type is a function type, finalize the result and parameter types.
  if (type_class.IsSignatureClass()) {
    ResolveAndFinalizeSignature(
        type_class, Function::Handle(type_class.signature_function()));
  }

  parameterized_type.set_is_finalized();
}


RawString* ClassFinalizer::FinalizeTypeWhileParsing(const Type& type) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    FinalizeType(type);
    isolate->set_long_jump_base(base);
    return String::null();
  } else {
    // Error occured: Get the error message.
    isolate->set_long_jump_base(base);
    return isolate->object_store()->sticky_error();
  }
  UNREACHABLE();
  return String::null();
}


// Top level function signatures are canonicalized, added to the library class
// dictionary, and finalized with other library classes and interfaces.
// Function signatures used as type of a local variable or of a local function
// are canonicalized and finalized upon creation, since all the types they
// reference are already resolved.
void ClassFinalizer::ResolveAndFinalizeSignature(const Class& cls,
                                                 const Function& function) {
  // Resolve result type.
  Type& type = Type::Handle(function.result_type());
  type = ResolveType(cls, type);
  function.set_result_type(type);
  FinalizeType(type);
  // Resolve formal parameter types.
  const intptr_t num_parameters = function.NumberOfParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    type = ResolveType(cls, type);
    function.SetParameterTypeAt(i, type);
    FinalizeType(type);
  }
}


static RawClass* FindSuperOwnerOfInstanceMember(const Class& cls,
                                                const String& name) {
  Class& super_class = Class::Handle();
  Function& function = Function::Handle();
  Field& field = Field::Handle();
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
    // Check if an instance member of same name exists in any super class.
    function = super_class.LookupFunction(name);
    if (!function.IsNull() && !function.is_static()) {
      return super_class.raw();
    }
    field = super_class.LookupField(name);
    if (!field.IsNull() && !field.is_static()) {
      return super_class.raw();
    }
    super_class = super_class.SuperClass();
  }
  return Class::null();
}


static RawClass* FindSuperOwnerOfFunction(const Class& cls,
                                          const String& name) {
  Class& super_class = Class::Handle();
  Function& function = Function::Handle();
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
    // Check if a function of same name exists in any super class.
    function = super_class.LookupFunction(name);
    if (!function.IsNull()) {
      return super_class.raw();
    }
    super_class = super_class.SuperClass();
  }
  return Class::null();
}


void ClassFinalizer::ResolveAndFinalizeMemberTypes(const Class& cls) {
  // Note that getters and setters are explicitly listed as such in the list of
  // functions of a class, so we do not need to consider fields as implicitly
  // generating getters and setters.
  // The only compile errors we report are therefore:
  // - a getter having the same name as a method (but not a getter) in a super
  //   class or in a subclass.
  // - a setter having the same name as a method (but not a setter) in a super
  //   class or in a subclass.
  // - a static field, instance field, or static method (but not an instance
  //   method) having the same name as an instance member in a super class.

  // Resolve type of fields and check for conflicts in super classes.
  Array& array = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  Type& type = Type::Handle();
  String& name = String::Handle();
  Class& super_class = Class::Handle();
  intptr_t num_fields = array.Length();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    type = ResolveType(cls, type);
    field.set_type(type);
    FinalizeType(type);
    name = field.name();
    super_class = FindSuperOwnerOfInstanceMember(cls, name);
    if (!super_class.IsNull()) {
      const String& class_name = String::Handle(cls.Name());
      const String& super_class_name = String::Handle(super_class.Name());
      ReportError("field '%s' of class '%s' conflicts with instance "
                  "member '%s' of super class '%s'.\n",
                  name.ToCString(),
                  class_name.ToCString(),
                  name.ToCString(),
                  super_class_name.ToCString());
    }
  }
  // Resolve function signatures and check for conflicts in super classes.
  array = cls.functions();
  Function& function = Function::Handle();
  Function& overridden_function = Function::Handle();
  intptr_t num_functions = array.Length();
  String& function_name = String::Handle();
  for (intptr_t i = 0; i < num_functions; i++) {
    function ^= array.At(i);
    ResolveAndFinalizeSignature(cls, function);
    function_name = function.name();
    if (function.is_static()) {
      super_class = FindSuperOwnerOfInstanceMember(cls, function_name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        ReportError("static function '%s' of class '%s' conflicts with "
                    "instance member '%s' of super class '%s'.\n",
                    function_name.ToCString(),
                    class_name.ToCString(),
                    function_name.ToCString(),
                    super_class_name.ToCString());
      }
    } else {
      // TODO(regis): This arity check is still being debated. Revisit.
      super_class = cls.SuperClass();
      while (!super_class.IsNull()) {
        overridden_function = super_class.LookupDynamicFunction(function_name);
        if (!overridden_function.IsNull() &&
          !function.HasCompatibleParametersWith(overridden_function)) {
          // Function types are purposely not checked for subtyping.
          const String& class_name = String::Handle(cls.Name());
          const String& super_class_name = String::Handle(super_class.Name());
          ReportError("class '%s' overrides function '%s' of super class '%s' "
                      "with incompatible parameters.\n",
                      class_name.ToCString(),
                      function_name.ToCString(),
                      super_class_name.ToCString());
        }
        super_class = super_class.SuperClass();
      }
    }
    if (function.kind() == RawFunction::kGetterFunction) {
      name = Field::NameFromGetter(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        ReportError("getter '%s' of class '%s' conflicts with "
                    "function '%s' of super class '%s'.\n",
                    name.ToCString(),
                    class_name.ToCString(),
                    name.ToCString(),
                    super_class_name.ToCString());
      }
    } else if (function.kind() == RawFunction::kSetterFunction) {
      name = Field::NameFromSetter(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        ReportError("setter '%s' of class '%s' conflicts with "
                    "function '%s' of super class '%s'.\n",
                    name.ToCString(),
                    class_name.ToCString(),
                    name.ToCString(),
                    super_class_name.ToCString());
      }
    } else {
      name = Field::GetterName(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        ReportError("function '%s' of class '%s' conflicts with "
                    "getter '%s' of super class '%s'.\n",
                    function_name.ToCString(),
                    class_name.ToCString(),
                    function_name.ToCString(),
                    super_class_name.ToCString());
      }
      name = Field::SetterName(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        ReportError("function '%s' of class '%s' conflicts with "
                    "setter '%s' of super class '%s'.\n",
                    function_name.ToCString(),
                    class_name.ToCString(),
                    function_name.ToCString(),
                    super_class_name.ToCString());
      }
    }
  }
  // Resolve the signature type if this class is a signature class.
  if (cls.IsSignatureClass()) {
    const Type& signature_type = Type::Handle(cls.SignatureType());
    FinalizeType(signature_type);
  }
}


void ClassFinalizer::FinalizeClass(const Class& cls) {
  if (cls.is_finalized()) {
    return;
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("Finalize %s\n", cls.ToCString());
  }
  if (!IsSuperCycleFree(cls)) {
    const String& name = String::Handle(cls.Name());
    ReportError("class '%s' has a cycle in its superclass relationship.\n",
                name.ToCString());
  }
  GrowableArray<const Class*> visited;
  ResolveInterfaces(cls, &visited);
  const Type& super_type = Type::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    // Finalize super class and super type.
    FinalizeClass(super_class);
    FinalizeType(super_type);
  }
  if (cls.is_interface()) {
    const Type& factory_type = Type::Handle(cls.factory_type());
    if (!factory_type.IsNull()) {
      const Class& factory_class = Class::Handle(factory_type.type_class());
      // Finalize factory class and factory type.
      if (!factory_class.is_finalized()) {
        FinalizeClass(factory_class);
        // Finalizing the factory class may indirectly finalize this interface.
        if (cls.is_finalized()) {
          return;
        }
      }
      FinalizeType(factory_type);
    }
  }
  // Finalize interface types (but not necessarily interface classes).
  Array& interface_types = Array::Handle(cls.interfaces());
  Type& interface_type = Type::Handle();
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    FinalizeType(interface_type);
  }
  // Mark as finalized before resolving member types in order to break cycles.
  cls.Finalize();
  ResolveAndFinalizeMemberTypes(cls);
  // Run additional checks after all types are finalized.
  if (cls.is_const()) {
    CheckForLegalConstClass(cls);
  }
}


bool ClassFinalizer::IsSuperCycleFree(const Class& cls) {
  Class& test1 = Class::Handle(cls.raw());
  Class& test2 = Class::Handle(cls.SuperClass());
  // A finalized class has been checked for cycles.
  // Using the hare and tortoise algorithm for locating cycles.
  while (!test1.is_finalized() &&
         !test2.IsNull() && !test2.is_finalized()) {
    if (test1.raw() == test2.raw()) {
      // Found a cycle.
      return false;
    }
    test1 = test1.SuperClass();
    test2 = test2.SuperClass();
    if (!test2.IsNull()) {
      test2 = test2.SuperClass();
    }
  }
  // No cycles.
  return true;
}


bool ClassFinalizer::AddInterfaceIfUnique(GrowableArray<Type*>* interface_list,
                                          Type* interface,
                                          Type* conflicting) {
  String& interface_class_name = String::Handle(interface->ClassName());
  String& existing_interface_class_name = String::Handle();
  for (intptr_t i = 0; i < interface_list->length(); i++) {
    existing_interface_class_name = (*interface_list)[i]->ClassName();
    if (interface_class_name.Equals(existing_interface_class_name)) {
      // Same interface class name, now check names of type arguments.
      const String& interface_name = String::Handle(interface->Name());
      const String& existing_interface_name =
          String::Handle((*interface_list)[i]->Name());
      // TODO(regis): Revisit depending on the outcome of issue 4905685.
      if (!interface_name.Equals(existing_interface_name)) {
        *conflicting = (*interface_list)[i]->raw();
        return false;
      } else {
        return true;
      }
    }
  }
  interface_list->Add(interface);
  return true;
}


template<typename T>
static RawArray* NewArray(const GrowableArray<T*>& objs) {
  Array& a = Array::Handle(Array::New(objs.length()));
  for (int i = 0; i < objs.length(); i++) {
    a.SetAt(i, *objs[i]);
  }
  return a.raw();
}


// Walks the graph of explicitly declared interfaces of classes and
// interfaces recursively. Resolves unresolved interfaces.
// Returns false if there is an interface reference that cannot be
// resolved, or if there is a cycle in the graph. We detect cycles by
// remembering interfaces we've visited in each path through the
// graph. If we visit an interface a second time on a given path,
// we found a loop.
void ClassFinalizer::ResolveInterfaces(const Class& cls,
                                       GrowableArray<const Class*>* visited) {
  ASSERT(visited != NULL);
  for (int i = 0; i < visited->length(); i++) {
    if ((*visited)[i]->raw() == cls.raw()) {
      // We have already visited interface class 'cls'. We found a cycle.
      const String& interface_name = String::Handle(cls.Name());
      ReportError("Cyclic reference found for interface '%s'\n",
                  interface_name.ToCString());
    }
  }

  // If the class/interface has no explicit interfaces, we are done.
  Array& super_interfaces = Array::Handle(cls.interfaces());
  if (super_interfaces.Length() == 0) {
    return;
  }

  visited->Add(&cls);
  Type& interface = Type::Handle();
  for (intptr_t i = 0; i < super_interfaces.Length(); i++) {
    interface ^= super_interfaces.At(i);
    interface = ResolveType(cls, interface);
    super_interfaces.SetAt(i, interface);
    if (interface.IsTypeParameter()) {
      ReportError("Type parameter '%s' cannot be used as interface\n",
                  String::Handle(interface.Name()).ToCString());
    }
    const Class& interface_class = Class::Handle(interface.type_class());
    if (!interface_class.is_interface()) {
      ReportError("Class name '%s' used where interface expected\n",
                  String::Handle(interface_class.Name()).ToCString());
    }
    // TODO(regis): Verify that unless cls is in core lib, it cannot implement
    // an instance of Number or String. Any other? bool?

    // Now resolve the super interfaces.
    ResolveInterfaces(interface_class, visited);
  }
  visited->RemoveLast();
}


// A class is marked as constant if it has one constant constructor.
// A constant class:
// - may extend only const classes.
// - has only const instance fields.
// Note: we must check for cycles before checking for const properties.
void ClassFinalizer::CheckForLegalConstClass(const Class& cls) {
  ASSERT(cls.is_const());
  const Class& super = Class::Handle(cls.SuperClass());
  if (!super.IsNull() && !super.is_const()) {
    String& name = String::Handle(super.Name());
    ReportError("superclass '%s' must be const.\n", name.ToCString());
  }
  const Array& fields_array = Array::Handle(cls.fields());
  intptr_t len = fields_array.Length();
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    if (!field.is_static() && !field.is_final()) {
      const String& class_name = String::Handle(cls.Name());
      const String& field_name = String::Handle(field.name());
      ReportError("const class '%s' has non-final field '%s'\n",
                  class_name.ToCString(), field_name.ToCString());
    }
  }
}


void ClassFinalizer::PrintClassInformation(const Class& cls) {
  HANDLESCOPE();
  const String& class_name = String::Handle(cls.Name());
  OS::Print("%s '%s'",
            cls.is_interface() ? "interface" : "class",
            class_name.ToCString());
  const Library& library = Library::Handle(cls.library());
  if (!library.IsNull()) {
    OS::Print(" library '%s%s':\n",
              String::Handle(library.url()).ToCString(),
              String::Handle(library.private_key()).ToCString());
  } else {
    OS::Print(" (null library):\n");
  }
  const Array& interfaces_array = Array::Handle(cls.interfaces());
  Type& interface = Type::Handle();
  intptr_t len = interfaces_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    interface ^= interfaces_array.At(i);
    OS::Print("  %s\n", interface.ToCString());
  }
  const Array& functions_array = Array::Handle(cls.functions());
  Function& function = Function::Handle();
  len = functions_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= functions_array.At(i);
    OS::Print("  %s\n", function.ToCString());
  }
  const Array& fields_array = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  len = fields_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    OS::Print("  %s\n", field.ToCString());
  }
}


void ClassFinalizer::ReportError(const Script& script,
                                 intptr_t token_index,
                                 const char* format, ...) {
  static const int kBufferLength = 1024;
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Zone* zone = isolate->current_zone();
  ASSERT(zone != NULL);
  char* msg_buffer = reinterpret_cast<char*>(zone->Allocate(kBufferLength + 1));

  const String& script_url = String::CheckedHandle(script.url());
  const int buf_size = 256;
  static char text_buffer[buf_size];
  intptr_t line, column;
  script.GetTokenLocation(token_index, &line, &column);
  va_list args;
  va_start(args, format);
  OS::VSNPrint(text_buffer, buf_size, format, args);
  va_end(args);

  intptr_t msg_len = OS::SNPrint(msg_buffer, kBufferLength,
                                 "'%s': line %d pos %d: %s\n",
                                 script_url.ToCString(),
                                 line, column, text_buffer);
  const String& text = String::Handle(script.GetLine(line));
  ASSERT(!text.IsNull());
  if (text.Length() < buf_size) {
    OS::SNPrint(msg_buffer + msg_len, (kBufferLength - msg_len), "%s\n%*s\n",
                text.ToCString(), column, "^");
  }
  isolate->long_jump_base()->Jump(1, msg_buffer);
  UNREACHABLE();
}


void ClassFinalizer::ReportError(const char* format, ...) {
  static const int kBufferLength = 1024;
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Zone* zone = isolate->current_zone();
  ASSERT(zone != NULL);
  char* msg_buffer = reinterpret_cast<char*>(zone->Allocate(kBufferLength + 1));
  ASSERT(msg_buffer != NULL);
  va_list args;
  va_start(args, format);
  OS::VSNPrint(msg_buffer, kBufferLength, format, args);
  va_end(args);
  isolate->long_jump_base()->Jump(1, msg_buffer);
  UNREACHABLE();
}

}  // namespace dart
