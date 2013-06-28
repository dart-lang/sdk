// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): more commentary here.
/**
 * This library provides access to Model-Driven-Views APIs on HTML elements.
 * More information can be found at: <https://github.com/toolkitchen/mdv>.
 */
library mdv;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math' as math;
import 'package:observe/observe.dart';

// TODO(jmesserly): get this from somewhere else. See http://dartbug.com/4161.
import 'package:serialization/src/serialization_helpers.dart' show IdentityMap;

part 'src/bindings.dart';
part 'src/element.dart';
part 'src/input_element.dart';
part 'src/node.dart';
part 'src/template.dart';
part 'src/text.dart';

/** Initialize the Model-Driven Views polyfill. */
void initialize() {
  TemplateElement.mdvPackage = _mdv;
}

StreamController<DocumentFragment> _instanceCreated;

/**
 * *Warning*: This is an implementation helper for Model-Driven Views and
 * should not be used in your code.
 *
 * This event is fired whenever a template is instantiated via
 * [Element.createInstance].
 */
// TODO(rafaelw): This is a hack, and is neccesary for the polyfill
// because custom elements are not upgraded during clone()
Stream<DocumentFragment> get instanceCreated {
  if (_instanceCreated == null) {
    _instanceCreated =
        new StreamController<DocumentFragment>(sync: true);
  }
  return _instanceCreated.stream;
}

/**
 * Binds all mustaches recursively starting from the [root] node.
 *
 * Note: this is not an official Model-Driven-Views API; it is intended to
 * support binding the [ShadowRoot]'s content to a model.
 */
// TODO(jmesserly): this is needed to avoid two <template> nodes when using
// bindings in a custom element's template. See also:
// https://github.com/polymer-project/polymer/blob/master/src/bindMDV.js#L68
// Called from:
// https://github.com/polymer-project/polymer/blob/master/src/register.js#L99
void bindModel(Node root, model, [CustomBindingSyntax syntax]) {
  _Bindings._addBindings(root, model, syntax);
}


// TODO(jmesserly): investigate if expandos give us enough performance.

// The expando for storing our MDV wrappers.
//
// In general, we need state associated with the nodes. Rather than having a
// bunch of individual expandos, we keep one per node.
//
// Aside from the potentially helping performance, it also keeps things simpler
// if we decide to integrate MDV into the DOM later, and means less code needs
// to worry about expandos.
final Expando _mdvExpando = new Expando('mdv');

_mdv(node) {
  var wrapper = _mdvExpando[node];
  if (wrapper != null) return wrapper;

  if (node is InputElement) {
    wrapper = new _InputElementExtension(node);
  } else if (node is Element) {
    if (node.isTemplate) {
      wrapper = new _TemplateExtension(node);
    } else {
      wrapper = new _ElementExtension(node);
    }
  } else if (node is Text) {
    wrapper = new _TextExtension(node);
  } else if (node is Node) {
    wrapper = new _NodeExtension(node);
  } else {
    // TODO(jmesserly): this happens for things like CompoundBinding.
    wrapper = node;
  }

  _mdvExpando[node] = wrapper;
  return wrapper;
}
