# Enhanced Type Promotion

Author: Brian Wilkerson

Language team shepherd: Bob Nystrom

The Dart language features type promotion. This lets you avoid pointless
explicit casts in some cases where it's obvious that a variable has a more
specific type than its declared (or originally inferred) type. For example:

```dart
int stringLength(Object o) {
  if (o is String) {
    return o.length; // OK!
  } else {
    throw "Not a string.";
  }
}
```

Without type promotion, the marked line would have a static error since Object
does not have a `.length` getter. Type promotion notes that an is String test
was applied to `o`, and promotes or "re-types" `o` to have type String inside
the then clause of the if statement.

The type promotion rules in Dart are useful, but very restricted. Some
restriction is necessary because dataflow based type inference can get quite
complex in some cases. But, in practice, the current rules are too restrictive.
For example, this does not work:

```dart
int stringLength(Object o) {
  if (o is! String) {
    throw "Not a string.";
  } else {
    return o.length; // Error: Object does not have a "length" getter.
  }
}
```

The type promotion rules don't handle negated `is` checks and else clauses. This
doesn't work either:

```dart
int stringLength(Object o) {
  if (o is! String) throw "Not a string.";
  return o.length; // Error: Object does not have a "length" getter.
}
```

Since the first line will definitely throw if `o` is not a String, the only way
the second line could execute is if `o` is a string. But type promotion fails to
understand that.

To get around these limitations, the analyzer used by IntelliJ and others also
has "type propagation". This is more sophisticated than type promotion. But,
since the language spec controls what errors and warnings are shown, type
propagation is limited to be using for things like auto-complete suggestions.

