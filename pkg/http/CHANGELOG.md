## 0.10.0

* Make `BaseRequest.contentLength` and `BaseResponse.contentLength` use `null`
  to indicate an unknown content length rather than -1.

* The `contentLength` parameter to `new BaseResponse` is now named rather than
  positional.

* Make request headers case-insensitive.
