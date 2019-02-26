<!--
Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

This file describes the format of the `problemsAsJson` strings in Dart Kernel.

Each string in the list is a json object consisting of these keys and values:

`ansiFormatted`: A list of strings the contain ansi formatted (for instance with
colors) problem-texts as reported by the compiler.

`plainTextFormatted`: A list of strings that contain formatted plaintext
problem-texts as reported by the compiler.

`severity`: An integer representing severity. This should match the index in
`package:front_end/src/fasta/severity.dart`.

`uri: A uri that this problems relates to.

These values are subject to change, but this file will be updated along with any
such changes. On the code-side these are defined in
`package:front_end/src/fasta/fasta_codes.dart`.
