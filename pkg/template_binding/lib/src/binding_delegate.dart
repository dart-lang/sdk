// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/**
 * Template Bindings native features enables a wide-range of use cases,
 * but (by design) don't attempt to implement a wide array of specialized
 * behaviors.
 *
 * Enabling these features is a matter of implementing and registering a
 * BindingDelegate. A binding delegate is an object which contains one or more
 * delegation functions which implement specialized behavior. This object is
 * registered via [TemplateBindExtension.bindingDelegate]:
 *
 * HTML:
 *     <template bind>
 *       {{ What!Ever('crazy')->thing^^^I+Want(data) }}
 *     </template>
 *
 * Dart:
 *     class MySyntax extends BindingDelegate {
 *       prepareBinding(path, name, node) {
 *         // The magic happens here!
 *       }
 *     }
 *     ...
 *     templateBind(query('template'))
 *         ..bindingDelegate = new MySyntax()
 *         ..model = new MyModel();
 *
 *
 * See
 * <http://www.polymer-project.org/platform/template.html#binding-delegate-api>
 * for more information about the binding delegate.
 */
// TODO(jmesserly): need better api docs here. The link above seems out of date.
class BindingDelegate {
  /**
   * Prepares a binding. This is called immediately after parsing a mustache
   * token with `{{ path }}` in the context of the [node] and the property named
   * [name]. This should return a function that will be passed the actual
   * node and model, and either returns null or an object with a `value`
   * property. This allows the syntax to reinterpret the model for each binding.
   */
  PrepareBindingFunction prepareBinding(String path, String name, Node node)
      => null;

  /**
   * Returns a function that can optionally replace the model that will be
   * passed to [TemplateBindExtension.createInstance]. This can be used to
   * implement syntax such as `<template repeat="{{ item in items }}">` by
   * ensuring that the returned model has the "item" name available.
   */
  PrepareInstanceModelFunction prepareInstanceModel(Element template) => null;

  /**
   * Returns a function that will be called whenever the position of an item
   * inside this template changes.
   */
  PrepareInstancePositionChangedFunction prepareInstancePositionChanged(
      Element template) => null;

  Expando<_InstanceBindingMap> _bindingMaps;

  // TODO(jmesserly): if we have use this everywhere, we can avoid many
  // delegate != null checks throughout the code, simplifying things.
  // For now we just use it for _bindingMaps.
  static final _DEFAULT = new BindingDelegate();
}

typedef PrepareBindingFunction(model, Node node, bool oneTime);

typedef PrepareInstanceModelFunction(model);

typedef PrepareInstancePositionChangedFunction(TemplateInstance instance,
    int index);
