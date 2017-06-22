// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/class_finalizer.h"

#include "vm/flags.h"
#include "vm/hash_table.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/program_visitor.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/type_table.h"

namespace dart {

DEFINE_FLAG(bool, print_classes, false, "Prints details about loaded classes.");
DEFINE_FLAG(bool, reify, true, "Reify type arguments of generic types.");
DEFINE_FLAG(bool, trace_class_finalization, false, "Trace class finalization.");
DEFINE_FLAG(bool, trace_type_finalization, false, "Trace type finalization.");


bool ClassFinalizer::AllClassesFinalized() {
  ObjectStore* object_store = Isolate::Current()->object_store();
  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(object_store->pending_classes());
  return classes.Length() == 0;
}


// Removes optimized code once we load more classes, since CHA based
// optimizations may have become invalid.
// Only methods which owner classes where subclasses can be invalid.
// TODO(srdjan): Be even more precise by recording the exact CHA optimization.
static void RemoveCHAOptimizedCode(
    const Class& subclass,
    const GrowableArray<intptr_t>& added_subclass_to_cids) {
  ASSERT(FLAG_use_cha_deopt);
  if (added_subclass_to_cids.is_empty()) {
    return;
  }
  // Switch all functions' code to unoptimized.
  const ClassTable& class_table = *Isolate::Current()->class_table();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < added_subclass_to_cids.length(); i++) {
    intptr_t cid = added_subclass_to_cids[i];
    cls = class_table.At(cid);
    ASSERT(!cls.IsNull());
    cls.DisableCHAOptimizedCode(subclass);
  }
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
    const Class& cls_,
    GrowableArray<intptr_t>* finalized_super_classes) {
  Class& cls = Class::Handle(cls_.raw());
  AbstractType& super_type = Type::Handle();
  super_type = cls.super_type();
  if (!super_type.IsNull()) {
    if (!super_type.IsMalformed() && super_type.HasResolvedTypeClass()) {
      cls ^= super_type.type_class();
      if (cls.is_finalized()) {
        AddSuperType(super_type, finalized_super_classes);
      }
    }
  }
}


static void CollectImmediateSuperInterfaces(const Class& cls,
                                            GrowableArray<intptr_t>* cids) {
  const Array& interfaces = Array::Handle(cls.interfaces());
  Class& ifc = Class::Handle();
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    if (type.IsMalformed()) continue;
    if (!type.HasResolvedTypeClass()) continue;
    ifc ^= type.type_class();
    for (intptr_t j = 0; j < cids->length(); ++j) {
      if ((*cids)[j] == ifc.id()) {
        // Already added.
        return;
      }
    }
    cids->Add(ifc.id());
  }
}


// Processing ObjectStore::pending_classes_ occurs:
// a) when bootstrap process completes (VerifyBootstrapClasses).
// b) after the user classes are loaded (dart_api).
bool ClassFinalizer::ProcessPendingClasses(bool from_kernel) {
  Thread* thread = Thread::Current();
  NOT_IN_PRODUCT(TimelineDurationScope tds(thread, Timeline::GetIsolateStream(),
                                           "ProcessPendingClasses"));
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  HANDLESCOPE(thread);
  ObjectStore* object_store = isolate->object_store();
  const Error& error = Error::Handle(thread->zone(), thread->sticky_error());
  if (!error.IsNull()) {
    return false;
  }
  if (AllClassesFinalized()) {
    return true;
  }

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    GrowableObjectArray& class_array = GrowableObjectArray::Handle();
    class_array = object_store->pending_classes();
    ASSERT(!class_array.IsNull());
    Class& cls = Class::Handle();
    // First resolve all superclasses.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      GrowableArray<intptr_t> visited_interfaces;
      ResolveSuperTypeAndInterfaces(cls, &visited_interfaces);
    }
    // Finalize all classes.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      FinalizeTypesInClass(cls);
    }

    // Classes compiled from Dart sources are finalized more lazily, classes
    // compiled from Kernel binaries can be finalized now (and should be,
    // since we will not revisit them).
    if (from_kernel) {
      for (intptr_t i = 0; i < class_array.Length(); i++) {
        cls ^= class_array.At(i);
        FinalizeClass(cls);
      }
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

    return true;
  } else {
    return false;
  }
  UNREACHABLE();
  return true;
}


// Adds all interfaces of cls into 'collected'. Duplicate entries may occur.
// No cycles are allowed.
void ClassFinalizer::CollectInterfaces(const Class& cls,
                                       GrowableArray<const Class*>* collected) {
  Zone* zone = Thread::Current()->zone();
  const Array& interface_array = Array::Handle(zone, cls.interfaces());
  AbstractType& interface = AbstractType::Handle(zone);
  Class& interface_class = Class::Handle(zone);
  for (intptr_t i = 0; i < interface_array.Length(); i++) {
    interface ^= interface_array.At(i);
    interface_class = interface.type_class();
    collected->Add(&Class::ZoneHandle(zone, interface_class.raw()));
    CollectInterfaces(interface_class, collected);
  }
}


#if !defined(DART_PRECOMPILED_RUNTIME)
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
  cls = object_store->linked_hash_map_class();
  ASSERT(LinkedHashMap::InstanceSize() == cls.instance_size());
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

  // Finalize type hierarchy for types that aren't pre-finalized
  // by Object::Init().
  if (!ProcessPendingClasses()) {
    // TODO(srdjan): Exit like a real VM instead.
    const Error& err = Error::Handle(Thread::Current()->sticky_error());
    OS::PrintErr("Could not verify bootstrap classes : %s\n",
                 err.ToErrorCString());
    OS::Exit(255);
  }
  if (FLAG_trace_class_finalization) {
    OS::Print("VerifyBootstrapClasses END.\n");
  }
  Isolate::Current()->heap()->Verify();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)


static bool IsLoaded(const Type& type) {
  if (type.HasResolvedTypeClass()) {
    return true;
  }
  const UnresolvedClass& unresolved_class =
      UnresolvedClass::Handle(type.unresolved_class());
  const Object& prefix =
      Object::Handle(unresolved_class.library_or_library_prefix());
  if (prefix.IsNull()) {
    return true;
  } else if (prefix.IsLibraryPrefix()) {
    return LibraryPrefix::Cast(prefix).is_loaded();
  } else {
    return true;
  }
}


// Resolve unresolved_class in the library of cls, or return null.
RawClass* ClassFinalizer::ResolveClass(
    const Class& cls,
    const UnresolvedClass& unresolved_class) {
  const String& class_name = String::Handle(unresolved_class.ident());
  Library& lib = Library::Handle();
  Class& resolved_class = Class::Handle();
  if (unresolved_class.library_or_library_prefix() == Object::null()) {
    lib = cls.library();
    ASSERT(!lib.IsNull());
    resolved_class = lib.LookupClass(class_name);
  } else {
    const Object& prefix =
        Object::Handle(unresolved_class.library_or_library_prefix());

    if (prefix.IsLibraryPrefix()) {
      resolved_class = LibraryPrefix::Cast(prefix).LookupClass(class_name);
    } else {
      resolved_class = Library::Cast(prefix).LookupClass(class_name);
    }
  }
  return resolved_class.raw();
}


void ClassFinalizer::ResolveRedirectingFactory(const Class& cls,
                                               const Function& factory) {
  const Function& target = Function::Handle(factory.RedirectionTarget());
  if (target.IsNull()) {
    Type& type = Type::Handle(factory.RedirectionType());
    if (!type.IsMalformed() && IsLoaded(type)) {
      const GrowableObjectArray& visited_factories =
          GrowableObjectArray::Handle(GrowableObjectArray::New());
      ResolveRedirectingFactoryTarget(cls, factory, visited_factories);
    }
    if (factory.is_const()) {
      type = factory.RedirectionType();
      if (type.IsMalformedOrMalbounded()) {
        ReportError(Error::Handle(type.error()));
      }
    }
  }
}


void ClassFinalizer::ResolveRedirectingFactoryTarget(
    const Class& cls,
    const Function& factory,
    const GrowableObjectArray& visited_factories) {
  ASSERT(factory.IsRedirectingFactory());

  // Check for redirection cycle.
  for (intptr_t i = 0; i < visited_factories.Length(); i++) {
    if (visited_factories.At(i) == factory.raw()) {
      // A redirection cycle is reported as a compile-time error.
      ReportError(cls, factory.token_pos(),
                  "factory '%s' illegally redirects to itself",
                  String::Handle(factory.name()).ToCString());
    }
  }
  visited_factories.Add(factory);

  // Check if target is already resolved.
  Type& type = Type::Handle(factory.RedirectionType());
  Function& target = Function::Handle(factory.RedirectionTarget());
  if (type.IsMalformedOrMalbounded()) {
    // Already resolved to a malformed or malbounded type. Will throw on usage.
    ASSERT(target.IsNull());
    return;
  }
  if (!target.IsNull()) {
    // Already resolved.
    return;
  }

  // Target is not resolved yet.
  if (FLAG_trace_class_finalization) {
    THR_Print("Resolving redirecting factory: %s\n",
              String::Handle(factory.name()).ToCString());
  }
  type ^= FinalizeType(cls, type);
  factory.SetRedirectionType(type);
  if (type.IsMalformedOrMalbounded()) {
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }
  ASSERT(!type.IsTypeParameter());  // Resolved in parser.
  if (type.IsDynamicType()) {
    // Replace the type with a malformed type and compile a throw when called.
    type = NewFinalizedMalformedType(Error::Handle(),  // No previous error.
                                     Script::Handle(cls.script()),
                                     factory.token_pos(),
                                     "factory may not redirect to 'dynamic'");
    factory.SetRedirectionType(type);
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }
  const Class& target_class = Class::Handle(type.type_class());
  String& target_class_name = String::Handle(target_class.Name());
  String& target_name =
      String::Handle(String::Concat(target_class_name, Symbols::Dot()));
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
        Script::Handle(target_class.script()), factory.token_pos(),
        "class '%s' has no constructor or factory named '%s'",
        target_class_name.ToCString(), user_visible_target_name.ToCString());
    factory.SetRedirectionType(type);
    ASSERT(factory.RedirectionTarget() == Function::null());
    return;
  }

  if (Isolate::Current()->error_on_bad_override()) {
    // Verify that the target is compatible with the redirecting factory.
    Error& error = Error::Handle();
    if (!target.HasCompatibleParametersWith(factory, &error)) {
      const Script& script = Script::Handle(target_class.script());
      type = NewFinalizedMalformedType(
          error, script, target.token_pos(),
          "constructor '%s' has incompatible parameters with "
          "redirecting factory '%s'",
          String::Handle(target.name()).ToCString(),
          String::Handle(factory.name()).ToCString());
      factory.SetRedirectionType(type);
      ASSERT(factory.RedirectionTarget() == Function::null());
      return;
    }
  }

  // Verify that the target is const if the redirecting factory is const.
  if (factory.is_const() && !target.is_const()) {
    ReportError(target_class, target.token_pos(),
                "constructor '%s' must be const as required by "
                "redirecting const factory '%s'",
                String::Handle(target.name()).ToCString(),
                String::Handle(factory.name()).ToCString());
  }

  // Update redirection data with resolved target.
  factory.SetRedirectionTarget(target);
  // Not needed anymore.
  factory.SetRedirectionIdentifier(Object::null_string());
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
      // We do not support generic constructors.
      ASSERT(target_type.IsInstantiated(kFunctions));
      const TypeArguments& type_args = TypeArguments::Handle(type.arguments());
      Error& bound_error = Error::Handle();
      target_type ^=
          target_type.InstantiateFrom(type_args, Object::null_type_arguments(),
                                      &bound_error, NULL, NULL, Heap::kOld);
      if (bound_error.IsNull()) {
        target_type ^= FinalizeType(cls, target_type);
      } else {
        ASSERT(target_type.IsInstantiated() && type_args.IsInstantiated());
        const Script& script = Script::Handle(target_class.script());
        FinalizeMalformedType(bound_error, script, target_type,
                              "cannot resolve redirecting factory");
        target_target = Function::null();
      }
    }
  }
  factory.SetRedirectionType(target_type);
  factory.SetRedirectionTarget(target_target);
}


void ClassFinalizer::ResolveTypeClass(const Class& cls, const Type& type) {
  if (type.IsFinalized()) {
    return;
  }
  if (FLAG_trace_type_finalization) {
    THR_Print("Resolve type class of '%s'\n",
              String::Handle(type.Name()).ToCString());
  }

  // Type parameters are always resolved in the parser in the correct
  // non-static scope or factory scope. That resolution scope is unknown here.
  // Being able to resolve a type parameter from class cls here would indicate
  // that the type parameter appeared in a static scope. Leaving the type as
  // unresolved is the correct thing to do.

  // Lookup the type class if necessary.
  Class& type_class = Class::Handle();
  if (type.HasResolvedTypeClass()) {
    type_class = type.type_class();
  } else {
    const UnresolvedClass& unresolved_class =
        UnresolvedClass::Handle(type.unresolved_class());
    type_class = ResolveClass(cls, unresolved_class);
    if (type_class.IsNull()) {
      // The type class could not be resolved. The type is malformed.
      FinalizeMalformedType(Error::Handle(),  // No previous error.
                            Script::Handle(cls.script()), type,
                            "cannot resolve class '%s' from '%s'",
                            String::Handle(unresolved_class.Name()).ToCString(),
                            String::Handle(cls.Name()).ToCString());
      return;
    }
    // Replace unresolved class with resolved type class.
    type.set_type_class(type_class);
  }
  // Promote the type to a function type in case its type class is a typedef.
  // Note that the type may already be a function type if it was parsed as a
  // formal parameter function type.
  if (!type.IsFunctionType() && type_class.IsTypedefClass() &&
      !type.IsMalformedOrMalbounded()) {
    type.set_signature(Function::Handle(type_class.signature_function()));
  }
  ASSERT(!type_class.IsTypedefClass() ||
         (type.signature() != Function::null()));

  // Replace FutureOr<T> type of async library with dynamic.
  if ((type_class.library() == Library::AsyncLibrary()) &&
      (type_class.Name() == Symbols::FutureOr().raw())) {
    Type::Cast(type).set_type_class(Class::Handle(Object::dynamic_class()));
    type.set_arguments(Object::null_type_arguments());
  }
}


void ClassFinalizer::ResolveType(const Class& cls, const AbstractType& type) {
  if (type.IsResolved()) {
    return;
  }
  if (FLAG_trace_type_finalization) {
    THR_Print("Resolve type '%s'\n", String::Handle(type.Name()).ToCString());
  }
  if (type.IsType()) {
    ResolveTypeClass(cls, Type::Cast(type));
    if (type.IsMalformed()) {
      ASSERT(type.IsResolved());
      return;
    }
  }
  // Mark type as resolved before resolving its type arguments and, in case of a
  // function type, its signature, in order to avoid cycles.
  type.SetIsResolved();
  // Resolve type arguments, if any.
  const TypeArguments& arguments = TypeArguments::Handle(type.arguments());
  if (!arguments.IsNull()) {
    const intptr_t num_arguments = arguments.Length();
    AbstractType& type_argument = AbstractType::Handle();
    for (intptr_t i = 0; i < num_arguments; i++) {
      type_argument = arguments.TypeAt(i);
      ResolveType(cls, type_argument);
    }
  }
  // Resolve signature if function type.
  if (type.IsFunctionType()) {
    const Function& signature = Function::Handle(Type::Cast(type).signature());
    Type& signature_type = Type::Handle(signature.SignatureType());
    if (signature_type.raw() != type.raw()) {
      // This type was promoted to a function type because its type class is a
      // typedef class. The promotion is achieved by assigning the signature
      // function of the typedef class to this type. This function is pointing
      // to the original typedef function type, which is not this type.
      // By resolving the typedef function type (which may already be resolved,
      // hence saving work), we will resolve the shared signature function.
      ASSERT(Class::Handle(type.type_class()).IsTypedefClass());
      ResolveType(cls, signature_type);
    } else {
      const Class& scope_class = Class::Handle(type.type_class());
      if (scope_class.IsTypedefClass()) {
        // This type is the original function type of the typedef class.
        ResolveSignature(scope_class, signature);
      } else {
        ASSERT(scope_class.IsClosureClass());
        ResolveSignature(cls, signature);
        ASSERT(type.arguments() == TypeArguments::null());
        if (signature.IsSignatureFunction()) {
          // Drop fields that are not necessary anymore after resolution.
          // The parent function, owner, and token position of a shared
          // canonical function type are meaningless, since the canonical
          // representent is picked arbitrarily.
          // The parent function is however still required to finalize function
          // type parameters when the function has a generic parent.
          if (!signature.HasGenericParent()) {
            signature.set_parent_function(Function::Handle());
          }
          // TODO(regis): As long as we support metadata in typedef signatures,
          // we cannot reset these fields used to reparse a typedef.
          // Note that the scope class of a typedef function type is always
          // preserved as the typedef class (not reset to _Closure class),
          // thereby preventing sharing of canonical function types between
          // typedefs. Not being shared, these fields are therefore always
          // meaningful for typedefs.
          if (!scope_class.IsTypedefClass()) {
            signature.set_owner(Object::Handle());
            signature.set_token_pos(TokenPosition::kNoSource);
          }
        }
      }
    }
  }
}


