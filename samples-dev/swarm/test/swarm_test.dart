// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library swarm_tests;

import 'dart:html';
import 'dart:async';
import 'package:expect/expect.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import '../swarmlib.dart';
import '../swarm_ui_lib/base/base.dart';
import '../swarm_ui_lib/util/utilslib.dart';

// TODO(jmesserly): these would probably be easier to debug if they were written
// in the WebKit layout test style, so we could easy compare that the DOM is
// what we expect it to be after performing some simulated user actions.

void main() {
  useHtmlConfiguration();
  Swarm swarm = new Swarm(useCannedData: true);
  UIStateProxy state = new UIStateProxy(swarm.sections);
  swarm.state = state;
  swarm.run();
  // TODO(jmesserly): should be adding the full stylesheet here
  Dom.addStyle('''
      .story-content {
        -webkit-column-width: 300px;
        -webkit-column-gap: 26px; /* 2em */
      }''');

  getStoryNode() => swarm.frontView.storyView.node;

  getView(Section section) {
    return CollectionUtils.find(
        swarm.frontView.sections.childViews, (view) => view.section == section);
  }

  getHistory(Article article) {
    final feed = article.dataSource;
    return {
      'section': CollectionUtils
          .find(swarm.sections, (s) => s.feeds.indexOf(feed, 0) >= 0)
          .id,
      'feed': feed.id,
      'article': article.id
    };
  }

  test('BackButton', () {
    _serialInvokeAsync([
      () {
        Expect.equals(null, swarm.frontView.storyView); // verify initial state

        // Make sure we've transitioned to the section
        // In the real app, this isn't needed because ConveyorView fires the
        // transition end event before we can click a story.
        SectionView section = getView(swarm.sections[0]);
        section.showSources();
      },
      () {
        final item = swarm.sections[0].feeds[2].articles[1];
        state.loadFromHistory(getHistory(item));

        Expect.equals(item, state.currentArticle.value);

        Expect.isFalse(getStoryNode().classes.contains(CSS.HIDDEN_STORY));

        state.loadFromHistory({});

        Expect.equals(null, state.currentArticle.value);
        Expect.isTrue(getStoryNode().classes.contains(CSS.HIDDEN_STORY));
      }
    ]);
  });

  test('StoryView', () {
    state.clearHistory();

    Expect.isTrue(getStoryNode().classes.contains(CSS.HIDDEN_STORY));

    final dataSourceView =
        swarm.frontView.currentSection.dataSourceView.getSubview(0);
    final itemView = dataSourceView.itemsView.getSubview(0);
    // TODO(jacobr): remove  this null check. This is likely due to tests
    // running without the correct CSS to size the window so that some items
    // are visible.
    if (itemView != null) {
      click(itemView.node);
      state.expectHistory([getHistory(itemView.item)]);
    }
  });

  test('SliderMenu', () {
    Expect.equals(getView(swarm.sections[0]), swarm.frontView.currentSection);

    // Find the first slider menu item, and click on the one next after it.
    click(document.querySelectorAll('.${CSS.SM_ITEM}')[1]);

    Expect.equals(getView(swarm.sections[1]), swarm.frontView.currentSection);

    // Find the first menu item again and click on it.
    click(document.querySelector('.${CSS.SM_ITEM}'));

    Expect.equals(getView(swarm.sections[0]), swarm.frontView.currentSection);
  });
}

/** Triggers the click event, like [http://api.jquery.com/click/] */
click(Element element) {
  // TODO(rnystrom): This should be on the DOM API somewhere.
  MouseEvent event = new MouseEvent('click');
  element.dispatchEvent(event);
}

/** A proxy so we can intercept history calls */
class UIStateProxy extends SwarmState {
  List<Map<String, String>> history;

  UIStateProxy(Sections dataModel) : super(dataModel) {
    clearHistory();
  }

  void pushToHistory() {
    history.add(toHistory());
    super.pushToHistory();
  }

  void clearHistory() {
    history = new List<Map<String, String>>();
  }

  void expectHistory(List<Map<String, String>> entries) {
    Expect.equals(entries.length, history.length);
    for (int i = 0; i < entries.length; i++) {
      Map e = entries[i];
      Map h = history[i];
      Expect.equals(e['article'], h['article']);
    }
    clearHistory();
  }
}

void _serialInvokeAsync(List closures) {
  final length = closures.length;
  if (length > 0) {
    int i = 0;
    void invokeNext() {
      closures[i]();
      i++;
      if (i < length) {
        Timer.run(expectAsync(invokeNext));
      }
    }

    Timer.run(expectAsync(invokeNext));
  }
}
