// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_finalizer.h"

#include "vm/flags.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, error_on_malformed_type, false,
            "Report error for malformed types.");
DEFINE_FLAG(bool, print_classes, false, "Prints details about loaded classes.");
DEFINE_FLAG(bool, trace_class_finalization, false, "Trace class finalization.");
DEFINE_FLAG(bool, trace_type_finalization, false, "Trace type finalization.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, use_cha);

bool ClassFinalizer::AllClassesFinalized() {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(object_store->pending_classes());
  return classes.Length() == 0;
}


// Removes optimized code once we load more classes, since --use_cha based
// optimizations may have become invalid.
// Only methods which owner classes where subclasses can be invalid.
// TODO(srdjan): Be even more precise by recording the exact CHA optimization.
static void RemoveOptimizedCode(
    const GrowableArray<intptr_t>& added_subclasses_to_cids) {
  ASSERT(FLAG_use_cha);
  if (added_subclasses_to_cids.is_empty()) return;
  // TODO(regis): Reenable this code for mips when possible.
#if defined(TARGET_ARCH_IA32) ||                                               \
    defined(TARGET_ARCH_X64) ||                                                \
    defined(TARGET_ARCH_ARM)
  // Deoptimize all live frames.
  DeoptimizeIfOwner(added_subclasses_to_cids);
  // Switch all functions' code to unoptimized.
  const ClassTable& class_table = *Isolate::Current()->class_table();
  Class& cls = Class::Handle();
  Array& array = Array::Handle();
  Function& function = Function::Handle();
  for (intptr_t i = 0; i < added_subclasses_to_cids.length(); i++) {
    intptr_t cid = added_subclasses_to_cids[i];
    cls = class_table.At(cid);
    ASSERT(!cls.IsNull());
    array = cls.functions();
    intptr_t num_functions = array.IsNull() ? 0 : array.Length();
    for (intptr_t f = 0; f < num_functions; f++) {
      function ^= array.At(f);
      ASSERT(!function.IsNull());
      if (function.HasOptimizedCode()) {
        function.SwitchToUnoptimizedCode();
      }
    }
  }
#endif
}


void AddSuperType(const AbstractType& type,
                  GrowableArray<intptr_t>* finalized_super_classes) {
  ASSERT(type.HasResolvedTypeClass());
  ASSERT(!type.IsDynamicType());
  if (type.IsObjectType()) {
    return;
  }
  const Class& cls = Class::Handle(type.type_class());
  ASSERT(cls.is_finalized());
  const intptr_t cid = cls.id();
  for (intptr_t i = 0; i < finalized_super_classes->length(); i++) {
    if ((*finalized_super_classes)[i] == cid) {
      // Already added.
      return;
    }
  }
  finalized_super_classes->Add(cid);
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  AddSuperType(super_type, finalized_super_classes);
}


// Use array instead of set since we expect very few subclassed classes
// to occur.
static void CollectFinalizedSuperClasses(
    const GrowableObjectArray& pending_classes,
    GrowableArray<intptr_t>* finalized_super_classes) {
  Class& cls = Class::Handle();
  AbstractType& super_type = Type::Handle();
  for (intptr_t i = 0; i < pending_classes.Length(); i++) {
    cls ^= pending_classes.At(i);
    ASSERT(!cls.is_finalized());
    super_type = cls.super_type();
    if (!super_type.IsNull()) {
      if (!super_type.IsMalformed() &&
          super_type.HasResolvedTypeClass() &&
          Class::Handle(super_type.type_class()).is_finalized()) {
        AddSuperType(super_type, finalized_super_classes);
      }
    }
  }
}


// Class finalization occurs:
// a) when bootstrap process completes (VerifyBootstrapClasses).
// b) after the user classes are loaded (dart_api).
bool ClassFinalizer::FinalizePendingClasses() {
  bool retval = true;
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  HANDLESCOPE(isolate);
  ObjectStore* object_store = isolate->object_store();
  const Error& error = Error::Handle(object_store->sticky_error());
  if (!error.IsNull()) {
    return false;
  }
  if (AllClassesFinalized()) {
    return true;
  }

  GrowableArray<intptr_t> added_subclasses_to_cids;
  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  if (setjmp(*jump.Set()) == 0) {
    GrowableObjectArray& class_array = GrowableObjectArray::Handle();
    class_array = object_store->pending_classes();
    ASSERT(!class_array.IsNull());
    // Collect superclasses that were already finalized before this run of
    // finalization.
    CollectFinalizedSuperClasses(class_array, &added_subclasses_to_cids);
    Class& cls = Class::Handle();
    // First resolve all superclasses.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      if (FLAG_trace_class_finalization) {
        OS::Print("Resolving super and interfaces: %s\n", cls.ToCString());
      }
      GrowableArray<intptr_t> visited_interfaces;
      ResolveSuperTypeAndInterfaces(cls, &visited_interfaces);
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
    // Clear pending classes array.
    class_array = GrowableObjectArray::New();
    object_store->set_pending_classes(class_array);
    VerifyImplicitFieldOffsets();  // Verification after an error may fail.
  } else {
    retval = false;
  }
  isolate->set_long_jump_base(base);
  if (FLAG_use_cha) {
    RemoveOptimizedCode(added_subclasses_to_cids);
  }
  return retval;
}


// Adds all interfaces of cls into 'collected'. Duplicate entries may occur.
// No cycles are allowed.
void ClassFinalizer::CollectInterfaces(const Class& cls,
                                       const GrowableObjectArray& collected) {
  const Array& interface_array = Array::Handle(cls.interfaces());
  AbstractType& interface = AbstractType::Handle();
  Class& interface_class = Class::Handle();
  for (intptr_t i = 0; i < interface_array.Length(); i++) {
    interface ^= interface_array.At(i);
    interface_class = interface.type_class();
    collected.Add(interface_class);
    CollectInterfaces(interface_class, collected);
  }
}


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
  cls = object_store->integer_implementation_class();
  ASSERT(Integer::InstanceSize() == cls.instance_size());
  cls = object_store->smi_class();
  ASSERT(Smi::InstanceSize() == cls.instance_size());
  cls = object_store->mint_class();
  ASSERT(Mint::InstanceSize() == cls.instance_size());
  cls = object_store->bigint_class();
  ASSERT(Bigint::InstanceSize() == cls.instance_size());
  cls = object_store->one_byte_string_class();
  ASSERT(OneByteString::InstanceSize() == cls.instance_size());
  cls = object_store->two_byte_string_class();
  ASSERT(TwoByteString::InstanceSize() == cls.instance_size());
  cls = object_store->external_one_byte_string_class();
  ASSERT(ExternalOneByteString::InstanceSize() == cls.instance_size());
  cls = object_store->external_two_byte_string_class();
  ASSERT(ExternalTwoByteString::InstanceSize() == cls.instance_size());
  cls = object_store->double_class();
  ASSERT(Double::InstanceSize() == cls.instance_size());
  cls = object_store->bool_class();
  ASSERT(Bool::InstanceSize() == cls.instance_size());
  cls = object_store->array_class();
  ASSERT(Array::InstanceSize() == cls.instance_size());
  cls = object_store->immutable_array_class();
  ASSERT(ImmutableArray::InstanceSize() == cls.instance_size());
  cls = object_store->weak_property_class();
  ASSERT(WeakProperty::InstanceSize() == cls.instance_size());
#endif  // defined(DEBUG)

  // Remember the currently pending classes.
  const GrowableObjectArray& class_array =
      GrowableObjectArray::Handle(object_store->pending_classes());
  for (intptr_t i = 0; i < class_array.Length(); i++) {
    // TODO(iposva): Add real checks.
    cls ^= class_array.At(i);
    if (cls.is_finalized() || cls.is_prefinalized()) {
      // Pre-finalized bootstrap classes must not define any fields.
      ASSERT(!cls.HasInstanceFields());
    }
  }

  // Finalize classes that aren't pre-finalized by Object::Init().
  if (!FinalizePendingClasses()) {
    // TODO(srdjan): Exit like a real VM instead.
    const Error& err = Error::Handle(object_store->sticky_error());
    OS::PrintErr("Could not verify bootstrap classes : %s\n",
                 err.ToErrorCString());
    OS::Exit(255);
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("VerifyBootstrapClasses END.\n");
  }
  Isolate::Current()->heap()->Verify();
}


// Resolve unresolved_class in the library of cls, or return null.
RawClass* ClassFinalizer::ResolveClass(
    const Class& cls, const UnresolvedClass& unresolved_class) {
  const String& class_name = String::Handle(unresolved_class.ident());
  Library& lib = Library::Handle();
  Class& resolved_class = Class::Handle();
  if (unresolved_class.library_prefix() == LibraryPrefix::null()) {
    lib = cls.library();
    ASSERT(!lib.IsNull());
    resolved_class = lib.LookupClass(class_name);
  } else {
    LibraryPrefix& lib_prefix = LibraryPrefix::Handle();
    lib_prefix = unresolved_class.library_prefix();
    ASSERT(!lib_prefix.IsNull());
    resolved_class = lib_prefix.LookupLocalClass(class_name);
  }
  return resolved_class.raw();
}


