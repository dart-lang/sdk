# Statement Completion

### Mission Statement

The purpose of this feature is to add required syntax to the current
statement. The goal is to make the statement syntactically complete.
That is not possible to do in all cases. A best-effort attempt is made
when it cannot be done.

### Current Statement

The term _statement completion_ comes from IntelliJ. It is also called
_smart enter_ there, which is a more general term. See the IntelliJ
[documentation.](https://www.jetbrains.com/help/idea/2017.1/auto-completing-code.html#statements_completion)

Rather than restricting the functionality to statements, in the sense of the grammar construct
called _statement_, it is best to think of code constructs. Statement completion
can be used to add syntax to declarations, statements, and some expressions.
Generally, the syntax additions are punctuation marks, such as semicolons,
parentheses, and braces.

The _current statement_ then, is the code construct being written in the
editor, as identified by the position of the editing cursor. The _cursor_ is the
primary editing cursor of the active editor in IntelliJ. We ignore multiple
secondary cursors.

If the _current statement_ is already syntactically complete then the feature
just adds a newline. This will be the case when the cursor follows the closing
brace of the body of a for-statement or while-statement, for example. The model
used is that the user is creating code going forward, and when the
_smart enter_ keystroke is typed the user expects to see forward progress.
The cursor should end up at the most likely place to continue editing, regardless
of what errors may exist in previous code. It is as if the user said "I'm done
with this line. Finish it up and move me to the next line."

## Code Constructs

There are a number of cases where a matching right parenthesis could be added
if it is missing. This feature has not been considered a priority since the
editor by default adds parenthesis in pairs.

Generics are not currently handled.

#### Declarations

There is limited work to be done.

- [x] Functions, methods, and classes can have a pair of braces added if they do not already have a body defined.
- [x] Functions and methods can have a closing parenthesis added to the parameter list.
- [x] Variables can have a semicolon added to terminate them.

#### Expressions

Also limited.

- [x] Unterminated strings can have appropriate string
terminators added.
- [x] Lists that have not been properly terminated can
have closing brackets added (potentially with trailing commas).
- [x] Maps are not currently handled. The parser error recovery
gets confused by braces of code blocks too easily.

#### Statements

With actual statements, there are many more possibilities.
Statements that start with a keyword must have at least the
keyword in the partial statement in order for completion to
happen.

###### Do Statement

This is one of the few cases where an actual word may be included.
If the `while` keyword is missing it will be added.
As long as the `do` keyword is present the braces for the body
will be added. If the `while` keyword is present or can be added
then the parentheses for the condition will be added, too. Finally,
the terminating semicolon will be added.

###### For Statement

The parser cannot distinguish a for-statement from a for-each unless
either at least one semicolon or the `in` keyword is present in the
control parts. If neither is present then completion cannot do any
more than possibly add braces for the body.

Given that the statement is actually a for-statement then the control
parts will be adjusted to ensure there are two semicolons. If the braces
for the body are missing then they will be added.

###### For-each Statement

Braces for the body can be added if missing.

###### If Statement

The if-else-etc construct could get arbitrarily complex, so
for simplicity the `else` keyword is ignored. Starting with nothing
but the `if` keyword, the parentheses for the condition will be added
and the braces for the body will be added.

###### Switch Statement

Given the `switch` keyword, parentheses for the selector will be added
if absent and the braces for the body will be added. Also, for an
individual case or default clause the terminating colon will be added
if needed. To be clear, only the colon for the clause containing
the cursor will be added.

###### Try Statement

If the statement is nothing more than the `try` keyword then the braces
for the body will be added. No clauses (on, catch, or finally) will be added.

An on-clause will be completed by adding braces for its body, if absent.

A catch-clause will be completed by adding parentheses for its
parameter list and braces for the body.

A finally-clause will be completed by adding braces for its body.

###### While Statement

This is structurally identical to the if-statement and the implementation
for both is shared.

###### Expression Statements

These include method and function invocations.
- [x] Add closing parenthesis, if the expression is an invocation.
- [x] Add terminating semicolon.

###### Control-flow Blocks

After finishing a `return` or `throw` in a block that is the
body of a control-flow statement (do, for, for-each, if, while)
then the cursor will be moved outside the block, ready to begin
the next statement following the control-flow statement.
```dart
if (isFinished()) {
releaseResources();
return; // invoke 'smart enter' here
}
// continue typing here
```
