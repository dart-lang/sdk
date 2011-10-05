// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestEvents extends Events {
  EventListenerList get abort();
  EventListenerList get error();
  EventListenerList get load();
  EventListenerList get loadStart();
  EventListenerList get progress();
  EventListenerList get readyStateChange();
}

interface XMLHttpRequest extends EventTarget factory XMLHttpRequestWrappingImplementation {
  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  XMLHttpRequest();

  // TODO(rnystrom): This name should just be "get" which is valid in Dart, but
  // not correctly implemented yet. (b/4970173)
  XMLHttpRequest.getTEMPNAME(String url, onSuccess(XMLHttpRequest request));

  int get readyState();

  String get responseText();

  String get responseType();

  void set responseType(String value);

  Document get responseXML();

  int get status();

  String get statusText();

  XMLHttpRequestUpload get upload();

  bool get withCredentials();

  void set withCredentials(bool value);

  void abort();

  String getAllResponseHeaders();

  String getResponseHeader(String header);

  void open(String method, String url, bool async, [String user, String password]);

  void overrideMimeType(String mime);

  void send([String data]);

  void setRequestHeader(String header, String value);

  XMLHttpRequestEvents get on();
}
