# The dart2js compiler

Welcome to the sources of the dart2js compiler!

## Architecture

The compiler is currently undergoing a long refactoring process. As you navigate
this code you may find it helpful to understand how the compiler used to be,
where it is going, and where it is today.

### The near future architecture

The compiler will operate in these general phases:

  1. **load kernel**: Load all the code as kernel
      * Collect dart sources transtively
      * Convert to kernel AST  
  
  (this will be handled by invoking the front-end package)
  
  Alternatively, the compiler can start compilation directly from kernel files.

  2. **model**: Create a Dart model of the program
     * The kernel ASTs could be used as a model, so this might be a no-op or just
       creating a thin wrapper on top of kernel.

  3. **tree-shake and create world**: Build world of reachable code
     * For each reachable piece of code:
         * Compute impact (i1) from kernel AST
     * Build a closed world (w1)

  4. **analyze**: Run a global analysis
     * Assume closed world semantics (from w1)
     * Produce a global result (g)
        * Like today (g) will contain type and nullability information
        * After we adopt strong-mode types, we want to explore simplifying this
        to only contain native + nullability information.

  5. **codegen model**: Create a JS model of the program
     * Model JavaScript specific concepts (like the split of constructor bodies
       as separate elements) and provide a mapping to the Dart model

  6. **codegen and tree-shake**: Generate code, as needed
     * For each reachable piece of code:
        * build ssa graph from kernel ASTs and global results (g)
        * optimize ssa
        * compute impact (i2) from optimized code
        * emit JS ASTs for the code
     * Build a codegen closed world (w2) from new impacts (i2)

  7. **emit**: Assemble and minify the program
     * Build program structure from the compiled pieces (w2)
     * Use frequency namer to minify names.
     * Emit js and source map files.

### The old architecture

The compiler used to operate as follows:

  1. **load dart**: Load all source files
     * Collect dart sources transtively
     * Scan enough tokens to build import dependencies.

  2. **model**: Create a Dart model (aka. Element Model) of the program
     * Do a diet-parse of the program to create the high-level element model

  3. **resolve and tree-shake**: Resolve and build world of reachable code (the
     resolution enqueuer)
     * For each reachable piece of code:
        * Parse the full body of the function
        * Resolve it and enqueue other pieces that are reachable
        * Type check the body of the function

  4. **analyze**: Run a global analysis
     * Assume closed world semantics (from everything enqueued by the resolver)
     * Produce a global result about type and nullability information of method
       arguments, return values, and receivers of dynamic sends.

  5. **codegen and tree-shake**: Generate code, as needed (via the codegen
     enqueuer)
     * For each reachable piece of code:
        * build ssa graph from resolved source ASTs global results (g)
        * optimize ssa
        * enqueue visible dependencies
        * emit js asts for the code

  6. **emit**: Assemble and minify the program
     * Build program structure from the compiled pieces
     * Use frequency namer to minify names.
     * Emit js and source map files.

### The architecture today (which might be changing while you read this!)

When using the `--use-kernel` flag, you can test the latest state of the
compiler as we are migrating to the new architecture. Currently it works as
follows:

  1. **load dart**: (same as old compiler)

  2. **model**: (same element model as old compiler)

  3. **resolve, tree-shake and build world**: Build world of reachable code
     * For each reachable piece of code:
        * Parse full body of the function
        * Resolve it from the parsed source ASTs
        * Type check it (same as old compiler)
        * Compute impact (i1) from resolved source ASTs (no kernel)
     * Build a closed world (w1)

  4. **kernelize**: Create kernel ASTs
     * For all resolved elements in w1, compute their kernel representation using
       the `rasta` visitor.

  5. **analyze**: (almost same as old compiler)

  6. **codegen and tree-shake**: Generate code, as needed
     * For each reachable piece of code:
        * build ssa graph from kernel ASTs (uses global results g)
        * optimize ssa
        * compute impact (i2) from optimized code
        * emit js asts for the code
     * Build a codegen closed world (w2) from new impacts (i2)

  7. **emit**: (same as old compiler)

