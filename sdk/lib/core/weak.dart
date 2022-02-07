// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An [Expando] allows adding new properties to objects.
///
/// Does not work on numbers, strings, booleans, `null`, `dart:ffi` pointers,
/// `dart:ffi` structs, or `dart:ffi` unions.
///
/// An `Expando` does not hold on to the added property value after an object
/// becomes inaccessible.
///
/// Since you can always create a new number that is identical to an existing
/// number, it means that an expando property on a number could never be
/// released. To avoid this, expando properties cannot be added to numbers.
/// The same argument applies to strings, booleans and `null`, which also have
/// literals that evaluate to identical values when they occur more than once.
///
/// There is no restriction on other classes, even for compile time constant
/// objects. Be careful if adding expando properties to compile time constants,
/// since they will stay alive forever.
class Expando<T extends Object> {
  /// The name of the this [Expando] as passed to the constructor.
  ///
  /// If no name was passed to the constructor, the value is the `null` value.
  final String? name;

  /// Creates a new [Expando]. The optional name is only used for
  /// debugging purposes and creating two different [Expando]s with the
  /// same name yields two [Expando]s that work on different properties
  /// of the objects they are used on.
  external Expando([String? name]);

  /// Expando toString method override.
  String toString() => "Expando:$name";

  /// Gets the value of this [Expando]'s property on the given object.
  ///
  /// If the object hasn't been expanded, the result is the `null` value.
  ///
  /// The object must not be a number, a string, a boolean, `null`, a
  /// `dart:ffi` pointer, a `dart:ffi` struct, or a `dart:ffi` union.
  external T? operator [](Object object);

  /// Sets this [Expando]'s property value on the given object to [value].
  ///
  /// Properties can effectively be removed again
  /// by setting their value to `null`.
  ///
  /// The object must not be a number, a string, a boolean, `null`, a
  /// `dart:ffi` pointer, a `dart:ffi` struct, or a `dart:ffi` union.
  external void operator []=(Object object, T? value);
}

/// A weak reference to a Dart object.
///
/// A _weak_ reference to the [target] object which may be cleared
/// (set to reference `null` instead) at any time
/// when there is no other way for the program to access the target object.
///
/// _Being the target of a weak reference does not keep an object
/// from being garbage collected._
///
/// There are no guarantees that a weak reference will ever be cleared
/// even if all references to its target are weak references.
///
/// Not all objects are supported as targets for weak references.
/// The [WeakReference] constructor will reject any object that is not
/// supported as an [Expando] key.
@Since("2.17")
abstract class WeakReference<T extends Object> {
  /// Creates a [WeakReference] pointing to the given [target].
  ///
  /// The [target] must be an object supported as an [Expando] key,
  /// which means [target] cannot be a number, a string, a boolean,
  /// the `null` value, or certain other types of special objects.
  external factory WeakReference(T target);

  /// The current object weakly referenced by [this], if any.
  ///
  /// The value is either the object supplied in the constructor,
  /// or `null` if the weak reference has been cleared.
  T? get target;
}

