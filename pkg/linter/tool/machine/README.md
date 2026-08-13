# Generated inter rule information

> [!WARNING]
> The `rules.json` file is unsupported and deprecated,
> and should **not** be relied on.

The [`rules.json`](rules.json) is generated from lint information in
the rule source files as well as the `pkg/linter/messages.yaml` file.
It is primarily used by the `dart.dev` website.

To update the `rules.json` file, run:

```
dart run pkg/linter/tool/machine/machine.dart -w
```

## Deprecation and replacement

The `rules.json` file is unsupported and deprecated,
and should not be used nor should its contents be relied on.
In the future, it will stop receiving updates and
will be removed without notice.

If you need a list of all available and stable lint rules,
you can reference [dart.dev/lints/all](https://dart.dev/lints/all).
[dart.dev/lints](https://dart.dev/lints) has details about each lint rule,
including deprecated, removed, and experimental rules.

Some of the information in the `rules.json` file
is instead available in the `pkg/linter/messages.yaml` file.
However, the `messages.yaml` file is subject to change
and is not guaranteed to be stable.
To follow along and provide feedback on this transition,
check out [SDK issue #56835](https://github.com/dart-lang/sdk/issues/56835).
