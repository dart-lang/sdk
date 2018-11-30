// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 *
 * Built-in types, collections,
 * and other core functionality for every Dart program.
 *
 * This library is automatically imported.
 *
 * Some classes in this library,
 * such as [String] and [num],
 * support Dart's built-in data types.
 * Other classes, such as [List] and [Map], provide data structures
 * for managing collections of objects.
 * And still other classes represent commonly used types of data
 * such as URIs, dates and times, and errors.
 *
 * ## Numbers and booleans
 *
 * [int] and [double] provide support for Dart's built-in numerical data types:
 * integers and double-precision floating point numbers, respectively.
 * An object of type [bool] is either true or false.
 * Variables of these types can be constructed from literals:
 *
 *     int meaningOfLife = 42;
 *     double valueOfPi  = 3.141592;
 *     bool visible      = true;
 *
 * ## Strings and regular expressions
 *
 * A [String] is immutable and represents a sequence of characters.
 *
 *     String shakespeareQuote = "All the world's a stage, ...";
 *
 * [StringBuffer] provides a way to construct strings efficiently.
 *
 *     StringBuffer moreShakespeare = new StringBuffer();
 *     moreShakespeare.write('And all the men and women ');
 *     moreShakespeare.write('merely players; ...');
 *
 * The String and StringBuffer classes implement string concatenation,
 * interpolation, and other string manipulation features.
 *
 *     String philosophy = 'Live on ';
 *     String get palindrome => philosophy + philosophy.split('').reversed.join();
 *
 * [RegExp] implements Dart regular expressions,
 * which provide a grammar for matching patterns within text.
 * For example, here's a regular expression that matches
 * a string of one or more digits:
 *
 *     var numbers = new RegExp(r'\d+');
 *
 * Dart regular expressions have the same syntax and semantics as
 * JavaScript regular expressions. See
 * <http://ecma-international.org/ecma-262/5.1/#sec-15.10>
 * for the specification of JavaScript regular expressions.
 *
 * ## Collections
 *
 * The dart:core library provides basic collections,
 * such as [List], [Map], and [Set].
 *
 * A List is an ordered collection of objects, with a length.
 * Lists are sometimes called arrays.
 * Use a List when you need to access objects by index.
 *
 *     List superheroes = [ 'Batman', 'Superman', 'Harry Potter' ];
 *
 * A Set is an unordered collection of unique objects.
 * You cannot get an item by index (position).
 * Adding a duplicate item has no effect.
 *
 *     Set villains = new Set();
 *     villains.add('Joker');
 *     villains.addAll( ['Lex Luther', 'Voldemort'] );
 *
 * A Map is an unordered collection of key-value pairs.
 * Maps are sometimes called associative arrays because
 * maps associate a key to some value for easy retrieval.
 * Keys are unique.
 * Use a Map when you need to access objects
 * by a unique identifier.
 *
 *     Map sidekicks = { 'Batman': 'Robin',
 *                       'Superman': 'Lois Lane',
 *                       'Harry Potter': 'Ron and Hermione' };
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
 * Iterable is implemented by List and Set,
 * and used by Map for its keys and values.
 *
 * For other kinds of collections, check out the
 * `dart:collection` library.
 *
 * ## Date and time
 *
 * Use [DateTime] to represent a point in time
 * and [Duration] to represent a span of time.
 *
 * You can create DateTime objects with constructors
 * or by parsing a correctly formatted string.
 *
 *     DateTime now = new DateTime.now();
 *     DateTime berlinWallFell = new DateTime(1989, 11, 9);
 *     DateTime moonLanding = DateTime.parse("1969-07-20");
 *
 * Create a Duration object specifying the individual time units.
 *
 *     Duration timeRemaining = new Duration(hours:56, minutes:14);
 *
 * In addition to DateTime and Duration,
 * dart:core contains the [Stopwatch] class for measuring elapsed time.
 *
 * ## Uri
 *
 * A [Uri] object represents a uniform resource identifier,
 * which identifies a resource on the web.
 *
 *     Uri dartlang = Uri.parse('http://dartlang.org/');
 *
 * ## Errors
 *
 * The [Error] class represents the occurrence of an error
 * during runtime.
 * Subclasses of this class represent specific kinds of errors.
 *
 * ## Other documentation
 *
 * For more information about how to use the built-in types, refer to [Built-in
 * Types](http://www.dartlang.org/docs/dart-up-and-running/contents/ch02.html#built-in-types)
 * in Chapter 2 of
 * [Dart: Up and Running](http://www.dartlang.org/docs/dart-up-and-running/).
 *
 * Also, see [dart:core - Numbers, Collections, Strings, and
 * More](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartcore---numbers-collections-strings-and-more)
 * for more coverage of classes in this package.
 *
 * The
 * [Dart Language Specification](http://www.dartlang.org/docs/spec/)
 * provides technical details.
 *
 * {@category Core}
 */
library dart.core;

import "dart:collection";
import "dart:_internal" hide Symbol, LinkedList, LinkedListEntry;
import "dart:_internal" as internal show Symbol;
import "dart:convert"
    show
        ascii,
        base64,
        Base64Codec,
        Encoding,
        latin1,
        StringConversionSink,
        utf8;
import "dart:math" show Random; // Used by List.shuffle.
import "dart:typed_data" show Uint8List, Uint16List, Endian;

@Since("2.1")
export "dart:async" show Future, Stream;

part "annotations.dart";
part "bigint.dart";
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
part "sink.dart";
part "stacktrace.dart";
part "stopwatch.dart";
part "string.dart";
part "string_buffer.dart";
part "string_sink.dart";
part "symbol.dart";
part "type.dart";
part "uri.dart";