Some additional details worth highlighting:

  * tree-shaking is close to working as we want: the notion of a world and world
    impacts are computed explicitly:

     * In the old compiler, the resolver and code generator directly
       enqueued items to be processed, there was no knowledge of what had
       to be done other than in the algorithm itself.

     * Now the information is computed explicitly in two ways:

       * The dependencies of a single element are computed as an "impact"
         object, these are derived from the structure of the
         code (either the resolved code or the generated code).

       * The closed world is now an explicit concept that can be replaced in the
         compiler.

     * This allows us to delete the resolver in the future and replace it
       with a kernel loader, an impact builder from kernel, and a kernel world.

     * There is an implementation of a kernel impact builder, but it is not yet
       in use in the compiler pipeline (gated on replacing the Dart model)

  * We still depend on the Dart model computed by resolution, but progress has
    been made introducing an abstraction common to the new and old models. The
    old model is the "Element model", the generic abstraction is called the
    "Entity model". Some portions of the compiler now refer to the entity model.

  * The ssa graph is built from the kernel ASTs, but it still depends on the old
    element model computed from resolution (accessed via a kernel2Ast adapter).
    The graph builder implementation covers a large chunk of the language
    features, but is not complete (89% of langage & corelib tests are passing).

  * Global analysis is still working on top of the dart2js ASTs.

## Code organization and history

The compiler package was initially intended to be compiler for multiple targets:
Javascript, Dart (dart2dart), and dartino bytecodes. It has now evolved to be a
Javascript only compiler, but some of the abstractions to support multiple
targets still remain.

### Possibly confusing terminology

Some of the terminology in the compiler is confusing without knowing its
history. We are cleaning this up as we are rearchitecting the system, but here
are some of the legacy terminology we have:

  * **target**: the output the compiler is producing. Nowdays it just
    JavaScript, but in the past there was also Dart and dartino bytecodes.

  * **backend**: pieces of the compiler that were target-specific.
    Note: in the past we've used the term *backend* also for code that is used
    in the frontend of the compiler that happens to be target-specific, as well
    as and code that is used in the emitter or what traditionally is known
    as the backend of the compiler.

  * **frontend**: the parser, resolver, and other early stages of the compiler.
    The front-end however makes target-specific choices. For example, to compile
    a program with async-await, the dart2js backend needs to include some helper
    functions that are used by the expanded async-await code, these helpers need
    to be parsed by the frontend and added to the compilation pipeline.

  * **world**: the compiler exploits closed-world assumptions to do
    optimizations. The *world* encapsulates some of our knowledge of the
    program, like what's reachable from `main`, which classes are instantiated,
    etc.

  * **universe**: rather than loading entire programs and removing unreachable
    code, the compiler uses a tree-growing approach: it enqueues work based on
    what it sees. While this is happening the *world* is considered to be
    growing, in the past the term *universe* was used to describe this growing
    world. While the term is not completely deleted from the codebase, a lot of
    progress has been made to rename *universe* into *world builders*.

  * **model**: there are many models in the compiler:

    * **element model**: this is an abstraction describing the elements seen in
      Dart programs, like "libraries", "classes", "methods", etc.

    * **entity model**: also describes elements seen in Dart programs, but it is
      meant to be minimalistic and a super-hierarchy above the *element models*.
      This is a newer addition, is an added abstraction to make it possible to
      refactor our code from our old frontend to the kernel frontend.

    * **Dart vs JS models**: the compiler in the past had a single model to
      describe elements in the source and elements that were being compiled. In
      the future we plan to have two. Both input model and output models will be
      implementations of the *entity model*. The JS model is intended to have
      concepts specific about generating code in JS (like constructor-bodies as
      a separate entity than the constructor, closure classes, etc).

    * **emitter model**: this is a model just used for dumping out the structure
      of the program in a .js text file. It doesn't have enough semantic meaning
      to be a JS model for compilation at this moment.

  * **enqueuer**: a work-queue used to achieve tree-shaking (or more precisely
    tree-growing): elements are added to the enqueuer as we recognize that they
    are needed in a given application. Note that we even track how elements are
    used, since some ways of using an element require more code than others.

### Code layout

Here are some details of our current code layout and what's in each file. This
list also includes some action items (labeled AI below), which are mainly
cleanup tasks that we have been discussing for a while:

