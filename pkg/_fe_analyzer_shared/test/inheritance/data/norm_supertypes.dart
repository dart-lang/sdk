// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'dart:async';

/*class: A:A<T>,Object*/
class A<T> {}

/*class: Foo:A<FutureOr<T?>>,Foo<T, S>,Object*/
class Foo<T extends S, S extends Never> implements A<FutureOr<T?>> {}

/*cfe|cfe:builder.class: Bar:A<FutureOr<Never>>,Bar,Object*/
/*analyzer.class: Bar:A<FutureOr<Never?>>,Bar,Object*/
class Bar implements A<FutureOr<Never?>> {}

/*class: Baz:A<Future<Null>?>,Baz,Object*/
class Baz implements A<Future<Null>?> {}

/*cfe|cfe:builder.class: Hest:A<Future<Null>?>,Bar,Foo<Never, Never>,Hest,Object*/
/*analyzer.class: Hest:A<FutureOr<Never?>>,Bar,Foo<Never, Never>,Hest,Object*/
class Hest extends Foo implements Bar {}

/*cfe|cfe:builder.class: Fisk:A<Future<Null>?>,Bar,Baz,Fisk,Object*/
/*analyzer.class: Fisk:A<FutureOr<Never?>>,Bar,Baz,Fisk,Object*/
class Fisk extends Bar implements Baz {}

/*class: Naebdyr:A<Future<Null>?>,Baz,Foo<Never, Never>,Naebdyr,Object*/
class Naebdyr extends Baz implements Foo {}

main() {}
