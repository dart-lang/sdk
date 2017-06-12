# Asserts in Initializer List
[lrn@google.com](mailto:lrn@google.com)
Version 1.1 (2017-06-08)
Status: Accepted, Informally specified

(See: http://dartbug.com/24841, http://dartbug.com/27141)

In some cases, you want to validate your inputs before creating an instance, even in a const constructor. To allow that, we have tested the possibility of allowing assert statements in the initializer list of a generative constructor.

We started by implementing the feature in the VM behind a flag, with at syntax support from the analyzer and the formatter.

This was as successful experiment, and the feature is actively being used by the Flutter project, so now we promote the experimental feature to a language feature.

## Syntax

The syntax is changed to allow an assert statement without trailing semicolon (just the `assert(condition[, message])`) to appear as an item in the initializer list.
Example:

```dart
   C(x, y) : this.foo = x, assert(x < y), this.bar = y;
```

The assert can occur anywhere in the list where an initializing assignment can.

That is, the grammar changes so that *superCallOrFieldIntitializer* can also produce an assert.

For simplicity, we add a new production for the assert-without-the-semicolon, and reuse that in both the initializer list and the *assertStatement*.

> *superCallOrFieldInitializer*:
> &nbsp;&nbsp;&nbsp; **super** arguments
> &nbsp;&nbsp;| **super** ‘.’ identifier arguments
> &nbsp;&nbsp;| fieldInitializer
> &nbsp;&nbsp;| assertion
> &nbsp;&nbsp;;
>
> assertion:  **assert** ‘(' expression (‘,' expression)? ‘)'  ;
>
> assertStatement: assertion ‘;' ;

The *superCallOrFieldInitializer* production will probably change name too, perhaps to *initializerListEntry*, but that's not important for the behavior.

## Semantics

The initializer list assert works the same way as an assert statement in a function body (with special treatment for asserts in a const constructor's initializer list, see next section). The assert expressions are evaluated in the initializer list scope, which does not have access to `this`, exactly the same way that an assert statement would be evaluated in the same scope. The runtime behavior is effectively:

1.  evaluate the condition expression (in the initializer list scope) to a result, `o`.
1.  If `o` implements `Function`, call it with zero arguments and let `r` be the return value,
1.  otherwise let `r` = `o`.
1.  Perform boolean conversion on `r`. This throws if `r` is not an instance of `bool`.
1.  if `r` isn't `true`,
    a.  if there is a message expression, evaluate that to a value `m`
    b.  otherwise let `m` be `null`
    c.  then throw an `AssertionError` with `m` as message.

Statically, like in an assertion statement, it's a warning if the static type of the condition expression isn't assignable to either `bool` or `bool Function()`.

Here step 2, 4 and 5a may throw before reaching step 5c, in which case that is the effect of the assert.


The assert statement is evaluated at its position in the initializer list, relative to the left-to-right evaluation of initializer list entries.

As usual, assert statements have no effect unless asserts are enabled (e.g., by running in checked mode).


## Const Semantics

If the constructor is a const constructor, the condition and message expressions in the assert must be potentially compile-time constant expressions. If any of them aren't, it is a compile-time error, the same way a non-potentially compile-time constant initializer expression in the initializer list is.

Further, the condition expression should not evaluate to a function, since we can't call functions at compile time. We can't prevent it from evaluating to a function, but the function cannot not be called. To account for this, the behavior above is changed for const constructor initializer list asserts:

*Step 2 above is dropped for an assert in a const constructor initializer list.*

The change is entirely syntax driven - an assert inside a const constructor initializer list does not test whether the expression is a function, not even when the constructor is invoked using `new`.
This change from the current specification is needed because asserts previously couldn't occur in a (potentially) const context[^1].

During a const constructor invocation (that is, when the const constructor is invoked using the `const` prefix), if the assert fails, either due to boolean conversion when `r` is not a boolean value or due to assertion failure when `r` is `false`, it is treated like any other compile-time throw in a compile-time constant expression, and it causes a compile-time error.


## Revisions

1.0 (2016-06-23) Initial specification.

1.1 (2017-06-08) Handle second expression in asserts as well, add grammar rules.


## Notes

[^1]:
     If we ever add "const functions" which can be "called" in a const context, then we may allow them here, but other functions are still compile time errors.