void ClassFinalizer::ResolveRedirectingFactoryTarget(
    const Class& cls,
    const Function& factory,
    const GrowableObjectArray& visited_factories) {
  ASSERT(factory.IsRedirectingFactory());

  // Check for redirection cycle.
  for (int i = 0; i < visited_factories.Length(); i++) {
    if (visited_factories.At(i) == factory.raw()) {
      // A redirection cycle is reported as a compile-time error.
      const Script& script = Script::Handle(cls.script());
      ReportError(script, factory.token_pos(),
                  "factory '%s' illegally redirects to itself",
                  String::Handle(factory.name()).ToCString());
    }
  }
  visited_factories.Add(factory);

  // Check if target is already resolved.
  Type& type = Type::Handle(factory.RedirectionType());
  Function& target = Function::Handle(factory.RedirectionTarget());
  if (type.IsMalformed()) {
    // Already resolved to a malformed type. Will throw on usage.
    ASSERT(target.IsNull());
    return;
  }
  if (!target.IsNull()) {
    // Already resolved.
    return;
  }

  // Target is not resolved yet.
  if (FLAG_trace_class_finalization) {
    OS::Print("Resolving redirecting factory: %s\n",
              String::Handle(factory.name()).ToCString());
  }
  ResolveType(cls, type, kCanonicalize);
  type ^= FinalizeType(cls, type, kCanonicalize);
  factory.SetRedirectionType(type);
  if (type.IsMalformed()) {
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }
  const Class& target_class = Class::Handle(type.type_class());
  String& target_class_name = String::Handle(target_class.Name());
  String& target_name = String::Handle(
      String::Concat(target_class_name, Symbols::Dot()));
  const String& identifier = String::Handle(factory.RedirectionIdentifier());
  if (!identifier.IsNull()) {
    target_name = String::Concat(target_name, identifier);
  }

  // Verify that the target constructor of the redirection exists.
  target = target_class.LookupConstructor(target_name);
  if (target.IsNull()) {
    target = target_class.LookupFactory(target_name);
  }
  if (target.IsNull()) {
    const String& user_visible_target_name =
        identifier.IsNull() ? target_class_name : target_name;
    // Replace the type with a malformed type and compile a throw when called.
    type = NewFinalizedMalformedType(
        Error::Handle(),  // No previous error.
        cls,
        factory.token_pos(),
        kTryResolve,  // No compile-time error.
        "class '%s' has no constructor or factory named '%s'",
        target_class_name.ToCString(),
        user_visible_target_name.ToCString());
    factory.SetRedirectionType(type);
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }

  // Verify that the target is compatible with the redirecting factory.
  if (!target.HasCompatibleParametersWith(factory)) {
    type = NewFinalizedMalformedType(
        Error::Handle(),  // No previous error.
        cls,
        factory.token_pos(),
        kTryResolve,  // No compile-time error.
        "constructor '%s' has incompatible parameters with "
        "redirecting factory '%s'",
        String::Handle(target.name()).ToCString(),
        String::Handle(factory.name()).ToCString());
    factory.SetRedirectionType(type);
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }

  // Verify that the target is const if the the redirecting factory is const.
  if (factory.is_const() && !target.is_const()) {
    const Script& script = Script::Handle(cls.script());
    ReportError(script, factory.token_pos(),
                "constructor '%s' must be const as required by redirecting"
                "const factory '%s'",
                String::Handle(target.name()).ToCString(),
                String::Handle(factory.name()).ToCString());
  }

  // Update redirection data with resolved target.
  factory.SetRedirectionTarget(target);
  factory.SetRedirectionIdentifier(String::Handle());  // Not needed anymore.
  if (!target.IsRedirectingFactory()) {
    return;
  }

  // The target is itself a redirecting factory. Recursively resolve its own
  // target and update the current redirection data to point to the end target
  // of the redirection chain.
  ResolveRedirectingFactoryTarget(target_class, target, visited_factories);
  Type& target_type = Type::Handle(target.RedirectionType());
  Function& target_target = Function::Handle(target.RedirectionTarget());
  if (target_target.IsNull()) {
    ASSERT(target_type.IsMalformed());
  } else {
    // If the target type refers to type parameters, substitute them with the
    // type arguments of the redirection type.
    if (!target_type.IsInstantiated()) {
      const AbstractTypeArguments& type_args = AbstractTypeArguments::Handle(
          type.arguments());
      Error& malformed_error = Error::Handle();
      target_type ^= target_type.InstantiateFrom(type_args, &malformed_error);
      if (malformed_error.IsNull()) {
        target_type ^= FinalizeType(cls, target_type, kCanonicalize);
      } else {
        FinalizeMalformedType(malformed_error,
                              cls, target_type, kFinalize,
                              "cannot resolve redirecting factory");
        target_target = Function::null();
      }
    }
  }
  factory.SetRedirectionType(target_type);
  factory.SetRedirectionTarget(target_target);
}


void ClassFinalizer::ResolveType(const Class& cls,
                                 const AbstractType& type,
                                 FinalizationKind finalization) {
  if (type.IsResolved() || type.IsFinalized()) {
    if ((finalization == kCanonicalizeWellFormed) && type.IsMalformed()) {
      ReportError(Error::Handle(type.malformed_error()));
    }
    return;
  }
  if (FLAG_trace_type_finalization) {
    OS::Print("Resolve type '%s'\n", String::Handle(type.Name()).ToCString());
  }

  // Resolve the type class.
  if (!type.HasResolvedTypeClass()) {
    // Type parameters are always resolved in the parser in the correct
    // non-static scope or factory scope. That resolution scope is unknown here.
    // Being able to resolve a type parameter from class cls here would indicate
    // that the type parameter appeared in a static scope. Leaving the type as
    // unresolved is the correct thing to do.

    // Lookup the type class.
    const UnresolvedClass& unresolved_class =
        UnresolvedClass::Handle(type.unresolved_class());
    const Class& type_class =
        Class::Handle(ResolveClass(cls, unresolved_class));

    // Replace unresolved class with resolved type class.
    const Type& parameterized_type = Type::Cast(type);
    if (!type_class.IsNull()) {
      parameterized_type.set_type_class(type_class);
    } else {
      // The type class could not be resolved. The type is malformed.
      FinalizeMalformedType(Error::Handle(),  // No previous error.
                            cls, parameterized_type, finalization,
                            "cannot resolve class name '%s' from '%s'",
                            String::Handle(unresolved_class.Name()).ToCString(),
                            String::Handle(cls.Name()).ToCString());
      return;
    }
  }

  // Resolve type arguments, if any.
  const AbstractTypeArguments& arguments =
      AbstractTypeArguments::Handle(type.arguments());
  if (!arguments.IsNull()) {
    intptr_t num_arguments = arguments.Length();
    AbstractType& type_argument = AbstractType::Handle();
    for (intptr_t i = 0; i < num_arguments; i++) {
      type_argument = arguments.TypeAt(i);
      ResolveType(cls, type_argument, finalization);
    }
  }
}


