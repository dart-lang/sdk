<!--
Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->
# Builder

A program element is any part of a program excluding method bodies (but including local variables). Examples of program elements includes classes, methods, typedefs, etc.

A builder is a representation of a program element that is being constructed, either from source or dill file.

The builders in this directory are supposed to capture the common behavior shared between builders specific for source or dill.
