// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstance extends EventTarget {

  final SVGElementInstanceList childNodes;

  final SVGElement correspondingElement;

  final SVGUseElement correspondingUseElement;

  final SVGElementInstance firstChild;

  final SVGElementInstance lastChild;

  final SVGElementInstance nextSibling;

  final SVGElementInstance parentNode;

  final SVGElementInstance previousSibling;

  SVGElementInstanceEvents get on();

  void _addEventListener(String type, EventListener listener, [bool useCapture]);

  bool _dispatchEvent(Event event);

  void _removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface SVGElementInstanceEvents extends Events {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get input();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get reset();

  EventListenerList get resize();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get submit();

  EventListenerList get unload();
}
