// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 *
 * Built-in types, collections,
 * and other core functionality for every Dart program.
 *
 * Some classes in this library,
 * such as [String] and [num],
 * support Dart's built-in data types.
 * Other classes provide data structures
 * for managing collections of objects.
 * And still other classes represent commonly used types of data
 * such as URIs, dates, and times.
 *
 *
 * ## Built-in types
 *
 * [String], [int], [double], [bool], [List], and [Map]
 * provide support for Dart's built-in data types.
 * To declare and initialize variables of these types, write:
 *     String myString   = 'A sequence of characters.';
 *     int meaningOfLife = 42;
 *     double valueOfPi  = 3.141592;
 *     bool visible      = true;
 *     List superHeros   = [ 'Batman', 'Superman', 'Harry Potter' ];
 *     Map sidekicks     = { 'Batman': 'Robin',
 *                           'Superman': 'Lois Lane',
 *                           'Harry Potter': 'Ron and Hermione' };
 *
 * ## Strings
 *
 * A [String] is immutable and represents a sequence of characters.
 * [StringBuffer] provides a way to construct strings efficiently.
 * 
 * The Dart language uses the [String] and [StringBuffer]
 * behind the scenes to implement string concatenation, interpolation,
 * and other features.
 *     String myString = 'Live on ';
 *     String get palindrome => myString + myString.split('').reversed.join();
 *
 *
 * ## Collections
 *
 * The dart:core library provides basic collections,
 * such as [List], [Map], and [Set].
 *
 * * A [List] is an ordered collection of objects, with a length.
 * Lists are sometimes called arrays.
 * Use a List when you need to access objects by index.
 *
 * * A [Set] is an unordered collection of unique objects.
 * You cannot get an item by index (position).
 * Adding a duplicate item has no effect.
 * Use a [Set] when you need to guarantee object uniqueness.
 *
 * * A [Map] is an unordered collection of key-value pairs.
 * Maps are sometimes called associative arrays because
 * maps associate a key to some value for easy retrieval.
 * Keys are unique.
 * Use a [Map] when you need to access objects
 * by a unique identifier.
 *
 * In addition to these classes,
 * dart:core contains [Iterable],
 * an interface that defines functionality
 * common in collections of objects.
 * Examples include the ability
 * to run a function on each element in the collection,
 * to apply a test to each element, 
 * to retrieve an object, and to determine length.
 *
 * Iterable is implemented by [List] and [Set],
 * and used by [Map] for its lists of keys and values.
 * 
 * For other kinds of collections, check out the dart:collection library.
 * 
 * ## Date and time
 *
 * Use [DateTime] to represent a point in time
 * and [Duration] to represent a span of time.
 *
 * You can create [DateTime] objects with constructors
 * or by parsing a correctly formatted string.
 *     DateTime now = new DateTime.now();
 *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
 *     DateTime moonLanding = DateTime.parse("1969-07-20");
 *
 * Create a [Duration] object specifying the individual time units.
 *     Duration timeRemaining = new Duration(hours:56, minutes:14);
 *     
 * ## Uri
 *
 * A [Uri] object represents a uniform resource identifier,
 * which identifies a resource on the web.
 *     Uri dartlang = Uri.parse('http://dartlang.org/');
 *
 * ## Other documentation
 *
 * For more information about how to use the built-in types, refer to
 * [Built-in Types](http://www.dartlang.org/docs/dart-up-and-running/contents/ch02.html#built-in-types)
 * in Chapter 2 of
 * [Dart: Up and Running](http://www.dartlang.org/docs/dart-up-and-running/).
 *
 * Also, see
 * [dart:core - Numbers, Collections, Strings, and More](http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-dartcore---strings-collections-and-more)
 * for more coverage of classes in this package.
 *
 */


library dart.core;

import "dart:collection";
import "dart:_collection-dev" hide Symbol;
import "dart:_collection-dev" as _collection_dev;
import "dart:utf" show codepointsToUtf8, decodeUtf8;

part "bool.dart";
part "comparable.dart";
part "date_time.dart";
part "double.dart";
part "duration.dart";
part "errors.dart";
part "exceptions.dart";
part "expando.dart";
part "function.dart";
part "identical.dart";
part "int.dart";
part "invocation.dart";
part "iterable.dart";
part "iterator.dart";
part "list.dart";
part "map.dart";
part "null.dart";
part "num.dart";
part "object.dart";
part "pattern.dart";
part "print.dart";
part "regexp.dart";
part "set.dart";
part "stacktrace.dart";
part "stopwatch.dart";
part "string.dart";
part "string_buffer.dart";
part "string_sink.dart";
part "symbol.dart";
part "type.dart";
part "uri.dart";
