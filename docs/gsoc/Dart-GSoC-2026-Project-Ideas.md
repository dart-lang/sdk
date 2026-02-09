> [!info]
> **Google Summer of Code 2026 is currently accepting applications until March 31st, 2026.**

The list of accepted projects will be announced on [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/organizations/).

📌 See the [official timeline](https://developers.google.com/open-source/gsoc/timeline) for more details.
------

A list of Google Summer of Code project ideas for Dart.

For GSoC related discussions please use the [dart-gsoc group](https://groups.google.com/forum/#!forum/dart-gsoc).

**Potential mentors**
 * Jonas Jensen ([jonasfj](https://github.com/jonasfj)) `jonasfj@google.com`
 * Daco Harkes ([dcharkes](https://github.com/dcharkes)) `dacoharkes@google.com`
 * Liam Appelbe ([liamappelbe](https://github.com/liamappelbe)) `liama@google.com`
 * Brian Quinlan ([bquinlan](https://github.com/brianquinlan)) `bquinlan@google.com`
 * Ben Konyi ([bkonyi](https://github.com/bkonyi)) `bkonyi@google.com`
 * More to come!

## Project Application Process
All projects assume familiarity with Dart (and sometimes Flutter). Aspiring applicants are encouraged to [learn Dart](https://dart.dev/guides/language/language-tour) and try to write some code.

Applicants are welcome to find and fix bugs in [Dart](https://github.com/dart-lang/sdk) or some of the [packages written by the Dart team](https://pub.dev/publishers/dart.dev/packages). However, getting reviews can take a long time as code owners may be busy working on new features. So instead of requiring applicants to fix a _good first bug_, we
suggest that applicants write a working code sample relevant for the proposed project.

The code sample can be attached to the application as a [**secret** gist](https://gist.github.com/) (please use _secret gists_, and do not share these with other applicants). Suggested ideas below includes proposed "Good Sample Projects".

**Do not spend too much energy on this piece of sample code**, we just want to see
that you can code something relevant -- and that this sample code can run and do something non-trivial. Be aware that we have a limited number of
mentors available, and will only be able to accept a few applicants.

Applications can be submitted through the [summerofcode.withgoogle.com](https://summerofcode.withgoogle.com/) website. Applicants are encouraged to submit draft proposals, linking to Google Docs with permission for mentors to comment. See also the [contributor guide](https://google.github.io/gsocguides/student/writing-a-proposal) on writing a proposal.

**IMPORTANT**: Remember to submit _final proposals_ before [the March 31st deadline](https://developers.google.com/open-source/gsoc/timeline).

## **Idea:** Inspect native memory in Dart DevTools

 - **Possible Mentor(s)**: `dacoharkes@google.com`, `bkonyi@google.com`
 - **Difficulty**: Hard
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, C++

**Description**:
When using the Dart debugger on `Pointer<X>` (where `X` extends `Struct` or `Union` or is a native type), the pointer itself is opaque. It would be extremely useful if the debugger could inspect the memory that the `Pointer` points to, effectively making `.ref` available as an inspectable getter.

For example, when debugging the following code:
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class MyStruct extends Struct {
  @Int32()
  external int a;
  @Double()
  external double b;
}

void main() {
  final ptr = malloc<MyStruct>();
  ptr.ref.a = 42;
  ptr.ref.b = 3.14;
  // Inspecting 'ptr' in the debugger should allow seeing 'a' and 'b'
  // (either via the binary layout or a higher-level abstraction).
  malloc.free(ptr);
}
```
Currently, `ptr` only shows its memory address in the debugger.

However, dereferencing invalid pointers leads to segmentation faults. While `nullptr` (address 0) is easy to check, user-created pointers might point to invalid memory, and dereferencing them during a debug session should not crash the application.

This project involves:
1.  **Exploring UI integration**: We'd want to explore different ways of exposing native memory in the developer tools:
    *   Updating Dart DevTools and the [Debug Adapter Protocol (DAP)](https://microsoft.github.io/debug-adapter-protocol/) to handle a new `Instance` type for `Pointer` so they are displayed properly across IDEs without an extension.
    *   Extending the **Object Inspector** (found under the **VM Tools** tab in DevTools).
2.  **VM Service Protocol**: Extend the protocol to provide access to `Struct`/`Union` layout and annotations if not already available.
3.  **VM Runtime**: Implement a mechanism in the Dart VM to safely dereference pointers during debugging. This likely means intercepting segmentation faults (signals) during these specific read operations and converting them into a virtual exception or error message that the debugger can display, rather than crashing the process.

**Good Sample Project**:
Create a standalone Flutter app that demonstrates a custom view for a `Pointer`.
*   The view should take a `Pointer` object (or a mock of one), compute the size of the data structure (the `X` in `Pointer<X>`), and display the memory contents. For the sample, you can assume valid pointers or mock the data retrieval to avoid crashes. **Bonus**: Implement this custom view directly in the [DevTools codebase](https://github.com/flutter/devtools) (e.g. in the Object Inspector) rather than as a standalone app.
*   **Standout**: Add a new method or property to the VM Service Protocol (requires building the Dart SDK) and use this new protocol feature in your sample application.

**Expected outcome**:
A working feature in Dart DevTools (and underlying VM support) that allows
developers to inspect the contents of `Pointer`s safely during debugging.

**Further reading**:

* [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md)
* [Dart Debug Adapter Protocol](https://github.com/dart-lang/sdk/blob/main/third_party/pkg/dap/tool/README.md)
* [Dart DevTools source code](https://github.com/flutter/devtools)
* https://github.com/dart-lang/sdk/issues/48882
* https://github.com/dart-lang/native/issues/1034



## **Idea:** C++ in FFIgen

 - **Possible Mentor(s)**: Liam Appelbe, Brian Quinlan
 - **Difficulty**: Medium
 - **Project size**: Large (350 hours)
 - **Skills**: Dart, C++

**Description**:

C++ doesn't have a stable ABI (for example, it varies by compiler), so we can't directly interop with it. However, it would be possible to parse a C++ API, code-gen C compatible bindings for the API (using `extern "C"`), then generate Dart bindings that look like the C++ API, but actually invoke the C glue code.

```
Input       Output          Output
C++ API <-> C glue code <-> Dart bindings
```

The goal of this project is to add C++ as a new experimental language in FFIgen. FFIgen already uses libclang to parse C/ObjC APIs, so the parsing logic just needs to be extended to parse C++ APIs. Then the AST needs to be extended to be able to represent C++ language features. Finally, the code generator needs to be extended to support generating C code to wrap the C++ API, and Dart code to interact with the C API.

A good proposal for this project will explore the various language features of C++, describe how that feature can be most closely represented in Dart, and what the C glue code looks like to support that feature. The more language features we can translate, the better the final product will be.

A good sample project would be to add parsing logic to FFIgen to parse some simple C++ feature, such as a class with methods. Don't worry about code gen or representing the class in the AST yet, just write the parsing logic and print out some info about the class and its methods.

Tracking bug: [https://github.com/dart-lang/native/issues/2644](https://github.com/dart-lang/native/issues/2644)  


## **Idea:** Migrate Intellij Plugins off weberknecht web socket library

 - **Possible Mentor(s)**: Phil Quitslund, Helin Shiah
 - **Difficulty**: Medium
 - **Project size**: Medium (175 hours)
 - **Skills**: Kotlin

**Description**:

The current implementation of websocket connections in Intellij is out of date and conflicts with certain Anti-Virus software on Windows PCs. This needs to be updated to a more modern library and tested on various development platforms.

Tracking bug: https://github.com/flutter/dart-intellij-third-party/issues/208

## **Idea:** Prototype New Dart IntelliJ plugin using LSP for Analysis Server Connection

 - **Possible Mentor(s)**: Phil Quitslund, Helin Shiah
 - **Difficulty**: Medium
 - **Project size**: Large (350 hours)
 - **Skills**: Kotlin

**Description**:

The Dart plugin communicates with the analysis server with a legacy custom protocol, but migrating to language server protocol (LSP) would enable more language analysis features for IntelliJ/Android Studio users with less IntelliJ-specific code.

Related to: https://github.com/flutter/dart-intellij-third-party/issues/207


## **Idea:** Add WebSocket/GRPC Support to Flutter DevTools Network panel

 - **Possible Mentor(s)**: Elliott Brooks, Samuel Rawlins
 - **Difficulty**: Medium
 - **Project size**: Medium (175 hours)
 - **Skills**: Dart, Flutter

**Description**:

The network panel on Flutter DevTools currently only supports HTTP connections, but many developers use other types of connections between their applications and back end services. Adding support for these would dramatically increase the effectiveness of the network panel for developers.




## TODO: More ideas as they come!

# Template:

Copy this template.

## **Idea:** ...

 - **Possible Mentor(s)**:
 - **Difficulty**: Easy / Hard
 - **Project size**: Small (90) / Medium (175 hours) / Large (350 hours)
 - **Skills**: ...

**Description**: ...

**Good Sample Project**: ...

**Expected outcome**: ...
