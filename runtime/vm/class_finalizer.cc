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
  Class& cls = Class::Handle(cls_.raw());
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

    *current_class = klass.raw();
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

#if defined(DEBUG)
    for (intptr_t i = 0; i < class_array.Length(); i++) {
      cls ^= class_array.At(i);
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

#if !defined(DART_PRECOMPILED_RUNTIME)
void ClassFinalizer::VerifyBootstrapClasses() {
  if (FLAG_trace_class_finalization) {
    OS::PrintErr("VerifyBootstrapClasses START.\n");
  }
  ObjectStore* object_store = Isolate::Current()->object_store();

  Class& cls = Class::Handle();
#if defined(DEBUG)
  // Basic checking.
  cls = object_store->object_class();
  ASSERT(Instance::InstanceSize() == cls.host_instance_size());
  cls = object_store->integer_implementation_class();
  ASSERT(Integer::InstanceSize() == cls.host_instance_size());
  cls = object_store->smi_class();
  ASSERT(Smi::InstanceSize() == cls.host_instance_size());
  cls = object_store->mint_class();
  ASSERT(Mint::InstanceSize() == cls.host_instance_size());
  cls = object_store->one_byte_string_class();
  ASSERT(OneByteString::InstanceSize() == cls.host_instance_size());
  cls = object_store->two_byte_string_class();
  ASSERT(TwoByteString::InstanceSize() == cls.host_instance_size());
  cls = object_store->external_one_byte_string_class();
  ASSERT(ExternalOneByteString::InstanceSize() == cls.host_instance_size());
  cls = object_store->external_two_byte_string_class();
  ASSERT(ExternalTwoByteString::InstanceSize() == cls.host_instance_size());
  cls = object_store->double_class();
  ASSERT(Double::InstanceSize() == cls.host_instance_size());
  cls = object_store->bool_class();
  ASSERT(Bool::InstanceSize() == cls.host_instance_size());
  cls = object_store->array_class();
  ASSERT(Array::InstanceSize() == cls.host_instance_size());
  cls = object_store->immutable_array_class();
  ASSERT(ImmutableArray::InstanceSize() == cls.host_instance_size());
  cls = object_store->weak_property_class();
  ASSERT(WeakProperty::InstanceSize() == cls.host_instance_size());
  cls = object_store->linked_hash_map_class();
  ASSERT(LinkedHashMap::InstanceSize() == cls.host_instance_size());
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
  Isolate::Current()->heap()->Verify();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ClassFinalizer::FinalizeTypeParameters(const Class& cls) {
  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type parameters of '%s'\n",
              String::Handle(cls.Name()).ToCString());
  }
  // The type parameter bounds are not finalized here.
  const intptr_t offset = cls.NumTypeArguments() - cls.NumTypeParameters();
  const TypeArguments& type_parameters =
      TypeArguments::Handle(cls.type_parameters());
  if (!type_parameters.IsNull()) {
    TypeParameter& type_parameter = TypeParameter::Handle();
    const intptr_t num_types = type_parameters.Length();
    for (intptr_t i = 0; i < num_types; i++) {
      type_parameter ^= type_parameters.TypeAt(i);
      if (!type_parameter.IsFinalized()) {
        ASSERT(type_parameter.index() == i);
        type_parameter.set_index(offset + i);
        type_parameter.SetIsFinalized();
      } else {
        ASSERT(type_parameter.index() == offset + i);
      }
      // The declaration of a type parameter is canonical.
      ASSERT(type_parameter.IsDeclaration());
      ASSERT(type_parameter.IsCanonical());
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
void ClassFinalizer::CheckRecursiveType(const AbstractType& type,
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
  if (arguments.IsNull()) {
    // However, Kernel does not keep the relation between a function type and
    // its declaring typedef. Therefore, a typedef-declared function type may
    // refer to the still unfinalized typedef via a type in its signature.
    ASSERT(type.IsFunctionType());
    return;
  }
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
    if ((pending_type.raw() != type.raw()) && pending_type.IsType() &&
        (pending_type.type_class() == type_cls.raw())) {
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
    const AbstractType& type,
    PendingTypes* pending_types) {
  Zone* zone = Thread::Current()->zone();
  // The type class does not need to be finalized in order to finalize the type.
  // Also, the type parameters of the type class must be finalized.
  Class& type_class = Class::Handle(zone, type.type_class());
  type_class.EnsureDeclarationLoaded();
  if (!type_class.is_type_finalized()) {
    FinalizeTypeParameters(type_class);
  }

  // The finalized type argument vector needs num_type_arguments types.
  const intptr_t num_type_arguments = type_class.NumTypeArguments();
  // The class has num_type_parameters type parameters.
  const intptr_t num_type_parameters = type_class.NumTypeParameters();

  // Initialize the type argument vector.
  // A null type argument vector indicates a raw type.
  TypeArguments& arguments = TypeArguments::Handle(zone, type.arguments());
  ASSERT(arguments.IsNull() || (arguments.Length() == num_type_parameters));

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
          type_arg = FinalizeType(type_arg, kFinalize, pending_types);
          full_arguments.SetTypeAt(offset + i, type_arg);
        }
      }
      if (offset > 0) {
        TrailPtr trail = new Trail(zone, 4);
        FinalizeTypeArguments(type_class, full_arguments, offset, pending_types,
                              trail);
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
                                           PendingTypes* pending_types,
                                           TrailPtr trail) {
  ASSERT(arguments.Length() >= cls.NumTypeArguments());
  if (!cls.is_type_finalized()) {
    FinalizeTypeParameters(cls);
  }
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    const Class& super_class = Class::Handle(super_type.type_class());
    const intptr_t num_super_type_params = super_class.NumTypeParameters();
    const intptr_t num_super_type_args = super_class.NumTypeArguments();
    if (!super_type.IsFinalized() && !super_type.IsBeingFinalized()) {
      super_type = FinalizeType(super_type, kFinalize, pending_types);
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
            CheckRecursiveType(super_type_arg, pending_types);
            if (FLAG_trace_type_finalization) {
              THR_Print("Creating TypeRef '%s': '%s'\n",
                        String::Handle(super_type_arg.Name()).ToCString(),
                        super_type_arg.ToCString());
            }
            super_type_arg = TypeRef::New(super_type_arg);
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
          super_type_arg = super_type_arg.InstantiateFrom(
              arguments, Object::null_type_arguments(), kNoneFree, Heap::kOld,
              trail);
          if (super_type_arg.IsBeingFinalized()) {
            // The super_type_arg was instantiated from a type being finalized.
            // We need to finish finalizing its type arguments.
            AbstractType& unfinalized_type = AbstractType::Handle();
            if (super_type_arg.IsTypeRef()) {
              unfinalized_type = TypeRef::Cast(super_type_arg).type();
            } else {
              ASSERT(super_type_arg.IsType());
              unfinalized_type = super_type_arg.raw();
            }
            if (FLAG_trace_type_finalization) {
              THR_Print("Instantiated unfinalized '%s': '%s'\n",
                        String::Handle(unfinalized_type.Name()).ToCString(),
                        unfinalized_type.ToCString());
            }
            CheckRecursiveType(unfinalized_type, pending_types);
            pending_types->Add(unfinalized_type);
            const Class& super_cls =
                Class::Handle(unfinalized_type.type_class());
            const TypeArguments& super_args =
                TypeArguments::Handle(unfinalized_type.arguments());
            // Mark as finalized before finalizing to avoid cycles.
            unfinalized_type.SetIsFinalized();
            // Although the instantiator is different between cls and super_cls,
            // we still need to pass the current instantiation trail as to avoid
            // divergence. Finalizing the type arguments of super_cls may indeed
            // recursively require instantiating the same type_refs already
            // present in the trail (see issue #29949).
            FinalizeTypeArguments(
                super_cls, super_args,
                super_cls.NumTypeArguments() - super_cls.NumTypeParameters(),
                pending_types, trail);
            if (FLAG_trace_type_finalization) {
              THR_Print("Finalized instantiated '%s': '%s'\n",
                        String::Handle(unfinalized_type.Name()).ToCString(),
                        unfinalized_type.ToCString());
            }
          }
        }
      }
      arguments.SetTypeAt(i, super_type_arg);
    }
    FinalizeTypeArguments(super_class, arguments, super_offset, pending_types,
                          trail);
  }
}

