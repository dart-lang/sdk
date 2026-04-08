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

can-be-used-as-type:
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

`can-be-used-as-type` section specifies classes and extension types
which can be used in dynamic module in `is` checks, `as` casts,
type parameters, or type literals.

## Library

```
  - library: '<library-uri>'
```

Library item specifies all _public_ classes and members in the given
library. Public members of private classes are not included.

## Class

```
  - library: '<library-uri>'
    class: '<class-name>'
```

Class item specifies given class and all _public_ members of this class.

## Extension Type

```
  - library: '<library-uri>'
    extension_type: '<extension-type-name>'
```

Extension Type item specifies given extension type and all _public_ members of such extension type.

This item is only allowed in the `callable` section of the dynamic interface.


## Class list

```
  - library: '<library-uri>'
    class: ['<class-name-1>', ..., 'class-name-N']
```

Class list item specifies given classes and all _public_ members of these classes.

## Extension Type list

```
  - library: '<library-uri>'
    extension_type: ['<extension-type-name-1>', ..., 'extension-type-name-N']
```

Extension type list item specifies given extension types and all _public_ members of these.


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
## Extension Type member

```
  - library: '<library-uri>'
    extension_type: '<extension-type-name>'
    member: '<member-name>'
```

Extension type member item specifies given member of the given extension type.

--

## Extension

```
  - library: '<library-uri>'
    extension: '<extension-name>'
```

Extension item specifies given extension and all _public_ members of such extension.

This item is only allowed in the `callable` section of the dynamic interface.

--

## Extension list

```
  - library: '<library-uri>'
    extension: ['<extension-name-1>', ..., 'extension-name-N']
```

Extension list item specifies given extensions and all _public_ members of these.


--

## Extension member

```
  - library: '<library-uri>'
    extension: '<extension-name>'
    member: '<member-name>'
```

Extension member item specifies given member of the given extension.

--

## Example
```
callable:
  # All public classes and members in `dart:core`.
  - library: 'dart:core'

  # Only `foo` in `package:my_app/dyn_interface.dart`.
  - library: 'package:my_app/dyn_interface.dart'
    member: foo

  # Only `DynInterface.bar` in `package:my_app/dyn_interface.dart`.
  - library: 'package:my_app/dyn_interface.dart'
    class: DynInterface
    member: 'bar'

  # Only `EType.baz` in `package:my_app/dyn_interface.dart`.
  - library: 'package:my_app/dyn_interface.dart'
    extension_type: Etype
    member: 'baz'

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

can-be-used-as-type:
  # All public classes in `dart:core`.
  - library: 'dart:core'

  # `MyClass` in `package:my_app/lib/my_app.dart`.
  - library: 'package:my_app/lib/my_app.dart'
    class: 'MyClass'
```
