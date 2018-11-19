dev_compiler
============

[![Build Status](https://travis-ci.org/dart-lang/sdk.svg?branch=master)](https://travis-ci.org/dart-lang/sdk)

The Dart Dev Compiler (DDC) is a fast, modular compiler that generates modern JavaScript (EcmaScript 6).  Its primary use today is to support fast, iterative development of Dart web applications for Chrome and other modern browsers.

Most users will use DDC via [pub](https://webdev.dartlang.org/tools/pub/pub-serve).  It is supported by pub starting with the Dart 1.24 release.

# Soundness and Restrictions

DDC is built upon Dart's new [strong mode](STRONG_MODE.md) type system.  It only compiles programs that statically type check (i.e., no strong mode errors).  It leverages static type checking to generate simpler, readable, and more idiomatic code with fewer runtime checks.  In general, DDC is able to provide stronger type guarantees - i.e., *soundness* - than traditional Dart checked mode with significantly fewer runtime checks.

With strong mode, DDC is stricter than traditional Dart production mode or checked mode.  Running existing Dart code on DDC will generally require fixing both static and runtime type errors.  

For example, although the following snippet will run in production or checked mode, it will fail to compile with DDC:

```dart
var list = ["hello", "world"];  // Inferred as List<String> in strong mode
List<int> list2 = list;  // Static type error: incompatible types
```

On the other hand, the following snippet - which tries to mask the type error via casts - will compile with DDC, but fail with a runtime type error.

```dart
var list = ["hello", "world"];
List<Object> list2 = list;  // Generics are covariant.  No runtime check required.
List<int> list3 = list2;  // Implicit runtime downcast triggers error.
```  

See the [strong mode documentation](STRONG_MODE.md) for more details.

# Modularity

DDC provides fast, incremental compilation based on standard JavaScript modules.  Unlike Dart2JS, DDC does not require an entire Dart application.  Instead, it operates modularly: it compiles a set of Dart files into a JavaScript module.  A DDC compilation step requires a set of input Dart files and a set of *summaries* of dependencies.  It performs modular type checking as part of this compilation step, and, if the input type checks, it generates a JavaScript module (e.g., [*ES6*](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import), [*AMD*](https://github.com/amdjs/amdjs-api/blob/master/AMD.md), or [*CommonJS*](https://nodejs.org/docs/latest/api/modules.html)).  The browser (i.e., the JavaScript runtime) loads and links the generated modules when running the application.
During development, a compilation step only needs to be rerun if the Dart files or summaries it relies upon change.  For most changes, only a very small part of your code will require recompilation.  Moreover, modules that are unchanged can be cached in the browser.

Most users invoke DDC indirectly via [pub](https://webdev.dartlang.org/tools/pub/pub-serve).  Pub computes module structure and build steps automatically and invoke DDC accordingly.  Pub configures DDC to use AMD modules and uses the standard [AMD `require.js` loader](http://requirejs.org/) to bootstrap and load the application.

More advanced users may want to configure or invoke DDC directly.  In general, the mapping of Dart files to JS modules is flexible.  The key requirement is that module dependencies (i.e., `require` in AMD or CommonJS or `import` in ES6) must be acyclic.  In practice, this means that individual Dart libraries cannot each be mapped to a corresponding JS module (as Dart imports can be and often are cyclic).  See the [usage document](USAGE.md) for more details.

# EcmaScript 6

DDC attempts to map Dart to idiomatic EcmaScript 6 (ES6) as cleanly as possible, and it relies heavily on static typing to do this.  In general, where Dart concepts map directly to ES6, DDC generates code accordingly.  For example, Dart classes are mapped to ES6 classes, Dart fields to ES6 properties, Dart getters/setters to ES6 getters/setters, Dart methods to ES6 methods, and so on.  In most cases, names are preserved and calling conventions are natural JavaScript ones.

There are some import caveats where Dart concepts do not map directly:

- *Libraries*.  Multiple Dart libraries are mapped to a single JS module.  Each library appears as a first class object in the generated JS module, with its top-level symbols as members.  We currently use a heuristic (based upon file paths) to ensure unique naming of generated library objects.
- *Generics*.  Dart generics are *reified*, i.e., they are preserved at runtime.  Generic classes are mapped to factories that, given one or more type parameters, return an actual ES6 class (e.g., `HashMap$(core.String, core.int)` produces a class that represents a HashMap from strings to ints).  Similarly, generic methods are mapped to factories that, given one or more type parameters, return a method.  
- *Dynamic*.  DDC supports dynamically typed code (i.e., Dart's `dynamic` type), but it will typically generate less readable and less efficient ES6 output as many type checks must be deferred to runtime.  All dynamic operations are invoked via runtime helper code.
- *Constructors*.  Dart supports multiple, named and factory constructors for a given class with a different initialization order for fields.  Today, these are mapped to instance or static methods on the generated ES6 class.
- *Private members*.  Dart maps private members (e.g., private fields or methods) to ES6 symbols.  For example, `a._x` may map to `a[_x]` where `_x` is a symbol only defined in the scope of the generated library.
- *Scoping*.  Dart scoping rules and reserved words are slightly different than JavaScript.  While we try to preserve names wherever possible, in certain cases, we are required to rename.

In general, the current conventions (i.e., the Application Binary Interface or ABI in compiler terminology) should not be considered stable.  We reserve the right to change these in the future.

# Browser support

DDC currently supports Chrome stable (though users have had success running on FireFox and Safari).  In the near future, we expect to target all common modern browsers that support ES6.  ES6 itself is in active development across all modern browsers, but at advanced stages of support:

[kangax.github.io/compat-table/es6](https://kangax.github.io/compat-table/es6/).
