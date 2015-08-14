# Dart2js Info

This package contains the definition of the information that dart2js produces
when you pass the `--dump-info` flag. It also contains tools that you can use to
process that information to better the information.

Currently, most information is related to code-size and how much of the size of
your output program is attributed to different parts of the source application.

With time, we expect to have more information about type inference that can help
developers understand why dart2js wasn't able to tree-shake some part of the
code.

This package is evolving and rapidly changing.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/dart2js_info/issues
