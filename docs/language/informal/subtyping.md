# Dart 2.0 Static and Runtime Subtyping

leafp@google.com

Status: Draft

This is intended to define the core of the Dart 2.0 static and runtime subtyping
relation.


## Types

The syntactic set of types used in this draft are a slight simplification of
full Dart types.

The meta-variables `X`, `Y`, and `Z` range over type variables.

The meta-variables `T`, `S`, `U`, and `V` range over types.

The meta-variable `C` ranges over classes.

The meta-variable `B` ranges over types used as bounds for type variables.

As a general rule, indices up to `k` are used for type parameters and type
arguments, `n` for required value parameters, and `m` for all value parameters.

The set of types under consideration are as follows:

- Type variables `X`
- Promoted type variables `X & T` *Note: static only*
- `Object`
- `dynamic`
- `void`
- `Null`
- `Function`
- `Future<T>`
- `FutureOr<T>`
- Interface types `C`, `C<T0, ..., Tk>`
- Function types
  - `U Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn, [Tn+1 xn+1, ..., Tm xm])`
  - `U Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn, {Tn+1 xn+1, ..., Tm xm})`

We leave the set of interface types unspecified, but assume a class hierarchy
which provides a mapping from interfaces types `T` to the set of direct
super-interfaces of `T` induced by the superclass declaration, implemented
interfaces, and mixins of the class of `T`.  Among other well-formedness
constraints, the edges induced by this mapping must form a directed acyclic
graph rooted at `Object`.

The types `Object`, `dynamic` and `void` are all referred to as *top* types, and
are considered equivalent as types (including when they appear as sub-components
of other types).  They exist as distinct names only to support distinct errors
and warnings (or absence thereof).

The type `X & T` represents the result of a type promotion operation on a
variable.  In certain circumstances (defined elsewhere) a variable `x` of type
`X` that is tested against the type `T` (e.g. `x is T`) will have its type
replaced with the more specific type `X & T`, indicating that while it is known
to have type `X`, it is also known to have the more specific type `T`.  Promoted
type variables only occur statically (never at runtime).

Given the current promotion semantics the following properties are also true:
   - If `X` has bound `B` then for any type `X & T`, `T <: B` will be true.
   - Promoted type variable types will only appear as top level types: that is,
     they can never appear as sub-components of other types, in bounds, or as
     part of other promoted type variables.


## Notation

We use `S[T0/Y0, ..., Tk/Yk]` for the result of performing a simultaneous
capture-avoiding substitution of types `T0, ..., Tk` for the type variables
`Y0, ..., Yk` in the type `S`.


## Type equality

We say that a type `T0` is equal to another type `T1` (written `T0 === T1`) if
the two types are structurally equal up to renaming of bound type variables,
and equating all top types.

TODO: make these rules explicit.


## Algorithmic subtyping

By convention the following rules are intended to be applied in top down order,
with exactly one rule syntactically applying.  That is, rules are written in the
form:

```
Syntactic criteria.
  - Additional condition 1
  - Additional or alternative condition 2
```

and it is the case that if a subtyping query matches the syntactic criteria for
a rule (but not the syntactic criteria for any rule preceeding it), then the
subtyping query holds iff the listed additional conditions hold.

This makes the rules algorithmic, because they correspond in an obvious manner
to an algorithm with an acceptable time complexity, and it makes them syntax
directed because the overall structure of the algorithm corresponds to specific
syntactic shapes. We will use the word _algorithmic_ to refer to this property.

The runtime subtyping rules can be derived by eliminating all clauses dealing
with promoted type variables.


### Rules

We say that a type `T0` is a subtype of a type `T1` (written `T0 <: T1`) when:

- **Reflexivity**: `T0` and `T1` are the same type.
  - *Note that this check is necessary as the base case for primitive types, and
    type variables but not for composite types.  In particular, algorithmically
    a structural equality check is admissible, but not required
    here. Pragmatically, non-constant time identity checks here are
    counter-productive*

- **Right Top**: `T1` is a top type (i.e. `Object`, `dynamic`, or `void`).

- **Left Bottom**: `T0` is `Null`

- **Left FutureOr**: `T0` is `FutureOr<S0>`
  - and `Future<S0> <: T1`
  - and `S0 <: T1`

- **Type Variable Reflexivity 1**: `T0` is a type variable `X0` or a
promoted type variables `X0 & S0` and `T1` is `X0`.
  - *Note that this rule is admissible, and can be safely elided if desired*

- **Type Variable Reflexivity 2**: Promoted`T0` is a type variable `X0` or a
promoted type variables `X0 & S0` and `T1` is `X0 & S1`
  - and `T0 <: S1`.
  - *Note that this rule is admissible, and can be safely elided if desired*

