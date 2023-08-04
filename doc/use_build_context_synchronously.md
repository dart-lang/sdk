# `use_build_context_synchronously` design

## Background

The idea behind the `use_build_context_synchronously` lint rule requires
careful tracking of a function body's possible control flow. At various points
in the syntax tree, we must be able to answer questions like, "when this
expression is reached, is it _possible_ that we have traversed through an
asynchronous gap?" and "does this mounted check _definitely_ guard this
expression?" The intricacies of such tracking are quite different from the
requirements of most linter rules.

## High level design

At a high level, the task of the lint rule can be broken down into three steps:

1. Consider each expression which references a BuildContext value, and which
   may be vulnerable to async gap bugs. For each such expression:
2. Walk up the syntax tree from the expression, until reaching the boundary of a
   function body (don't walk outside an anonymous function body, or a method
   declaration, etc.). At each ancestor node (well, not exactly ancestor, see
   below):
3. Compute the "async state" between the ancestor node and the expression-in-
   question, by visiting the ancestor's descendent nodes, looking for await
   expressions and mounted checks.

The first step just uses the linter's standard rule-registering mechanism. The
latter steps are explained below.

### Mounted guards

It would be egregious to require a function with a reference to a BuildContext
to have _zero_ async gaps (await expressions) above the reference. Developers
are allowed a safeguard: a "mounted check" which leads to a "mounted guard."

* A "mounted check" is merely an expression in which the `mounted` property of a
  BuildContext expression is read. It typically looks like `context.mounted`.
* A mounted check leads to a "mounted guard" for a certain node if it guarantees
  that the node will only be executed if the BuildContext is mounted, that is,
  the mounted check has returned positive.

## Walking up the ancestors and their preceding siblings

In this step, we have a single expression with a **reference** to a BuildContext
object, and we need to examine nodes which contain an async gap _which could be
crossed before the access to the **reference**_. This means we are simulating,
to a very limited extent, the runtime flow between an async gap and
**reference**.

1. Start with the expression containing the **reference**.
2. Define a **child** node whose value is initially **reference**.
3. While **child** is not a function body:
   a. Set a **parent** node equal to the child's parent.
   b. Check the "async state" between **parent** and **child**.
   c. If the state is "asynchronous," then there is a _possible_ async gap
      between **parent** and **child**, so report a lint.
   d. If the state is "mounted guard," then there is a _definite_ mounted
      guard between **parent** and **child**, so **child** is safe, and we can
      stop checking **child**.

Note: We use **child** in the loop, rather than just **reference**, in order to
make use of **child**'s relationship to **parent**, when computing the "async
gap" (see the next section).

Given the way we walk up the syntax tree, the async state between **parent** and
**child** is the same state as between **parent** and **reference**: if there is
a _possible_ async gap between **parent** and **child**, then there is a
possible async gap between **parent** and **reference**, and if there is a
_definite_ mounted guard between **parent** and **child**, then there is a
_definite_ mounted guard between **parent** and **reference**.

## Computing the "async state" of one node relative to another

This is the most complex and delicate step. Given two nodes, a **parent** and
**child**, we must calculate whether there is a _possible_ async gap between the
two (with no mounted guard between the async gap and the **child**), or a
_definite_ mounted guard between the two (without a possible async gap between
the mounted guard and **child**), or no interesting async state between the two.
This calculation is based on a few simple properties:

* We implement this calculation with a standard SimpleVisitor from the analyzer.
  We create the visitor with **child** as the reference node to consider. Each
  visit method descends down various child nodes, receiving their returned
  "async state" in order to calculate the state of it's own visited node,
  relative to **child**.
* At the entrypoint of the visitation, **child**'s parent is **parent**. Then we
  descend into **parent**'s various descendents, and so for every other visit
  method, **child** is a sibling of the visited node (in a NodeList), or is a
  child of some ancestor of the visited node.
* For nodes with multiple children, the associated visit method must take the
  position of **child** into account, as an async gap only affects **child** if
  it occurs _before_ **child**. Examples:
  * YieldStatement - this node has one child. If **child** is that child, then
    the async state is "uninteresting" (`null`). Otherwise, **child** follows
    the YieldStatement, and any await expressions occurring in the
    YieldStatement's expression result in `AsyncState.asynchronous`.
  * Block - this node has a list of child Statements. If **child** is one of
    those, then we compute the async state between each Statement that precedes
    **child** and **child**. We do not consider the Statements that follow
    **child** (unless the parent of the Block is a DoStatement, ForStatement, or
    WhileStatement). We consider each preceding Statement in reverse order,
    starting with the Statement that immediately precedes **child**. In this way
    we can correctly identify that a Statement which acts as a mounted guard for
    **child**. If **child** is not one of the Statements, then it follows the
    Block, and any await expressions occurring in the Block's expressions result
    in `AsyncState.asynchronous`.
  * MethodInvocation - this node has a target Expression and an argument list of
    Expressions. At runtime, the target is evaluated before the argument list,
    and the arguments are evaluated in left-to-right order. The associated visit
    method uses these facts to compute, for example, that if **child** is the
    target, then any async gaps in the argument list do not affect it.
* For nodes which can affect control flow (IfStatement, IfElement,
  ConditionalExpression, etc.), the associated visit methods must take
  **child**'s position into account for the purposes of mounted guards. For
  example, an IfStatement with a condition like `context.mounted` guards the
  then-statement, but not the else-statement, and no statements that follow the
  IfStatement. An IfStatement with a condition like `!context.mounted` and a
  then-statement that definitely exits (e.g. with a return or a throw),
  definitely guards the statements that follow it.