AbstractTypePtr ClassFinalizer::FinalizeType(const AbstractType& type,
                                             FinalizationKind finalization,
                                             PendingTypes* pending_types) {
  // Only the 'root' type of the graph can be canonicalized, after all depending
  // types have been bound checked.
  ASSERT((pending_types == NULL) || (finalization < kCanonicalize));
  if (type.IsFinalized()) {
    // Ensure type is canonical if canonicalization is requested.
    if ((finalization >= kCanonicalize) && !type.IsCanonical()) {
      return type.Canonicalize(Thread::Current(), nullptr);
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

  if (FLAG_trace_type_finalization) {
    THR_Print("Finalizing type '%s'\n",
              String::Handle(zone, type.Name()).ToCString());
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
    type_parameter.set_index(type_parameter.index() + offset);
    type_parameter.SetIsFinalized();

    if (FLAG_trace_type_finalization) {
      THR_Print("Done finalizing type parameter '%s' with index %" Pd "\n",
                String::Handle(zone, type_parameter.name()).ToCString(),
                type_parameter.index());
    }

    if (type_parameter.IsDeclaration()) {
      // The declaration of a type parameter is canonical.
      ASSERT(type_parameter.IsCanonical());
      return type_parameter.raw();
    }
    return type_parameter.Canonicalize(Thread::Current(), nullptr);
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
      ExpandAndFinalizeTypeArguments(type, pending_types);

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
          FinalizeSignature(signature, finalization);
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
          signature = signature.InstantiateSignatureFrom(
              instantiator_type_arguments, Object::null_type_arguments(),
              kNoneFree, Heap::kOld);
          // Note that if instantiator_type_arguments contains type parameters,
          // as in F<K>, the signature is still uninstantiated (the typedef type
          // parameters were substituted in the signature with typedef type
          // arguments). Note also that the function type parameters were not
          // modified.
          FinalizeSignature(signature, finalization);
        }
        fun_type.set_signature(signature);
      } else {
        FinalizeSignature(Function::Handle(zone, fun_type.signature()),
                          finalization);
      }
    }

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
      AbstractType& canonical_type = AbstractType::Handle(
          zone, type.Canonicalize(Thread::Current(), nullptr));
      THR_Print("Done canonicalizing type '%s'\n",
                String::Handle(zone, canonical_type.Name()).ToCString());
      return canonical_type.raw();
    }
    return type.Canonicalize(Thread::Current(), nullptr);
  } else {
    return type.raw();
  }
}

