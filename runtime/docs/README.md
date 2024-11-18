# Introduction to Dart VM

> **Warning**
>
> This document is work in progress. Please contact [Vyacheslav Egorov](vegorov@google.com) if you have any questions, suggestions, bug reports. **Last update: Oct 6 2022**

[TOC]

This document is intended as a reference for new members of the Dart VM team, potential external contributors or just anybody interested in VM internals. It starts with a high-level overview of the Dart VM and then proceeds to describe various components of the VM in more details.

Dart VM is a collection of components for executing Dart code natively. Notably it includes the following:

* Runtime System
    * Object Model
    * Garbage Collection
    * Snapshots
* Core libraries native methods
* Development Experience components accessible via *service protocol*
    * Debugging
    * Profiling
    * Hot-reload
* Just-in-Time (JIT) and Ahead-of-Time (AOT) compilation pipelines
* Interpreter
* ARM simulators

The name "Dart VM" is historical. Dart VM is a virtual machine in a sense that it provides an execution environment for a high-level programming language, however it does not imply that Dart is always interpreted or JIT-compiled, when executing on Dart VM. For example, Dart code can be compiled into machine code using Dart VM AOT pipeline and then executed within a stripped version of the Dart VM, called *precompiled runtime*, which does not contain any compiler components and is incapable of loading Dart source code dynamically.

## How does Dart VM run your code?

Dart VM has multiple ways to execute the code, for example:

* from source or Kernel binary using JIT;
* from snapshots:
    * from AOT snapshot;
    * from AppJIT snapshot.

However the main difference between these lies in when and how VM converts Dart source code to executable code. The runtime environment that facilitates the execution remains the same.

```
                                     pseudo isolate for
                                     shared immutable objects
                                     like null, true, false.
                                     ┌────────────┐
                                     │ VM Isolate │       heaps can reference
                                     │ ╭────────╮ │       vm-isolate heap.
                            ┏━━━━━━━━━▶│ Heap   │◀━━━━━━━━━━━━━━━━┓
                            ┃        │ ╰────────╯ │               ┃
                            ┃        └────────────┘               ┃
                            ┃                                     ┃
  ┌─────────────────────────┃────────┐            ┌───────────────┃──────────────────┐
  │ IsolateGroup            ┃        │            │ IsolateGroup  ┃                  │
  │                         ┃        │            │               ┃                  │
  │ ╭───────────────────────┃──────╮ │            │ ╭─────────────┃────────────────╮ │
  │ │ GC managed Heap              ┅┅┅┅┅┅┅┅╳┅┅┅┅┅┅┅▶│ GC managed Heap              │ │
  │ ╰──────────────────────────────╯ │ no cross   │ ╰──────────────────────────────╯ │
  │  ┌─────────┐     ┌─────────┐     │ group      │  ┌─────────┐     ┌─────────┐     │
  │  │┌─────────┐    │┌─────────┐    │ references │  │┌─────────┐    │┌─────────┐    │
  │  ││┌─────────┐   ││┌─────────┐   │            │  ││┌─────────┐   ││┌─────────┐   │
  │  │││Isolate  │   │││         │   │            │  │││Isolate  │   │││         │   │
  │  │││         │   │││         │   │            │  │││         │   │││         │   │
  │  │││ globals │   │││ helper  │   │            │  │││ globals │   │││ helper  │   │
  │  │││         │   │││ thread  │   │            │  │││         │   │││ thread  │   │
  │  └││ mutator │   └││         │   │            │  └││ mutator │   └││         │   │
  │   └│ thread  │    └│         │   │            │   └│ thread  │    └│         │   │
  │    └─────────┘     └─────────┘   │            │    └─────────┘     └─────────┘   │
  └──────────────────────────────────┘            └──────────────────────────────────┘
```

Any Dart code within the VM is running within some _isolate_, which can be best described as an isolated Dart universe with its own global state and _usually_ with its own thread of control (*mutator thread*). Isolates are grouped together into _isolate groups_. Isolate within the group share the same garbage collector managed *heap*, used as a storage for objects allocated by an isolate. Heap sharing between isolates in the same group is an implementation detail which is not observable from the Dart code. Even isolates within the same group can not share any mutable state directly and can only communicate by message passing through *ports* (not to be confused with network ports!).

