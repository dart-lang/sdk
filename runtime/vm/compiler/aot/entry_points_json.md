
# Entry points file format

Dart VM precompiler (AOT compiler) performs whole-program optimizations such as
tree shaking in order to decrease size of the resulting compiled apps and
improve their performance. Such optimizations assume that compiler can see
the whole Dart program, and is able to discover and analyze all Dart functions
and members which can be potentially executed at run time. While the Dart code
is fully available for precompiler, native code of the embedder and native
methods are out of reach of the compiler. Such native code can call back to
Dart via native Dart API.

In order to aid precompiler, programmer can explicitly list entry
points (roots) - Dart classes and members which are accessed from native code.
Note that listing entry points is not optional: as long as program defines
native methods which call into Dart, the entry points are required for the
correctness of compilation.

This memo describes _new_ format of entry points file, which is intended to
replace old comma-separated lists of entry points. At the time of writing,
new format is not fully adopted yet. 

The native entry points are described in a JSON text file. The descriptor has the form

```json
{
 "roots": [
    <root1>,
    ...
    <rootN>
  ],

  “native-methods”: {
    “<native1_name>” : [
      <native1_root1>,
      ...
      <native1_rootM1>,
    ],

    ...

    “<nativeK_name>” : [
      <nativeK_root1>,
      ...
      <nativeK_rootMK>,
    ]
  }
```

## "roots" element

The “roots” element describes entry points which can be accessed by arbitrary native code.
Each root has the following elements:

```json
{
 "library": "<library URI>",
 "class": "<class name>",
 "name": "<member name>",
 "action": "<action>"
}
```

| Element | Meaning                                   | Can be omitted                     |
| ------- | ----------------------------------------- | ---------------------------------- |
| library | Library URI of the entry point.           | No.                                |
| class   | Dart class name.                          | Omitted for top-level functions.   |
| name    | Dart function name or member name.        | Omitted for class-related actions. |
| action  | Specifies kind of the entry point access. | Depends on the entry point.        |


The following actions are supported:
* _"create-instance"_ - native code creates an instance of given Dart class.
* _"call"_ - native code calls given Dart function or member.
* _"get"_ - native code calls given getter or retrieves value of a given field.
* _“set”_ - native code calls given setter or sets value to a given field.

If action element is omitted, the following actions are assumed by default:
* For classes - “create-instance”.
* For fields - both “get” and “set” (only “get” if a field is final).
* For others - “call”.

If needed, the description of an entry point can be extended by supporting
more elements or actions.

## “native-methods” element

The “native-methods” section contains description of entry points accessed from
specific native methods. It can be used to declare behavior of a native method
more accurately.
Each element in “native-methods” section is identified by the native name - the
name specified after the native clause in the Dart method or function declaration.

Native method descriptor may contain arbitrary number of entry points.
In addition to the declaration of entry points described above, native methods
may contain the root with the action “return”, which describes the specific
concrete type of a Dart instance returned from the native method:

```json
{
 "action": "return",
 "library": "<library URI>",
 "class": "<class name>",
 "nullable": "false|true"
}
```

“nullable” attribute may be omitted defaulting to “true”.
If “nullable” is “true” (or omitted), then native method can return an instance
of the given class or null.