void ClassFinalizer::FinalizeSignature(const Function& function,
                                       FinalizationKind finalization) {
  AbstractType& type = AbstractType::Handle();
  AbstractType& finalized_type = AbstractType::Handle();
  // Finalize function type parameters, including their bounds and default args.
  const intptr_t num_parent_type_params = function.NumParentTypeParameters();
  const intptr_t num_type_params = function.NumTypeParameters();
  if (num_type_params > 0) {
    TypeParameter& type_param = TypeParameter::Handle();
    const TypeArguments& type_params =
        TypeArguments::Handle(function.type_parameters());
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      if (!type_param.IsFinalized()) {
        ASSERT(type_param.index() == i);
        type_param.set_index(num_parent_type_params + i);
        type_param.SetIsFinalized();
      } else {
        ASSERT(type_param.index() == num_parent_type_params + i);
      }
      // The declaration of a type parameter is canonical.
      ASSERT(type_param.IsDeclaration());
      ASSERT(type_param.IsCanonical());
    }
    for (intptr_t i = 0; i < num_type_params; i++) {
      type_param ^= type_params.TypeAt(i);
      type = type_param.bound();
      finalized_type = FinalizeType(type, finalization);
      if (finalized_type.raw() != type.raw()) {
        type_param.set_bound(finalized_type);
      }
      type = type_param.default_argument();
      finalized_type = FinalizeType(type, finalization);
      if (finalized_type.raw() != type.raw()) {
        type_param.set_default_argument(finalized_type);
      }
    }
    function.UpdateCachedDefaultTypeArguments(Thread::Current());
  }
  // Finalize result type.
  type = function.result_type();
  finalized_type = FinalizeType(type, finalization);
  if (finalized_type.raw() != type.raw()) {
    function.set_result_type(finalized_type);
  }
  // Finalize formal parameter types.
  const intptr_t num_parameters = function.NumParameters();
  for (intptr_t i = 0; i < num_parameters; i++) {
    type = function.ParameterTypeAt(i);
    finalized_type = FinalizeType(type, finalization);
    if (type.raw() != finalized_type.raw()) {
      function.SetParameterTypeAt(i, finalized_type);
    }
  }
}

