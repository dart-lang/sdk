// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

// Utility functions:
String safeHTML(String value) {
  // TODO(terry): TBD
  return value;
}

/* Data Model */
class Friend {
  String name;
  String phone;
  int age;
  int friendsCircle, familyCircle, workCircle;

  Friend(this.name, this.phone, this.age,
         this.friendsCircle, this.familyCircle, this.workCircle);
}

/* Simple template:
   ================

  template HTML FriendList(List<Friend> friends) {
    <div>Friends:
      <ul>
        ${#each friends}          // Iterates over each friend
          <li>${name}</li>        // Scope of block is Friend type
        ${/each}
      </ul>
    </div>
  }
*/
class FriendList /*extends Template*/ {
  Element _fragment;

  // ${#each friends}
  each_0(List items, Element parent) {
    for (var item in items) {
      var e0 = new Element.html('<li></li>');      // Node before injection
      e0.innerHTML = inject_0(item);
      parent.elements.add(e0);
    }
  }

  // ${name}
  String inject_0(item) {
    return safeHTML('''${item.name}''');
  }

  FriendList(List<Friend> friends) {
    _fragment = new Element.tag('div');
    Element e0 = new Element.html('<div>Friends:</div>');
    _fragment.elements.add(e0);
    Element e0_0 = new Element.html('<ul></ul>');  // Node before #each
    e0.elements.add(e0_0);
    each_0(friends, e0_0);
  }

  Element get root => _fragment.nodes.first;

  String toString(){
    return _fragment.innerHTML;
  }
}


/* More template control:
   ======================

  template HTML FriendEntry(Friend friend) {
    <li>
      ${#with friend}
        <span>${name}</span>
        ${#if (age < 18)}
          <span class=”left-space”>child</span>
        ${#else}
          <span class=”left-space”>adult</span>
        ${/if}
        <span class=”left-space”>circles = ${friendCircle + familyCircle + workCircle}</span>
      ${/friend}
    </li>
  }
*/
class FriendEntry /*extends Template*/ {
  Element _fragment;

  // ${#with friend}
  with_0(Friend item, Element parent) {
    var e0 = new Element.html('<span></span>');  // Node before injection
    e0.innerHTML = inject_0(item);
    parent.elements.add(e0);

    // ${#if expression} 
    if (if_0(item)) {
      var e1 = new Element.html('<span class="left-space">child</span>');
      parent.elements.add(e1);
    } else {
      var e2 = new Element.html('<span class="left-space">adult</span>');
      parent.elements.add(e2);
    }

    // Node before injection.
    var e3 = new Element.html('<span class="left-space"></span>');
    e3.innerHTML = inject_1(item);
    parent.elements.add(e3);
  }

  // expression (age < 18)}
  bool if_0(var item) {
    return (item.age < 18);
  }

  // ${name}
  String inject_0(item) {
    return safeHTML('''${item.name}''');
  }

  // ${friendCircle + family.Circle + workCircle
  String inject_1(item) {
    return safeHTML('circles = ${item.friendsCircle + item.familyCircle + item.workCircle}');
  }

  FriendEntry(Friend friend) {
    _fragment = new Element.tag('div');
    Element e0 = new Element.html('<li></li>');  // Node before #with
    _fragment.elements.add(e0);
    with_0(friend, e0);
  }

  Element get root => _fragment.nodes.first;

  String toString(){
    return _fragment.innerHTML;
  }
}


/* Template with events:
   =====================

  template HTML FriendEntryEvents(Friend friend) {
   <li>
     ${#with friend}
       <span var=friendElem style="cursor: pointer;">${name}</span>
       ${#if (age < 18)}
         <span class=”left-space”>child</span>
       ${#else}
         <span class=”left-space”>adult</span>
       ${/if}
       <span class=”left-space”>circles = ${friendCircle + familyCircle + workCircle}</span>
     ${/friend}
   </li>
  }
*/
class FriendEntryEvents /*extends Template*/ {
  Element _fragment;
  var _friendElem;

  get friendElem => _friendElem;

  // ${#with friend}
  with_0(Friend item, Element parent) {
    _friendElem = new Element.html('<span style="cursor: pointer;"></span>');  // Node before injection
    _friendElem.innerHTML = inject_0(item);
   parent.elements.add(_friendElem);

   // ${#if expression} 
   if (if_0(item)) {
     var e1 = new Element.html('<span class="left-space">child</span>');
     parent.elements.add(e1);
   } else {
     var e2 = new Element.html('<span class="left-space">adult</span>');
     parent.elements.add(e2);
   }

   // Node before injection.
   var e3 = new Element.html('<span class="left-space"></span>');
   e3.innerHTML = inject_1(item);
   parent.elements.add(e3);
  }

  // expression (age < 18)}
  bool if_0(var item) {
   return (item.age < 18);
  }

  // ${name}
  String inject_0(item) {
   return safeHTML('''${item.name}''');
  }

  // ${friendCircle + family.Circle + workCircle
  String inject_1(item) {
   return safeHTML('circles = ${item.friendsCircle + item.familyCircle + item.workCircle}');
  }

  FriendEntryEvents(Friend friend) {
   _fragment = new Element.tag('div');
   Element e0 = new Element.html('<li></li>');  // Node before #with
   _fragment.elements.add(e0);
   with_0(friend, e0);
  }

  Element get root => _fragment.nodes.first;

  String toString(){
   return _fragment.innerHTML;
  }
}


void main() {
  // Setup style sheet for page.
  document.head.elements.add(new Element.html('<style>.left-space { margin-left: 10px; }</style>'));

  // Create data model.
  List<Friend> friends = new List<Friend>();
  friends.add(new Friend('Tom','425.123.4567', 35, 20, 10, 40));
  friends.add(new Friend('Sue','802.987.6543', 23, 53, 25, 80));
  friends.add(new Friend('Bill','617.123.4444', 50, 10, 5, 110));

  // Simple template.
  document.body.elements.add(new FriendList(friends).root);

  // Use control template.
  document.body.elements.add(new FriendEntry(friends[0]).root);

  // Template with Events:
  var clickableFriend = new FriendEntryEvents(friends[0]);
  document.body.elements.add(clickableFriend.root);
  clickableFriend.friendElem.on.click.add((e) {
    var elemStyle = e.srcElement.style;
    String toggleColor = elemStyle.getPropertyValue("background-color") == "red" ? "white" : "red";
    elemStyle.setProperty("background-color", "${toggleColor}");
  });

  // Calling template inside of a template:
//  document.body.elements.add(new Templates(friends).root);
}
