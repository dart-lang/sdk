// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  testAnonymousAsync(0),
  testAnonymousAsyncStar(0),
  testAnonymousSyncStar(0),
  testAsync(0),
  testAsyncForIn(1),
  testAsyncForInTyped(1),
  testAsyncStar(0),
  testLocalAsync(0),
  testLocalAsyncStar(0),
  testLocalSyncStar(0),
  testSyncStar(0)],
  type=[inst:JSNull]
*/
main() {
  testSyncStar();
  testAsync();
  testAsyncStar();
  testLocalSyncStar();
  testLocalAsync();
  testLocalAsyncStar();
  testAnonymousSyncStar();
  testAnonymousAsync();
  testAnonymousAsyncStar();
  testAsyncForIn(null);
  testAsyncForInTyped(null);
}

/*element: testSyncStar:
 static=[
  _IterationMarker.endOfIteration,
  _IterationMarker.uncaughtError,
  _IterationMarker.yieldStar,
  _makeSyncStarIterable<dynamic>(1)]
*/
testSyncStar() sync* {}

/*element: testAsync:
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync]
*/
testAsync() async {}

/*element: testAsyncStar:static=[StreamIterator.,
  _IterationMarker.yieldSingle,
  _IterationMarker.yieldStar,
  _asyncStarHelper,
  _makeAsyncStarStreamController<dynamic>(1),
  _streamOfController,
  _wrapJsFunctionForAsync]*/
testAsyncStar() async* {}

/*kernel.element: testLocalSyncStar:
 static=[
  _IterationMarker.endOfIteration,
  _IterationMarker.uncaughtError,
  _IterationMarker.yieldStar,
  _makeSyncStarIterable<dynamic>(1),
  def:local],
 type=[inst:Function]
*/
/*strong.element: testLocalSyncStar:
 static=[
  _IterationMarker.endOfIteration,
  _IterationMarker.uncaughtError,
  _IterationMarker.yieldStar,
  _makeSyncStarIterable<Null>(1),
  computeSignature,
  def:local,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalSyncStar() {
  local() sync* {}
  return local;
}

/*kernel.element: testLocalAsync:
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync,
  def:local],
 type=[inst:Function]
*/
/*strong.element: testLocalAsync:
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<Null>(0),
  _wrapJsFunctionForAsync,
  computeSignature,
  def:local,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalAsync() {
  local() async {}
  return local;
}

/*kernel.element: testLocalAsyncStar:
 static=[
 StreamIterator.,
  _IterationMarker.yieldSingle,
  _IterationMarker.yieldStar,
  _asyncStarHelper,
  _makeAsyncStarStreamController<dynamic>(1),
  _streamOfController,
  _wrapJsFunctionForAsync,
  def:local],
 type=[inst:Function]
*/
/*strong.element: testLocalAsyncStar:
 static=[
  StreamIterator.,
  _IterationMarker.yieldSingle,
  _IterationMarker.yieldStar,
  _asyncStarHelper,
  _makeAsyncStarStreamController<Null>(1),
  _streamOfController,
  _wrapJsFunctionForAsync,
  computeSignature,
  def:local,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalAsyncStar() {
  local() async* {}
  return local;
}

/*kernel.element: testAnonymousSyncStar:
 static=[
  _IterationMarker.endOfIteration,
  _IterationMarker.uncaughtError,
  _IterationMarker.yieldStar,
  _makeSyncStarIterable<dynamic>(1),
  def:<anonymous>],
 type=[
  check:Iterable<dynamic>,
  inst:Function]
*/
/*strong.element: testAnonymousSyncStar:
 static=[
  _IterationMarker.endOfIteration,
  _IterationMarker.uncaughtError,
  _IterationMarker.yieldStar,
  _makeSyncStarIterable<Null>(1),
  computeSignature,
  def:<anonymous>,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testAnonymousSyncStar() {
  return () sync* {};
}

/*kernel.element: testAnonymousAsync:
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync,
  def:<anonymous>],
 type=[
  check:Future<dynamic>,
  inst:Function]
*/
/*strong.element: testAnonymousAsync:
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<Null>(0),
  _wrapJsFunctionForAsync,
  computeSignature,
  def:<anonymous>,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testAnonymousAsync() {
  return () async {};
}

/*kernel.element: testAnonymousAsyncStar:
 static=[
  StreamIterator.,
  _IterationMarker.yieldSingle,
  _IterationMarker.yieldStar,
  _asyncStarHelper,
  _makeAsyncStarStreamController<dynamic>(1),
  _streamOfController,
  _wrapJsFunctionForAsync,
  def:<anonymous>],
 type=[
  check:Stream<dynamic>,
  inst:Function]
*/
/*strong.element: testAnonymousAsyncStar:
 static=[
  StreamIterator.,
  _IterationMarker.yieldSingle,
  _IterationMarker.yieldStar,
  _asyncStarHelper,
  _makeAsyncStarStreamController<Null>(1),
  _streamOfController,
  _wrapJsFunctionForAsync,
  computeSignature,
  def:<anonymous>,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testAnonymousAsyncStar() {
  return () async* {};
}

/*kernel.element: testAsyncForIn:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync],
 type=[
  inst:JSNull,
  inst:Null]
*/
/*strong.element: testAsyncForIn:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync],
 type=[
  impl:Stream<dynamic>,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testAsyncForIn(o) async {
  // ignore: UNUSED_LOCAL_VARIABLE
  await for (var e in o) {}
}

/*kernel.element: testAsyncForInTyped:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync],
 type=[
  check:int,
  inst:JSNull,
  inst:Null]
*/
/*strong.element: testAsyncForInTyped:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.,
  _asyncAwait,
  _asyncRethrow,
  _asyncReturn,
  _asyncStartSync,
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync],
 type=[
  impl:Stream<dynamic>,
  impl:int,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testAsyncForInTyped(o) async {
  // ignore: UNUSED_LOCAL_VARIABLE
  await for (int e in o) {}
}