// Finalize bounds and default arguments of the type parameters of class cls.
void ClassFinalizer::FinalizeUpperBounds(const Class& cls,
                                         FinalizationKind finalization) {
  const intptr_t num_type_params = cls.NumTypeParameters();
  TypeParameter& type_param = TypeParameter::Handle();
  AbstractType& type = AbstractType::Handle();
  const TypeArguments& type_params =
      TypeArguments::Handle(cls.type_parameters());
  ASSERT((type_params.IsNull() && (num_type_params == 0)) ||
         (type_params.Length() == num_type_params));
  for (intptr_t i = 0; i < num_type_params; i++) {
    type_param ^= type_params.TypeAt(i);
    // First, finalize the default argument (no cycles possible here).
    type = type_param.default_argument();
    type = FinalizeType(type, finalization);
    type_param.set_default_argument(type);
    // Next, finalize the bound.
    type = type_param.bound();
    // Bound may be finalized, but not canonical yet.
    if (type.IsCanonical() || type.IsBeingFinalized()) {
      // A bound involved in F-bounded quantification may form a cycle.
      continue;
    }
    type = FinalizeType(type, finalization);
    type_param.set_bound(type);
  }
}

#if defined(TARGET_ARCH_X64)
static bool IsPotentialExactGeneric(const AbstractType& type) {
  // TODO(dartbug.com/34170) Investigate supporting this for fields with types
  // that depend on type parameters of the enclosing class.
  if (type.IsType() && !type.IsFunctionType() && !type.IsDartFunctionType() &&
      type.IsInstantiated() && !type.IsFutureOrType()) {
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
  Isolate* isolate = Isolate::Current();
  Zone* zone = Thread::Current()->zone();
  Array& array = Array::Handle(zone, cls.fields());
  Field& field = Field::Handle(zone);
  AbstractType& type = AbstractType::Handle(zone);
  const intptr_t num_fields = array.Length();
  const bool track_exactness = isolate->use_field_guards();
  for (intptr_t i = 0; i < num_fields; i++) {
    field ^= array.At(i);
    type = field.type();
    type = FinalizeType(type);
    field.SetFieldType(type);
    if (track_exactness && IsPotentialExactGeneric(type)) {
      field.set_static_type_exactness_state(
          StaticTypeExactnessState::Uninitialized());
    }
  }
  // Finalize function signatures and check for conflicts in super classes and
  // interfaces.
  array = cls.current_functions();
  Function& function = Function::Handle(zone);
  const intptr_t num_functions = array.Length();
  for (intptr_t i = 0; i < num_functions; i++) {
    function ^= array.At(i);
    FinalizeSignature(function);
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

  Class& cls = Class::Handle(zone, iface.raw());
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

void ClassFinalizer::FinalizeTypesInClass(const Class& cls) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  cls.EnsureDeclarationLoaded();
  if (cls.is_type_finalized()) {
    return;
  }

  SafepointWriteRwLocker ml(thread, thread->isolate_group()->program_lock());
  if (cls.is_type_finalized()) {
    return;
  }

  if (FLAG_trace_class_finalization) {
    THR_Print("Finalize types in %s\n", cls.ToCString());
  }
  // Finalize super class.
  Class& super_class = Class::Handle(cls.SuperClass());
  if (!super_class.IsNull()) {
    FinalizeTypesInClass(super_class);
  }
  // Finalize type parameters before finalizing the super type.
  FinalizeTypeParameters(cls);
  ASSERT(super_class.IsNull() || super_class.is_type_finalized());
  FinalizeUpperBounds(cls);
  // Finalize super type.
  AbstractType& super_type = AbstractType::Handle(cls.super_type());
  if (!super_type.IsNull()) {
    super_type = FinalizeType(super_type);
    cls.set_super_type(super_type);
  }
  if (cls.IsTypedefClass()) {
    Function& signature = Function::Handle(cls.signature_function());
    Type& type = Type::Handle(signature.SignatureType());
    ASSERT(type.signature() == signature.raw());
    ASSERT(type.type_class() == cls.raw());

    cls.set_is_type_finalized();

    // Finalize the result and parameter types of the signature
    // function of this typedef class.
    FinalizeSignature(signature);  // Does not modify signature type.
    ASSERT(signature.SignatureType() == type.raw());

    // Finalize the signature type of this typedef.
    type ^= FinalizeType(type);
    ASSERT(type.type_class() == cls.raw());

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
  for (intptr_t i = 0; i < interface_types.Length(); i++) {
    interface_type ^= interface_types.At(i);
    interface_type = FinalizeType(interface_type);
    interface_types.SetAt(i, interface_type);
  }
  cls.set_is_type_finalized();

  RegisterClassInHierarchy(thread->zone(), cls);
}

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

void ClassFinalizer::FinalizeClass(const Class& cls) {
  ASSERT(cls.is_type_finalized());
  if (cls.is_finalized()) {
    return;
  }

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

#if !defined(DART_PRECOMPILED_RUNTIME)
  // If loading from a kernel, make sure that the class is fully loaded.
  ASSERT(cls.IsTopLevel() || (cls.kernel_offset() > 0));
  if (!cls.is_loaded()) {
    kernel::KernelLoader::FinishLoading(cls);
    if (cls.is_finalized()) {
      return;
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

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

  if (cls.is_enum_class()) {
    AllocateEnumValues(cls);
  }

  // The rest of finalization for non-top-level class has to be done with
  // stopped mutators. It will be done by AllocateFinalizeClass. before new
  // instance of a class is created in GetAllocationStubForClass.
  if (cls.IsTopLevel()) {
    cls.set_is_allocate_finalized();
  }
}

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
    ClassTable* class_table = thread->isolate()->class_table();
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
  ASSERT(Thread::Current()->IsMutatorThread());
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

  const String& enum_name = String::Handle(zone, enum_cls.ScrubbedName());

  const Array& fields = Array::Handle(zone, enum_cls.fields());
  Field& field = Field::Handle(zone);
  Instance& enum_value = Instance::Handle(zone);
  String& enum_ident = String::Handle(zone);

  enum_ident =
      Symbols::FromConcat(thread, Symbols::_DeletedEnumPrefix(), enum_name);
  enum_value = Instance::New(enum_cls, Heap::kOld);
  enum_value.SetField(index_field, Smi::Handle(zone, Smi::New(-1)));
  enum_value.SetField(name_field, enum_ident);
  enum_value = enum_value.Canonicalize(thread);
  ASSERT(!enum_value.IsNull());
  ASSERT(enum_value.IsCanonical());
  const Field& sentinel = Field::Handle(
      zone, enum_cls.LookupStaticField(Symbols::_DeletedEnumSentinel()));
  ASSERT(!sentinel.IsNull());
  sentinel.SetStaticValue(enum_value, true);

  ASSERT(enum_cls.kernel_offset() > 0);
  Error& error = Error::Handle(zone);
  for (intptr_t i = 0; i < fields.Length(); i++) {
    field = Field::RawCast(fields.At(i));
    if (!field.is_static() || !field.is_const() ||
        (sentinel.raw() == field.raw())) {
      continue;
    }
    // Hot-reload expects the static const fields to be evaluated when
    // performing a reload.
    if (!FLAG_precompiled_mode) {
      if (field.IsUninitialized()) {
        error = field.InitializeStatic();
        if (!error.IsNull()) {
          ReportError(error);
        }
      }
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

void ClassFinalizer::VerifyImplicitFieldOffsets() {
#ifdef DEBUG
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();

  if (isolate->obfuscate()) {
    // Field names are obfuscated.
    return;
  }

  Zone* zone = thread->zone();
  const ClassTable& class_table = *(isolate->class_table());
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
  cls = class_table.At(kFfiPointerCid);
  error = cls.EnsureIsFinalized(thread);
  ASSERT(error.IsNull());
  ASSERT(cls.NumTypeParameters() == 1);
  type_param ^= TypeParameter::RawCast(
      TypeArguments::Handle(cls.type_parameters()).TypeAt(0));
  ASSERT(Pointer::kNativeTypeArgPos == type_param.index());
#endif
}

void ClassFinalizer::SortClasses() {
  Thread* T = Thread::Current();
  Zone* Z = T->zone();
  Isolate* I = T->isolate();

  // Prevent background compiler from adding deferred classes or canonicalizing
  // new types while classes are being sorted and type hashes are modified.
  BackgroundCompiler::Stop(I);
  SafepointWriteRwLocker ml(T, T->isolate_group()->program_lock());

  ClassTable* table = I->class_table();
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
  RemapClassIds(old_to_new_cid.get());
  RehashTypes();         // Types use cid's as part of their hashes.
  I->RehashConstants();  // Const objects use cid's as part of their hashes.

  // Ensure any newly spawned isolate will apply this permutation map right
  // after kernel loading.
  I->group()->source()->cid_permutation_map = std::move(old_to_new_cid);
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
      const classid_t old_cid = cls->ptr()->id_;
      if (ClassTable::IsTopLevelCid(old_cid)) {
        // We don't remap cids of top level classes.
        return;
      }
      cls->ptr()->id_ = Map(old_cid);
    } else if (obj->IsField()) {
      FieldPtr field = Field::RawCast(obj);
      field->ptr()->guarded_cid_ = Map(field->ptr()->guarded_cid_);
      field->ptr()->is_nullable_ = Map(field->ptr()->is_nullable_);
    } else if (obj->IsTypeParameter()) {
      TypeParameterPtr param = TypeParameter::RawCast(obj);
      param->ptr()->parameterized_class_id_ =
          Map(param->ptr()->parameterized_class_id_);
    } else if (obj->IsType()) {
      TypePtr type = Type::RawCast(obj);
      ObjectPtr id = type->ptr()->type_class_id_;
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
        obj->ptr()->SetClassIdUnsynchronized(new_cid);
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
    IG->ForEachIsolate(
        [&](Isolate* I) {
          I->set_remapping_cids(true);

          // Update the class table. Do it before rewriting cids in headers, as
          // the heap walkers load an object's size *after* calling the visitor.
          I->class_table()->Remap(old_to_new_cid);
        },
        /*is_at_safepoint=*/true);

    // Rewrite cids in headers and cids in Classes, Fields, Types and
    // TypeParameters.
    {
      CidRewriteVisitor visitor(old_to_new_cid);
      IG->heap()->VisitObjects(&visitor);
    }

    IG->ForEachIsolate(
        [&](Isolate* I) {
          I->set_remapping_cids(false);
#if defined(DEBUG)
          I->class_table()->Validate();
#endif
        },
        /*is_at_safepoint=*/true);
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
//    * RawType (due to TypeLayout::type_class_id_)
//    * RawTypeParameter (due to TypeParameterLayout::parameterized_class_id_)
//
// The following instances use cids for the computation of canonical hash codes
// indirectly:
//
//    * RawTypeRef (due to TypeRefLayout::type_->type_class_id)
//    * RawType (due to TypeLayout::signature_'s result/parameter types)
//    * RawTypeArguments (due to type references)
//    * RawInstance (due to instance fields)
//    * RawArray (due to type arguments & array entries)
//
// Caching of the canonical hash codes happens for:
//
//    * TypeLayout::hash_
//    * TypeParameterLayout::hash_
//    * TypeArgumentsLayout::hash_
//    * RawInstance (weak table)
//    * RawArray (weak table)
//
// No caching of canonical hash codes (i.e. it gets re-computed every time)
// happens for:
//
//    * RawTypeRef (computed via TypeRefLayout::type_->type_class_id)
//
// Usages of canonical hash codes are:
//
//   * ObjectStore::canonical_types()
//   * ObjectStore::canonical_type_parameters()
//   * ObjectStore::canonical_type_arguments()
//   * Class::constants()
//
class ClearTypeHashVisitor : public ObjectVisitor {
 public:
  explicit ClearTypeHashVisitor(Zone* zone)
      : type_param_(TypeParameter::Handle(zone)),
        type_(Type::Handle(zone)),
        type_args_(TypeArguments::Handle(zone)) {}

  void VisitObject(ObjectPtr obj) {
    if (obj->IsTypeParameter()) {
      type_param_ ^= obj;
      type_param_.SetHash(0);
    } else if (obj->IsType()) {
      type_ ^= obj;
      type_.SetHash(0);
    } else if (obj->IsTypeArguments()) {
      type_args_ ^= obj;
      type_args_.SetHash(0);
    }
  }

 private:
  TypeParameter& type_param_;
  Type& type_;
  TypeArguments& type_args_;
};

void ClassFinalizer::RehashTypes() {
  Thread* T = Thread::Current();
  Zone* Z = T->zone();
  Isolate* I = T->isolate();

  // Clear all cached hash values.
  {
    HeapIterationScope his(T);
    ClearTypeHashVisitor visitor(Z);
    I->heap()->VisitObjects(&visitor);
  }

  // Rehash the canonical Types table.
  ObjectStore* object_store = I->object_store();
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
    ASSERT(!present);
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
  I->RehashConstants();

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
#ifdef DART_PRECOMPILED_RUNTIME
  UNREACHABLE();
#else
  auto const thread = Thread::Current();
  auto const isolate = thread->isolate();
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);
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
  ProgramVisitor::WalkProgram(zone, isolate, &visitor);

  // Apart from normal function code and allocation stubs we have two global
  // code objects to clear.
  if (including_nonchanging_cids) {
    auto object_store = isolate->object_store();
    auto& null_code = Code::Handle(zone);
    object_store->set_build_method_extractor_code(null_code);
  }
#endif  // !DART_PRECOMPILED_RUNTIME
}

}  // namespace dart