Maintaining two similar but different flow typing systems adds complexity to our
tools and confuses users. ("Why are you showing me an error that a variable
isn't a Foo, when auto-complete on that same variable shows me all of Foo's
methods?")

To remedy that, this proposal augments type promotion with smarter rules when
variables can be promoted. That should avoid requiring annoying redundant casts
in more places, and let us unify type promotion and propagation into a single
coherent system. This proposal doesn't cover all possible extensions to type
propagation, but it handles the simplest, most common cases.

## How Type Promotion Works

The language specifies type promotion out of four components:

1.  **Certain expressions cause a fact to be known about a variable.** For
    example, `o` is String deduces the fact "`o` must be a String".

2.  **The scope where a fact is known to be true.** For example in:

    ```dart
    if (o is String) {
      return o.length;
    } else {
      throw "Not a string.";
    }
    ```

    The fact "`o` is a String" is known to be true inside the then clause of the
    if statement, but not the else clause, and not after the end of the if
    statement.

3.  **Which variables can have their types promoted.** Some code may cause a
    fact to not be soundly reliable. In that case, we shouldn't promote. For
    example:

    ```dart
    test(Object o, bool callClosure) {
      closure() {
        o = 123;
      }

      if (o is String) {
        if (callClosure) closure();
        print(o.length);
      }
    }
    ```

    At the point where `.length` is accessed, `o` may be a String, or it may be
    an int if `callClosure` was true. To avoid cases like this, the spec defines
    certain variables to be off limits for type promotion.

4.  **Which pairs of types -- declared and promoted -- are allowed for
    promotion.** The spec says that promotion only applies if the promoted type
    is a subtype of the declared type.

This proposal keeps the same general pieces, but refines the first three of
them. The forth is unchanged.

## Facts for False Expressions

The specification defines a single fact that can be deduced: that a variable `v`
has some type T. It says some expressions "show that a variable has some type".
There are two places this can happen:

*   Section 16.34 says that an "is-test" expression `v is T` shows that `v` has
    type T.

*   Section 16.22 propagates facts through logical expressions. It says
    (roughly) that an and expression like `e1 && e2` shows `v` has type T if
    either `e1` or `e2` does.

In both cases there is an unstated assumption that the fact is deduced when the
expression evaluates to true. We extend this to include information that can be
deduced when an expression evaluates to false. As with the true case, there are
two places that we can do this.

*   An is-expression `e` of the form `v is! T`, shows that `v` has type T when
    `e` is false.

*   A logical or expression `e` like `e1 || e2` shows that `v` has type T if
    either `e1` or `e2` shows that when they are false if `e` itself is false.
    For example, in `o is! String || itsMonday`, we know `o` must be a String if
    the entire `||` expression evaluated to false.

## Extending Scope

### "Else" Scope

The specification defines three scopes where promotion can apply:

*   The "then" clause of a conditional expression (16.20):

    ```dart
    o is String ? oPromotedToStringHere : notHere
    ```

*   The right operand of a logical `&&` expression (16.22):

    ```dart
    o is String && oPromotedToStringHere
    ```

    This is because short-circuiting means the right operand is only evaluated
    when the left is true.

*   The "then" clause of an if statement (17.5):

    ```dart
    if (o is String) oPromotedToStringHere;
    ```

All of these correspond to code that is only reached if a condition expression
evaluates to true. We extend this to cover facts that are known when an
expression evaluates to false.

*   In a conditional expression of the form `e1 ? e2 : e3`, we know that if `e1`
    shows that `v` has type T when `e1` is false, then `v` is known to be of
    type T in `e3`:

    ```dart
    o is! String ? notHere : oPromotedToStringHere
    ```

*   In a logical boolean expression of the form `e1 || e2`, if `e1` shows `v`
    has type T when `e1` is false, then `v` is known to be of type T in `e2`:

    ```dart
    o is! String || oPromotedToStringHere
    ```

    This is because short-circuiting means the right operand is only evaluated
    when the left is false.

*   In an if statement, if the condition shows that `v` has type T when the
    condition is false, then `v` is known to be of type T in the else clause.

    ```dart
    if (o is! String) notHere; else oPromotedToStringHere;
    ```

### Loop Scopes

Much like if statements, we extend C-style for and while loops to promote inside
their bodies when the condition is true and the condition expression shows a `v`
has type T:

```dart
while (o is String) oPromotedToStringHere;

for (; o is String;) oPromotedToStringHere;
```

### Scopes After Exits

The last common case where users expect type promotion to work but currently
doesn't is in code that can only be reached if a type test succeeds because
earlier code will cause the code to exit, as in:

```dart
int stringLength(Object o) {
  if (o is! String) throw "Not a string.";
  return o.length; // Should be promoted here.
}
```

We say a statement "cannot complete normally" if the statement is one of:

*   A return statement.

*   A rethrow statement.

*   An expression statement whose expression is a throw expression.

*   An if statement with an else where neither statement can complete normally.

*   A block that directly contains a statement that cannot complete normally.

We do not allow *labeled* statements of the above form. Fortunately, labels are
so vanishingly rare that this is unlikely to affect users in practice.

Then, given an if statement of the form `if (b) s1 else s2` that is contained in
some block:

*   If `b` shows that `v` has type T when `b` is true, and `s2` cannot complete
    normally, then `v` has the type T in the statements after the if statement
    in the immediately enclosing block. As in:

    ```dart
    int stringLength(Object o) {
      if (o is String) /* whatever */; else throw "Not a string.";
      return o.length; // Promoted here.
    }
    ```

*   If `b` shows that `v` has type T when `b` is false, and `v` can be promoted,
    and `s1` cannot complete normally, then `v` has the type T in the statements
    after the if statement in the immediately enclosing block.

    This is also allowed if the if statement has no else clause at all.

## Promoting More Variables

The specification places several restrictions on the variables whose type can be promoted. The variable `v`:

*   Must be either a local variable or a parameter,

*   cannot be potentially assigned to within the scope S that the promotion
    would apply to,

*   cannot be potentially assigned to within any closure, and

*   if `v` is captured by a closure in the scope S then `v` cannot be
    potentially mutated anywhere.

The most common case where this eliminates useful promotion is the second rule.
Consider:

```dart
Object trimIfString(Object o) {
  if (o is String) o = o.trim();
  return o;
}
```

In Dart today, the assignment to `o` prevents `o` from being promoted. That in
turn means the call to `o.trim()` has a static error since Object has no
`trim()` method.

We accommodate these cases by simply removing the second restriction. We allow
promotion to occur even if the variable is assigned within the promoted scope.
This opens the door to code that is not safe:

```dart
test(Object o) {
  if (o is String) {
    o = 123;          // No longer a String.
    print(o.length);  // Error!
  }
}
```

Obviously, by the time we execute `o.length`, `o` will no longer be a String and
the call will fail. We address this by promoting `o`'s static type not just for
accesses of `o`, but for assignments to it as well.

In this example, if means the `o = 123` now generates a static error because an
int cannot be assigned to a variable of (promoted) type String. There are still
cases where the assignment is allowed but would lead to unsound code because of
an implicit downcast:

```dart
test(Object o) {
  if (o is String) {
    o = new Object(); // No longer a String.
    print(o.length);  // Error!
  }
}
```

Here, the assignment `o = new Object()` has no static error, but would lead to
code that fails later since Object has no `length` getter. We address this like
all downcasts are addressed in strong mode, by checking at runtime that the
assignment succeeds. Now, though, the runtime check is against the *promoted*
type. In the above example, at runtime, we check that `new Object()` can be
assigned to String. That check fails at runtime, and we never reach the invalid
call to `o.length`.

*Optional: The restriction on mutation within closures could be relaxed to only
apply to closures defined before the boolean expression that allows for the
promotion or within the scope that the promotion would apply to. A similar
relaxation could be made for the locations of closures that capture the
variable. This would require defining precisely what we mean by "before", which
might be more work than it's worth.*

*Optional: The restriction on mutation within the scope that the promotion would
apply to could be relaxed by allowing the promotion to apply to everything up to
the point of mutation. For example:*

```dart
if (v is T) {
  // v has type T here
  v = someNonTValue;
  // v has the non-promoted type here
}
```

## Example Specification Wording

Putting together all of the changes above, the following are examples of how the
specification might read when this proposal is integrated. There is no
assumption here that this would be the final wording in the specification (I'm
sure others are more skilled at crafting specifications than I am). There is
also no attempt to highlight the differences from the existing specification
because that was found to be confusing.

### 16.20 Conditional

Given a conditional expression c of the form `e1 ? e2 : e3`, if

*   the variable `v` is promotable in `e2`, and
*   `e1` shows that a variable `v` has type T when `e1` is true.

then the type of `v` is known to be T in `e2`.

Given a conditional expression `c` of the form `e1 ? e2 : e3`, if

*   the variable `v` is promotable in `e3`, and
*   `e1` shows that a variable `v` has type T when `e1` is false,

then the type of `v` is known to be T in `e3`.

### 16.22 Logical Boolean Expressions

A logical boolean expression `b` of the form `e1 || e2` shows that a variable
`v` has type T when `b` is false if either `e1` shows that `v` has type T when
`e1` is false or `e2` shows that `v` has type T when `e2` is false.

Given a logical boolean expression `b` of the form `e1 || e2`, if:

*   the variable `v` is promotable in `e2`, and
*   `e1` shows that `v` has type T when `e1` is false,

then the type of `v` is known to be T in `e2`.

A logical boolean expression `b` of the form `e1 && e2` shows that a variable
`v` has type T when `b` is true if either `e1` shows that `v` has type T when
`e1` is true or `e2` shows that `v` has type T when `e2` is true.

Given a logical boolean expression `b` of the form `e1 && e2`, if:

*   the variable `v` is promotable in `e2`, and
*   `e1` shows that `v` has type T when `e1` is true.

then the type of `v` is known to be T in `e2`.

### 16.29 Unary Expressions

A unary expression `b` of the form `!e` shows that a variable `v` has type T
when `b` is true if `e` shows that the variable `v` has type T when `e` is
false. A unary expression `b` of the form `!e` shows that a variable `v` has
type T when b is false if e shows that the variable v has type T when e is true.

### 16.34 Type Test

Dart 1.0: Let `v` be a local variable or a formal parameter. An is-expression
`e` of the form `v is T` shows that `v` has type T when `e` is true iff T is
more specific than the type S of the expression `v` and both T != dynamic and S
!= dynamic. An is-expression `e` of the form `v is! T` shows that `v` has type T
when `e` is false iff T is more specific than the type S of the expression `v`
and both T != dynamic and S != dynamic.

Dart 2.0: Let `v` be a local variable or a formal parameter. An is-expression
`e` of the form `v is T` shows that `v` has type T when `e` is true iff T is a
subtype of the type S of the expression `v`, or, if S is a type variable with
bound B, if T is a subtype of B. An is-expression `e` of the form `v is! T`
shows that `v` has type T when `e` is false iff T is a subtype of the type S of
the expression `v`, or, if S is a type variable with bound B, if T is a subtype
of B.

### 17.5 If

Given an if statement of the form `if (b) s1 else s2`, if:

*   the variable `v` is promotable in `s1`, and
*   `b` shows that a variable `v` has type T when `b` is true.

then the type of `v` is known to be T in `s1`. If the if-statement is enclosed
in a block and if `s2` cannot complete normally, and `v` is promotable in the
statements (S) in the immediately enclosing block that follow the if statement,
then `v` is known to have type T in S.

Given an if statement of the form `if (b) s1 else s2`, if:

*   the variable `v` is promotable in `s2`, and
*   `b` shows that a variable `v` has type T when `b` is false,

then the type of `v` is known to be T in `s2`. If the if-statement in enclosed
in a block and if `s1` cannot complete normally, and `v` is promotable in the
statements (S) in the immediately enclosing block that follow the if statement,
then `v` is known to have type T in S.

### 17.6.1 For Loop

Given a for statement of the form `for (...; c; ...) s`, if

*   the variable `v` is promotable in `s`, and
*   `c` shows that `v` has the type T when true,

then `v` is known to have type T in `s`.

Given a for statement of the form `for (...; c; u) s`, if

*   the variable `v` is promotable in `u`, and
*   `c` shows that `v` has the type T when true,

then `v` is known to have type T in `u`.

Given a for statement of the form `for (...; c; u) s`, if

*   the variable `v` is promotable in the statements (S) in the immediately
    enclosing block that follow the for statement,
*   `c` shows that `v` has the type T when false, and
*   `s` is neither a break statement, nor a block containing, directly or
    indirectly, a break statement,

then `v` is known to have type T in S.

### 17.7 While

Given a while statement of the form `while (e) s`, if

*   the variable `v` is promotable in `s`, and
*   `e` shows that `v` has the type T when true,

then `v` is known to have type T in `s`.

Given a while statement of the form `while (e) s`, if

*   the variable `v` is promotable in the statements (S) in the immediately
    enclosing block that follow the while statement,
*   `e` shows that `v` has the type T when false, and
*   `s` is neither a break statement, nor a block containing, directly or
    indirectly, a break statement,

then `v` is known to have type T in S.

### 17.8 Do

Given a do statement of the form `do s while (e);`, if

*   the variable `v` is promotable in the statements (S) in the immediately
    enclosing block that follow the do statement,
*   `e` shows that `v` has the type T when false, and
*   `s` is neither a break statement, nor a block containing, directly or
    indirectly, a break statement,

then `v` is known to have type T in S.

### 19.1.1 Type Promotion

The static type system ascribes a static type to every expression. In some
cases, the types of local variables and formal parameters may be promoted from
their declared types based on control flow.

We say that a variable `v` is known to have type T whenever we allow the type of
`v` to be promoted. The exact circumstances when type promotion is allowed are
given in the relevant sections of the specification (16.20, 16.22, 16.29, 17.5,
17.6.1, and 17.7). Each of these sections defines the scope (range of code) in
which the variable's type is to be promoted.

Type promotion for a variable `v` is allowed only when we can deduce that such
promotion is valid based on an analysis of certain boolean expressions. In such
cases, we either say that the boolean expression `b` shows that `v` has type T
when `b` is true, or that the boolean expression `b` shows that `v` has type T
when `b` is false. As a rule, for all variables `v` and types T, a boolean
expression does not show that `v` has type T. Those situations where an
expression does show that a variable has a type are mentioned explicitly in the
relevant sections of this specification (16.34 and 16.22).

Dart 1.0: Type promotion for a variable `v` is also allowed only for a subset of
variables and is dependent on the use of the variable in the scope in which the
promotion would occur. If a variable is one for which type promotion is allowed,
we say that the variable is promotable in some scope. A variable `v` is
promotable in the scope S if all of the following conditions are met:

*   `v` is either a local variable or a parameter,

*   `v` cannot be potentially mutated within any closure, and

*   if `v` is accessed by a closure in S then `v` cannot be potentially mutated
    anywhere.

Dart 2.0: Type promotion for a variable `v` is also allowed only for a subset of
variables and is dependent on the use of the variable in the scope in which the
promotion would occur. If a variable is one for which type promotion is allowed,
we say that the variable is promotable in some scope. A variable `v` is
promotable in the scope S if all of the following conditions are met:

*   `v` is either a local variable or a parameter,

*   `v` cannot be potentially mutated within any closure, and

*   if `v` is accessed by a closure in S then `v` cannot be potentially mutated
    anywhere.

For the purposes of type promotion, a statement cannot complete normally if the
statement is either

*   a return statement,
*   a rethrow statement,
*   an expression statement whose expression is a throw expression,
*   an if statement of the form `if (b) s1 else s2` where neither `s1` nor `s2`
    can complete normally, or
*   a block whose last statement cannot complete normally.