**bin folder**: some experimental command-line entrypoints, these need to be
revisited

* `bin/dart2js.dart`: is a dart2js entry point, not used today other than
  locally for development, most of our tools launch dart2js from
  `lib/src/dart2js.dart` instead.

  AI: change how we build the SDK to launch dart2js from here, most logic might
  remain inside `lib/src/dart2js.dart` for testing purposes.

**lib folder**: API to use dart2js as a library. This is used by our
command-line tool to launch dart2js, but also by pub to invoke dart2js as a
library during `pub-build` and `pub-serve`.

* `lib/compiler_new.dart`: the current API. This API is used by our command-line
  tool to spawn the dart2js compiler. This API (and everything that is
  transitively created from it) has no dependencies on `dart:io` so that the
  compiler can be used in contexts where `dart:io` is not available (e.g.
  running in a browser worker) or where `dart:io` is not used explicitly (e.g.
  running as a pub transformer).

  AI: rename to `compiler.dart`.

* `lib/compiler.dart`: a legacy API that now is implemented by adapting calls to
  the new API in `compiler_new.dart`.

  AI: migrate users to the new API (pub is one of those users, possibly dart-pad
  is another), and delete the legacy API.

**lib/src folder**: most of the compiler lives here, as very little of its
functionality is publicly exposed.


* `lib/src/dart2js.dart`: the command-line script that runs dart2js. When
  building the SDK, the dart2js snapshot is built using the main method on this
  script.  This file creates the parameters needed to invoke the API defined in
  `lib/compiler_new.dart`. All dependencies on `dart:io` come from here. This is
  also where we process options (although some of the logic is done in
  `options.dart`).

* `lib/src/compiler.dart`: defines the core `Compiler` object, which contains
  all the logic about what the compiler pipeline does and how data is organized
  and communicated between different phases. For a long time, `Compiler` was
  also used throughout the system as a global dependency-injection object.
  We've been slowly disentangling those dependencies, but there are still many
  references to `compiler` still in use.

* `lib/src/apiimpl.dart`: defines `CompilerImpl` a subclass of `Compiler` that
  adds support for loading scripts, resolving package URIs and patch files. The
  separation here is a bit historical and we should be able to remove it. It was
  added to make it easier to create a `MockCompiler` implementation for unit
  testing. The `MockCompiler` has been replaced in most unit tests by a regular
  `CompilerImpl` that uses a mock of the file-system (see
  `tests/compiler/dart2js/memory_compiler.dart`).

  AI: Once all tests are migrated to this memory compiler, we should merge
  `Compiler` and `CompilerImpl` and remove this file.

* `lib/src/old_to_new_api.dart`: helper library used to adapt the public API in
  `lib/compiler.dart` to `lib/compiler_new.dart`.

* `lib/src/closure.dart`: closures are compiled as classes, this file has the
  logic to do this kind of conversion in the Dart element model. This includes
  computing what needs to be boxed and creating fake element models to represent
  closures as classes. We use the fake model approach because the compiler
  currently uses the same element model for Dart and JS. Our goal with the
  compiler rearchitecture described earlier is to have two models. The
  Dart model will be able to encode closures directly, and we'll introduce their
  corresponding classes when we create the corresponding JS model, removing the
  need of the fake elements.

* `lib/src/colors.dart`: ANSI support for reporting error messages with colors.

  AI: this file should move under a utilities folder.


* Handling of options: as mentioned earlier `lib/src/dart2js.dart` has some
  handling of command-line options, the rest is divided into these files:

  * `lib/src/commandline_options.dart`: defines the flags that dart2js accepts.

  * `lib/src/options.dart`: defines first-class objects to represent options of
    dart2js. This includes a parse function that can translate flags into their
    corresponding objects. This was added recently to simplify how options were
    propagated throughout the compiler.

  AI: simplify further how we specify options. Ideally all changes can be done
  in a single file (`options.dart`?), and unit-tests can specify options via an
  options object rather than command-line flags.

* `lib/src/common.dart`: convenience file that reexports code used in many
  places in the compiler.

  AI: consider deleting this file.


