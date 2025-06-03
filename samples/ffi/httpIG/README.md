This is an example that shows how to use `NativeCallable.listener` to interact
with a multi threaded native API.

The native API is a fake HTTP library with some hard coded requests and
responses. To build the dynamic library, run this command:

```bash
c++ -shared -fpic lib/fake_http.cc -lstdc++ -o lib/libfake_http.so
```

On Windows the output library should be `lib/fake_http.dll` and on Mac it should
be `lib/libfake_http.dylib`.
