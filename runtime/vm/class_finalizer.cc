// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/class_finalizer.h"

#include "vm/canonical_tables.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/flags.h"
#include "vm/hash_table.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/kernel_loader.h"
#include "vm/log.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/program_visitor.h"
#include "vm/runtime_entry.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"

namespace dart {

DEFINE_FLAG(bool, print_classes, false, "Prints details about loaded classes.");
DEFINE_FLAG(bool, trace_class_finalization, false, "Trace class finalization.");
DEFINE_FLAG(bool, trace_type_finalization, false, "Trace type finalization.");

bool ClassFinalizer::AllClassesFinalized() {
  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  const GrowableObjectArray& classes =
      GrowableObjectArray::Handle(object_store->pending_classes());
  return classes.Length() == 0;
}

#if defined(DART_PRECOMPILED_RUNTIME)

bool ClassFinalizer::ProcessPendingClasses() {
  ASSERT(AllClassesFinalized());
  return true;
}

#else

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
  const ClassTable& class_table = *IsolateGroup::Current()->class_table();
  Class& cls = Class::Handle();
  for (intptr_t i = 0; i < added_subclass_to_cids.length(); i++) {
    intptr_t cid = added_subclass_to_cids[i];
    cls = class_table.At(cid);
    ASSERT(!cls.IsNull());
    cls.DisableCHAOptimizedCode(subclass);
  }
}

static void AddSuperType(const AbstractType& type,
                         GrowableArray<intptr_t>* finalized_super_classes) {
  ASSERT(type.HasTypeClass());
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
  Class& cls = Class::Handle(cls_.ptr());
  AbstractType& super_type = Type::Handle();
  super_type = cls.super_type();
  if (!super_type.IsNull()) {
    if (super_type.HasTypeClass()) {
      cls = super_type.type_class();
      if (cls.is_finalized()) {
        AddSuperType(super_type, finalized_super_classes);
      }
    }
  }
}

class InterfaceFinder {
 public:
  InterfaceFinder(Zone* zone,
                  ClassTable* class_table,
                  GrowableArray<intptr_t>* cids)
      : class_table_(class_table),
        array_handles_(zone),
        class_handles_(zone),
        type_handles_(zone),
        cids_(cids) {}

  void FindAllInterfaces(const Class& klass) {
    // The class is implementing its own interface.
    cids_->Add(klass.id());

    ScopedHandle<Array> array(&array_handles_);
    ScopedHandle<Class> interface_class(&class_handles_);
    ScopedHandle<Class> current_class(&class_handles_);
    ScopedHandle<AbstractType> type(&type_handles_);

    *current_class = klass.ptr();
    while (true) {
      // We don't care about top types.
      const intptr_t cid = current_class->id();
      if (cid == kObjectCid || cid == kDynamicCid || cid == kVoidCid) {
        break;
      }

      // The class is implementing its directly declared implemented interfaces.
      *array = klass.interfaces();
      if (!array->IsNull()) {
        for (intptr_t i = 0; i < array->Length(); ++i) {
          *type ^= array->At(i);
          *interface_class = class_table_->At(type->type_class_id());
          FindAllInterfaces(*interface_class);
        }
      }

      // The class is implementing its super type's interfaces.
      *type = current_class->super_type();
      if (type->IsNull()) break;
      *current_class = class_table_->At(type->type_class_id());
    }
  }

 private:
  ClassTable* class_table_;
  ReusableHandleStack<Array> array_handles_;
  ReusableHandleStack<Class> class_handles_;
  ReusableHandleStack<AbstractType> type_handles_;
  GrowableArray<intptr_t>* cids_;
};

