☠☠ **Warning: This package is experimental and may be removed in a future
version of Dart.** ☠☠

`dart2js` can generate extra code to measure certain activities.
This library provides access to the measurements at runtime.

An application might make timings and other measurements and report them back to
a server in order to collect information on how the application is working in
production. The APIs in this library provide access to measurements that require
help from dart2js. For example, `startupMetrics` accesses measurements of
activities that happen as the program is loaded, before `main()`.

The APIs are stubbed so that dummy values are returned on the VM and dartdevc.
