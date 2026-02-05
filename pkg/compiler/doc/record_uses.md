# Recorded Uses

Tree-shaking can cause APIs and resources to be removed from programs.  We
developed a mechanism in dart2js to help developers understand what resources
are still in use after an application is optimized.

## Status

(experimental, in progress)

Currently we have a mechanism that only supports tracking static member
functions. It is not rich enough to track the use of resource classes or
constants, like `IconData` in flutter applications. That would be an ideal
expansion in the future.

## How it works

Developers can annotate top-level functions or methods with `RecordUse` from
`package:record_use`. This annotation signals to `dart2js` that the annotated
member is a resource that needs to be tracked.

Example:
```dart
import 'package:record_use/record_use.dart';

@RecordUse()
void myTopLevelMethod() {
  // ... resource usage ...
}
```

When providing dart2js with the experimental `--write-resources` flag, the
compiler will emit a `.resources.json` file. This file lists whether any
top-level methods annotated with the special pragma was invoked in the program.
It will also include some additional static information, like the source
location of the call, or even which parameters where provided (if the parameters
are constant).

Only calls in reachable code (executable code) are tracked. Calls appearing
within metadata (annotations) are ignored.

### Example output

Example outputs can be found in [pkg/vm/testcases/transformations/record_use/](
../../../pkg/vm/testcases/transformations/record_use/), and can be read with
`package:record_use`.