static void CollectImmediateSuperInterfaces(const Class& cls,
                                            GrowableArray<intptr_t>* cids) {
  const Array& interfaces = Array::Handle(cls.interfaces());
  Class& ifc = Class::Handle();
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    if (!type.HasTypeClass()) continue;
    ifc = type.type_class();
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
bool ClassFinalizer::ProcessPendingClasses() {
  Thread* thread = Thread::Current();
  TIMELINE_DURATION(thread, Isolate, "ProcessPendingClasses");
  auto isolate_group = thread->isolate_group();
  ASSERT(isolate_group != nullptr);
  HANDLESCOPE(thread);
  ObjectStore* object_store = isolate_group->object_store();
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

#if defined(DEBUG)
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      // Recognized a new class, but forgot to add @pragma('vm:entrypoint')?
      ASSERT(cls.is_declaration_loaded());
    }
#endif

    // Finalize types in all classes.
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
      FinalizeTypesInClass(cls);
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

void ClassFinalizer::VerifyBootstrapClasses() {
  if (FLAG_trace_class_finalization) {
    OS::PrintErr("VerifyBootstrapClasses START.\n");
  }
  ObjectStore* object_store = IsolateGroup::Current()->object_store();

  Class& cls = Class::Handle();
#if defined(DEBUG)
  // Basic checking.
  cls = object_store->object_class();
  ASSERT_EQUAL(Instance::InstanceSize(), cls.host_instance_size());
  cls = object_store->integer_implementation_class();
  ASSERT_EQUAL(Integer::InstanceSize(), cls.host_instance_size());
  cls = object_store->smi_class();
  ASSERT_EQUAL(Smi::InstanceSize(), cls.host_instance_size());
  cls = object_store->mint_class();
  ASSERT_EQUAL(Mint::InstanceSize(), cls.host_instance_size());
  cls = object_store->one_byte_string_class();
  ASSERT_EQUAL(OneByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->two_byte_string_class();
  ASSERT_EQUAL(TwoByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->external_one_byte_string_class();
  ASSERT_EQUAL(ExternalOneByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->external_two_byte_string_class();
  ASSERT_EQUAL(ExternalTwoByteString::InstanceSize(), cls.host_instance_size());
  cls = object_store->double_class();
  ASSERT_EQUAL(Double::InstanceSize(), cls.host_instance_size());
  cls = object_store->bool_class();
  ASSERT_EQUAL(Bool::InstanceSize(), cls.host_instance_size());
  cls = object_store->array_class();
  ASSERT_EQUAL(Array::InstanceSize(), cls.host_instance_size());
  cls = object_store->immutable_array_class();
  ASSERT_EQUAL(ImmutableArray::InstanceSize(), cls.host_instance_size());
  cls = object_store->weak_property_class();
  ASSERT_EQUAL(WeakProperty::InstanceSize(), cls.host_instance_size());
  cls = object_store->weak_reference_class();
  ASSERT_EQUAL(WeakReference::InstanceSize(), cls.host_instance_size());
  cls = object_store->linked_hash_map_class();
  ASSERT_EQUAL(LinkedHashMap::InstanceSize(), cls.host_instance_size());
  cls = object_store->immutable_linked_hash_map_class();
  ASSERT_EQUAL(LinkedHashMap::InstanceSize(), cls.host_instance_size());
  cls = object_store->linked_hash_set_class();
  ASSERT_EQUAL(LinkedHashSet::InstanceSize(), cls.host_instance_size());
  cls = object_store->immutable_linked_hash_set_class();
  ASSERT_EQUAL(LinkedHashSet::InstanceSize(), cls.host_instance_size());
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
    OS::PrintErr("VerifyBootstrapClasses END.\n");
  }
  IsolateGroup::Current()->heap()->Verify();
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeTypeParameters(Zone* zone,
                                            const Class& cls,
                                            const FunctionType& signature,
                                            FinalizationKind finalization,
                                            PendingTypes* pending_types) {
  if (FLAG_trace_type_finalization) {
    THR_Print(
        "%s type parameters of %s '%s'\n",
        finalization == kFinalize ? "Finalizing" : "Canonicalizing",
        !cls.IsNull() ? "class" : "signature",
        String::Handle(zone, !cls.IsNull() ? cls.Name() : signature.Name())
            .ToCString());
  }
  const TypeParameters& type_params =
      TypeParameters::Handle(zone, !cls.IsNull() ? cls.type_parameters()
                                                 : signature.type_parameters());
  if (!type_params.IsNull()) {
    TypeArguments& type_args = TypeArguments::Handle(zone);

    type_args = type_params.bounds();
    type_args =
        FinalizeTypeArguments(zone, type_args, finalization, pending_types);
    type_params.set_bounds(type_args);

    type_args = type_params.defaults();
    type_args =
        FinalizeTypeArguments(zone, type_args, finalization, pending_types);
    type_params.set_defaults(type_args);

    type_params.OptimizeFlags();
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
void ClassFinalizer::CheckRecursiveType(const AbstractType& type,
                                        PendingTypes* pending_types) {
  ASSERT(!type.IsFunctionType());
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
  // raw form, i.e. where each class type parameter is substituted with dynamic.
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
    if ((pending_type.ptr() != type.ptr()) && pending_type.IsType() &&
        (pending_type.type_class() == type_cls.ptr())) {
      pending_arguments = pending_type.arguments();
      // By using TypeEquality::kInSubtypeTest, we throw a wider net than
      // using canonical or syntactical equality and may reject more
      // problematic declarations.
      if (!pending_arguments.IsSubvectorEquivalent(
              arguments, first_type_param, num_type_params,
              TypeEquality::kInSubtypeTest) &&
          !pending_arguments.IsSubvectorInstantiated(first_type_param,
                                                     num_type_params)) {
        const TypeArguments& instantiated_arguments = TypeArguments::Handle(
            zone, arguments.InstantiateFrom(Object::null_type_arguments(),
                                            Object::null_type_arguments(),
                                            kNoneFree, Heap::kNew));
        const TypeArguments& instantiated_pending_arguments =
            TypeArguments::Handle(zone, pending_arguments.InstantiateFrom(
                                            Object::null_type_arguments(),
                                            Object::null_type_arguments(),
                                            kNoneFree, Heap::kNew));
        // By using TypeEquality::kInSubtypeTest, we throw a wider net than
        // using canonical or syntactical equality and may reject more
        // problematic declarations.
        if (!instantiated_pending_arguments.IsSubvectorEquivalent(
                instantiated_arguments, first_type_param, num_type_params,
                TypeEquality::kInSubtypeTest)) {
          const String& type_name = String::Handle(zone, type.Name());
          ReportError("illegal recursive type '%s'", type_name.ToCString());
        }
      }
    }
  }
}

// Expand the type arguments of the given type and finalize its full type
// argument vector. Return the number of type arguments (0 for a raw type).
intptr_t ClassFinalizer::ExpandAndFinalizeTypeArguments(
    Zone* zone,
    const AbstractType& type,
    PendingTypes* pending_types) {
  // The type class does not need to be finalized in order to finalize the type.
  // Also, the type parameters of the type class must be finalized.
  Class& type_class = Class::Handle(zone, type.type_class());
  type_class.EnsureDeclarationLoaded();

  // The finalized type argument vector needs num_type_arguments types.
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  // The class has num_type_parameters type parameters.
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // Initialize the type argument vector.
  // A null type argument vector indicates a raw type.
  TypeArguments& arguments = TypeArguments::Handle(zone, type.arguments());
  ASSERT(arguments.IsNull() || (arguments.Length() == num_type_parameters));

  // The full type argument vector consists of the type arguments of the
  // super types of type_class, which are initialized from the parsed
  // type arguments, followed by the parsed type arguments.
  TypeArguments& full_arguments = TypeArguments::Handle(zone);
  if (num_type_arguments > 0) {
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
          if (type_arg.IsTypeRef()) {
            // Dereferencing the TypeRef 'rotates' the cycle in the recursive
            // type argument, so that the top level type arguments of the type
            // do not start with a TypeRef, for better readability and possibly
            // fewer later dereferences in various type traversal routines.
            // This rotation is not required for correctness.
            // The cycle containing TypeRefs always involves type arguments of
            // the super class in the flatten argument vector, so it is safe to
            // remove TypeRefs from type arguments corresponding to the type
            // parameters of the type class.
            // Such TypeRefs may appear after instantiation of types at runtime.
            type_arg = TypeRef::Cast(type_arg).type();
          }
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
          if (!type_arg.IsBeingFinalized()) {
            type_arg = FinalizeType(type_arg, kFinalize, pending_types);
          } else {
            ASSERT(type_arg.IsTypeParameter());
            // The bound of the type parameter is still being finalized.
          }
          full_arguments.SetTypeAt(offset + i, type_arg);
        }
      }
      if (offset > 0) {
        TrailPtr trail = new Trail(zone, 4);
        FillAndFinalizeTypeArguments(zone, type_class, full_arguments, offset,
                                     pending_types, trail);
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
void ClassFinalizer::FillAndFinalizeTypeArguments(
    Zone* zone,
    const Class& cls,
    const TypeArguments& arguments,
    intptr_t num_uninitialized_arguments,
    PendingTypes* pending_types,
    TrailPtr trail) {
  ASSERT(arguments.Length() >= cls.NumTypeArguments());
  if (!cls.is_type_finalized()) {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    FinalizeTypeParameters(zone, cls, Object::null_function_type(), kFinalize);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  }
  AbstractType& super_type = AbstractType::Handle(zone, cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(zone, super_type.type_class());
    const intptr_t num_super_type_params = super_class.NumTypeParameters();
    const intptr_t num_super_type_args = super_class.NumTypeArguments();
    if (!super_type.IsFinalized() && !super_type.IsBeingFinalized()) {
      super_type = FinalizeType(super_type, kFinalize, pending_types);
      cls.set_super_type(super_type);
    }
    TypeArguments& super_type_args =
        TypeArguments::Handle(zone, super_type.arguments());
    // Offset of super type's type parameters in cls' type argument vector.
    const intptr_t super_offset = num_super_type_args - num_super_type_params;
    // If the super type is raw (i.e. super_type_args is null), set to dynamic.
    AbstractType& super_type_arg =
        AbstractType::Handle(zone, Type::DynamicType());
    for (intptr_t i = super_offset; i < num_uninitialized_arguments; i++) {
      if (!super_type_args.IsNull()) {
        super_type_arg = super_type_args.TypeAt(i);
        if (!super_type_arg.IsTypeRef()) {
          if (super_type_arg.IsBeingFinalized()) {
            // A type parameter being finalized indicates an unfinalized bound,
            // but the bound is not relevant here. Its index is finalized.
            if (!super_type_arg.IsTypeParameter()) {
              if (super_type_arg.IsType()) {
                CheckRecursiveType(super_type_arg, pending_types);
              } else {
                // The spec prohibits a typedef-declared function type to refer
                // to itself. However, self-reference can occur via type
                // arguments of the base class,
                // e.g. `class Derived extends Base<TypeDef<Derived>> {}`.
                ASSERT(super_type_arg.IsFunctionType());
              }
              if (FLAG_trace_type_finalization) {
                THR_Print(
                    "Creating TypeRef '%s': '%s'\n",
                    String::Handle(zone, super_type_arg.Name()).ToCString(),
                    super_type_arg.ToCString());
              }
              super_type_arg = TypeRef::New(super_type_arg);
            }
            super_type_args.SetTypeAt(i, super_type_arg);
          } else {
            if (!super_type_arg.IsFinalized()) {
              super_type_arg =
                  FinalizeType(super_type_arg, kFinalize, pending_types);
              super_type_args.SetTypeAt(i, super_type_arg);
              // Note that super_type_arg may still not be finalized here, in
              // which case it is a TypeRef to a legal recursive type.
            }
          }
        }
        // Instantiate super_type_arg with the current argument vector.
        if (!super_type_arg.IsInstantiated()) {
          if (FLAG_trace_type_finalization && super_type_arg.IsTypeRef()) {
            AbstractType& ref_type = AbstractType::Handle(
                zone, TypeRef::Cast(super_type_arg).type());
            THR_Print(
                "Instantiating TypeRef '%s': '%s'\n"
                "  instantiator: '%s'\n",
                String::Handle(zone, super_type_arg.Name()).ToCString(),
                ref_type.ToCString(), arguments.ToCString());
          }
          // In the typical case of an F-bounded type, the instantiation of the
          // super_type_arg from arguments is a fixpoint. Take the shortcut.
          // Example: class B<T>; class D<T> extends B<D<T>>;
          // While finalizing D<T>, the super type arg D<T> (a typeref) gets
          // instantiated from vector [T], yielding itself.
          if (super_type_arg.IsTypeRef() &&
              (super_type_arg.arguments() == arguments.ptr())) {
            ASSERT(super_type_arg.IsBeingFinalized());
            arguments.SetTypeAt(i, super_type_arg);
            continue;
          }
          super_type_arg = super_type_arg.InstantiateFrom(
              arguments, Object::null_type_arguments(), kNoneFree, Heap::kOld,
              trail);
          if (super_type_arg.IsBeingFinalized() &&
              !super_type_arg.IsTypeParameter()) {
            // The super_type_arg was instantiated from a type being finalized.
            // We need to finish finalizing its type arguments, unless it is a
            // type parameter, in which case there is nothing more to do.
            AbstractType& unfinalized_type = AbstractType::Handle(zone);
            if (super_type_arg.IsTypeRef()) {
              unfinalized_type = TypeRef::Cast(super_type_arg).type();
            } else {
              ASSERT(super_type_arg.IsType());
              unfinalized_type = super_type_arg.ptr();
            }
            if (FLAG_trace_type_finalization) {
              THR_Print(
                  "Instantiated unfinalized '%s': '%s'\n",
                  String::Handle(zone, unfinalized_type.Name()).ToCString(),
                  unfinalized_type.ToCString());
            }
            if (unfinalized_type.IsType()) {
              CheckRecursiveType(unfinalized_type, pending_types);
              pending_types->Add(unfinalized_type);
            }
            const Class& super_cls =
                Class::Handle(zone, unfinalized_type.type_class());
            const TypeArguments& super_args =
                TypeArguments::Handle(zone, unfinalized_type.arguments());
            // Mark as finalized before finalizing to avoid cycles.
            unfinalized_type.SetIsFinalized();
            // Although the instantiator is different between cls and super_cls,
            // we still need to pass the current instantiation trail as to avoid
            // divergence. Finalizing the type arguments of super_cls may indeed
            // recursively require instantiating the same type_refs already
            // present in the trail (see issue #29949).
            FillAndFinalizeTypeArguments(
                zone, super_cls, super_args,
                super_cls.NumTypeArguments() - super_cls.NumTypeParameters(),
                pending_types, trail);
            if (FLAG_trace_type_finalization) {
              THR_Print(
                  "Finalized instantiated '%s': '%s'\n",
                  String::Handle(zone, unfinalized_type.Name()).ToCString(),
                  unfinalized_type.ToCString());
            }
          }
        }
      }
      arguments.SetTypeAt(i, super_type_arg);
    }
    FillAndFinalizeTypeArguments(zone, super_class, arguments, super_offset,
                                 pending_types, trail);
  }
}

TypeArgumentsPtr ClassFinalizer::FinalizeTypeArguments(
    Zone* zone,
    const TypeArguments& type_args,
    FinalizationKind finalization,
    PendingTypes* pending_types) {
  if (type_args.IsNull()) return TypeArguments::null();
  ASSERT(type_args.ptr() != Object::empty_type_arguments().ptr());
  const intptr_t len = type_args.Length();
  AbstractType& type = AbstractType::Handle(zone);
  AbstractType& finalized_type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < len; i++) {
    type = type_args.TypeAt(i);
    if (type.IsBeingFinalized()) {
      ASSERT(finalization < kCanonicalize);
      continue;
    }
    finalized_type = FinalizeType(type, kFinalize, pending_types);
    if (type.ptr() != finalized_type.ptr()) {
      type_args.SetTypeAt(i, finalized_type);
    }
  }
  if (finalization >= kCanonicalize) {
    return type_args.Canonicalize(Thread::Current(), nullptr);
  }
  return type_args.ptr();
}

AbstractTypePtr ClassFinalizer::FinalizeType(const AbstractType& type,
                                             FinalizationKind finalization,
                                             PendingTypes* pending_types) {
  // Only the 'root' type of the graph can be canonicalized, after all depending
  // types have been bound checked.
  ASSERT((pending_types == NULL) || (finalization < kCanonicalize));
  if (type.IsFinalized()) {
    // Ensure type is canonical if canonicalization is requested.
    if ((finalization >= kCanonicalize) && !type.IsCanonical() &&
        !type.IsBeingFinalized()) {
      return type.Canonicalize(Thread::Current(), nullptr);
    }
    return type.ptr();
  }

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();

  if (type.IsTypeRef()) {
    if (type.IsBeingFinalized()) {
      // The referenced type will be finalized later by the code that set the
      // is_being_finalized mark bit.
      return type.ptr();
    }
    AbstractType& ref_type =
        AbstractType::Handle(zone, TypeRef::Cast(type).type());
    ref_type = FinalizeType(ref_type, finalization, pending_types);
    TypeRef::Cast(type).set_type(ref_type);
    return type.ptr();
  }

  // Recursive types must be processed in FillAndFinalizeTypeArguments() and
  // cannot be encountered here.
  ASSERT(!type.IsBeingFinalized());

  // Mark the type as being finalized in order to detect self reference.
  type.SetIsBeingFinalized();

  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type '%s'\n",
              String::Handle(zone, type.Name()).ToCString());
  }

  if (type.IsTypeParameter()) {
    const TypeParameter& type_parameter = TypeParameter::Cast(type);
    const Class& parameterized_class =
        Class::Handle(zone, type_parameter.parameterized_class());
    // The base and index of a function type parameter are eagerly calculated
    // upon loading and do not require adjustment here.
    if (!parameterized_class.IsNull()) {
      // The index must reflect the position of this type parameter in the type
      // arguments vector of its parameterized class. The offset to add is the
      // number of type arguments in the super type, which is equal to the
      // difference in number of type arguments and type parameters of the
      // parameterized class.
      const intptr_t offset = parameterized_class.NumTypeArguments() -
                              parameterized_class.NumTypeParameters();
      type_parameter.set_base(offset);  // Informative, but not needed.
      type_parameter.set_index(type_parameter.index() + offset);

      // Remove the reference to the parameterized class.
      type_parameter.set_parameterized_class_id(kClassCid);
    }

    type_parameter.SetIsFinalized();
    AbstractType& upper_bound = AbstractType::Handle(zone);
    upper_bound = type_parameter.bound();
    if (!upper_bound.IsBeingFinalized()) {
      upper_bound = FinalizeType(upper_bound, kFinalize);
      type_parameter.set_bound(upper_bound);
    }

    if (FLAG_trace_type_finalization) {
      THR_Print("Done finalizing type parameter at index %" Pd "\n",
                type_parameter.index());
    }

    if (finalization >= kCanonicalize) {
      return type_parameter.Canonicalize(thread, nullptr);
    }
    return type_parameter.ptr();
  }

  // If the type is a function type, we also need to finalize the types in its
  // signature, i.e. finalize the result type and parameter types of the
  // signature function of this function type.
  if (type.IsFunctionType()) {
    return FinalizeSignature(zone, FunctionType::Cast(type), finalization,
                             pending_types);
  }

  // This type is the root type of the type graph if no pending types queue is
  // allocated yet. A function type is a collection of types, but not a root.
  const bool is_root_type = pending_types == NULL;
  if (is_root_type) {
    pending_types = new PendingTypes(zone, 4);
  }

  // At this point, we can only have a Type.
  ASSERT(type.IsType());
  pending_types->Add(type);

  const intptr_t num_expanded_type_arguments =
      ExpandAndFinalizeTypeArguments(zone, type, pending_types);

  // Self referencing types may get finalized indirectly.
  if (!type.IsFinalized()) {
    if (FLAG_trace_type_finalization) {
      THR_Print("Marking type '%s' as finalized\n",
                String::Handle(zone, type.Name()).ToCString());
    }
    // Mark the type as finalized.
    type.SetIsFinalized();
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
          AbstractType::Handle(zone, type.Canonicalize(thread, nullptr));
      THR_Print("Done canonicalizing type '%s'\n",
                String::Handle(zone, canonical_type.Name()).ToCString());
      return canonical_type.ptr();
    }
    return type.Canonicalize(thread, nullptr);
  } else {
    return type.ptr();
  }
}

AbstractTypePtr ClassFinalizer::FinalizeSignature(Zone* zone,
                                                  const FunctionType& signature,
                                                  FinalizationKind finalization,
                                                  PendingTypes* pending_types) {
  // Finalize signature type parameter upper bounds and default args.
  FinalizeTypeParameters(zone, Object::null_class(), signature, finalization,
                         pending_types);

  AbstractType& type = AbstractType::Handle(zone);
  AbstractType& finalized_type = AbstractType::Handle(zone);
  // Finalize result type.
  type = signature.result_type();
  finalized_type = FinalizeType(type, kFinalize, pending_types);
  if (finalized_type.ptr() != type.ptr()) {
    signature.set_result_type(finalized_type);
  }
  // Finalize formal parameter types.
  const intptr_t num_parameters = signature.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = signature.ParameterTypeAt(i);
    finalized_type = FinalizeType(type, kFinalize, pending_types);
    if (type.ptr() != finalized_type.ptr()) {
      signature.SetParameterTypeAt(i, finalized_type);
    }
  }

  if (FLAG_trace_type_finalization) {
    THR_Print("Marking function type '%s' as finalized\n",
              String::Handle(zone, signature.Name()).ToCString());
  }
  signature.SetIsFinalized();

  if (finalization >= kCanonicalize) {
    return signature.Canonicalize(Thread::Current(), nullptr);
  }
  return signature.ptr();
}

#if !defined(DART_PRECOMPILED_RUNTIME)

#if defined(TARGET_ARCH_X64)
static bool IsPotentialExactGeneric(const AbstractType& type) {
  // TODO(dartbug.com/34170) Investigate supporting this for fields with types
  // that depend on type parameters of the enclosing class.
  if (type.IsType() && !type.IsDartFunctionType() && type.IsInstantiated() &&
      !type.IsFutureOrType()) {
    const Class& cls = Class::Handle(type.type_class());
    return cls.IsGeneric();
  }

  return false;
}
#else
// TODO(dartbug.com/34170) Support other architectures.
static bool IsPotentialExactGeneric(const AbstractType& type) {
  return false;
}
#endif

void ClassFinalizer::FinalizeMemberTypes(const Class& cls) {
  // Note that getters and setters are explicitly listed as such in the list of
  // functions of a class, so we do not need to consider fields as implicitly
  // generating getters and setters.
  // Most overriding conflicts are only static warnings, i.e. they are not
  // reported as compile-time errors by the vm.
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

  // Finalize type of fields and check for conflicts in super classes.
  auto isolate_group = IsolateGroup::Current();
  Zone* zone = Thread::Current()->zone();
  Array& array = Array::Handle(zone, cls.fields());
  Field& field = Field::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);
  Function& function = Function::Handle(zone);
  FunctionType& signature = FunctionType::Handle(zone);
  const intptr_t num_fields = array.Length();
  const bool track_exactness = isolate_group->use_field_guards();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    type = FinalizeType(type);
    field.SetFieldType(type);
    if (track_exactness && IsPotentialExactGeneric(type)) {
      field.set_static_type_exactness_state(
          StaticTypeExactnessState::Uninitialized());
    }
    function = field.InitializerFunction();
    if (!function.IsNull()) {
      // TODO(regis): It looks like the initializer is never set at this point.
      // Remove this finalization code?
      signature = function.signature();
      signature ^= FinalizeType(signature);
      function.SetSignature(signature);
    }
  }
  // Finalize function signatures and check for conflicts in super classes and
  // interfaces.
  array = cls.current_functions();
  const intptr_t num_functions = array.Length();
  for (intptr_t i = 0; i < num_functions; i++) {
    function ^= array.At(i);
    signature = function.signature();
    signature ^= FinalizeType(signature);
    function.SetSignature(signature);
    if (function.IsSetterFunction() || function.IsImplicitSetterFunction()) {
      continue;
    }
  }
}

