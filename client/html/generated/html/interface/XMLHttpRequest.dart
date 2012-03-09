// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequest extends EventTarget default _XMLHttpRequestFactoryProvider {
  // TODO(rnystrom): This name should just be "get" which is valid in Dart, but
  // not correctly implemented yet. (b/4970173)
  XMLHttpRequest.getTEMPNAME(String url, onSuccess(XMLHttpRequest request));

  XMLHttpRequest();

  XMLHttpRequestEvents get on();

  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  final int readyState;

  final Object response;

  final Blob responseBlob;

  final String responseText;

  String responseType;

  final Document responseXML;

  final int status;

  final String statusText;

  final XMLHttpRequestUpload upload;

  bool withCredentials;

  void abort();

  String getAllResponseHeaders();

  String getResponseHeader(String header);

  void open(String method, String url, [bool async, String user, String password]);

  void overrideMimeType(String override);

  void send([var data]);

  void setRequestHeader(String header, String value);
}

interface XMLHttpRequestEvents extends Events {

  EventListenerList get abort();

  EventListenerList get error();

  EventListenerList get load();

  EventListenerList get loadEnd();

  EventListenerList get loadStart();

  EventListenerList get progress();

  EventListenerList get readyStateChange();
}