void ClassFinalizer::FinalizeTypeParameters(const Class& cls,
                                            PendingTypes* pending_types) {
  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type parameters of '%s'\n",
              String::Handle(cls.Name()).ToCString());
  }
  if (cls.IsMixinApplication()) {
    // Setup the type parameters of the mixin application and finalize the
    // mixin type.
    ApplyMixinType(cls, pending_types);
  }
  // The type parameter bounds are not finalized here.
  const TypeArguments& type_parameters =
      TypeArguments::Handle(cls.type_parameters());
  if (!type_parameters.IsNull()) {
    TypeParameter& type_parameter = TypeParameter::Handle();
    const intptr_t num_types = type_parameters.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      type_parameter ^= type_parameters.TypeAt(i);
      type_parameter ^=
          FinalizeType(cls, type_parameter, kFinalize, pending_types);
      type_parameters.SetTypeAt(i, type_parameter);
    }
  }
}


// This function reports a compilation error if the recursive 'type' T being
// finalized is a non-contractive type, i.e. if the induced type set S of P is
// not finite, where P is the instantiation of T with its own type parameters.
// The induced type set S consists of the super types of any type in S as well
// as the type arguments of any parameterized type in S.
// The Dart Language Specification does not disallow the declaration and use of
// non-contractive types (this may change). They are nevertheless disallowed
// as an implementation restriction in the VM since they cause divergence.
// A non-contractive type can be detected by looking at the queue of types
// pending finalization that are mutually recursive with the checked type.
void ClassFinalizer::CheckRecursiveType(const Class& cls,
                                        const AbstractType& type,
                                        PendingTypes* pending_types) {
  ASSERT(pending_types != NULL);
  Zone* zone = Thread::Current()->zone();
  if (FLAG_trace_type_finalization) {
    THR_Print("Checking recursive type '%s': %s\n",
              String::Handle(type.Name()).ToCString(), type.ToCString());
  }
  const Class& type_cls = Class::Handle(zone, type.type_class());
  const TypeArguments& arguments =
      TypeArguments::Handle(zone, type.arguments());
  // A type can only be recursive via its type arguments.
  ASSERT(!arguments.IsNull());
  const intptr_t num_type_args = arguments.Length();
  ASSERT(num_type_args > 0);
  ASSERT(num_type_args == type_cls.NumTypeArguments());
  const intptr_t num_type_params = type_cls.NumTypeParameters();
  const intptr_t first_type_param = num_type_args - num_type_params;
  // If the type is not generic (num_type_params == 0) or if its type parameters
  // are instantiated, no divergence can occur. Note that if the type parameters
  // are null, i.e. if the generic type is raw, they are considered
  // instantiated and no divergence can occur.
  if ((num_type_params == 0) ||
      arguments.IsSubvectorInstantiated(first_type_param, num_type_params)) {
    return;
  }
  // Consider mutually recursive and uninstantiated types pending finalization
  // with the same type class and report an error if they are not equal in their
  // raw form, i.e. where each type parameter is substituted with dynamic.
  // This test eliminates divergent types without restricting recursive types
  // typically found in the wild.
  TypeArguments& pending_arguments = TypeArguments::Handle(zone);
  const intptr_t num_pending_types = pending_types->length();
  for (intptr_t i = num_pending_types - 1; i >= 0; i--) {
    const AbstractType& pending_type = pending_types->At(i);
    if (FLAG_trace_type_finalization) {
      THR_Print("  Comparing with pending type '%s': %s\n",
                String::Handle(pending_type.Name()).ToCString(),
                pending_type.ToCString());
    }
    if ((pending_type.raw() != type.raw()) && pending_type.IsType() &&
        (pending_type.type_class() == type_cls.raw())) {
      pending_arguments = pending_type.arguments();
      if (!pending_arguments.IsSubvectorEquivalent(arguments, first_type_param,
                                                   num_type_params) &&
          !pending_arguments.IsSubvectorInstantiated(first_type_param,
                                                     num_type_params)) {
        const TypeArguments& instantiated_arguments = TypeArguments::Handle(
            zone, arguments.InstantiateFrom(Object::null_type_arguments(),
                                            Object::null_type_arguments(), NULL,
                                            NULL, NULL, Heap::kNew));
        const TypeArguments& instantiated_pending_arguments =
            TypeArguments::Handle(zone, pending_arguments.InstantiateFrom(
                                            Object::null_type_arguments(),
                                            Object::null_type_arguments(), NULL,
                                            NULL, NULL, Heap::kNew));
        if (!instantiated_pending_arguments.IsSubvectorEquivalent(
                instantiated_arguments, first_type_param, num_type_params)) {
          const String& type_name = String::Handle(zone, type.Name());
          ReportError(cls, type.token_pos(), "illegal recursive type '%s'",
                      type_name.ToCString());
        }
      }
    }
  }
}


// Expand the type arguments of the given type and finalize its full type
// argument vector. Return the number of type arguments (0 for a raw type).
intptr_t ClassFinalizer::ExpandAndFinalizeTypeArguments(
    const Class& cls,
    const AbstractType& type,
    PendingTypes* pending_types) {
  Zone* zone = Thread::Current()->zone();
  // The type class does not need to be finalized in order to finalize the type,
  // however, it must at least be resolved (this was done as part of resolving
  // the type itself, a precondition to calling FinalizeType).
  // Also, the interfaces of the type class must be resolved and the type
  // parameters of the type class must be finalized.
  Class& type_class = Class::Handle(zone, type.type_class());
  if (!type_class.is_type_finalized()) {
    FinalizeTypeParameters(type_class, pending_types);
    ResolveUpperBounds(type_class);
  }

  // The finalized type argument vector needs num_type_arguments types.
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  // The class has num_type_parameters type parameters.
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // If we are not reifying types, drop type arguments.
  if (!FLAG_reify) {
    type.set_arguments(Object::null_type_arguments());
  }

  // Initialize the type argument vector.
  // Check the number of parsed type arguments, if any.
  // Specifying no type arguments indicates a raw type, which is not an error.
  // However, type parameter bounds are checked below, even for a raw type.
  TypeArguments& arguments = TypeArguments::Handle(zone, type.arguments());
  if (!arguments.IsNull() && (arguments.Length() != num_type_parameters)) {
    // Wrong number of type arguments. The type is mapped to the raw type.
    if (Isolate::Current()->error_on_bad_type()) {
      const String& type_class_name = String::Handle(zone, type_class.Name());
      ReportError(cls, type.token_pos(),
                  "wrong number of type arguments for class '%s'",
                  type_class_name.ToCString());
    }
    // Make the type raw and continue without reporting any error.
    // A static warning should have been reported.
    arguments = TypeArguments::null();
    type.set_arguments(arguments);
  }

  // Mark the type as being finalized in order to detect self reference and
  // postpone bound checking (if required) until after all types in the graph of
  // mutually recursive types are finalized.
  type.SetIsBeingFinalized();
  ASSERT(pending_types != NULL);
  pending_types->Add(type);

  // The full type argument vector consists of the type arguments of the
  // super types of type_class, which are initialized from the parsed
  // type arguments, followed by the parsed type arguments.
  TypeArguments& full_arguments = TypeArguments::Handle(zone);
  if (FLAG_reify && (num_type_arguments > 0)) {
    // If no type arguments were parsed and if the super types do not prepend
    // type arguments to the vector, we can leave the vector as null.
    if (!arguments.IsNull() || (num_type_arguments > num_type_parameters)) {
      full_arguments = TypeArguments::New(num_type_arguments);
      // Copy the parsed type arguments at the correct offset in the full type
      // argument vector.
      const intptr_t offset = num_type_arguments - num_type_parameters;
      AbstractType& type_arg = AbstractType::Handle(zone, Type::DynamicType());
      // Leave the temporary type arguments at indices [0..offset[ as null.
      for (intptr_t i = 0; i < num_type_parameters; i++) {
        // If no type parameters were provided, a raw type is desired, so we
        // create a vector of dynamic.
        if (!arguments.IsNull()) {
          type_arg = arguments.TypeAt(i);
          // The parsed type_arg may or may not be finalized.
        }
        full_arguments.SetTypeAt(offset + i, type_arg);
      }
      // Replace the compile-time argument vector (of length zero or
      // num_type_parameters) of this type being finalized with the still
      // unfinalized run-time argument vector (of length num_type_arguments).
      // This type being finalized may be recursively reached via bounds
      // checking or type arguments of its super type.
      type.set_arguments(full_arguments);
      // Finalize the current type arguments of the type, which are still the
      // parsed type arguments.
      if (!arguments.IsNull()) {
        for (intptr_t i = 0; i < num_type_parameters; i++) {
          type_arg = full_arguments.TypeAt(offset + i);
          ASSERT(!type_arg.IsBeingFinalized());
          type_arg = FinalizeType(cls, type_arg, kFinalize, pending_types);
          if (type_arg.IsMalformed()) {
            // Malformed type arguments are mapped to dynamic.
            type_arg = Type::DynamicType();
          }
          full_arguments.SetTypeAt(offset + i, type_arg);
        }
      }
      if (offset > 0) {
        TrailPtr instantiation_trail = new Trail(zone, 4);
        Error& bound_error = Error::Handle(zone);
        FinalizeTypeArguments(type_class, full_arguments, offset, &bound_error,
                              pending_types, instantiation_trail);
      }
      if (full_arguments.IsRaw(0, num_type_arguments)) {
        // The parameterized_type is raw. Set its argument vector to null, which
        // is more efficient in type tests.
        full_arguments = TypeArguments::null();
      }
      type.set_arguments(full_arguments);
    } else {
      ASSERT(full_arguments.IsNull());  // Use null vector for raw type.
    }
  }

  ASSERT(full_arguments.IsNull() ||
         !full_arguments.IsRaw(0, num_type_arguments));
  return full_arguments.IsNull() ? 0 : full_arguments.Length();
}


// Finalize the type argument vector 'arguments' of the type defined by the
// class 'cls' parameterized with the type arguments 'cls_args'.
// The vector 'cls_args' is already initialized as a subvector at the correct
// position in the passed in 'arguments' vector.
// The subvector 'cls_args' has length cls.NumTypeParameters() and starts at
// offset cls.NumTypeArguments() - cls.NumTypeParameters() of the 'arguments'
// vector.
// The type argument vector of cls may overlap the type argument vector of its
// super class. In case of an overlap, the overlapped type arguments of the
// super class are already initialized. The still uninitialized ones have an
// offset smaller than 'num_uninitialized_arguments'.
// Example 1 (without overlap):
//   Declared: class C<K, V> extends B<V> { ... }
//             class B<T> extends A<int> { ... }
//   Input:    C<String, double> expressed as
//             cls = C, arguments = [dynamic, dynamic, String, double],
//             num_uninitialized_arguments = 2,
//             i.e. cls_args = [String, double], offset = 2, length = 2.
//   Output:   arguments = [int, double, String, double]
// Example 2 (with overlap):
//   Declared: class C<K, V> extends B<K> { ... }
//             class B<T> extends A<int> { ... }
//   Input:    C<String, double> expressed as
//             cls = C, arguments = [dynamic, String, double],
//             num_uninitialized_arguments = 1,
//             i.e. cls_args = [String, double], offset = 1, length = 2.
//   Output:   arguments = [int, String, double]
//
// It is too early to canonicalize the type arguments of the vector, because
// several type argument vectors may be mutually recursive and finalized at the
// same time. Canonicalization happens when pending types are processed.
// The trail is required to correctly instantiate a recursive type argument
// of the super type.
void ClassFinalizer::FinalizeTypeArguments(const Class& cls,
                                           const TypeArguments& arguments,
                                           intptr_t num_uninitialized_arguments,
                                           Error* bound_error,
                                           PendingTypes* pending_types,
                                           TrailPtr instantiation_trail) {
  ASSERT(arguments.Length() >= cls.NumTypeArguments());
  if (!cls.is_type_finalized()) {
    FinalizeTypeParameters(cls, pending_types);
    ResolveUpperBounds(cls);
  }
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    const intptr_t num_super_type_params = super_class.NumTypeParameters();
    const intptr_t num_super_type_args = super_class.NumTypeArguments();
    ASSERT(num_super_type_args ==
           (cls.NumTypeArguments() - cls.NumOwnTypeArguments()));
    if (!super_type.IsFinalized() && !super_type.IsBeingFinalized()) {
      super_type ^= FinalizeType(cls, super_type, kFinalize, pending_types);
      cls.set_super_type(super_type);
    }
    TypeArguments& super_type_args =
        TypeArguments::Handle(super_type.arguments());
    // Offset of super type's type parameters in cls' type argument vector.
    const intptr_t super_offset = num_super_type_args - num_super_type_params;
    // If the super type is raw (i.e. super_type_args is null), set to dynamic.
    AbstractType& super_type_arg = AbstractType::Handle(Type::DynamicType());
    for (intptr_t i = super_offset; i < num_uninitialized_arguments; i++) {
      if (!super_type_args.IsNull()) {
        super_type_arg = super_type_args.TypeAt(i);
        if (!super_type_arg.IsTypeRef()) {
          if (super_type_arg.IsBeingFinalized()) {
            ASSERT(super_type_arg.IsType());
            CheckRecursiveType(cls, super_type_arg, pending_types);
            if (FLAG_trace_type_finalization) {
              THR_Print("Creating TypeRef '%s': '%s'\n",
                        String::Handle(super_type_arg.Name()).ToCString(),
                        super_type_arg.ToCString());
            }
            super_type_arg = TypeRef::New(super_type_arg);
            super_type_args.SetTypeAt(i, super_type_arg);
          } else {
            if (!super_type_arg.IsFinalized()) {
              super_type_arg ^=
                  FinalizeType(cls, super_type_arg, kFinalize, pending_types);
              super_type_args.SetTypeAt(i, super_type_arg);
              // Note that super_type_arg may still not be finalized here, in
              // which case it is a TypeRef to a legal recursive type.
            }
          }
        }
        // Instantiate super_type_arg with the current argument vector.
        if (!super_type_arg.IsInstantiated()) {
          if (FLAG_trace_type_finalization && super_type_arg.IsTypeRef()) {
            AbstractType& ref_type =
                AbstractType::Handle(TypeRef::Cast(super_type_arg).type());
            THR_Print(
                "Instantiating TypeRef '%s': '%s'\n"
                "  instantiator: '%s'\n",
                String::Handle(super_type_arg.Name()).ToCString(),
                ref_type.ToCString(), arguments.ToCString());
          }
          // In the typical case of an F-bounded type, the instantiation of the
          // super_type_arg from arguments is a fixpoint. Take the shortcut.
          // Example: class B<T>; class D<T> extends B<D<T>>;
          // While finalizing D<T>, the super type arg D<T> (a typeref) gets
          // instantiated from vector [T], yielding itself.
          if (super_type_arg.IsTypeRef() &&
              (super_type_arg.arguments() == arguments.raw())) {
            ASSERT(super_type_arg.IsBeingFinalized());
            arguments.SetTypeAt(i, super_type_arg);
            continue;
          }
          Error& error = Error::Handle();
          super_type_arg = super_type_arg.InstantiateFrom(
              arguments, Object::null_type_arguments(), &error,
              instantiation_trail, NULL, Heap::kOld);
          if (!error.IsNull()) {
            // InstantiateFrom does not report an error if the type is still
            // uninstantiated. Instead, it will return a new BoundedType so
            // that the check is postponed to run time.
            ASSERT(super_type_arg.IsInstantiated());
            // Keep only the first bound error.
            if (bound_error->IsNull()) {
              *bound_error = error.raw();
            }
          }
          if (super_type_arg.IsBeingFinalized()) {
            // The super_type_arg was instantiated from a type being finalized.
            // We need to finish finalizing its type arguments.
            ASSERT(super_type_arg.IsTypeRef());
            AbstractType& ref_super_type_arg =
                AbstractType::Handle(TypeRef::Cast(super_type_arg).type());
            if (FLAG_trace_type_finalization) {
              THR_Print("Instantiated TypeRef '%s': '%s'\n",
                        String::Handle(super_type_arg.Name()).ToCString(),
                        ref_super_type_arg.ToCString());
            }
            CheckRecursiveType(cls, ref_super_type_arg, pending_types);
            pending_types->Add(ref_super_type_arg);
            const Class& super_cls =
                Class::Handle(ref_super_type_arg.type_class());
            const TypeArguments& super_args =
                TypeArguments::Handle(ref_super_type_arg.arguments());
            // Mark as finalized before finalizing to avoid cycles.
            ref_super_type_arg.SetIsFinalized();
            // Although the instantiator is different between cls and super_cls,
            // we still need to pass the current instantiation trail as to avoid
            // divergence. Finalizing the type arguments of super_cls may indeed
            // recursively require instantiating the same type_refs already
            // present in the trail (see issue #29949).
            FinalizeTypeArguments(
                super_cls, super_args,
                super_cls.NumTypeArguments() - super_cls.NumTypeParameters(),
                bound_error, pending_types, instantiation_trail);
            if (FLAG_trace_type_finalization) {
              THR_Print("Finalized instantiated TypeRef '%s': '%s'\n",
                        String::Handle(super_type_arg.Name()).ToCString(),
                        ref_super_type_arg.ToCString());
            }
          }
        }
      }
      arguments.SetTypeAt(i, super_type_arg);
    }
    FinalizeTypeArguments(super_class, arguments, super_offset, bound_error,
                          pending_types, instantiation_trail);
  }
}