// For a class used as an interface marks this class and all its superclasses
// implemented.
//
// Does not mark its interfaces implemented because those would already be
// marked as such.
static void MarkImplemented(Zone* zone, const Class& iface) {
  if (iface.is_implemented()) {
    return;
  }

  Class& cls = Class::Handle(zone, iface.ptr());
  AbstractType& type = AbstractType::Handle(zone);

  while (!cls.is_implemented()) {
    cls.set_is_implemented();

    type = cls.super_type();
    if (type.IsNull() || type.IsObjectType()) {
      break;
    }
    cls = type.type_class();
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeTypesInClass(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  cls.EnsureDeclarationLoaded();
  if (cls.is_type_finalized()) {
    return;
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Zone* zone = thread->zone();
  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (cls.is_type_finalized()) {
    return;
  }

  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize types in %s\n", cls.ToCString());
  }
  // Finalize super class.
  Class& super_class = Class::Handle(zone, cls.SuperClass());
  if (!super_class.IsNull()) {
    FinalizeTypesInClass(super_class);
  }
  // Finalize type parameters before finalizing the super type.
  FinalizeTypeParameters(zone, cls, Object::null_function_type(),
                         kCanonicalize);
  ASSERT(super_class.ptr() == cls.SuperClass());  // Not modified.
  ASSERT(super_class.IsNull() || super_class.is_type_finalized());
  // Finalize super type.
  AbstractType& super_type = AbstractType::Handle(zone, cls.super_type());
  if (!super_type.IsNull()) {
    super_type = FinalizeType(super_type);
    cls.set_super_type(super_type);
  }
  // Finalize interface types (but not necessarily interface classes).
  Array& interface_types = Array::Handle(zone, cls.interfaces());
  AbstractType& interface_type = AbstractType::Handle(zone);
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    interface_type = FinalizeType(interface_type);
    interface_types.SetAt(i, interface_type);
  }
  cls.set_is_type_finalized();

  RegisterClassInHierarchy(thread->zone(), cls);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void ClassFinalizer::RegisterClassInHierarchy(Zone* zone, const Class& cls) {
  auto& type = AbstractType::Handle(zone, cls.super_type());
  auto& other_cls = Class::Handle(zone);
  // Add this class to the direct subclasses of the superclass, unless the
  // superclass is Object.
  if (!type.IsNull() && !type.IsObjectType()) {
    other_cls = cls.SuperClass();
    ASSERT(!other_cls.IsNull());
    other_cls.AddDirectSubclass(cls);
  }

  // Add this class as an implementor to the implemented interface's type
  // classes.
  const auto& interfaces = Array::Handle(zone, cls.interfaces());
  const intptr_t mixin_index =
      cls.is_transformed_mixin_application() ? interfaces.Length() - 1 : -1;
  for (intptr_t i = 0; i < interfaces.Length(); ++i) {
    type ^= interfaces.At(i);
    other_cls = type.type_class();
    MarkImplemented(zone, other_cls);
    other_cls.AddDirectImplementor(cls, /* is_mixin = */ i == mixin_index);
  }
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeClass(const Class& cls) {
  ASSERT(cls.is_type_finalized());
  if (cls.is_finalized()) {
    return;
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);

  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize %s\n", cls.ToCString());
  }

#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(),
                             "FinalizeClass");
  if (tbes.enabled()) {
    tbes.SetNumArguments(1);
    tbes.CopyArgument(0, "class", cls.ToCString());
  }
#endif  // defined(SUPPORT_TIMELINE)

  // If loading from a kernel, make sure that the class is fully loaded.
  ASSERT(cls.IsTopLevel() || (cls.kernel_offset() > 0));
  if (!cls.is_loaded()) {
    kernel::KernelLoader::FinishLoading(cls);
    if (cls.is_finalized()) {
      return;
    }
  }

  // Ensure super class is finalized.
  const Class& super = Class::Handle(cls.SuperClass());
  if (!super.IsNull()) {
    FinalizeClass(super);
    if (cls.is_finalized()) {
      return;
    }
  }
  // Mark as loaded and finalized.
  cls.Finalize();
  if (FLAG_print_classes) {
    PrintClassInformation(cls);
  }
  FinalizeMemberTypes(cls);

  if (cls.is_enum_class() && !FLAG_precompiled_mode) {
    AllocateEnumValues(cls);
  }

  // The rest of finalization for non-top-level class has to be done with
  // stopped mutators. It will be done by AllocateFinalizeClass. before new
  // instance of a class is created in GetAllocationStubForClass.
  if (cls.IsTopLevel()) {
    cls.set_is_allocate_finalized();
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

#if !defined(DART_PRECOMPILED_RUNTIME)

ErrorPtr ClassFinalizer::AllocateFinalizeClass(const Class& cls) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(cls.is_finalized());
  ASSERT(!cls.is_allocate_finalized());

  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);

  if (FLAG_trace_class_finalization) {
    THR_Print("Allocate finalize %s\n", cls.ToCString());
  }

#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(),
                             "AllocateFinalizeClass");
  if (tbes.enabled()) {
    tbes.SetNumArguments(1);
    tbes.CopyArgument(0, "class", cls.ToCString());
  }
#endif  // defined(SUPPORT_TIMELINE)

  // Run additional checks after all types are finalized.
  if (FLAG_use_cha_deopt && !cls.IsTopLevel()) {
    {
      GrowableArray<intptr_t> cids;
      CollectFinalizedSuperClasses(cls, &cids);
      CollectImmediateSuperInterfaces(cls, &cids);
      RemoveCHAOptimizedCode(cls, cids);
    }

    Zone* zone = thread->zone();
    ClassTable* class_table = thread->isolate_group()->class_table();
    auto& interface_class = Class::Handle(zone);

    // We scan every interface this [cls] implements and invalidate all CHA
    // code which depends on knowing the implementors of that interface.
    {
      GrowableArray<intptr_t> cids;
      InterfaceFinder finder(zone, class_table, &cids);
      finder.FindAllInterfaces(cls);
      for (intptr_t j = 0; j < cids.length(); ++j) {
        interface_class = class_table->At(cids[j]);
        interface_class.DisableCHAImplementorUsers();
      }
    }
  }

  cls.set_is_allocate_finalized();
  return Error::null();
}

