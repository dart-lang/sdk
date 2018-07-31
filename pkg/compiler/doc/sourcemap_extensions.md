# Source map extensions

Dart2js includes 2 extensions to the source-map format to improve deobfuscation
of production stack traces. These extensions compensate for some of the
optimizations that the compiler does which make deobfuscation harder.

## Format changes

Dart2js currently generates source-maps using the [source-map v3][sourcemapv3]
format. The format allows extensions as new map entries, as long as they are
prefixed by `x_` (other prefixes are reserved). We use an extension named
`x_org_dartlang_dart2js`, to store any additional information we need to
share between dart2js and the deobfuscation tools:

```
{
  version: 3,
  file: “main.dart.js”,
  sources: ["a.dart", "b.dart"],
  names: ["ClassA", "methodFoo"],
  mappings: "AAAA,E;;ABCDE;"
  x_org_dartlang_dart2js: {
    minified_names: {...},
    frames: [...]
  }
}
```

We include 2 sections: `minified_names` which encodes the mapping between
minified and deobfuscated names, and `frames` which encodes relevant
information about stack frames, including inlining decisions (so that
deobfuscation tools can expand them later on) and less-relevant frames (so that
deobfuscation tools can hide them or deemphasize them).

These new sections contain references to names and source URIs, but to
keep the encoding smaller, we reuse the sources and names tables from the
main source-map section.

## Minified names data

### Global minified names

Dart2js by default uses a global frequency based namer to choose minified
names. One of it's invariants is that there is a 1-1 mapping for class names
and method names (including getter names and setter names). For example, if two
classes have an instance method with the same public name and same signature of
optional arguments, they will also have the same minified method name.

To support deobfuscating type names and method names, we embed a translation
table for minified names, and we will
add a new mechanism to deobfuscator tools to recognize when these names are
present.


Dart2js divides names in several namespaces. Many namespaces are local and
but two of them are global to the entire program: `global` and `instance`. The
`global` namespace includes the names of classes, while the `instance`
namespace includes the names of instance members.

The format looks like this:

```
 ...
 x_org_dartlang_dart2js: {
    minified_names: {
      global: {
        "a": 3,  // an index in the names table, e.g. "topLevelMethod1"
        "X": 4,  // e.g. "MyAbstractClass"
      },
      instance: {
        "a": 5,  // e.g. "instanceMethod1"
        "gb": 6, // e.g. "myGetter"
      }
    }
  }
```

Initially our plan is just to include a mapping from one name to another.
Depending on how much detail we want deobfuscation tools to provide, we could
one day include the source location where the name is defined (for type names)
or a list of such locations (for instance methods).

Dart2js also has a global namespace for constants, but we do not believe those
names appear in error messages, so we don't include it in the source-map
file at this time.

### Recognizing types and method names in error messages

To help deobfuscator tools identify minified names, dart2js will ensure that
all string representations of types and method names include a marker to
indicate what namespace they belong to.

Several string representations already have a marker:
 * The default `instance.toString` (e.g. `new MyClass().toString()`) prints
`Instance of X`. The prefix "Instance of" is an indication that the name should
be found in the global namespace.
 * Tear-offs also have an indicator

Some string representations will change in the near future. For example
`x.runtimeType.toString()` will include a marker in minified-mode. Types can be
complex, so the marker will be next to every type symbol. For example,
a function type `ClassA Function(ClassB)` would be printed in minified mode as
`minified:x Function(minified:y)` instead of `x Function(y)`.

### Local minified names data

Unlike types, constants, and methods; fields, closure local, and local
variables don't have a 1-1 correspondence. There are various algorithms in use,
but the bottom-line is that it's possible to have two different field names
mapped to the same minified name, and similarly different local variable names
in different methods mapped to the same name.  These names are less likely to
show up in error messages, but when they do, it is often the case that they are
being used in the same line as the error.

To support deobfuscation of these names, dart2js will include the `sourceNameId`
on each symbol as it is emitting the regular source-map file. This can be
encoded in the standard source-map format without any extensions. Today dart2js
uses the `sourceNameId` to denote the name of the enclosing function instead.

## Inlining data

Dart2js uses method inlining heavily for optimizations. Inlined methods however
confuse users and deobfuscation tools. For users, there are less frames than
calls in the program, so they wonder where the missing frames are. For tools,
the way they find the method name of each frame by looking backwards for a
function declaration can create a mismatch in the deobfuscated stack trace: the
deobfuscated frame may show the name of a caller, but the location of an
inlined method.

The `frames` extension is a table with details about inlining information.
Each entry in this table consists of:
 * An offset in the program
 * A list of one or more frame entries, which in turn can be:
    * push: indicates that we entered an inlined context
    * pop: indicates that we returned from an inlined context
    * pop-and-empty: indicates that this is a pop that also ends an inlining
      context, hence the offset has no inlining. This is used to mark the end
      of a region containing inlining data

A push operation includes details about the call site, in particular:
 * the source location: offset into the sources URI table, line, and column.
 * the name of the inlined method (as and index in the name table), note that
   dart2js encodes instance methods as a compound name "ClassName.methodName".

Here is an example of what the encoded format would look like:
```
...
 x_org_dartlang_dart2js: {
    ...
    frames: [
      [ 2310, // offset containing data
         [2, 34, 11, 4]],  // a list encodes a push operation
      [ 2320, [4, 4, 2, 9]],
      [ 2330, -1], // -1 encodes a pop operation
      [ 2333, 0]   // 0 encodes a pop-and-empty operation
    ]
  }
```

A few details worth noting about the format:
 * Multiple operations are allowed in case multiple methods are inlined or
   return at once. In that case, the second inlining information will have the
   source-location where the first inlined method invokes the second inlined
   method.

   For example, `[110, [2, 11, 3, 200], [3, 10, 4, 19]]` represents 2 pushes at
   offset `110`: the current method calls method `200` (index in the name table)
   at location `2, 11, 3` (2 is an index in the URI map, 11 is line, 3 the
   column) which then calls method `19` at location `3, 10, 4`.

 * The encoding excludes the name of the caller because it can be derived from
   the existing context (either from source-map information of the enclosing
   function, or from the previous inlining push calls).

   We also considered to store the name of the caller and omit the callee, but
   decided against it. That would've worked today because we don't use
   source-names to support deobfuscation of fields and local names, instead we
   are storing the name of the method. As we improve deobfuscation of minified
   names, the name of the inlined method will no longer be available in the main
   source-map section, so we need to include the name of the callee here.

This encoding helps deobfuscation tools decode the full stack trace with a
simple backwards traversal of the table:

 * Based on the offset of a frame, a binary search is done to find the first
   entry before the frame location.

 * Then frames are visited backwards, tracking the current inlining level and
   counting pop and push operations. Once an "pop-and-empty" operation is
   found, the search stops.

Note that this encoding is also sparse and only requires us to add information
for methods containing inlining. That is because the empty markers basically
indicate that every method between a given offset and the empty marker had no
inlining in it.

[sourcemapv3]: https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit#heading=h.n05z8dfyl3yh
