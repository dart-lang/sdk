<!--
Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

# Dynamic interface specification

This file describes the format of dynamic_interface.yaml file.
Dynamic interface specifies classes and members of the host
application which can be used, extended,
implemented and overridden by a dynamically loaded module.

TODO(alexmarkov) Add a link to dynamic module API.

The dynamic interface yaml file can contain the following sections:

```
callable:
  - item 1
  ...
  - item N

extendable:
  - item 1
  ...
  - item N

can-be-overridden:
  - item 1
  ...
  - item N
```

`callable` section specifies members which can be
called from dynamic module and classes which can be
referenced in types of dynamic module.

`extendable` section specifies classes which dynamic module can be
extend, mix-in or implement.

`can-be-overridden` section specifies instance members which
dynamic module can override.

## Library

```
  - library: '<library-uri>'
```

Library item specifies all _public_ classes and members in the given
library. Public members of private classes are not included.

## Library prefix

```
  - library: '<prefix>*'
```

Library prefix item specifies all _public_ classes and members of
all libraries with given prefix. Public members of private classes are not included.


## Class

```
  - library: '<library-uri>'
    class: '<class-name>'
```

Class item specifies given class and all _public_ members of this class.

## Class list

```
  - library: '<library-uri>'
    class: ['<class-name-1>', ..., 'class-name-N']
```

Class list item specifies given classes and all _public_ members of these classes.

## Library member

```
  - library: '<library-uri>'
    member: '<member-name>'
```

Library member item specifies given top-level member in the given library.

## Class member

```
  - library: '<library-uri>'
    class: '<class-name>'
    member: '<member-name>'
```

Class member item specifies given member of the given class.

## Example

```
callable:
  # All public classes and members in `dart:core`.
  - library: 'dart:core'

  # All public classes and members in `package:flutter`.
  - library: 'package:flutter/*'

  # Only `foo` in `package:my_app/dyn_interface.dart`.
  - library: 'package:my_app/dyn_interface.dart'
    member: foo

  # Only `DynInterface.bar` in `package:my_app/dyn_interface.dart`.
  - library: 'package:my_app/dyn_interface.dart'
    class: DynInterface
    member: 'bar'

extendable:
  # All public classes in `dart:core`.
  - library: 'dart:core'

  # `StatefulWidget` and `StatelessWidget` classes in `package:flutter/src/widgets/framework.dart`.
  - library: 'package:flutter/src/widgets/framework.dart'
    class: ['StatefulWidget', 'StatelessWidget']

can-be-overridden:
  # All public classes and members in `dart:core`.
  - library: 'dart:core'

  # Only `StatelessWidget.build` in `package:flutter/src/widgets/framework.dart`.
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'StatelessWidget'
    member: 'build'
```
