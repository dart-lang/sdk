// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

/*cfe|cfe:builder.class: Future:Future<T*>,Object*/
/*analyzer.class: Future:Future<T>,Object*/
class Future<T> {}

/*cfe|cfe:builder.class: FutureOr:FutureOr<T*>,Object*/
/*analyzer.class: FutureOr:FutureOr<T>,Object*/
class FutureOr<T> {}