* Constants: the compiler has a constant system that delays evaluation of
  constants and provides different semantics depending on the embedder, this
  abstraction was especially necessary when dart2js was used as a front-end for
  non-JS systems like dart2dart and dartino.

  * `lib/src/constants/expressions.dart`: this is how constants are represented
    after they are parsed but before they are evaluated. It is a target
    agnostic representation, all expressions are kept as they appear in the
    source, and it doesn't replace _environemnt_ values that are provided on the
    command line. In particular, the constant `1 == 1.0` is represented as an
    expression that includes the `==` binary expression, and `const
    String.fromEnvironment("FOO")` is not expanded.

  * `lib/src/constants/value.dart`: this is the represented value of a constant
    after it has been evaluated. The resulting value is specific to the target
    of the compiler and will no longer have environment placeholders. For
    example, when the target is Dart (dart2dart) `1 == 1.0` is evaluated to
    `false`, and when the target is JavaScript it is evaluated to `true`. This
    specific example is a result of the way dart2js compiles numbers as
    JavaScript Numbers.

  * `lib/src/constants/evaluation.dart`: defines the algorithm to turn an
    expression into a value.

  * `lib/src/constants/constant_system.dart`: an abstraction that defines how
    expressions may be folded. Different implementations of the constant system
    are used to target Dart or JavaScript.

  * `lib/src/compile_time_constants.dart`: defines how constant expressions are
    created from a parsed AST.

  * `lib/src/constant_system_dart.dart`: defines an implementation of a constant
    system with the Dart semantics (where `1 == 1.0` is true).

  * `lib/src/js_backend/constant_system_javascript.dart`: defines an
    implementation of a constant system with the JavaScript semantics (where
    `1 == 1.0` is false).

  * `lib/src/constants/constructors.dart` and
    `lib/src/constants/constant_constructors.dart`: used to define expressions
    containing constant constructors. They depend on the resolver to figure out
    what is the meaning of an initializer or a field on a constructed constant
    created this way.

  AI: consider deleting `constant_system_dart.dart` now that it is no longer
  used, or move under testing, if it might be used for unittests of the constant
  expressions.

* Common elements: the compiler often refers to certain elements during
  compilation either because they are first-class in the language or because
  they are implicitly used to implement some features. These include:

  * `lib/src/common_elements.dart`: provides an interface to lookup basic
    elements like the class of `Object`, `int`, `List`, and their corresponding
    interface types, constructors for symbols, annotations such as
    `@MirrorsUsed`, the `identical` function, etc. These are normally restricted
    to elements that are understood directly in Dart.

  * `lib/src/js_backend/backend_helpers.dart`: provides a way to lookup internal
    elements of the Javascript backend, like our internal
    representation of JSInt31, JSArray, and other implementation-specific
    elements.

* `lib/src/dart2js_resolver.dart`: a script to run the compiler up to resolution
  and to generate a serialized json representation of the element model.

  AI: delete.

* `lib/src/deferred_load.dart`: general analysis for deferred loading. This is
  where we compute how to split the code in different JS chunks or fragments.
  This is run after resolution, but at a time when no code is generated yet, so
  the decisions made here are used later on by the emitter to dump code into
  different files.

* `lib/src/dump_info.dart`: a special phase used to create a .info.json file.
  This file contains lots of information computed by dart2js including decisions
  about deferred loading, results of the global type-inference, and the actual
  code generated for each function. The output is used by tools provided in the
  `dart2js_info` package to analyze a program and better understand why
  something wasn't optimized as you'd expect.

* Tree-shaking: The compiler does two phases of reducing the program size by
  throwing away unreachable code. The first phase is done while resolving the
  program (reachablity is basically based on dependencies that appear in the
  code), the second phase is done as functions are optimized (which in turn can
  delete branches of the code and make more code unreachable). Externally
  we refer to it as tree-shaking, but it behaves more like a tree-growing
  algorithm: elements are added as they are discovered or as they are used.
  On some large apps we've seen 50% of code tree-shaken: 20% from the first
  phase, and an additional 30% from the second phase.

  * `lib/src/enqueue.dart`: this is the basic algorithm that adds things as they
    are discovered during resolution.

  * `lib/src/js_backend/enqueuer.dart`: this is the enqueuer used during code
    generation.

