# Local type inference

leafp@google.com

Status: Work in progress

## Type schemas

Local type inference uses a notion of `type schema`, which are slight
generalizations of normal Dart types.  The grammar of Dart types is extended
with an additional construct `?` which can appear anywhere that a type is
expected.  The intent is that `?` represents a component of a type which has not
yet been fixed by inference.  Type schemas cannot appear in programs or in final
inferred types: they are purely part of the specification of the local inference
process.  In this document, we sometimes refer to `?` as "the unknown type".

### Type schema elimination (least and greatest closure of a type schema)

We define the least closure of a type schema `P` with respect to `?` to be `P`
with every covariant occurrence of `?` replaced with `Null`, and every
contravariant occurrence of `?` replaced with `Object`.

We define the greatest closure of a type schema `P` with respect to `?` to be `P`
with every covariant occurrence of `?` replaced with `Object`, and every
contravariant occurrence of `?` replaced with `Null`.

TODO(leafp): Specify this precisely

Note that the closure of a type schema is a proper type.

Note that the least closure of a type schema is always a subtype of any type
which matches the schema, and the greatest closure of is always a supertype of
any type which matches the schema.



### Type variable elimination (least and greatest closure of a type)

We define the least closure of a type `M` with respect to a set of type
variables `T0, ..., Tn` to be `M` with every covariant occurrence of `Ti`
replaced with `Null`, and every contravariant occurrence of `Ti` replaced
with `Object`.

We define the greatest closure of a type `M` with respect to a set of type
variables `T0, ..., Tn` to be `M` with every contravariant occurrence of `Ti`
replaced with `Null`, and every covariant occurrence of `Ti` replaced with
`Object`.

TODO(leafp): Specify this precisely

Note that the least closure of a type is a subtype of the original type (and of
any substitution of types for the closed over type variables), and the greatest
closure of a type is a supertype of the original type (and of any substitution
of types for the closed over type variables).

Discussion: We could consider taking bound information on the `Ti` into account,
but this raises issues with respect to places where a default bound cannot be
computed due to f-bounded subtyping.  If we do not take bounds into
consideration (and even if we do) we may create types `A<Object>` where `Object`
does not satisfy the bound for `A`.  If we accept super-bounded types of this
form (as we have proposed to do) then this is not problematic.  If we don't
accept these, then we need to be sure that there is eventually an appropriate
error check on the final inferred types.

## Upper bound

We write `UP(T0, T1)` for the upper bound of `T0` and `T1`and `DOWN(T0, T1)` for
the lower bound of `T0` and `T1`.  This extends to type schema by taking `UP(T,
?) == T` and `DOWN(T, ?) == T` and symmetrically.

TODO(leafp): write out the rules for this.

## Subtype Constraints

Subtype constraints are constraints on type variables `T` indicating that the
constrained type variable is required to be either a subtype (`T <: M`) or a
supertype (`M <: T`) of a specific type (or type schema) `M`.  Constraints in
which the same variable occurs on the left and the right of the constraint are
ill-formed.

### Closure of subtype and supertype constraints.

The closure of a subtype constraint `T <: M` with respect to a set of type
variables `L` is the subtype constraint `T <: N` where `N` is the least closure
of `M` with respect to `L`, and similarly for supertype constraints.

The closure of a supertype constraint `M <: T` with respect to a set of type
variables `L` is the subtype constraint `N <: T` where `N` is the greatest
closure of `M` with respect to `L`, and similarly for supertype constraints.

Note that the closure of a type constraint implies the original constraint: that
is, any solution to the original constraint is a solution to the new constraint.

The motivation for these operations is that constraint generation may produce a
constraint on a type variable from an outer scope (say `S`) that refers to a
type variable from an inner scope (say `T`).  For example, ` <T>(S) -> int <:
<T>(List<T> -> int ` constrains `List<T>` to be a subtype of `S`.  But this
constraint is ill-formed outside of the scope of `T`, and hence if inference
requires this constraint to be generated and moved out of the scope of `T`, we
must approximate the constraint to the nearest constraint which does not mention
`T`, but which still implies the original constraint.  Choosing the greatest
closure of `List<T>` (i.e. `List<Object>`) as the new supertype constraint on
`S` results in the constraint `List<Object> <: S`, which implies the original
constraint.