void ClassFinalizer::FinalizeTypeParameters(const Class& cls) {
  // The type parameter bounds are not finalized here.
  const TypeArguments& type_parameters =
      TypeArguments::Handle(cls.type_parameters());
  if (!type_parameters.IsNull()) {
    TypeParameter& type_parameter = TypeParameter::Handle();
    const intptr_t num_types = type_parameters.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      type_parameter ^= type_parameters.TypeAt(i);
      type_parameter ^= FinalizeType(cls,
                                     type_parameter,
                                     kCanonicalizeWellFormed);
      type_parameters.SetTypeAt(i, type_parameter);
    }
  }
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
//             class B<T> extends A<int> { ... }
//   Input:    C<String, double> expressed as
//             cls = C, arguments = [null, null, String, double],
//             i.e. cls_args = [String, double], offset = 2, length = 2.
//   Output:   arguments = [int, double, String, double]
void ClassFinalizer::FinalizeTypeArguments(
    const Class& cls,
    const AbstractTypeArguments& arguments,
    FinalizationKind finalization,
    Error* bound_error) {
  ASSERT(arguments.Length() >= cls.NumTypeArguments());
  if (!cls.is_finalized()) {
    FinalizeTypeParameters(cls);
    ResolveUpperBounds(cls);
  }
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    AbstractTypeArguments& super_type_args = AbstractTypeArguments::Handle();
    if (super_type.IsBeingFinalized()) {
      // This type references itself via its type arguments. This is legal, but
      // we must avoid endless recursion. We therefore map the innermost
      // super type to dynamic.
      // Note that a direct self-reference via the super class chain is illegal
      // and reported as an error earlier.
      // Such legal self-references occur with F-bounded quantification.
      // Example 1: class Derived extends Base<Derived>.
      // The type 'Derived' forms a cycle by pointing to itself via its
      // flattened type argument vector: Derived[Base[Derived[Base[...]]]]
      // We break the cycle as follows: Derived[Base[Derived[dynamic]]]
      // Example 2: class Derived extends Base<Middle<Derived>> results in
      // Derived[Base[Middle[Derived[dynamic]]]]
      // Example 3: class Derived<T> extends Base<Derived<T>> results in
      // Derived[Base[Derived[dynamic]], T].
      ASSERT(super_type_args.IsNull());  // Same as a vector of dynamic.
    } else {
      super_type ^= FinalizeType(cls, super_type, finalization);
      cls.set_super_type(super_type);
      super_type_args = super_type.arguments();
    }
    const intptr_t num_super_type_params = super_class.NumTypeParameters();
    const intptr_t offset = super_class.NumTypeArguments();
    const intptr_t super_offset = offset - num_super_type_params;
    ASSERT(offset == (cls.NumTypeArguments() - cls.NumTypeParameters()));
    AbstractType& super_type_arg = AbstractType::Handle(Type::DynamicType());
    for (intptr_t i = 0; i < num_super_type_params; i++) {
      if (!super_type_args.IsNull()) {
        super_type_arg = super_type_args.TypeAt(super_offset + i);
        if (!super_type_arg.IsInstantiated()) {
          Error& malformed_error = Error::Handle();
          super_type_arg = super_type_arg.InstantiateFrom(arguments,
                                                          &malformed_error);
          if (!malformed_error.IsNull()) {
            if (!super_type_arg.IsInstantiated()) {
              // CheckTypeArgumentBounds will insert a BoundedType.
            } else if (bound_error->IsNull()) {
              *bound_error = malformed_error.raw();
            }
          }
        }
        if (finalization >= kCanonicalize) {
          super_type_arg = super_type_arg.Canonicalize();
        }
      }
      arguments.SetTypeAt(super_offset + i, super_type_arg);
    }
    FinalizeTypeArguments(super_class, arguments, finalization, bound_error);
  }
}


// Check the type argument vector 'arguments' against the corresponding bounds
// of the type parameters of class 'cls' and, recursively, of its superclasses.
// Replace a type argument that cannot be checked at compile time by a
// BoundedType, thereby postponing the bound check to run time.
// Return a bound error if a type argument is not within bound at compile time.
void ClassFinalizer::CheckTypeArgumentBounds(
    const Class& cls,
    const AbstractTypeArguments& arguments,
    Error* bound_error) {
  if (!cls.is_finalized()) {
    FinalizeUpperBounds(cls);
  }
  // Note that when finalizing a type, we need to verify the bounds in both
  // production mode and checked mode, because the finalized type may be written
  // to a snapshot. It would be wrong to ignore bounds when generating the
  // snapshot in production mode and then use the unchecked type in checked mode
  // after reading it from the snapshot.
  // However, we do not immediately report a bound error, which would be wrong
  // in production mode, but simply postpone the bound checking to runtime.
  const intptr_t num_type_params = cls.NumTypeParameters();
  const intptr_t offset = cls.NumTypeArguments() - num_type_params;
  AbstractType& type_arg = AbstractType::Handle();
  AbstractType& cls_type_param = AbstractType::Handle();
  AbstractType& declared_bound = AbstractType::Handle();
  AbstractType& instantiated_bound = AbstractType::Handle();
  const TypeArguments& cls_type_params =
      TypeArguments::Handle(cls.type_parameters());
  ASSERT((cls_type_params.IsNull() && (num_type_params == 0)) ||
         (cls_type_params.Length() == num_type_params));
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_arg = arguments.TypeAt(offset + i);
    if (type_arg.IsDynamicType()) {
      continue;
    }
    cls_type_param = cls_type_params.TypeAt(i);
    const TypeParameter& type_param = TypeParameter::Cast(cls_type_param);
    ASSERT(type_param.IsFinalized());
    declared_bound = type_param.bound();
    if (!declared_bound.IsObjectType() && !declared_bound.IsDynamicType()) {
      Error& malformed_error = Error::Handle();
      // Note that the bound may be malformed, in which case the bound check
      // will return an error and the bound check will be postponed to run time.
      // Note also that the bound may still be unfinalized.
      if (declared_bound.IsInstantiated()) {
        instantiated_bound = declared_bound.raw();
      } else {
        instantiated_bound =
            declared_bound.InstantiateFrom(arguments, &malformed_error);
      }
      if (!instantiated_bound.IsFinalized()) {
        // The bound refers to type parameters, creating a cycle; postpone
        // bound check to run time, when the bound will be finalized.
        // The bound may not necessarily be 'IsBeingFinalized' yet, as is the
        // case with a pair of type parameters of the same class referring to
        // each other via their bounds.
        type_arg = BoundedType::New(type_arg, instantiated_bound, type_param);
        arguments.SetTypeAt(offset + i, type_arg);
        continue;
      }
      // TODO(regis): We could simplify this code if we could differentiate
      // between a failed bound check and a bound check that is undecidable at
      // compile time.
      // Shortcut the special case where we check a type parameter against its
      // declared upper bound.
      bool below_bound = true;
      if (malformed_error.IsNull() &&
          (!type_arg.Equals(type_param) ||
           !instantiated_bound.Equals(declared_bound))) {
        // Pass NULL to prevent expensive and unnecessary error formatting in
        // the case the bound check is postponed to run time.
        below_bound = type_param.CheckBound(type_arg, instantiated_bound, NULL);
      }
      if (!malformed_error.IsNull() || !below_bound) {
        if (!type_arg.IsInstantiated() ||
            !instantiated_bound.IsInstantiated()) {
          type_arg = BoundedType::New(type_arg, instantiated_bound, type_param);
          arguments.SetTypeAt(offset + i, type_arg);
        } else if (bound_error->IsNull()) {
          if (malformed_error.IsNull()) {
            // Call CheckBound again to format error message.
            type_param.CheckBound(type_arg,
                                  instantiated_bound,
                                  &malformed_error);
          }
          ASSERT(!malformed_error.IsNull());
          *bound_error = malformed_error.raw();
        }
      }
    }
  }
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    CheckTypeArgumentBounds(super_class, arguments, bound_error);
  }
}


