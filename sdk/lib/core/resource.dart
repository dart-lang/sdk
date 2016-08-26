// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * DEPRECATED. A resource that can be read into the program.
 *
 * WARNING: This API is _deprecated_,
 * and it will be removed in 1.14. Please use
 * https://pub.dartlang.org/packages/resource instead.
 *
 * A resource is data that can be located using a URI and read into
 * the program at runtime.
 * The URI may use the `package` scheme to read resources provided
 * along with package sources.
 */
@Deprecated('1.14')
abstract class Resource {
  /**
   * Creates a resource object with the given [uri] as location.
   *
   * The `uri` is a string containing a valid URI.
   * If the string is not a valid URI, using any of the functions on
   * the resource object will fail.
   *
   * The URI may be relative, in which case it will be resolved
   * against [Uri.base] before being used.
   *
   * The URI may use the `package` scheme, which is always supported.
   * Other schemes may also be supported where possible.
   */
  external const factory Resource(String uri);

  /**
   * The location `uri` of this resource.
   *
   * This is a [Uri] of the `uri` parameter given to the constructor.
   * If the parameter was not a valid URI, reading `uri` may fail.
   */
  Uri get uri;

  /** Read the resource content as a stream of bytes. */
  Stream<List<int>> openRead();

  /** Read the resource content. */
  Future<List<int>> readAsBytes();

  /**
   * Read the resource content as a string.
   *
   * The content is decoded into a string using an [Encoding].
   * If no other encoding is provided, it defaults to UTF-8.
   */
  Future<String> readAsString({Encoding encoding});
}