// Check the type argument vector 'arguments' against the corresponding bounds
// of the type parameters of class 'cls' and, recursively, of its superclasses.
// Replace a type argument that cannot be checked at compile time by a
// BoundedType, thereby postponing the bound check to run time.
// Return a bound error if a type argument is not within bound at compile time.
void ClassFinalizer::CheckTypeArgumentBounds(const Class& cls,
                                             const TypeArguments& arguments,
                                             Error* bound_error) {
  if (!cls.is_type_finalized()) {
    FinalizeTypeParameters(cls);
    FinalizeUpperBounds(cls, kFinalize);  // No canonicalization yet.
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
  // In case of overlapping type argument vectors, the same type argument may
  // get checked against different bounds.
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_arg = arguments.TypeAt(offset + i);
    if (type_arg.IsDynamicType()) {
      continue;
    }
    ASSERT(type_arg.IsFinalized());
    if (type_arg.IsMalbounded()) {
      // The type argument itself is already malbounded, independently of the
      // declared bound, which may be Object.
      // Propagate the bound error from the type argument to the type.
      if (bound_error->IsNull()) {
        *bound_error = type_arg.error();
        ASSERT(!bound_error->IsNull());
      }
    }
    cls_type_param = cls_type_params.TypeAt(i);
    const TypeParameter& type_param = TypeParameter::Cast(cls_type_param);
    ASSERT(type_param.IsFinalized());
    declared_bound = type_param.bound();
    if (!declared_bound.IsObjectType() && !declared_bound.IsDynamicType()) {
      if (!declared_bound.IsFinalized() && !declared_bound.IsBeingFinalized()) {
        declared_bound = FinalizeType(cls, declared_bound);
        type_param.set_bound(declared_bound);
      }
      ASSERT(declared_bound.IsFinalized() || declared_bound.IsBeingFinalized());
      Error& error = Error::Handle();
      // Note that the bound may be malformed, in which case the bound check
      // will return an error and the bound check will be postponed to run time.
      if (declared_bound.IsInstantiated()) {
        instantiated_bound = declared_bound.raw();
      } else {
        instantiated_bound = declared_bound.InstantiateFrom(
            arguments, Object::null_type_arguments(), &error, NULL, NULL,
            Heap::kOld);
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
      // Shortcut the special case where we check a type parameter against its
      // declared upper bound.
      if (error.IsNull() &&
          !(type_arg.Equals(type_param) &&
            instantiated_bound.Equals(declared_bound))) {
        // If type_arg is a type parameter, its declared bound may not be
        // finalized yet.
        if (type_arg.IsTypeParameter()) {
          const Class& type_arg_cls = Class::Handle(
              TypeParameter::Cast(type_arg).parameterized_class());
          AbstractType& bound =
              AbstractType::Handle(TypeParameter::Cast(type_arg).bound());
          if (!bound.IsFinalized() && !bound.IsBeingFinalized()) {
            bound = FinalizeType(type_arg_cls, bound);
            TypeParameter::Cast(type_arg).set_bound(bound);
          }
        }
        // This may be called only if type needs to be finalized, therefore
        // seems OK to allocate finalized types in old space.
        if (!type_param.CheckBound(type_arg, instantiated_bound, &error, NULL,
                                   Heap::kOld) &&
            error.IsNull()) {
          // The bound cannot be checked at compile time; postpone to run time.
          type_arg = BoundedType::New(type_arg, instantiated_bound, type_param);
          arguments.SetTypeAt(offset + i, type_arg);
        }
      }
      if (!error.IsNull() && bound_error->IsNull()) {
        *bound_error = error.raw();
      }
    }
  }
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    CheckTypeArgumentBounds(super_class, arguments, bound_error);
  }
}


void ClassFinalizer::CheckTypeBounds(const Class& cls,
                                     const AbstractType& type) {
  Zone* zone = Thread::Current()->zone();
  ASSERT(type.IsType());
  ASSERT(type.IsFinalized());
  ASSERT(!type.IsCanonical());
  TypeArguments& arguments = TypeArguments::Handle(zone, type.arguments());
  if (arguments.IsNull()) {
    return;
  }
  if (FLAG_trace_type_finalization) {
    THR_Print("Checking bounds of type '%s' for class '%s'\n",
              String::Handle(zone, type.Name()).ToCString(),
              String::Handle(zone, cls.Name()).ToCString());
  }
  const Class& type_class = Class::Handle(zone, type.type_class());
  Error& bound_error = Error::Handle(zone);
  CheckTypeArgumentBounds(type_class, arguments, &bound_error);
  // CheckTypeArgumentBounds may have indirectly canonicalized this type.
  if (!type.IsCanonical()) {
    type.set_arguments(arguments);
    // If a bound error occurred, mark the type as malbounded.
    // The bound error will be ignored in production mode.
    if (!bound_error.IsNull()) {
      // No compile-time error during finalization.
      const String& type_name = String::Handle(zone, type.UserVisibleName());
      FinalizeMalboundedType(
          bound_error, Script::Handle(zone, cls.script()), type,
          "type '%s' has an out of bound type argument", type_name.ToCString());
      if (FLAG_trace_type_finalization) {
        THR_Print("Marking type '%s' as malbounded: %s\n",
                  String::Handle(zone, type.Name()).ToCString(),
                  bound_error.ToErrorCString());
      }
    }
  }
  if (FLAG_trace_type_finalization) {
    THR_Print("Done checking bounds of type '%s': %s\n",
              String::Handle(zone, type.Name()).ToCString(), type.ToCString());
  }
}


RawAbstractType* ClassFinalizer::FinalizeType(const Class& cls,
                                              const AbstractType& type,
                                              FinalizationKind finalization,
                                              PendingTypes* pending_types) {
  // Only the 'root' type of the graph can be canonicalized, after all depending
  // types have been bound checked.
  ASSERT((pending_types == NULL) || (finalization < kCanonicalize));
  if (type.IsFinalized()) {
    // Ensure type is canonical if canonicalization is requested, unless type is
    // malformed.
    if ((finalization >= kCanonicalize) && !type.IsMalformed() &&
        !type.IsCanonical() && type.IsType()) {
      CheckTypeBounds(cls, type);
      return type.Canonicalize();
    }
    return type.raw();
  }
  ASSERT(finalization >= kFinalize);

  if (type.IsTypeRef()) {
    // The referenced type will be finalized later by the code that set the
    // is_being_finalized mark bit.
    return type.raw();
  }

  // Recursive types must be processed in FinalizeTypeArguments() and cannot be
  // encountered here.
  ASSERT(!type.IsBeingFinalized());

  Zone* zone = Thread::Current()->zone();
  ResolveType(cls, type);
  // A malformed type gets mapped to a finalized type.
  if (type.IsMalformed()) {
    ASSERT(type.IsFinalized());
    return type.raw();
  }

  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type '%s' for class '%s'\n",
              String::Handle(zone, type.Name()).ToCString(),
              String::Handle(zone, cls.Name()).ToCString());
  }

  if (type.IsTypeParameter()) {
    const TypeParameter& type_parameter = TypeParameter::Cast(type);
    const Class& parameterized_class =
        Class::Handle(zone, type_parameter.parameterized_class());
    intptr_t offset;
    if (!parameterized_class.IsNull()) {
      // The index must reflect the position of this type parameter in the type
      // arguments vector of its parameterized class. The offset to add is the
      // number of type arguments in the super type, which is equal to the
      // difference in number of type arguments and type parameters of the
      // parameterized class.
      offset = parameterized_class.NumTypeArguments() -
               parameterized_class.NumTypeParameters();
    } else {
      const Function& function =
          Function::Handle(zone, type_parameter.parameterized_function());
      ASSERT(!function.IsNull());
      offset = function.NumParentTypeParameters();
    }
    // Calling NumTypeParameters() may finalize this type parameter if it
    // belongs to a mixin application class.
    if (!type_parameter.IsFinalized()) {
      type_parameter.set_index(type_parameter.index() + offset);
      type_parameter.SetIsFinalized();
    } else {
      ASSERT(cls.IsMixinApplication());
    }

    if (FLAG_trace_type_finalization) {
      THR_Print("Done finalizing type parameter '%s' with index %" Pd "\n",
                String::Handle(zone, type_parameter.name()).ToCString(),
                type_parameter.index());
    }

    // We do not canonicalize type parameters.
    return type_parameter.raw();
  }

  // At this point, we can only have a Type.
  ASSERT(type.IsType());

  // This type is the root type of the type graph if no pending types queue is
  // allocated yet.
  const bool is_root_type = pending_types == NULL;
  if (is_root_type) {
    pending_types = new PendingTypes(zone, 4);
  }

  const intptr_t num_expanded_type_arguments =
      ExpandAndFinalizeTypeArguments(cls, type, pending_types);

  // Self referencing types may get finalized indirectly.
  if (!type.IsFinalized()) {
    // If the type is a function type, we also need to finalize the types in its
    // signature, i.e. finalize the result type and parameter types of the
    // signature function of this function type.
    // We do this after marking this type as finalized in order to allow a
    // typedef function type to refer to itself via its parameter types and
    // result type.
    if (type.IsFunctionType()) {
      const Type& fun_type = Type::Cast(type);
      const Class& scope_class = Class::Handle(zone, fun_type.type_class());
      if (scope_class.IsTypedefClass()) {
        Function& signature =
            Function::Handle(zone, scope_class.signature_function());
        if (!scope_class.is_type_finalized()) {
          FinalizeSignature(scope_class, signature);
        }
        // If the function type is a generic typedef, instantiate its signature
        // from its type arguments.
        // Example: typedef F<T> = S Function<S>(T x) has uninstantiated
        // signature (T x) => S.
        // The instantiated signature of F(int) becomes (int x) => S.
        // Note that after this step, the signature of the function type is not
        // identical to the canonical signature of the typedef class anymore.
        if (scope_class.IsGeneric() && !signature.HasInstantiatedSignature()) {
          if (FLAG_trace_type_finalization) {
            THR_Print("Instantiating signature '%s' of typedef '%s'\n",
                      String::Handle(zone, signature.Signature()).ToCString(),
                      String::Handle(zone, fun_type.Name()).ToCString());
          }
          const TypeArguments& instantiator_type_arguments =
              TypeArguments::Handle(zone, fun_type.arguments());
          const TypeArguments& function_type_arguments =
              TypeArguments::Handle(zone, signature.type_parameters());
          signature = signature.InstantiateSignatureFrom(
              instantiator_type_arguments, function_type_arguments, Heap::kOld);
          // Note that if instantiator_type_arguments contains type parameters,
          // as in F<K>, the signature is still uninstantiated (the typedef type
          // parameters were substituted in the signature with typedef type
          // arguments). Note also that the function type parameters were not
          // modified.
          FinalizeSignature(scope_class, signature);  // Canonicalize signature.
        }
        fun_type.set_signature(signature);
      } else {
        FinalizeSignature(cls, Function::Handle(zone, fun_type.signature()));
      }
    }

    if (FLAG_trace_type_finalization) {
      THR_Print("Marking type '%s' as finalized for class '%s'\n",
                String::Handle(zone, type.Name()).ToCString(),
                String::Handle(zone, cls.Name()).ToCString());
    }
    // Mark the type as finalized.
    type.SetIsFinalized();
  }

  // If we are done finalizing a graph of mutually recursive types, check their
  // bounds.
  if (is_root_type) {
    for (intptr_t i = pending_types->length() - 1; i >= 0; i--) {
      const AbstractType& type = pending_types->At(i);
      if (!type.IsMalformed() && !type.IsCanonical()) {
        CheckTypeBounds(cls, type);
      }
    }
  }

  if (FLAG_trace_type_finalization) {
    THR_Print("Done finalizing type '%s' with %" Pd " type args: %s\n",
              String::Handle(zone, type.Name()).ToCString(),
              num_expanded_type_arguments, type.ToCString());
  }

  if (finalization >= kCanonicalize) {
    if (FLAG_trace_type_finalization) {
      THR_Print("Canonicalizing type '%s'\n",
                String::Handle(zone, type.Name()).ToCString());
      AbstractType& canonical_type =
          AbstractType::Handle(zone, type.Canonicalize());
      THR_Print("Done canonicalizing type '%s'\n",
                String::Handle(zone, canonical_type.Name()).ToCString());
      return canonical_type.raw();
    }
    return type.Canonicalize();
  } else {
    return type.raw();
  }
}


void ClassFinalizer::ResolveSignature(const Class& cls,
                                      const Function& function) {
  AbstractType& type = AbstractType::Handle();
  // Resolve upper bounds of function type parameters.
  const intptr_t num_type_params = function.NumTypeParameters();
  if (num_type_params > 0) {
    TypeParameter& type_param = TypeParameter::Handle();
    const TypeArguments& type_params =
        TypeArguments::Handle(function.type_parameters());
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      type = type_param.bound();
      ResolveType(cls, type);
    }
  }
  // Resolve result type.
  type = function.result_type();
  // It is not a compile time error if this name does not resolve to a class or
  // interface.
  ResolveType(cls, type);
  // Resolve formal parameter types.
  const intptr_t num_parameters = function.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    ResolveType(cls, type);
  }
}


void ClassFinalizer::FinalizeSignature(const Class& cls,
                                       const Function& function,
                                       FinalizationKind finalization) {
  AbstractType& type = AbstractType::Handle();
  AbstractType& finalized_type = AbstractType::Handle();
  // Finalize function type parameters and their upper bounds.
  const intptr_t num_parent_type_params = function.NumParentTypeParameters();
  const intptr_t num_type_params = function.NumTypeParameters();
  if (num_type_params > 0) {
    TypeParameter& type_param = TypeParameter::Handle();
    const TypeArguments& type_params =
        TypeArguments::Handle(function.type_parameters());
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      if (!type_param.IsFinalized()) {
        type_param.set_index(num_parent_type_params + i);
        type_param.SetIsFinalized();
      }
      type = type_param.bound();
      finalized_type = FinalizeType(cls, type, finalization);
      if (finalized_type.raw() != type.raw()) {
        type_param.set_bound(finalized_type);
      }
    }
  }
  // Finalize result type.
  type = function.result_type();
  finalized_type = FinalizeType(cls, type, finalization);
  // The result type may be malformed or malbounded.
  if (finalized_type.raw() != type.raw()) {
    function.set_result_type(finalized_type);
  }
  // Finalize formal parameter types.
  const intptr_t num_parameters = function.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    finalized_type = FinalizeType(cls, type, finalization);
    // The parameter type may be malformed or malbounded.
    if (type.raw() != finalized_type.raw()) {
      function.SetParameterTypeAt(i, finalized_type);
    }
  }
}


// Check if an instance field, getter, or method of same name exists
// in any super class.
static RawClass* FindSuperOwnerOfInstanceMember(const Class& cls,
                                                const String& name,
                                                const String& getter_name) {
  Class& super_class = Class::Handle();
  Function& function = Function::Handle();
  Field& field = Field::Handle();
  super_class = cls.SuperClass();
  while (!super_class.IsNull()) {
    function = super_class.LookupFunction(name);
    if (!function.IsNull() && !function.is_static()) {
      return super_class.raw();
    }
    function = super_class.LookupFunction(getter_name);
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
    if (!function.IsNull() && !function.is_static() &&
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
  const TypeArguments& type_params =
      TypeArguments::Handle(cls.type_parameters());
  ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
         (type_params.Length() == num_type_params));
  // In a first pass, resolve all bounds. This guarantees that finalization
  // of mutually referencing bounds will not encounter an unresolved bound.
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    bound = type_param.bound();
    ResolveType(cls, bound);
  }
}


// Finalize the upper bounds of the type parameters of class cls.
void ClassFinalizer::FinalizeUpperBounds(const Class& cls,
                                         FinalizationKind finalization) {
  const intptr_t num_type_params = cls.NumTypeParameters();
  TypeParameter& type_param = TypeParameter::Handle();
  AbstractType& bound = AbstractType::Handle();
  const TypeArguments& type_params =
      TypeArguments::Handle(cls.type_parameters());
  ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
         (type_params.Length() == num_type_params));
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    bound = type_param.bound();
    // Bound may be finalized, but not canonical yet.
    if (bound.IsCanonical() || bound.IsBeingFinalized()) {
      // A bound involved in F-bounded quantification may form a cycle.
      continue;
    }
    bound = FinalizeType(cls, bound, finalization);
    type_param.set_bound(bound);
  }
}