RawAbstractType* ClassFinalizer::FinalizeType(const Class& cls,
                                              const AbstractType& type,
                                              FinalizationKind finalization) {
  if (type.IsFinalized()) {
    // Ensure type is canonical if canonicalization is requested, unless type is
    // malformed.
    if (finalization >= kCanonicalize) {
      if (type.IsMalformed()) {
        if (finalization == kCanonicalizeWellFormed) {
          ReportError(Error::Handle(type.malformed_error()));
        }
      } else {
        return type.Canonicalize();
      }
    }
    return type.raw();
  }
  ASSERT(type.IsResolved());
  ASSERT(finalization >= kFinalize);

  if (FLAG_trace_type_finalization) {
    OS::Print("Finalize type '%s'\n", String::Handle(type.Name()).ToCString());
  }

  if (type.IsTypeParameter()) {
    const TypeParameter& type_parameter = TypeParameter::Cast(type);
    const Class& parameterized_class =
        Class::Handle(type_parameter.parameterized_class());
    ASSERT(!parameterized_class.IsNull());
    // The index must reflect the position of this type parameter in the type
    // arguments vector of its parameterized class. The offset to add is the
    // number of type arguments in the super type, which is equal to the
    // difference in number of type arguments and type parameters of the
    // parameterized class.
    const intptr_t offset = parameterized_class.NumTypeArguments() -
                            parameterized_class.NumTypeParameters();
    type_parameter.set_index(type_parameter.index() + offset);
    type_parameter.set_is_finalized();
    // We do not canonicalize type parameters.
    return type_parameter.raw();
  }

  // At this point, we can only have a parameterized_type.
  const Type& parameterized_type = Type::Cast(type);

  if (parameterized_type.IsBeingFinalized()) {
    // Self reference detected. The type is malformed.
    FinalizeMalformedType(
        Error::Handle(),  // No previous error.
        cls, parameterized_type, finalization,
        "type '%s' illegally refers to itself",
        String::Handle(parameterized_type.UserVisibleName()).ToCString());
    return parameterized_type.raw();
  }

  // Mark type as being finalized in order to detect illegal self reference.
  parameterized_type.set_is_being_finalized();

  // The type class does not need to be finalized in order to finalize the type,
  // however, it must at least be resolved (this was done as part of resolving
  // the type itself, a precondition to calling FinalizeType).
  // Also, the interfaces of the type class must be resolved and the type
  // parameters of the type class must be finalized.
  Class& type_class = Class::Handle(parameterized_type.type_class());
  if (!type_class.is_finalized()) {
    FinalizeTypeParameters(type_class);
    ResolveUpperBounds(type_class);
  }

  // Finalize the current type arguments of the type, which are still the
  // parsed type arguments.
  AbstractTypeArguments& arguments =
      AbstractTypeArguments::Handle(parameterized_type.arguments());
  if (!arguments.IsNull()) {
    intptr_t num_arguments = arguments.Length();
    AbstractType& type_argument = AbstractType::Handle();
    for (intptr_t i = 0; i < num_arguments; i++) {
      type_argument = arguments.TypeAt(i);
      type_argument = FinalizeType(cls, type_argument, finalization);
      if (type_argument.IsMalformed()) {
        // In production mode, malformed type arguments are mapped to dynamic.
        // In checked mode, a type with malformed type arguments is malformed.
        if (FLAG_enable_type_checks || FLAG_error_on_malformed_type) {
          const Error& error = Error::Handle(type_argument.malformed_error());
          const String& type_name =
              String::Handle(parameterized_type.UserVisibleName());
          FinalizeMalformedType(error, cls, parameterized_type, finalization,
                                "type '%s' has malformed type argument",
                                type_name.ToCString());
          return parameterized_type.raw();
        } else {
          type_argument = Type::DynamicType();
        }
      }
      arguments.SetTypeAt(i, type_argument);
    }
  }

  // The finalized type argument vector needs num_type_arguments types.
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  // The type class has num_type_parameters type parameters.
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // Initialize the type argument vector.
  // Check the number of parsed type arguments, if any.
  // Specifying no type arguments indicates a raw type, which is not an error.
  // However, type parameter bounds are checked below, even for a raw type.
  if (!arguments.IsNull() && (arguments.Length() != num_type_parameters)) {
    // Wrong number of type arguments. The type is malformed.
    if (finalization >= kCanonicalizeExpression) {
      const Script& script = Script::Handle(cls.script());
      const String& type_name =
          String::Handle(parameterized_type.UserVisibleName());
      ReportError(script, parameterized_type.token_pos(),
                  "wrong number of type arguments in type '%s'",
                  type_name.ToCString());
    }
    FinalizeMalformedType(
        Error::Handle(),  // No previous error.
        cls, parameterized_type, finalization,
        "wrong number of type arguments in type '%s'",
        String::Handle(parameterized_type.UserVisibleName()).ToCString());
    return parameterized_type.raw();
  }
  // The full type argument vector consists of the type arguments of the
  // super types of type_class, which may be initialized from the parsed
  // type arguments, followed by the parsed type arguments.
  TypeArguments& full_arguments = TypeArguments::Handle();
  Error& bound_error = Error::Handle();
  if (num_type_arguments > 0) {
    // If no type arguments were parsed and if the super types do not prepend
    // type arguments to the vector, we can leave the vector as null.
    if (!arguments.IsNull() || (num_type_arguments > num_type_parameters)) {
      full_arguments = TypeArguments::New(num_type_arguments);
      // Copy the parsed type arguments at the correct offset in the full type
      // argument vector.
      const intptr_t offset = num_type_arguments - num_type_parameters;
      AbstractType& type_arg = AbstractType::Handle(Type::DynamicType());
      for (intptr_t i = 0; i < num_type_parameters; i++) {
        // If no type parameters were provided, a raw type is desired, so we
        // create a vector of DynamicType.
        if (!arguments.IsNull()) {
          type_arg = arguments.TypeAt(i);
        }
        ASSERT(type_arg.IsFinalized());  // Index of type parameter is adjusted.
        full_arguments.SetTypeAt(offset + i, type_arg);
      }
      // If the type class is a signature class, the full argument vector
      // must include the argument vector of the super type.
      // If the signature class is a function type alias, it is also the owner
      // of its signature function and no super type is involved.
      // If the signature class is canonical (not an alias), the owner of its
      // signature function may either be an alias or the enclosing class of a
      // local function, in which case the super type of the enclosing class is
      // also considered when filling up the argument vector.
      if (type_class.IsSignatureClass()) {
        const Function& signature_fun =
            Function::Handle(type_class.signature_function());
        ASSERT(!signature_fun.is_static());
        const Class& sig_fun_owner = Class::Handle(signature_fun.Owner());
        FinalizeTypeArguments(
            sig_fun_owner, full_arguments, finalization, &bound_error);
        CheckTypeArgumentBounds(sig_fun_owner, full_arguments, &bound_error);
      } else {
        FinalizeTypeArguments(
            type_class, full_arguments, finalization, &bound_error);
        CheckTypeArgumentBounds(type_class, full_arguments, &bound_error);
      }
      if (full_arguments.IsRaw(num_type_arguments)) {
        // The parameterized_type is raw. Set its argument vector to null, which
        // is more efficient in type tests.
        full_arguments = TypeArguments::null();
      } else if (finalization >= kCanonicalize) {
        // FinalizeTypeArguments can modify 'full_arguments',
        // canonicalize afterwards.
        full_arguments ^= full_arguments.Canonicalize();
      }
      parameterized_type.set_arguments(full_arguments);
    } else {
      ASSERT(full_arguments.IsNull());  // Use null vector for raw type.
    }
  }

  // Self referencing types may get finalized indirectly.
  if (!parameterized_type.IsFinalized()) {
    // Mark the type as finalized.
    parameterized_type.SetIsFinalized();
  }

  // If the type class is a signature class, we are currently finalizing a
  // signature type, i.e. finalizing the result type and parameter types of the
  // signature function of this signature type.
  // We do this after marking this type as finalized in order to allow a
  // function type to refer to itself via its parameter types and result type.
  if (type_class.IsSignatureClass()) {
    // The class may be created while parsing a function body, after all
    // pending classes have already been finalized.
    FinalizeClass(type_class);
  }

  // If a bound error occurred, return a BoundedType with a malformed bound.
  // The malformed bound will be ignored in production mode.
  if (!bound_error.IsNull()) {
    FinalizationKind bound_finalization = kTryResolve;  // No compile error.
    if (FLAG_enable_type_checks || FLAG_error_on_malformed_type) {
      bound_finalization = finalization;
    }
    const String& parameterized_type_name = String::Handle(
        parameterized_type.UserVisibleName());
    const Type& malformed_bound = Type::Handle(
        NewFinalizedMalformedType(bound_error,
                                  cls,
                                  parameterized_type.token_pos(),
                                  bound_finalization,
                                  "type '%s' has an out of bound type argument",
                                  parameterized_type_name.ToCString()));
    return BoundedType::New(parameterized_type,
                            malformed_bound,
                            TypeParameter::Handle());
  }

  if (finalization >= kCanonicalize) {
    return parameterized_type.Canonicalize();
  } else {
    return parameterized_type.raw();
  }
}


void ClassFinalizer::ResolveAndFinalizeSignature(const Class& cls,
                                                 const Function& function) {
  // Resolve result type.
  AbstractType& type = AbstractType::Handle(function.result_type());
  // It is not a compile time error if this name does not resolve to a class or
  // interface.
  ResolveType(cls, type, kCanonicalize);
  type = FinalizeType(cls, type, kCanonicalize);
  // In production mode, a malformed result type is mapped to dynamic.
  if (!FLAG_enable_type_checks && type.IsMalformed()) {
    type = Type::DynamicType();
  }
  function.set_result_type(type);
  // Resolve formal parameter types.
  const intptr_t num_parameters = function.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    ResolveType(cls, type, kCanonicalize);
    type = FinalizeType(cls, type, kCanonicalize);
    // In production mode, a malformed parameter type is mapped to dynamic.
    if (!FLAG_enable_type_checks && type.IsMalformed()) {
      type = Type::DynamicType();
    }
    function.SetParameterTypeAt(i, type);
  }
}


// Check if an instance field or method of same name exists
// in any super class.
static RawClass* FindSuperOwnerOfInstanceMember(const Class& cls,
                                                const String& name) {
  Class& super_class = Class::Handle();
  Function& function = Function::Handle();
  Field& field = Field::Handle();
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
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


// Check if an instance method of same name exists in any super class.
static RawClass* FindSuperOwnerOfFunction(const Class& cls,
                                          const String& name) {
  Class& super_class = Class::Handle();
  Function& function = Function::Handle();
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
    function = super_class.LookupFunction(name);
    if (!function.IsNull() &&
        !function.is_static() &&
        !function.IsMethodExtractor()) {
      return super_class.raw();
    }
    super_class = super_class.SuperClass();
  }
  return Class::null();
}