- **Right Promoted Variable**: `T1` is a promoted type variable `X1 & S1`
  - and `T0 <: X1`
  - and `T0 <: S1`

- **Right FutureOr**: `T1` is `FutureOr<S1>` and
  - either `T0 <: Future<S1>`
  - or `T0 <: S1`
  - or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
  - or `T0` is `X0 & S0` and `S0 <: T1`

- **Left Promoted Variable**: `T0` is a promoted type variable `X0 & S0`
  - and `S0 <: T1`

- **Left Type Variable Bound**: `T0` is a type variable `X0` with bound `B0`
  - and `B0 <: T1`

- **Function Type/Function**: `T0` is a function type and `T1` is `Function`

- **Interface Compositionality**: `T0` is an interface type `C0<S0, ..., Sk>`
  and `T1` is `C0<U0, ..., Uk>`
  - and each `Si <: Ui`

- **Super-Interface**: `T0` is an interface type with super-interfaces `S0,...Sn`
  - and `Si <: T1` for some `i`

- **Positional Function Types**: `T0` is
  `U0 Function<X0 extends B00, ..., Xk extends B0k>(V0 x0, ..., Vn xn, [Vn+1 xn+1, ..., Vm xm])`
  - and `T1` is
    `U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0, ..., Sp yp, [Sp+1 yp+1, ..., Sq yq])`
  - and `p >= n`
  - and `m >= q`
  - and `Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk]` for `i` in `0...q`
  - and `U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]`
  - and `B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk]` for `i` in `0...k`
  - where the `Zi` are fresh type variables with bounds `B0i[Z0/X0, ..., Zk/Xk]`

- **Named Function Types**: `T0` is
  `U0 Function<X0 extends B00, ..., Xk extends B0k>(V0 x0, ..., Vn xn, {Vn+1 xn+1, ..., Vm xm})`
  - and `T1` is
    `U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0, ..., Sn yn, {Sn+1 yn+1, ..., Sq yq})`
  - and `{yn+1, ... , yq}` subsetof `{xn+1, ... , xm}`
  - and `Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk]` for `i` in `0...n`
  - and `Si[Z0/Y0, ..., Zk/Yk] <: Tj[Z0/X0, ..., Zk/Xk]` for `i` in `n+1...q`, `yj = xi`
  - and `U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]`
  - and `B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk]` for `i` in `0...k`
  - where the `Zi` are fresh type variables with bounds `B0i[Z0/X0, ..., Zk/Xk]`

*Note: the requirement that `Zi` are fresh is as usual strictly a requirement
that the choice of common variable names avoid capture.  It is valid to choose
the `Xi` or the `Yi` for `Zi` so long as capture is avoided*


## Derivation of algorithmic rules

This section sketches out the derivation of the algorithmic rules from the
interpretation of `FutureOr` as a union type, and promoted type bounds as
intersection types, based on standard rules for such types that do not satisfy
the requirements for being algorithmic.


### Non-algorithmic rules

The non-algorithmic rules that we derive from first principles of union and
intersection types are as follows:

Left union introduction:
 - `FutureOr<S> <: T` if `Future<S> <: T` and `S <: T`

Right union introduction:
 - `S <: FutureOr<T>` if `S <: Future<T>` or `S <: T`

Left intersection introduction:
 - `X & S <: T` if `X <: T` or `S <: T`

Right intersection introduction:
 - `S <: X & T` if `S <: X` and `S <: T`

The only remaining non-algorithmic rule is the variable bounds rule:

Variable bounds:
  - `X <: T` if `X extends B` and `B <: T`

All other rules are algorithmic.

Note: We believe that bounds can be treated simply as uses of intersections,
which could simplify this presentation.


### Preliminaries

**Lemma 1**: If there is any derivation of `FutureOr<S> <: T`, then there is a
derivation ending in a use of left union introduction.

Proof.  By induction on derivations.  Consider a derivation of `FutureOr<S> <:
T`.

