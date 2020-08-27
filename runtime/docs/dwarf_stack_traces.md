# Using and interpreting DWARF stack traces

The Dart VM AOT compiler can encode code source mapping information as DWARF
debugging information instead of using in-snapshot `CodeSourceMap` objects.
Unlike `CodeSourceMap` objects, this DWARF information can then be stripped
from snapshots provided to users, which lowers the binary size.

## Turning on DWARF encoding of code source mapping information

To output code source mapping information as DWARF debugging information,
use the `--dwarf-stack-traces` flag. By default, generated assembly or ELF
snapshots include the DWARF information directly.

> **Note**: DWARF debugging information is _not_ obfuscated when using the
> `--obfuscate` flag. To avoid unobfuscated information leaking to users
> when using `--dwarf-stack-traces`, use the `--strip` option when creating
> ELF snapshots.

To output DWARF debugging information to a separate file that can be saved
as an artifact for later debugging, use the `--save-debugging-info=<...>` flag.
The generated file is not guaranteed to be any specific format and may change in
the future. See
[Translating DWARF stack traces](#translating-dwarf-stack-traces) for how to use
this file.

## Differences when using DWARF code source mapping information

When using DWARF code source mapping information, stack traces only include PC
address information for frames. This means that a developer will need the
generated DWARF information to get function, file, and line number information
for each frame.

Take the following example program, saved as `throws.dart` in the root of a
Dart SDK checkout:
```dart
@pragma('vm:prefer-inline')
void bar() => throw null;

@pragma('vm:never-inline')
void foo() => bar();

void main() => foo();
```

Below is the result of running the file both without and with
`--dwarf-stack-traces` in a 64-bit Linux development environment:

```bash
$ python tools/build.py -a x64 -m release runtime_kernel runtime_precompiled

$ pkg/vm/tool/gen_kernel --platform out/ReleaseX64/vm_platform_strong.dill -o throws.dill throws.dart

$ out/ReleaseX64/gen_snapshot --snapshot_kind=app-aot-elf --elf=snapshot.so throws.dill

# Here, we save the debugging information to a separate file debug.data as well
# as including it in the generated ELF snapshot for future examples.
$ out/ReleaseX64/gen_snapshot --dwarf-stack-traces --save-debugging-info=debug.data --snapshot_kind=app-aot-elf --elf=dwarf_snapshot.so throws.dill

$ out/ReleaseX64/dart_precompiled_runtime snapshot.so
Unhandled exception:
Throw of null.
#0      bar (file:///.../sdk/throws.dart:2)
#1      foo (file:///.../sdk/throws.dart:5)
#2      main (file:///.../sdk/throws.dart:7)
#3      _startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307)
#4      _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174)

$ out/ReleaseX64/dart_precompiled_runtime dwarf_snapshot.so
Unhandled exception:
Throw of null.
Warning: This VM has been configured to produce stack traces that violate the Dart standard.
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 148677, tid: 139648739401792, name Dart_Initialize
isolate_instructions: 7f028072e000 vm_instructions: 0
    #00 abs 00007f028098381e virt 000000000025c81e /.../sdk/snapshot.so
    #01 abs 00007f0280983742 virt 000000000025c742 /.../sdk/snapshot.so
    #02 abs 00007f02809837d5 virt 000000000025c7d5 /.../sdk/snapshot.so
    #03 abs 00007f028099d8af virt 00000000002768af /.../sdk/snapshot.so
    #04 abs 00007f02808f42ff virt 00000000001cd2ff /.../sdk/snapshot.so
    #05 abs 00007f028099d7a2 virt 00000000002767a2 /.../sdk/snapshot.so
    #06 abs 00007f028086df98 virt 0000000000146f98 /.../sdk/snapshot.so
```

For a DWARF-based stack trace, we are guaranteed to have an absolute PC
address for each frame (the hexadecimal number following `abs`) as well as the
absolute addresses for the start of the isolate instructions and the VM
instructions (the line starting with `isolate_instructions`). This information
is used by our tool and libraries for converting DWARF stack traces, described
later.

If we are running from a snapshot which is a native format for dynamic libraries
(e.g., ELF on Linux or Mach-O on Mac OS X), then we will also have a virtual PC
address for each frame (the hexadecimal number following `virt`). If we have
appropriate DWARF information for the snapshot (e.g., part of the unstripped
ELF snapshot on Linux, or a separately generated .DSYM package when compiling
the generated assembly on Mac OS X), we can use the virtual address along with
the DWARF information to get back function, file, and line number information
using native tools:

```bash
# Virtual address from frame #00
$ addr2line -f -i -e dwarf_snapshot.so 000000000025c81e
bar
file:///.../sdk/throws.dart:2
foo
file:///.../sdk/throws.dart:5

# Virtual address from frame #01
$ addr2line -f -i -e dwarf_snapshot.so 000000000025c742
Precompiled____main_6919
file:///.../dart/sdk/throws.dart:7
```

However, as seen here, the information may not be exactly as expected from the
non-DWARF stack trace. In addition, the DWARF stack trace may include frames
that are internal to the Dart VM and would not normally be provided in
non-DWARF stack traces. Note that there are seven frames in the DWARF stack
trace above, but only 5 in the non-DWARF stack trace. Frame `#02` happens
to correspond to one of these elided frames:

```bash
# Virtual address from frame #02
$ addr2line -f -i -e dwarf_snapshot.so 000000000025c7d5
Precompiled____main_main_6920
file:///.../sdk/throws.dart:?
```

## Translating DWARF stack traces

To ease translation of DWARF stack traces, we provide a platform-independent
tool and libraries. They can translate DWARF stack traces using the DWARF
debugging information contained in unstripped ELF snapshots or saved separately
using `--save-debugging-info=<...>`. For most uses, the tool should suffice, but
the libraries it uses are also available for integration into Dart-based
workflows.

### Using the stack trace converter tool

A simple way to translate DWARF stack traces is to use the tool `decode`
from the package [native_stack_traces](https://pub.dev/packages/native_stack_traces). The tool has one required
argument `-e`, which takes the name of the file containing DWARF
debugging information as an input. This can either be an
unstripped ELF snapshot or a file generated by `--save-debugging-info=<...>`.

Using the earlier example, we can run the snapshot and convert any generated
stack traces as follows:

```bash
# Using the unstripped ELF snapshot and piping all output to the tool's stdin.
$ out/ReleaseX64/dart_precompiled_runtime dwarf_snapshot.so |& out/ReleaseX64/dart pkg/native_stack_traces/bin/decode.dart -e dwarf_snapshot.so
Unhandled exception:
Throw of null.
Warning: This VM has been configured to produce stack traces that violate the Dart standard.
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 158029, tid: 140495595888704, name Dart_Initialize
isolate_instructions: 7fc7ad076000 vm_instructions: 0
#0	bar (file:///.../sdk/throws.dart:2)
#1	foo (file:///.../sdk/throws.dart:5)
#2	main (file:///.../sdk/throws.dart:7)
#3	_startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307)
#4	_RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174)

# Using the separately saved debugging information and piping all output to the tool's stdin.
$ out/ReleaseX64/dart_precompiled_runtime dwarf_snapshot.so |& out/ReleaseX64/dart pkg/native_stack_traces/bin/decode.dart -e debug.data
Unhandled exception:
Throw of null.
Warning: This VM has been configured to produce stack traces that violate the Dart standard.
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 158242, tid: 139697980215360, name Dart_Initialize
isolate_instructions: 7f0df76e1000 vm_instructions: 0
#0	bar (file:///.../sdk/throws.dart:2)
#1	foo (file:///.../sdk/throws.dart:5)
#2	main (file:///.../sdk/throws.dart:7)
#3	_startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307)
#4	_RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174)

# Saving all output to the file "output.txt".
$ out/ReleaseX64/dart_precompiled_runtime dwarf_snapshot.so >output.txt 2>&1

# Reading the input to convert from the file "output.txt" instead of stdin.
$ out/ReleaseX64/dart pkg/native_stack_traces/bin/decode.dart -e debug.data -i output.txt
Unhandled exception:
Throw of null.
Warning: This VM has been configured to produce stack traces that violate the Dart standard.
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 159139, tid: 139991440654400, name Dart_Initialize
isolate_instructions: 7f524b090000 vm_instructions: 0
#0	bar (file:///.../sdk/throws.dart:2)
#1	foo (file:///.../sdk/throws.dart:5)
#2	main (file:///.../sdk/throws.dart:7)
#3	_startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307)
#4	_RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174)

# Output the converted input to the file "converted.txt" instead of stdout.
$ out/ReleaseX64/dart pkg/native_stack_traces/bin/decode.dart -e debug.data -i output.txt -o converted.txt

$ cat converted.txt
Unhandled exception:
Throw of null.
Warning: This VM has been configured to produce stack traces that violate the Dart standard.
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 159139, tid: 139991440654400, name Dart_Initialize
isolate_instructions: 7f524b090000 vm_instructions: 0
#0	bar (file:///.../sdk/throws.dart:2)
#1	foo (file:///.../sdk/throws.dart:5)
#2	main (file:///.../sdk/throws.dart:7)
#3	_startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:307)
#4	_RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:174)
```

> **Note**: As seen here, only lines that contain stack trace frames are
> converted. In particular, we do not strip the extra stack trace header lines
> that are only part of DWARF-based stack traces.

### Using the stack trace converter libraries

This section describes two different libraries used to retrieve and convert
information associated with DWARF-based stack traces:

* `package:vm/dwarf/dwarf.dart`, for 'Dwarf' and 'CallInfo' objects
* `package:vm/dwarf/convert.dart`, for `PCOffset` objects and various operations on stack traces

#### DWARF debugging information

A `Dwarf` object represents the DWARF debugging information from either
unstripped ELF snapshots or a file generated by `--save-debugging-info=<...>`.

The `Dwarf.fromFile` factory takes a filename and returns a 'Dwarf' object,
if the given file exists and is a recognized format that contains DWARF
information.

#### Call site information

A `CallInfo` object represents a call site in the code corresponding to a
particular virtual address and contains the function name, file name, and line
number for the call site and whether the code for the call site has been
inlined at this use.

To look up the call information associated with a particular virtual address,
use `Dwarf::callInfo`. If the virtual address is outside the range of those
generated by the DWARF line number program(s), then it returns `null`, otherwise
it returns an iterable of `CallInfo` objects. If the optional
`includeInternalFrames` argument is false (the default), then the iterable can
be empty if the virtual address points to code that does not correspond to
user or library code, like generated function prologues.

#### Converting stack traces

To convert a stream of lines that may include DWARF stack traces, use
the stack transformer `DwarfStackTraceDecoder`. Its constructor takes a `Dwarf`
object, and the transformer, like `decode.dart` from the package [native_stack_traces](https://pub.dev/packages/native_stack_traces), only changes
lines that correspond to stack trace frames.

> **Note**: The stack transformer assumes that lines are not combined or broken
> across `String`s in the input stream. If this is not already guaranteed,
> transform the stream with `LineSplitter` from `dart:convert` prior to
> transforming it with a `DwarfStackTraceDecoder`.

#### Extracting information from stack traces

A `PCOffset` object represents the PC address information extracted from a
DWARF-based stack trace frame. It contains whether the PC address comes from
the VM or isolate instructions section, and the offset of the PC address in
that section.

The `PCOffset::virtualAddress` method takes a `Dwarf` object and returns
a compatible virtual address for use with methods on that `Dwarf` object.

The function `collectPCOffsets` extracts `PCOffset`s for the frames of a stack
trace.

> **Note**: Since the absolute addresses of the VM and isolate instruction
> sections are part of the stack frame header, `collectPCOffsets` can only
> extract information from _complete_ stack traces.
