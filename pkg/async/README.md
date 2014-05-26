The `async` package will contain tools to work with asynchronous computations.

The package contains sub-libraries with different utilities.

### Zipping streams

The "stream_zip.dart" sub-library contains functionality
to combine several streams of events into a single stream of tuples of events.

### Results
The "result.dart" sub-library introduces a `Result` class that can hold either
a value or an error.
It allows capturing an asynchronous computation which can give either a value
or an error, into an asynchronous computation that always gives a `Result`
value, where errors can be treated as data.
It also allows releasing the `Result` back into an asynchronous computation.

### History.
This package is unrelated to the discontinued `async` package with version 0.1.7.