* `lib/src/environment.dart`: simple interface for collecting environment values
  (these are values passed via -D flags on the command line).

* `lib/src/filenames.dart`: basic support for converting between native and Uri
  paths.

  AI: move to utils

* `lib/src/id_generator.dart`: simple id generator

  AI: move to utils

* `lib/src/library_loader.dart`: the loader of the dart2js frontend. Asks the
  compiler to read and scan files, produce enough metadata to understand
  import, export, and part directives and keep crawling. It also triggers the
  patch parser to load patch files.

* `lib/src/mirrors_used.dart`: task that analyzes `@MirrorsUsed` annotations,
  which let the compiler continue to do tree-shaking even when code is used via
  `dart:mirrors`.

* Input/output: the compiler is designed to avoid all dependencies on dart:io.
  Most data is consumed and emitted via provider APIs.

  * `lib/src/compiler_new.dart`: defines the interface of these providers (see
    `CompilerInput` and `CompilerOutput`).

  * `lib/src/null_compiler_output.dart`: a `CompilerOutput` that discards all
    data written to it (name derives from /dev/null).

  * `lib/src/source_file_provider.dart`: _TODO: add details_.

* Parsing: most of the parsing logic is now in the `front_end` package,
  currently under `pkg/front_end/lib/src/fasta/scanner` and
  `pkg/front_end/lib/src/fasta/parser`. The `front_end` parser is AST agnostic
  and uses listeners to create on the side what they want as the result of
  parsing. The logic to create dart2js' ASTs is defined in listeners within the
  compiler package:

  * `lib/src/parser/element_listener.dart`: listener used to create the first
    skeleton of the element model (used by the diet parser)

  * `lib/src/parser/partial_elements.dart`: representation of elements in the
    element model whose body is not parsed yet (e.g. a diet-parsed member).

  * `lib/src/parser/node_listener.dart`: listener used to create the body of
    methods.

  * `lib/src/parser/member_listener.dart`: listener used to attach method bodies
    to class members.

  * `lib/src/parser/parser_task.dart`: Task to execute the full parser.

  * `lib/src/parser/diet_parser_task.dart`: Task to execute diet parsing.

  * `lib/src/patch_parser.dart`: additional support for parsing patch files. We
    expect this will also move under `front_end` in the future.


* URI resolution: the compiler needs special logic to resolve `dart:*` URIs and
  `package:*` URIs. These are specified in three parts:

  * sdk library files are specified in a .platform file. This file has a special
    .ini format which is parsed with `lib/src/platform_configuration.dart`.

  * sdk patch files are hardcoded in the codebase in
    `lib/src/js_backend/backend.dart` (see `_patchLocations`).

  * package resolution is specified with a `.packages` file, which is parsed
    using the `package_config` package.

  * `lib/src/resolved_uri_translator.dart`: has the logic to translate all these
    URIs when they are encountered by the library loader.

  AI: consider changing the .platform file format to yaml.


* `lib/src/typechecker.dart`: the type checker (spec mode semantics, no support
  for strong mode here).

* World: _TODO: add details_

  * `lib/src/world.dart`
  * `lib/src/universe/call_structure.dart`
  * `lib/src/universe/use.dart`
  * `lib/src/universe/feature.dart`
  * `lib/src/universe/world_impact.dart`
  * `lib/src/universe/selector.dart`
  * `lib/src/universe/side_effects.dart`
  * `lib/src/universe/class_set.dart`
  * `lib/src/universe/world_builder.dart`
  * `lib/src/universe/function_set.dart`


* Testing, debugging, and what not: _TODO: add details_
  * `lib/src/tracer.dart`
  * `lib/src/use_unused_api.dart`