### Constraint solving

Inference works by collecting lists of subtype and supertype constraints for
type variables of interest.  We write a list of constraints using the
meta-variable `C`, and use the meta-variable `c` for a single constraint.
Inference relies on various operations on constraint sets.

#### Merge of a constraint set

The merge of constraint set `C` for a type variable `T` is a pair of types `Mb
<: T <: Mt` defined as follows:
  - let `Mt` be the lower bound of the `Mi` such that `T <: Mi` is in `C`
      (and `?` if there are no subtype bounds for T in `C`)
  - let `Mb` be the upper bound of the `Mi` such that `Mi <: T` is in `C` (and
      `?` if there are no supertype bounds for T in `C`)

#### Constraint solution for a type variable

The constraint solution for a type variable `T` with respect to a constraint set
`C` is defined as follows:
  - let `Mb <: T <: Mb` be the merge of `C` with respect to `T`.
  - If `Mb` is known (that is, it does not contain `?`) then the solution is
    `Mb`
  - Otherwise, if `Mt` is known (that is, it does not contain `?`) then the
    solution is `Mt`
  - Otherwise, if `Mb` is not `?` then the solution is `Mb`
  - Otherwise the solution is `Mt`

#### Grounded constraint solution for a type variable

The grounded constraint solution for a type variable `T` with respect to a
constraint set `C` is define as follows:
  - let `Mb <: T <: Mb` be the merge of `C` with respect to `T`.
  - If `Mb` is known (that is, it does not contain `?`) then the solution is
    `Mb`
  - Otherwise, if `Mt` is known (that is, it does not contain `?`) then the
    solution is `Mt`
  - Otherwise, if `Mb` is not `?` then the solution is the greatest closure of
    `Mb` with respect to `?`
  - Otherwise the solution is the least closure of `Mt` with respect to `?`.

#### Constrained type variables

A constraint set `C` constrains a type variable `T` if there exists a `c` in `C`
of the form `T <: M` or `M <: T` where `M` is not `?`.

A constraint set `C` partially constrains a type variable `T` if the constraint
solution for `T` with respect to `C` is a type schema (that is, it contains `?`).

A constraint set `C` fully constrains a type variable `T` if the constraint
solution for `T` with respect to `C` is a proper type (that is, it does not
contain `?`).


## Subtype constraint generation

Subtype constraint generation is an operation on two type schemas `P` and `Q`
and a list of type variables `L`, producing a list of subtype
constraints `C`.

We write this operation as a relation as follows:

```
P <: Q [L] -> C
```

where `P` and `Q` are type schemas, `L` is a list of type variables `T0, ...,
Tn`, and `C` is a list of subtype and supertype constraints on the `Ti`.

This relation can be read as "`P` is a subtype match for `Q` with respect to the
list of type variables `L` under constraints `C`".


By invariant, at any point in constraint generation, only one of `P` and `Q` may
be a type schema (that is, contain `?`), only one of `P` and `Q` may contain any
of the `Ti`, and neither may contain both.  That is, constraint generation is a
relation on type-schema/type pairs and type/type-schema pairs, only the type
element of which may refer to the `Ti`.

### Notes:

- For convenience, ordering matters in this presentation: where any two clauses
  overlap syntactically, the first match is preferred.
- This presentation is assuming appropriate well-formedness conditions on the
  input types (e.g. non-cyclic class hierarchies)

### Syntactic notes:

- `C0 + C1` is the concatenation of constraint lists `C0` and `C1`.

### Rules

- The unknown type `?` is a subtype match for any type `Q` with no constraints.
- Any type `P` is a subtype match for the unknown type `?` with no constraints.
- A type variable `T` in `L` is a subtype match for any type schema `Q`:
  - Under constraint `T <: Q`.
- A type schema `Q` is a subtype match for a type variable `T` in `L`:
  - Under constraint `Q <: T`.
