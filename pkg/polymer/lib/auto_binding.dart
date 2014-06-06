// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.auto_binding;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:template_binding/template_binding.dart';

/**
 * The `d-auto-binding` element extends the template element. It provides a
 * quick and easy way to do data binding without the need to setup a binding
 * delegate or use the [templateBind] call. Both data and event handlers can be
 * bound using the [model].
 *
 * The `d-auto-binding` element acts just like a template that is bound to
 * a model. It stamps its content in the dom adjacent to itself. When the
 * content is stamped, the `template-bound` event is fired.
 *
 * Example:
 *
 *     <template is="d-auto-binding">
 *       <div>Say something: <input value="{{value}}"></div>
 *       <div>You said: {{value}}</div>
 *       <button on-tap="{{buttonTap}}">Tap me!</button>
 *     </template>
 *     <script type="application/dart">
 *       import 'dart:html';
 *       import 'package:polymer/polymer.dart';
 *
 *       main() {
 *         var template = document.querySelector('template');
 *         template.model = new MyModel();
 *       }
 *
 *       class MyModel {
 *         String value = 'something';
 *         buttonTap() => console.log('tap!');
 *       }
 *     </script>
 *
 */
// Dart note: renamed to d-auto-binding to avoid conflict with JS auto-binding.
class AutoBindingElement extends TemplateElement with Polymer, Observable
    implements TemplateBindExtension {

  /// Make template_binding "extension methods" friendly.
  /// Note that [NodeBindExtension] is already implemented by [Polymer].
  TemplateBindExtension _self;

  get model => _self.model;
  set model(value) { _self.model = value; }

  BindingDelegate get bindingDelegate => _self.bindingDelegate;
  set bindingDelegate(BindingDelegate value) { _self.bindingDelegate = value; }

  void clear() => _self.clear();

  @override
  PolymerExpressions get syntax => bindingDelegate;

  AutoBindingElement.created() : super.created() {
    polymerCreated();

    _self = templateBindFallback(this);

    bindingDelegate = makeSyntax();

    // delay stamping until polymer-ready so that auto-binding is not
    // required to load last.
    Polymer.onReady.then((_) {
      attributes['bind'] = '';
      // we don't bother with an explicit signal here, we could ust a MO
      // if necessary
      async((_) {
        // note: this will marshall *all* the elements in the parentNode
        // rather than just stamped ones. We'd need to use createInstance
        // to fix this or something else fancier.
        marshalNodeReferences(parentNode);
        // template stamping is asynchronous so stamping isn't complete
        // by polymer-ready; fire an event so users can use stamped elements
        fire('template-bound');
      });
    });
  }

  PolymerExpressions makeSyntax() => new _AutoBindingSyntax(this);

  DocumentFragment createInstance([model, BindingDelegate delegate]) =>
      _self.createInstance(model, delegate);
}

// Dart note: this is implemented a little differently to keep it in classic
// OOP style. Instead of monkeypatching findController, we override
// getEventHandler to do the right thing.
class _AutoBindingSyntax extends PolymerExpressions {
  final AutoBindingElement _node;

  _AutoBindingSyntax(this._node) : super();

  EventListener getEventHandler(controller, target, String method) => (e) {
    if (controller == null || controller is! Polymer) controller = _node;

    if (controller is Polymer) {
      var args = [e, e.detail, e.currentTarget];

      // Dart note: make sure we dispatch to the model, not the
      // AutoBindingElement instance.
      var obj = controller == _node ? _node.model : controller;
      controller.dispatchMethod(obj, method, args);
    } else {
      throw new StateError('controller $controller is not a '
          'Dart polymer-element.');
    }
  };
}
