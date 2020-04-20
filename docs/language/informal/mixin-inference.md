# Dart 2.X super mixin inference proposal

**Owner**: leafp@google.com

**Status**: This is now background material.

The current version of this document now resides
[here](https://github.com/dart-lang/language/blob/master/working/0006.%20Super-invocations%20in%20mixins/0007.%20Mixin%20declarations/mixin-inference.md).

This is intended to define a prototype approach to supporting inference of type
arguments in super-mixin applications.  This is not an official part of Dart
2, but is an experimental feature hidden under flags.  When super-mixins are
specified and landed, this feature or some variant of it may be included.

## Syntactic conventions

The meta-variables `X`, `Y`, and `Z` range over type variables.

The meta-variables `T`, and `U` range over types.

The meta-variables `M`, `I`, and `S` range over interface types (that is,
classes instantiated with zero or more type arguments).

The meta-variable `C` ranges over classes.

The meta-variable `B` ranges over types used as bounds for type variables.

Throughout this document, I assume that bound type variables have been suitably
renamed to avoid accidental capture.

## Mixin inference

In Dart 2 syntax, a class definition may also have an interpretation as mixin
under certain restrictions defined elsewhere.

### Mixins and superclass constraints

Given a class of the form:

```
class C<X0, ..., Xn> extends S with M0, ..., Mj implements I0, ..., Ik { ...}
```

we say that the superclass of `C<X0, ..., Xn>` is `S with M0, ..., Mj`.

When interpreted as a mixin, we say that the super class constraints for `C<X0,
..., Xn>` are `S`, `M0`, ..., `Mj`.

Given a mixin application class of the form:

```
class C<X0, ..., Xn> =  S with M0, ..., Mj implements I0, ..., Ik;
```

for we say that the superclass of `C<X0, ..., Xn>` is `S with M0, ..., Mj-1`.

When interpreted as a mixin, we say that the super class constraints for `C<X0,
..., Xn>` are `S`, `M0`, ..., `Mj-1`.

#### Discussion

A class, interpreted as a mixin, is interpreted as a function from its
superclass to its own type.  That is, the actual class onto which the mixin is
applied must be a subtype of the superclass constraint.  When the superclass is
itself a mixin, we interpret each component of the mixin as a separate
constraint, each of which the actual class onto which the mixin is applied must
be a subtype of.

### Mixin type inference

Given a class of the form:

```
class C<T0, ..., Tn> extends S with M0, ..., Mj implements I0, ..., Ik { ...}
```

or of the form

```
class C<T0, ..., Tn> =  S with M0, ..., Mj implements I0, ..., Ik;
```

we say that the superclass of `M0` is `S`, the superclass of `M1` is `S with
M0`, etc.

For a class with one or more mixins of either of the forms above we allow any
or all of the `M0`, ..., `Mj` to have their type arguments inferred.  That is,
if any of the `M0`, ..., `Mj` are references to generic classes with no type
arguments provided, the missing type arguments will be attempted to be
reconstructed in accordance with this specification.

Type inference for a class is done from the innermost mixin application out.
That is, the type arguments for `M0` (if any) are inferred before type arguments
for `M1`, and so on. Each successive inference is done with respect to the
inferred version of its superclass: so if type arguments `T0, ..., Tn` are
inferred for `M0`, `M1` is inferred with respect to `M0<T0, ..., Tn`>, etc.

Type inference for the class hierarchy is done from top down.  That is, in the
example classes above, all mixin inference for the definitions of `S`, the `Mi`,
and the `Ii` is done before mixin inference for `C` is done.

Let be `M` be a mixin applied to a superclass `S` where `M` is a reference to a
generic class with no type arguments provided, and `S` is some class (possibly
generic); and where `M` is defined with type parameters `X0, ..., Xj`.  Let `S0,
..., Sn` be the superclass constraints for `M` as defined above.  Note that the
`Xi` may appear free in the `Si`.  Let `C0, ..., Cn` be the corresponding
classes for the `Si`: that is, each `Si` is of the form `Ci<T0, ..., Tk>` for
some `k >= 0`.  Note that by assumption, the `Xi` are disjoint from any type
parameters in the enclosing scope, since we have assumed that type variables are
suitably renamed to avoid capture.

For each `Si`, find the unique `Ui` in the super-interface graph of `S` such
that the class of `Ui` is `Ci`.  Note that if there is not such a `Ui`, then
there is no instantiation of `M` that will allow its superclass constraint to be
satisfied, and if there is such a `Ui` but it is not unique, then the superclass
hierarchy is ill-formed.  In either case it is an error.

Let *SLN* be the smallest set of pairs of type variables and types `(Z0, T0),
..., (Zl, Tl)` with type variables drawn from `X0, ..., Xj` such that `{T0/Z0,
..., Tl/Zl}Si == Ui`.  That is, replacing each free type variable in the `Si`
with its corresponding type in *SLN* makes `Si` and `Ui` the same.  If no such
set exists, then it is an error.  Note that for well-formed programs, the only
free type variables in the `Ti` must by definition be drawn from the type
parameters to the enclosing class of the mixin application. Hence it follows
both that the `Ti` are well-formed types in the scope of the mixin application,
and that the the `Xi` do not occur free in the `Ti` since we have assumed that
classes are suitably renamed to avoid capture.

Let `[X0 extends B0, ..., Xj extends Bj]` be a set of type variable bounds such
that if `(Xi, Ti)` is in *SLN* then `Bi` is `Ti` and otherwise `Bi` is the
declared bound for `Xi` in the definition of `M`.

Let `[X0 -> T0', ..., Xj -> Tj']` be the default bounds for this set of type
variable bounds as defined in the "instantiate to bounds" specification.

The inferred type arguments for `M` are then `<T0', ..., Ti'>`.

It is an error if the inferred type arguments are not a valid instantiation of
`M` (that is, if they do not satisfy the bounds of `M`).

#### Discussion

For each superclass constraint, there must be a matching interface in the
super-interface hierarchy of the actual superclass.  So for each superclass
constraint of the form `I0<U0, ..., Uk>` there must be some `I0<U0', ..., Uk'>`
in the super-interface hierarchy of the actual superclass `S` (if not, there is
an error in the super class hierarchy, or in the mixin application).  Note that
the `Ui` may have free occurrences of the type variables for which we are
solving, but the `Ui'` may not.  A simple equality traversal comparing `Ui` and
`Ui'` will find all of the type variables which must be equated in order to make
the two interfaces equal.  Once a type variable is solved via such a traversal,
subsequent occurrences must be constrained to an equal type, otherwise there is
no solution.  Type variables which do not appear in any of the superclass
constraints are not constrained by the mixin application.  Some or all of the
type variables may be unconstrained in this manner.  We choose a solution for
these type variables using the instantiate to bounds algorithm.  We construct a
synthetic set of bounds using the chosen constraints for the constrained
variables, and use instantiate to bounds to produce the remaining results.
Since instantiate to bounds may produce a super-bounded type, we must check that
the result satisfies the bounds (or else define a version of instantiate to
bounds which issues an error rather than approximates).

Note that we do not take into account information from later mixins when solving
the constraints: nor from implemented interfaces.  The approach specified here
may therefore fail to find valid instantiations.  We may consider relaxing this
in the future.  Note however that fully using information from other positions
will result in equality constraint queries in which type variables being solved
for appear on both sides of the query, hence leading to a full unification
problem.

The approach specified here is a simplification of the subtype matching
algorithm used in expression level type inference.  In the case that there is no
solution to the declarative specification above, subtype matching may still find
a solution which does not satisfy the property that no generic interface may
occur twice in the class hierarchy with different type arguments.  A valid
implementation of the approach specified here should be to run the subtype
matching algorithm, and then to subsequently check that no generic interface has
been introduced at incompatible type.

## Tests and illustrative examples.

Some examples illustrating key points.

### Inference proceeds outward

```
class I<X> {}

class M0<T> extends I<T> {}

class M1<T> extends I<T> {}

// M1 is inferred as M1<int>
class A extends M0<int> with M1 {}
```

```
class I<X> {}

class M0<T> extends I<T> {}

class M1<T> extends I<T> {}

class M2<T> extends I<T> {}

// M1 is inferred as M1<int>
// M2 is inferred as M1<int>
class A extends M0<int> with M1, M2 {}
```

```
class I<X> {}

class M0<T> extends Object implements I<T> {}

class M1<T> extends I<T> {}

// M0 is inferred as M0<dynamic>
// Error since class hierarchy is inconsistent
class A extends Object with M0, M1<int> {}
```

```
class I<X> {}

class M0<T> extends Object implements I<T> {}

class M1<T> extends I<T> {}

// M0 is inferred as M0<dynamic> (unconstrained)
// M1 is inferred as M1<dynamic> (constrained by inferred argument to M0)
// Error since class hierarchy is inconsistent
class A extends Object with M0, M1 implements I<int> {}
```

### Multiple superclass constraints
```
class I<X> {}

class J<X> {}

class M0<X, Y> extends I<X> with J<Y> {}

class M1 implements I<int> {}
class M2 extends M1 implements J<double> {}

// M0 is inferred as M0<int, double>
class A extends M2 with M0 {}
```

### Instantiate to bounds
```
class I<X> {}

class M0<X, Y extends String> extends I<X> {}

class M1 implements I<int> {}

// M0 is inferred as M0<int, String>
class A extends M1 with M0 {}
```

```
class I<X> {}

class M0<X, Y extends X> extends I<X> {}

class M1 implements I<int> {}

// M0 is inferred as M0<int, int>
class A extends M1 with M0 {}
```

```
class I<X> {}

class M0<X, Y extends Comparable<Y>> extends I<X> {}

class M1 implements I<int> {}

// M0 is inferred as M0<int, Comparable<dynamic>>
// Error since super-bounded type not allowed
class A extends M1 with M0 {}
```

### Non-trivial constraints

```
class I<X> {}

class M0<T> extends I<List<T>> {}

class M1<T> extends I<List<T>> {}

class M2<T> extends M1<Map<T, T>> {}

// M0 is inferred as M0<Map<int, int>>
class A extends M2<int> with M0 {}
```

### Unification
These examples are not inferred given the strategy in this proposal, and suggest
some tricky cases to consider if we consider a broader approach.


```
class I<X, Y> {}

class M0<T> implements I<T, int> {}

class M1<T> implements I<String, T> {}

// M0 inferred as M0<String>
// M1 inferred as M1<int>
class A extends Object with M0, M1 {}
```


```
class I<X, Y> {}

class M0<T> implements I<T, List<T>> {}

class M1<T> implements I<List<T>, T> {}

// No solution, even with unification, since solution
// requires that I<List<U0>, U0> == I<U1, List<U1>>
// for some U0, U1, and hence that:
// U0 = List<U1>
// U1 = List<U0>
// which has no finite solution
class A extends Object with M0, M1 {}
```
