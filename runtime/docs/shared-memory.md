# Shared memory

https://github.com/dart-lang/language/blob/main/working/333%20-%20shared%20memory%20multithreading/proposal.md provided a framework for adding shared memory support to applications running on dart vm.

First, support for `pragma("vm:shared")` was added, which could be put on static fields. Static fields
decorated with such pragma become shared by all isolates in isolate group.