ErrorPtr ClassFinalizer::LoadClassMembers(const Class& cls) {
  ASSERT(IsolateGroup::Current()->program_lock()->IsCurrentThreadWriter());
  ASSERT(!cls.is_finalized());

  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    cls.EnsureDeclarationLoaded();
#endif
    ASSERT(cls.is_type_finalized());
    ClassFinalizer::FinalizeClass(cls);
    return Error::null();
  } else {
    return Thread::Current()->StealStickyError();
  }
}

// Eagerly allocate instances for enumeration values by evaluating
// static const field 'values'. Also, pre-allocate
// deleted sentinel value. This is needed to correctly
// migrate enumeration values in case of hot reload.
void ClassFinalizer::AllocateEnumValues(const Class& enum_cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ObjectStore* object_store = thread->isolate_group()->object_store();

  const auto& values_field =
      Field::Handle(zone, enum_cls.LookupStaticField(Symbols::Values()));
  if (!values_field.IsNull()) {
    ASSERT(values_field.is_static() && values_field.is_const());

    const auto& values =
        Object::Handle(zone, values_field.StaticConstFieldValue());
    if (values.IsError()) {
      ReportError(Error::Cast(values));
    }
    ASSERT(values.IsArray());
  }

  const auto& index_field =
      Field::Handle(zone, object_store->enum_index_field());
  ASSERT(!index_field.IsNull());

  const auto& name_field = Field::Handle(zone, object_store->enum_name_field());
  ASSERT(!name_field.IsNull());

  const auto& enum_name = String::Handle(zone, enum_cls.ScrubbedName());

  const auto& sentinel_ident = String::Handle(
      zone,
      Symbols::FromConcat(thread, Symbols::_DeletedEnumPrefix(), enum_name));
  auto& sentinel_value =
      Instance::Handle(zone, Instance::New(enum_cls, Heap::kOld));
  sentinel_value.SetField(index_field, Smi::Handle(zone, Smi::New(-1)));
  sentinel_value.SetField(name_field, sentinel_ident);
  sentinel_value = sentinel_value.Canonicalize(thread);
  ASSERT(!sentinel_value.IsNull());
  ASSERT(sentinel_value.IsCanonical());
  const auto& sentinel_field = Field::Handle(
      zone, enum_cls.LookupStaticField(Symbols::_DeletedEnumSentinel()));
  ASSERT(!sentinel_field.IsNull());

  // The static const field contains `Object::null()` instead of
  // `Object::sentinel()` - so it's not considered an initializing store.
  sentinel_field.SetStaticConstFieldValue(sentinel_value,
                                          /*assert_initializing_store*/ false);
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
  const Array& functions_array = Array::Handle(cls.current_functions());
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

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::ReportError(const Error& error) {
  Report::LongJump(error);
  UNREACHABLE();
}

void ClassFinalizer::ReportError(const char* format, ...) {
  va_list args;
  va_start(args, format);
  const Script& null_script = Script::Handle();
  Report::MessageV(Report::kError, null_script, TokenPosition::kNoSource,
                   Report::AtLocation, format, args);
  va_end(args);
  UNREACHABLE();
}

#if !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::VerifyImplicitFieldOffsets() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  auto isolate_group = thread->isolate_group();

  if (isolate_group->obfuscate()) {
    // Field names are obfuscated.
    return;
  }

  Zone* zone = thread->zone();
  const ClassTable& class_table = *(isolate_group->class_table());
  Class& cls = Class::Handle(zone);
  Array& fields_array = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  String& name = String::Handle(zone);
  String& expected_name = String::Handle(zone);
  Error& error = Error::Handle(zone);
  TypeParameter& type_param = TypeParameter::Handle(zone);

  // Now verify field offsets of '_ByteBuffer' class.
  cls = class_table.At(kByteBufferCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  fields_array ^= cls.fields();
  ASSERT(fields_array.Length() == ByteBuffer::NumberOfFields());
  field ^= fields_array.At(0);
  ASSERT(field.HostOffset() == ByteBuffer::data_offset());
  name ^= field.name();
  expected_name ^= String::New("_data");
  ASSERT(String::EqualsIgnoringPrivateKey(name, expected_name));

  // Now verify field offsets of 'Pointer' class.
  cls = class_table.At(kPointerCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  ASSERT(cls.NumTypeParameters() == 1);
  type_param = cls.TypeParameterAt(0);
  ASSERT(Pointer::kNativeTypeArgPos == type_param.index());
#endif
}

void ClassFinalizer::SortClasses() {
  auto T = Thread::Current();
  StackZone stack_zone(T);
  auto Z = T->zone();
  auto IG = T->isolate_group();

  // Prevent background compiler from adding deferred classes or canonicalizing
  // new types while classes are being sorted and type hashes are modified.
  NoBackgroundCompilerScope no_bg_compiler(T);
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());

  ClassTable* table = IG->class_table();
  intptr_t num_cids = table->NumCids();

  std::unique_ptr<intptr_t[]> old_to_new_cid(new intptr_t[num_cids]);

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
    if (!cls.is_declaration_loaded()) {
      continue;
    }
    if (cls.SuperClass() == IG->object_store()->object_class()) {
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
  RemapClassIds(old_to_new_cid.get());
  RehashTypes();          // Types use cid's as part of their hashes.
  IG->RehashConstants();  // Const objects use cid's as part of their hashes.
}

class CidRewriteVisitor : public ObjectVisitor {
 public:
  explicit CidRewriteVisitor(intptr_t* old_to_new_cids)
      : old_to_new_cids_(old_to_new_cids) {}

  intptr_t Map(intptr_t cid) {
    ASSERT(cid != -1);
    return old_to_new_cids_[cid];
  }

  void VisitObject(ObjectPtr obj) {
    if (obj->IsClass()) {
      ClassPtr cls = Class::RawCast(obj);
      const classid_t old_cid = cls->untag()->id_;
      if (ClassTable::IsTopLevelCid(old_cid)) {
        // We don't remap cids of top level classes.
        return;
      }
      cls->untag()->id_ = Map(old_cid);
    } else if (obj->IsField()) {
      FieldPtr field = Field::RawCast(obj);
      field->untag()->guarded_cid_ = Map(field->untag()->guarded_cid_);
      field->untag()->is_nullable_ = Map(field->untag()->is_nullable_);
    } else if (obj->IsTypeParameter()) {
      TypeParameterPtr param = TypeParameter::RawCast(obj);
      param->untag()->parameterized_class_id_ =
          Map(param->untag()->parameterized_class_id_);
    } else if (obj->IsType()) {
      TypePtr type = Type::RawCast(obj);
      type->untag()->type_class_id_ = Map(type->untag()->type_class_id_);
    } else {
      intptr_t old_cid = obj->GetClassId();
      intptr_t new_cid = Map(old_cid);
      if (old_cid != new_cid) {
        // Don't touch objects that are unchanged. In particular, Instructions,
        // which are write-protected.
        obj->untag()->SetClassIdUnsynchronized(new_cid);
      }
    }
  }

 private:
  intptr_t* old_to_new_cids_;
};

void ClassFinalizer::RemapClassIds(intptr_t* old_to_new_cid) {
  Thread* T = Thread::Current();
  IsolateGroup* IG = T->isolate_group();

  // Code, ICData, allocation stubs have now-invalid cids.
  ClearAllCode();

  {
    // The [HeapIterationScope] also safepoints all threads.
    HeapIterationScope his(T);

    IG->shared_class_table()->Remap(old_to_new_cid);
    IG->set_remapping_cids(true);

    // Update the class table. Do it before rewriting cids in headers, as
    // the heap walkers load an object's size *after* calling the visitor.
    IG->class_table()->Remap(old_to_new_cid);

    // Rewrite cids in headers and cids in Classes, Fields, Types and
    // TypeParameters.
    {
      CidRewriteVisitor visitor(old_to_new_cid);
      IG->heap()->VisitObjects(&visitor);
    }

    IG->set_remapping_cids(false);
#if defined(DEBUG)
    IG->class_table()->Validate();
#endif
  }

#if defined(DEBUG)
  IG->heap()->Verify();
#endif
}

// Clears the cached canonicalized hash codes for all instances which directly
// (or indirectly) depend on class ids.
//
// In the Dart VM heap the following instances directly use cids for the
// computation of canonical hash codes:
//
//    * TypePtr (due to UntaggedType::type_class_id_)
//    * TypeParameterPtr (due to UntaggedTypeParameter::parameterized_class_id_)
//
// The following instances use cids for the computation of canonical hash codes
// indirectly:
//
//    * TypeRefPtr (due to UntaggedTypeRef::type_->type_class_id)
//    * TypePtr (due to type arguments)
//    * FunctionTypePtr (due to the result and parameter types)
//    * TypeArgumentsPtr (due to type references)
//    * InstancePtr (due to instance fields)
//    * ArrayPtr (due to type arguments & array entries)
//
// Caching of the canonical hash codes happens for:
//
//    * UntaggedType::hash_
//    * UntaggedFunctionType::hash_
//    * UntaggedTypeParameter::hash_
//    * UntaggedTypeArguments::hash_
//    * InstancePtr (weak table)
//    * ArrayPtr (weak table)
//
// No caching of canonical hash codes (i.e. it gets re-computed every time)
// happens for:
//
//    * TypeRefPtr (computed via UntaggedTypeRef::type_->type_class_id)
//
// Usages of canonical hash codes are:
//
//   * ObjectStore::canonical_types()
//   * ObjectStore::canonical_function_types()
//   * ObjectStore::canonical_type_parameters()
//   * ObjectStore::canonical_type_arguments()
//   * Class::constants()
//
class ClearTypeHashVisitor : public ObjectVisitor {
 public:
  explicit ClearTypeHashVisitor(Zone* zone)
      : type_param_(TypeParameter::Handle(zone)),
        type_(Type::Handle(zone)),
        function_type_(FunctionType::Handle(zone)),
        type_args_(TypeArguments::Handle(zone)) {}

  void VisitObject(ObjectPtr obj) {
    if (obj->IsTypeParameter()) {
      type_param_ ^= obj;
      type_param_.SetHash(0);
    } else if (obj->IsType()) {
      type_ ^= obj;
      type_.SetHash(0);
    } else if (obj->IsFunctionType()) {
      function_type_ ^= obj;
      function_type_.SetHash(0);
    } else if (obj->IsTypeArguments()) {
      type_args_ ^= obj;
      type_args_.SetHash(0);
    }
  }

 private:
  TypeParameter& type_param_;
  Type& type_;
  FunctionType& function_type_;
  TypeArguments& type_args_;
};

void ClassFinalizer::RehashTypes() {
  auto T = Thread::Current();
  auto Z = T->zone();
  auto IG = T->isolate_group();

  // Clear all cached hash values.
  {
    HeapIterationScope his(T);
    ClearTypeHashVisitor visitor(Z);
    IG->heap()->VisitObjects(&visitor);
  }

  // Rehash the canonical Types table.
  ObjectStore* object_store = IG->object_store();
  Array& types = Array::Handle(Z);
  Type& type = Type::Handle(Z);
  {
    CanonicalTypeSet types_table(Z, object_store->canonical_types());
    types = HashTables::ToArray(types_table, false);
    types_table.Release();
  }

  intptr_t dict_size = Utils::RoundUpToPowerOfTwo(types.Length() * 4 / 3);
  CanonicalTypeSet types_table(
      Z, HashTables::New<CanonicalTypeSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < types.Length(); i++) {
    type ^= types.At(i);
    bool present = types_table.Insert(type);
    // Two recursive types with different topology (and hashes) may be equal.
    ASSERT(!present || type.IsRecursive());
  }
  object_store->set_canonical_types(types_table.Release());

  // Rehash the canonical FunctionTypes table.
  Array& function_types = Array::Handle(Z);
  FunctionType& function_type = FunctionType::Handle(Z);
  {
    CanonicalFunctionTypeSet function_types_table(
        Z, object_store->canonical_function_types());
    function_types = HashTables::ToArray(function_types_table, false);
    function_types_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(function_types.Length() * 4 / 3);
  CanonicalFunctionTypeSet function_types_table(
      Z, HashTables::New<CanonicalFunctionTypeSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < function_types.Length(); i++) {
    function_type ^= function_types.At(i);
    bool present = function_types_table.Insert(function_type);
    // Two recursive types with different topology (and hashes) may be equal.
    ASSERT(!present || function_type.IsRecursive());
  }
  object_store->set_canonical_function_types(function_types_table.Release());

  // Rehash the canonical TypeParameters table.
  Array& typeparams = Array::Handle(Z);
  TypeParameter& typeparam = TypeParameter::Handle(Z);
  {
    CanonicalTypeParameterSet typeparams_table(
        Z, object_store->canonical_type_parameters());
    typeparams = HashTables::ToArray(typeparams_table, false);
    typeparams_table.Release();
  }

  dict_size = Utils::RoundUpToPowerOfTwo(typeparams.Length() * 4 / 3);
  CanonicalTypeParameterSet typeparams_table(
      Z, HashTables::New<CanonicalTypeParameterSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < typeparams.Length(); i++) {
    typeparam ^= typeparams.At(i);
    bool present = typeparams_table.Insert(typeparam);
    // Two recursive types with different topology (and hashes) may be equal.
    ASSERT(!present || typeparam.IsRecursive());
  }
  object_store->set_canonical_type_parameters(typeparams_table.Release());

  // Rehash the canonical TypeArguments table.
  Array& typeargs = Array::Handle(Z);
  TypeArguments& typearg = TypeArguments::Handle(Z);
  {
    CanonicalTypeArgumentsSet typeargs_table(
        Z, object_store->canonical_type_arguments());
    typeargs = HashTables::ToArray(typeargs_table, false);
    typeargs_table.Release();
  }

  // The canonical constant tables use canonical hashcodes which can change
  // due to cid-renumbering.
  IG->RehashConstants();

  dict_size = Utils::RoundUpToPowerOfTwo(typeargs.Length() * 4 / 3);
  CanonicalTypeArgumentsSet typeargs_table(
      Z, HashTables::New<CanonicalTypeArgumentsSet>(dict_size, Heap::kOld));
  for (intptr_t i = 0; i < typeargs.Length(); i++) {
    typearg ^= typeargs.At(i);
    bool present = typeargs_table.Insert(typearg);
    // Two recursive types with different topology (and hashes) may be equal.
    ASSERT(!present || typearg.IsRecursive());
  }
  object_store->set_canonical_type_arguments(typeargs_table.Release());
}

void ClassFinalizer::ClearAllCode(bool including_nonchanging_cids) {
  auto const thread = Thread::Current();
  auto const isolate_group = thread->isolate_group();
  SafepointWriteRwLocker ml(thread, isolate_group->program_lock());
  StackZone stack_zone(thread);
  auto const zone = thread->zone();

  class ClearCodeVisitor : public FunctionVisitor {
   public:
    ClearCodeVisitor(Zone* zone, bool force)
        : force_(force),
          pool_(ObjectPool::Handle(zone)),
          entry_(Object::Handle(zone)) {}

    void VisitClass(const Class& cls) {
      if (force_ || cls.id() >= kNumPredefinedCids) {
        cls.DisableAllocationStub();
      }
    }

    void VisitFunction(const Function& function) {
      function.ClearCode();
      function.ClearICDataArray();
    }

   private:
    const bool force_;
    ObjectPool& pool_;
    Object& entry_;
  };

  ClearCodeVisitor visitor(zone, including_nonchanging_cids);
  ProgramVisitor::WalkProgram(zone, isolate_group, &visitor);

  // Apart from normal function code and allocation stubs we have two global
  // code objects to clear.
  if (including_nonchanging_cids) {
    auto object_store = isolate_group->object_store();
    auto& null_code = Code::Handle(zone);
    object_store->set_build_generic_method_extractor_code(null_code);
    object_store->set_build_nongeneric_method_extractor_code(null_code);
  }
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
