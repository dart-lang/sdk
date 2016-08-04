// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_ref_element;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

import 'class_ref.dart';
import 'class_ref_as_value.dart';
import 'code_ref.dart';
import 'error_ref.dart';
import 'function_ref.dart';
import 'library_ref.dart';
import 'library_ref_as_value.dart';
import 'script_ref.dart';
import 'observatory_element.dart';

class ServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published bool internal = false;
  @published String expandKey;
  ServiceRefElement.created() : super.created();

  void refChanged(oldValue) {
    notifyPropertyChange(#url, "", url);
    notifyPropertyChange(#name, [], name);
    notifyPropertyChange(#nameIsEmpty, 0, 1);
    notifyPropertyChange(#hoverText, "", hoverText);
  }

  String get url {
    if (ref == null) {
      return 'NULL REF';
    }
    return gotoLink('/inspect', ref);
  }

  String get serviceId {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.id;
  }

  String get hoverText {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.vmName;
  }

  String get name {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.name;
  }

  // Workaround isEmpty not being useable due to missing @MirrorsUsed.
  bool get nameIsEmpty {
    return (name == null) || name.isEmpty;
  }


  @published bool expanded = false;
  dynamic expander() {
    return expandEvent;
  }
  void expandEvent(bool expand, Function onDone) {
    if (expand) {
      ref.reload().then((result) {
        ref = result;
        notifyPropertyChange(#ref, 0, 1);
        expanded = true;
      }).whenComplete(onDone);
    } else {
      expanded = false;
      onDone();
    }
  }
}


@CustomTag('any-service-ref')
class AnyServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published String expandKey;
  @published bool asValue = false;
  AnyServiceRefElement.created() : super.created();

  Element _constructElementForRef() {
    var type = ref.type;
    switch (type) {
     case 'Class':
        if (asValue) {
          ClassRefAsValueElement element =
            new Element.tag('class-ref-as-element');
          element.ref = ref;
          return element;
        }
        return new ClassRefElement(ref.isolate,
                                   ref as M.ClassRef,
                                   queue: app.queue);
      case 'Code':
        return new CodeRefElement(ref.isolate, ref as M.Code, queue: app.queue);
      case 'Context':
        ServiceRefElement element = new Element.tag('context-ref');
        element.ref = ref;
        return element;
      case 'Error':
        return new ErrorRefElement(ref as M.ErrorRef, queue: app.queue);
      case 'Field':
        ServiceRefElement element = new Element.tag('field-ref');
        element.ref = ref;
        return element;
      case 'Function':
        return new FunctionRefElement(ref.isolate,
                                      ref as M.FunctionRef,
                                      queue: app.queue);
      case 'Library':
        if (asValue) {
          LibraryRefAsValueElement element =
              new Element.tag('library-ref-as-value');
          element.ref = ref;
          return element;
        }
        return new LibraryRefElement(ref.isolate,
                                     ref as M.LibraryRef,
                                     queue: app.queue);
      case 'Object':
        ServiceRefElement element = new Element.tag('object-ref');
        element.ref = ref;
        return element;
      case 'Script':
        return new ScriptRefElement(ref.isolate,
                                    ref as M.ScriptRef,
                                    queue: app.queue);
      case 'Instance':
      case 'Sentinel':
        ServiceRefElement element = new Element.tag('instance-ref');
        element.ref = ref;
        if (expandKey != null) {
          element.expandKey = expandKey;
        }
        return element;
      default:
        SpanElement element = new Element.tag('span');
        element.text = "<<Unknown service ref: $ref>>";
        return element;
    }
  }

  refChanged(oldValue) {
    // Remove the current view.
    children.clear();
    if (ref == null) {
      Logger.root.info('Viewing null object.');
      return;
    }
    var type = ref.type;
    var element = _constructElementForRef();
    if (element == null) {
      Logger.root.info('Unable to find a ref element for \'${type}\'');
      return;
    }
    children.add(element);
  }
}

@CustomTag('object-ref')
class ObjectRefElement extends ServiceRefElement {
  ObjectRefElement.created() : super.created();
}