* SSA (`lib/src/ssa`): internal IR used to optimize functions before emitting
  JavaScript. _TODO: add details_.
  * `ssa.dart`
  * `kernel_string_builder.dart`
  * `codegen.dart`
  * `variable_allocator.dart`
  * `type_builder.dart`
  * `value_set.dart`
  * `types.dart`
  * `jump_handler.dart`
  * `codegen_helpers.dart`
  * `switch_continue_analysis.dart`
  * `types_propagation.dart`
  * `nodes.dart`
  * `kernel_ast_adapter.dart`
  * `graph_builder.dart`
  * `validate.dart`
  * `builder.dart.rej`
  * `interceptor_simplifier.dart`
  * `builder_kernel.dart`
  * `locals_handler.dart`
  * `optimize.dart`
  * `kernel_impact.dart`
  * `invoke_dynamic_specializers.dart`
  * `builder.dart`
  * `ssa_branch_builder.dart`
  * `value_range_analyzer.dart`
  * `ssa_tracer.dart`
  * `loop_handler.dart`

* `tool`: some helper scripts, some of these could be deleted

  * `tool/perf.dart`: used by our benchmark runners to measure performance of
    some frontend pieces of dart2js. We should be able to delete it in the near
    future once the front end code is moved into `fasta`.

  * `tool/perf_test.dart`: small test to ensure we don't break `perf.dart`.

  * `tool/track_memory.dart`: a helper script to see memory usage of dart2js
    while it's running. Used in the past to profile the global analysis phases
    when run on very large apps.

  * `tool/dart2js_stress.dart` and `tool/dart2js_profile_many.dart`: other
    helper wrappers to make it easier to profile dart2js with Observatory.

* Source map tracking (`lib/src/io`): helpers used to track source information
  and to build source map files. _TODO: add details_.
   * `lib/src/io/code_output.dart`
   * `lib/src/io/source_map_builder.dart`
   * `lib/src/io/start_end_information.dart`
   * `lib/src/io/position_information.dart`
   * `lib/src/io/source_information.dart`
   * `lib/src/io/source_file.dart`
   * `lib/src/io/line_column_provider.dart`

* Kernel conversion (`lib/src/kernel`): temporary code to create kernel within
  dart2js (previously known as `rasta`). Most of this code will be gone when we
  are in the final architecture. _TODO: add details_.
   * `lib/src/kernel/task.dart`
   * `lib/src/kernel/kernel_visitor.dart`
   * `lib/src/kernel/kernel_debug.dart`
   * `lib/src/kernel/unresolved.dart`
   * `lib/src/kernel/kernel.dart`
   * `lib/src/kernel/unavailable.dart`
   * `lib/src/kernel/accessors.dart`
   * `lib/src/kernel/constant_visitor.dart`
   * `lib/src/kernel/error.dart`

* Global whole-program analysis (a.k.a. type inference): We try to avoid the
  term "type inference" to avoid confusion with strong-mode type inference.
  However the code still uses the term inference for this global analysis. The
  code is contained under `lib/src/inferrer`. _TODO: add details_.
   * `lib/src/inferrer/type_graph_dump.dart`
   * `lib/src/inferrer/node_tracer.dart`
   * `lib/src/inferrer/list_tracer.dart`
   * `lib/src/inferrer/closure_tracer.dart`
   * `lib/src/inferrer/inferrer_engine.dart`
   * `lib/src/inferrer/type_graph_inferrer.dart`
   * `lib/src/inferrer/type_graph_nodes.dart`
   * `lib/src/inferrer/type_system.dart`
   * `lib/src/inferrer/debug.dart`
   * `lib/src/inferrer/locals_handler.dart`
   * `lib/src/inferrer/map_tracer.dart`
   * `lib/src/inferrer/builder.dart`

