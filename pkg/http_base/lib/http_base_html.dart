library http_base.http_base_html;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'http_base.dart';
export 'http_base.dart';

/// The following headers will be blocked by browsers. See:
/// http://www.w3.org/TR/XMLHttpRequest/
const List<String> _BLOCKED_HEADERS = const [
    'accept-charset', 'accept-encoding', 'access-control-request-headers',
    'access-control-request-method', 'connection', 'content-length', 'cookie',
    'cookie2', 'date', 'dnt', 'expect', 'host', 'keep-alive', 'origin',
    'referer', 'te', 'trailer', 'transfer-encoding', 'upgrade', 'user-agent',
    'via'];

/// An implementation for [RequestHandler]. It uses dart:html to make http
/// requests.
class Client {
  Future<Response> call(Request request) {
    return _bufferData(request.read()).then((Uint8List data) {
      var url = request.url.toString();
      return _request(url, request.method, request.headers, data).then((xhr) {
        var headers = HeadersImpl.Empty.replace(xhr.responseHeaders);
        var body = _readResponse(xhr);
        return new ResponseImpl(xhr.status, headers: headers, body: body);
      });
    });
  }

  Future<Uint8List> _bufferData(Stream<List<int>> stream) {
    int size = 0;

    return stream.fold([], (buffer, data) {
      size += data.length;
      return buffer..add(data);
    }).then((List<List<int>> buffer) {
      if (size > 0) {
        var data;
        if (buffer.length == 0 && buffer[0] is Uint8List) {
          data = buffer[0];
        } else {
          data = new Uint8List(size);
          int offset = 0;
          for (var bytes in buffer) {
            var end = offset + bytes.length;
            data.setRange(offset, end, bytes);
            offset = end;
          }
        }
        return data;
      }
      return null;
    });
  }

  Future<HttpRequest> _request(String url,
                               String method,
                               Headers headers,
                               Uint8List sendData) {
    var completer = new Completer<HttpRequest>();

    var xhr = new HttpRequest();
    xhr.open(method, url, async: true);

    // Maybe we should use 'arraybuffer' instead?
    xhr.responseType = 'blob';

    // TODO: Special case Cookie/Set-Cookie here!
    for (var name in headers.names) {
      xhr.setRequestHeader(name, headers[name]);
    }

    xhr.onLoad.first.then((_) => completer.complete(xhr));
    xhr.onError.first.then(completer.completeError);
    xhr.send(sendData);

    return completer.future;
  }

  Stream<List<int>> _readResponse(HttpRequest request) {
    var controller = new StreamController<List<int>>();

    var data = request.response;
    assert (data is Blob);

    var reader = new FileReader();
    reader.onLoad.first.then((_) {
      controller.add(reader.result);
      controller.close();
    });
    reader.readAsArrayBuffer(data);

    return controller.stream;
  }
}