void ClassFinalizer::ResolveAndFinalizeMemberTypes(const Class& cls) {
  // Note that getters and setters are explicitly listed as such in the list of
  // functions of a class, so we do not need to consider fields as implicitly
  // generating getters and setters.
  // Most overriding conflicts are only static warnings, i.e. they are not
  // reported as compile-time errors by the vm. However, signature conflicts in
  // overrides can be reported if the flag --error_on_bad_override is specified.
  // Static warning examples are:
  // - a static getter 'v' conflicting with an inherited instance setter 'v='.
  // - a static setter 'v=' conflicting with an inherited instance member 'v'.
  // - an instance member 'v' conflicting with an accessible static member 'v'
  //   or 'v=' of a super class (except that an instance method 'v' does not
  //   conflict with an accessible static setter 'v=' of a super class).
  // The compile-time errors we report are:
  // - a static member 'v' conflicting with an inherited instance member 'v'.
  // - a static setter 'v=' conflicting with an inherited instance setter 'v='.
  // - an instance method conflicting with an inherited instance field or
  //   instance getter.
  // - an instance field or instance getter conflicting with an inherited
  //   instance method.

  // Resolve type of fields and check for conflicts in super classes.
  Zone* zone = Thread::Current()->zone();
  Array& array = Array::Handle(zone, cls.fields());
  Field& field = Field::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);
  String& name = String::Handle(zone);
  String& getter_name = String::Handle(zone);
  String& setter_name = String::Handle(zone);
  Class& super_class = Class::Handle(zone);
  const intptr_t num_fields = array.Length();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    type = FinalizeType(cls, type);
    field.SetFieldType(type);
    name = field.name();
    if (field.is_static()) {
      getter_name = Field::GetterSymbol(name);
      super_class = FindSuperOwnerOfInstanceMember(cls, name, getter_name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(cls, field.token_pos(),
                    "static field '%s' of class '%s' conflicts with "
                    "instance member '%s' of super class '%s'",
                    name.ToCString(), class_name.ToCString(), name.ToCString(),
                    super_cls_name.ToCString());
      }
      // An implicit setter is not generated for a static field, therefore, we
      // cannot rely on the code below handling the static setter case to report
      // a conflict with an instance setter. So we check explicitly here.
      setter_name = Field::SetterSymbol(name);
      super_class = FindSuperOwnerOfFunction(cls, setter_name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(cls, field.token_pos(),
                    "static field '%s' of class '%s' conflicts with "
                    "instance setter '%s=' of super class '%s'",
                    name.ToCString(), class_name.ToCString(), name.ToCString(),
                    super_cls_name.ToCString());
      }

    } else {
      // Instance field. Check whether the field overrides a method
      // (but not getter).
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(cls, field.token_pos(),
                    "field '%s' of class '%s' conflicts with method '%s' "
                    "of super class '%s'",
                    name.ToCString(), class_name.ToCString(), name.ToCString(),
                    super_cls_name.ToCString());
      }
    }
    if (field.is_static() && (field.StaticValue() != Object::null()) &&
        (field.StaticValue() != Object::sentinel().raw())) {
      // The parser does not preset the value if the type is a type parameter or
      // is parameterized unless the value is null.
      Error& error = Error::Handle(zone);
      if (type.IsMalformedOrMalbounded()) {
        error = type.error();
      } else {
        ASSERT(type.IsInstantiated());
      }
      const Instance& const_value = Instance::Handle(zone, field.StaticValue());
      if (!error.IsNull() ||
          (!type.IsDynamicType() &&
           !const_value.IsInstanceOf(type, Object::null_type_arguments(),
                                     Object::null_type_arguments(), &error))) {
        if (Isolate::Current()->error_on_bad_type()) {
          const AbstractType& const_value_type =
              AbstractType::Handle(zone, const_value.GetType(Heap::kNew));
          const String& const_value_type_name =
              String::Handle(zone, const_value_type.UserVisibleName());
          const String& type_name =
              String::Handle(zone, type.UserVisibleName());
          ReportErrors(error, cls, field.token_pos(),
                       "error initializing static %s field '%s': "
                       "type '%s' is not a subtype of type '%s'",
                       field.is_const() ? "const" : "final", name.ToCString(),
                       const_value_type_name.ToCString(),
                       type_name.ToCString());
        } else {
          // Do not report an error yet, even in checked mode, since the field
          // may not actually be used.
          // Also, we may be generating a snapshot in production mode that will
          // later be executed in checked mode, in which case an error needs to
          // be reported, should the field be accessed.
          // Therefore, we undo the optimization performed by the parser, i.e.
          // we create an implicit static final getter and reset the field value
          // to the sentinel value.
          const Function& getter = Function::Handle(
              zone, Function::New(
                        getter_name, RawFunction::kImplicitStaticFinalGetter,
                        /* is_static = */ true,
                        /* is_const = */ field.is_const(),
                        /* is_abstract = */ false,
                        /* is_external = */ false,
                        /* is_native = */ false, cls, field.token_pos()));
          getter.set_result_type(type);
          getter.set_is_debuggable(false);
          getter.set_kernel_offset(field.kernel_offset());
          cls.AddFunction(getter);
          field.SetStaticValue(Object::sentinel(), true);
        }
      }
    }
  }
  // If we check for bad overrides, collect interfaces, super interfaces, and
  // super classes of this class.
  GrowableArray<const Class*> interfaces(zone, 4);
  if (Isolate::Current()->error_on_bad_override()) {
    CollectInterfaces(cls, &interfaces);
    // Include superclasses in list of interfaces and super interfaces.
    super_class = cls.SuperClass();
    while (!super_class.IsNull()) {
      interfaces.Add(&Class::ZoneHandle(zone, super_class.raw()));
      CollectInterfaces(super_class, &interfaces);
      super_class = super_class.SuperClass();
    }
  }
  // Resolve function signatures and check for conflicts in super classes and
  // interfaces.
  array = cls.functions();
  Function& function = Function::Handle(zone);
  Function& overridden_function = Function::Handle(zone);
  const intptr_t num_functions = array.Length();
  Error& error = Error::Handle(zone);
  for (intptr_t i = 0; i < num_functions; i++) {
    function ^= array.At(i);
    FinalizeSignature(cls, function);
    name = function.name();
    // Report signature conflicts only.
    if (Isolate::Current()->error_on_bad_override() && !function.is_static() &&
        !function.IsGenerativeConstructor()) {
      // A constructor cannot override anything.
      for (intptr_t i = 0; i < interfaces.length(); i++) {
        const Class* interface = interfaces.At(i);
        // All interfaces should have been finalized since override checks
        // rely on all interface members to be finalized.
        ASSERT(interface->is_finalized());
        overridden_function = interface->LookupDynamicFunction(name);
        if (!overridden_function.IsNull() &&
            !function.HasCompatibleParametersWith(overridden_function,
                                                  &error)) {
          const String& class_name = String::Handle(zone, cls.Name());
          const String& interface_name =
              String::Handle(zone, interface->Name());
          ReportErrors(error, cls, function.token_pos(),
                       "class '%s' overrides method '%s' of super class or "
                       "interface '%s' with incompatible parameters",
                       class_name.ToCString(), name.ToCString(),
                       interface_name.ToCString());
        }
      }
    }
    if (function.IsSetterFunction() || function.IsImplicitSetterFunction()) {
      if (function.is_static()) {
        super_class = FindSuperOwnerOfFunction(cls, name);
        if (!super_class.IsNull()) {
          const String& class_name = String::Handle(zone, cls.Name());
          const String& super_cls_name =
              String::Handle(zone, super_class.Name());
          ReportError(cls, function.token_pos(),
                      "static setter '%s=' of class '%s' conflicts with "
                      "instance setter '%s=' of super class '%s'",
                      name.ToCString(), class_name.ToCString(),
                      name.ToCString(), super_cls_name.ToCString());
        }
      }
      continue;
    }
    if (function.IsGetterFunction() || function.IsImplicitGetterFunction()) {
      getter_name = name.raw();
      name = Field::NameFromGetter(getter_name);
    } else {
      getter_name = Field::GetterSymbol(name);
    }
    if (function.is_static()) {
      super_class = FindSuperOwnerOfInstanceMember(cls, name, getter_name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(
            cls, function.token_pos(),
            "static %s '%s' of class '%s' conflicts with "
            "instance member '%s' of super class '%s'",
            (function.IsGetterFunction() || function.IsImplicitGetterFunction())
                ? "getter"
                : "method",
            name.ToCString(), class_name.ToCString(), name.ToCString(),
            super_cls_name.ToCString());
      }
      if (function.IsRedirectingFactory()) {
        // The function may be a still unresolved redirecting factory. Do not
        // yet try to resolve it in order to avoid cycles in class finalization.
        // However, the redirection type should be finalized.
        // If the redirection type is from a deferred library and is not
        // yet loaded, do not attempt to resolve.
        Type& type = Type::Handle(zone, function.RedirectionType());
        if (IsLoaded(type)) {
          type ^= FinalizeType(cls, type);
          function.SetRedirectionType(type);
        }
      }
    } else if (function.IsGetterFunction() ||
               function.IsImplicitGetterFunction()) {
      super_class = FindSuperOwnerOfFunction(cls, name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(cls, function.token_pos(),
                    "getter '%s' of class '%s' conflicts with "
                    "method '%s' of super class '%s'",
                    name.ToCString(), class_name.ToCString(), name.ToCString(),
                    super_cls_name.ToCString());
      }
    } else if (!function.IsSetterFunction() &&
               !function.IsImplicitSetterFunction()) {
      // A function cannot conflict with a setter, since they cannot
      // have the same name. Thus, we do not need to check setters.
      super_class = FindSuperOwnerOfFunction(cls, getter_name);
      if (!super_class.IsNull()) {
        const String& class_name = String::Handle(zone, cls.Name());
        const String& super_cls_name = String::Handle(zone, super_class.Name());
        ReportError(cls, function.token_pos(),
                    "method '%s' of class '%s' conflicts with "
                    "getter '%s' of super class '%s'",
                    name.ToCString(), class_name.ToCString(), name.ToCString(),
                    super_cls_name.ToCString());
      }
    }
  }
}


// Clone the type parameters of the super class and of the mixin class of this
// mixin application class and use them as the type parameters of this mixin
// application class. Set the type arguments of the super type, of the mixin
// type (as well as of the interface type, which is identical to the mixin type)
// to refer to the respective type parameters of the mixin application class.
// In other words, decorate this mixin application class with type parameters
// that forward to the super type and mixin type (and interface type).
// Example:
//   class S<T extends BT> { }
//   class M<T extends BT> { }
//   class C<E extends BE> extends S<E> with M<List<E>> { }
// results in
//   class S&M<T`, T extends BT> extends S<T`> implements M<T> { }
//   class C<E extends BE> extends S&M<E, List<E>> { }
// CloneMixinAppTypeParameters decorates class S&M with type parameters T` and
// T, and use them as type arguments in S<T`> and M<T>.
// Note that the bound BT on T of S is not applied to T` of S&M. However, the
// bound BT on T of M is applied to T of S&M. See comments below.
void ClassFinalizer::CloneMixinAppTypeParameters(const Class& mixin_app_class) {
  ASSERT(mixin_app_class.type_parameters() == TypeArguments::null());
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const AbstractType& super_type =
      AbstractType::Handle(zone, mixin_app_class.super_type());
  ASSERT(super_type.IsResolved());
  const Class& super_class = Class::Handle(zone, super_type.type_class());
  const intptr_t num_super_type_params = super_class.NumTypeParameters();
  const Type& mixin_type = Type::Handle(zone, mixin_app_class.mixin());
  const Class& mixin_class = Class::Handle(zone, mixin_type.type_class());
  const intptr_t num_mixin_type_params = mixin_class.NumTypeParameters();

  // The mixin type (in raw form) should have been added to the interfaces
  // implemented by the mixin application class. This is necessary so that cycle
  // check works at compile time (type arguments are ignored) and so that
  // type tests work at runtime (by then, type arguments will have been set, see
  // below).
  ASSERT(mixin_app_class.interfaces() != Object::empty_array().raw());

  // If both the super type and the mixin type are non generic, the mixin
  // application class is non generic as well and we can skip type parameter
  // cloning.
  TypeArguments& instantiator = TypeArguments::Handle(zone);
  if ((num_super_type_params + num_mixin_type_params) > 0) {
    // If the last ampersand in the name of the mixin application class is
    // doubled, the same type parameters can propagate the type arguments to
    // the super type and to the mixin type.
    bool share_type_params = false;
    if (num_super_type_params == num_mixin_type_params) {
      const String& name = String::Handle(zone, mixin_app_class.Name());
      for (intptr_t i = name.Length() - 1; i > 0; --i) {
        if (name.CharAt(i) == '&') {
          if (name.CharAt(i - 1) == '&') {
            share_type_params = true;
          }
          break;
        }
      }
    }

    const TypeArguments& cloned_type_params = TypeArguments::Handle(
        zone,
        TypeArguments::New((share_type_params ? 0 : num_super_type_params) +
                           num_mixin_type_params));
    TypeParameter& param = TypeParameter::Handle(zone);
    TypeParameter& cloned_param = TypeParameter::Handle(zone);
    String& param_name = String::Handle(zone);
    AbstractType& param_bound = AbstractType::Handle(zone);
    Function& null_function = Function::Handle(zone);
    intptr_t cloned_index = 0;

    // First, clone the super class type parameters. Rename them so that
    // there can be no name conflict between the parameters of the super
    // class and the mixin class.
    if (!share_type_params && (num_super_type_params > 0)) {
      const TypeArguments& super_type_params =
          TypeArguments::Handle(zone, super_class.type_parameters());
      const TypeArguments& super_type_args = TypeArguments::Handle(
          zone, TypeArguments::New(num_super_type_params));
      // The cloned super class type parameters do not need to repeat their
      // bounds, since the bound checks will be performed at the super class
      // level. As a consequence, if this mixin application is used itself as a
      // mixin in another mixin application, the bounds will be ignored, which
      // is correct, because the other mixin application does not inherit from
      // the super class of its mixin. Note also that the other mixin
      // application will only mixin the last mixin type listed in the first
      // mixin application it is mixing in.
      param_bound = thread->isolate()->object_store()->object_type();
      for (intptr_t i = 0; i < num_super_type_params; i++) {
        param ^= super_type_params.TypeAt(i);
        param_name = param.name();
        param_name =
            Symbols::FromConcat(thread, param_name, Symbols::Backtick());
        cloned_param =
            TypeParameter::New(mixin_app_class, null_function, cloned_index,
                               param_name, param_bound, param.token_pos());
        cloned_type_params.SetTypeAt(cloned_index, cloned_param);
        // Change the type arguments of the super type to refer to the
        // cloned type parameters of the mixin application class.
        super_type_args.SetTypeAt(cloned_index, cloned_param);
        cloned_index++;
      }
      // The super type may have a BoundedType as type argument, but cannot be
      // a BoundedType itself.
      Type::Cast(super_type).set_arguments(super_type_args);
      ASSERT(!super_type.IsFinalized());
    }

    // Second, clone the type parameters of the mixin class.
    // We need to retain the parameter names of the mixin class
    // since the code that will be compiled in the context of the
    // mixin application class may refer to the type parameters
    // with that name. We also retain the type parameter bounds.
    if (num_mixin_type_params > 0) {
      const TypeArguments& mixin_params =
          TypeArguments::Handle(zone, mixin_class.type_parameters());
      const intptr_t offset =
          mixin_class.NumTypeArguments() - mixin_class.NumTypeParameters();
      const TypeArguments& mixin_type_args = TypeArguments::Handle(
          zone, TypeArguments::New(num_mixin_type_params));
      instantiator ^= TypeArguments::New(offset + num_mixin_type_params);
      bool has_uninstantiated_bounds = false;
      for (intptr_t i = 0; i < num_mixin_type_params; i++) {
        param ^= mixin_params.TypeAt(i);
        param_name = param.name();
        param_bound = param.bound();  // The bound will be adjusted below.
        if (!param_bound.IsInstantiated()) {
          has_uninstantiated_bounds = true;
        }
        cloned_param =
            TypeParameter::New(mixin_app_class, null_function,
                               cloned_index,  // Unfinalized index.
                               param_name, param_bound, param.token_pos());
        cloned_type_params.SetTypeAt(cloned_index, cloned_param);
        mixin_type_args.SetTypeAt(i, cloned_param);  // Unfinalized length.
        instantiator.SetTypeAt(offset + i, cloned_param);  // Finalized length.
        cloned_index++;
      }

      // Third, replace the type parameters appearing in the bounds of the mixin
      // type parameters, if any, by the cloned type parameters. This can be
      // done by instantiating each bound using the instantiator built above.
      // If the mixin class extends a generic super class, its first finalized
      // type parameter has a non-zero index, therefore, the instantiator
      // requires shifting by the offset calculated above.
      // Unfinalized type parameters replace finalized type parameters, which
      // is not a problem since they will get finalized shortly as the mixin
      // application class gets finalized.
      if (has_uninstantiated_bounds) {
        Error& bound_error = Error::Handle(zone);
        for (intptr_t i = 0; i < num_mixin_type_params; i++) {
          param ^= mixin_type_args.TypeAt(i);
          param_bound = param.bound();
          if (!param_bound.IsInstantiated()) {
            // Make sure the bound is finalized before instantiating it.
            if (!param_bound.IsFinalized() && !param_bound.IsBeingFinalized()) {
              param_bound = FinalizeType(mixin_app_class, param_bound);
              param.set_bound(param_bound);  // In case part of recursive type.
            }
            param_bound = param_bound.InstantiateFrom(
                instantiator, Object::null_type_arguments(), &bound_error, NULL,
                NULL, Heap::kOld);
            // The instantiator contains only TypeParameter objects and no
            // BoundedType objects, so no bound error may occur.
            ASSERT(!param_bound.IsBoundedType());
            ASSERT(bound_error.IsNull());
            ASSERT(!param_bound.IsInstantiated());
            param.set_bound(param_bound);
          }
        }
      }

      // Lastly, set the type arguments of the mixin type, which is also the
      // single interface type.
      ASSERT(!mixin_type.IsFinalized());
      mixin_type.set_arguments(mixin_type_args);
      if (share_type_params) {
        Type::Cast(super_type).set_arguments(mixin_type_args);
        ASSERT(!super_type.IsFinalized());
      }
    }
    mixin_app_class.set_type_parameters(cloned_type_params);
  }
  // If the mixin class is a mixin application alias class, we insert a new
  // synthesized mixin application class in the super chain of this mixin
  // application class. The new class will have the aliased mixin as actual
  // mixin.
  if (mixin_class.is_mixin_app_alias()) {
    ApplyMixinAppAlias(mixin_app_class, instantiator);
  }
}