* Serialization (`lib/src/serialization/*`: the compiler had support to emit a
  serialized form of the element model. This is likely going to be deleted in
  the near future (it was created before we had the intent to use kernel as a
  serialization format).

---------

_TODO: complete the documentation for the following files_.

`lib/src/ordered_typeset.dart`
`lib/src/script.dart`
`lib/src/string_validator.dart`

`lib/src/native`
`lib/src/native/ssa.dart`
`lib/src/native/scanner.dart`
`lib/src/native/js.dart`
`lib/src/native/enqueue.dart`
`lib/src/native/behavior.dart`
`lib/src/native/native.dart`

`lib/src/js_emitter`
`lib/src/js_emitter/native_emitter.dart`
`lib/src/js_emitter/main_call_stub_generator.dart`
`lib/src/js_emitter/model.dart`
`lib/src/js_emitter/headers.dart`
`lib/src/js_emitter/native_generator.dart`
`lib/src/js_emitter/parameter_stub_generator.dart`
`lib/src/js_emitter/constant_ordering.dart`
`lib/src/js_emitter/program_builder`
`lib/src/js_emitter/program_builder/collector.dart`
`lib/src/js_emitter/program_builder/program_builder.dart`
`lib/src/js_emitter/program_builder/field_visitor.dart`
`lib/src/js_emitter/program_builder/registry.dart`
`lib/src/js_emitter/metadata_collector.dart`
`lib/src/js_emitter/code_emitter_task.dart.rej`
`lib/src/js_emitter/code_emitter_task.dart.orig`
`lib/src/js_emitter/code_emitter_task.dart`
`lib/src/js_emitter/interceptor_stub_generator.dart`
`lib/src/js_emitter/full_emitter`
`lib/src/js_emitter/full_emitter/class_builder.dart`
`lib/src/js_emitter/full_emitter/container_builder.dart`
`lib/src/js_emitter/full_emitter/deferred_output_unit_hash.dart`
`lib/src/js_emitter/full_emitter/class_emitter.dart`
`lib/src/js_emitter/full_emitter/interceptor_emitter.dart`
`lib/src/js_emitter/full_emitter/code_emitter_helper.dart`
`lib/src/js_emitter/full_emitter/emitter.dart`
`lib/src/js_emitter/full_emitter/setup_program_builder.dart`
`lib/src/js_emitter/full_emitter/declarations.dart`
`lib/src/js_emitter/full_emitter/nsm_emitter.dart`
`lib/src/js_emitter/type_test_registry.dart`
`lib/src/js_emitter/js_emitter.dart.rej`
`lib/src/js_emitter/class_stub_generator.dart`
`lib/src/js_emitter/lazy_emitter`
`lib/src/js_emitter/lazy_emitter/model_emitter.dart`
`lib/src/js_emitter/lazy_emitter/emitter.dart`
`lib/src/js_emitter/startup_emitter`
`lib/src/js_emitter/startup_emitter/deferred_fragment_hash.dart`
`lib/src/js_emitter/startup_emitter/model_emitter.dart`
`lib/src/js_emitter/startup_emitter/emitter.dart`
`lib/src/js_emitter/startup_emitter/fragment_emitter.dart`
`lib/src/js_emitter/js_emitter.dart`
`lib/src/js_emitter/helpers.dart`
`lib/src/js_emitter/runtime_type_generator.dart`
`lib/src/js_emitter/js_emitter.dart.orig`

`lib/src/elements`
`lib/src/elements/modelx.dart`
`lib/src/elements/types.dart`
`lib/src/elements/resolution_types.dart`
`lib/src/elements/entities.dart`
`lib/src/elements/common.dart`
`lib/src/elements/names.dart`
`lib/src/elements/visitor.dart`
`lib/src/elements/elements.dart`

`lib/src/diagnostics`
`lib/src/diagnostics/invariant.dart`
`lib/src/diagnostics/generated`
`lib/src/diagnostics/generated/shared_messages.dart`
`lib/src/diagnostics/messages.dart`
`lib/src/diagnostics/source_span.dart`
`lib/src/diagnostics/code_location.dart`
`lib/src/diagnostics/diagnostic_listener.dart`
`lib/src/diagnostics/spannable.dart`

`lib/src/common`
`lib/src/common/codegen.dart`
`lib/src/common/resolution.dart`
`lib/src/common/tasks.dart`
`lib/src/common/work.dart`
`lib/src/common/backend_api.dart`
`lib/src/common/names.dart`

`lib/src/tokens/token_map.dart`: unused

`lib/src/resolution`
`lib/src/resolution/typedefs.dart`
`lib/src/resolution/registry.dart.orig`
`lib/src/resolution/scope.dart`
`lib/src/resolution/members.dart`
`lib/src/resolution/label_scope.dart`
`lib/src/resolution/registry.dart.rej`
`lib/src/resolution/resolution.dart`
`lib/src/resolution/access_semantics.dart`
`lib/src/resolution/operators.dart`
`lib/src/resolution/member_impl.dart`
`lib/src/resolution/resolution_common.dart`
`lib/src/resolution/semantic_visitor.dart`
`lib/src/resolution/resolution_result.dart`
`lib/src/resolution/send_resolver.dart`
`lib/src/resolution/send_structure.dart`
`lib/src/resolution/variables.dart`
`lib/src/resolution/enum_creator.dart`
`lib/src/resolution/members.dart.orig`
`lib/src/resolution/type_resolver.dart`
`lib/src/resolution/class_members.dart`
`lib/src/resolution/constructors.dart`
`lib/src/resolution/secret_tree_element.dart`
`lib/src/resolution/registry.dart`
`lib/src/resolution/tree_elements.dart`
`lib/src/resolution/semantic_visitor_mixins.dart`
`lib/src/resolution/class_hierarchy.dart`
`lib/src/resolution/signatures.dart`

`lib/src/scanner`
`lib/src/scanner/scanner_task.dart`

`lib/src/helpers`
`lib/src/helpers/trace.dart`
`lib/src/helpers/debug_collection.dart`
`lib/src/helpers/expensive_map.dart`
`lib/src/helpers/helpers.dart`
`lib/src/helpers/track_map.dart`
`lib/src/helpers/expensive_set.dart`
`lib/src/helpers/stats.dart`

`lib/src/js`
`lib/src/js/js.dart`
`lib/src/js/placeholder_safety.dart`
`lib/src/js/js_debug.dart`
`lib/src/js/js_source_mapping.dart`
`lib/src/js/rewrite_async.dart`

`lib/src/util`
`lib/src/util/uri_extras.dart`
`lib/src/util/indentation.dart`
`lib/src/util/enumset.dart`
`lib/src/util/link.dart`
`lib/src/util/util.dart`
`lib/src/util/maplet.dart`
`lib/src/util/setlet.dart`
`lib/src/util/characters.dart`
`lib/src/util/emptyset.dart`
`lib/src/util/link_implementation.dart`
`lib/src/util/util_implementation.dart`
`lib/src/util/command_line.dart`

`lib/src/js_backend`
`lib/src/js_backend/frequency_namer.dart`
`lib/src/js_backend/patch_resolver.dart`
`lib/src/js_backend/minify_namer.dart`
`lib/src/js_backend/mirrors_analysis.dart`
`lib/src/js_backend/js_backend.dart`
`lib/src/js_backend/field_naming_mixin.dart`
`lib/src/js_backend/native_data.dart`
`lib/src/js_backend/namer.dart`
`lib/src/js_backend/custom_elements_analysis.dart`
`lib/src/js_backend/type_variable_handler.dart`
`lib/src/js_backend/js_interop_analysis.dart`
`lib/src/js_backend/backend_impact.dart`
`lib/src/js_backend/constant_emitter.dart`
`lib/src/js_backend/lookup_map_analysis.dart`
`lib/src/js_backend/namer_names.dart`
`lib/src/js_backend/runtime_types.dart`
`lib/src/js_backend/no_such_method_registry.dart`
`lib/src/js_backend/constant_system_javascript.dart`
`lib/src/js_backend/backend.dart`
`lib/src/js_backend/backend_serialization.dart`
`lib/src/js_backend/checked_mode_helpers.dart`
`lib/src/js_backend/constant_handler_javascript.dart`

`lib/src/tree`
`lib/src/tree/prettyprint.dart`
`lib/src/tree/tree.dart`
`lib/src/tree/nodes.dart`
`lib/src/tree/dartstring.dart`
`lib/src/tree/unparser.dart`

`lib/src/types`
`lib/src/types/abstract_value_domain.dart`
`lib/src/types/types.dart`
`lib/src/types/type_mask.dart`
`lib/src/types/dictionary_type_mask.dart`
`lib/src/types/map_type_mask.dart`
`lib/src/types/forwarding_type_mask.dart`
`lib/src/types/container_type_mask.dart`
`lib/src/types/constants.dart`
`lib/src/types/flat_type_mask.dart`
`lib/src/types/masks.dart`
`lib/src/types/value_type_mask.dart`
`lib/src/types/union_type_mask.dart`

`lib/src/hash`
`lib/src/hash/sha1.dart`
