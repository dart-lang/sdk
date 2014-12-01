library http_mock;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers =
      new HashMap<String, List<String>>();

  operator[](key) => _headers[key];

  int get contentLength => int.parse(_headers[HttpHeaders.CONTENT_LENGTH][0]);

  DateTime get ifModifiedSince {
    List<String> values = _headers[HttpHeaders.IF_MODIFIED_SINCE];
    if (values != null) {
      try {
        return HttpDate.parse(values[0]);
      } on Exception catch (e) {
        return null;
      }
    }
    return null;
  }

  void set ifModifiedSince(DateTime ifModifiedSince) {
    // Format "ifModifiedSince" header with date in Greenwich Mean Time (GMT).
    String formatted = HttpDate.format(ifModifiedSince.toUtc());
    _set(HttpHeaders.IF_MODIFIED_SINCE, formatted);
  }

  ContentType contentType;

  void set(String name, Object value) {
    name = name.toLowerCase();
    _headers.remove(name);
    _addAll(name, value);
  }

  String value(String name) {
    name = name.toLowerCase();
    List<String> values = _headers[name];
    if (values == null) return null;
    if (values.length > 1) {
      throw new HttpException("More than one value for header $name");
    }
    return values[0];
  }

  String toString() => '$runtimeType : $_headers';

  // [name] must be a lower-case version of the name.
  void _add(String name, value) {
    if (name == HttpHeaders.IF_MODIFIED_SINCE) {
      if (value is DateTime) {
        ifModifiedSince = value;
      } else if (value is String) {
        _set(HttpHeaders.IF_MODIFIED_SINCE, value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else {
      _addValue(name, value);
    }
  }

  void _addAll(String name, value) {
    if (value is List) {
      for (int i = 0; i < value.length; i++) {
        _add(name, value[i]);
      }
    } else {
      _add(name, value);
    }
  }

  void _addValue(String name, Object value) {
    List<String> values = _headers[name];
    if (values == null) {
      values = new List<String>();
      _headers[name] = values;
    }
    if (value is DateTime) {
      values.add(HttpDate.format(value));
    } else {
      values.add(value.toString());
    }
  }

  void _set(String name, String value) {
    assert(name == name.toLowerCase());
    List<String> values = new List<String>();
    _headers[name] = values;
    values.add(value);
  }

  /*
   * Implemented to remove editor warnings
   */
  dynamic noSuchMethod(Invocation invocation) {
    print([invocation.memberName,
           invocation.isGetter,
           invocation.isSetter,
           invocation.isMethod,
           invocation.isAccessor]);
    return super.noSuchMethod(invocation);
  }
}

class MockHttpRequest implements HttpRequest {
  final Uri uri;
  final MockHttpResponse response = new MockHttpResponse();
  final HttpHeaders headers = new MockHttpHeaders();
  final String method = 'GET';
  final bool followRedirects;

  MockHttpRequest(this.uri, {this.followRedirects: true,
      DateTime ifModifiedSince}) {
    if(ifModifiedSince != null) {
      headers.ifModifiedSince = ifModifiedSince;
    }
  }

  /*
   * Implemented to remove editor warnings
   */
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class MockHttpResponse implements HttpResponse {
  final HttpHeaders headers = new MockHttpHeaders();
  final Completer _completer = new Completer();
  final List<int> _buffer = new List<int>();
  String _reasonPhrase;
  Future _doneFuture;

  MockHttpResponse() {
    _doneFuture = _completer.future
        .whenComplete(() {
          assert(!_isDone);
          _isDone = true;
        });
  }

  bool _isDone = false;

  int statusCode = HttpStatus.OK;

  String get reasonPhrase => _findReasonPhrase(statusCode);

  void set reasonPhrase(String value) {
    _reasonPhrase = value;
  }

  Future get done => _doneFuture;

  Future close() {
    _completer.complete();
    return _doneFuture;
  }

  void add(List<int> data) {
    _buffer.addAll(data);
  }

  void addError(error, [StackTrace stackTrace]) {
    // doesn't seem to be hit...hmm...
  }

  Future redirect(Uri location, {int status: HttpStatus.MOVED_TEMPORARILY}) {
    this.statusCode = status;
    headers.set(HttpHeaders.LOCATION, location.toString());
    return close();
  }

  void write(Object obj) {
    var str = obj.toString();
    add(UTF8.encode(str));
  }

  /*
   * Implemented to remove editor warnings
   */
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);

  String get mockContent => UTF8.decode(_buffer);

  List<int> get mockContentBinary => _buffer;

  bool get mockDone => _isDone;

  // Copied from SDK http_impl.dart @ 845 on 2014-01-05
  // TODO: file an SDK bug to expose this on HttpStatus in some way
  String _findReasonPhrase(int statusCode) {
    if (_reasonPhrase != null) {
      return _reasonPhrase;
    }

    switch (statusCode) {
      case HttpStatus.NOT_FOUND: return "Not Found";
      default: return "Status $statusCode";
    }
  }
}
