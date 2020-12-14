// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that built-in identifiers can be used to specify metadata.

const abstract = 0;
const as = 0;
const covariant = 0;
const deferred = 0;
const dynamic = 0;
const export = 0;
const external = 0;
const factory = 0;
const Function = 0;
const get = 0;
const implements = 0;
const import = 0;
const interface = 0;
const late = 0;
const library = 0;
const mixin = 0;
const operator = 0;
const part = 0;
const required = 0;
const set = 0;
const static = 0;
const typedef = 0;

@abstract
@as
@covariant
@deferred
@dynamic
@export
@external
@factory
@Function
@get
@implements
@import
@interface
@late
@library
@mixin
@operator
@part
@required
@set
@static
@typedef
void main(
  @abstract
  @as
  @covariant
  @deferred
  @dynamic
  @export
  @external
  @factory
  @Function
  @get
  @implements
  @import
  @interface
  @late
  @library
  @mixin
  @operator
  @part
  @required
  @set
  @static
  @typedef
      List<String> args,
) {
  @abstract
  @as
  @covariant
  @deferred
  @dynamic
  @export
  @external
  @factory
  @Function
  @get
  @implements
  @import
  @interface
  @late
  @library
  @mixin
  @operator
  @part
  @required
  @set
  @static
  @typedef
  var x = true;

  void f<
      @abstract
      @as
      @covariant
      @deferred
      @dynamic
      @export
      @external
      @factory
      @Function
      @get
      @implements
      @import
      @interface
      @late
      @library
      @mixin
      @operator
      @part
      @required
      @set
      @static
      @typedef
          X>() {}
}
