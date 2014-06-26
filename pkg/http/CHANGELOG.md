## 0.11.1+2

* Widen the version constraint on `unittest`.

## 0.11.1+1

* Widen the version constraint for `stack_trace`.

## 0.11.1

* Expose the `IOClient` class which wraps a `dart:io` `HttpClient`.

## 0.11.0+1

* Fix a bug in handling errors in decoding XMLHttpRequest responses for
  `BrowserClient`.

## 0.11.0

* The package no longer depends on `dart:io`. The `BrowserClient` class in
  `package:http/browser_client.dart` can now be used to make requests on the
  browser.

* Change `MultipartFile.contentType` from `dart:io`'s `ContentType` type to
  `http_parser`'s `MediaType` type.

* Exceptions are now of type `ClientException` rather than `dart:io`'s
  `HttpException`.

## 0.10.0

* Make `BaseRequest.contentLength` and `BaseResponse.contentLength` use `null`
  to indicate an unknown content length rather than -1.

* The `contentLength` parameter to `new BaseResponse` is now named rather than
  positional.

* Make request headers case-insensitive.

* Make `MultipartRequest` more closely adhere to browsers' encoding conventions.
