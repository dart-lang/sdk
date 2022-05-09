// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Script to find all short names used prototypes of global definitions.  This
// can be used as a basis for a list of names to avoid for dynamic method
// selectors.
//
// TODO(7554): Update compiler regularly.

function analyze() {
  let names = Object.create(null)
  for (var global of Object.getOwnPropertyNames(self)) {
    let value = window[global];
    if (typeof value != "function") continue;
    let prototype = value.prototype;
    if (prototype == null) continue;
    while (prototype != null) {
      for (let name of Object.getOwnPropertyNames(prototype)) {
        if (name.length > 4) continue;
        names[name] = 1;
      }
      prototype = Object.getPrototypeOf(prototype);
    }
  }

  names = Object.keys(names);

  function byLengthThenName(a, b) {
    if (a.length != b.length) return a.length - b.length;
    let a_lc = a.toLowerCase();
    let b_lc = b.toLowerCase();
    if (a_lc < b_lc) return -1;
    if (a_lc > b_lc) return 1;
    if (a > b) return -1;
    if (a < b) return 1;
    return 0;
  }
  names.sort(byLengthThenName);

  return names;
}

function display(names) {
  console.log(names)
  let div = document.createElement('div');
  document.body.appendChild(div);
  div.style.fontFamily = 'courier'
  for (let name of names) {
    div.appendChild(document.createTextNode("'" + name + "',"))
    div.appendChild(document.createElement("br"));
  }
}

display(analyze());
