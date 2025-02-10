# Guide to Program Split Constraints in Dart2js

## Introduction
Deferred loading can be a very powerful tool for improving IPL in
Dart2js. However, if Dart2js generates too many part files, the user
experience can degrade significantly. This degradation occurs
because each part file has to be downloaded and initialized. While
the download overhead can be minimized via bundling, there is
currently no way to alleviate initialization overhead.

The Dart2js team has explored ways to reduce part file
initialization overhead, and we have ideas for further incremental
improvements. However, ‘zero’ overhead is impossible as a
significant source of initialization overhead can be attributed to
parsing and compiling JS, and a naive restructuring of part files
for reduced overhead will significantly harm steady state
performance.

Though someday initializing part files may be as close to ‘free’ as
possible, in the meantime clients want to ship more granular apps,
and thus there is an urgent need for addressing initialization
overhead. One obvious way to address initialization overhead is to
reduce the number of part files. Unfortunately, doing this
automatically turns out to be non-trivial. Dart2js simply does not
have enough information to intelligently reduce the number of part
files, and a naive reduction will do more harm than good, bloating
load lists with code that may be totally unrelated.

In order to reduce the number of part files efficiently, Dart2js
needs accurate load order information. Program split constraints are
a way for user’s of Dart2js to supply load order information to the
compiler. With accurate information about the relative ordering of
loadLibrary calls, Dart2js is able to constrain the deferred loading
graph, and reduce the number of part files all without bloating load
lists unnecessarily.

One final point, program split constraints are only useful if a
program is structured in a hierarchical manner, i.e. where
loadLibrary calls frequently dominate other loadLibrary calls. If
programs are structured hierarchically, and a complete load order
graph can be provided, then Dart2js can reduce the number of part
files, in many cases very significantly.


## Constraints
Practically, a program split constraints file is just a yaml list of
constraint nodes. There are different types of constraint nodes,
with different properties, but nearly all of them reduce the number
of part files. Writing constraint files requires a good
understanding of the ordering of loadLibrary calls in a program. It
is worth pointing out that constraints always affect performance,
and never program correctness. Thus, incorrect use of constraints
should never break a valid Dart program, but can negatively impact
performance.

### Reference Nodes
The most basic node type is a reference node. A reference node is
just a way to create a symbol which represents a deferred import.

For example:
**foo.dart:**

```dart
import '...' deferred as baz;
```

**constraints.yaml:**

```yaml
  ...
  -  type: reference
     name: baz
     import: /path/to/foo.dart#baz
  ...
```

Creates a reference ‘baz’ which can be used in other nodes. We could
support references inline with the body of a node, but explicit
reference nodes do help keep constraints organized.

### Order Nodes
The most important constraint node is the order node. An order node
indicates that the ‘predecessor’ temporally dominates a given
‘successor’ and thus Dart2js should ensure any code shared between
predecessor and successor loads with the predecessor.

Sequencing even just two nodes will reduce the total number of
output units if those nodes share code but because sequencing is a
transitive operation the real benefit comes from deep hierarchies.

For example:

**foo.dart:**

```dart
import '...' deferred as step1;
import '...' deferred as step2;

do() {
  step1.loadLibrary().then((_) { step2.loadLibrary().then(...) } );
}
```

**constraints.yaml:**

```yaml
  ...
   - type: relative_order
     predecessor: step1
     successor: step2
  ...
```

### Combiner Nodes
Order nodes support both fan in and fan out, that is multiple
predecessors mapping to the same successor and multiple successors
mapping to the same predecessor. In addition to fan in / out, other
ways of combining constraints are supported via explicit combiner
nodes.

The primary purpose of combiner nodes is to allow users to propagate
ordering information deeper into the deferred graph. However,
combiner nodes will also reduce the number of part files in many
cases.

