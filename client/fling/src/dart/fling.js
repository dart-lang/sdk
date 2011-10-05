// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native__Logger__printString(message) {
  print(message + '\n');
}

function native_Fling__getArgs() {
  return argv;
}


// Fling
function native_Fling_goForth() {
  goForth();
}

function native_Fling_refresh() {
  refresh();
}

function native_Fling_getInstallPath() {
  return getInstallPath();
}


// HttpServer
function native_HttpServer__init() {
  this.$impl = new HttpServer();
}

function native_HttpServer_listen(port) {
  this.$impl.listen(port);
}

function native_HttpServer_handle(path, handler) {
  this.$impl.handle(path,
    function(req, rsp) { $dartcall(handler, [req, rsp]); });
}

// HttpResponse
function native_HttpResponse_finish() {
  this.$impl.finish();
}

function native_HttpResponse_flush() {
  this.$impl.flush();
}

function native_HttpResponse_setHeader(name, value) {
  this.$impl.setHeader(name, value);
}

function native_HttpResponse_setStatusCode(code) {
  this.$impl.setStatusCode(code);
}

function native_HttpResponse_write(data) {
  this.$impl.write(data);
}

// HttpRequest
function native_HttpRequest_get$body() {
  return this.$impl.body;
}

function native_HttpRequest_get$isKeepAlive() {
  return this.$impl.isKeepAlive;
}

function native_HttpRequest_get$method() {
  return this.$impl.method;
}

function native_HttpRequest_get$requestedPath() {
  return this.$impl.requestedPath;
}

function native_HttpRequest_get$version() {
  return this.$impl.version;
}

function native_HttpRequest_get$prefix() {
  return this.$impl.prefix;
}

// ClientApp
function native_ClientApp__init(path, apps) {
  this.$impl = new ClientApp(path, apps);
}

function native_ClientApp__handle(req, res) {
  this.$impl.handler(req, res);
}