/// A finalizer which can be attached to Dart objects.
///
/// A finalizer can create attachments between
/// the finalizer and any number of Dart values,
/// by calling [attach] with the value, along with a
/// _finalization token_ and an optional _attach key_,
/// which are part of the attachment.
///
/// When a Dart value becomes inaccessible to the program,
/// any finalizer that currently has an attachment to
/// the value *may* have its callback function called
/// with the attachment's finalization token.
///
/// Example:
/// ```dart template:none
/// // Keep the finalizer itself reachable, otherwise might not do anything.
/// final Finalizer<DBConnection> _finalizer = Finalizer((connection) {
///   connection.close();
/// });
///
/// /// Access the database.
/// Database connect() {
///   // Wraps the connection in a nicer user-facing API,
///   // *and* closes connection if the user forgets to.
///   var connection = _connectToDatabase();
///   var wrapper = Database._fromConnection(connection, _finalizer);
///   // Get finalizer callback when `wrapper` is no longer reachable.
///   _finalizer.attach(wrapper, connection, detach: wrapper);
///   return wrapper;
/// }
///
/// class Database {
///   final DBConnection _connection;
///   final Finalizer<Connection> _finalizer;
///   Database._fromConnection(this._connection, this._finalizer);
///
///   // Some useful methods.
///
///   void close() {
///     // User requested close.
///     _connection.close();
///     // Detach from finalizer, no longer needed.
///     _finalizer.detach(this);
///   }
/// }
/// ```
/// This example has an example of an external resource that needs clean-up.
/// The finalizer is used to clean up an external connection when the
/// user of the API no longer has access to that connection.
/// The example uses the same object as attached object and detach key,
/// which is a useful approach when each attached object can be detached
/// individually. Being a detachment key doesn't keep an object alive.
///
/// No promises are made that the callback will ever be called.
/// The only thing that is guaranteed is that if a finalizer's callback
/// is called with a specific finalization token as argument,
/// then at least one value with an attachment to to the finalizer
/// that has that finalization token,
/// is no longer accessible to the program.
///
/// If the finalzier *itself* becomes unreachable,
/// it's allowed to be garbage collected
/// and then it won't trigger any further callbacks.
/// Always make sure to keep the finalizer itself reachable while it's needed.
///
/// If multiple finalizers are attached to a single object,
/// or the same finalizer is attached multiple times to an object,
/// and that object becomes inaccessible to the program,
/// then any number (including zero) of those attachments may trigger
/// their associated finalizer's callback.
/// It will not necessarily be all or none of them.
///
/// Finalization callbacks will happen as *events*.
/// They will not happen during execution of other code,
/// and not as a microtask,
/// but as high-level events similar to timer events.
///
/// Finalization callbacks must not throw.
@Since("2.17")
abstract class Finalizer<T> {
  /// Creates a finalizer with the given finalization callback.
  ///
  /// The [callback] is bound to the current zone
  /// when the [Finalizer] is created, and will run in that zone when called.
  external factory Finalizer(void Function(T) callback);

  /// Attaches this finalizer to [value].
  ///
  /// When [value] is longer accessible to the program,
  /// while still having an attachement to this finalizer,
  /// the callback of this finalizer *may* be called
  /// with [finalizationToken] as argument.
  /// The callback may be called at most once per active attachment,
  /// ones which have not been detached by calling [Finalizer.detach].
  ///
  /// If a non-`null` [detach] value is provided, that object can be
  /// passed to [Finalizer.detach] to remove the attachment again.
  ///
  /// The [value] and [detach] arguments do not count towards those
  /// objects being accessible to the program.
  /// Both must be objects supported as an [Expando] key.
  /// They may be the *same* object.
  ///
  /// Example:
  /// ```dart template:top
  /// /// Access the data base.
  /// Database connect() {
  ///   // Wraps the connection in a nice user API,
  ///   // *and* closes connection if the user forgets to.
  ///   var connection = _connectToDatabase();
  ///   var wrapper = Database._fromConnection(connection, _finalizer);
  ///   // Get finalizer callback when `wrapper` is no longer reachable.
  ///   _finalizer.attach(wrapper, connection, detach: wrapper);
  ///   return wrapper;
  /// }
  /// ````
  ///
  /// Multiple objects may be attached using the same finalization token,
  /// and the finalizer can be attached multiple times to the same object
  /// with different, or the same, finalization token.
  void attach(Object value, T finalizationToken, {Object? detach});

  /// Detaches the finalizer from values attached with [detachToken].
  ///
  /// Each attachment between this finalizer and a value,
  /// which was created by calling [attach] with the [detachToken] object as
  /// `detach` argument, is removed.
  ///
  /// If the finalizer was attached multiple times to the same value
  /// with different detachment keys,
  /// only those attachments which used [detachToken] are removed.
  ///
  /// After detaching, an attachment won't cause any callbacks to happen
  /// if the object become inaccessible.
  ///
  /// Example:
  /// ```dart template:none
  /// final Finalizer<DBConnection> _finalizer = Finalizer((connection) {
  ///   connection.close();
  /// });
  ///
  /// class Database {
  ///   final DBConnection _connection;
  ///   final Finalizer<Connection> _finalizer;
  ///   Database._fromConnection(this._connection, this._finalizer);
  ///
  ///   // Some useful methods.
  ///
  ///   void close() {
  ///     // User requested close.
  ///     _connection.close();
  ///     // Detach from finalizer, no longer needed.
  ///     // Was attached using this object as `detach` token.
  ///     _finalizer.detach(this);
  ///   }
  /// }
  /// ```
  void detach(Object detachToken);
}