// Resolve the upper bounds of the type parameters of class cls.
void ClassFinalizer::ResolveUpperBounds(const Class& cls) {
  const intptr_t num_type_params = cls.NumTypeParameters();
  TypeParameter& type_param = TypeParameter::Handle();
  AbstractType& bound = AbstractType::Handle();
  const AbstractTypeArguments& type_params =
      AbstractTypeArguments::Handle(cls.type_parameters());
  ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
         (type_params.Length() == num_type_params));
  // In a first pass, resolve all bounds. This guarantees that finalization
  // of mutually referencing bounds will not encounter an unresolved bound.
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    bound = type_param.bound();
    ResolveType(cls, bound, kCanonicalize);
  }
}


// Finalize the upper bounds of the type parameters of class cls.
void ClassFinalizer::FinalizeUpperBounds(const Class& cls) {
  const intptr_t num_type_params = cls.NumTypeParameters();
  TypeParameter& type_param = TypeParameter::Handle();
  AbstractType& bound = AbstractType::Handle();
  const AbstractTypeArguments& type_params =
      AbstractTypeArguments::Handle(cls.type_parameters());
  ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
         (type_params.Length() == num_type_params));
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    bound = type_param.bound();
    if (bound.IsFinalized() || bound.IsBeingFinalized()) {
      // A bound involved in F-bounded quantification may form a cycle.
      continue;
    }
    bound = FinalizeType(cls, bound, kCanonicalize);
    type_param.set_bound(bound);
  }
}


void ClassFinalizer::ResolveAndFinalizeMemberTypes(const Class& cls) {
  // Note that getters and setters are explicitly listed as such in the list of
  // functions of a class, so we do not need to consider fields as implicitly
  // generating getters and setters.
  // The only compile errors we report are therefore:
  // - a getter having the same name as a method (but not a getter) in a super
  //   class or in a subclass.
  // - a static field, instance field, or static method (but not an instance
  //   method) having the same name as an instance member in a super class.

  // Resolve type of fields and check for conflicts in super classes.
  Array& array = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  AbstractType& type = AbstractType::Handle();
  String& name = String::Handle();
  Class& super_class = Class::Handle();
  intptr_t num_fields = array.Length();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    ResolveType(cls, type, kCanonicalize);
    type = FinalizeType(cls, type, kCanonicalize);
    field.set_type(type);
    name = field.name();
    if (field.is_static()) {
      super_class = FindSuperOwnerOfInstanceMember(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        const Script& script = Script::Handle(cls.script());
        ReportError(script, field.token_pos(),
                    "static field '%s' of class '%s' conflicts with "
                    "instance member '%s' of super class '%s'",
                    name.ToCString(),
                    class_name.ToCString(),
                    name.ToCString(),
                    super_class_name.ToCString());
      }
    } else {
      // Instance field. Check whether the field overrides a method
      // (but not getter).
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        const Script& script = Script::Handle(cls.script());
        ReportError(script, field.token_pos(),
                    "field '%s' of class '%s' conflicts with method '%s' "
                    "of super class '%s'",
                    name.ToCString(),
                    class_name.ToCString(),
                    name.ToCString(),
                    super_class_name.ToCString());
      }
    }
  }
  // Collect interfaces, super interfaces, and super classes of this class.
  const GrowableObjectArray& interfaces =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  CollectInterfaces(cls, interfaces);
  // Include superclasses in list of interfaces and super interfaces.
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
    interfaces.Add(super_class);
    CollectInterfaces(super_class, interfaces);
    super_class = super_class.SuperClass();
  }
  // Resolve function signatures and check for conflicts in super classes and
  // interfaces.
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
        const Script& script = Script::Handle(cls.script());
        ReportError(script, function.token_pos(),
                    "static function '%s' of class '%s' conflicts with "
                    "instance member '%s' of super class '%s'",
                    function_name.ToCString(),
                    class_name.ToCString(),
                    function_name.ToCString(),
                    super_class_name.ToCString());
      }
      if (function.IsRedirectingFactory()) {
        const GrowableObjectArray& redirecting_factories =
            GrowableObjectArray::Handle(GrowableObjectArray::New());
        ResolveRedirectingFactoryTarget(cls, function, redirecting_factories);
      }
    } else {
      for (int i = 0; i < interfaces.Length(); i++) {
        super_class ^= interfaces.At(i);
        overridden_function = super_class.LookupDynamicFunction(function_name);
        if (!overridden_function.IsNull() &&
            !function.HasCompatibleParametersWith(overridden_function)) {
          // Function types are purposely not checked for subtyping.
          const String& class_name = String::Handle(cls.Name());
          const String& super_class_name = String::Handle(super_class.Name());
          const Script& script = Script::Handle(cls.script());
          ReportError(script, function.token_pos(),
                      "class '%s' overrides function '%s' of super class '%s' "
                      "with incompatible parameters",
                      class_name.ToCString(),
                      function_name.ToCString(),
                      super_class_name.ToCString());
        }
      }
    }
    if (function.IsGetterFunction()) {
      name = Field::NameFromGetter(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        const Script& script = Script::Handle(cls.script());
        ReportError(script, function.token_pos(),
                    "getter '%s' of class '%s' conflicts with "
                    "function '%s' of super class '%s'",
                    name.ToCString(),
                    class_name.ToCString(),
                    name.ToCString(),
                    super_class_name.ToCString());
      }
    } else if (!function.IsSetterFunction()) {
      // A function cannot conflict with a setter, since they cannot
      // have the same name. Thus, we do not need to check setters.
      name = Field::GetterName(function_name);
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(cls.Name());
        const String& super_class_name = String::Handle(super_class.Name());
        const Script& script = Script::Handle(cls.script());
        ReportError(script, function.token_pos(),
                    "function '%s' of class '%s' conflicts with "
                    "getter '%s' of super class '%s'",
                    function_name.ToCString(),
                    class_name.ToCString(),
                    function_name.ToCString(),
                    super_class_name.ToCString());
      }
    }
  }
}


// Copy the type parameters of the super and mixin classes to the
// mixin application class. Change type arguments of super type to
// refer to the respective type parameters of the mixin application
// class.
void ClassFinalizer::CloneTypeParameters(const Class& mixapp_class) {
  ASSERT(mixapp_class.NumTypeParameters() == 0);

  const AbstractType& super_type =
      AbstractType::Handle(mixapp_class.super_type());
  ASSERT(super_type.IsResolved());
  const Class& super_class = Class::Handle(super_type.type_class());
  const Type& mixin_type = Type::Handle(mixapp_class.mixin());
  const Class& mixin_class = Class::Handle(mixin_type.type_class());
  const int num_super_parameters = super_class.NumTypeParameters();
  const int num_mixin_parameters = mixin_class.NumTypeParameters();
  if ((num_super_parameters + num_mixin_parameters) == 0) {
    return;
  }

  // First, clone the super class type parameters. Rename them so that
  // there can be no name conflict between the parameters of the super
  // class and the mixin class.
  const TypeArguments& cloned_type_params = TypeArguments::Handle(
      TypeArguments::New(num_super_parameters + num_mixin_parameters));
  TypeParameter& param = TypeParameter::Handle();
  TypeParameter& cloned_param = TypeParameter::Handle();
  String& param_name = String::Handle();
  AbstractType& param_bound = AbstractType::Handle();
  int cloned_index = 0;
  if (num_super_parameters > 0) {
    const TypeArguments& super_params =
        TypeArguments::Handle(super_class.type_parameters());
    const TypeArguments& super_type_args =
        TypeArguments::Handle(TypeArguments::New(num_super_parameters));
    for (int i = 0; i < num_super_parameters; i++) {
      param ^= super_params.TypeAt(i);
      param_name = param.name();
      param_bound = param.bound();
      // TODO(hausner): handle type bounds.
      if (!param_bound.IsObjectType()) {
        const Script& script = Script::Handle(mixapp_class.script());
        ReportError(script, param.token_pos(),
                    "type parameter '%s': type bounds not yet"
                    " implemented for mixins\n",
                    param_name.ToCString());
      }
      param_name = String::Concat(param_name, Symbols::Backtick());
      param_name = Symbols::New(param_name);
      cloned_param = TypeParameter::New(mixapp_class,
                                        cloned_index,
                                        param_name,
                                        param_bound,
                                        param.token_pos());
      cloned_type_params.SetTypeAt(cloned_index, cloned_param);
      // Change the type arguments of the super type to refer to the
      // cloned type parameters of the mixin application class.
      super_type_args.SetTypeAt(cloned_index, cloned_param);
      cloned_index++;
    }
    // TODO(hausner): May need to handle BoundedType here.
    ASSERT(super_type.IsType());
    Type::Cast(super_type).set_arguments(super_type_args);
  }

  // Second, clone the type parameters of the mixin class.
  // We need to retain the parameter names of the mixin class
  // since the code that will be compiled in the context of the
  // mixin application class may refer to the type parameters
  // with that name.
  if (num_mixin_parameters > 0) {
    const TypeArguments& mixin_params =
        TypeArguments::Handle(mixin_class.type_parameters());
    for (int i = 0; i < num_mixin_parameters; i++) {
      param ^= mixin_params.TypeAt(i);
      param_name = param.name();
      param_bound = param.bound();

      // TODO(hausner): handle type bounds.
      if (!param_bound.IsObjectType()) {
        const Script& script = Script::Handle(mixapp_class.script());
        ReportError(script, param.token_pos(),
                    "type parameter '%s': type bounds not yet"
                    " implemented for mixins\n",
                    param_name.ToCString());
      }
      cloned_param = TypeParameter::New(mixapp_class,
                                        cloned_index,
                                        param_name,
                                        param_bound,
                                        param.token_pos());
      cloned_type_params.SetTypeAt(cloned_index, cloned_param);
      cloned_index++;
    }
  }
  mixapp_class.set_type_parameters(cloned_type_params);
}


