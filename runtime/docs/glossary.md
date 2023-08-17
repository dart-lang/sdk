# Glossary

## Small integer, Smi (/smaɪ/)

A signed integer with one bit less than a full word (i.e., 31 or 63). An [immediate object](gc.md#object-representation).

## Medium integer, Mint

A signed 64-bit integer. A [heap object](gc.md#object-representation). Mints never represent a value that can be represented as a Smi.

## Class id, class index, CID

An integer that uniquely identifies a class within an isolate. It has the virtues of being smaller than a full pointer to the class, never changing due to GC, and being a build-time constant for well-known classes.

An object's reference to its class, type feedback collected by ICData, and various optimizations are represented with CIDs instead of full pointers to classes.

In other VMs, this is also called the _class tag_.

## [Object pool, literal pool](../vm/object.h#:~:text=class%20ObjectPool)

A set of objects and raw bits used by generated code as constants.

## Pool pointer, PP

A fixed register containing the address of the current function's (JIT) or global (AOT) [literal pool](#object-pool-literal-pool).

## [Instruction pointer, IP, program counter, PC](https://en.wikipedia.org/wiki/Program_counter)

The address of the currently executing instruction.

## [Garbage collection, GC](gc.md)

Automatic memory management that reclaims objects known to be unreachable via tracing.

## [Safepoint](gc.md#safepoints)

A point at which all pointers into the Dart heap can be precisely identified.

## [Handle](gc.md#handles)

An indirect pointer to a Dart object.

## Thread-local allocation buffer, TLAB

A contiguous area owned by one thread for allocation, allowing it to bump allocate without locking.

## [Stack map](../vm/object.h#:~:text=class%20CompressedStackMaps)

Identifies which slots in a stack frame contain objects (to be visited by the GC) and which contain raw bits (to be ignored by the GC) for each return address.

## [Inline cache, IC](https://en.wikipedia.org/wiki/Inline_caching)

A cache of method lookup results specific to one call-site. It both speeds up method invocation by avoiding repeated lookups and records type feedback that is used by the optimizer. In the Dart VM,
these are not literally inline in the machine code as they were in [early Smalltalk JITs](https://dl.acm.org/doi/10.1145/800017.800542), but the name has stuck.

## Monomorphic

Having exactly one possible type (in the context of a conservative optimization) or one observed type (in the context of a speculative optimization).

## Polymorphic

Having a small number of possible types.

## Megamorphic

Having a large number of possible types.

## [Ahead-of-time compilation, AOT](https://en.wikipedia.org/wiki/Ahead-of-time_compilation)

Compiling a program in a separate process from its execution. Uses conservative optimizations based on a closed-world assumption and whole-program analysis.

## [Just-in-time compilation, JIT](https://en.wikipedia.org/wiki/Just-in-time_compilation)

Compiling a program as it executes in the same process. Uses speculative optimizations based on type feedback and usage feedback.

## Conservative optimization

An optimization based on some property that is true for all possible executions of a program.

## Speculative optimization

An optimization based on some property that has held so far in the execution of a program, but may fail to hold as part of future execution. Speculative optimizations must add checks that their assumptions continue to hold and be able deoptimize if and when their assumptions no longer hold.

## Deoptimization

Transitioning from a stack frame running optimized code to a frame or multiple frames running the corresponding unoptimized code. Usually because a speculative assumption made by the optimized code has been discovered to no longer hold.

## Deopt id

An identifier that matches a position in optimized code to a position in unoptimized code.

## On-stack replacement, OSR

Switching an active stack frame from unoptimized code to optimize code. This is an uncommon case; the common case of optimization only causes new invocations of the function to run the new,
optimized code.

## Token position

A source position within a script, usually a file. It is a UTF-8 offset unrelated to tokenization. The name dates from the VM's frontend, where it was an index into a [token](https://en.wikipedia.org/wiki/Lexical_analysis#Token) list.

## [Executable and Linkable Format, ELF](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format)

The format of executables on Linux, Android and Fuchsia. The Dart AOT compiler can directly produce an ELF shared library as output.

## [Mach-O](https://en.wikipedia.org/wiki/Mach-O)

The format of executables on macOS and iOS. The Dart AOT compiler can produce assembly that the GCC or LLVM assemblers can translate into Mach-O.

## [DWARF](https://en.wikipedia.org/wiki/DWARF)

The format of debugging information included in [ELF](#elf) or [Mach-O](#mach-o) files. The Dart AOT compiler can directly produce DWARF, which contains information on how to unwind Dart frames and how to map machine code addresses back to source positions.

## Isolate

The unit of concurrency in Dart. Each isolate has an independent set of globals and message queue. Isolates communicate with each other via [asynchronous message passing](https://en.wikipedia.org/wiki/Actor_model) rather than shared mutable memory like threads do.

## Isolate group

A set of isolates that are sharing the same program and the same heap. Isolates in the same isolate group can send more types of objects to each other because the sender can rely on the receiver having the classes needed to represent any object it might send. Messages sent within an isolate group can also be more efficient because they are in the same heap.

## Out-of-band message, OOB message

A message that is delivered at any interrupt check, such as at function entry or the back-edge of a loop, rather than only when returning to the message loop.

## [Hot reload](https://github.com/dart-lang/sdk/wiki/Hot-reload)

Changing a running program while retaining its current state: globals, frames, and objects transitively reachable from such.

## [AddressSanitizer, ASAN](https://github.com/dart-lang/sdk/wiki/Debugging-Dart-VM-with-AddressSanitizer)

Instrumentation to detect use-after-free and other similar issues.

## [MemorySanitizer, MSAN](https://github.com/dart-lang/sdk/wiki/Debugging-Dart-VM-with-AddressSanitizer)

Instrumentation to detect use of uninitialized memory and other similar issues.

## [ThreadSanitizer, TSAN](https://github.com/dart-lang/sdk/wiki/Debugging-Dart-VM-with-AddressSanitizer)

Instrumentation to detect use of data races and other similar issues.

## [UndefinedBehaviorSanitizer, UBSAN](https://github.com/dart-lang/sdk/wiki/Debugging-Dart-VM-with-AddressSanitizer)

Instrumentation to detect undefined behavior such as signed integer overflow.

## [Common front end, CFE, Dart front end, DFE](../../pkg/front_end/README.md)

A tool that handles the early phases of compilation, shared between the Dart VM and dart2js. It takes Dart source as input and produces [kernel](#kernel-dart-intermediate-language-dil-dill).

## [Kernel, Dart intermediate language, DIL, DILL](../../pkg/kernel/README.md)

A representation of a Dart program at the level of a resolved [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree).

## [Intermediate Language, IL, intermediate representation, IR](../vm/compiler/backend/il.h)

A representation of a Dart function between kernel and machine code. Most optimizations happen at this level.

Not to be confused with [DIL](#kernel-dart-intermediate-language-dil-dill).

## [Control flow graph, CFG, flow graph](https://en.wikipedia.org/wiki/Control-flow_graph)

## [Loop-invariant code mode, LICM](../vm/compiler/backend/redundancy_elimination.h#:~:text=class%20LICM)

## Common subexpression elimination, CSE

## [Static single-assignment form, SSA](https://en.wikipedia.org/wiki/Static_single-assignment_form)

## [Class hierarchy analysis, CHA](../vm/compiler/cha.h)

## Simulator, SIMARM, SIMARM64, SIMRISCV32, SIMRISCV64

An interpreter to enable running Dart code compiled for some target architecture on hardware of a different architecture. For example, one can run Dart code compiled for ARM64 on a X64 host machine. This allows compiler developers to test changes without needing hardware for each architecture.

The Dart VM has simulators for ARM, ARM64, RV32GC and RV64GC, but not for IA32 or X64.

## Stub

A commonly used sequence of machine code that has been factored out into a separate procedure to be called when needed instead of being repeated inline.

## [Type arguments, type argument vector](types.md#typearguments)