For v0, combiner nodes must have only reference nodes as children,
though in the longer term we may relax this restriction and allow
combiners to nest under certain situations. A further limitation is
that we do not currently support cycles in the constraints graph,
and thus every reference to a node references the exact same node.

#### ‘And’ Combiner Node
‘And’ nodes are used for cases where multiple loadLibrary calls are
guaranteed to occur at a certain point in time, but the relative
ordering of those nodes may change.

In the case of an ‘and’ node, because all of the nodes in an ‘and’
node are guaranteed to load at a given point in time, Dart2js can
merge certain part files. In the case of the below example, any code
shared between step1a and its successors can be merged into step1a.
And code shared between step1a and its predecessors can be merged
into its predecessors. The same optimizations will also apply to
step1b.  However step1a and step1b themselves will not merge.

For example:

**foo.dart**:

```dart
import '...' deferred as step1a;
import '...' deferred as step1b;

do() {
  if (...) {
    step1a.loadLibrary().then((_) { step1b.loadLibrary().then(...) } );
  } else {
    step1b.loadLibrary().then((_) { step1a.loadLibrary().then(...) } );
  }
}
```

**constraints.yaml**:

```yaml
  ...
  - type: and
    name: step1
    nodes:
      - step1a
      - step1b
  ...
```

#### ‘Or’ Combiner Node
‘Or’ nodes are used for cases where at least one of multiple
loadLibrary calls will occur at a certain point in time. Nodes
within an ‘or’ node need not be mutually exclusive.

Because at least one of the nodes within the ‘or’ is guaranteed to
load at a certain point in time, Dart2js can perform optimizations
with the code shared between all of the nodes in the ‘or.’
Specifically, code shared between successors of the ‘or’ node and
all of the nodes in the ‘or’ node can merge with the shared ‘or’
code, and code shared between all of the nodes in the ‘or’ and
predecessors can merge with predecessors without bloating load
lists.

For example:

**foo.dart:**

```dart
import '...' deferred as step1a;
import '...' deferred as step1b;

do() {
  if (...) {
    step1a.loadLibrary().then((_) { ... });
  } else {
    step1b.loadLibrary().then((_) { ... } );
  }
}
```

**constraints.yaml:**

```yaml
  ...
  - type: or
    name: step1
    nodes:
      - step1a
      - step1b
  ...
```

#### Fuse Combiner Node
Fuse nodes combine multiple nodes into a strongly connected
component. This is very useful in cases where two loadLibrary calls
almost always happen together. Fuse nodes can greatly reduce the
number of part files.

For example:

**foo.dart:**
```dart
import '...' deferred as step1a;
import '...' deferred as step1b;

do() {
  ...
}
```

**constraints.yaml:**
```yaml
  ...
  - type: fuse
    name: step1
    nodes:
      - step1a
      - step1b
  ...
```

## Examples
Below is a more complete example. The part files impact section is
based on a worst case scenario where code is shared between all
combinations of deferred imports.

**foo.dart**:

```dart
import '...' as deferred S1;
import '...' as deferred S2a;
import '...' as deferred S2b;
import '...' as deferred S3;

main() {
  S1.loadLibrary().then((_) {
    if (...) {
      S2a.loadLibrary().then((_) {
        S2b.loadLibrary().then((_) { S3.loadLibrary().then((_) {...}); });
      });
    } else {
      S2b.loadLibrary().then((_) {
        S2a.loadLibrary().then((_) { S3.loadLibrary().then((_) {...}); });
      });
    }
  });
}
```

**constraints.yaml**:

```yaml
  - type: reference
    name: s1
    import: /path/to/foo.dart#S1
  - type: reference
    name: s2a
    import: /path/to/foo.dart#S2a
  - type: reference
    name: s2b
    import: /path/to/foo.dart#S2b
  - type: reference
    name: s3
    import: /path/to/foo.dart#S3
  - type: $COMBINER_TYPE
    name: s2
    nodes: [ s2a, s2b ]
  - type: relative_order
    predecessor: s1
    successor: s2
  - type: relative_order
    predecessor: s2
    successor: s3
```