/* Support for mixin alias.
Consider the following example:

class I<T> { }
class J<T> { }
class S<T extends num> { }
class M<T extends Map> { }
class A<U, V extends List> = Object with M<Map<U, V>> implements I<V>;
class C<T, K extends T> = S<T> with A<T, List<K>> implements J<K>;

Before the call to ApplyMixinAppAlias, the VM has already synthesized 2 mixin
application classes Object&M and S&A:

Object&M<T extends Map> extends Object implements M<T> {
  ... members of M applied here ...
}
A<U, V extends List> extends Object&M<Map<U, V>> implements I<V> { }

S&A<T`, U, V extends List> extends S<T`> implements A<U, V> {
  ... members of A applied here, but A has no members ...
}
C<T, K extends T> extends S&A<T, T, List<K>> implements J<K> { }

In theory, class A should be an alias of Object&M instead of extending it.
In practice, the additional class provides a hook for implemented interfaces
(e.g. I<V>) and for type argument substitution via the super type relation (e.g.
type parameter T of Object&M is substituted with Map<U, V>, U and V being the
type parameters of the alias A).

Similarly, class C should be an alias of S&A instead of extending it.

Now, A does not have any members to be mixed into S&A, because A is an alias.
The members to be mixed in are actually those of M, and they should appear in a
scope where the type parameter T is visible. The class S&A declares the type
parameters of A, i.e. U and V, but not T.

Therefore, the call to ApplyMixinAppAlias inserts another synthesized class S&A`
as the superclass of S&A. The class S&A` declares a type argument T:

Instead of
S&A<T`, U, V extends List> extends S<T`> implements A<U, V> { }

We now have:
S&A`<T`, T extends Map> extends S<T`> implements M<T> {
  ... members of M applied here ...
}
S&A<T`, U, V extends List> extends S&A`<T`, Map<U, V>> implements A<U, V> { }

The main implementation difficulty resides in the fact that the type parameters
U and V in the super type S&A`<T`, Map<U, V>> of S&A must refer to the type
parameters U and V of S&A. However, Map<U, V> is copied from the super type
Object&M<Map<U, V>> of A and, therefore, U and V refer to A. An instantiation
step with a properly crafted instantiator vector takes care of the required type
parameter substitution.
The instantiator vector must end with the type parameters U and V of S&A.
The offset in the instantiator of the type parameter U of S&A must be at the
finalized index of type parameter U of A.

The same instantiator vector is used to adjust the type parameter bounds on U
and V, if any. This step is done in CloneMixinAppTypeParameters above, and the
already built instantiator is passed here.

Also, a possible bound on type parameter T of M must be applied to type
parameter T of S&A`. If the bound is uninstantiated, i.e. if it refers to T or
other type parameters of M, an instantiation step is required to substitute
these type parameters of M with type parameters of S&A`.
The instantiator vector consists of the cloned type parameters of M shifted by
an offset corresponding to the finalized index of the first type parameter of M.
This is done in the recursive call to CloneMixinAppTypeParameters and does not
require specific code in ApplyMixinAppAlias.
*/
void ClassFinalizer::ApplyMixinAppAlias(const Class& mixin_app_class,
                                        const TypeArguments& instantiator) {
  // If this mixin alias is aliasing another mixin alias, another class
  // will be inserted via recursion. No need to check here.
  // The mixin type may or may not be finalized yet.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  AbstractType& super_type =
      AbstractType::Handle(zone, mixin_app_class.super_type());
  const Type& mixin_type = Type::Handle(zone, mixin_app_class.mixin());
  const Class& mixin_class = Class::Handle(zone, mixin_type.type_class());
  ASSERT(mixin_class.is_mixin_app_alias());
  const Class& aliased_mixin_app_class =
      Class::Handle(zone, mixin_class.SuperClass());
  // Note that the super class of aliased_mixin_app_class can itself be a
  // mixin application class (this happens if the alias is mixing more than one
  // type). Instead of trying to recursively insert yet another class as the
  // super class of this inserted class, we apply the composition rules of the
  // spec and only mixin the members of aliased_mixin_app_class, not those of
  // its super class. In other words, we only mixin the last mixin of the alias.
  const Type& aliased_mixin_type =
      Type::Handle(zone, aliased_mixin_app_class.mixin());
  // The name of the inserted mixin application class is the name of mixin
  // class name with a backtick added.
  String& inserted_class_name = String::Handle(zone, mixin_app_class.Name());
  inserted_class_name =
      String::Concat(inserted_class_name, Symbols::Backtick());
  const Library& library = Library::Handle(zone, mixin_app_class.library());
  Class& inserted_class =
      Class::Handle(zone, library.LookupLocalClass(inserted_class_name));
  if (inserted_class.IsNull()) {
    inserted_class_name = Symbols::New(thread, inserted_class_name);
    const Script& script = Script::Handle(zone, mixin_app_class.script());
    inserted_class = Class::New(library, inserted_class_name, script,
                                mixin_app_class.token_pos());
    inserted_class.set_is_synthesized_class();
    library.AddClass(inserted_class);

    if (FLAG_trace_class_finalization) {
      THR_Print("Creating mixin application alias %s\n",
                inserted_class.ToCString());
    }

    // The super type of the inserted class is identical to the super type of
    // this mixin application class, except that it must refer to the type
    // parameters of the inserted class rather than to those of the mixin
    // application class.
    // The type arguments of the super type will be set properly when calling
    // CloneMixinAppTypeParameters on the inserted class, as long as the super
    // type class is set properly.
    inserted_class.set_super_type(super_type);  // Super class only is used.

    // The mixin type and interface type must also be set before calling
    // CloneMixinAppTypeParameters.
    // After FinalizeTypesInClass, if the mixin type and interface type are
    // generic, their type arguments will refer to the type parameters of
    // inserted_class.
    const Type& inserted_class_mixin_type = Type::Handle(
        zone, Type::New(Class::Handle(zone, aliased_mixin_type.type_class()),
                        Object::null_type_arguments(),
                        aliased_mixin_type.token_pos()));
    inserted_class.set_mixin(inserted_class_mixin_type);
    // Add the mixin type to the list of interfaces that the mixin application
    // class implements. This is necessary so that cycle check work at
    // compile time (type arguments are ignored by that check).
    const Array& interfaces = Array::Handle(Array::New(1));
    interfaces.SetAt(0, inserted_class_mixin_type);
    ASSERT(inserted_class.interfaces() == Object::empty_array().raw());
    inserted_class.set_interfaces(interfaces);
    // The type arguments of the interface, if any, will be set in
    // CloneMixinAppTypeParameters, which is called indirectly from
    // FinalizeTypesInClass below.
  }

  // Finalize the types and call CloneMixinAppTypeParameters.
  FinalizeTypesInClass(inserted_class);

  // The super type of this mixin application class must point to the
  // inserted class. The super type arguments are the concatenation of the
  // old super type arguments (propagating type arguments to the super class)
  // with new type arguments providing type arguments to the mixin.
  // The appended type arguments are those of the super type of the mixin
  // application alias that are forwarding to the aliased mixin type, except
  // that they must refer to the type parameters of the mixin application
  // class rather than to those of the mixin application alias class.
  // This type parameter substitution is performed by an instantiation step.
  // It is important that the type parameters of the mixin application class
  // are not finalized yet, because new type parameters may have been added
  // to the super class.
  const Class& super_class = Class::Handle(zone, super_type.type_class());
  ASSERT(mixin_app_class.SuperClass() == super_class.raw());  // Will change.
  const intptr_t num_super_type_params = super_class.NumTypeParameters();
  AbstractType& type = AbstractType::Handle(zone);
  // The instantiator is mapping finalized type parameters of mixin_class to
  // unfinalized type parameters of mixin_app_class. Therefore, the type
  // arguments of mixin_class_super_type must be finalized, since they get
  // instantiated by this instantiator. Finalizing the types in mixin_class
  // will finalize mixin_class_super_type.
  // The aliased_mixin_type does not need to be finalized, but only resolved.
  ASSERT(aliased_mixin_type.IsResolved());
  const Class& aliased_mixin_type_class =
      Class::Handle(zone, aliased_mixin_type.type_class());
  FinalizeTypesInClass(mixin_class);
  const intptr_t num_aliased_mixin_type_params =
      aliased_mixin_type_class.NumTypeParameters();
  ASSERT(inserted_class.NumTypeParameters() ==
         (num_super_type_params + num_aliased_mixin_type_params));
  const AbstractType& mixin_class_super_type =
      AbstractType::Handle(zone, mixin_class.super_type());
  ASSERT(mixin_class_super_type.IsFinalized());
  // The aliased_mixin_type may be raw.
  const TypeArguments& mixin_class_super_type_args =
      TypeArguments::Handle(zone, mixin_class_super_type.arguments());
  TypeArguments& new_mixin_type_args = TypeArguments::Handle(zone);
  if ((num_aliased_mixin_type_params > 0) &&
      !mixin_class_super_type_args.IsNull()) {
    new_mixin_type_args = TypeArguments::New(num_aliased_mixin_type_params);
    AbstractType& bounded_type = AbstractType::Handle(zone);
    AbstractType& upper_bound = AbstractType::Handle(zone);
    TypeParameter& type_parameter = TypeParameter::Handle(zone);
    Error& bound_error = Error::Handle(zone);
    const intptr_t offset =
        mixin_class_super_type_args.Length() - num_aliased_mixin_type_params;
    for (intptr_t i = 0; i < num_aliased_mixin_type_params; i++) {
      type = mixin_class_super_type_args.TypeAt(offset + i);
      if (!type.IsInstantiated()) {
        // In the presence of bounds, the bounded type and the upper bound must
        // be instantiated separately. Instantiating a BoundedType would wrap
        // the BoundedType in another BoundedType.
        if (type.IsBoundedType()) {
          bounded_type = BoundedType::Cast(type).type();
          bounded_type = bounded_type.InstantiateFrom(
              instantiator, Object::null_type_arguments(), &bound_error, NULL,
              NULL, Heap::kOld);
          // The instantiator contains only TypeParameter objects and no
          // BoundedType objects, so no bound error may occur.
          ASSERT(bound_error.IsNull());
          upper_bound = BoundedType::Cast(type).bound();
          upper_bound = upper_bound.InstantiateFrom(
              instantiator, Object::null_type_arguments(), &bound_error, NULL,
              NULL, Heap::kOld);
          ASSERT(bound_error.IsNull());
          type_parameter = BoundedType::Cast(type).type_parameter();
          // The type parameter that declared the bound does not change.
          type = BoundedType::New(bounded_type, upper_bound, type_parameter);
        } else {
          type =
              type.InstantiateFrom(instantiator, Object::null_type_arguments(),
                                   &bound_error, NULL, NULL, Heap::kOld);
          ASSERT(bound_error.IsNull());
        }
      }
      new_mixin_type_args.SetTypeAt(i, type);
    }
  }
  TypeArguments& new_super_type_args = TypeArguments::Handle(zone);
  if ((num_super_type_params + num_aliased_mixin_type_params) > 0) {
    new_super_type_args = TypeArguments::New(num_super_type_params +
                                             num_aliased_mixin_type_params);
    const TypeArguments& type_params =
        TypeArguments::Handle(zone, mixin_app_class.type_parameters());
    for (intptr_t i = 0; i < num_super_type_params; i++) {
      type = type_params.TypeAt(i);
      new_super_type_args.SetTypeAt(i, type);
    }
    for (intptr_t i = 0; i < num_aliased_mixin_type_params; i++) {
      if (new_mixin_type_args.IsNull()) {
        type = Type::DynamicType();
      } else {
        type = new_mixin_type_args.TypeAt(i);
      }
      new_super_type_args.SetTypeAt(num_super_type_params + i, type);
    }
  }
  super_type = Type::New(inserted_class, new_super_type_args,
                         mixin_app_class.token_pos());
  mixin_app_class.set_super_type(super_type);

  // Mark this mixin application class as being an alias.
  mixin_app_class.set_is_mixin_app_alias();
  ASSERT(!mixin_app_class.is_type_finalized());
  ASSERT(!mixin_app_class.is_mixin_type_applied());
  if (FLAG_trace_class_finalization) {
    THR_Print(
        "Inserting class '%s' %s\n"
        "  as super type '%s' with %" Pd
        " type args: %s\n"
        "  of mixin application alias '%s' %s\n",
        String::Handle(inserted_class.Name()).ToCString(),
        TypeArguments::Handle(inserted_class.type_parameters()).ToCString(),
        String::Handle(zone, super_type.Name()).ToCString(),
        num_super_type_params + num_aliased_mixin_type_params,
        super_type.ToCString(),
        String::Handle(mixin_app_class.Name()).ToCString(),
        TypeArguments::Handle(mixin_app_class.type_parameters()).ToCString());
  }
}


void ClassFinalizer::ApplyMixinType(const Class& mixin_app_class,
                                    PendingTypes* pending_types) {
  if (mixin_app_class.is_mixin_type_applied()) {
    return;
  }
  Type& mixin_type = Type::Handle(mixin_app_class.mixin());
  ASSERT(!mixin_type.IsNull());
  ASSERT(mixin_type.HasResolvedTypeClass());
  const Class& mixin_class = Class::Handle(mixin_type.type_class());

  if (FLAG_trace_class_finalization) {
    THR_Print("Applying mixin type '%s' to %s at pos %s\n",
              String::Handle(mixin_type.Name()).ToCString(),
              mixin_app_class.ToCString(),
              mixin_app_class.token_pos().ToCString());
  }

  // Check for illegal self references.
  GrowableArray<intptr_t> visited_mixins;
  if (!IsMixinCycleFree(mixin_class, &visited_mixins)) {
    const String& class_name = String::Handle(mixin_class.Name());
    ReportError(mixin_class, mixin_class.token_pos(),
                "mixin class '%s' illegally refers to itself",
                class_name.ToCString());
  }

  // Copy type parameters to mixin application class.
  CloneMixinAppTypeParameters(mixin_app_class);

  // Verify that no restricted class is used as a mixin by checking the
  // interfaces of the mixin application class, which implements its mixin.
  GrowableArray<intptr_t> visited_interfaces;
  ResolveSuperTypeAndInterfaces(mixin_app_class, &visited_interfaces);

  if (FLAG_trace_class_finalization) {
    THR_Print(
        "Done applying mixin type '%s' to class '%s' %s extending '%s'\n",
        String::Handle(mixin_type.Name()).ToCString(),
        String::Handle(mixin_app_class.Name()).ToCString(),
        TypeArguments::Handle(mixin_app_class.type_parameters()).ToCString(),
        AbstractType::Handle(mixin_app_class.super_type()).ToCString());
  }
  // Mark the application class as having been applied its mixin type in order
  // to avoid cycles while finalizing its mixin type.
  mixin_app_class.set_is_mixin_type_applied();
  // Finalize the mixin type, which may have been changed in case
  // mixin_app_class is an alias.
  mixin_type = mixin_app_class.mixin();
  ASSERT(!mixin_type.IsBeingFinalized());
  mixin_type ^=
      FinalizeType(mixin_app_class, mixin_type, kFinalize, pending_types);
  // The mixin type cannot be malbounded, since it merely substitutes the
  // type parameters of the mixin class with those of the mixin application
  // class, but it does not instantiate them.
  ASSERT(!mixin_type.IsMalbounded());
  mixin_app_class.set_mixin(mixin_type);
}


void ClassFinalizer::CreateForwardingConstructors(
    const Class& mixin_app,
    const Class& mixin_cls,
    const GrowableObjectArray& cloned_funcs) {
  Thread* T = Thread::Current();
  Zone* Z = T->zone();
  const String& mixin_name = String::Handle(Z, mixin_app.Name());
  const Class& super_class = Class::Handle(Z, mixin_app.SuperClass());
  const String& super_name = String::Handle(Z, super_class.Name());
  const Array& functions = Array::Handle(Z, super_class.functions());
  const intptr_t num_functions = functions.Length();
  Function& func = Function::Handle(Z);
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.IsGenerativeConstructor()) {
      // Build constructor name from mixin application class name
      // and name of cloned super class constructor.
      const String& ctor_name = String::Handle(Z, func.name());
      String& clone_name =
          String::Handle(Z, String::SubString(ctor_name, super_name.Length()));
      clone_name = Symbols::FromConcat(T, mixin_name, clone_name);

      if (FLAG_trace_class_finalization) {
        THR_Print("Cloning constructor '%s' as '%s'\n", ctor_name.ToCString(),
                  clone_name.ToCString());
      }

      // The owner of the forwarding constructor is the mixin application
      // class. The source is the mixin class. The source may be needed
      // to parse field initializer expressions in the mixin class.
      const PatchClass& owner =
          PatchClass::Handle(Z, PatchClass::New(mixin_app, mixin_cls));

      const Function& clone = Function::Handle(
          Z, Function::New(clone_name, func.kind(), func.is_static(),
                           false,  // Not const.
                           false,  // Not abstract.
                           false,  // Not external.
                           false,  // Not native.
                           owner, mixin_cls.token_pos()));
      clone.set_num_fixed_parameters(func.num_fixed_parameters());
      clone.SetNumOptionalParameters(func.NumOptionalParameters(),
                                     func.HasOptionalPositionalParameters());
      clone.set_result_type(Object::dynamic_type());
      clone.set_is_debuggable(false);

      const intptr_t num_parameters = func.NumParameters();
      // The cloned ctor shares the parameter names array with the
      // original.
      const Array& parameter_names = Array::Handle(Z, func.parameter_names());
      ASSERT(parameter_names.Length() == num_parameters);
      clone.set_parameter_names(parameter_names);
      // The parameter types of the cloned constructor are 'dynamic'.
      clone.set_parameter_types(Array::Handle(Z, Array::New(num_parameters)));
      for (intptr_t n = 0; n < num_parameters; n++) {
        clone.SetParameterTypeAt(n, Object::dynamic_type());
      }
      cloned_funcs.Add(clone);
    }
  }
}


