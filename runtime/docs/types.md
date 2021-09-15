# Representation of Types

The Dart VM keeps track of the runtime type of Dart objects (also called *instances*) allocated in the heap by storing information in the objects themselves.  Heap objects contain a header and zero or more fields that can point to further objects.  Small integer objects (*Smi*) are not allocated as separate instances in the heap, but appear as immediate fields of instances. They are identified by their least significant bit being zero, as opposed to tagged object pointers whose least significant bit is one.  Refer to the document [gc.md](https://github.com/dart-lang/sdk/blob/main/runtime/docs/gc.md) for a description of objects and tagged object pointers.

## Runtime Type of an Instance

The type of a *Smi* object is implicitly the non-nullable `Smi` type, a VM internal type which is a subtype of the Dart type `int`.
All other Dart instances contain in their header a `ClassIdTag` bitfield identifying the Dart class of the instance, and, if the class is generic, a `type_arguments` field at a known offset.
The *class id* is an index into a table of class objects, representing the Dart classes currently loaded in the VM isolate. The class object, an instance of class `Class`, contains a field named `host_type_arguments_field_offset_in_words` which describes where to find the `type_arguments` field in each instance of that class.
The type of an instance can then be built using the retrieved class and type arguments. For example, if an instance has a class id corresponding to class `Directory` and the `type_arguments` field is the vector `[String,  Entry]`, then the runtime type of the instance is the non-nullable type `Directory<String, Entry>`. The type of an instance is non-nullable by definition, unless the instance happens to be the null instance, in which case its type is the nullable `Null` type.

There is a particular case where the type is not built as described above. Indeed, when the class of the instance is `Closure`, the runtime type of the instance is not the type `Closure`, but a function type representing the signature of the closure. In this case, the `function` field of the closure points to the `Function` object associated with the closure. The `signature` field in the `Function` object represents the type of the function. This function type is instantiated in the context of the closure in order to represent the runtime type of the closure. More on function types, signatures, and instantiation later.

## Type

A simple Dart type is represented by an object of class `Type` in the heap. It contains a `type_class_id` field and an `arguments` field containing the type arguments in case the class is generic. The type object also contains a `nullability` field, as types can be `legacy`, `nullable`, or `non-nullable`, a `hash` field caching the computed hash code of the type, as well as a `state` field keeping track of the finalization state of the type. More on finalization later.

The runtime type of all Dart instances in the heap (except closures) can therefore be represented by a `Type` object. The class id and the type arguments of the instance are copied into the `Type` object.

## FunctionType

The signature of a function is represented by an object of class `FunctionType`. If the function is generic, it contains the list of type parameters of the function and their bounds. It contains the result type and the list of parameter types, as well as the names of the optional named parameters. It also specifies which optional parameters are required.

## TypeParameter

A parameter type in the signature can be either a `Type`, a `FunctionType`, or a type parameter in scope (declared by either an enclosing signature or enclosing class). For example, the result type of the signature `<X>() => X` is the type parameter `X` declared by the signature itself. A third type flavor is required to represent the type `X`: a `TypeParameter` object, which is described in more detail later.

## AbstractType

The VM declares the class `AbstractType` as a placeholder to store a concrete type. The following classes extend `AbstractType`: `Type`, `FunctionType`, `TypeParameter`, and `TypeRef`. The latter one, `TypeRef` is used to break cycles in recursive type graphs. More on it later. `AbstractType` declares several virtual methods that may be overridden by concrete types. See its declaration in [object.h](https://github.com/dart-lang/sdk/blob/main/runtime/vm/object.h).

## TypeArguments

As its name suggests, an object of class `TypeArguments` represents a vector of `AbstractType`, but it does not extend `AbstractType`, since it is not a type, only the generic component of a type.

In Dart 1, leaving the type arguments of a generic class unspecified when allocating an instance of that class would result in all type arguments being the `dynamic` type. The concept of *instantiation to bounds* was introduced in Dart 2. Therefore, vectors consisting solely of the type `dynamic` were quite frequent in Dart 1 and it made sense to optimize them away and leave the whole vector as `null`. This optimization has remained to this day, and a null type argument vector still implies a vector of `dynamic` of the proper length for the context.

## Flattening of TypeArguments

An important characteristic of the Dart VM is that it *flattens* the type argument vector of instances so that the same vector can be used at any level of the generic class hierarchy of the instance. Let’s take this example:

```dart
class B<X> {
  bar() => X;
}
class C<T> extends B<List<T>> {
  foo() => T;
}

main() {
  var c = C<bool>();
  print(c.foo());  // prints “bool”
  print(c.bar());  // prints “List<bool>”
}
```

Variable `c` is assigned a new instance of type `C<bool>`. According to the previous sections, the type arguments of the instance `c` could simply be the vector `[bool]`. When the method `foo()` is called on receiver `c`,  the type `bool` in the type argument vector of `c` would properly reflect the type parameter `T` of class `C`. However, when the method `bar()` is called on the same receiver `c`, its type argument vector would need some transformation so that the correct type argument `List<bool>` reflects the type parameter `X` of class `B`.

For this reason, the type argument vector stored in instance `c` is not simply `[bool]`, but `[List<bool>, bool]`. More generally, the type argument vector stored in any instance of class `C` will have the form `[List<T>, T]`, where `T` is substituted with the actual type argument used to allocate the instance. The type at index 0 in the vector represents `X` in class `B` and the type at index 1 represents `T` in class `C`.

This *index* is an important attribute of the type parameter. In fact, the `TypeParameter` object contains a field `index` specifying which type argument to look up in the vector in order to *instantiate* the type parameter.

Each Dart class has a calculated attribute *num_type_parameters* and *num_type_arguments*. The value of *num_type_parameters* reflects the number of type parameters declared by the class, i.e. 1 for each of `B` and `C` in the example above. The value of *num_type_arguments* reflects the length of the type argument vector of an instance of that class, i.e. 1 for `B` and 2 for `C` in the example above.

Note that instances of non-generic classes may still have a type argument vector field. Take the following example:
```dart
class B<X> {
  bar() => X;
}
class D extends B<List<bool>> {
  foo() => 42;
}

main() {
  var d = D();
  print(d.foo());  // prints “42”
  print(d.bar());  // prints “List<bool>”
}
```
Every instance of class `D` will have the type argument vector `[List<bool>]`. Class `B` has 1 type parameter and 1 type argument, whereas class `D` has no type parameters and 1 type argument. More accurately, type `D` is represented by `D[List[bool]]`, since the type `List<bool>` is also represented by a class and its type argument vector, i.e. `List[bool]`.

## Overlapping of TypeArguments

Consider the following modified example:
```dart
class B<X> {
  bar() => X;
}
class C<T> extends B<T> {
  foo() => T;
}
```
Note how the flattened type argument vector would now repeat type parameter `T` as in `[T, T]`. This repetition is not necessary, since the type at index 0 in the vector representing `X` in class `B` is always identical to the type at index 1 representing `T` in class `C`. Therefore, the repeating parts of the vector are shifted as to *overlap* each other. The longer vector `[T, T]` is collapsed into a shorter vector `[T]`. In other words, both type parameters `X` of `B` and `T` of `C` now have the same index 0.
More complex situations can arise with overlapping vectors:
```dart
class B<R, S> { }
class C<T> extends B<List<T>, T> { }
```
Instead of using `[List[T], T, T]`, the last overlapping `T` is collapsed and the vector becomes `[List[T], T]`.
Class `B` has 2 type parameters and 2 type arguments, whereas class `C` has 1 type parameter and 2 type arguments.


## TypeRef

Consider the following example:
```dart
class B<T> { }
class D extends B<D> { }
```
Flattening the type argument vector of instances of class `D` poses a problem. Indeed, the type argument at index 0 must represent type `D`, which is the type argument of class `B`. Therefore, type `D` would need to be represented by `D[D[D[D[...]]]]` ad infinitum. To solve this problem, the `TypeRef` object extending `AbstractType` is introduced. It contains a single field `type`, which points to an `AbstractType`. Basically, `TypeRef` references another type and it is used to break cycles in type graphs. In this example, type `D` is represented as `D[TypeRef -> D]`, or graphically:
```
D:    D[TypeRef]
      ^    |
      |    |
      +----+
```

Another example:
```dart
class D1 extends B<D2> { }
class D2 extends B<D1> { }
```
Corresponding types and their internal representation:
```
D1:    D1[TypeRef -> D2]
D2:    D2[TypeRef -> D1]
```

Note that not all declarations of types can be represented this way, but only what is called *contractive* types:
```dart
class D<T> extends B<D<D<int>> { }
```
```
D<T>:       D[D<D<int>>, T]
D<D<int>>:  D[TypeRef -> D<D<int>>, D<int>]
D<int>:     D[D<D<int>>, int]
```
Here however is the example of a *non-contractive* type:
```dart
class D<T> extends B<D<D<T>> { }
```
```
D<T>:       D[D<D<T>>, T]
D<D<T>>:    D[D<D<D<T>>>, D<T>]
D<D<D<T>>>: D[D<D<D<D<T>>>>, D<D<T>>]
...
```
The representation is divergent and therefore not possible. The VM detects non-contractive types (search for `ClassFinalizer::CheckRecursiveType` in the [class finalizer](https://github.com/dart-lang/sdk/blob/main/runtime/vm/class_finalizer.cc)) and reports an error. These non-contractive types make no sense in real programs and rejecting them is not an issue at all.

## Compile Time Type

The VM classes described so far are not only used to represent the runtime type of instances in the heap, but they are also used to describe types at compile time. For example, the right handside of an *instance of* type test is represented by a concrete instance of `AbstractType`. Note that the type may still be *uninstantiated* at compile time, e.g. `List<T>` still contains the `TypeParameter` `T` of a generic class in its type argument vector:

```dart
  if (x is List<T>) {
    …
  }
```

While the type is uninstantiated at compile time, it is fully instantiated when the program runs. The index of `TypeParameter` `T` is used to look up the actual type in the *instantiator*, i.e. in the type argument vector of the receiver.

 ## Instantiation

The term *instantiation* refers to the substitution of type parameters with type arguments provided by the context, either by the type arguments of the receiver or by the type arguments of the current and/or enclosing generic function(s).

The *instantiator type arguments* are those of the receiver, possibly prefixed by the type arguments of the super classes, as explained above in the section about flattening type arguments.

The *function type arguments* are the concatenation of the type argument vectors explicitly passed (or inferred) to each enclosing generic function in the current context, from the outermost to the innermost function.

A `TypeParameter` object specifies whether it is declared by a class (it is then a *class type parameter*) or by a function (it is then a *function type parameter*), thereby selecting the vector to use for its instantiation. The index value then identifies the type argument from that specific vector to be used to substitute the type parameter. To complete the instantiation, a normalization step is applied after the substitution.

The virtual method to instantiate an `AbstractType` is declared as follows:
```dart
  virtual AbstractTypePtr InstantiateFrom(
      const TypeArguments& instantiator_type_arguments,
      const TypeArguments& function_type_arguments,
      intptr_t num_free_fun_type_params,
      Heap::Space space,
      TrailPtr trail = nullptr) const;

```
Note how both instantiators explained above are passed in, `instantiator_type_arguments` and `function_type_arguments`. Note also that an integer `num_free_fun_type_params` is provided. Its value indicates how many type arguments in the `function_type_arguments` vector are considered to be free variables and are therefore available to substitute type parameters with an index below this value. Type parameters with an index equal or above that value remain uninstantiated.
Here is an example:
```dart
class C<T> {
  T foo(bar<B>(T t, B b)) {
     …
  }
}
```
Although method `foo` is not generic, it takes a generic function `bar<B>()` as argument and its function type refers to class type parameter `T` and function type parameter `B`. When instantiating the function type of `foo` for a particular value of `T`, the function type parameter `B` must remain uninstantiated, because only `T` is a free variable in this function type. An instantiation in the context of `C<int>` would yield `int foo(bar<B>(int t, B b))`. In this case, the `InstantiateFrom` method would be called with `num_free_fun_type_params = 0`, as no function type parameters are free in this example.

## Trail

Another argument passed to the `InstantiateFrom` method above is `trail`. The trail prevents infinite recursion when traversing cyclic type graphs. When building type graphs, the VM makes sure that back references to the graph creating a cycle are represented by a `TypeRef` object. During graph traversal, when a `TypeRef` node is encountered, the implementation checks that the `TypeRef` is not already in the trail, in which case a repeated traversal of the same cycle is avoided. If not yet present, the `TypeRef` node is inserted in the trail, and the trail is passed down to recursive traversal calls.

There are different type graph traversal methods in the VM performing various operations. Each one of these traversals requires a trail to avoid divergence. Some take a single type graph as input, such as type instantiation and type instantiation check (whether a type is instantiated), but others take two type graphs as input, such as subtype test (whether a type is a subtype of another type) and type equivalence (whether two types are equivalent).

The traversals that take two type graphs as input use the trail differently. When a `TypeRef` is encountered on the left hand side, it is inserted in the trail in association with the right hand side type node being currently traversed. The implementation calls the right hand side type node the `buddy` of the `TypeRef` node. The trail consists of pairs of nodes. The implementation checks that a particular pair is already present before inserting it.

## Type Equivalence

The same virtual method `IsEquivalent` of `AbstractType` is used to traverse a pair of type graphs and decide whether they are canonically equal, syntactically equal, or equal in the context of subtype tests:
```dart
enum class TypeEquality {
  kCanonical = 0,
  kSyntactical = 1,
  kInSubtypeTest = 2,
};

  virtual bool IsEquivalent(const Instance& other,
                            TypeEquality kind,
                            TrailPtr trail = nullptr) const;
```
Instead of implementing three different traversals, the kind of type equality is passed as an argument to a single traversal method.

## Finalization

Types read from kernel files (produced by the Common Front End) need finalization before being used in the VM runtime. Finalization consists in flattening type argument vectors and in assigning indices to type parameters. A generic type provided by CFE will always have as many type arguments as the number of type parameters declared by the type’s class. As explained above, type arguments get prepended to the type argument vector, so that the vector can be used unchanged in any super class of the type’s class. This is done by methods of the [class finalizer](https://github.com/dart-lang/sdk/blob/main/runtime/vm/class_finalizer.h) called `ExpandAndFinalizeTypeArguments` and `FillAndFinalizeTypeArguments`.

The index of function type parameters can be assigned immediately upon loading of the type parameter from the kernel file. This is possible because enclosing generic functions are always loaded prior to inner generic functions. Therefore the number of type parameters declared in the  enclosing scope is known. The picture is more complicated with class type parameters. Classes can reference each other and a clear order is not defined in the kernel file. Clusters of classes must be fully loaded before type arguments can be flattened, which in turn determines the indices of class type parameters.

As a last step of finalization, types and type argument vectors get canonicalized not only to minimize memory usage but also to optimize type tests. Indeed, previously tested types can be entered in test caches to speed up further tests. Since types are canonical, using their heap address as an identifier works (different addresses imply unequal types).

## Canonicalization and Hash

The VM keeps global tables of canonical types and type arguments. Canonicalizing a type or a type argument vector consists in a table look up using a hash code to find a candidate, and then comparing the type with the candidate using the `IsEquivalent` method mentioned above (passing `kind = kCanonical`).

It is therefore imperative that two canonically equal types share the same hash code. `TypeRef` objects pose a problem in this regard. Namely, the hash of a `TypeRef` node cannot depend on the hash of the referenced type graph, otherwise, the hash code would depend on the location in the cycle where hash computation started and ended. Instead, the hash of a `TypeRef` node can only depend on information obtainable by “peeking” at the referenced type node, but not at the whole referenced type graph. See the comments in the [implementation](https://github.com/dart-lang/sdk/blob/main/runtime/vm/object.cc) of `TypeRef::Hash()` for details.

## Cached Instantiations of TypeArguments

Uninstantiated type argument vectors are often repeatedly instantiated from the same instantiators at runtime. The result of the instantiation, along with the two instantiators, is cached as a 3-tuple in the `instantiations` field of `TypeArguments`. Assembly code checks the cache before calling the instantiation code in the VM.

## Sharing of TypeArguments

The instantiation of some particularly formed type argument vectors will always result in one of the instantiator vectors. This can be detected at compile time and special code will speed up instantiation at runtime.
Consider this example:
```dart
class A<X0, X1> { }
class C<S, T> {
  foo() {
    A<S, T>();
  }
}
```
The new instance `A<S, T>` allocated in method `foo` is guaranteed to share the same type arguments as the receiver of `foo` and an instantiation of the type arguments can be avoided.
For details, search for the string *ShareInstantiator* in the source.

## Nullability of TypeArguments

The previous section ignores an important point, namely, sharing is only allowed if the nullability of each type argument in the instantiator is not modified by the instantiation. If the new instance was allocated with `A<S?, T>()` instead, it would only work if the first type argument in the instantiator is nullable, otherwise, its nullability would change from legacy or non-nullable to nullable. This check cannot be performed at compile time and performing it at run time undermines the benefits of the optimization. However, whether the nullability will remain unchanged for each type argument in the vector can be computed quickly for the whole vector with a simple integer operation. Each type argument vector is assigned a nullability value reflecting the nullability of each one of its type arguments. Since two bits are required per type argument, there is a maximal vector length allowed to apply this optimization. For a more detailed explanation, search for `kNullabilityBitsPerType` in the [source](https://github.com/dart-lang/sdk/blob/main/runtime/vm/object.h) and read the comments.

