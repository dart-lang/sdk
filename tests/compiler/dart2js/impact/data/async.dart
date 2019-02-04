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
  _IterationMarker.endOfIteration(0),
  _IterationMarker.uncaughtError(1),
  _IterationMarker.yieldStar(1),
  _makeSyncStarIterable<dynamic>(1)]
*/
testSyncStar() sync* {}

/*element: testAsync:
 static=[
  StreamIterator.(1),
  _asyncAwait(2),
  _asyncRethrow(2),
  _asyncReturn(2),
  _asyncStartSync(2),
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync(1)]
*/
testAsync() async {}

/*element: testAsyncStar:
 static=[
  StreamIterator.(1),
  _IterationMarker.yieldSingle(1),
  _IterationMarker.yieldStar(1),
  _asyncStarHelper(3),
  _makeAsyncStarStreamController<dynamic>(1),
  _streamOfController(1),
  _wrapJsFunctionForAsync(1)]
*/
testAsyncStar() async* {}

/*strong.element: testLocalSyncStar:
 static=[
  _IterationMarker.endOfIteration(0),
  _IterationMarker.uncaughtError(1),
  _IterationMarker.yieldStar(1),
  _makeSyncStarIterable<Null>(1),
  computeSignature(3),
  def:local,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testLocalAsync:
 static=[
  StreamIterator.(1),
  _asyncAwait(2),
  _asyncRethrow(2),
  _asyncReturn(2),
  _asyncStartSync(2),
  _makeAsyncAwaitCompleter<Null>(0),
  _wrapJsFunctionForAsync(1),
  computeSignature(3),
  def:local,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testLocalAsyncStar:
 static=[
  StreamIterator.(1),
  _IterationMarker.yieldSingle(1),
  _IterationMarker.yieldStar(1),
  _asyncStarHelper(3),
  _makeAsyncStarStreamController<Null>(1),
  _streamOfController(1),
  _wrapJsFunctionForAsync(1),
  computeSignature(3),
  def:local,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testAnonymousSyncStar:
 static=[
  _IterationMarker.endOfIteration(0),
  _IterationMarker.uncaughtError(1),
  _IterationMarker.yieldStar(1),
  _makeSyncStarIterable<Null>(1),
  computeSignature(3),
  def:<anonymous>,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testAnonymousAsync:
 static=[
  StreamIterator.(1),
  _asyncAwait(2),
  _asyncRethrow(2),
  _asyncReturn(2),
  _asyncStartSync(2),
  _makeAsyncAwaitCompleter<Null>(0),
  _wrapJsFunctionForAsync(1),
  computeSignature(3),
  def:<anonymous>,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testAnonymousAsyncStar:
 static=[
  StreamIterator.(1),
  _IterationMarker.yieldSingle(1),
  _IterationMarker.yieldStar(1),
  _asyncStarHelper(3),
  _makeAsyncStarStreamController<Null>(1),
  _streamOfController(1),
  _wrapJsFunctionForAsync(1),
  computeSignature(3),
  def:<anonymous>,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
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

/*strong.element: testAsyncForIn:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.(1),
  _asyncAwait(2),
  _asyncRethrow(2),
  _asyncReturn(2),
  _asyncStartSync(2),
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync(1)],
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

/*strong.element: testAsyncForInTyped:
 dynamic=[
  cancel(0),
  current,
  moveNext(0)],
 static=[
  StreamIterator.(1),
  _asyncAwait(2),
  _asyncRethrow(2),
  _asyncReturn(2),
  _asyncStartSync(2),
  _makeAsyncAwaitCompleter<dynamic>(0),
  _wrapJsFunctionForAsync(1)],
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