- Any two equal types `P` and `Q` are subtype matches under no constraints.
- Any type `P` is a subtype match for `dynamic`, `Object`, or `void` under no
  constraints.
- `Null` is a subtype match for any type `Q` under no constraints.
- `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to `L` under
  constraints `C`:
  - If `P` is a subtype match for `Q` with respect to `L` under constraints `C`.
- `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
constraints `C0 + C1`.
  - If `Future<P>` is a subtype match for `Q` with respect to `L` under
    constraints `C0`.
  - And `P` is a subtype match for `Q` with respect to `L` under constraints
    `C1`.
- `P` is a subtype match for `FutureOr<Q>` with respect to `L` under constraints
  `C`:
  - If `P` is a subtype match for `Future<Q>` with respect to `L` under
    constraints `C`.
  - Or `P` is not a subtype match for `Future<Q>` with respect to `L` under
    constraints `C`
    - And `P` is a subtype match for `Q` with respect to `L` under constraints
      `C`
- A type variable `T` not in `L` with bound `P` is a subtype match for the same
type variable `T` with bound `Q` with respect to `L` under constraints `C`:
  - If `P` is a subtype match for `Q` with respect to `L` under constraints `C`.
- A type variable `T` not in `L` with bound `P` is a subtype match for a type
`Q` with respect to `L` under constraints `C`:
  - If `P` is a subtype match for `Q` with respect to `L` under constraints `C`.
- A type `P<M0, ..., Mk>` is a subtype match for `P<N0, ..., Nk>` with respect
to `L` under constraints `C0 + ... + Ck`:
  - If `Mi` is a subtype match for `Ni` with respect to `L` under constraints
    `C`.
- A type `P<M0, ..., Mk>` is a subtype match for `Q<N0, ..., Nj>` with respect
to `L` under constraints `C`:
  - If `R<B0, ..., Bj>` is the superclass of `P<M0, ..., Mk>` and `R<B0, ...,
Bj>` is a subtype match for `Q<N0, ..., Nj>` with respect to `L` under
constraints `C`.
  - Or `R<B0, ..., Bj>` is one of the interfaces implemented by `P<M0, ..., Mk>` 
(considered in lexical order) and `R<B0, ..., Bj>` is a subtype match for `Q<N0,
..., Nj>` with respect to `L` under constraints `C`.
  - Or `R<B0, ..., Bj>` is a mixin into `P<M0, ..., Mk>` (considered in lexical
order) and `R<B0, ..., Bj>` is a subtype match for `Q<N0, ..., Nj>` with respect
to `L` under constraints `C`.
- A type `P` is a subtype match for `Function` with respect to `L` under no constraints:
  - If `P` implements a call method.
  - Or if `P` is a function type.
- A type `P` is a subtype match for a type `Q` with respect to `L` under
constraints `C`:
  - If `P` is an interface type which implements a call method of type `F`, and
  `F` is a subtype match for a type `Q` with respect to `L` under constraints
  `C`.
- A function type `(M0,..., Mn, [M{n+1}, ..., Mm]) -> R0` is a subtype match for
  a function type `(N0,..., Nk, [N{k+1}, ..., Nr]) -> R1` with respect to `L`
  under constraints `C0 + ... + Cr + C`
  - If `R0` is a subtype match for a type `R1` with respect to `L` under
  constraints `C`:
  - If `n <= k` and `r <= m`.
  - And for `i` in `0...r`, `Ni` is a subtype match for `Mi` with respect to `L`
  under constraints `Ci`.
- Function types with named parameters are treated analogously to the positional
  parameter case above.
