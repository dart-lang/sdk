## Obtaining a heapsnapshot

There's several ways one can obtain a heapsnapshot

### Obtain snapshot from live VM

One can use existing tools (e.g. observatory / DevTools) to load & save a
heapsnapshot.

For convenience there's also a `bin/download.dart` script in
`package:heapsnapshot` that can be given an URL to a live VM and it will fetch a
heapsnapshot.

### Programmatically

Note: enabled for debug and release Dart build modes, but not for product mode.

It's possible to programmatically dump a heapsnapshot to a file by using a
`dart:developer` API:
```
import 'dart:developer';

foo() {
  ...
  // Will dump the heapsnapshot at a specific place in program execution.
  // Allows very precise analysis of what data is live at a particular place.
  NativeRuntime.writeHeapSnapshotToFile('dump.heapsnapshot');
  ...
}
```

## CLI Usage:

### Loading a snapshot

After launching `bin/explore.dart` one has to load a heapsnapshot before doing
anything else. This can be done with the `load` command. It will auto-complete
directories and any file with the `.heapsnapshot` extension.

```
# Load
load <file>
```

### Finding all live objects
```
# Find all live objects by finding transitive closure of roots.
# We assign to a `all` variable for later usage.
all = closure roots
```

### Show known sets of objects

```
# Show named sets / known variables
info
```

### Show statistics of objects

To examine how many objects there are per class and how large they are one can
use the `stats` command:

```
stats all
```

### Example usage session

```
# Filter lists from "all" into "lists"
lists = filter all _List

# Find empty lists into "empty-lists"
empty-lists = dfilter lists ==0

# Who's using the empty lists?
users empty-lists

# print that info (from $0 in this case as we didn't give it a name but it was
# the first one we didn't give a name)
stat $0

# Filter more
empty-growable-lists = filter (users empty-lists) _GrowableList

# Print
stats empty-growable-lists

# Who's using them?
retainers empty-growable-lists

# Look into strings next
strings = filter all String

# What's inside the strings
dstats strings

# Who's pointing to the big strings?
retainers (dfilter strings >=1024)

# Small strings
small-strings = dfilter strings <100

# See them
dstats small-strings

# Who's retaining the string "foo"
f = dfilter small-strings foo
retainters f

# Find stuff with specific field
hasField = filter all :specificField
stats closure hasField :specificField
foo = follow hasField :specificField
stats closure foo

# Stop the closure search if going into specific files
stats closure foo ^file1.dart ^file2.dart ^file3.dart
```