**part files impact**:

**unconstrained**
* {S1}
* {S2a}
* {S2b}
* {S3}
* {S1, S2a}
* {S1, S2b}
* {S1, S3}
* {S2a, S2b}
* {S2a, S3}
* {S2b, S3}
* {S1, S2a, S2b}
* {S1, S2a, S3}
* {S1, S2b, S3}
* {S2a, S2b, S3}
* {S1, S2a, S2b, S3}

**COMBINER\_TYPE = or**
* {S2a}
* {S2b}
* {S3}
* {S2a, S3}
* {S2b, S3}
* {S2a, S2b, S3}
* {S1, S2a, S2b, S3}

**COMBINER\_TYPE = and**
* {S3}
* {S2a, S3}
* {S2b, S3}
* {S2a, S2b, S3}
* {S1, S2a, S2b, S3}

**COMBINER\_TYPE = fuse**
* {S3}
* {S2a, S2b, S3}
* {S1, S2a, S2b, S3}

**load list impact(redundant loads are ~~crossed out~~):**

**unconstrained**
* S1 : {S1, S2a, S2b, S3}, {S1, S2a, S2b}, {S1, S2a, S3}, {S1, S2b, S3}, {S1, S2a}, {S1,  S2b}, {S1, S3}, {S1}
* S2a: ~~{S1, S2a, S2b, S3}, {S1, S2a, S2b}, {S1, S2a, S3}~~, {S2a, S2b, S3}, ~~{S1, S2a}~~, {S2a, S2b}, {S2a, S3}, {S2a}
* S2b: ~~{S1, S2a, S2b, S3}, {S1, S2a, S2b}, {S1, S2b, S3}~~, {S2a, S2b, S3}, ~~{S1, S2b}~~, {S2a, S2b}, {S2b, S3}, {S2b}
* S3 : ~~{S1, S2a, S2b, S3}, {S2a, S2b, S3}, {S1, S2a, S3}, {S1, S2b, S3}, {S2a, S3}, {S2b, S3}, {S1, S3}~~, {S3}

**COMBINER_TYPE = or**
* S1 : {S1, S2a, S2b, S3}
* S2a: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}, {S2a, S3}, {S2a}
* S2b: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}, {S2b, S3}, {S2b}
* S3 : ~~{S1, S2a, S2b, S3}, {S2a, S2b, S3}, {S2a, S3}, {S2b, S3}~~, {S3}

**COMBINER_TYPE = and**
* S1: {S1, S2a, S2b, S3}
* S2a: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}, {S2a, S3}
* S2b: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}, {S2b, S3}
* S3 : ~~{S1, S2a, S2b, S3}, {S2a, S2b, S3}, {S2a, S3}, {S2b, S3}~~, {S3}

**COMBINER_TYPE = fuse**
* S1: {S1, S2a, S2b, S3}
* S2a: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}
* S2b: ~~{S1, S2a, S2b, S3}~~, {S2a, S2b, S3}
* S3 : ~~{S1, S2a, S2b, S3}, {S2a, S2b, S3}~~, {S3}

## TODO
* Documentation for Inline references, glob support, groups, set
  operations on groups, nested combiners

## Glossary
* deferred import: A method of asynchronously loading code. Deferred
  imports are used to reduce the size of the main part file and thus
  improve IPL.
* deferred load: The runtime implementation of a deferred import.
* load list: A list of part files which must be loaded before a
  loadLibrary call completes.
* main part file: The part file representing the initial chunk of
  code which must be downloaded and initialized before a given
  program can run.
* part file: A chunk of JS code representing some subset of the
  compiled output which results from compiling a Dart program to JS
  via Dart2js.
* IPL: Stands for initial page load, i.e. the time it takes for a
  given web page to complete its first load.