- A generic function type `<T0 extends B0, ..., Tn extends Bn>F0` is a subtype
match for a generic function type `<S0 extends B0, ..., Sn extends Bn>F1` with
respect to `L` under constraints `Cl`:
  - If `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for `F0[Z0/S0, ..., Zn/Sn]`
with respect to `L` under constraints `C`, where each `Zi` is a fresh type
variable with bound `Bi`.
  - And `Cl` is `C` with each constraint replaced with its closure with respect
    to `[Z0, ..., Zn]`.

## Expression inference

Expression inference uses information about what constraints are imposed on the
expression by the context in which the expression occurs.  An expression may
occur in a context which provides no typing expectation, in which case there is
no contextual information.  Otherwise, the contextual information takes the form
of a type schema which describes the structure of the type to which the
expression is required to conform by its context of occurrence.

The primary function of expression inference is to determine the parameter and
return types of closure literals which are not explicitly annotated, and to fill
in elided type variables in constructor calls, generic method calls, and generic
literals.

### Expectation contexts

A typing expectation context (written using the meta-variables `J` or `K`) is
either a type schema `P`, or an empty context `_`.

### Constraint set resolution

The full resolution of a constraint set `C` for a list of type parameters `<T0
extends B0, ..., Tn extends Bn>` given an initial partial
solution `[T0 -> P0, ..., Tn -> Pn]` is defined as follows.  The resolution
process computes a sequence of partial solutions before arriving at the final
resolution of the arguments.

Solution 0 is `[T0 -> P00, ..., Tn -> P0n]` where `P0i` is `Pi` if `Ti` is fixed
in the initial partial solution (i.e. `Pi` is a type and not a type schema) and
otherwise `Pi` is `?`.

Solution 1 is `[T0 -> P10, ..., Tn -> P1n]` where:
  - If `Ti` is fixed in Solution 0 then `P1i` is `P0i`'
  - Otherwise, let `Ai` be `Bi[P10/T0, ..., ?/Ti, ...,  ?/Tn]`
  - If `C + Ti <: Ai` over constrains `Ti`, then it is an
    inference failure error
  - If `C + Ti <: Ai` does not constrain `Ti` then `P1i` is `?`
  - Otherwise `Ti` is fixed with `P1i`, where `P1i` is the **grounded**
    constraint solution for `Ti` with respect to `C + Ti <: Ai`.

Solution 2 is `[T0 -> M0, ..., Tn -> Mn]` where:
  - let `A0, ..., An` be derived as
    - let `Ai` be `P1i` if `Ti` is fixed in Solution 1
    - let `Ai` be `Bi` otherwise
  - If `<T0 extends A0, ..., Tn extends An>` has no default bounds then it is
    an inference failure error.
  - Otherwise, let `M0, ..., Mn`be the default bounds for `<T0 extends A0,
      ..., Tn extends An>`

If `[M0, ..., Mn]` do not satisfy the bounds `<T0 extends B0, ..., Tn extends
Bn>` then it is an inference failure error.

Otherwise, the full solution is `[T0 -> M0, ..., Tn -> Mn]`.

### Downwards generic instantiation resolution

Downwards resolution is the process by which the return type of a generic method
(or constructor, etc) is matched against a type expectation context from an
invocation of the method to find a (possibly partial) solution for the missing
type arguments

`[T0 -> P0, ..., Tn -> Pn]` is a partial solution for a set of type variables
`<T0 extends B0, ..., Tn extends Bn>` under constraint set `Cp` given a type
expectation of `R` with respect to a return type `Q` (in which the `Ti` may be
free) where the `Pi` are type schemas (potentially just `?` if unresolved)/

If `R <: Q [T0, ..., Tn] -> C` does not hold, then each `Pi` is `?` and `Cp` is
    empty

Otherwise:
  - `R <: Q [T0, ..., Tn] -> C` and `Cp` is `C`
  - If `C` does not constrain `Ti` then `Pi` is `?`
  - If `C` partially constrains `Ti`
    - If `C` is over constrained, then it is an inference failure error
    - Otherwise `Pi` is the constraint solution for `Ti` with respect to `C` 
  - If `C` fully constrains `Ti`, then
    - Let `Ai` be `Bi[R0/T0, ..., ?/Ti, ..., ?/Tn]`
    - If `C + Ti <: Ai` is over constrained, it is an inference failure error.
    - Otherwise, `Ti` is fixed to be `Pi`, where `Pi` is the constraint solution
      for `Ti` with respect to `C + Ti <: Ai`.

### Upwards generic instantiation resolution

Upwards resolution is the process by which the parameter types of a generic
method (or constructor, etc) are matched against the actual argument types from
an invocation of a method to find a solution for the missing type arguments that
have not been fixed by downwards resolution.

`[T0 -> M0, ..., Tn -> Mn]` is the upwards solution for an invocation of a
generic method of type `<T0 extends B0, ..., Tn extends Bn>(P0, ..., Pk) -> Q`
given actual argument types `R0, ..., Rk`, a partial solution `[T0 -> P0, ...,
Tn -> Pn]` and a partial constraint set `Cp`:
  - If `Ri <: Pi [T0, ..., Tn] -> Ci` 
  - And the full constraint resolution of `Cp + C0 + ... + Cn` for `<T0 extends