void ClassFinalizer::ApplyMixin(const Class& cls) {
  const Type& mixin_type = Type::Handle(cls.mixin());
  ASSERT(!mixin_type.IsNull());
  ASSERT(mixin_type.HasResolvedTypeClass());
  const Class& mixin_cls = Class::Handle(mixin_type.type_class());

  if (FLAG_trace_class_finalization) {
    OS::Print("Applying mixin '%s' to '%s' at pos %"Pd"\n",
              String::Handle(mixin_cls.Name()).ToCString(),
              cls.ToCString(),
              cls.token_pos());
  }

  // Check that the super class of the mixin class is extending
  // class Object.
  const AbstractType& mixin_super_type =
      AbstractType::Handle(mixin_cls.super_type());
  if (!mixin_super_type.IsObjectType()) {
    const Script& script = Script::Handle(cls.script());
    const String& class_name = String::Handle(mixin_cls.Name());
    ReportError(script, cls.token_pos(),
                "mixin class %s must extend class Object",
                class_name.ToCString());
  }

  // Copy type parameters to mixin application class.
  CloneTypeParameters(cls);

  const GrowableObjectArray& cloned_funcs =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  Array& functions = Array::Handle();
  Function& func = Function::Handle();
  // The parser creates the mixin application class and adds just
  // one function, the implicit constructor.
  functions = cls.functions();
  ASSERT(functions.Length() == 1);
  func ^= functions.At(0);
  ASSERT(func.IsImplicitConstructor());
  cloned_funcs.Add(func);
  // Now clone the functions from the mixin class.
  functions = mixin_cls.functions();
  const intptr_t num_functions = functions.Length();
  for (int i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.IsConstructor()) {
      // A mixin class must not have explicit constructors.
      if (!func.IsImplicitConstructor()) {
        const Script& script = Script::Handle(cls.script());
        ReportError(script, cls.token_pos(),
                    "mixin class %s must not have constructors\n",
                    String::Handle(mixin_cls.Name()).ToCString());
      }
      continue;  // Skip the implicit constructor.
    }
    if (!func.is_static()) {
      func = func.Clone(cls);
      cloned_funcs.Add(func);
    }
  }
  functions = Array::MakeArray(cloned_funcs);
  cls.SetFunctions(functions);

  // Now clone the fields from the mixin class. There should be no
  // existing fields in the mixin application class.
  ASSERT(Array::Handle(cls.fields()).Length() == 0);
  Array& fields = Array::Handle(mixin_cls.fields());
  Field& field = Field::Handle();
  const GrowableObjectArray& cloned_fields =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const intptr_t num_fields = fields.Length();
  for (int i = 0; i < num_fields; i++) {
    field ^= fields.At(i);
    if (!field.is_static()) {
      field = field.Clone(cls);
      cloned_fields.Add(field);
    }
  }
  fields = Array::MakeArray(cloned_fields);
  cls.SetFields(fields);

  if (FLAG_trace_class_finalization) {
    OS::Print("done mixin appl %s %s extending %s\n",
              String::Handle(cls.Name()).ToCString(),
              TypeArguments::Handle(cls.type_parameters()).ToCString(),
              AbstractType::Handle(cls.super_type()).ToCString());
  }
}


void ClassFinalizer::FinalizeClass(const Class& cls) {
  HANDLESCOPE(Isolate::Current());
  if (cls.is_finalized()) {
    return;
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("Finalize %s\n", cls.ToCString());
  }
  if (!IsSuperCycleFree(cls)) {
    const String& name = String::Handle(cls.Name());
    const Script& script = Script::Handle(cls.script());
    ReportError(script, cls.token_pos(),
                "class '%s' has a cycle in its superclass relationship",
                name.ToCString());
  }
  // Finalize super class.
  const Class& super_class = Class::Handle(cls.SuperClass());
  if (!super_class.IsNull()) {
    FinalizeClass(super_class);
  }
  if (cls.mixin() != Type::null()) {
    // Copy instance methods and fields from the mixin class.
    // This has to happen before the check whether the methods of
    // the class conflict with inherited methods.
    ApplyMixin(cls);
  }
  // Finalize type parameters before finalizing the super type.
  FinalizeTypeParameters(cls);
  ResolveUpperBounds(cls);
  // Finalize super type.
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    // In case of a bound error in the super type in production mode, the
    // finalized super type will be a BoundedType with a malformed bound.
    // It should not be a problem if the class is written to a snapshot and
    // later executed in checked mode. Note that the finalized type argument
    // vector of any type of the base class will contain a BoundedType for the
    // out of bound type argument.
    super_type = FinalizeType(cls, super_type, kCanonicalizeWellFormed);
    cls.set_super_type(super_type);
  }
  if (cls.IsSignatureClass()) {
    // Check for illegal self references.
    GrowableArray<intptr_t> visited_aliases;
    if (!IsAliasCycleFree(cls, &visited_aliases)) {
      const String& name = String::Handle(cls.Name());
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "typedef '%s' illegally refers to itself",
                  name.ToCString());
    }
    cls.Finalize();
    // Signature classes extend Object. No need to add this class to the direct
    // subclasses of Object.
    ASSERT(super_type.IsNull() || super_type.IsObjectType());

    // The type parameters of signature classes may have bounds.
    FinalizeUpperBounds(cls);

    // Resolve and finalize the result and parameter types of the signature
    // function of this signature class.
    const Function& sig_function = Function::Handle(cls.signature_function());
    ResolveAndFinalizeSignature(cls, sig_function);

    // Resolve and finalize the signature type of this signature class.
    const Type& sig_type = Type::Handle(cls.SignatureType());
    FinalizeType(cls, sig_type, kCanonicalizeWellFormed);
    return;
  }
  // Finalize interface types (but not necessarily interface classes).
  Array& interface_types = Array::Handle(cls.interfaces());
  AbstractType& interface_type = AbstractType::Handle();
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    interface_type = FinalizeType(cls, interface_type, kCanonicalizeWellFormed);
    interface_types.SetAt(i, interface_type);

    // Check whether the interface is duplicated. We need to wait with
    // this check until the super type and interface types are finalized,
    // so that we can use Type::Equals() for the test.
    ASSERT(interface_type.IsFinalized());
    ASSERT(super_type.IsFinalized());
    if (interface_type.Equals(super_type)) {
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "super type '%s' may not be listed in "
                  "implements clause of class '%s'",
                  String::Handle(super_type.Name()).ToCString(),
                  String::Handle(cls.Name()).ToCString());
    }
    AbstractType& seen_interf = AbstractType::Handle();
    for (intptr_t j = 0; j < i; j++) {
      seen_interf ^= interface_types.At(j);
      if (interface_type.Equals(seen_interf)) {
        const Script& script = Script::Handle(cls.script());
        ReportError(script, cls.token_pos(),
                    "interface '%s' appears twice in "
                    "implements clause of class '%s'",
                    String::Handle(interface_type.Name()).ToCString(),
                    String::Handle(cls.Name()).ToCString());
      }
    }
  }
  // Mark as finalized before resolving type parameter upper bounds and member
  // types in order to break cycles.
  cls.Finalize();
  // Finalize bounds even if running in production mode, so that a snapshot
  // contains them.
  FinalizeUpperBounds(cls);
  ResolveAndFinalizeMemberTypes(cls);
  // Run additional checks after all types are finalized.
  if (cls.is_const()) {
    CheckForLegalConstClass(cls);
  }
  // Add this class to the direct subclasses of the superclass, unless the
  // superclass is Object.
  if (!super_type.IsNull() && !super_type.IsObjectType()) {
    ASSERT(!super_class.IsNull());
    super_class.AddDirectSubclass(cls);
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


// Returns false if the function type alias illegally refers to itself.
bool ClassFinalizer::IsAliasCycleFree(const Class& cls,
                                      GrowableArray<intptr_t>* visited) {
  ASSERT(cls.IsSignatureClass());
  ASSERT(!cls.is_finalized());
  ASSERT(visited != NULL);
  const intptr_t cls_index = cls.id();
  for (int i = 0; i < visited->length(); i++) {
    if ((*visited)[i] == cls_index) {
      // We have already visited alias 'cls'. We found a cycle.
      return false;
    }
  }

  // Visit the result type and parameter types of this signature type.
  visited->Add(cls.id());
  const Function& function = Function::Handle(cls.signature_function());
  // Check class of result type.
  AbstractType& type = AbstractType::Handle(function.result_type());
  ResolveType(cls, type, kCanonicalize);
  if (type.IsType() && !type.IsMalformed()) {
    const Class& type_class = Class::Handle(type.type_class());
    if (!type_class.is_finalized() &&
        type_class.IsSignatureClass() &&
        !IsAliasCycleFree(type_class, visited)) {
      return false;
    }
  }
  // Check classes of formal parameter types.
  const intptr_t num_parameters = function.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    ResolveType(cls, type, kCanonicalize);
    if (type.IsType() && !type.IsMalformed()) {
      const Class& type_class = Class::Handle(type.type_class());
      if (!type_class.is_finalized() &&
          type_class.IsSignatureClass() &&
          !IsAliasCycleFree(type_class, visited)) {
        return false;
      }
    }
  }
  visited->RemoveLast();
  return true;
}


