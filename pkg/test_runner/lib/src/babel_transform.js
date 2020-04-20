// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


const babelStandalonePath = arguments[0];
load(babelStandalonePath);
const inputFilePath = arguments[2];
const input = read(inputFilePath);
const options = JSON.parse(arguments[1]);
const output = Babel.transform(input, options).code;
console.log(output);