void ClassFinalizer::ApplyMixinMembers(const Class& cls) {
  Zone* zone = Thread::Current()->zone();
  const Type& mixin_type = Type::Handle(zone, cls.mixin());
  ASSERT(!mixin_type.IsNull());
  ASSERT(mixin_type.HasResolvedTypeClass());
  const Class& mixin_cls = Class::Handle(zone, mixin_type.type_class());
  FinalizeClass(mixin_cls);
  // If the mixin is a mixin application alias class, there are no members to
  // apply here. A new synthesized class representing the aliased mixin
  // application class was inserted in the super chain of this mixin application
  // class. Members of the actual mixin class will be applied when visiting
  // the mixin application class referring to the actual mixin.
  ASSERT(!mixin_cls.is_mixin_app_alias() ||
         Class::Handle(zone, cls.SuperClass()).IsMixinApplication());
  // A default constructor will be created for the mixin app alias class.

  if (FLAG_trace_class_finalization) {
    THR_Print("Applying mixin members of %s to %s at pos %s\n",
              mixin_cls.ToCString(), cls.ToCString(),
              cls.token_pos().ToCString());
  }

  const GrowableObjectArray& cloned_funcs =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());

  Array& functions = Array::Handle(zone);
  Function& func = Function::Handle(zone);

  // The parser creates the mixin application class with no functions.
  // But the Kernel frontend will generate mixin classes with only
  // constructors inside them, which forward to the base class constructors.
  //
  // => We generate the constructors if they are not already there.
  functions = cls.functions();
  if (functions.Length() == 0) {
    CreateForwardingConstructors(cls, mixin_cls, cloned_funcs);
  } else {
    for (intptr_t i = 0; i < functions.Length(); i++) {
      func ^= functions.At(i);
      ASSERT(func.kernel_offset() > 0);
      cloned_funcs.Add(func);
    }
  }

  // Now clone the functions from the mixin class.
  functions = mixin_cls.functions();
  const intptr_t num_functions = functions.Length();
  for (intptr_t i = 0; i < num_functions; i++) {
    func ^= functions.At(i);
    if (func.IsGenerativeConstructor()) {
      // A mixin class must not have explicit constructors.
      if (!func.IsImplicitConstructor()) {
        const Script& script = Script::Handle(cls.script());
        const Error& error = Error::Handle(LanguageError::NewFormatted(
            Error::Handle(), script, func.token_pos(), Report::AtLocation,
            Report::kError, Heap::kNew,
            "constructor '%s' is illegal in mixin class %s",
            String::Handle(func.UserVisibleName()).ToCString(),
            String::Handle(zone, mixin_cls.Name()).ToCString()));

        ReportErrors(error, cls, cls.token_pos(),
                     "mixin class '%s' must not have constructors",
                     String::Handle(zone, mixin_cls.Name()).ToCString());
      }
      continue;  // Skip the implicit constructor.
    }
    if (!func.is_static() && !func.IsMethodExtractor() &&
        !func.IsNoSuchMethodDispatcher() && !func.IsInvokeFieldDispatcher()) {
      func = func.Clone(cls);
      cloned_funcs.Add(func);
    }
  }
  functions = Array::MakeArray(cloned_funcs);
  cls.SetFunctions(functions);

  // Now clone the fields from the mixin class. There should be no
  // existing fields in the mixin application class.
  ASSERT(Array::Handle(cls.fields()).Length() == 0);
  const Array& fields = Array::Handle(zone, mixin_cls.fields());
  const intptr_t num_fields = fields.Length();
  Field& field = Field::Handle(zone);
  GrowableArray<const Field*> cloned_fields(num_fields);
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= fields.At(i);
    // Static fields are shared between the mixin class and the mixin
    // application class.
    if (!field.is_static()) {
      const Field& cloned = Field::ZoneHandle(zone, field.Clone(cls));
      cloned_fields.Add(&cloned);
    }
  }
  cls.AddFields(cloned_fields);

  if (FLAG_trace_class_finalization) {
    THR_Print("Done applying mixin members of %s to %s\n",
              mixin_cls.ToCString(), cls.ToCString());
  }
}


void ClassFinalizer::FinalizeTypesInClass(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  if (cls.is_type_finalized()) {
    return;
  }
  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize types in %s\n", cls.ToCString());
  }
  if (!IsSuperCycleFree(cls)) {
    const String& name = String::Handle(cls.Name());
    ReportError(cls, cls.token_pos(),
                "class '%s' has a cycle in its superclass relationship",
                name.ToCString());
  }
  // Finalize super class.
  Class& super_class = Class::Handle(cls.SuperClass());
  if (!super_class.IsNull()) {
    FinalizeTypesInClass(super_class);
  }
  // Finalize type parameters before finalizing the super type.
  FinalizeTypeParameters(cls);  // May change super type while applying mixin.
  super_class = cls.SuperClass();  // Get again possibly changed super class.
  ASSERT(super_class.IsNull() || super_class.is_type_finalized());
  // Only resolving rather than finalizing the upper bounds here would result in
  // instantiated type parameters of the super type to temporarily have
  // unfinalized bounds. It is more efficient to finalize them early.
  // Finalize bounds even if running in production mode, so that a snapshot
  // contains them.
  FinalizeUpperBounds(cls);
  // Finalize super type.
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    // In case of a bound error in the super type in production mode, the
    // finalized super type will have a BoundedType as type argument for the
    // out of bound type argument.
    // It should not be a problem if the class is written to a snapshot and
    // later executed in checked mode. Note that the finalized type argument
    // vector of any type of the base class will contain a BoundedType for the
    // out of bound type argument.
    super_type = FinalizeType(cls, super_type);
    cls.set_super_type(super_type);
  }
  // Finalize mixin type.
  Type& mixin_type = Type::Handle(cls.mixin());
  if (!mixin_type.IsNull()) {
    mixin_type ^= FinalizeType(cls, mixin_type);
    cls.set_mixin(mixin_type);
  }
  if (cls.IsTypedefClass()) {
    Function& signature = Function::Handle(cls.signature_function());
    Type& type = Type::Handle(signature.SignatureType());
    ASSERT(type.signature() == signature.raw());

    // Check for illegal self references.
    GrowableArray<intptr_t> visited_aliases;
    if (!IsTypedefCycleFree(cls, type, &visited_aliases)) {
      const String& name = String::Handle(cls.Name());
      ReportError(cls, cls.token_pos(),
                  "typedef '%s' illegally refers to itself", name.ToCString());
    }
    cls.set_is_type_finalized();

    // Resolve and finalize the result and parameter types of the signature
    // function of this typedef class.
    FinalizeSignature(cls, signature);  // Does not modify signature type.
    ASSERT(signature.SignatureType() == type.raw());

    // Resolve and finalize the signature type of this typedef.
    type ^= FinalizeType(cls, type);

    // If a different canonical signature type is returned, update the signature
    // function of the typedef.
    signature = type.signature();
    signature.SetSignatureType(type);
    cls.set_signature_function(signature);

    // Closure instances do not refer to this typedef as their class, so there
    // is no need to add this typedef class to the subclasses of _Closure.
    ASSERT(super_type.IsNull() || super_type.IsObjectType());

    return;
  }

  // Finalize interface types (but not necessarily interface classes).
  Array& interface_types = Array::Handle(cls.interfaces());
  AbstractType& interface_type = AbstractType::Handle();
  AbstractType& seen_interf = AbstractType::Handle();
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    interface_type = FinalizeType(cls, interface_type);
    interface_types.SetAt(i, interface_type);

    // Check whether the interface is duplicated. We need to wait with
    // this check until the super type and interface types are finalized,
    // so that we can use Type::Equals() for the test.
    // TODO(regis): This restriction about duplicated interfaces may get lifted.
    ASSERT(interface_type.IsFinalized());
    ASSERT(super_type.IsNull() || super_type.IsFinalized());
    if (!super_type.IsNull() && interface_type.Equals(super_type)) {
      ReportError(cls, cls.token_pos(),
                  "super type '%s' may not be listed in "
                  "implements clause of class '%s'",
                  String::Handle(super_type.Name()).ToCString(),
                  String::Handle(cls.Name()).ToCString());
    }
    for (intptr_t j = 0; j < i; j++) {
      seen_interf ^= interface_types.At(j);
      if (interface_type.Equals(seen_interf)) {
        ReportError(cls, cls.token_pos(),
                    "interface '%s' appears twice in "
                    "implements clause of class '%s'",
                    String::Handle(interface_type.Name()).ToCString(),
                    String::Handle(cls.Name()).ToCString());
      }
    }
  }
  // Mark as type finalized before resolving type parameter upper bounds
  // in order to break cycles.
  cls.set_is_type_finalized();
  // Add this class to the direct subclasses of the superclass, unless the
  // superclass is Object.
  if (!super_type.IsNull() && !super_type.IsObjectType()) {
    ASSERT(!super_class.IsNull());
    super_class.AddDirectSubclass(cls);
  }
  // A top level class is parsed eagerly so just finalize it.
  if (cls.IsTopLevel()) {
    FinalizeClass(cls);
  } else {
    // This class should not contain any functions or user-defined fields yet,
    // because it has not been compiled yet. There may however be metadata
    // fields because type parameters are parsed before the class body. Since
    // 'ResolveAndFinalizeMemberTypes(cls)' has not been called yet, unfinalized
    // member types could choke the snapshotter.
    // Or
    // if the class is being refinalized because a patch is being applied
    // after the class has been finalized then it is ok for the class to have
    // functions.
    //
    // TODO(kmillikin): This ASSERT will fail when bootstrapping from Kernel
    // because classes are first created, methods are added, and then classes
    // are finalized.  It is not easy to finalize classes earlier because not
    // all bootstrap classes have been created yet.  It would be possible to
    // create all classes, delay adding methods, finalize the classes, and then
    // reprocess all classes to add methods, but that seems unnecessary.
    // Marking the bootstrap classes as is_refinalize_after_patch seems cute but
    // it causes other things to fail by violating their assumptions.  Reenable
    // this ASSERT if it's important, remove it if it's just a sanity check and
    // not required for correctness.
    //
    // ASSERT((Array::Handle(cls.functions()).Length() == 0) ||
    //        cls.is_refinalize_after_patch());
  }
}


void ClassFinalizer::FinalizeClass(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  ASSERT(cls.is_type_finalized());
  if (cls.is_finalized()) {
    return;
  }
  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize %s\n", cls.ToCString());
  }
  if (cls.is_patch()) {
    // The fields and functions of a patch class are copied to the
    // patched class after parsing. There is nothing to finalize.
    ASSERT(Array::Handle(cls.functions()).Length() == 0);
    ASSERT(Array::Handle(cls.fields()).Length() == 0);
    cls.set_is_finalized();
    return;
  }
  // Ensure super class is finalized.
  const Class& super = Class::Handle(cls.SuperClass());
  if (!super.IsNull()) {
    FinalizeClass(super);
  }
  // Ensure interfaces are finalized in case we check for bad overrides.
  if (Isolate::Current()->error_on_bad_override()) {
    GrowableArray<const Class*> interfaces(4);
    CollectInterfaces(cls, &interfaces);
    for (intptr_t i = 0; i < interfaces.length(); i++) {
      FinalizeClass(*interfaces.At(i));
    }
  }
  if (cls.IsMixinApplication()) {
    // Copy instance methods and fields from the mixin class.
    // This has to happen before the check whether the methods of
    // the class conflict with inherited methods.
    ApplyMixinMembers(cls);
  }
  // Mark as parsed and finalized.
  cls.Finalize();
  // Mixin app alias classes may still lack their forwarding constructor.
  if (cls.is_mixin_app_alias() &&
      (cls.functions() == Object::empty_array().raw())) {
    const GrowableObjectArray& cloned_funcs =
        GrowableObjectArray::Handle(GrowableObjectArray::New());

    const Class& mixin_app_class = Class::Handle(cls.SuperClass());
    const Type& mixin_type = Type::Handle(mixin_app_class.mixin());
    const Class& mixin_cls = Class::Handle(mixin_type.type_class());

    CreateForwardingConstructors(cls, mixin_cls, cloned_funcs);
    const Array& functions = Array::Handle(Array::MakeArray(cloned_funcs));
    cls.SetFunctions(functions);
  }
  // Every class should have at least a constructor, unless it is a top level
  // class or a typedef class. The Kernel frontend does not create an implicit
  // constructor for abstract classes.
  ASSERT(cls.IsTopLevel() || cls.IsTypedefClass() || cls.is_abstract() ||
         (Array::Handle(cls.functions()).Length() > 0));
  // Resolve and finalize all member types.
  ResolveAndFinalizeMemberTypes(cls);
  // Run additional checks after all types are finalized.
  if (cls.is_const()) {
    CheckForLegalConstClass(cls);
  }
  if (FLAG_use_cha_deopt) {
    GrowableArray<intptr_t> cids;
    CollectFinalizedSuperClasses(cls, &cids);
    CollectImmediateSuperInterfaces(cls, &cids);
    RemoveCHAOptimizedCode(cls, cids);
  }
  if (cls.is_enum_class()) {
    AllocateEnumValues(cls);
  }
}


// Allocate instances for each enumeration value, and populate the
// static field 'values'.
// By allocating the instances programmatically, we save an implicit final
// getter function object for each enumeration value and for the
// values field. We also don't have to generate the code for these getters
// from thin air (no source code is available).
void ClassFinalizer::AllocateEnumValues(const Class& enum_cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Field& index_field =
      Field::Handle(zone, enum_cls.LookupInstanceField(Symbols::Index()));
  ASSERT(!index_field.IsNull());
  const Field& name_field = Field::Handle(
      zone, enum_cls.LookupInstanceFieldAllowPrivate(Symbols::_name()));
  ASSERT(!name_field.IsNull());
  const Field& values_field =
      Field::Handle(zone, enum_cls.LookupStaticField(Symbols::Values()));
  ASSERT(!values_field.IsNull());
  ASSERT(Instance::Handle(zone, values_field.StaticValue()).IsArray());
  Array& values_list =
      Array::Handle(zone, Array::RawCast(values_field.StaticValue()));
  const String& enum_name = String::Handle(enum_cls.ScrubbedName());
  const String& name_prefix =
      String::Handle(String::Concat(enum_name, Symbols::Dot()));

  Field& field = Field::Handle(zone);
  Instance& ordinal_value = Instance::Handle(zone);
  Instance& enum_value = Instance::Handle(zone);

  String& enum_ident = String::Handle();

  enum_ident =
      Symbols::FromConcat(thread, Symbols::_DeletedEnumPrefix(), enum_name);
  enum_value = Instance::New(enum_cls, Heap::kOld);
  enum_value.SetField(index_field, Smi::Handle(zone, Smi::New(-1)));
  enum_value.SetField(name_field, enum_ident);
  const char* error_msg = NULL;
  enum_value = enum_value.CheckAndCanonicalize(thread, &error_msg);
  ASSERT(!enum_value.IsNull());
  ASSERT(enum_value.IsCanonical());
  field = enum_cls.LookupStaticField(Symbols::_DeletedEnumSentinel());
  ASSERT(!field.IsNull());
  field.SetStaticValue(enum_value, true);
  field.RecordStore(enum_value);

  const Array& fields = Array::Handle(zone, enum_cls.fields());
  for (intptr_t i = 0; i < fields.Length(); i++) {
    field = Field::RawCast(fields.At(i));
    if (!field.is_static()) continue;
    ordinal_value = field.StaticValue();
    // The static fields that need to be initialized with enum instances
    // contain the smi value of the ordinal number, which was stored in
    // the field by the parser. Other fields contain non-smi values.
    if (!ordinal_value.IsSmi()) continue;
    enum_ident = field.name();
    // Construct the string returned by toString.
    ASSERT(!enum_ident.IsNull());
    // For the user-visible name of the enumeration value, we need to
    // unmangle private names.
    if (enum_ident.CharAt(0) == '_') {
      enum_ident = String::ScrubName(enum_ident);
    }
    enum_ident = Symbols::FromConcat(thread, name_prefix, enum_ident);
    enum_value = Instance::New(enum_cls, Heap::kOld);
    enum_value.SetField(index_field, ordinal_value);
    enum_value.SetField(name_field, enum_ident);
    enum_value = enum_value.CheckAndCanonicalize(thread, &error_msg);
    ASSERT(!enum_value.IsNull());
    ASSERT(enum_value.IsCanonical());
    field.SetStaticValue(enum_value, true);
    field.RecordStore(enum_value);
    intptr_t ord = Smi::Cast(ordinal_value).Value();
    ASSERT(ord < values_list.Length());
    values_list.SetAt(ord, enum_value);
  }
  values_list.MakeImmutable();
  values_list ^= values_list.CheckAndCanonicalize(thread, &error_msg);
  ASSERT(!values_list.IsNull());
}