void ClassFinalizer::CollectTypeArguments(const Class& cls,
                              const Type& type,
                              const GrowableObjectArray& collected_args) {
  ASSERT(type.HasResolvedTypeClass());
  Class& type_class = Class::Handle(type.type_class());
  AbstractTypeArguments& type_args =
      AbstractTypeArguments::Handle(type.arguments());
  intptr_t num_type_parameters = type_class.NumTypeParameters();
  intptr_t num_type_arguments = type_args.IsNull() ? 0 : type_args.Length();
  AbstractType& arg = AbstractType::Handle();
  if (num_type_arguments > 0) {
    if (num_type_arguments != num_type_parameters) {
      const Script& script = Script::Handle(cls.script());
      const String& type_class_name = String::Handle(type_class.Name());
      ReportError(script, type.token_pos(),
          "wrong number of type arguments for class '%s'",
          type_class_name.ToCString());
    }
    for (int i = 0; i < num_type_arguments; i++) {
      arg = type_args.TypeAt(i);
      collected_args.Add(arg);
    }
  } else {
    // Fill arguments with type dynamic.
    for (int i = 0; i < num_type_parameters; i++) {
      arg = Type::DynamicType();
      collected_args.Add(arg);
    }
  }
}


RawType* ClassFinalizer::ResolveMixinAppType(const Class& cls,
                                             const MixinAppType& mixin_app) {
  // Resolve super type and all mixin types.
  const GrowableObjectArray& type_args =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  AbstractType& type = AbstractType::Handle(mixin_app.super_type());
  ResolveType(cls, type, kCanonicalizeWellFormed);
  ASSERT(type.HasResolvedTypeClass());
  // TODO(hausner): May need to handle BoundedType here.
  ASSERT(type.IsType());
  CollectTypeArguments(cls, Type::Cast(type), type_args);
  const Array& mixins = Array::Handle(mixin_app.mixin_types());
  for (int i = 0; i < mixins.Length(); i++) {
    type ^= mixins.At(i);
    ASSERT(type.HasResolvedTypeClass());  // Newly created class in parser.
    const Class& mixin_app_class = Class::Handle(type.type_class());
    type = mixin_app_class.mixin();
    ASSERT(!type.IsNull());
    ResolveType(cls, type, kCanonicalizeWellFormed);
    ASSERT(type.HasResolvedTypeClass());
    ASSERT(type.IsType());
    CollectTypeArguments(cls, Type::Cast(type), type_args);
  }
  const TypeArguments& mixin_app_args =
    TypeArguments::Handle(TypeArguments::New(type_args.Length()));
  for (int i = 0; i < type_args.Length(); i++) {
    type ^= type_args.At(i);
    mixin_app_args.SetTypeAt(i, type);
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("ResolveMixinAppType: mixin appl type args: %s\n",
              mixin_app_args.ToCString());
  }
  // The last element in the mixins array is the lowest mixin application
  // type in the mixin chain. Build a new super type with its type class
  // and the collected type arguments from the super type and all
  // mixin types. This super type replaces the MixinAppType object
  // in the class that extends the mixin application.
  type ^= mixins.At(mixins.Length() - 1);
  const Class& resolved_mixin_app_class = Class::Handle(type.type_class());
  Type& resolved_mixin_app_type = Type::Handle();
  resolved_mixin_app_type = Type::New(resolved_mixin_app_class,
                                      mixin_app_args,
                                      mixin_app.token_pos());
  return resolved_mixin_app_type.raw();
}


// Recursively walks the graph of explicitly declared super type and
// interfaces, resolving unresolved super types and interfaces.
// Reports an error if there is an interface reference that cannot be
// resolved, or if there is a cycle in the graph. We detect cycles by
// remembering interfaces we've visited in each path through the
// graph. If we visit an interface a second time on a given path,
// we found a loop.
void ClassFinalizer::ResolveSuperTypeAndInterfaces(
    const Class& cls, GrowableArray<intptr_t>* visited) {
  ASSERT(visited != NULL);
  const intptr_t cls_index = cls.id();
  for (int i = 0; i < visited->length(); i++) {
    if ((*visited)[i] == cls_index) {
      // We have already visited class 'cls'. We found a cycle.
      const String& class_name = String::Handle(cls.Name());
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "cyclic reference found for class '%s'",
                  class_name.ToCString());
    }
  }

  // If the class/interface has no explicit super class/interfaces
  // and is not a mixin application, we are done.
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  Array& super_interfaces = Array::Handle(cls.interfaces());
  if ((super_type.IsNull() || super_type.IsObjectType()) &&
      (super_interfaces.Length() == 0)) {
    return;
  }

  if (super_type.IsMixinAppType()) {
    const MixinAppType& mixin_app_type = MixinAppType::Cast(super_type);
    super_type = ResolveMixinAppType(cls, mixin_app_type);
    cls.set_super_type(super_type);
  }

  // If cls belongs to core lib, restrictions about allowed interfaces
  // are lifted.
  const bool cls_belongs_to_core_lib = cls.library() == Library::CoreLibrary();

  // Resolve and check the super type and interfaces of cls.
  visited->Add(cls_index);
  AbstractType& interface = AbstractType::Handle();
  Class& interface_class = Class::Handle();

  // Resolve super type. Failures lead to a longjmp.
  ResolveType(cls, super_type, kCanonicalizeWellFormed);

  interface_class = super_type.type_class();
  // If cls belongs to core lib or to core lib's implementation, restrictions
  // about allowed interfaces are lifted.
  if (!cls_belongs_to_core_lib) {
    // Prevent extending core implementation classes.
    bool is_error = false;
    switch (interface_class.id()) {
      case kNumberCid:
      case kIntegerCid:  // Class Integer, not int.
      case kSmiCid:
      case kMintCid:
      case kBigintCid:
      case kDoubleCid:  // Class Double, not double.
      case kOneByteStringCid:
      case kTwoByteStringCid:
      case kExternalOneByteStringCid:
      case kExternalTwoByteStringCid:
      case kBoolCid:
      case kArrayCid:
      case kImmutableArrayCid:
      case kGrowableObjectArrayCid:
#define DO_NOT_EXTEND_TYPED_DATA_CLASSES(clazz)                                \
      case kTypedData##clazz##Cid:                                             \
      case kTypedData##clazz##ViewCid:                                         \
      case kExternalTypedData##clazz##Cid:
      CLASS_LIST_TYPED_DATA(DO_NOT_EXTEND_TYPED_DATA_CLASSES)
#undef DO_NOT_EXTEND_TYPED_DATA_CLASSES
      case kByteDataViewCid:
      case kDartFunctionCid:
      case kWeakPropertyCid:
        is_error = true;
        break;
      default: {
        // Special case: classes for which we don't have a known class id.
        if (super_type.IsDoubleType() ||
            super_type.IsIntType() ||
            super_type.IsStringType()) {
          is_error = true;
        }
        break;
      }
    }
    if (is_error) {
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "'%s' is not allowed to extend '%s'",
                  String::Handle(cls.Name()).ToCString(),
                  String::Handle(interface_class.Name()).ToCString());
    }
  }
  // Now resolve the super interfaces of the super type.
  ResolveSuperTypeAndInterfaces(interface_class, visited);

  // Resolve interfaces. Failures lead to a longjmp.
  for (intptr_t i = 0; i < super_interfaces.Length(); i++) {
    interface ^= super_interfaces.At(i);
    ResolveType(cls, interface, kCanonicalizeWellFormed);
    if (interface.IsTypeParameter()) {
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "type parameter '%s' cannot be used as interface",
                  String::Handle(interface.Name()).ToCString());
    }
    interface_class = interface.type_class();
    if (interface_class.IsSignatureClass()) {
      const Script& script = Script::Handle(cls.script());
      ReportError(script, cls.token_pos(),
                  "'%s' is used where an interface or class name is expected",
                  String::Handle(interface_class.Name()).ToCString());
    }
    // Verify that unless cls belongs to core lib, it cannot extend or implement
    // any of bool, num, int, double, String, Function, dynamic.
    // The exception is signature classes, which are compiler generated and
    // represent a function type, therefore implementing the Function interface.
    if (!cls_belongs_to_core_lib) {
      if (interface.IsBoolType() ||
          interface.IsNumberType() ||
          interface.IsIntType() ||
          interface.IsDoubleType() ||
          interface.IsStringType() ||
          (interface.IsFunctionType() && !cls.IsSignatureClass()) ||
          interface.IsDynamicType()) {
        const Script& script = Script::Handle(cls.script());
        ReportError(script, cls.token_pos(),
                    "'%s' is not allowed to extend or implement '%s'",
                    String::Handle(cls.Name()).ToCString(),
                    String::Handle(interface_class.Name()).ToCString());
      }
    }
    interface_class.set_is_implemented();
    // Now resolve the super interfaces.
    ResolveSuperTypeAndInterfaces(interface_class, visited);
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
    const Script& script = Script::Handle(cls.script());
    ReportError(script, cls.token_pos(),
                "superclass '%s' must be const", name.ToCString());
  }
  const Array& fields_array = Array::Handle(cls.fields());
  intptr_t len = fields_array.Length();
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    if (!field.is_static() && !field.is_final()) {
      const String& class_name = String::Handle(cls.Name());
      const String& field_name = String::Handle(field.name());
      const Script& script = Script::Handle(cls.script());
      ReportError(script, field.token_pos(),
                  "const class '%s' has non-final field '%s'",
                  class_name.ToCString(), field_name.ToCString());
    }
  }
}


