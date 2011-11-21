// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstance extends EventTarget {

  SVGElementInstanceList get childNodes();

  SVGElement get correspondingElement();

  SVGUseElement get correspondingUseElement();

  SVGElementInstance get firstChild();

  SVGElementInstance get lastChild();

  SVGElementInstance get nextSibling();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onbeforecopy();

  void set onbeforecopy(EventListener value);

  EventListener get onbeforecut();

  void set onbeforecut(EventListener value);

  EventListener get onbeforepaste();

  void set onbeforepaste(EventListener value);

  EventListener get onblur();

  void set onblur(EventListener value);

  EventListener get onchange();

  void set onchange(EventListener value);

  EventListener get onclick();

  void set onclick(EventListener value);

  EventListener get oncontextmenu();

  void set oncontextmenu(EventListener value);

  EventListener get oncopy();

  void set oncopy(EventListener value);

  EventListener get oncut();

  void set oncut(EventListener value);

  EventListener get ondblclick();

  void set ondblclick(EventListener value);

  EventListener get ondrag();

  void set ondrag(EventListener value);

  EventListener get ondragend();

  void set ondragend(EventListener value);

  EventListener get ondragenter();

  void set ondragenter(EventListener value);

  EventListener get ondragleave();

  void set ondragleave(EventListener value);

  EventListener get ondragover();

  void set ondragover(EventListener value);

  EventListener get ondragstart();

  void set ondragstart(EventListener value);

  EventListener get ondrop();

  void set ondrop(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onfocus();

  void set onfocus(EventListener value);

  EventListener get oninput();

  void set oninput(EventListener value);

  EventListener get onkeydown();

  void set onkeydown(EventListener value);

  EventListener get onkeypress();

  void set onkeypress(EventListener value);

  EventListener get onkeyup();

  void set onkeyup(EventListener value);

  EventListener get onload();

  void set onload(EventListener value);

  EventListener get onmousedown();

  void set onmousedown(EventListener value);

  EventListener get onmousemove();

  void set onmousemove(EventListener value);

  EventListener get onmouseout();

  void set onmouseout(EventListener value);

  EventListener get onmouseover();

  void set onmouseover(EventListener value);

  EventListener get onmouseup();

  void set onmouseup(EventListener value);

  EventListener get onmousewheel();

  void set onmousewheel(EventListener value);

  EventListener get onpaste();

  void set onpaste(EventListener value);

  EventListener get onreset();

  void set onreset(EventListener value);

  EventListener get onresize();

  void set onresize(EventListener value);

  EventListener get onscroll();

  void set onscroll(EventListener value);

  EventListener get onsearch();

  void set onsearch(EventListener value);

  EventListener get onselect();

  void set onselect(EventListener value);

  EventListener get onselectstart();

  void set onselectstart(EventListener value);

  EventListener get onsubmit();

  void set onsubmit(EventListener value);

  EventListener get onunload();

  void set onunload(EventListener value);

  SVGElementInstance get parentNode();

  SVGElementInstance get previousSibling();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