B0, ..., Tn extends Bn>` given the initial partial solution `[T0 -> P0, ..., Tn
-> Pn]` is `[T0 -> M0, ..., Tn -> Mn]`

### Discussion

The incorporation of the type bounds information is asymmetric and procedural:
it iterates through the bounds in order (`Bi[R0/T0, ..., ?/Ti, ..., ?/Tn]`).  Is
there a better formulation of this that is symmetric but still allows some
propagation?

### Inference rules

- The expression `e as T` is inferred as `m as T` of type `T` in context `K`:
  - If `e` is inferred as `m` in an empty context
- The expression `x = e` is inferred as `x = m` of type `T` in context `K`:
  - If `e` is inferred as `m` of type `T` in context `M` where `x` has type `M`.
- The expression `x ??= e` is inferred as `x ??= m` of type `UP(T, M)` in
  context `K`:
  - If `e` is inferred as `m` of type `T` in context `M` where `x` has type `M`.
- The expression `await e` is inferred as `await m` of type `T` in context `K`:
  - If `e` is inferred as `m` of type `T` in context `J` where:
    - `J` is `FutureOr<K>` if `K` is not `_`, and is `_` otherwise
- The expression `e0 ?? e1` is inferred as `m0 ?? m1` of type `T` in
  context `K`:
  - If `e0` is inferred as `m0` of type `T0` in context `K`
  - And `e1` is inferred as `m1` of type `T1` in context `J`
  - Where `J` is `T0` if `K` is `_` and otherwise `K`
  - Where `T` is the greatest closure of `K` with respect to `?` if `K` is not
    `_` and otherwise `UP(T0, T1)`
- The expression `e0..e1` is inferred as `m0..m1` of type `T` in context `K`
  - If `e0` is inferred as `m0` of type `T` in context `K`
  - And `e1` is inferred as `m1` of type `P` in context `_`
- The expression `e0 ? e1 : e2` is inferred as `m0 ? m1 : m2` of type `T` in
  context `K`
  - If `e0` is inferred as `m0` of any type in context `bool`
  - And `e1` is inferred as `m1` of type `T0` in context `K`
  - And `e2` is inferred as `m2` of type `T1` in context `K`
  - Where `T` is the greatest closure of `K` with respect to `?` if `K` is not
    `_` and otherwise `UP(T0, T1)`
- TODO(leafp): Generalize the following closure cases to the full function
  signature.
  - In general, if the function signature is compatible with the context type,
    take any available information from the context.  If the function signature
    is not compatible, this this should always be a type error anyway, so
    implementations should be free to choose the best error recovery path.
  - The monomorphic case can be treated as a degenerate case of the polymorphic
    rule
- The expression `<T>(P x) => e` is inferred as `<T>(P x) => m` of type `<T>(P)
  -> M` in context `_`
  - If `e` is inferred as `m` of type `M` in context `_`
- The expression `<T>(P x) => e` is inferred as `<T>(P x) => m` of type `<T>(P)
  -> M` in context `<S>(Q) -> N`
  - If `e` is inferred as `m` of type `M` in context `N[T/S]`
  - Note: `x` is resolved as having type `P`  for inference in `e`
- The expression `<T>(x) => e` is inferred as `<T>(dynamic x) => m` of type
  `<T>(dynamic) -> M` in context `_`
  - If `e` is inferred as `m` of type `M` in context `_`
- The expression `<T>(x) => e` is inferred as `<T>(Q[T/S] x) => m` of type
  `<T>(Q[T/S]) -> M` in context `<S>(Q) -> N`
  - If `e` is inferred as `m` of type `M` in context `N[T/S]`
  - Note: `x` is resolved as having type `Q[T/S]` for inference in `e`
- Block bodied lamdas are treated essentially the same as expression bodied
  lambdas above, except that:
  - The final inferred return type is `UP(T0, ..., Tn)`, where the `Ti` are the
    inferred types of the return expressions (`void` if no returns).
  - The returned expression from each `return` in the body of the lamda uses the
    same type expectation context as described above.
  - TODO(leafp): flesh this out.
- For async and generator functions, the downwards context type is computed as
  above, except that the propagated downwards type is taken from the type
  argument to the `Future` or `Iterable` or `Stream` constructor as appropriate.
  If the return type is not the appropriate constructor type for the function,
  then the downwards context is empty.  Note that subtypes of these types are
  not considered (this is a strong mode error).
- The expression `e(e0, .., ek)` is inferred as `m<M0, ..., Mn>(m0, ..., mk)` of
  type `N` in context `_`:
  - If `e` is inferred as `m` of type `<T0 extends B0, ..., Tn extends Bn>(P0,
    ..., Pk) -> Q` in context `_`
  - And the initial downwards solution is `[T0 -> Q0, ..., Tn -> Qn]` with
    partial constraint set `Cp` where:
    - If `K` is `_`, then the `Qi` are `?` and `Cp` is empty
    - If `K` is `Q <> _` then `[T0 -> Q0, ..., Tn -> Qn]` is the partial
solution for `<T0 extends B0, ..., Tn extends Bn>` under constraint set `Cp` in
downwards context `P` with respect to return type `Q`.
  - And `ei` is inferred as `mi` of type `Ri` in context `Pi[?/T0, ..., ?/Tn]`
  - And `<T0 extends B0, ..., Tn extends Bn>(P0, ..., Pk) -> Q` resolves via
upwards resolution to a full solution `[T0 -> M0, ..., Tn -> Mn]`
    - Given partial solution `[T0 -> Q0, ..., Tn -> Qn]`
    - And partial constraint set `Cp` 
    - And actual argument types `R0, ..., Rk`
  - And `N` is `Q[M0/T0, ..., Mn/Tn]`
- A constructor invocation is inferred exactly as if it were a static generic
  method invocation of the appropriate type as in the previous case.
- A list or map literal is inferred analagously to a constructor invocation or
  generic method call (but with a variadic number of arguments)
- A (possibly generic) method invocation is inferred using the same process as
  for function invocation.
- A named expression is inferred to have the same type as the sub-expression
- A parenthesized expression is inferred to have the same type as the
  sub-expression
- A tear-off of a generic method, static class method, or top level function `f`
  is inferred as `f<M0, ..., Mn>` of type `(R0, ..., Rm) -> R` in context `K`:
  - If `f` has type `A``T0 extends extends B0, ..., Tn extends Bn>(P0, ..., Pk) ->
    Q`
  - And `K` is `N` where `N` is a monomorphic function type
  - And `(P0, ..., Pk) -> Q <: N [T0, ..., Tn] -> C`
  - And the full resolution of `C` for `<T0 extends B0, ..., Tn extends Bn>`
given an initial partial solution `[T0 -> ?, ..., Tn -> ?]` and empty constraint
set is `[T0 -> M0, ..., Tn -> Mn]`



TODO(leafp): Specify the various typing contexts associated with specific binary
operators.


## Method and function inference.

TODO(leafp)


Constructor declaration (field initializers)
Default parameters

## Statement inference.

TODO(leafp)

Return statements pull the return type from the enclosing function for downwards
inference, and compute the upper bound of all returned values for upwards
inference.  Appropriate adjustments for asynchronous and generator functions.

Do statements 
For each statement
