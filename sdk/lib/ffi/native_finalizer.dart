// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.ffi;

/// Marker interface for objects which should not be finalized too soon.
///
/// Any local variable with a static type that _includes `Finalizable`_
/// is guaranteed to be alive until execution exits the code block where
/// the variable is in scope.
///
/// A type _includes `Finalizable`_ if either
/// * the type is a non-`Never` subtype of `Finalizable`, or
/// * the type is `T?` or `FutureOr<T>` where `T` includes `Finalizable`.
///
/// In other words, while an object is referenced by such a variable,
/// it is guaranteed to *not* be considered unreachable,
/// and the variable itself is considered alive for the entire duration
/// of its scope, even after it is last referenced.
///
/// _Without this marker interface on the variable's type, a variable's
/// value might be garbage collected before the surrounding scope has
/// been completely executed, as long as the variable is definitely not
/// referenced again. That can, in turn, trigger a `NativeFinalizer`
/// to perform a callback. When the variable's type includes [Finalizable],
/// The `NativeFinalizer` callback is prevented from running until
/// the current code using that variable is complete._
///
/// For example, `finalizable` is kept alive during the execution of
/// `someNativeCall`:
///
/// ```dart
/// void myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   someNativeCall(finalizable.nativeResource);
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// Methods on a class implementing `Finalizable` keep the `this` object alive
/// for the duration of the method execution. _The `this` value is treated
/// like a local variable._
///
/// For example, `this` is kept alive during the execution of `someNativeCall`
/// in `myFunction`:
///
/// ```dart
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
///
///   void myFunction() {
///     someNativeCall(nativeResource);
///   }
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
/// ```
///
/// It is good practise to implement logic involving finalizables as methods
/// on the class that implements [Finalizable].
///
/// If a closure is created inside the block scope declaring the variable, and
/// that closure contains any reference to the variable, the variable stays
/// alive as long as the closure object does, or as long as the body of such a
/// closure is executing.
///
/// For example, `finalizable` is kept alive by the closure object and until the
/// end of the closure body:
///
/// ```dart
/// void doSomething() {
///   final resourceAction = myFunction();
///   resourceAction(); // `finalizable` is alive until this call returns.
/// }
///
/// void Function() myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   return () {
///     someNativeCall(finalizable.nativeResource);
///   };
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// Only captured variables are kept alive by closures, not all variables.
///
/// For example, `finalizable` is not kept alive by the returned closure object:
///
/// ```dart
/// void Function() myFunction() {
///   final finalizable = MyFinalizable(Pointer.fromAddress(0));
///   final nativeResource = finalizable.nativeResource;
///   return () {
///     someNativeCall(nativeResource);
///   };
/// }
///
/// void someNativeCall(Pointer nativeResource) {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   final Pointer nativeResource;
///
///   MyFinalizable(this.nativeResource);
/// }
/// ```
///
/// It's likely an error if a resource extracted from a finalizable object
/// escapes the scope of the finalizable variable it's taken from.
///
/// The behavior of `Finalizable` variables applies to asynchronous
/// functions too. Such variables are kept alive as long as any
/// code may still execute inside the scope that declared the variable,
/// or in a closure capturing the variable,
/// even if there are asynchronous delays during that execution.
///
/// For example, `finalizable` is kept alive during the `await someAsyncCall()`:
///
/// ```dart
/// Future<void> myFunction() async {
///   final finalizable = MyFinalizable();
///   await someAsyncCall();
/// }
///
/// Future<void> someAsyncCall() async {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   // ..
/// }
/// ```
///
/// Also in asynchronous code it's likely an error if a resource extracted from
/// a finalizable object escapes the scope of the finalizable variable it's
/// taken from. If you have to extract a resource from a `Finalizable`, you
/// should ensure the scope in which Finalizable is defined outlives the
/// resource by `await`ing any asynchronous code that uses the resource.
///
/// For example, `this` is kept alive until `resource` is not used anymore in
/// `useAsync1`, but not in `useAsync2` and `useAsync3`:
///
/// ```dart
/// class MyFinalizable {
///   final Pointer<Int8> resource;
///
///   MyFinalizable(this.resource);
///
///   Future<int> useAsync1() async {
///     return await useResource(resource);
///   }
///
///   Future<int> useAsync2() async {
///     return useResource(resource);
///   }
///
///   Future<int> useAsync3() {
///     return useResource(resource);
///   }
/// }
///
/// /// Does not use [resource] after the returned future completes.
/// Future<int> useResource(Pointer<Int8> resource) async {
///   return resource.value;
/// }
/// ```
///
/// _It is possible for an asynchronous function to *stall* at an
/// `await`, such that the runtime system can see that there is no possible
/// way for that `await` to complete. In that case, no code after the
/// `await` will ever execute, including `finally` blocks, and the
/// variable may be considered dead along with everything else._
///
/// If you're not going to keep a variable alive yourself, make sure to pass the
/// finalizable object to other functions instead of just its resource.
///
/// For example, `finalizable` is not kept alive by `myFunction` after it has
/// run to the end of its scope, while `someAsyncCall` could still continue
/// execution. However, `finalizable` is kept alive by `someAsyncCall` itself:
///
/// ```dart
/// void myFunction() {
///   final finalizable = MyFinalizable();
///   someAsyncCall(finalizable);
/// }
///
/// Future<void> someAsyncCall(MyFinalizable finalizable) async {
///   // ..
/// }
///
/// class MyFinalizable implements Finalizable {
///   // ..
/// }
/// ```
// TODO(http://dartbug.com/44395): Add implicit await to Dart implementation.
// This will fix `useAsync2` above.
abstract class Finalizable {
  factory Finalizable._() => throw UnsupportedError("");
}
