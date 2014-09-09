Pub is currently dogfooding the new Dart async/await syntax. Since the Dart VM
doesn't natively support it yet, we are using the [async-await][] compiler
package.

[async-await]: https://github.com/dart-lang/async_await

We run that to compile pub-using-await from sdk/lib/_internal/pub down to
vanilla Dart code which is what you see here. To interoperate more easily with
the rest of the repositry, we check in that generated code.

When bug #104 is fixed, we can remove this entirely.

The code here was compiled using the async-await compiler at commit:

    6228072d2a3fd87d6d4e8b147853c74486fdb581

(Note: this file is also parsed by a tool to update the above commit, so be
careful not to reformat it.)
