# Dart Dynamic Modules

## Quick Disclaimers

*Dart Dynamic Modules* is a work-in-progress and experimental. Like
any experimental Dart feature, that means it might change in
breaking ways and we are not yet committed to adopting it. Please be
aware of the risks if you consider using it beyond local
experiments.

At this time, we are prioritizing work for Dynamic Modules and Dart
Bytecodes that helps us improve specific developer journeys. We have
focused on collaborative sharing of prototypes, and mobile
development without JITing. We are not currently prioritizing work
related to other applications of Dynamic Modules in production
applications, like server-driven UI use-cases.

Regardless of the use case, this feature needs to be treated with
responsibility and care. Further
[below](##technical-details--considerations--faq) we share many
considerations, from security to policy, that you should be aware of
before proceeding.

## What are Dart Dynamic Modules?

Dart Dynamic Modules allows delivering code to an existing
application and loading it dynamically much like a dynamic import in
JavaScript or a dynamically linked library in C.

We'll dive into two parts in a bit more detail:

* **Semantics**: Until now Dart primarily supported statically
  compiled applications. This feature provides semantic reasoning
  for how to expand applications dynamically, mechanisms to declare
  these expansions, and validation needed to ensure these
  expansions don't break memory safety.

* **Technology**: How we implemented it for AOT applications by
  using Dart bytecodes to deliver dynamic modules.

Even though we don't have implementations for Dart web backends
today, we have explored prototypes enough to convince ourselves that
the semantics can be achieved using different technologies that fit
naturally with those backends as well.

## Semantics

Dart Dynamic Modules makes it possible to dynamically load a set of
Dart libraries in a running Dart application. It defines how those
libraries can interact with the rest of the application, and
provides utilities to facilitate their construction and correct
usage.

### Basic architecture: Leaving a closed-world behind

Historically, we have mostly treated Dart applications as a
monolith. Every time we build a Dart binary, we typically build the
entire application as a unit. Yes, there are some exceptions in
development scenarios where we support modular compilation, like DDC
on the web, but this whole-program approach is generally true across
our backends (dart2wasm, dart2js, AOT). Even features like deferred
loading that allow developers to split their binary into pieces to
lower latency during an initial load, operate with the whole program
first and only later they split the code into chunks.

Dart Dynamic Modules moves us away from this monolith concept. Now,
an application can be built and more modules can be defined,
compiled, and loaded after the fact. This represents architectural
change: the application now acts as a ***host*** that is extensible
through dynamic modules over time. The main semantic restriction:
all extensions are additive. Dynamic modules cannot replace an
existing declaration in the application, not even if that
declaration was delivered through a dynamic module earlier.

To extend an application, developers are required to define an API
surface area that establishes how dynamic modules will interact with
the rest of the host application. We call the declaration of this
surface area a ***Dynamic Interface***. With a surface area defined,
a host application is built as a single binary like before, but with
the caveat that the API surface area is now exposed. More libraries
can be compiled later on and loaded as dynamic modules, as long as
they are compatible with the API surface area defined by the host.

Quick recap on our terminology:

* **Host application**: the application that will load the dynamic
  module.
* **Dynamic interface**: a declaration of the API surface area
  exposed by a host application and made accessible to a dynamic
  module.
* **Dynamic module**: a set of Dart libraries and an entrypoint
  method, that are loaded dynamically.

### Typical steps to use dynamic modules

Let's dive into more details on how this architecture plays out. If
you are interested in how to use them directly and experiment with
them, skip ahead and look at our [example](#example).
Here we describe the conceptual steps that are needed when adopting
an application architecture that uses dynamic modules:

* Step 1: First, you will need to have a special build of Dart that
  supports dynamic modules. We don't ship this as part of the Dart
  or Flutter SDKs, so at this time this needs to be built from
  sources (we show how in the [example below](#example)).

* Step 2: You need to determine an API surface area. To do so, you
  usually start by imagining what logic will be loaded dynamically
  and how it will be integrated into your application. This helps
  you figure out the right contract between the application and the
  dynamic modules, when and how the application will load them, and
  identify which APIs need to be exposed. By default, nothing is
  exposed, not even APIs in `dart:core`, unless you opt into them.

* Step 3: Once you decide which APIs you want to expose from the
  host, you write a special `dynamic_interface.yaml` file that
  defines the dynamic interface (see
  [format specification][dynamic_interface.md]).
  This file is later used as an input to all compilation steps.

* Step 4: With a dynamic interface in hand, you can build the host
  application. There are three differences from how normal Dart
  applications are built:

  * First, the compiler and runtime are slightly different in order
    to include support for executing the dynamic modules. As we'll
    see later below, for AOT we decided to adopt Dart bytecodes and
    embed an interpreter in the runtime as the technology to execute
    dynamic modules in AOT.

  * Second, the application code is compiled differently by
    informing the compiler about the dynamic interface.
    Traditionally, Dart's AOT compiler performs closed-world
    optimizations assuming all code is known to the compiler,
    dynamic modules break that assumption so the compiler needs
    guidance to produce correct and sound applications. Usually this
    means less code is tree-shaken and fewer calls can be
    specialized because we don't know how exposed APIs will be used.

  * Third, the application code needs to embed some ***provenance***
    information that will be used later to validate the
    compatibility of what we load dynamically. This is important to
    guarantee correctness and memory safety and is a consequence of
    the technological choices we made for implementing dynamic
    modules. (Note: provenance is work in progress and not available
    yet in the current implementation of the package).

* Step 5: At this stage the application is ready to be delivered and
  run. The logic of what comes in a dynamic module can be defined
  later, even after the application is running.

* Step 6: Create and build a dynamic module. This involves writing a
  new set of Dart libraries with a special entrypoint. There is an
  important constraint, dynamic modules can only define new code. If
  they define libraries that already exist in the host application
  or in previous dynamic modules, the module is going to be rejected
  during the load. To deliver a dynamic module, we first compile it
  to a format compatible with the runtime where the application is
  running. In the case of AOT, we use a bytecode compiler to produce
  the dynamic module. As hinted above, bytecode compilation not only
  produces the bytecode that we will run, but also provenance
  attestations needed in the validation process.

* Step 7: Deliver the dynamic module to the app. Since dynamic
  modules are delivered dynamically, some effort is needed to set up
  the right way to deliver the dynamic module properly and securely.
  This often involves some form of transport-level security (TLS).

* Step 8: Validate and run the dynamic module. Before running the
  dynamic module — which mainly consists of invoking the designated
  entry point of the dynamic module and returning the result to the
  host application — we need assurances that the dynamic module
  won’t break the integrity of the application. Without validation,
  loading a dynamic module could break the application in unexpected
  ways (e.g. crashes, heap corruption, and more). Validation
  typically confirms compatibility of the dynamic module format and
  APIs in use. Depending on the technology, the verification may be
  done differently. Our implementation based on bytecodes relies on
  provenance checks to provide validation. Dynamic modules are
  allowed to load only if the same application code,
  dynamic-interface, and version of the SDK tools were used to build
  both the host app and the dynamic module.

That's the basic principle.

### Additional semantic details

This isn't a complete or formal spec, but here are some details to
expect about dynamic modules:

* It's a static error to tear off or invoke a member that is not
  exposed as "callable" in the dynamic interface. This rejection
  typically happens in Step 6 of our conceptual steps above.
* It's a static error to extend a class that was not exposed as
  "extendable" in the dynamic interface.
* It's a static error to override a member that was not exposed as
  "can-be-overridden" in the dynamic interface.
* It's a static error to use a class as a type that was not exposed
  as "callable" or "can-be-used-as-type" in the dynamic interface.
* All direct and interface calls are validated statically.
* Dynamic calls are generally discouraged because they can't be
  verified statically. They are, however, supported with special
  rules:
  * By default, compilers will reject the use of a dynamic call
    unless the selector name used in the dynamic call was previously
    allowed.

  * A selector name can be allowed if elements with the same name
    are exposed as "dynamically-callable" in the dynamic interface.
    This makes it possible to use dynamic calls that originate in
    dynamic modules but target a member in the host application.

  * A selector name can also be allowed through an allow-list flag
    of the dynamic module compiler. This makes it possible to use
    dynamic calls that originate from dynamic modules and target
    members declared also in dynamic modules.

  * Unlike all other parts of the API surface area, runtime checks
    are performed to enforce that the dynamic interface was
    respected. Runtime errors may be reported on dynamic calls that
    originate in the dynamic module if the target of the call was a
    member of the host application that was not exposed as
    "dynamically-callable".
* It's a runtime error to load a dynamic module with an incompatible
  format.
* It's a runtime error to load a dynamic module that attempts to
  define a library with an import-URI that already exists in the
  program, regardless of whether that import-URI was used for a
  library defined by the host application or a prior dynamic module.

## Technology: Bytecode-based Implementation in AOT

For each backend, there are many possible ways to bring dynamic
modules to life. DDC, for instance, is a modular compiler, so a
dynamic module can directly be implemented as a new module with very
little change to the compiler architecture. For AOT, we decided to
adopt an architecture that uses an interpreter.

The Dart bytecode [interpreter][interpreter.cc] exists in the Dart
VM codebase. It requires a tight integration with the runtime, which
makes it difficult to deliver separately from the Dart runtime
itself. At the same time, it has an implicit code-size cost on the
runtime that we don't want to include by default on all Dart
applications today. Because of these reasons, we don't ship it by
default as part of our SDK today. Instead, to use the dynamic
modules experiment, we require passing a build-time flag when
building Dart.

We also have a [dart2bytecode compiler][dart2bytecode], which we
use to compile dynamic modules to bytecode. In the future, we expect
the format to deliver dynamic modules will be expanded beyond
bytecode to allow embedding resources (e.g. icons, images,
provenance).

Finally, we are in the process of putting together tools to produce
provenance information. This includes information about how an app
and dynamic module were created, including versioning details about
the inputs and tools used in the process. This may be embedded from
the bytecode compiler or provided separately. We'll update this
README as we make progress on the implementation.

The libraries in `package:dynamic_modules` currently provide an API
to load bytecode directly. This will be updated in the near future
once we update the format and embed provenance information. Stay
tuned for changes.

## Example

The [`example/`](example/) directory contains a simple example that
illustrates the steps described above. The example is a simple
calculator command line interface that lets users extend it with new
operations beyond those built-in.

The example [README.md](example/README.md) contains details on how
to navigate it. Here, we'd like to highlight how the example
connects with some of the conceptual steps we described above.

The calculator consists of 3 parts:

* **An API surface area** exposes the interface used by dynamic
  modules to define new operations, as well as the API to register
  them. This corresponds to steps 2 and 3 above. See
  [`dynamic_interface.yaml`](example/dynamic_interface.yaml)
  and [`common/common.dart`](example/common/common.dart).

* **The host app** defines the main REPL (read–eval–print loop) and
  provides one built-in operation (math addition). This corresponds
  to step 4 above. See [`host/main.dart`](example/host/main.dart).

* **Dynamic modules** define new operations for the calculator
  following the API surface area defined by the host application.
  This corresponds to step 6 above. See the
  [`modules/`](example/modules/) subfolder.

Finally everything comes together in the [`run.sh`](example/run.sh)
script. This script shows:

* How to build Dart SDK artifacts with support for Dart Dynamic
  Modules (Step 1 above) by providing the `--dart-dynamic-modules`
  build-time flag.

* How to use the dynamic interface to build artifacts of steps 4 and
  6.

This example doesn't show how dynamic modules are delivered over the
network (step 7), instead bytecode files are copied over to a data
directory as an over simplistic way to represent the delivery
process.

## Progress/Status

Dynamic modules are designed so they can eventually be supported in
any Dart backend, however we have primarily focused on the AOT
implementation. All other backends are either unsupported or
incomplete.

What works?

* AOT compilation factors dynamic-interface to prevent tree-shaking
  and invalid optimizations and to perform runtime validation of
  dynamic calls.
* Modular validation of API usage against dynamic-interface.
* Integration of bytecode interpreter in the AOT runtime.
* Integration of bytecode interpreter in the JIT runtime.
* Required runtime checks in the AOT runtime needed to validate
  dynamic calls emanating from dynamic modules. For context, most
  validation of dynamic modules is done statically and modularly
  while compiling dynamic modules. However, the use of dynamic calls
  in dynamic modules require an additional whole-program static
  check and runtime checks.

What doesn't work yet?

* Bytecode provenance validation. There is work in progress, but the
  APIs have not been migrated over. This is a known upcoming
  breaking change to our APIs.
* Whole-program validation of dynamic modules. As mentioned earlier,
  dynamic calls also need a whole-program static check. This check
  is not implemented yet.
* Required runtime checks in the JIT runtime to validate dynamic
  calls. This is missing mainly because the JIT runtime doesn't load
  the dynamic-interface when running a host application from
  sources.
* Simple developer experience when authoring dynamic interfaces.
  Currently the `dynamic_interface.yaml` format has quirks
  especially around private members, which sometimes need to be
  exposed due to low-level implementation details of the language.
* Invoking FFI APIs from a dynamic module.

What is currently not planned?

* We are primarily focused on the AOT pipeline. We may improve
  support in JIT, but do not plan to focus on the web backends (DDC,
  dart2js, or dart2wasm) at this time. While this package includes
  tests that use an old DDC implementation based on DDC's JS module
  systems, that implementation was primarily created to validate the
  dynamic-modules concepts and ensure the semantics were flexible
  enough to support Dart backends other than AOT.

## Technical details, Considerations, FAQ

**Q: How are dynamic modules executed in AOT?**

The current implementation in AOT focuses entirely on using bytecode
to deliver dynamic modules and executing it using a bytecode
interpreter. That said, in general Dart Dynamic Modules as a concept
is agnostic of how code gets executed. We only define how code
extends an existing application and how it interacts with it. In
fact, prototypes we have built with DDC and dart2wasm leveraged
their own JS or wasm module systems to load new code.

**Q: Are dynamic modules fully sandboxed?**

No. Dynamic modules run in an interpreter, but you are loading code
into the same context of the application. Both the original host
application code and the dynamic modules run together as a single
program with a shared heap. Even though dynamic modules have
restricted APIs to refer to, there are no restrictions on what those
APIs can access indirectly.

You can create some lightweight isolation by loading dynamic modules
in a new Dart isolate. This separates the heap from the rest of the
host application, but won’t provide a full sandbox as it will still
be running in the same OS process as the app.

We think it is an interesting future direction to explore creating
trim-down versions of the Dart runtime that are fully sandboxed
(e.g. absolute no access to IO or FFI), though.

**Q: Is it OK to load untrusted/external/third-party code as a
dynamic module?**

No. As mentioned above, there is no sandbox. Anything you load with
a dynamic module requires a lot of trust. Just like it's not OK to
load untrusted third-party code without a sandbox in the same
context as your web application, it's not OK to do so in a Dart
application. Any code that is not developed by your team (external
contributions, unreviewed LLM generated code, etc) should be treated
as untrusted.

**Q: Why will the API change to require provenance information?**

We will require provenance information to validate compatibility
before a dynamic module is loaded and run in a host application.
Unlike other bytecode formats, like Java bytecodes, the Dart
bytecode format has no stable ABI and no mechanism to verify that
APIs used from the bytecode are compatible. As such, we need
additional mechanisms to prove compatibility and verify that a
dynamic module will behave as expected when loaded into a running
host application. Since compilation to bytecode already performs
most of the verification steps we need, we are designing the system
to plumb provenance information as a way to give the host
application the proof it needs to confirm everything is in order
before proceeding.

**Q: Why are Dart bytecodes and Dart dynamic modules being
developed?**

We are currently exploring improvements to the development story of
Dart and Flutter applications. Historically we relied heavily on JIT
compilation, but we were exploring using modular AOT compilation in
combination with Dart bytecodes to provide alternative development
workflows that can be supported in environments where JIT
compilation is not feasible. We discovered that the same technology
can be used for loading code dynamically, which led us to explore
new development use cases of the technology. One such use-case is to
share prototypes between team members at a low cost.

**Q: Can I use dynamic modules today in my Dart/Flutter app?**

We are in an early experimental stage of this feature, so we don't
recommend taking a dependency on it for projects used in production
today. You'll note that the feature is also not available by default
in Dart and Flutter SDKs, in part because just enabling it
introduces code-size bloat and performance effects that are
unnecessary for existing applications today.

We are prioritizing dynamic modules for development use cases, where
enabling dynamic modules at build time is an option and the
trade-offs are less of an issue.

**Q: Why are you only prioritizing development use cases?**

There are many considerations that need to be factored when
supporting a feature for production use cases. In the case of Dart
Dynamic Modules, the consideration list is long and requires a lot
of diligence, care, and effort, both from the SDK and from actual
developers adopting it. We decided to focus only on development use
cases that allow us to reduce the scope of these considerations.

Here are some of the top-of-mind factors for this technology:

* This feature can increase application size unnecessarily. The
  interpreter has a fixed cost, but there are additional effects on
  AOT binaries from disabling tree-shaking and optimizations related
  to the dynamic interface. If used naively, that extra size bloat
  can be substantial.

* If used improperly, this feature can introduce security risks.
  Dynamic modules are loaded in a trusted environment with no extra
  sandbox, so care needs to be in place to ensure bytecode has the
  right provenance and is delivered safely. Our work on requiring
  provenance is an effort to reduce this risk, but it doesn't
  eliminate all attack vectors.

* If used improperly, this feature can break applications or cause
  them to behave unexpectedly. For example, accidentally mixing
  bytecode compiled against a different version of the app can cause
  issues. Our work on provenance also helps reduce this risk by
  validating compatibility, but it doesn't reduce the complexity
  required to manage versioning in the first place.

* Proper version management involves non-trivial efforts, including
  creating server components and properly managing creation and
  storage of bytecode. We think a production-ready solution should
  have clear guidance and designs for how to address this challenge.

By focusing on the development use cases we found that some of these
considerations have a lower impact or lower complexity. For
instance, code-size is a lesser concern and we can focus on
single-version scenarios that ignore the more general versioning
questions. We still believe these considerations are important and
relevant, so we have used the development scenarios to help us make
progress on them (e.g. provenance support).

**Q: Is Dart Dynamic Modules a "code-push" implementation?**

No. Dart Dynamic Modules is a language runtime technology, similar
to that available in many other languages. It resembles C dynamic
linking, JavaScript dynamic imports, wasm module instantiations.

Code-push approaches are full-stack solutions that use multiple
technologies and services underneath to enable developers to send
over-the-air updates that patch existing applications. A general
code-push solution needs hosting services to track releases and
patches over time, mechanisms to make the application updatable
in-place, to determine what has changed between patches, to encode
updates in a deliverable format, to deliver and apply such updates,
and more.

We believe Dart Dynamic Modules is not an ideal technology for a
general-purpose codepush solution for a few reasons. First, the
additive semantics: dynamic modules can only introduce new
libraries, but can't update any existing declaration in an
application. Second, the API surface area: dynamic modules can only
invoke code that was previously exposed. In contrast, code-push
solutions want to update existing declarations and want patches to
be able to invoke anything already in the application. For a dynamic
module to be able to invoke anything in an application, we would
need to expose the entire app in the dynamic interface. That would
practically disable tree-shaking and all whole-program
optimizations, dramatically affecting the original application
performance and code-size to the point that we doubt it would be
suitable for use in production environments.

**Q: Are there security concerns behind dynamic modules?**

Yes. As hinted above in the earlier questions about how it works,
some top security considerations are that:

* A dynamic module loads in the same context as the host app,
  without an additional sandbox. Compared to the web, this is
  equivalent to appending `<script>` tags without using an
  iframe. As such, similar precautions are needed to use dynamic
  modules safely. This includes ensuring the code is trusted,
  preventing injection scenarios that would tamper the integrity of
  the bytecode. For example, you should never use dynamic modules to
  load code provided by others or provided by LLMs. Also, even if
  the source of the code is trusted, the delivery needs to be
  secured with proper TLS.

* Our bytecode doesn't have a stable ABI, so compatibility is only
  guaranteed if the bytecode loaded matches the format supported by
  the host app. A skew in the ABI can cause memory corruption or
  other semantic errors and lead the application to misbehave.

* Similarly, incompatible APIs can also lead to the same result.

Our work to provide provenance validation is designed to help
validate ABI and API compatibility before a load is allowed. Unlike
Java bytecodes, Dart bytecodes don't offer verification that the
APIs in the bytecode match the APIs in the host app, so we resort to
provenance as an alternative technique. Just like the web,
provenance alone does not guarantee the safety of the code being
loaded. Special diligence is required by developers to ensure that
only code that is trusted and delivered securely is ever loaded in
the context of the application.

**Q: Are there store policy considerations to consider when using
dynamic modules?**

Yes, there are policy considerations, regardless of how code is run.
For example, you might want to validate that any store you are
publishing to allows running interpreted code in a custom
interpreter. And stores might have policies around how much an app
is allowed to change after it has been installed by the user.

[interpreter.cc]: https://github.com/dart-lang/sdk/blob/898a1e4bbfbc472dc0a9505dc7d2e4c21d6f856e/runtime/vm/interpreter.cc
[dart2bytecode]: https://github.com/dart-lang/sdk/blob/898a1e4bbfbc472dc0a9505dc7d2e4c21d6f856e/pkg/dart2bytecode/
[dynamic_interface.md]: https://github.com/dart-lang/sdk/blob/898a1e4bbfbc472dc0a9505dc7d2e4c21d6f856e/pkg/vm/dynamic_interface.md