Isolates within a group share the same Dart program. [`Isolate.spawn`](https://api.dart.dev/stable/dart-isolate/Isolate/spawn.html) spawns an isolate within the same group, while [`Isolate.spawnUri`](https://api.dart.dev/stable/dart-isolate/Isolate/spawnUri.html) starts a new group.

The relationship between OS threads and isolates is a bit blurry and highly dependent on how VM is embedded into an application. Only the following is guaranteed:

* an OS thread can *enter* only one isolate at a time. It has to leave current isolate if it wants to enter another isolate;
* there can only be a single *mutator* thread associated with an isolate at a time. Mutator thread is a thread that executes Dart code and uses VM's public C API.

However the same OS thread can first enter one isolate, execute Dart code, then leave this isolate and enter another isolate. Alternatively many different OS threads can enter an isolate and execute Dart code inside it, just not simultaneously.

In addition to a single *mutator* thread an isolate can also be associated with multiple helper threads, for example:

* a background JIT compiler thread;
* GC sweeper threads;
* concurrent GC marker threads.

Internally VM uses a thread pool [`dart::ThreadPool`][] to manage OS threads and the code is structured around [`dart::ThreadPool::Task`][] concept rather than around a concept of an OS thread. For example, instead of spawning a dedicated thread to perform background sweeping after a GC VM posts a [`dart::ConcurrentSweeperTask`][] to the global VM thread pool and thread pool implementation either selects an idling thread or spawns a new thread if no threads are available. Similarly the default implementation of an event loop for isolate message processing does not actually spawn a dedicated event loop thread, instead it posts a [`dart::MessageHandlerTask`][] to the thread pool whenever a new message arrives.

> **Source to read**
>
> Class [`dart::Isolate`][] represents an isolate, [`dart::IsolateGroup`][] an isolate group and class [`dart::Heap`][] - isolate group's heap. Class [`dart::Thread`][] describes the state associated with a thread attached to an isolate. Note that the name `Thread` is somewhat confusing because all OS threads attached to the same isolate as a mutator will reuse the same `Thread` instance. See [`Dart_RunLoop`][] and [`dart::MessageHandler`][] for the default implementation of an isolate's message handling.

### Running from source via JIT.

This section tries to cover what happens when you try to execute Dart from the command line:

```dart
// hello.dart
main() => print('Hello, World!');
```

```console
$ dart hello.dart
Hello, World!
```

Since Dart 2 VM no longer has the ability to directly execute Dart from raw source, instead VM expects to be given _Kernel binaries_ (also called _dill files_) which contain serialized [Kernel ASTs][`pkg/kernel/README.md`]. The task of translating Dart source into Kernel AST is handled by the [common front-end (CFE)][`pkg/front_end`] written in Dart and shared between different Dart tools (e.g. VM, dart2js, Dart Dev Compiler).

```
 ╭─────────────╮                       ╭────────────╮
 │╭─────────────╮       ╔═════╗        │╭────────────╮        ╔════╗
 ││╭─────────────╮┣━━━▶ ║ CFE ║ ┣━━━▶  ││╭────────────╮ ┣━━━▶ ║ VM ║
 ┆││ Dart Source │      ╚═════╝        │││ Kernel AST │       ╚════╝
 ┆┆│             │                     ╰││ (binary)   │
  ┆┆             ┆                      ╰│            │
   ┆             ┆                       ╰────────────╯
```

To preserve convenience of executing Dart directly from source standalone `dart` executable hosts a helper isolate called *kernel service*, which handles compilation of Dart source into Kernel. VM then will run resulting Kernel binary.

```
                    ┌───────────────────────────────────────────────────┐
                    │ dart (cli)                                        │
                    │  ┌─────────┐                          ┌─────────┐ │
 ╭─────────────╮    │  │ kernel  │     ╭────────────╮       │ main    │ │
 │╭─────────────╮   │  │ service │     │╭────────────╮      │ isolate │ │
 ││╭─────────────╮┣━━━▶│ isolate │┣━━━▶││╭────────────╮┣━━━▶│         │ │
 ┆││ Dart Source │  │  │         │     │││ Kernel AST │     │         │ │
 ┆┆│             │  │  │╔══════╗ │     ╰││ (binary)   │     │         │ │
  ┆┆             ┆  │  │║ CFE  ║ │      ╰│            │     │         │ │
   ┆             ┆  │  │╚══════╝ │       ╰────────────╯     │         │ │
                    │  │         │══════════════════════════│         │ │
                    │  └─────────┘           VM             └─────────┘ │
                    │         ╚═════════════════════════════════╝       │
                    └───────────────────────────────────────────────────┘
```


However this setup is not the only way to arrange CFE and VM to run Dart code. For example, Flutter completely separates _compilation to Kernel_ and _execution from Kernel_ by putting them onto different devices: compilation happens on the developer machine (_host_) and execution is handled on the target mobile _device_, which receives Kernel binaries send to it by `flutter` tool.

```
                                             HOST ┆ DEVICE
                                                  ┆
                         ┌──────────────────────┐ ┆ ┌────────────────┐
 ╭─────────────╮         │frontend_server (CFE) │ ┆ │ Flutter Engine │
 │╭─────────────╮      ┌──────────────────────┐ │ ┆ │ ╔════════════╗ │
 ││╭─────────────╮┣━━━▶│flutter run --debug   │ │ ┆ │ ║     VM     ║ │
 ┆││ Dart Source │     │                      │─┘ ┆ │ ╚════════════╝ │
 ┆┆│             │     │                      │   ┆ └────────────────┘
  ┆┆             ┆     └──────────────────────┘   ┆            ▲
   ┆             ┆               ┳                ┆            ┃
                                 ┃                ┆            ┃
                                 ┃         ╭────────────╮      ┃
                                 ┃         │╭────────────╮     ┃
                                 ┃         ││╭────────────╮    ┃
                                 ┗━━━━━━━━▶│││ Kernel AST │┣━━━┛
                                           ╰││ (binary)   │
                                            ╰│            │
                                             ╰────────────╯
```

Note that `flutter` tool does not handle parsing of Dart itself - instead it spawns another persistent process `frontend_server`, which is essentially a thin wrapper around CFE and some Flutter specific Kernel-to-Kernel transformations. `frontend_server` compiles Dart source into Kernel files, which `flutter` tool then sends to the device. Persistence of the `frontend_server` process comes into play when developer requests _hot reload_: in this case `frontend_server` can reuse CFE state from the previous compilation and recompile just libraries which actually changed.

Once Kernel binary is loaded into the VM it is parsed to create objects representing various program entities. However this is done lazily: at first only basic information about libraries and classes is loaded. Each entity originating from a Kernel binary keeps a pointer back to the binary, so that later more information can be loaded as needed.

> **Note**
>
> Definitions of internal VM objects, like those representing classes and functions, are split into two parts: class `Xyz` in the header [`runtime/vm/object.h`][] defines C++ methods, while class `UntaggedXyz` in the header [`runtime/vm/raw_object.h`][] defines memory layout. For example, [`dart::Class`][] and [`dart::UntaggedClass`][] specify a VM object describing Dart class, [`dart::Field`][] and [`dart::UntaggedField`][] specify a VM object describing a Dart field within a Dart class and so on. We will return to this in a section covering runtime system and object model. We omit `Untagged...` prefix from illustrations to make them more compact.

```
             KERNEL AST BINARY    ┆ ISOLATE GROUP HEAP
                                  ┆
              ╭─────────────────╮ ┆   ┌───────┐
              │                 │ ┆ ┏━┥ Class │
              ├─────────────────┤ ┆ ┃ └───────┘╲ heap objects
 AST node     │(Class           │◀━━┛            representing
 representing │ (Field)         │ ┆   ┌───────┐╱ a class
 a class      │ (Procedure      │ ┆ ┏━┥ Class │
              │  (FunctionNode))│ ┆ ┃ └───────┘
              │ (Procedure      │ ┆ ┃
              │  (FunctionNode))│ ┆ ┃╲
              ├─────────────────┤ ┆ ┃ ╲ heap objects representing
              │(Class           │◀━━┛   program entities keep
              │ (Field)         │ ┆     pointers back into kernel
              │ (Field)         │ ┆     binary blob and are
              │ (Procedure      │ ┆     deserialized lazily
              │  (FunctionNode))│ ┆
              ├─────────────────┤ ┆
                                  ┆
```

Information about the class is fully deserialized only when runtime later needs it (e.g. to lookup a class member, to allocate an instance, etc). At this stage class members are read from the Kernel binary. However full function bodies are not deserialized at this stage, only their signatures.

```
             KERNEL AST BINARY    ┆ ISOLATE GROUP HEAP
                                  ┆
              ╭─────────────────╮ ┆   ┌───────┐
              │                 │ ┆ ┏━┥ Class ┝━━━━━━━┓
              ├─────────────────┤ ┆ ┃ └───────┘       ┃
              │(Class           │◀━━┛   ┌──────────┐  ┃
              │ (Field)         │◀━━━━━━┥ Field    │◀━┫
              │ (Procedure      │◀━━━━┓ └──────────┘  ┃
              │  (FunctionNode))│ ┆   ┃ ┌──────────┐  ┃
              │ (Procedure      │◀━━━┓┗━┥ Function │◀━┫
              │  (FunctionNode))│ ┆  ┃  └──────────┘  ┃
              ├─────────────────┤ ┆  ┃  ┌──────────┐  ┃
              │(Class           │ ┆  ┗━━┥ Function │◀━┛
              │ (Field)         │ ┆     └──────────┘
              │ (Field)         │ ┆
              │ (Procedure      │ ┆
              │  (FunctionNode))│ ┆
              ├─────────────────┤ ┆
                                  ┆
```

At this point enough information is loaded from Kernel binary for runtime to successfully resolve and invoke methods. For example, it could resolve and invoke `main` function from a library.

> **Source to read**
>
> [`package:kernel/ast.dart`][] defines classes describing the Kernel AST. [`package:front_end`][] handles parsing Dart source and building Kernel AST from it. [`dart::kernel::KernelLoader::LoadEntireProgram`][] is an entry point for deserialization of Kernel AST into corresponding VM objects. [`pkg/vm/bin/kernel_service.dart`][] implements the Kernel Service isolate, [`runtime/vm/kernel_isolate.cc`][] glues Dart implementation to the rest of the VM. [`package:vm`][] hosts most of the Kernel based VM specific functionality, e.g various Kernel-to-Kernel transformations.


> **Trying it**
>
> If you are interested in Kernel format and its VM specific usage, then you can use [`pkg/vm/bin/gen_kernel.dart`][] to produce a Kernel binary file from Dart source. Resulting binary can then be dumped using [`pkg/vm/bin/dump_kernel.dart`][].
>
> * Compile `hello.dart` to `hello.dill` Kernel binary using CFE
>     ```console
>     $ dart pkg/vm/bin/gen_kernel.dart                        \
>            --platform out/ReleaseX64/vm_platform_strong.dill \
>            -o hello.dill                                     \
>            hello.dart
>     ```
> * Dump textual representation of Kernel AST.
>     ```console
>     $ dart pkg/vm/bin/dump_kernel.dart hello.dill hello.kernel.txt
>     ```
>
> When you try using `gen_kernel.dart` you will notice that it requires something called *platform*, a Kernel binary containing AST for all core libraries (`dart:core`, `dart:async`, etc). If you have Dart SDK build configured then you can just use platform file from the `out` directory, e.g. `out/ReleaseX64/vm_platform_strong.dill`. Alternatively you can use [`pkg/front_end/tool/compile_platform.dart`][] to generate the platform:
>
> ```console
> $ dart pkg/front_end/tool/compile_platform.dart \
>        dart:core                                       \
>        sdk/lib/libraries.json                          \
>        vm_outline.dill vm_platform.dill vm_outline.dill
> ```

Initially all functions have a placeholder instead of an actually executable code for their bodies: they point to `LazyCompileStub`, which simply asks runtime system to generate executable code for the current function and then tail-calls this newly generated code.

```
┌──────────┐
│ Function │
│          │     LazyCompileStub
│  code_ ━━━━━━▶ ┌─────────────────────────────┐
│          │     │ code = CompileFunction(...) │
└──────────┘     │ return code(...);           │
                 └─────────────────────────────┘
```

When the function is compiled for the first time this is done by *unoptimizing compiler*.

```
 Kernel AST            Unoptimized IL            Machine Code
╭──────────────╮      ╭──────────────────╮      ╭─────────────────────╮
│ FunctionNode │      │ LoadLocal('a')   │      │ push [rbp + ...]    │
│              │      │ LoadLocal('b')   │      │ push [rbp + ...]    │
│ (a, b) =>    │ ┣━━▶ │ InstanceCall('+')│ ┣━━▶ │ call InlineCacheStub│
│   a + b;     │      │ Return           │      │ retq                │
╰──────────────╯      ╰──────────────────╯      ╰─────────────────────╯
```

Unoptimizing compiler produces machine code in two passes:

1. Serialized AST for the function's body is walked to generate a *control flow graph* (**CFG**) for the function body. CFG consists of basic blocks filled with *intermediate language* (**IL**) instructions. IL instructions used at this stage resemble instructions of a stack based virtual machine: they take operands from the stack, perform operations and then push results to the same stack.

> **Note**
>
> In reality not all functions have actual Dart / Kernel AST bodies, e.g. *natives* defined in C++ or artificial tear-off functions generated by Dart VM - in these cases IL is just created from the thin air, instead of being generated from Kernel AST.

2. resulting CFG is directly compiled to machine code using one-to-many lowering of IL instructions: each IL instruction expands to multiple machine language instructions.

There are no optimizations performed at this stage. The main goal of unoptimizing compiler is to produce executable code quickly.

This also means that unoptimizing compiler does not attempt to statically resolve any calls that were not resolved in Kernel binary, so calls (`MethodInvocation` or `PropertyGet` AST nodes) are compiled as if they were completely dynamic. VM currently does not use any form of *virtual table* or *interface table* based dispatch and instead implements dynamic calls using [*inline caching*](https://en.wikipedia.org/wiki/Inline_caching).

The core idea behind inline caching is to cache results of method resolution in a call site specific cache. Inline caching mechanism used by the VM consists of:

> **Note**
>
> Original implementations of inline caching were actually patching the native code of the function - hence the name  _**inline** caching_. The idea of inline caching dates far back to Smalltalk-80, see [Efficient implementation of the Smalltalk-80 system](https://dl.acm.org/citation.cfm?id=800542).

* a call site specific cache ([`dart::UntaggedICData`][] object) that maps receiver's class to a method, that should be invoked if receiver is of a matching class. The cache also stores some auxiliary information, e.g. invocation frequency counters, which track how often the given class was seen at this call site;
* a shared lookup stub, which implements method invocation fast path. This stub searches through the given cache to see if it contains an entry that matches receiver's class. If the entry is found then stub increments the frequency counter and tail call cached method. Otherwise stub invokes a runtime system helper which implements method resolution logic. If method resolution succeeds then cache is updated and subsequent invocations will not need to enter runtime system.

The picture below illustrates the structure and the state of an inline cache associated with `animal.toFace()` call site, which was executed twice with an instance of `Dog` and once with an instance of a `Cat`.

```
class Dog {
  get face => '🐶';
}

class Cat {
  get face => '🐱';
}                                 ICData
                                  ┌─────────────────────────────────────┐
sameFace(animal, face) ┌─────────▶│// class, method, frequency          │
  animal.face == face; │          │[Dog, Dog.get:face, 2,               │
        ┬              │          │ Cat, Cat.get:face, 1]               │
        └──────────────┤          └─────────────────────────────────────┘
sameFace(Dog(), ...);  │          InlineCacheStub
sameFace(Dog(), ...);  │          ┌─────────────────────────────────────┐
sameFace(Cat(), ...);  └─────────▶│ idx = cache.indexOf(classOf(this)); │
                                  │ if (idx != -1) {                    │
                                  │   cache[idx + 2]++;  // frequency++ │
                                  │   return cache[idx + 1](...);       │
                                  │ }                                   │
                                  │ return InlineCacheMiss(...);        │
                                  └─────────────────────────────────────┘
```

Unoptimizing compiler by itself is enough to execute any possible Dart code. However the code it produces is rather slow, which is why VM also implements *adaptive optimizing* compilation pipeline. The idea behind adaptive optimization is to use execution profile of a running program to drive optimization decisions.

As unoptimized code is running it collects the following information:

* As described above, inline caches collect information about receiver types observed at
callsites;
* Execution counters associated with functions and basic blocks within functions track hot regions of the code.

When an execution counter associated with a function reaches certain threshold, this function is submitted to a *background optimizing compiler* for optimization.

Optimizing compilations starts in the same way as unoptimizing compilation does: by walking serialized Kernel AST to build unoptimized IL for the function that is being optimized. However instead of directly lowering that IL into machine code, optimizing compiler proceeds to translate unoptimized IL into *static single assignment* (SSA) form based optimized IL. SSA based IL is then subjected to speculative specialization based on the collected type feedback and passed through a sequence of classical and Dart specific optimizations: e.g. inlining, range analysis, type propagation, representation selection, store-to-load and load-to-load forwarding, global value numbering, allocation sinking, etc. At the end optimized IL is lowered into machine code using linear scan register allocator and a simple one-to-many lowering of IL instructions.

Once compilation is complete background compiler requests mutator thread to enter a *safepoint* and attaches optimized code to the function.

> **Note**
>
> Broadly speaking a thread in a managed environment (virtual machine) is considered to be at a *safepoint* when the state associated with it (e.g. stack frames, heap, etc) is consistent and can be accessed or modified without interruption from the thread itself. Usually this implies that the thread is either paused or is executing some code outside of the managed environment e.g. running unmanaged native code. See [GC](/gc.html) page for more information.

The next time this function is called - it will use optimized code. Some functions contain very long running loops and for those it makes sense to switch execution from unoptimized to optimized code while the function is still running. This process is called *on stack replacement* (**OSR**) owing its name to the fact that a stack frame for one version of the function is transparently replaced with a stack frame for another version of the same function.

```
                                                        in hot code ICs
 Kernel AST            Unoptimized IL                   have collected type
╭──────────────╮      ╭───────────────────────╮         ╱ feedback
│ FunctionNode │      │ LoadLocal('a')        │   ICData
│              │      │ LoadLocal('b')      ┌────▶┌─────────────────────┐
│ (a, b) =>    │ ┣━━▶ │ InstanceCall:1('+', ┴)│   │[(Smi, Smi.+, 10000)]│
│   a + b;     │      │ Return      ╱         │   └─────────────────────┘
╰──────────────╯      ╰────────────╱──────────╯
                              deopt id  ┳
                                        ┃
                               SSA IL   ▼
                              ╭────────────────────────────────╮
                              │ v1<-Parameter('a')             │
                              │ v2<-Parameter('b')             │
                              │ v3<-InstanceCall:1('+', v1, v2)│
                              │ Return(v3)                     │
                              ╰────────────────────────────────╯
                                        ┳
                                        ┃
   Machine Code                         ▼    Optimized SSA IL
  ╭─────────────────────╮     ╭──────────────────────────────╮
  │ movq rax, [rbp+...] │     │ v1<-Parameter('a')           │
  │ testq rax, 1        │ ◀━━┫│ v2<-Parameter('b')           │
  │ jnz ->deopt@1       │     │ CheckSmi:1(v1)               │
  │ movq rbx, [rbp+...] │     │ CheckSmi:1(v2)               │
  │ testq rbx, 1        │     │ v3<-BinarySmiOp:1(+, v1, v2) │
  │ jnz ->deopt@1       │     │ Return(v3)                   │
  │ addq rax, rbx       │     ╰──────────────────────────────╯
  │ jo ->deopt@1        │
  │ retq                │
  ╰─────────────────────╯
```

> **Source to read**
>
> Compiler sources are in the [`runtime/vm/compiler`][] directory.
> Compilation pipeline entry point is [`dart::CompileParsedFunctionHelper::Compile`][]. IL is defined in [`runtime/vm/compiler/backend/il.h`][]. Kernel-to-IL translation starts in [`dart::kernel::StreamingFlowGraphBuilder::BuildGraph`][], and this function also handles construction of IL for various artificial functions. [`dart::compiler::StubCodeCompiler::GenerateNArgsCheckInlineCacheStub`][] generates machine code for inline-cache stub, while [`dart::InlineCacheMissHandler`][] handles IC misses. [`runtime/vm/compiler/compiler_pass.cc`][] defines optimizing compiler passes and their order. [`dart::JitCallSpecializer`][] does most of the type-feedback based specializations.

> **Trying it**
>
> VM also has flags which can be used to control JIT and to make it dump IL and generated machine code for the functions that are being compiled by the JIT.
>
> | Flag | Description |
> | ---- | ---- |
> | `--print-flow-graph[-optimized]` | Print IL for all (or only optimized) compilations |
> | `--disassemble[-optimized]` | Disassemble all (or only optimized) compiled functions |
> | `--print-flow-graph-filter=xyz,abc,...` | Restrict output triggered by previous flags only to the functions which contain one of the comma separated substrings in their names |
> | `--compiler-passes=...` | Fine control over compiler passes: force IL to be printed before/after a certain pass. Disable passes by name. Pass `help` for more information |
> | `--no-background-compilation` | Disable background compilation, and compile all hot functions on the main thread. Useful for experimentation, otherwise short running programs might finish before background compiler compiles hot function |
> | `--deterministic` | Disable various sources of non-determinism in the VM (concurrent GC and compiler).  |
>
> For example the following command will run `test.dart` and dump optimized IL and machine code for functions that contain `myFunction` in their names:
>
> ```console
> $ dart --print-flow-graph-optimized         \
>        --disassemble-optimized              \
>        --print-flow-graph-filter=myFunction \
>        --no-background-compilation          \
>        test.dart
> ```

It is important to highlight that the code generated by optimizing compiler is specialized under speculative assumptions based on the execution profile of the application. For example, a dynamic call site that only observed instances of a single class `C` as a receiver will be converted into a direct call preceded by a check verifying that receiver has an expected class `C`. However these assumptions might be violated later during execution of the program:

```dart
void printAnimal(obj) {
  print('Animal {');
  print('  ${obj.toString()}');
  print('}');
}

// Call printAnimal(...) a lot of times with an instance of Cat.
// As a result printAnimal(...) will be optimized under the
// assumption that obj is always a Cat.
for (var i = 0; i < 50000; i++)
  printAnimal(Cat());

// Now call printAnimal(...) with a Dog - optimized version
// can not handle such an object, because it was
// compiled under assumption that obj is always a Cat.
// This leads to deoptimization.
printAnimal(Dog());
```

Whenever optimized code is making some optimistic assumptions, which might be
violated during the execution, it needs to guard against such violations and
be able to recover if they occur.

This process of recovery is known as _deoptimization_: whenever optimized version hits a case which it can't handle, it simply transfers execution into the matching point of unoptimized function and continues execution there. Unoptimized version of a function does not make any assumptions and can handle all possible inputs.


> **Note**
>
> Entering unoptimized function at the right spot is absolutely crucial because code has side-effects (e.g. in the function above deoptimization happens after we already executed the first `print`). Matching instructions that deoptimize to positions in the unoptimized code in VM is done using *deopt ids*

VM usually discards optimized version of the function after deoptimization and
then reoptimizes it again later - using updated type feedback.

There are two ways VM guards speculative assumptions made by the compiler:

* Inline checks (e.g. `CheckSmi`, `CheckClass` IL instructions) that verify if assumption holds at *use* site where compiler made this assumption. For example, when turning dynamic calls into direct calls compiler adds these checks right before a direct call. Deoptimization that happens on such checks is called *eager deoptimization*, because it occurs eagerly as the check is reached.
* Global guards which instruct runtime to discard optimized code when it changes something that optimized code relies on. For example, optimizing compiler might observe that some class `C` is never extended and use this information during type propagation pass. However subsequent dynamic code loading or class finalization can introduce a subclass of `C` - which invalidates the assumption. At this point runtime needs to find and discard all optimized code that was compiled under the assumption that `C` has no subclasses. It is possible that runtime finds some of the now invalid optimized code on the execution stack - in which case affected frames are marked for deoptimization and will deoptimize when execution returns to them.  This sort of deoptimization is called *lazy deoptimization*: because it is delayed until control returns back to the optimized code.

> **Source to read**
>
> Deoptimizer machinery resides in [`runtime/vm/deopt_instructions.cc`][]. It is essentially a mini-interpreter for *deoptimization instructions* which describe how to reconstruct needed state of the unoptimized code from the state of optimized code. Deoptimization instructions are generated by [`dart::CompilerDeoptInfo::CreateDeoptInfo`][] for every potential deoptimization location in optimized code during compilation.

> **Trying it**
>
> Flag `--trace-deoptimization` makes VM print information about the cause and location of every deoptimization that occurs. `--trace-deoptimization-verbose` makes VM print a line for every deoptimization instruction it executes during deoptimization.

### Running from Snapshots

VM has the ability to serialize isolate's heap or more precisely object graph residing in the heap into a binary *snapshot*. Snapshot then can be used to recreate the same state when starting VM isolates.

```
                                                   ┌──────────────┐
                            SNAPSHOT              ┌──────────────┐│
┌──────────────┐           ╭─────────╮           ┌──────────────┐││
│ HEAP         │           │ 0101110 │           │ HEAP         │││
│     ██       │           │ 1011010 │           │     ██       │││
│    ╱  ╲      │           │ 1010110 │           │    ╱  ╲      │││
│  ██╲   ██    │           │ 1101010 │           │  ██╲   ██    │││
│     ╲ ╱  ╲   │┣━━━━━━━━━▶│ 0010101 │┣━━━━━━━━━▶│     ╲ ╱  ╲   │││
│      ╳   ██  │ serialize │ 0101011 │deserialize│      ╳   ██  │││
│     ╱ ╲  ╱   │           │ 1111010 │           │     ╱ ╲  ╱   │││
│   ██   ██    │           │ 0010110 │           │   ██   ██    ││┘
│              │           │ 0001011 │           │              │┘
└──────────────┘           ╰─────────╯           └──────────────┘

```

Snapshot's format is low level and optimized for fast startup - it is essentially a list of objects to create and instructions on how to connect them together. That was the original idea behind snapshots: instead of parsing Dart source and gradually creating internal VM data structures, VM can just spin an isolate up with all necessary data structures quickly unpacked from the snapshot.

> **Note**
>
> The idea of a snapshots has roots in Smalltalk [images](https://en.wikipedia.org/wiki/Smalltalk#Image-based_persistence) which were in turn inspired by [Alan Kay's M.Sc thesis](https://www.mprove.de/visionreality/media/kay68.html). Dart VM is using clustered serialization format which is similar to techniques described in [Parcels: a Fast and Feature-Rich Binary Deployment Technology](http://scg.unibe.ch/archive/papers/Mira05aParcels.pdf) and [Clustered serialization with Fuel](https://rmod.inria.fr/archives/workshops/Dia11a-IWST11-Fuel.pdf) papers.

Initially snapshots did not include machine code, however this capability was later added when AOT compiler was developed. Motivation for developing AOT compiler and snapshots-with-code was to allow VM to be used on the platforms where JITing is impossible due to platform level restrictions.

Snapshots-with-code work almost in the same way as normal snapshots with a minor difference: they include a code section which unlike the rest of the snapshot does not require deserialization. This code section laid in way that allows it to directly become part of the heap after it was mapped into memory.

```
                                                    ┌──────────────┐
                            SNAPSHOT               ┌──────────────┐│
┌──────────────┐           ╭────╮╭────╮           ┌──────────────┐││
│ HEAP         │           │ 01 ││    │           │ HEAP         │││
│     ██       │           │ 10 ││ ░░◀──┐         │     ██       │││
│    ╱  ╲      │           │ 10 ││    │ │         │    ╱  ╲      │││
│  ██╲   ██    │           │ 11 ││    │ └────────────██╲   ██    │││
│  ╱  ╲ ╱  ╲   │┣━━━━━━━━━▶│ 00 ││    │┣━━━━━━━━━▶│     ╲ ╱  ╲   │││
│ ░░   ╳   ██  │ serialize │ 01 ││    │deserialize│      ╳   ██  │││
│     ╱ ╲  ╱   │           │ 11 ││    │           │     ╱ ╲  ╱   │││
│   ██   ██╲   │           │ 00 ││    │           │   ██   ██    ││┘
│           ░░ │           │ 00 ││ ░░◀──────────────────────┘    │┘
└──────────╱───┘           ╰────╯╰────╯           └──────────────┘
         code               data  code
```


> **Source to read**
>
> [`runtime/vm/app_snapshot.cc`][] handles serialization and deserialization of snapshots. A family of API functions `Dart_CreateXyzSnapshot[AsAssembly]` are responsible for writing out snapshots of the heap (e.g. [`Dart_CreateAppJITSnapshotAsBlobs`][] and [`Dart_CreateAppAOTSnapshotAsAssembly`][]). On the other hand [`Dart_CreateIsolateGroup`][] optionally takes snapshot data to start an isolate from.

### Running from AppJIT snapshots

AppJIT snapshots were introduced to reduce JIT warm up time for large Dart applications like `dartanalyzer` or `dart2js`. When these tools are used on small projects they spent as much time doing actual work as VM spends JIT compiling these apps.

AppJIT snapshots allow to address this problem: an application can be run on the VM using some mock training data and then all generated code and VM internal data structures are serialized into an AppJIT snapshot. This snapshot can then be distributed instead of distributing application in the source (or Kernel binary) form. VM starting from this snapshot can still JIT - if it turns out that execution profile on the real data does not match execution profile observed during training.

```
                                                    ┌──────────────┐
                            SNAPSHOT               ┌──────────────┐│
┌──────────────┐           ╭────╮╭────╮           ┌──────────────┐││
│ HEAP         │           │ 01 ││    │           │ HEAP         │││
│     ██       │           │ 10 ││ ░░◀──┐         │     ██       │││
│    ╱  ╲      │           │ 10 ││    │ │         │    ╱  ╲      │││
│  ██╲   ██    │           │ 11 ││    │ └────────────██╲   ██    │││
│  ╱  ╲ ╱  ╲   │┣━━━━━━━━━▶│ 00 ││    │┣━━━━━━━━━▶│     ╲ ╱  ╲   │││
│ ░░   ╳   ██  │ serialize │ 01 ││    │deserialize│      ╳   ██  │││
│     ╱ ╲  ╱   │           │ 11 ││    │           │     ╱ ╲  ╱│  │││
│   ██   ██╲   │           │ 00 ││    │           │   ██   ██ │  ││┘
│           ░░ │           │ 00 ││ ░░◀──────────────────────┘ ░░ │┘
└──────────╱───┘           ╰────╯╰────╯           └──────────╱───┘
         code               data  code                 isolate can JIT more
```

> **Trying it**
>
> `dart` binary will generate AppJIT snapshot after running the application if you pass `--snapshot-kind=app-jit --snapshot=path-to-snapshot` to it. Here is an example of generating and using an AppJIT snapshot for `dart2js`.
>
> * Run from source in JIT mode
>     ```console
>     $ dart pkg/compiler/lib/src/dart2js.dart -o hello.js hello.dart
>     Dart file (hello.dart) compiled to JavaScript: hello.js
>     ```
> * Create an app-jit snapshot trained by compiling `dart2js` with itself, then
>   run from this snapshot.
>     ```console
>     $ dart --snapshot-kind=app-jit --snapshot=dart2js.snapshot \
>        pkg/compiler/lib/src/dart2js.dart -o hello.js hello.dart
>     Dart file (hello.dart) compiled to JavaScript: hello.js
>
>     $ dart dart2js.snapshot -o hello.js hello.dart
>     Dart file (hello.dart) compiled to JavaScript: hello.js
>     ```

### Running from AppAOT snapshots

AOT snapshots were originally introduced for platforms which make JIT compilation impossible, but they can also be used in situations where fast startup and consistent performance is worth potential peak performance penalty.

> **Note**
>
> There is usually a lot of confusion around how performance characteristics of JIT and AOT compare. JIT has access to precise local type information and execution profile of the running application, however it has to pay for it with warmup. AOT can infer and prove various properties globally (for which it has to pay with compile time), but has no information of how the program will actually be executing - on the other hand AOT compiled code reaches its peak performance almost immediately with virtual no warmup. Currently Dart VM JIT has best peak performance, while Dart VM AOT has best startup time.

Inability to JIT implies that:

1. AOT snapshot *must* contain executable code for each and every function that could be invoked during application execution;
2. the executable code *must not* rely on any speculative assumptions that could be violated during execution;

To satisfy these requirements the process of AOT compilation does global static analysis (*type flow analysis* or *TFA*) to determine which parts of the application are reachable from known set of *entry points*, instances of which classes are allocated and how types flow through the program. All of these analyses are conservative: meaning that they err on the side of correctness - which is in stark contrast with JIT which can err on the side of performance, because it can always deoptimize into unoptimized code to implement correct behavior.

All potentially reachable functions are then compiled to native code without any speculative optimizations. However type flow information is still used to specialize the code (e.g. devirtualize calls).

Once all functions are compiled a snapshot of the heap can be taken.

Resulting snapshot can then be run using *precompiled runtime*, a special variant of the Dart VM which excludes components like JIT and dynamic code loading facilities.

```
 ╭─────────────╮                      ╭────────────╮
 │╭─────────────╮       ╔═════╗       │ Kernel AST │
 ││╭─────────────╮┣━━━▶ ║ CFE ║ ┣━━━▶ │            │
 ┆││ Dart Source │      ╚═════╝       │ whole      │
 ┆┆│             │                    │ program    │
  ┆┆             ┆                    ╰────────────╯
   ┆             ┆                          ┳
                                            ┃
                                            ▼
                                         ╔═════╗ type-flow analysis
                                         ║ TFA ║ propagates types globally
                   VM contains an        ╚═════╝ through the whole program
                  AOT compilation           ┳
                  pipeline which            ┃
                  reuses parts of           ▼
                    JIT pipeline      ╭────────────╮
     ╭────────────╮       ╲           │ Kernel AST │
     │AOT Snapshot│      ╔════╗       │            │
     │            │◀━━━┫ ║ VM ║ ◀━━━┫ │ inferred   │
     │            │      ╚════╝       │ treeshaken │
     ╰────────────╯                   ╰────────────╯
```

> **Source to read**
>
> [`package:vm/transformations/type_flow/transformer.dart`][] is an entry point to the type flow analysis and transformation based on TFA results. [`dart::Precompiler::DoCompileAll`][] is an entry point to the AOT compilation loop in the VM.

> **Trying it**
>
> AOT compilation pipeline is currently packaged into Dart SDK as [`dart compile exe` command](https://dart.dev/tools/dart2native).
>
> ```console
> $ dart compile exe -o hello hello.dart
> $ ./hello
> Hello, World!
> ```
>
> It is possible to pass options like `--print-flow-graph-optimized` and `--disassemble-optimized` to the `dart compile exe` via `--extra-gen-snapshot-options` flag. You also need to pass `--verbose` to see the output, otherwise it is silently swallowed by the tool.
>
> ```console
> $ dart compile exe --verbose                                  \
>   --extra-gen-snapshot-options=--print-flow-graph-optimized   \
>   --extra-gen-snapshot-options=--print-flow-graph-filter=main \
>   --extra-gen-snapshot-options=--disassemble                  \
>   hello.dart
> ```
>

## Runtime System

### Object Model

### Representation of Types

See [Representation of Types](types.md).

### GC

See [GC](gc.md).

## Compiler

### Method Calls

There is currently large difference between how AOT and JIT optimize method invocation sequences.

JIT keeps to its Dart 1 roots and largely ignores statically typed nature of Dart 2. In unoptimized code method calls by default go through an inline cache which collects type feedback. Optimizing compiler then speculatively specializes indirect method calls into direct calls guarded by _class checks_. This process is called _speculative devirtualization_. Those call sites which can't be devirtualized are divided into two categories. Those call sites which have not been executed yet are compiled to use inline caching and collect type feedback for subsequent reoptimizations. Those call sites which are highly polymorphic (megamorphic) are compiled to use metamorphic dispatch.

On the other hand, AOT heavily leans onto the statically typed nature of Dart 2. The compiler uses results of global type flow analysis (TFA) to devirtualize as many call sites as it can. This devirtualization is not speculative: compiler only devirtualizes the call site if it can prove that it always invokes a specific method. If compiler can not devirtualize a call site, then it chooses a dispatch mechanism based on whether the receiver's static type is `dynamic` or not. Calls on `dynamic` receiver use switchable calls. All other calls go through a _global dispatch table_.

#### Global Dispatch Table (GDT)

> **Note**
>
> The approach adopted by Dart VM and described in this section is largely based on insights from [Minimizing row displacement dispatch tables](https://dl.acm.org/doi/abs/10.1145/217839.217851) by Karel Driesen and Urs Holzle.

Imagine for a moment that each class defined in the program added its methods to a global dictionary. For example, given the following class hierachy

```dart
class A {
  void foo() { }
  void bar() { }
}

class B extends A {
  void foo() { }
  void baz() { }
}
```

This dictionary will contain the following:

```dart
globalDispatchTable = {
  // Calling [foo] on an instance of [A] hits [A.foo].
  (A, #foo): A.foo,
  // Calling [bar] on an instance of [A] hits [A.bar].
  (A, #bar): A.bar,
  // Calling [foo] on an instance of [B] hits [B.foo].
  (B, #foo): B.foo,
  // Calling [bar] on an instance of [B] hits [A.bar].
  (B, #bar): A.bar,
  // Calling [baz] on an instance of [B] hits [B.baz].
  (B, #baz): B.baz
};
```

Compiler could then use such a dictionary to dispatch invocations: a method call  `o.m(...)` will be  compiled into `globalDispatchTable[(classOf(o), #m)](o, ...)`.

A naive approach to representing `globalDispatchTable` (or `gdt` for short) is to number all classes and all method selectors in the program sequentially and then use a two-dimensional array: `gdt[(classOf(o), #m)]` becomes `gdt[o.cid][#m.id]`. At this point we can choose to flatten this two-dimensional array either using selector-major order (`gdt[numClasses * #m.id + o.cid]`) or class-major order (`gdt[numSelectors * o.cid + #m.id]`) .

Let us take a look at selector-major order. In this representation we say that `numClasses * #m.id` gives us _selector offset_: an offset into the GDT at which a row of entries (one per class) corresponding to this selector is stored. Consider the following class hierarchy:

```dart
class A {
  void foo() { }
}

class B extends A {
  void foo() { }
}

class C {
  void bar() { }
}

class D extends C {
  void bar() { }
}
```

Classes `A`, `B`, `C` and `D` will be numbered 0, 1, 2 and 3 respectively, while selectors `foo` and `bar` will be numbered `0` and `1`. This will lead to the following array:

```
offset  0                       4
        │A     B     C     D    │
        ┌─────┬─────┬─────┬─────┐
foo row │A.foo│B.foo│ NSM │ NSM │
        └─────┴─────┴─────┴─────┘
                                │A     B     C     D
                                ┌─────┬─────┬─────┬─────┐
bar row                         │ NSM │ NSM │C.bar│D.bar│
                                └─────┴─────┴─────┴─────┘
        ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
GDT     │A.foo│B.foo│ NSM │ NSM │ NSM │ NSM │C.bar│D.bar│
        └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

It's evident that such representation is rather memory inefficient: dispatch table ends up with a lot of NSM (`noSuchMethod`) entries.

Fortunately, Dart 2 static type system provides us with a way to compress this table. In Dart 2 static type of the receiver constrains the list of selectors allowed by the compiler. This guarantees that any non-`dynamic` invocation calls an actual method rather than `Object.noSuchMethod`.  Consequently, if we only use dispatch table for non-`dynamic` call sites then we don't need to fill holes in the table with NSM entries.

This leads to the following idea: instead of numbering selectors sequentially and using `numClasses * sid` as a selector offset, we could instead select selector offsets which causes selector rows to interleave and reuse available holes.

Let us look back to the previous example with 4 classes. Instead of numbering `foo` with `0` and `bar` with `1` and using `0` and `4` as a selector offsets respectively,  we could simply assign both selectors an offset of `0` leading to the following compact table

```
offset  0
        │A     B     C     D
        ┌─────┬─────┬─────┬─────┐
foo row │A.foo│B.foo│░░░░░│░░░░░│
        └─────┴─────┴─────┴─────╲
         A     B     C     D     hole
        ┌─────┬─────┬─────┬─────┐
bar row │░░░░░│░░░░░│C.bar│D.bar│
        └─────┴─────┴─────┴─────┘
        ┌─────┬─────┬─────┬─────┐
GDT     │A.foo│B.foo│C.bar│D.bar│
        └─────┴─────┴─────┴─────┘
```

This works because it is impossible to invoke `bar` on `A` or `B` and it's impossible to invoke `foo` on `C` or `D` - meaning, for example, that `A.foo` entry will never be hit with an instance of `C` as receiver.

> **Note**
>
> Strictly speaking this technique does not actually require static typing and was originally applied to Smalltalk. This requires a small trick: each method should check in prologue whether its selector matches the selector of the invocation which led to this method being invoked. If selectors don't match this means we arrived to this method erroneously through a reused NSM entry. Static typing allows us to avoid this check.

Calls through GDT compile to the following machine code in Dart VM (X64 example):

```nasm
movzx cid, word ptr [obj + 15] ; load receiver's class id
call [GDT + cid * 8 + (selectorOffset - 16) * 8]
```

Here `GDT` is a reserved register containing a biased pointer to the GDT (`&GDT[16]` on X64) and `selectorOffset` is an offset of the selector we are invoking. The call looks similar across architectures, though concrete value of the bias (specified by [`dart::DispatchTable::kOriginElement`][]) depends on the target architecture. We bias `GDT` pointer to have a more compact call sequence encoding for smaller selectors, e.g. on X64
an indirect `call` has an encoding which allows for an 1 byte signed immediate offset. This means that imeddiate offsets in the range `-128` to `127` are represented as a single byte. With an unbiased GDT pointer we would only be able to utilize half of this range because `selectorOffset` is an unsigned value. With biased GDT we can use the full range:`selectorOffset` `15` still requires just one byte encoding.

> **Source to read**
>
> Computation of the global dispatch table is spread through different
> parts of the toolchain.
>
> * [`TableSelectorAssigner`][`package:vm/transformations/type_flow/table_selector_assigner.dart`] is responsible for assigning selector ids to methods in the program.
> * [`dart::DispatchTableCallInstr`][] is an IL instruction representing a call through
> GDT.
> * [`dart::AotCallSpecializer::ReplaceInstanceCallsWithDispatchTableCalls`][] is a compiler pass
> which replaces non-devirtualized method calls with GDT calls.
> * [`dart::FlowGraphCompiler::EmitDispatchTableCall`][] emits architecture specific
> call sequence for calls through GDT.
> * [`dart::compiler::DispatchTableGenerator`][] is responsible for assigning
> selector offsets and computing final layout of the table.

#### Switchable Calls

Switchable call is an extension of an inline caching originally developed for Dart 1 AOT - where they were used to compile all method calls. Current AOT only uses them when compiling calls with a `dynamic` receiver. They are also used in JIT to speedup calls from unoptimised code

JIT section already described that each inline cache associated with a call site consists of two pieces: a cache object (represented by an instance of [`dart::UntaggedICData`][]) and a chunk of native code to invoke (e.g. an [inline cache stub][`dart::compiler::StubCodeCompiler::GenerateNArgsCheckInlineCacheStub`]). Original implementation in JIT was only updating the cache itself, however this was later extended by allowing runtime system to update both the cache and the stub target depending on the types observed by the call site.

```
                 UnlinkedCall
      cache      ┌────────────────────────────────────┐
      ┌─────────▶│targetName: "method"                │
      │          └────────────────────────────────────┘
      ┴
object.method()
      ┬          SwitchableCallMissStub
      │          ┌────────────────────────────────────┐
      └─────────▶│ return DRT_SwitchableCallMiss(...);│
      target     └────────────────────────────────────┘
```

Initially all `dynamic` calls in AOT start in the *unlinked* state. When such call-site is reached for the first time [SwitchableCallMissStub][`dart::compiler::StubCodeCompiler::GenerateSwitchableCallMissStub`] is invoked, which simply calls into runtime helper [`dart::DRT_SwitchableCallMiss`][] to link this call site.

If possible [`dart::DRT_SwitchableCallMiss`][] tries to transition the call site into a _monomorphic_ state. In this state call site turns into a direct call, which enters method through a special entry point which verifies that receiver has expected class.

```

      cache      ┌────────────────────────────────────┐
      ┌─────────▶│id of class C                       │
      │          └────────────────────────────────────┘
      ┴
object.method()
      ┬          C.method
      │          ┌────────────────────────────────────┐
      └─────────▶│ monomorphic_entry:                 │
      target     │   // Check if receiver's cid       │
                 │   // matches the cached one.       │
                 │   if (this.cid != cache)           │
                 │     return SwitchableCallMissStub()│
 normal calls    │ // fall through to normal entry    │
 enter here ────▶│ normal_entry:                      │
                 │   // Body of C.method              │
                 └────────────────────────────────────┘
```

In the example above we assume that `obj` was an instance of `C`  and that `obj.method` resolved to `C.method` when `obj.method()` was executed for the first time.

Next time we execute the same call-site it will invoke `C.method` directly bypassing method lookup process. However it will enter `C.method` through a special entry point, which will verify that `obj` is still an instance of `C`. If that is not the case [`dart::DRT_SwitchableCallMiss`][] will be invoked and will update call site state to reflect the miss.

`C.method` might still be a valid target for an invocation, e.g `obj` is an instance of the class `D` which extends `C` but does not override `C.method`. In this case we check if call site could transition into a *single target* state, implemented by [SingleTargetCallStub][`dart::compiler::StubCodeCompiler::GenerateSingleTargetCallStub`] (see also [`dart::UntaggedSingleTargetCache`][]).

```
                 SingleTargetCache
      cache      ┌────────────────────────────────────┐
      ┌─────────▶│fromCid, toCid, target              │
      │          └────────────────────────────────────┘
      ┴
object.method()  SingleTargetCallStub
      ┬          ┌────────────────────────────────────┐
      └─────────▶│ if (cache.fromCid <= this.cid &&   │
      target     │     this.cid <= cache.toCid )      │
                 │     return cache.target(...);      │
                 │ // Not found                       │
                 │ return SwitchableCallMissStub(...);│
                 └────────────────────────────────────┘
```


This stub benefits from depth-first class id assignment done by AOT compiler and during AppJIT snapshot training. In this mode most classes are assigned integer ids using depth-first traversal of the inheritance hierarchy. If `C` is a base class with subclasses `D0, ..., Dn` and none of those override `C.method` then `C.:cid <= classId(obj) <= max(D0.:cid, ..., Dn.:cid)` implies that `obj.method` resolves to `C.method`. In such cases instead of comparing for equality (which checks a for a specific class), we can instead compare if class id falls into a specific range and that will cover all subclasses of `C`. That's exactly what `SingleTargetCallStub` does.

If single target case is not applicable call site is switched to use linear search inline cache. Which coincidentally is also the initial state for call-sites in JIT mode (see [`ICCallThroughCode`][`dart::compiler::StubCodeCompiler::GenerateICCallThroughCodeStub`] stub, [`dart::UntaggedICData`][] and [`dart::DRT_SwitchableCallMiss`][]).

```
                 ICData
      cache      ┌────────────────────────────────────┐
      ┌─────────▶│{cid0: target0, cid1: target1, ... }│
      │          └────────────────────────────────────┘
      ┴
object.method()  ICCallThroughCodeStub
      ┬          ┌────────────────────────────────────┐
      └─────────▶│ for (i = 0; i < cache.length; i++) │
      target     │   if (cache[i] == this.cid)        │
                 │     return cache[i + 1](...);      │
                 │ // Not found                       │
                 │ return SwitchableCallMissStub(...);│
                 └────────────────────────────────────┘
```


Finally if the number of checks in the linear array grows past threshold the call site is switched to use a dictionary like structure (see [MegamorphicCallStub][`dart::compiler::StubCodeCompiler::GenerateMegamorphicCallStub`], [`dart::UntaggedMegamorphicCache`][] and [`dart::DRT_SwitchableCallMiss`][]).

```
                 MegamorphicCache
      cache      ┌────────────────────────────────────┐
      ┌─────────▶│{cid0: target0, cid1: target1, ... }│
      │          └────────────────────────────────────┘
      ┴
object.method()  MegamorphicCallStub
      ┬          ┌────────────────────────────────────┐
      └─────────▶│ var target = cache[this.cid];      │
      target     │ if (target != null)                │
                 │   return target(...);              │
                 │ // Not found                       │
                 │ return SwitchableCallMissStub(...);│
                 └────────────────────────────────────┘
```

### `try`/`catch` in IL

See [Exceptions Implementation](compiler/exceptions.md).

### `async`, `async*` and `sync*` methods

See [Suspendable Functions](async.md).

### `as` checks

See [Type Testing Stubs](compiler/type_testing_stubs.md).

## Miscellaneous

### Pragmas

See [VM-Specific Pragma Annotations](pragmas.md).

### DWARF (non-symbolic) stack traces

See [DWARF stack traces mode](dwarf_stack_traces.md).

## Glossary

See [Glossary](glossary.md)


<!-- AUTOGENERATED XREF SECTION -->
[`dart::ThreadPool`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/thread_pool.h#L20
[`dart::ThreadPool::Task`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/thread_pool.h#L23
[`dart::ConcurrentSweeperTask`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/heap/sweeper.cc#L109
[`dart::MessageHandlerTask`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/message_handler.cc#L23
[`pkg/kernel/README.md`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/kernel/README.md
[`pkg/front_end`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/front_end
[`runtime/vm/object.h`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/object.h
[`runtime/vm/raw_object.h`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h
[`dart::Class`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/object.h#L1027
[`dart::UntaggedClass`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h#L958
[`dart::Field`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/object.h#L4099
[`dart::UntaggedField`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h#L1438
[`dart::DispatchTable::kOriginElement`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/dispatch_table.h#L31
[`dart::UntaggedICData`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h#L2453
[`dart::compiler::StubCodeCompiler::GenerateNArgsCheckInlineCacheStub`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/stub_code_compiler_arm64.cc#L2471
[`dart::compiler::StubCodeCompiler::GenerateSwitchableCallMissStub`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/stub_code_compiler_arm64.cc#L3613
[`dart::DRT_SwitchableCallMiss`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/runtime_entry.cc#L2551
[`dart::compiler::StubCodeCompiler::GenerateSingleTargetCallStub`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/stub_code_compiler_arm64.cc#L3640
[`dart::UntaggedSingleTargetCache`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h#L2414
[`dart::compiler::StubCodeCompiler::GenerateICCallThroughCodeStub`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/stub_code_compiler_arm64.cc#L3537
[`dart::compiler::StubCodeCompiler::GenerateMegamorphicCallStub`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/stub_code_compiler_arm64.cc#L3456
[`dart::UntaggedMegamorphicCache`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/raw_object.h#L2481
[`package:vm/transformations/type_flow/table_selector_assigner.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/lib/transformations/type_flow/table_selector_assigner.dart
[`dart::DispatchTableCallInstr`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/backend/il.h#L4758
[`dart::AotCallSpecializer::ReplaceInstanceCallsWithDispatchTableCalls`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/aot/aot_call_specializer.cc#L1128
[`dart::FlowGraphCompiler::EmitDispatchTableCall`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/backend/flow_graph_compiler_arm64.cc#L665
[`dart::compiler::DispatchTableGenerator`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/aot/dispatch_table_generator.h#L89
[`package:vm/transformations/type_flow/transformer.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/lib/transformations/type_flow/transformer.dart
[`dart::Precompiler::DoCompileAll`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/aot/precompiler.cc#L452
[`runtime/vm/app_snapshot.cc`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/app_snapshot.cc
[`Dart_CreateAppJITSnapshotAsBlobs`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/dart_api_impl.cc#L6954
[`Dart_CreateAppAOTSnapshotAsAssembly`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/dart_api_impl.cc#L6662
[`Dart_CreateIsolateGroup`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/dart_api_impl.cc#L1375
[`runtime/vm/deopt_instructions.cc`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/deopt_instructions.cc
[`dart::CompilerDeoptInfo::CreateDeoptInfo`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/backend/flow_graph_compiler_arm64.cc#L87
[`runtime/vm/compiler`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler
[`dart::CompileParsedFunctionHelper::Compile`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/jit/compiler.cc#L473
[`runtime/vm/compiler/backend/il.h`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/backend/il.h
[`dart::kernel::StreamingFlowGraphBuilder::BuildGraph`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/frontend/kernel_binary_flowgraph.cc#L891
[`dart::InlineCacheMissHandler`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/runtime_entry.cc#L2493
[`runtime/vm/compiler/compiler_pass.cc`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/compiler_pass.cc
[`dart::JitCallSpecializer`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/compiler/jit/jit_call_specializer.h#L16
[`pkg/vm/bin/gen_kernel.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/bin/gen_kernel.dart
[`pkg/vm/bin/dump_kernel.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/bin/dump_kernel.dart
[`pkg/front_end/tool/compile_platform.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/front_end/tool/_fasta/compile_platform.dart
[`package:kernel/ast.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/kernel/lib/ast.dart
[`package:front_end`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/front_end/lib
[`dart::kernel::KernelLoader::LoadEntireProgram`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/kernel_loader.cc#L236
[`pkg/vm/bin/kernel_service.dart`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/bin/kernel_service.dart
[`runtime/vm/kernel_isolate.cc`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/kernel_isolate.cc
[`package:vm`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/pkg/vm/lib
[`dart::Isolate`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/isolate.h#L971
[`dart::IsolateGroup`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/isolate.h#L281
[`dart::Heap`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/heap/heap.h#L35
[`dart::Thread`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/thread.h#L334
[`Dart_RunLoop`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/dart_api_impl.cc#L2010
[`dart::MessageHandler`]: https://github.com/dart-lang/sdk/blob/2ed6ea29003476e2a28fb5f4683a656427eb41ff/runtime/vm/message_handler.h#L20
