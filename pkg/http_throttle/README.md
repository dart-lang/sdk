`http_throttle` is middleware for the [http package][] that throttles the number
of concurrent requests that an HTTP client can make.

```dart
// This client allows 32 concurrent requests.
final client = new ThrottleClient(32);

Future<List<String>> readAllUrls(Iterable<Uri> urls) {
  return Future.wait(urls.map((url) {
    // You can safely call as many client methods as you want concurrently, and
    // ThrottleClient will ensure that only 32 underlying HTTP requests will be
    // open at once.
    return client.read(url);
  }));
}
```

[http package]: pub.dartlang.org/packages/http