void ClassFinalizer::PrintClassInformation(const Class& cls) {
  HANDLESCOPE(Isolate::Current());
  const String& class_name = String::Handle(cls.Name());
  OS::Print("class '%s'", class_name.ToCString());
  const Library& library = Library::Handle(cls.library());
  if (!library.IsNull()) {
    OS::Print(" library '%s%s':\n",
              String::Handle(library.url()).ToCString(),
              String::Handle(library.private_key()).ToCString());
  } else {
    OS::Print(" (null library):\n");
  }
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (super_type.IsNull()) {
    OS::Print("  Super: NULL");
  } else {
    const String& super_name = String::Handle(super_type.Name());
    OS::Print("  Super: %s", super_name.ToCString());
  }
  const Array& interfaces_array = Array::Handle(cls.interfaces());
  if (interfaces_array.Length() > 0) {
    OS::Print("; interfaces: ");
    AbstractType& interface = AbstractType::Handle();
    intptr_t len = interfaces_array.Length();
    for (intptr_t i = 0; i < len; i++) {
      interface ^= interfaces_array.At(i);
      OS::Print("  %s ", interface.ToCString());
    }
  }
  OS::Print("\n");
  const Array& functions_array = Array::Handle(cls.functions());
  Function& function = Function::Handle();
  intptr_t len = functions_array.Length();
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

// Either report an error or mark the type as malformed.
void ClassFinalizer::ReportMalformedType(const Error& prev_error,
                                         const Class& cls,
                                         const Type& type,
                                         FinalizationKind finalization,
                                         const char* format,
                                         va_list args) {
  LanguageError& error = LanguageError::Handle();
  if (FLAG_enable_type_checks ||
      !type.HasResolvedTypeClass() ||
      (finalization == kCanonicalizeWellFormed) ||
      FLAG_error_on_malformed_type) {
    const Script& script = Script::Handle(cls.script());
    if (prev_error.IsNull()) {
      error ^= Parser::FormatError(
          script, type.token_pos(), "Error", format, args);
    } else {
      error ^= Parser::FormatErrorWithAppend(
          prev_error, script, type.token_pos(), "Error", format, args);
    }
    if ((finalization == kCanonicalizeWellFormed) ||
        FLAG_error_on_malformed_type) {
      ReportError(error);
    }
  }
  // In checked mode, always mark the type as malformed.
  // In production mode, mark the type as malformed only if its type class is
  // not resolved.
  // In both mode, make the type raw, since it may not be possible to
  // properly finalize its type arguments.
  if (FLAG_enable_type_checks || !type.HasResolvedTypeClass()) {
    type.set_malformed_error(error);
  }
  type.set_arguments(AbstractTypeArguments::Handle());
  if (!type.IsFinalized()) {
    type.SetIsFinalized();
    // Do not canonicalize malformed types, since they may not be resolved.
  } else {
    // The only case where the malformed type was already finalized is when its
    // type arguments are not within bounds. In that case, we have a prev_error.
    ASSERT(!prev_error.IsNull());
  }
}


RawType* ClassFinalizer::NewFinalizedMalformedType(
    const Error& prev_error,
    const Class& cls,
    intptr_t type_pos,
    FinalizationKind finalization,
    const char* format, ...) {
  va_list args;
  va_start(args, format);
  const UnresolvedClass& unresolved_class = UnresolvedClass::Handle(
      UnresolvedClass::New(LibraryPrefix::Handle(),
                           Symbols::Empty(),
                           type_pos));
  const Type& type = Type::Handle(
      Type::New(unresolved_class, TypeArguments::Handle(), type_pos));
  ReportMalformedType(prev_error, cls, type, finalization, format, args);
  va_end(args);
  ASSERT(type.IsMalformed());
  ASSERT(type.IsFinalized());
  return type.raw();
}


void ClassFinalizer::FinalizeMalformedType(const Error& prev_error,
                                           const Class& cls,
                                           const Type& type,
                                           FinalizationKind finalization,
                                           const char* format, ...) {
  va_list args;
  va_start(args, format);
  ReportMalformedType(prev_error, cls, type, finalization, format, args);
  va_end(args);
}


void ClassFinalizer::ReportError(const Error& error) {
  Isolate::Current()->long_jump_base()->Jump(1, error);
  UNREACHABLE();
}


void ClassFinalizer::ReportError(const Script& script,
                                 intptr_t token_pos,
                                 const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      Parser::FormatError(script, token_pos, "Error", format, args));
  va_end(args);
  ReportError(error);
}


void ClassFinalizer::ReportError(const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Error& error = Error::Handle(
      Parser::FormatError(Script::Handle(), -1, "Error", format, args));
  va_end(args);
  ReportError(error);
}


void ClassFinalizer::VerifyImplicitFieldOffsets() {
#ifdef DEBUG
  const ClassTable& class_table = *(Isolate::Current()->class_table());
  Class& cls = Class::Handle();
  Array& fields_array = Array::Handle();
  Field& field = Field::Handle();
  String& name = String::Handle();
  String& expected_name = String::Handle();

  // First verify field offsets of all the TypedDataView classes.
  for (intptr_t cid = kTypedDataInt8ArrayViewCid;
       cid <= kTypedDataFloat32x4ArrayViewCid;
       cid++) {
    cls = class_table.At(cid);  // Get the TypedDataView class.
    cls = cls.SuperClass();  // Get it's super class '_TypedListView'.
    fields_array ^= cls.fields();
    ASSERT(fields_array.Length() == TypedDataView::NumberOfFields());
    field ^= fields_array.At(0);
    ASSERT(field.Offset() == TypedDataView::data_offset());
    name ^= field.name();
    expected_name ^= String::New("_typeddata");
    ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));
    field ^= fields_array.At(1);
    ASSERT(field.Offset() == TypedDataView::offset_in_bytes_offset());
    name ^= field.name();
    ASSERT(name.Equals("offsetInBytes"));
    field ^= fields_array.At(2);
    ASSERT(field.Offset() == TypedDataView::length_offset());
    name ^= field.name();
    ASSERT(name.Equals("length"));
  }

  // Now verify field offsets of '_ByteDataView' class.
  cls = class_table.At(kByteDataViewCid);
  fields_array ^= cls.fields();
  ASSERT(fields_array.Length() == TypedDataView::NumberOfFields());
  field ^= fields_array.At(0);
  ASSERT(field.Offset() == TypedDataView::data_offset());
  name ^= field.name();
  expected_name ^= String::New("_typeddata");
  ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));
  field ^= fields_array.At(1);
  ASSERT(field.Offset() == TypedDataView::offset_in_bytes_offset());
  name ^= field.name();
  expected_name ^= String::New("_offset");
  ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));
  field ^= fields_array.At(2);
  ASSERT(field.Offset() == TypedDataView::length_offset());
  name ^= field.name();
  ASSERT(name.Equals("length"));
#endif
}

}  // namespace dart