bool ClassFinalizer::IsSuperCycleFree(const Class& cls) {
  Class& test1 = Class::Handle(cls.raw());
  Class& test2 = Class::Handle(cls.SuperClass());
  // A finalized class has been checked for cycles.
  // Using the hare and tortoise algorithm for locating cycles.
  while (!test1.is_type_finalized() && !test2.IsNull() &&
         !test2.is_type_finalized()) {
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


// Returns false if a function type alias illegally refers to itself.
bool ClassFinalizer::IsTypedefCycleFree(const Class& cls,
                                        const AbstractType& type,
                                        GrowableArray<intptr_t>* visited) {
  ASSERT(visited != NULL);
  ResolveType(cls, type);
  bool checking_typedef = false;
  if (type.IsType() && !type.IsMalformed()) {
    AbstractType& other_type = AbstractType::Handle();
    if (type.IsFunctionType()) {
      const Class& scope_class = Class::Handle(type.type_class());
      const Function& signature_function =
          Function::Handle(Type::Cast(type).signature());
      // The signature function of this function type may be a local signature
      // function used in a formal parameter type of the typedef signature, but
      // not the typedef signature function itself, thus not qualifying as an
      // illegal self reference.
      if (!scope_class.is_type_finalized() && scope_class.IsTypedefClass() &&
          (scope_class.signature_function() == signature_function.raw())) {
        checking_typedef = true;
        const intptr_t scope_class_id = scope_class.id();
        ASSERT(visited != NULL);
        for (intptr_t i = 0; i < visited->length(); i++) {
          if ((*visited)[i] == scope_class_id) {
            // We have already visited alias 'scope_class'. We found a cycle.
            return false;
          }
        }
        visited->Add(scope_class_id);
      }
      // Check the bounds of this function type.
      const intptr_t num_type_params = scope_class.NumTypeParameters();
      TypeParameter& type_param = TypeParameter::Handle();
      const TypeArguments& type_params =
          TypeArguments::Handle(scope_class.type_parameters());
      ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
             (type_params.Length() == num_type_params));
      for (intptr_t i = 0; i < num_type_params; i++) {
        type_param ^= type_params.TypeAt(i);
        other_type = type_param.bound();
        if (!IsTypedefCycleFree(cls, other_type, visited)) {
          return false;
        }
      }
      // Check the result type of the signature of this function type.
      other_type = signature_function.result_type();
      if (!IsTypedefCycleFree(cls, other_type, visited)) {
        return false;
      }
      // Check the parameter types of the signature of this function type.
      const intptr_t num_parameters = signature_function.NumParameters();
      for (intptr_t i = 0; i < num_parameters; i++) {
        other_type = signature_function.ParameterTypeAt(i);
        if (!IsTypedefCycleFree(cls, other_type, visited)) {
          return false;
        }
      }
    }
    const TypeArguments& type_args = TypeArguments::Handle(type.arguments());
    if (!type_args.IsNull()) {
      for (intptr_t i = 0; i < type_args.Length(); i++) {
        other_type = type_args.TypeAt(i);
        if (!IsTypedefCycleFree(cls, other_type, visited)) {
          return false;
        }
      }
    }
    if (checking_typedef) {
      visited->RemoveLast();
    }
  }
  return true;
}


// Returns false if the mixin illegally refers to itself.
bool ClassFinalizer::IsMixinCycleFree(const Class& cls,
                                      GrowableArray<intptr_t>* visited) {
  ASSERT(visited != NULL);
  const intptr_t cls_index = cls.id();
  for (intptr_t i = 0; i < visited->length(); i++) {
    if ((*visited)[i] == cls_index) {
      // We have already visited mixin 'cls'. We found a cycle.
      return false;
    }
  }

  // Visit the super chain of cls.
  visited->Add(cls.id());
  Class& super_class = Class::Handle(cls.raw());
  do {
    if (super_class.IsMixinApplication()) {
      const Type& mixin_type = Type::Handle(super_class.mixin());
      ASSERT(!mixin_type.IsNull());
      ASSERT(mixin_type.HasResolvedTypeClass());
      const Class& mixin_class = Class::Handle(mixin_type.type_class());
      if (!IsMixinCycleFree(mixin_class, visited)) {
        return false;
      }
    }
    super_class = super_class.SuperClass();
  } while (!super_class.IsNull());
  visited->RemoveLast();
  return true;
}


void ClassFinalizer::CollectTypeArguments(
    const Class& cls,
    const Type& type,
    const GrowableObjectArray& collected_args) {
  ASSERT(type.HasResolvedTypeClass());
  Class& type_class = Class::Handle(type.type_class());
  TypeArguments& type_args = TypeArguments::Handle(type.arguments());
  const intptr_t num_type_parameters = type_class.NumTypeParameters();
  const intptr_t num_type_arguments =
      type_args.IsNull() ? 0 : type_args.Length();
  AbstractType& arg = AbstractType::Handle();
  if (num_type_arguments > 0) {
    if (num_type_arguments == num_type_parameters) {
      for (intptr_t i = 0; i < num_type_arguments; i++) {
        arg = type_args.TypeAt(i);
        arg = arg.CloneUnfinalized();
        ASSERT(!arg.IsBeingFinalized());
        collected_args.Add(arg);
      }
      return;
    }
    if (Isolate::Current()->error_on_bad_type()) {
      const String& type_class_name = String::Handle(type_class.Name());
      ReportError(cls, type.token_pos(),
                  "wrong number of type arguments for class '%s'",
                  type_class_name.ToCString());
    }
    // Discard provided type arguments and treat type as raw.
  }
  // Fill arguments with type dynamic.
  for (intptr_t i = 0; i < num_type_parameters; i++) {
    arg = Type::DynamicType();
    collected_args.Add(arg);
  }
}


RawType* ClassFinalizer::ResolveMixinAppType(
    const Class& cls,
    const MixinAppType& mixin_app_type) {
  // Lookup or create mixin application classes in the library of cls
  // and resolve super type and mixin types.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& library = Library::Handle(zone, cls.library());
  ASSERT(!library.IsNull());
  const Script& script = Script::Handle(zone, cls.script());
  ASSERT(!script.IsNull());
  const GrowableObjectArray& type_args =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  AbstractType& mixin_super_type =
      AbstractType::Handle(zone, mixin_app_type.super_type());
  ResolveType(cls, mixin_super_type);
  ASSERT(mixin_super_type.HasResolvedTypeClass());  // Even if malformed.
  if (mixin_super_type.IsMalformedOrMalbounded()) {
    ReportError(Error::Handle(zone, mixin_super_type.error()));
  }
  if (mixin_super_type.IsDynamicType()) {
    ReportError(cls, cls.token_pos(), "class '%s' may not extend 'dynamic'",
                String::Handle(zone, cls.Name()).ToCString());
  }
  // The super type may have a BoundedType as type argument, but cannot be
  // a BoundedType itself.
  CollectTypeArguments(cls, Type::Cast(mixin_super_type), type_args);
  AbstractType& mixin_type = AbstractType::Handle(zone);
  Class& mixin_app_class = Class::Handle(zone);
  Class& mixin_super_type_class = Class::Handle(zone);
  Class& mixin_type_class = Class::Handle(zone);
  Library& mixin_super_type_library = Library::Handle(zone);
  Library& mixin_type_library = Library::Handle(zone);
  String& mixin_app_class_name = String::Handle(zone);
  String& mixin_type_class_name = String::Handle(zone);
  AbstractType& super_type_arg = AbstractType::Handle(zone);
  AbstractType& mixin_type_arg = AbstractType::Handle(zone);
  Type& generic_mixin_type = Type::Handle(zone);
  Array& interfaces = Array::Handle(zone);
  const intptr_t depth = mixin_app_type.Depth();
  for (intptr_t i = 0; i < depth; i++) {
    mixin_type = mixin_app_type.MixinTypeAt(i);
    ASSERT(!mixin_type.IsNull());
    ResolveType(cls, mixin_type);
    ASSERT(mixin_type.HasResolvedTypeClass());  // Even if malformed.
    ASSERT(mixin_type.IsType());
    if (mixin_type.IsMalformedOrMalbounded()) {
      ReportError(Error::Handle(zone, mixin_type.error()));
    }
    if (mixin_type.IsDynamicType()) {
      ReportError(cls, cls.token_pos(), "class '%s' may not mixin 'dynamic'",
                  String::Handle(zone, cls.Name()).ToCString());
    }
    const intptr_t num_super_type_args = type_args.Length();
    CollectTypeArguments(cls, Type::Cast(mixin_type), type_args);

    // If the mixin type has identical type arguments as the super type, they
    // can share the same type parameters of the mixin application class,
    // thereby allowing for further optimizations, such as instantiator vector
    // reuse or sharing of type arguments with the super class.
    bool share_type_params = (num_super_type_args > 0) &&
                             (type_args.Length() == 2 * num_super_type_args);
    if (share_type_params) {
      for (intptr_t i = 0; i < num_super_type_args; i++) {
        super_type_arg ^= type_args.At(i);
        mixin_type_arg ^= type_args.At(num_super_type_args + i);
        if (!super_type_arg.Equals(mixin_type_arg)) {
          share_type_params = false;
          break;
        }
      }
      if (share_type_params) {
        // Cut the type argument vector in half.
        type_args.SetLength(num_super_type_args);
      }
    }

    // The name of the mixin application class is a combination of
    // the super class name and mixin class name, as well as their respective
    // library private keys if their library is different than the library of
    // the mixin application class.
    // Note that appending the library url would break naming conventions (e.g.
    // no period in the class name).
    mixin_app_class_name = mixin_super_type.ClassName();
    mixin_super_type_class = mixin_super_type.type_class();
    mixin_super_type_library = mixin_super_type_class.library();
    if (mixin_super_type_library.raw() != library.raw()) {
      mixin_app_class_name = String::Concat(
          mixin_app_class_name,
          String::Handle(zone, mixin_super_type_library.private_key()));
    }
    mixin_app_class_name =
        String::Concat(mixin_app_class_name, Symbols::Ampersand());
    // If the type parameters are shared between the super type and the mixin
    // type, use two ampersand symbols, so that the class has a different name
    // and is not reused in a context where this optimization is not possible.
    if (share_type_params) {
      mixin_app_class_name =
          String::Concat(mixin_app_class_name, Symbols::Ampersand());
    }
    mixin_type_class_name = mixin_type.ClassName();
    mixin_type_class = mixin_type.type_class();
    mixin_type_library = mixin_type_class.library();
    if (mixin_type_library.raw() != library.raw()) {
      mixin_type_class_name = String::Concat(
          mixin_type_class_name,
          String::Handle(zone, mixin_type_library.private_key()));
    }
    mixin_app_class_name =
        String::Concat(mixin_app_class_name, mixin_type_class_name);
    mixin_app_class = library.LookupLocalClass(mixin_app_class_name);
    if (mixin_app_class.IsNull()) {
      mixin_app_class_name = Symbols::New(thread, mixin_app_class_name);
      mixin_app_class = Class::New(library, mixin_app_class_name, script,
                                   mixin_type.token_pos());
      mixin_app_class.set_super_type(mixin_super_type);
      generic_mixin_type =
          Type::New(mixin_type_class, Object::null_type_arguments(),
                    mixin_type.token_pos());
      mixin_app_class.set_mixin(generic_mixin_type);
      // Add the mixin type to the list of interfaces that the mixin application
      // class implements. This is necessary so that cycle check work at
      // compile time (type arguments are ignored by that check).
      interfaces = Array::New(1);
      interfaces.SetAt(0, generic_mixin_type);
      ASSERT(mixin_app_class.interfaces() == Object::empty_array().raw());
      mixin_app_class.set_interfaces(interfaces);
      mixin_app_class.set_is_synthesized_class();
      library.AddClass(mixin_app_class);

      // No need to add the new class to pending_classes, since it will be
      // processed via the super_type chain of a pending class.

      if (FLAG_trace_class_finalization) {
        THR_Print("Creating mixin application %s\n",
                  mixin_app_class.ToCString());
      }
    }
    // This mixin application class becomes the type class of the super type of
    // the next mixin application class. It is however too early to provide the
    // correct super type arguments. We use the raw type for now.
    mixin_super_type = Type::New(mixin_app_class, Object::null_type_arguments(),
                                 mixin_type.token_pos());
  }
  TypeArguments& mixin_app_args = TypeArguments::Handle(zone);
  if (type_args.Length() > 0) {
    mixin_app_args = TypeArguments::New(type_args.Length());
    AbstractType& type_arg = AbstractType::Handle(zone);
    for (intptr_t i = 0; i < type_args.Length(); i++) {
      type_arg ^= type_args.At(i);
      mixin_app_args.SetTypeAt(i, type_arg);
    }
  }
  if (FLAG_trace_class_finalization) {
    THR_Print("ResolveMixinAppType: mixin appl type args: %s\n",
              mixin_app_args.ToCString());
  }
  // The mixin application class at depth k is a subclass of mixin application
  // class at depth k - 1. Build a new super type with the class at the highest
  // depth (the last one processed by the loop above) as the type class and the
  // collected type arguments from the super type and all mixin types.
  // This super type replaces the MixinAppType object in the class that extends
  // the mixin application.
  return Type::New(mixin_app_class, mixin_app_args, mixin_app_type.token_pos());
}


// Recursively walks the graph of explicitly declared super type and
// interfaces, resolving unresolved super types and interfaces.
// Reports an error if there is an interface reference that cannot be
// resolved, or if there is a cycle in the graph. We detect cycles by
// remembering interfaces we've visited in each path through the
// graph. If we visit an interface a second time on a given path,
// we found a loop.
void ClassFinalizer::ResolveSuperTypeAndInterfaces(
    const Class& cls,
    GrowableArray<intptr_t>* visited) {
  if (cls.is_cycle_free()) {
    return;
  }
  ASSERT(visited != NULL);
  if (FLAG_trace_class_finalization) {
    THR_Print("Resolving super and interfaces: %s\n", cls.ToCString());
  }
  Zone* zone = Thread::Current()->zone();
  const intptr_t cls_index = cls.id();
  for (intptr_t i = 0; i < visited->length(); i++) {
    if ((*visited)[i] == cls_index) {
      // We have already visited class 'cls'. We found a cycle.
      const String& class_name = String::Handle(zone, cls.Name());
      ReportError(cls, cls.token_pos(), "cyclic reference found for class '%s'",
                  class_name.ToCString());
    }
  }

  // If the class/interface has no explicit super class/interfaces
  // and is not a mixin application, we are done.
  AbstractType& super_type = AbstractType::Handle(zone, cls.super_type());
  Array& super_interfaces = Array::Handle(zone, cls.interfaces());
  if ((super_type.IsNull() || super_type.IsObjectType()) &&
      (super_interfaces.Length() == 0)) {
    cls.set_is_cycle_free();
    return;
  }

  if (super_type.IsMixinAppType()) {
    // For the cycle check below to work, ResolveMixinAppType needs to set
    // the mixin interfaces in the super classes, even if only in raw form.
    // It is indeed too early to set the correct type arguments, which is not
    // a problem since they are ignored in the cycle check.
    const MixinAppType& mixin_app_type = MixinAppType::Cast(super_type);
    super_type = ResolveMixinAppType(cls, mixin_app_type);
    cls.set_super_type(super_type);
  }

  // If cls belongs to core lib, restrictions about allowed interfaces
  // are lifted.
  const bool cls_belongs_to_core_lib = cls.library() == Library::CoreLibrary();

  // Resolve and check the super type and interfaces of cls.
  visited->Add(cls_index);
  AbstractType& interface = AbstractType::Handle(zone);
  Class& interface_class = Class::Handle(zone);

  // Resolve super type. Failures lead to a longjmp.
  ResolveType(cls, super_type);
  if (super_type.IsMalformedOrMalbounded()) {
    ReportError(Error::Handle(zone, super_type.error()));
  }
  if (super_type.IsDynamicType()) {
    ReportError(cls, cls.token_pos(), "class '%s' may not extend 'dynamic'",
                String::Handle(zone, cls.Name()).ToCString());
  }
  interface_class = super_type.type_class();
  if (interface_class.IsTypedefClass()) {
    ReportError(cls, cls.token_pos(),
                "class '%s' may not extend function type alias '%s'",
                String::Handle(zone, cls.Name()).ToCString(),
                String::Handle(zone, super_type.UserVisibleName()).ToCString());
  }
  if (interface_class.is_enum_class()) {
    ReportError(cls, cls.token_pos(), "class '%s' may not extend enum '%s'",
                String::Handle(zone, cls.Name()).ToCString(),
                String::Handle(zone, interface_class.Name()).ToCString());
  }

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
      case kNullCid:
      case kArrayCid:
      case kImmutableArrayCid:
      case kGrowableObjectArrayCid:
#define DO_NOT_EXTEND_TYPED_DATA_CLASSES(clazz)                                \
  case kTypedData##clazz##Cid:                                                 \
  case kTypedData##clazz##ViewCid:                                             \
  case kExternalTypedData##clazz##Cid:
        CLASS_LIST_TYPED_DATA(DO_NOT_EXTEND_TYPED_DATA_CLASSES)
#undef DO_NOT_EXTEND_TYPED_DATA_CLASSES
      case kByteDataViewCid:
      case kWeakPropertyCid:
        is_error = true;
        break;
      default: {
        // Special case: classes for which we don't have a known class id.
        if (super_type.IsDoubleType() || super_type.IsIntType() ||
            super_type.IsStringType()) {
          is_error = true;
        }
        break;
      }
    }
    if (is_error) {
      const String& interface_name =
          String::Handle(zone, interface_class.Name());
      ReportError(cls, cls.token_pos(), "'%s' is not allowed to extend '%s'",
                  String::Handle(zone, cls.Name()).ToCString(),
                  interface_name.ToCString());
    }
  }
  // Now resolve the super interfaces of the super type.
  ResolveSuperTypeAndInterfaces(interface_class, visited);

  // Resolve interfaces. Failures lead to a longjmp.
  for (intptr_t i = 0; i < super_interfaces.Length(); i++) {
    interface ^= super_interfaces.At(i);
    ResolveType(cls, interface);
    ASSERT(!interface.IsTypeParameter());  // Should be detected by parser.
    // A malbounded interface is only reported when involved in a type test.
    if (interface.IsMalformed()) {
      ReportError(Error::Handle(zone, interface.error()));
    }
    if (interface.IsDynamicType()) {
      ReportError(cls, cls.token_pos(),
                  "'dynamic' may not be used as interface");
    }
    interface_class = interface.type_class();
    if (interface_class.IsTypedefClass()) {
      const String& interface_name =
          String::Handle(zone, interface_class.Name());
      ReportError(cls, cls.token_pos(),
                  "function type alias '%s' may not be used as interface",
                  interface_name.ToCString());
    }
    if (interface_class.is_enum_class()) {
      const String& interface_name =
          String::Handle(zone, interface_class.Name());
      ReportError(cls, cls.token_pos(),
                  "enum '%s' may not be used as interface",
                  interface_name.ToCString());
    }
    // Verify that unless cls belongs to core lib, it cannot extend, implement,
    // or mixin any of Null, bool, num, int, double, String, dynamic.
    if (!cls_belongs_to_core_lib) {
      if (interface.IsBoolType() || interface.IsNullType() ||
          interface.IsNumberType() || interface.IsIntType() ||
          interface.IsDoubleType() || interface.IsStringType() ||
          interface.IsDynamicType()) {
        const String& interface_name =
            String::Handle(zone, interface_class.Name());
        if (cls.IsMixinApplication()) {
          ReportError(cls, cls.token_pos(), "illegal mixin of '%s'",
                      interface_name.ToCString());
        } else {
          ReportError(cls, cls.token_pos(),
                      "'%s' is not allowed to extend or implement '%s'",
                      String::Handle(zone, cls.Name()).ToCString(),
                      interface_name.ToCString());
        }
      }
    }
    interface_class.set_is_implemented();
    // Now resolve the super interfaces.
    ResolveSuperTypeAndInterfaces(interface_class, visited);
  }
  visited->RemoveLast();
  cls.set_is_cycle_free();
}


