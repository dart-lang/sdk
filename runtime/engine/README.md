# Dart Engine

The `include/dart_engine.h` provides additional functions to embed the Dart VM
and to call Dart functions from kernel and AOT snapshots. It is not intended to
be a full-featured API, and should be used together with `dart_api.h`.

It is intended for reusing of existing Dart code in non-Dart programs, and
allows to use Dart snapshots as shared libraries: the caller can start one or
several isolates from Dart snapshots and call Dart functions from it.

Comparing to `dart_api.h` it brings the following:

- Full initialization of Dart VM, including initializing core libraries.
- Easier handling of isolate messages
- Lock-guarded functions to enter/exit isolates.

See examples in `samples/embedder` for usages of the API.

## Handling isolate messages

In `dart_api.h` there are two possible ways to handle asynchronous
isolate messages:

- `Dart_MessageNotifyCallback`: Users can pass a callback to get
  notifications about messages to handle, but handling messages still
  requires entering an isolate, entering a scope, calling
  `Dart_HandleMessage`, and then leaving a scope and an isolate.
- `Dart_RunLoop`: Users can invoke it on a separate thread, but then they won't
  be able to enter isolates from other threads.

As an alternative, `dart_engine.h` provides a simpler function
`DartEngine_HandleMessage`, which encapsulates isolate and scope management, and
it allows to specify per isolate / default message schedulers, which only need
to schedule an execution `DartEngine_HandleMessage` with the right isolate.

Users can create their own `DartEngine_MessageScheduler` struct and pass it to
`DartEngine_SetMessageScheduler` / `DartEngine_SetDefaultMessageScheduler`. See
`samples/embedder/run_timer_async.cc` and `samples/embedder/run_timer.cc`
examples.

## Entering / leaving isolates

Because engine API uses its own message handling, it is important to use
`DartEngine_AcquireIsolate` / `DartEngine_ReleaseIsolate` instead of
`Dart_EnterIsolate` / `Dart_ExitIsolate`. `DartEngine_AcquireIsolate` blocks
until an isolate can be entered by trying to obtain an internal lock (which is
released by `DartEngine_ReleaseIsolate`), while `Dart_EnterIsolate` crashes if
some other thread has entered the same isolate.