If the last rule applied is:
  - Top type rules are trivial.

  - Null, Function and interface rules can't apply.

  - Left union introduction rule is immediate.

  - Right union introduction. Then `T` is of the form `FutureOr<T0>`, and either
    - we have a sub-derivation of `FutureOr<S> <: Future<T0>`
      - by induction we therefore have a derivation ending in left union
       introduction, so by inversion we have:
         - a derivation of `Future<S> <: Future<T0> `, and so by right union
           introduction we have `Future<S> <: FutureOr<T0>`
         - a derivation of `S <: Future<T0> `, and so by right union
           introduction we have `S <: FutureOr<T0>`
      - by left union introduction, we have `FutureOr<S> <: FutureOr<T0>`
      - QED
    - we have a sub-derivation of `FutureOr<S> <: T0`
      - by induction we therefore have a derivation ending in left union
       introduction, so by inversion we have:
         - a derivation of `Future<S> <: T0 `, and so by right union
           introduction we have `Future<S> <: FutureOr<T0>`
         - a derivation of `S <: T0 `, and so by right union
           introduction we have `S <: FutureOr<T0>`
      - by left union introduction, we have `FutureOr<S> <: FutureOr<T0>`
      - QED

  - Right intersection introduction.  Then `T` is of the form `X & T0`, and
     - we have sub-derivations `FutureOr<S> <: X` and `FutureOr<S> <: T0`
     - By induction, we can get derivations of the above ending in left union
       introduction, so by inversion we have derivations of:
       - `Future<S> <: X`, `S <: X`, `Future<S> <: T0`, `S <: T0`
         - so we have derivations of `S <: X`, `S <: T0`, so by right
           intersection introduction we have
           - `S <: X & T0`
         - so we have derivations of `Future<S> <: X`, `Future<S> <: T0`, so by right
           intersection introduction we have
           - `Future<S> <: X & T0`
     - so by left union introduction, we have a derivation of `FutureOr<S> <: X & T0`
     - QED

Note: The reverse is not true.  Counter-example:

Given arbitrary `B <: A`, suppose we wish to show that `(X extends FutureOr<B>)
<: FutureOr<A>`.  If we apply right union introduction first, we must show
either:
  - `X <: Future<A>`
  - only variable bounds rule applies, so we must show
    - `FutureOr<B> <: Future<A>`
    - Only left union introduction applies, so we must show both of:
      - `Future<B> <: Future<A>` (yes)
      - `B <: Future<A>` (no)
  - `X <: A`
  - only variable bounds rule applies, so we must show that
    - `FutureOr<B> <: A`
    - Only left union introduction applies, so we must show both of:
      - `Future<B> <: Future<A>` (no)
      - `B <: Future<A>` (yes)

On the other hand, the derivation via first applying the variable bounds rule is
trivial.

Note though that we can also not simply always apply the variable bounds rule
first.  Counter-example:

Given `X extends Object`, it is trivial to derive `X <: FutureOr<X>` via the
right union introduction rule.  But applying the variable bounds rule doesn't
work.

**Lemma 2**: If there is any derivation of `S <: X & T`, then there is
derivation ending in a use of right intersection introduction.

Proof.  By induction on derivations.  Consider a derivation D of `S <: X & T`.

If last rule applied in D is:
  - Bottom types are trivial.

  - Function and interface type rules can't apply.

  - Right intersection introduction then we're done.

  - Left intersection introduction. Then `S` is of the form `Y & S0`, and either
    - we have a sub-derivation of `Y <: X & T`
      - by induction we therefore have a derivation ending in right intersection
       introduction, so by inversion we have:
         - a derivation of `Y <: X `, and so by left intersection
           introduction we have `Y & S0 <: X`
         - a derivation of `Y <: T `, and so by left intersection
           introduction we have `Y & S0 <: T`
      - by right intersection introduction, we have `Y & S0 <: X & T`
      - QED
    - we have a sub-derivation of `S0 <: X & T`
      - by induction we therefore have a derivation ending in right intersection
       introduction, so by inversion we have:
         - a derivation of `S0 <: X `, and so by left intersection
           introduction we have `Y & S0 <: X`
         - a derivation of `S0 <: T `, and so by left intersection
           introduction we have `Y & S0 <: T`
     - by right intersection introduction, we have `Y & S0 <: X & T`
     - QED

  - Left union introduction.  Then `S` is of the form `FutureOr<S0>`, and
     - we have sub-derivations `Future<S0> <: X & T` and `S0 <: X & T`
     - By induction, we can get derivations of the above ending in right intersection
       introduction, so by inversion we have derivations of:
       - `Future<S0> <: X`, `S0 <: X`, `Future<S0> <: T`, `S0 <: T`
         - so we have derivations of `S0 <: X`, `Future<S0> <: X`, so by left
           union introduction we have
           - `FutureOr<S0> <: X`
         - so we have derivations of `S0 <: T`, `Future<S0> <: T`, so by left
           union introduction we have
           - `FutureOr<S0> <: T`
     - so by right intersection introduction, we have a derivation of `FutureOr<S0> <: X & T`
     - QED

**Conjecture 1**: `FutureOr<A> <: FutureOr<B>` is derivable iff `A <: B` is
derivable.

Showing that `A <: B => FutureOr<A> <: FutureOr<B>` is easy, but it is not
immediately clear how to tackle the opposite direction.

