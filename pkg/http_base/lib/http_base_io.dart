library http_base.http_base_io;

import 'dart:io' as io;
import 'dart:async';

import 'http_base.dart';
export 'http_base.dart';

/// An implementation for [RequestHandler]. It uses dart:io to make http
/// requests.
class Client {
  // TODO: Should we provide a mechanism to close (forcefully or not) [_client]?
  final io.HttpClient _client = new io.HttpClient();

  Future<Response> call(Request request) {
   return _client.openUrl(request.method, request.url).then((ioRequest) {
     // TODO: Special case Cookie/Set-Cookie here!

     for (var name in request.headers.names) {
       ioRequest.headers.set(name, request.headers[name]);
     }

     var stream = request.read();
     return ioRequest.addStream(stream).then((_) {
       return ioRequest.close();
     });
   }).then((io.HttpClientResponse ioResponse) {
     var headerMap = {};
     ioResponse.headers.forEach((name, values) {
       headerMap[name] = values;
     });
     var headers = new HeadersImpl(headerMap);

     return new ResponseImpl(
         ioResponse.statusCode, headers: headers, body: ioResponse);
   });
  }
}
