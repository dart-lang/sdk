## 0.11.0

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