**Lemma 3**: Transitivity of subtyping is admissible.  Given derivations of `A <: B`
and `B <: C`, there is a derivation of `A <: C`.

Proof sketch: The proof should go through by induction on sizes of derivations,
cases on pairs of rules used.  For any pair of rules used, we can construct a
new derivation of the desired result using only smaller derivations.

**Observation 1**: Given `X` with bound `S`, we have the property that for all
instances of `X & T`, `T <: S` will be true, and hence `S <: M => T <: M`.


### Algorithmic rules

Consider `T0 <: T1`.


#### Union on the left

By lemma 1, if `T0` is of the form `FutureOr<S0>` and there is any derivation of
`T0 <: T1`, then there is a derivation ending with a use of left union
introduction so we have the rule:

- `T0` is `FutureOr<S0>`
  - and `Future<S0> <: T1`
  - and `S0 <: T1`


#### Identical type variables

If `T0` and `T1` are both the same unpromoted type variable, then subtyping
holds by reflexivity.  If `T0` is a promoted type variable `X0 & S0`, and `T0`
is `X0` then it suffices to show that `X0 <: X0` or `S0 <: X0`, and the former
holds immediately.  This justifies the rule:

- `T0` is a type variable `X0` or a promoted type variables `X0 & S0` and `T1`
is `X0`.

If `T0` is `X0` or `X0 & S0` and `T1` is `X0 & S1`, then by lemma 1 it suffices
to show that `X0 & S0 <: X0` and `X0 & S0 <: S1`.  The first holds immediately
by reflexivity on the type variable, so it is sufficient to check `T0 <: S1`.

- `T0` is a type variable `X0` or a promoted type variables `X0 & S0` and `T1`
is `X0 & S1`
  - and `T0 <: S1`.

*Note that neither of the previous rules are required to make the rules
algorithmic: they are merely useful special cases of the next rule.*


#### Intersection on the right

By lemma 2, if `T1` is of the `X1 & S1` and there is any derivation of `T0 <:
T1`, then there is a derivation ending with a use of right intersection
introduction, hence the rule:

- `T1` is a promoted type variable `X1 & S1`
  - and `T0 <: X1`
  - and `T0 <: S1`


#### Union on the right

Suppose `T1` is `FutureOr<S1>`. The rules above have eliminated the possibility
that `T0` is of the form `FutureOr<S0`.  The only rules that could possibly
apply then are right union introduction, left intersection introduction, or the
variable bounds rules.  Combining these yields the following preliminary
disjunctive rule:

- `T1` is `FutureOr<S1>` and
  - either `T0 <: Future<S1>`
  - or `T0 <: S1`
  - or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
  - or `T0` is `X0 & S0` and `X0 <: T1` and `S0 <: T1`

The last disjunctive clause can be further simplified to
  - or `T0` is `X0 & S0` and `S0 <: T1`

since the premise `X0 <: FutureOr<S1>` can only derived either using the
variable bounds rule or right union introduction.  For the variable bounds rule,
the premise `B0 <: T1` is redundant with `S0 <: T1` by observation 1.  For right
union introduction, `X0 <: S1` is redundant with `T0 <: S1`, since if `X0 <: S1`
is derivable, then `T0 <: S1` is derivable by left union introduction; and `X0
<: Future<S1>` is redundant with `T0 <: Future<S1>`, since if the former is
derivable, then the latter is also derivable by left intersection introduction.
So we have the final rule:

- `T1` is `FutureOr<S1>` and
  - either `T0 <: Future<S1>`
  - or `T0 <: S1`
  - or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
  - or `T0` is `X0 & S0` and `S0 <: T1`


#### Intersection on the left

Suppose `T0` is `X0 & S0`. We've eliminated the possibility that `T1` is
`FutureOr<S1>`, the possibility that `T1` is `X1 & S1`, and the possibility that
`T1` is any variant of `X0`.  The only remaining rule that applies is left
intersection introduction, and so it suffices to check that `X0 <: T1` and `S0
<: T1`.  But given the remaining possible forms for `T1`, the only rule that can
apply to `X0 <: T1` is the variable bounds rule, which by observation 1 is
redundant with the second premise, and so we have the rule:

`T0` is a promoted type variable `X0 & S0`
  - and `S0 <: T1`


#### Type variable on the left

Suppose `T0` is `X0`.  We've eliminated the possibility that `T1` is
`FutureOr<S1>`, the possibility that `T1` is `X1 & S1`, and the possibility that
`T1` is any variant of `X0`.  The only rule that applies is the variable bounds
rule:

`T0` is a type variable `X0` with bound `B0`
  - and `B0 <: T1`

This eliminates all of the non-algorithmic rules: the remainder are strictly
algorithmic.
