## used_names.html

To run this program, visit
[`pkg/compiler/tool/used_names/used_names.html`](used_names.html) in a browser.

The page will display a list of short names that are defined as properties on
all the objects available from `window`. The names are sorted by size, and then
alphabetically ignoring case, and finally by case. They are quoted for easy
copy-paste into a Dart source file.

This data is to be used for editing tables of names that the minifying namer
should avoid in some circumstances.  These names should be in the table, but
other names might need to be in the table too.

### Why these names?

There are contexts where dart2js generates `a.b()` with the expectation that it
will either call an instance method in the Dart program or crash with a
JavaScript TypeError for an undefined function. The minifier code can't use
certain names for `b` since it won't crash, for example `toString`, or `length`,
which might result in a less clear diagnostic.

An example of this use is in dynamic calls to methods that do not need the
special 'interceptor' calling convention used on native objects like Arrays,
Strings, numbers and @Native classes. Dynamic calls use the same selector as
instance calls.

In unminified code we arrange that the selectors are descriptive of the call
site structure, e.g. `toString$0` or `get$length`. These generally are not
defined in the execution environment.

For minified code, we want to pick names as short as possible, so there is a
chance that the short names will conflict with one defined in the environment.
For example, minifying something to `a.at()` might call `String.prototype.at`.

### Discussion

In retrospect the decision to use names that Dart has no control over is not the
best. When this part of the compiler was written, the language was still very
dynamic (Dart 1) and there were very few program that extensively used
JavaScript interop.

Now that typical programs contain many fewer dynamic calls, perhaps it is time
to make the calling convention for dynamic call different to that for instance
method calls. One idea is we could start by making dynamic calls have a
different selector. This selector would eventually be a fully-checked entry
point, but initially it could just be an alias for the instance-call entry
point. The alias could be a JavaScript Symbol, or for legacy browsers, always
start with `dyn$`, even when minified.



