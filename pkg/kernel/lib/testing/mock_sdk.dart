// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String mockSdk = """
class Object;
class Comparable<T>;
class num implements Comparable<num>;
class int extends num;
class double extends num;
class Iterable<T>;
class List<T> extends Iterable<T>;
class Future<T>;
class FutureOr<T>;
class Null;
class Function;
class String;
class bool;
""";
