// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/** The top-level collection of all sections for a user. */
// TODO(jimhug): This is known as UserData in the server model.
class Sections extends IterableBase<Section> {
  final List<Section> _sections;

  Sections(this._sections);

  operator [](int i) => _sections[i];

  int get length => _sections.length;

  List<String> get sectionTitles => _sections.map((s) => s.title).toList();

  void refresh() {
    // TODO(jimhug): http://b/issue?id=5351067
  }

  /**
   * Find the Section object that has a given title.
   * This is used to integrate well with [ConveyorView].
   */
  Section findSection(String name) {
    return CollectionUtils.find(_sections, (sect) => sect.title == name);
  }

  // TODO(jimhug): Track down callers!
  Iterator<Section> get iterator => _sections.iterator;

  // TODO(jimhug): Better support for switching between local dev and server.
  static bool get runningFromFile {
    return window.location.protocol.startsWith('file:');
  }

  static String get home {
    // TODO(jmesserly): window.location.origin not available on Safari 4.
    // Move this workaround to the DOM code. See bug 5389503.
    return '${window.location.protocol}//${window.location.host}';
  }

  // This method is exposed for tests.
  static void initializeFromData(String data, void callback(Sections sects)) {
    final decoder = new Decoder(data);
    int nSections = decoder.readInt();
    final sections = new List<Section>();

    for (int i = 0; i < nSections; i++) {
      sections.add(Section.decode(decoder));
    }
    callback(new Sections(sections));
  }

  static void initializeFromUrl(
      bool useCannedData, void callback(Sections sections)) {
    if (Sections.runningFromFile || useCannedData) {
      initializeFromData(CannedData.data['user.data'], callback);
    } else {
      // TODO(jmesserly): display an error if we fail here! Silent failure bad.
      HttpRequest
          .getString('data/user.data')
          .then(EventBatch.wrap((responseText) {
        // TODO(jimhug): Nice response if get error back from server.
        // TODO(jimhug): Might be more efficient to parse request
        // in sections.
        initializeFromData(responseText, callback);
      }));
    }
  }

  Section findSectionById(String id) {
    return CollectionUtils.find(_sections, (section) => section.id == id);
  }

  /**
   * Given the name of a section, find its index in the set.
   */
  int findSectionIndex(String name) {
    for (int i = 0; i < _sections.length; i++) {
      if (name == _sections[i].title) {
        return i;
      }
    }
    return -1;
  }

  List<Section> get sections => _sections;

  // TODO(jmesserly): this should be a property
  bool get isEmpty => length == 0;
}

/** A collection of data sources representing a page in the UI. */
class Section {
  final String id;
  final String title;
  ObservableList<Feed> feeds;

  // Public for testing. TODO(jacobr): find a cleaner solution.
  Section(this.id, this.title, this.feeds);

  void refresh() {
    for (final feed in feeds) {
      // TODO(jimhug): http://b/issue?id=5351067
    }
  }

  static Section decode(Decoder decoder) {
    final sectionId = decoder.readString();
    final sectionTitle = decoder.readString();

    final nSources = decoder.readInt();
    final feeds = new ObservableList<Feed>();
    for (int j = 0; j < nSources; j++) {
      feeds.add(Feed.decode(decoder));
    }
    return new Section(sectionId, sectionTitle, feeds);
  }

  Feed findFeed(String id_) {
    return CollectionUtils.find(feeds, (feed) => feed.id == id_);
  }
}

/** Provider of a news feed. */
class Feed {
  String id;
  final String title;
  final String iconUrl;
  final String description;
  ObservableList<Article> articles;
  ObservableValue<bool> error; // TODO(jimhug): Check if dead code.

  Feed(this.id, this.title, this.iconUrl, {this.description: ''})
      : articles = new ObservableList<Article>(),
        error = new ObservableValue<bool>(false);

  static Feed decode(Decoder decoder) {
    final sourceId = decoder.readString();
    final sourceTitle = decoder.readString();
    final sourceIcon = decoder.readString();
    final feed = new Feed(sourceId, sourceTitle, sourceIcon);
    final nItems = decoder.readInt();

    for (int i = 0; i < nItems; i++) {
      feed.articles.add(Article.decodeHeader(feed, decoder));
    }
    return feed;
  }

  Article findArticle(String id_) {
    return CollectionUtils.find(articles, (article) => article.id == id_);
  }

  void refresh() {}
}

/** A single article or posting to display. */
class Article {
  final String id;
  DateTime date;
  final String title;
  final String author;
  final bool hasThumbnail;
  String textBody; // TODO(jimhug): rename to snippet.
  final Feed dataSource; // TODO(jimhug): rename to feed.
  String _htmlBody;
  String srcUrl;
  final ObservableValue<bool> unread; // TODO(jimhug): persist to server.

  bool error; // TODO(jimhug): Check if this is dead and remove.

  Article(this.dataSource, this.id, this.date, this.title, this.author,
      this.srcUrl, this.hasThumbnail, this.textBody,
      {htmlBody: null, bool unread: true, this.error: false})
      : unread = new ObservableValue<bool>(unread),
        this._htmlBody = htmlBody;

  String get htmlBody {
    _ensureLoaded();
    return _htmlBody;
  }

  String get dataUri {
    return SwarmUri
        .encodeComponent(id)
        .replaceAll('%2F', '/')
        .replaceAll('%253A', '%3A');
  }

  String get thumbUrl {
    if (!hasThumbnail) return null;

    var home;
    if (Sections.runningFromFile) {
      home = 'http://dart.googleplex.com';
    } else {
      home = Sections.home;
    }
    // By default images from the real server are cached.
    // Bump the version flag if you change the thumbnail size, and you want to
    // get the new images. Our server ignores the query params but it gets
    // around appengine server side caching and the client side cache.
    return 'data/$dataUri.jpg';
  }

  // TODO(jimhug): need to return a lazy Observable<String> and also
  //   add support for preloading.
  void _ensureLoaded() {
    if (_htmlBody != null) return;

    var name = '$dataUri.html';
    if (Sections.runningFromFile) {
      _htmlBody = CannedData.data[name];
    } else {
      // TODO(jimhug): Remove this truly evil synchronoush xhr.
      final req = new HttpRequest();
      req.open('GET', 'data/$name', async: false);
      req.send();
      _htmlBody = req.responseText;
    }
  }

  static Article decodeHeader(Feed source, Decoder decoder) {
    final id = decoder.readString();
    final title = decoder.readString();
    final srcUrl = decoder.readString();
    final hasThumbnail = decoder.readBool();
    final author = decoder.readString();
    final dateInSeconds = decoder.readInt();
    final snippet = decoder.readString();
    final date = new DateTime.fromMillisecondsSinceEpoch(dateInSeconds * 1000,
        isUtc: true);
    return new Article(
        source, id, date, title, author, srcUrl, hasThumbnail, snippet);
  }
}
