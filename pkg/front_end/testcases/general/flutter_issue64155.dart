// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin TestMixin<R, T> {
  Future<T> test(Future<R> fetch) async {
    final response = await fetch;
    T result;
    if (response is Response) {
      result = response.data;
    } else if (response is PagingResponse) {
      result = response.data.data as T;
    } else if (response is T) {
      result = response;
    } else {
      throw Exception('Invalid response type');
    }
    return result;
  }
}

class PagingResponse<T> {
  final PagingResponseData<T> data;

  PagingResponse(this.data);
}

class PagingResponseData<T> {
  final List<T> data;

  PagingResponseData(this.data);
}

class Response<T> {
  final T data;
  Response(this.data);
}

class Class1 with TestMixin<Response<String>, String> {
  _test() {
    final response = Response<String>('test');
    test(Future.value(response));
  }
}

class Class2 with TestMixin<PagingResponse<String>, String> {
  _test() {
    final response = PagingResponse<String>(PagingResponseData(['test']));
    test(Future.value(response));
  }
}

main() {}
