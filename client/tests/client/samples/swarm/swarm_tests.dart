// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('swarm_tests');

#import('../../../../base/base.dart');
#import('../../../../html/html.dart');
#import('../../../../samples/swarm/swarmlib.dart');
#import('../../../../testing/unittest/unittest.dart');
#import('../../../../view/view.dart');
#import('../../../../util/utilslib.dart');

void main() {
  new SwarmTests().run();
}

// TODO(jmesserly): these would probably be easier to debug if they were written
// in the WebKit layout test style, so we could easy compare that the DOM is
// what we expect it to be after performing some simulated user actions.

class SwarmTests extends UnitTestSuite {
  Swarm swarm;
  UIStateProxy state;

  SwarmTests() : super() {
    swarm = new Swarm();
    swarm.state = state = new UIStateProxy(swarm.sections);
    swarm.run();
  }

  Element get storyNode() => swarm.frontView.storyView.node;

  View getView(Section section) {
    return CollectionUtils.find(swarm.frontView.sections.childViews,
        (view) => view.section == section);
  }

  Map<String, String> getHistory(Article article) {
    final feed = article.dataSource;
    return {
      'section': CollectionUtils.find(swarm.sections,
          (s) => s.feeds.indexOf(feed, 0) >= 0).id,
      'feed': feed.id,
      'article': article.id
    };
  }

  void setUpTestSuite() {
    // TODO(jmesserly): should be adding the full stylesheet here
    Dom.addStyle('''
        .story-content {
          -webkit-column-width: 300px;
          -webkit-column-gap: 26px; /* 2em */
        }''');
    addTest(testBackButton);
    addTest(testStoryView);
    addTest(testSliderMenu);
  }

  /** Triggers the click event, like [http://api.jquery.com/click/] */
  _click(Element element) {
    // TODO(rnystrom): This should be on the DOM API somewhere.
    MouseEvent event = document.createEvent('MouseEvents');
    event.initMouseEvent('click', true, true, window, 1, 0, 0, 0, 0,
        false, false, false, false, 0, null);
    element.on.click.dispatch(event);
  }

  void testBackButton() {
    Expect.equals(null, swarm.frontView.storyView); // verify initial state

    // Make sure we've transitioned to the section
    // In the real app, this isn't needed because ConveyorView fires the
    // transition end event before we can click a story.
    SectionView section = getView(swarm.sections[0]);
    section.showSources();

    final item = swarm.sections[0].feeds[2].articles[1];
    state.loadFromHistory(getHistory(item));

    Expect.equals(item, state.currentArticle.value);

    Expect.isFalse(storyNode.classes.contains(CSS.HIDDEN_STORY));

    state.loadFromHistory({});

    Expect.equals(null, state.currentArticle.value);
    Expect.isTrue(storyNode.classes.contains(CSS.HIDDEN_STORY));
  }

  void testStoryView() {
    state.clearHistory();

    Expect.isTrue(storyNode.classes.contains(CSS.HIDDEN_STORY));

    final dataSourceView =
        swarm.frontView.currentSection.dataSourceView.getSubview(0);
    final itemView = dataSourceView.itemsView.getSubview(0);
    _click(itemView.node);
    state.expectHistory([getHistory(itemView.item)]);
  }

  void testSliderMenu() {
    Expect.equals(getView(swarm.sections[0]), swarm.frontView.currentSection);

    // Find the first slider menu item, and click on the one next after it.
    _click(document.queryAll('.${CSS.SM_ITEM}')[1]);

    Expect.equals(getView(swarm.sections[1]), swarm.frontView.currentSection);

    // Find the first menu item again and click on it.
    _click(document.query('.${CSS.SM_ITEM}'));

    Expect.equals(getView(swarm.sections[0]), swarm.frontView.currentSection);
  }
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