// A class is marked as constant if it has one constant constructor.
// A constant class can only have final instance fields.
// Note: we must check for cycles before checking for const properties.
void ClassFinalizer::CheckForLegalConstClass(const Class& cls) {
  ASSERT(cls.is_const());
  const Array& fields_array = Array::Handle(cls.fields());
  intptr_t len = fields_array.Length();
  Field& field = Field::Handle();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    if (!field.is_static() && !field.is_final()) {
      const String& class_name = String::Handle(cls.Name());
      const String& field_name = String::Handle(field.name());
      ReportError(cls, field.token_pos(),
                  "const class '%s' has non-final field '%s'",
                  class_name.ToCString(), field_name.ToCString());
    }
  }
}


void ClassFinalizer::PrintClassInformation(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  const String& class_name = String::Handle(cls.Name());
  THR_Print("class '%s'", class_name.ToCString());
  const Library& library = Library::Handle(cls.library());
  if (!library.IsNull()) {
    THR_Print(" library '%s%s':\n", String::Handle(library.url()).ToCString(),
              String::Handle(library.private_key()).ToCString());
  } else {
    THR_Print(" (null library):\n");
  }
  const AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (super_type.IsNull()) {
    THR_Print("  Super: NULL");
  } else {
    const String& super_name = String::Handle(super_type.Name());
    THR_Print("  Super: %s", super_name.ToCString());
  }
  const Array& interfaces_array = Array::Handle(cls.interfaces());
  if (interfaces_array.Length() > 0) {
    THR_Print("; interfaces: ");
    AbstractType& interface = AbstractType::Handle();
    intptr_t len = interfaces_array.Length();
    for (intptr_t i = 0; i < len; i++) {
      interface ^= interfaces_array.At(i);
      THR_Print("  %s ", interface.ToCString());
    }
  }
  THR_Print("\n");
  const Array& functions_array = Array::Handle(cls.functions());
  Function& function = Function::Handle();
  intptr_t len = functions_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    function ^= functions_array.At(i);
    THR_Print("  %s\n", function.ToCString());
  }
  const Array& fields_array = Array::Handle(cls.fields());
  Field& field = Field::Handle();
  len = fields_array.Length();
  for (intptr_t i = 0; i < len; i++) {
    field ^= fields_array.At(i);
    THR_Print("  %s\n", field.ToCString());
  }
}

// Either report an error or mark the type as malformed.
void ClassFinalizer::MarkTypeMalformed(const Error& prev_error,
                                       const Script& script,
                                       const Type& type,
                                       const char* format,
                                       va_list args) {
  LanguageError& error = LanguageError::Handle(LanguageError::NewFormattedV(
      prev_error, script, type.token_pos(), Report::AtLocation,
      Report::kMalformedType, Heap::kOld, format, args));
  if (Isolate::Current()->error_on_bad_type()) {
    ReportError(error);
  }
  type.set_error(error);
  // Make the type raw, since it may not be possible to
  // properly finalize its type arguments.
  type.set_type_class(Class::Handle(Object::dynamic_class()));
  type.set_arguments(Object::null_type_arguments());
  if (!type.IsFinalized()) {
    type.SetIsFinalized();
    // Do not canonicalize malformed types, since they contain an error field.
  } else {
    // The only case where the malformed type was already finalized is when its
    // type arguments are not within bounds. In that case, we have a prev_error.
    ASSERT(!prev_error.IsNull());
  }
}


RawType* ClassFinalizer::NewFinalizedMalformedType(const Error& prev_error,
                                                   const Script& script,
                                                   TokenPosition type_pos,
                                                   const char* format,
                                                   ...) {
  va_list args;
  va_start(args, format);
  const UnresolvedClass& unresolved_class =
      UnresolvedClass::Handle(UnresolvedClass::New(LibraryPrefix::Handle(),
                                                   Symbols::Empty(), type_pos));
  const Type& type = Type::Handle(
      Type::New(unresolved_class, Object::null_type_arguments(), type_pos));
  MarkTypeMalformed(prev_error, script, type, format, args);
  va_end(args);
  ASSERT(type.IsMalformed());
  ASSERT(type.IsFinalized());
  return type.raw();
}


void ClassFinalizer::FinalizeMalformedType(const Error& prev_error,
                                           const Script& script,
                                           const Type& type,
                                           const char* format,
                                           ...) {
  va_list args;
  va_start(args, format);
  MarkTypeMalformed(prev_error, script, type, format, args);
  va_end(args);
}


void ClassFinalizer::FinalizeMalboundedType(const Error& prev_error,
                                            const Script& script,
                                            const AbstractType& type,
                                            const char* format,
                                            ...) {
  va_list args;
  va_start(args, format);
  LanguageError& error = LanguageError::Handle(LanguageError::NewFormattedV(
      prev_error, script, type.token_pos(), Report::AtLocation,
      Report::kMalboundedType, Heap::kOld, format, args));
  va_end(args);
  if (Isolate::Current()->error_on_bad_type()) {
    ReportError(error);
  }
  type.set_error(error);
  if (!type.IsFinalized()) {
    type.SetIsFinalized();
    // Do not canonicalize malbounded types.
  }
}


void ClassFinalizer::ReportError(const Error& error) {
  Report::LongJump(error);
  UNREACHABLE();
}


void ClassFinalizer::ReportErrors(const Error& prev_error,
                                  const Class& cls,
                                  TokenPosition token_pos,
                                  const char* format,
                                  ...) {
  va_list args;
  va_start(args, format);
  const Script& script = Script::Handle(cls.script());
  Report::LongJumpV(prev_error, script, token_pos, format, args);
  va_end(args);
  UNREACHABLE();
}


void ClassFinalizer::ReportError(const Class& cls,
                                 TokenPosition token_pos,
                                 const char* format,
                                 ...) {
  va_list args;
  va_start(args, format);
  const Script& script = Script::Handle(cls.script());
  Report::MessageV(Report::kError, script, token_pos, Report::AtLocation,
                   format, args);
  va_end(args);
  UNREACHABLE();
}


void ClassFinalizer::VerifyImplicitFieldOffsets() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  const ClassTable& class_table = *(isolate->class_table());
  Class& cls = Class::Handle(zone);
  Array& fields_array = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  String& name = String::Handle(zone);
  String& expected_name = String::Handle(zone);
  Error& error = Error::Handle(zone);

  // First verify field offsets of all the TypedDataView classes.
  for (intptr_t cid = kTypedDataInt8ArrayViewCid;
       cid <= kTypedDataFloat32x4ArrayViewCid; cid++) {
    cls = class_table.At(cid);  // Get the TypedDataView class.
    error = cls.EnsureIsFinalized(thread);
    ASSERT(error.IsNull());
    cls = cls.SuperClass();  // Get it's super class '_TypedListView'.
    cls = cls.SuperClass();
    fields_array ^= cls.fields();
    ASSERT(fields_array.Length() == TypedDataView::NumberOfFields());
    field ^= fields_array.At(0);
    ASSERT(field.Offset() == TypedDataView::data_offset());
    name ^= field.name();
    expected_name ^= String::New("_typedData");
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
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  fields_array ^= cls.fields();
  ASSERT(fields_array.Length() == TypedDataView::NumberOfFields());
  field ^= fields_array.At(0);
  ASSERT(field.Offset() == TypedDataView::data_offset());
  name ^= field.name();
  expected_name ^= String::New("_typedData");
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

  // Now verify field offsets of '_ByteBuffer' class.
  cls = class_table.At(kByteBufferCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  fields_array ^= cls.fields();
  ASSERT(fields_array.Length() == ByteBuffer::NumberOfFields());
  field ^= fields_array.At(0);
  ASSERT(field.Offset() == ByteBuffer::data_offset());
  name ^= field.name();
  expected_name ^= String::New("_data");
  ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));
#endif
}


void ClassFinalizer::SortClasses() {
  Thread* T = Thread::Current();
  Zone* Z = T->zone();
  Isolate* I = T->isolate();
  ClassTable* table = I->class_table();
  intptr_t num_cids = table->NumCids();
  intptr_t* old_to_new_cid = new intptr_t[num_cids];
  for (intptr_t cid = 0; cid < kNumPredefinedCids; cid++) {
    old_to_new_cid[cid] = cid;  // The predefined classes cannot change cids.
  }
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    old_to_new_cid[cid] = -1;
  }

  intptr_t next_new_cid = kNumPredefinedCids;
  GrowableArray<intptr_t> dfs_stack;
  Class& cls = Class::Handle(Z);
  GrowableObjectArray& subclasses = GrowableObjectArray::Handle(Z);

  // Object doesn't use its subclasses list.
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (!table->HasValidClassAt(cid)) {
      continue;
    }
    cls = table->At(cid);
    if (cls.is_patch()) {
      continue;
    }
    if (cls.SuperClass() == I->object_store()->object_class()) {
      dfs_stack.Add(cid);
    }
  }

  while (dfs_stack.length() > 0) {
    intptr_t cid = dfs_stack.RemoveLast();
    ASSERT(table->HasValidClassAt(cid));
    cls = table->At(cid);
    ASSERT(!cls.IsNull());
    if (old_to_new_cid[cid] == -1) {
      old_to_new_cid[cid] = next_new_cid++;
      if (FLAG_trace_class_finalization) {
        THR_Print("%" Pd ": %s, was %" Pd "\n", old_to_new_cid[cid],
                  cls.ToCString(), cid);
      }
    }
    subclasses = cls.direct_subclasses();
    if (!subclasses.IsNull()) {
      for (intptr_t i = 0; i < subclasses.Length(); i++) {
        cls ^= subclasses.At(i);
        ASSERT(!cls.IsNull());
        dfs_stack.Add(cls.id());
      }
    }
  }

  // Top-level classes, typedefs, patch classes, etc.
  for (intptr_t cid = kNumPredefinedCids; cid < num_cids; cid++) {
    if (old_to_new_cid[cid] == -1) {
      old_to_new_cid[cid] = next_new_cid++;
      if (FLAG_trace_class_finalization && table->HasValidClassAt(cid)) {
        cls = table->At(cid);
        THR_Print("%" Pd ": %s, was %" Pd "\n", old_to_new_cid[cid],
                  cls.ToCString(), cid);
      }
    }
  }
  ASSERT(next_new_cid == num_cids);

  RemapClassIds(old_to_new_cid);
  delete[] old_to_new_cid;
  RehashTypes();  // Types use cid's as part of their hashes.
}


class CidRewriteVisitor : public ObjectVisitor {
 public:
  explicit CidRewriteVisitor(intptr_t* old_to_new_cids)
      : old_to_new_cids_(old_to_new_cids) {}

  intptr_t Map(intptr_t cid) {
    ASSERT(cid != -1);
    return old_to_new_cids_[cid];
  }

  void VisitObject(RawObject* obj) {
    if (obj->IsClass()) {
      RawClass* cls = Class::RawCast(obj);
      cls->ptr()->id_ = Map(cls->ptr()->id_);
    } else if (obj->IsField()) {
      RawField* field = Field::RawCast(obj);
      field->ptr()->guarded_cid_ = Map(field->ptr()->guarded_cid_);
      field->ptr()->is_nullable_ = Map(field->ptr()->is_nullable_);
    } else if (obj->IsTypeParameter()) {
      RawTypeParameter* param = TypeParameter::RawCast(obj);
      param->ptr()->parameterized_class_id_ =
          Map(param->ptr()->parameterized_class_id_);
    } else if (obj->IsType()) {
      RawType* type = Type::RawCast(obj);
      RawObject* id = type->ptr()->type_class_id_;
      if (!id->IsHeapObject()) {
        type->ptr()->type_class_id_ =
            Smi::New(Map(Smi::Value(Smi::RawCast(id))));
      }
    } else {
      intptr_t old_cid = obj->GetClassId();
      intptr_t new_cid = Map(old_cid);
      if (old_cid != new_cid) {
        // Don't touch objects that are unchanged. In particular, Instructions,
        // which are write-protected.
        obj->SetClassId(new_cid);
      }
    }
  }

 private:
  intptr_t* old_to_new_cids_;
};


void ClassFinalizer::RemapClassIds(intptr_t* old_to_new_cid) {
  Isolate* I = Thread::Current()->isolate();

  // Code, ICData, allocation stubs have now-invalid cids.
  ClearAllCode();

  {
    HeapIterationScope his;
    I->set_remapping_cids(true);

    // Update the class table. Do it before rewriting cids in headers, as the
    // heap walkers load an object's size *after* calling the visitor.
    I->class_table()->Remap(old_to_new_cid);

    // Rewrite cids in headers and cids in Classes, Fields, Types and
    // TypeParameters.
    {
      CidRewriteVisitor visitor(old_to_new_cid);
      I->heap()->VisitObjects(&visitor);
    }
    I->set_remapping_cids(false);
  }

#if defined(DEBUG)
  I->class_table()->Validate();
  I->heap()->Verify();
#endif
}


class ClearTypeHashVisitor : public ObjectVisitor {
 public:
  explicit ClearTypeHashVisitor(Zone* zone)
      : type_param_(TypeParameter::Handle(zone)),
        type_(Type::Handle(zone)),
        type_args_(TypeArguments::Handle(zone)),
        bounded_type_(BoundedType::Handle(zone)) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsTypeParameter()) {
      type_param_ ^= obj;
      type_param_.SetHash(0);
    } else if (obj->IsType()) {
      type_ ^= obj;
      type_.SetHash(0);
    } else if (obj->IsBoundedType()) {
      bounded_type_ ^= obj;
      bounded_type_.SetHash(0);
    } else if (obj->IsTypeArguments()) {
      type_args_ ^= obj;
      type_args_.SetHash(0);
    }
  }

 private:
  TypeParameter& type_param_;
  Type& type_;
  TypeArguments& type_args_;
  BoundedType& bounded_type_;
};


void ClassFinalizer::RehashTypes() {
  Thread* T = Thread::Current();
  Zone* Z = T->zone();
  Isolate* I = T->isolate();

  // Clear all cached hash values.
  {
    HeapIterationScope his;
    ClearTypeHashVisitor visitor(Z);
    I->heap()->VisitObjects(&visitor);
  }

  // Rehash the canonical Types table.
  ObjectStore* object_store = I->object_store();
  GrowableObjectArray& types =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  Array& types_array = Array::Handle(Z);
  Type& type = Type::Handle(Z);
  {
    CanonicalTypeSet types_table(Z, object_store->canonical_types());
    types_array = HashTables::ToArray(types_table, false);
    for (intptr_t i = 0; i < types_array.Length(); i++) {
      type ^= types_array.At(i);
      types.Add(type);
    }
    types_table.Release();
  }

  intptr_t dict_size = Utils::RoundUpToPowerOfTwo(types.Length() * 4 / 3);
  types_array = HashTables::New<CanonicalTypeSet>(dict_size, Heap::kOld);
  CanonicalTypeSet types_table(Z, types_array.raw());
  for (intptr_t i = 0; i < types.Length(); i++) {
    type ^= types.At(i);
    bool present = types_table.Insert(type);
    ASSERT(!present || type.IsRecursive());
  }
  object_store->set_canonical_types(types_table.Release());

  // Rehash the canonical TypeArguments table.
  Array& typeargs_array = Array::Handle(Z);
  GrowableObjectArray& typeargs =
      GrowableObjectArray::Handle(Z, GrowableObjectArray::New());
  TypeArguments& typearg = TypeArguments::Handle(Z);
  {
    CanonicalTypeArgumentsSet typeargs_table(
        Z, object_store->canonical_type_arguments());
    typeargs_array = HashTables::ToArray(typeargs_table, false);
    for (intptr_t i = 0; i < typeargs_array.Length(); i++) {
      typearg ^= typeargs_array.At(i);
      typeargs.Add(typearg);
    }
    typeargs_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(typeargs.Length() * 4 / 3);
  typeargs_array =
      HashTables::New<CanonicalTypeArgumentsSet>(dict_size, Heap::kOld);
  CanonicalTypeArgumentsSet typeargs_table(Z, typeargs_array.raw());
  for (intptr_t i = 0; i < typeargs.Length(); i++) {
    typearg ^= typeargs.At(i);
    bool present = typeargs_table.Insert(typearg);
    ASSERT(!present || typearg.IsRecursive());
  }
  object_store->set_canonical_type_arguments(typeargs_table.Release());
}


void ClassFinalizer::ClearAllCode() {
  class ClearCodeFunctionVisitor : public FunctionVisitor {
    void Visit(const Function& function) {
      function.ClearCode();
      function.ClearICDataArray();
    }
  };
  ClearCodeFunctionVisitor function_visitor;
  ProgramVisitor::VisitFunctions(&function_visitor);

  class ClearCodeClassVisitor : public ClassVisitor {
    void Visit(const Class& cls) { cls.DisableAllocationStub(); }
  };
  ClearCodeClassVisitor class_visitor;
  ProgramVisitor::VisitClasses(&class_visitor);
}

}  // namespace dart
