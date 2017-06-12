# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/env python
#
import re, base64, logging, pickle, httplib2, time, urlparse, urllib2, urllib, StringIO, gzip, zipfile

from google.appengine.ext import webapp, db

from google.appengine.api import taskqueue, urlfetch, memcache, images, users
from google.appengine.ext.webapp.util import login_required
from google.appengine.ext.webapp import template

from django.utils import simplejson as json
from django.utils.html import strip_tags

from oauth2client.appengine import CredentialsProperty
from oauth2client.client import OAuth2WebServerFlow

import encoder

# TODO(jimhug): Allow client to request desired thumb size.
THUMB_SIZE = (57, 57)
READER_API = 'http://www.google.com/reader/api/0'

MAX_SECTIONS = 5
MAX_ARTICLES = 20

class UserData(db.Model):
  credentials = CredentialsProperty()
  sections = db.ListProperty(db.Key)

  def getEncodedData(self, articleKeys=None):
    enc = encoder.Encoder()
    # TODO(jimhug): Only return initially visible section in first reply.
    maxSections = min(MAX_SECTIONS, len(self.sections))
    enc.writeInt(maxSections)
    for section in db.get(self.sections[:maxSections]):
      section.encode(enc, articleKeys)
    return enc.getRaw()


class Section(db.Model):
  title = db.TextProperty()
  feeds = db.ListProperty(db.Key)

  def fixedTitle(self):
    return self.title.split('_')[0]

  def encode(self, enc, articleKeys=None):
    # TODO(jimhug): Need to optimize format and support incremental updates.
    enc.writeString(self.key().name())
    enc.writeString(self.fixedTitle())
    enc.writeInt(len(self.feeds))
    for feed in db.get(self.feeds):
      feed.ensureEncodedFeed()
      enc.writeRaw(feed.encodedFeed3)
      if articleKeys is not None:
        articleKeys.extend(feed.topArticles)

class Feed(db.Model):
  title = db.TextProperty()
  iconUrl = db.TextProperty()
  lastUpdated = db.IntegerProperty()

  encodedFeed3 = db.TextProperty()
  topArticles = db.ListProperty(db.Key)

  def ensureEncodedFeed(self, force=False):
    if force or self.encodedFeed3 is None:
      enc = encoder.Encoder()
      articleSet = []
      self.encode(enc, MAX_ARTICLES, articleSet)
      logging.info('articleSet length is %s' % len(articleSet))
      self.topArticles = articleSet
      self.encodedFeed3 = enc.getRaw()
      self.put()

  def encode(self, enc, maxArticles, articleSet):
    enc.writeString(self.key().name())
    enc.writeString(self.title)
    enc.writeString(self.iconUrl)

    logging.info('encoding feed: %s' % self.title)
    encodedArts = []

    for article in self.article_set.order('-date').fetch(limit=maxArticles):
      encodedArts.append(article.encodeHeader())
      articleSet.append(article.key())

    enc.writeInt(len(encodedArts))
    enc.writeRaw(''.join(encodedArts))


class Article(db.Model):
  feed = db.ReferenceProperty(Feed)

  title = db.TextProperty()
  author = db.TextProperty()
  content = db.TextProperty()
  snippet = db.TextProperty()
  thumbnail = db.BlobProperty()
  thumbnailSize = db.TextProperty()
  srcurl = db.TextProperty()
  date = db.IntegerProperty()

  def ensureThumbnail(self):
    # If our desired thumbnail size has changed, regenerate it and cache.
    if self.thumbnailSize != str(THUMB_SIZE):
       self.thumbnail = makeThumbnail(self.content)
       self.thumbnailSize = str(THUMB_SIZE)
       self.put()

  def encodeHeader(self):
    # TODO(jmesserly): for now always unescape until the crawler catches up
    enc = encoder.Encoder()
    enc.writeString(self.key().name())
    enc.writeString(unescape(self.title))
    enc.writeString(self.srcurl)
    enc.writeBool(self.thumbnail is not None)
    enc.writeString(self.author)
    enc.writeInt(self.date)
    enc.writeString(unescape(self.snippet))
    return enc.getRaw()

class HtmlFile(db.Model):
  content = db.BlobProperty()
  compressed = db.BooleanProperty()
  filename = db.StringProperty()
  author = db.UserProperty(auto_current_user=True)
  date = db.DateTimeProperty(auto_now_add=True)


class UpdateHtml(webapp.RequestHandler):
  def post(self):
    upload_files = self.request.POST.multi.__dict__['_items']
    version = self.request.get('version')
    logging.info('files: %r' % upload_files)
    for data in upload_files:
      if data[0] != 'files': continue
      file = data[1]
      filename = file.filename
      if version:
        filename = '%s-%s' % (version, filename)
      logging.info('upload: %r' % filename)

      htmlFile = HtmlFile.get_or_insert(filename)
      htmlFile.filename = filename

      # If text > (1MB - 1KB) then gzip text to fit in 1MB space
      text = file.value
      if len(text) > 1024*1023:
        data = StringIO.StringIO()
        gz = gzip.GzipFile(str(filename), 'wb', fileobj=data)
        gz.write(text)
        gz.close()
        htmlFile.content = data.getvalue()
        htmlFile.compressed = True
      else:
        htmlFile.content = text
        htmlFile.compressed = False

      htmlFile.put()

    self.redirect('/')

class TopHandler(webapp.RequestHandler):
  @login_required
  def get(self):
    user = users.get_current_user()
    prefs = UserData.get_by_key_name(user.user_id())
    if prefs is None:
      self.redirect('/update/user')
      return

    params = {'files': HtmlFile.all().order('-date').fetch(limit=30)}
    self.response.out.write(template.render('top.html', params))


class MainHandler(webapp.RequestHandler):

  @login_required
  def get(self, name):
    if name == 'dev':
     return self.handleDev()

    elif name == 'login':
      return self.handleLogin()

    elif name == 'upload':
      return self.handleUpload()

    user = users.get_current_user()
    prefs = UserData.get_by_key_name(user.user_id())
    if prefs is None:
      return self.handleLogin()

    html = HtmlFile.get_by_key_name(name)
    if html is None:
      self.error(404)
      return

    self.response.headers['Content-Type'] = 'text/html'

    if html.compressed:
      # TODO(jimhug): This slightly sucks ;-)
      # Can we write directly to the response.out?
      gz = gzip.GzipFile(name, 'rb', fileobj=StringIO.StringIO(html.content))
      self.response.out.write(gz.read())
      gz.close()
    else:
      self.response.out.write(html.content)

    # TODO(jimhug): Include first data packet with html.

  def handleLogin(self):
    user = users.get_current_user()
    # TODO(jimhug): Manage secrets for dart.googleplex.com better.
    # TODO(jimhug): Confirm that we need client_secret.
    flow = OAuth2WebServerFlow(
        client_id='267793340506.apps.googleusercontent.com',
        client_secret='5m8H-zyamfTYg5vnpYu1uGMU',
        scope=READER_API,
        user_agent='swarm')

    callback = self.request.relative_url('/oauth2callback')
    authorize_url = flow.step1_get_authorize_url(callback)

    memcache.set(user.user_id(), pickle.dumps(flow))

    content = template.render('login.html', {'authorize': authorize_url})
    self.response.out.write(content)

  def handleDev(self):
    user = users.get_current_user()
    content = template.render('dev.html', {'user': user})
    self.response.out.write(content)

  def handleUpload(self):
    user = users.get_current_user()
    content = template.render('upload.html', {'user': user})
    self.response.out.write(content)


class UploadFeed(webapp.RequestHandler):
  def post(self):
    upload_files = self.request.POST.multi.__dict__['_items']
    version = self.request.get('version')
    logging.info('files: %r' % upload_files)
    for data in upload_files:
      if data[0] != 'files': continue
      file = data[1]
      logging.info('upload feed: %r' % file.filename)

      data = json.loads(file.value)

      feedId = file.filename
      feed = Feed.get_or_insert(feedId)

      # Find the section to add it to.
      sectionTitle = data['section']
      section = findSectionByTitle(sectionTitle)
      if section != None:
        if feed.key() in section.feeds:
          logging.warn('Already contains feed %s, replacing' % feedId)
          section.feeds.remove(feed.key())

        # Add the feed to the section.
        section.feeds.insert(0, feed.key())
        section.put()

        # Add the articles.
        collectFeed(feed, data)

      else:
        logging.error('Could not find section %s to add the feed to' %
            sectionTitle)

    self.redirect('/')

# TODO(jimhug): Batch these up and request them more aggressively.
class DataHandler(webapp.RequestHandler):
  def get(self, name):
    if name.endswith('.jpg'):
      # Must be a thumbnail
      key = urllib2.unquote(name[:-len('.jpg')])
      article = Article.get_by_key_name(key)
      self.response.headers['Content-Type'] = 'image/jpeg'
      # cache images for 10 hours
      self.response.headers['Cache-Control'] = 'public,max-age=36000'
      article.ensureThumbnail()
      self.response.out.write(article.thumbnail)
    elif name.endswith('.html'):
      # Must be article content
      key = urllib2.unquote(name[:-len('.html')])
      article = Article.get_by_key_name(key)
      self.response.headers['Content-Type'] = 'text/html'
      if article is None:
        content = '<h2>Missing article</h2>'
      else:
        content = article.content
      # cache article content for 10 hours
      self.response.headers['Cache-Control'] = 'public,max-age=36000'
      self.response.out.write(content)
    elif name == 'user.data':
      self.response.out.write(self.getUserData())
    elif name == 'CannedData.dart':
      self.canData()
    elif name == 'CannedData.zip':
      self.canDataZip()
    else:
      self.error(404)

  def getUserData(self, articleKeys=None):
    user = users.get_current_user()
    user_id = user.user_id()

    key = 'data_' + user_id
    # need to flush memcache fairly frequently...
    data = memcache.get(key)
    if data is None:
      prefs = UserData.get_or_insert(user_id)
      if prefs is None:
        # TODO(jimhug): Graceful failure for unknown users.
        pass
      data = prefs.getEncodedData(articleKeys)
      # TODO(jimhug): memcache.set(key, data)

    return data

  def canData(self):
    def makeDartSafe(data):
      return repr(unicode(data))[1:].replace('$', '\\$')

    lines = ['// TODO(jimhug): Work out correct copyright for this file.',
             'class CannedData {']

    user = users.get_current_user()
    prefs = UserData.get_by_key_name(user.user_id())
    articleKeys = []
    data = prefs.getEncodedData(articleKeys)
    lines.append('  static const Map<String,String> data = const {')
    for article in db.get(articleKeys):
      key = makeDartSafe(urllib.quote(article.key().name())+'.html')
      lines.append('    %s:%s, ' % (key, makeDartSafe(article.content)))

    lines.append('    "user.data":%s' % makeDartSafe(data))

    lines.append('  };')

    lines.append('}')
    self.response.headers['Content-Type'] = 'application/dart'
    self.response.out.write('\n'.join(lines))

  # Get canned static data
  def canDataZip(self):
    # We need to zip into an in-memory buffer to get the right string encoding
    # behavior.
    data = StringIO.StringIO()
    result = zipfile.ZipFile(data, 'w')

    articleKeys = []
    result.writestr('data/user.data',
        self.getUserData(articleKeys).encode('utf-8'))
    logging.info('  adding articles %s' % len(articleKeys))
    images = []
    for article in db.get(articleKeys):
      article.ensureThumbnail()
      path = 'data/' + article.key().name() + '.html'
      result.writestr(path.encode('utf-8'), article.content.encode('utf-8'))
      if article.thumbnail:
        path = 'data/' + article.key().name() + '.jpg'
        result.writestr(path.encode('utf-8'), article.thumbnail)

    result.close()
    logging.info('writing CannedData.zip')
    self.response.headers['Content-Type'] = 'multipart/x-zip'
    disposition = 'attachment; filename=CannedData.zip'
    self.response.headers['Content-Disposition'] = disposition
    self.response.out.write(data.getvalue())
    data.close()


class SetDefaultFeeds(webapp.RequestHandler):
  @login_required
  def get(self):
    user = users.get_current_user()
    prefs = UserData.get_or_insert(user.user_id())

    prefs.sections = [
      db.Key.from_path('Section', 'user/17857667084667353155/label/Top'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Design'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Eco'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Geek'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Google'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Seattle'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Tech'),
      db.Key.from_path('Section', 'user/17857667084667353155/label/Web')]

    prefs.put()

    self.redirect('/')

class SetTestFeeds(webapp.RequestHandler):
  @login_required
  def get(self):
    user = users.get_current_user()
    prefs = UserData.get_or_insert(user.user_id())

    sections = []
    for i in range(3):
      s1 = Section.get_or_insert('Test%d' % i)
      s1.title = 'Section %d' % (i+1)

      feeds = []
      for j in range(4):
        label = '%d_%d' % (i, j)
        f1 = Feed.get_or_insert('Test%s' % label)
        f1.title = 'Feed %s' % label
        f1.iconUrl = getFeedIcon('http://google.com')
        f1.lastUpdated = 0
        f1.put()
        feeds.append(f1.key())

        for k in range(8):
          label = '%d_%d_%d' % (i, j, k)
          a1 = Article.get_or_insert('Test%s' % label)
          if a1.title is None:
            a1.feed = f1
            a1.title = 'Article %s' % label
            a1.author = 'anon'
            a1.content = 'Lorem ipsum something or other...'
            a1.snippet = 'Lorem ipsum something or other...'
            a1.thumbnail = None
            a1.srcurl = ''
            a1.date = 0

      s1.feeds = feeds
      s1.put()
      sections.append(s1.key())

    prefs.sections = sections
    prefs.put()

    self.redirect('/')


class UserLoginHandler(webapp.RequestHandler):
  @login_required
  def get(self):
    user = users.get_current_user()
    prefs = UserData.get_or_insert(user.user_id())
    if prefs.credentials:
      http = prefs.credentials.authorize(httplib2.Http())

      response, content = http.request('%s/subscription/list?output=json' %
                                       READER_API)
      self.collectFeeds(prefs, content)
      self.redirect('/')
    else:
      self.redirect('/login')


  def collectFeeds(self, prefs, content):
    data = json.loads(content)

    queue_name = self.request.get('queue_name', 'priority-queue')
    sections = {}
    for feedData in data['subscriptions']:
      feed = Feed.get_or_insert(feedData['id'])
      feed.put()
      category = feedData['categories'][0]
      categoryId = category['id']
      if not sections.has_key(categoryId):
        sections[categoryId] = (category['label'], [])

      # TODO(jimhug): Use Reader preferences to sort feeds in a section.
      sections[categoryId][1].append(feed.key())

      # Kick off a high priority feed update
      taskqueue.add(url='/update/feed', queue_name=queue_name,
                    params={'id': feed.key().name()})

    sectionKeys = []
    for name, (title, feeds) in sections.items():
      section = Section.get_or_insert(name)
      section.feeds = feeds
      section.title = title
      section.put()
      # Forces Top to be the first section
      if title == 'Top': title = '0Top'
      sectionKeys.append( (title, section.key()) )

    # TODO(jimhug): Use Reader preferences API to get users true sort order.
    prefs.sections = [key for t, key in sorted(sectionKeys)]
    prefs.put()


class AllFeedsCollector(webapp.RequestHandler):
  '''Ensures that a given feed object is locally up to date.'''
  def post(self): return self.get()

  def get(self):
    queue_name = self.request.get('queue_name', 'background')
    for feed in Feed.all():
      taskqueue.add(url='/update/feed', queue_name=queue_name,
                    params={'id': feed.key().name()})

UPDATE_COUNT = 4 # The number of articles to request on periodic updates.
INITIAL_COUNT = 40 # The number of articles to get first for a new queue.
SNIPPET_SIZE = 180 # The length of plain-text snippet to extract.
class FeedCollector(webapp.RequestHandler):
  def post(self): return self.get()

  def get(self):
    feedId = self.request.get('id')
    feed = Feed.get_or_insert(feedId)

    if feed.lastUpdated is None:
      self.fetchn(feed, feedId, INITIAL_COUNT)
    else:
      self.fetchn(feed, feedId, UPDATE_COUNT)

    self.response.headers['Content-Type'] = "text/plain"

  def fetchn(self, feed, feedId, n, continuation=None):
    # basic pattern is to read by ARTICLE_COUNT until we hit existing.
    if continuation is None:
      apiUrl = '%s/stream/contents/%s?n=%d' % (
        READER_API, feedId, n)
    else:
      apiUrl = '%s/stream/contents/%s?n=%d&c=%s' % (
        READER_API, feedId, n, continuation)

    logging.info('fetching: %s' % apiUrl)
    result = urlfetch.fetch(apiUrl)

    if result.status_code == 200:
      data = json.loads(result.content)
      collectFeed(feed, data, continuation)
    elif result.status_code == 401:
      self.response.out.write( '<pre>%s</pre>' % result.content)
    else:
      self.response.out.write(result.status_code)

def findSectionByTitle(title):
  for section in Section.all():
    if section.fixedTitle() == title:
      return section
  return None

def collectFeed(feed, data, continuation=None):
  '''
  Reads a feed from the given JSON object and populates the given feed object
  in the datastore with its data.
  '''
  if continuation is None:
    if 'alternate' in data:
      feed.iconUrl = getFeedIcon(data['alternate'][0]['href'])
    feed.title = data['title']
    feed.lastUpdated = data['updated']

  articles = data['items']
  logging.info('%d new articles for %s' % (len(articles), feed.title))

  for articleData in articles:
    if not collectArticle(feed, articleData):
      feed.put()
      return False

  if len(articles) > 0 and data.has_key('continuation'):
    logging.info('would have looked for more articles')
    # TODO(jimhug): Enable this continuation check when more robust
    #self.fetchn(feed, feedId, data['continuation'])

  feed.ensureEncodedFeed(force=True)
  feed.put()
  return True

def collectArticle(feed, data):
  '''
  Reads an article from the given JSON object and populates the datastore with
  it.
  '''
  if not 'title' in data:
    # Skip this articles without titles
    return True

  articleId = data['id']
  article = Article.get_or_insert(articleId)
  # TODO(jimhug): This aborts too early - at lease for one adafruit case.
  if article.date == data['published']:
    logging.info('found existing, aborting: %r, %r' %
      (articleId, article.date))
    return False

  if data.has_key('content'):
    content = data['content']['content']
  elif data.has_key('summary'):
    content = data['summary']['content']
  else:
    content = ''
  #TODO(jimhug): better summary?
  article.content = content
  article.date = data['published']
  article.title = unescape(data['title'])
  article.snippet = unescape(strip_tags(content)[:SNIPPET_SIZE])

  article.feed = feed

  # TODO(jimhug): make this canonical so UX can change for this state
  article.author = data.get('author', 'anonymous')

  article.ensureThumbnail()

  article.srcurl = ''
  if data.has_key('alternate'):
    for alt in data['alternate']:
      if alt.has_key('href'):
        article.srcurl = alt['href']
  return True

def unescape(html):
  "Inverse of Django's utils.html.escape function"
  if not isinstance(html, basestring):
      html = str(html)
  html = html.replace('&#39;', "'").replace('&quot;', '"')
  return html.replace('&gt;', '>').replace('&lt;', '<').replace('&amp;', '&')

def getFeedIcon(url):
  url = urlparse.urlparse(url).netloc
  return 'http://s2.googleusercontent.com/s2/favicons?domain=%s&alt=feed' % url

def findImage(text):
  img = findImgTag(text, 'jpg|jpeg|png')
  if img is not None:
    return img

  img = findVideoTag(text)
  if img is not None:
    return img

  img = findImgTag(text, 'gif')
  return img

def findImgTag(text, extensions):
  m = re.search(r'src="(http://\S+\.(%s))(\?.*)?"' % extensions, text)
  if m is None:
    return None
  return m.group(1)

def findVideoTag(text):
  # TODO(jimhug): Add other videos beyond youtube.
  m = re.search(r'src="http://www.youtube.com/(\S+)/(\S+)[/|"]', text)
  if m is None:
    return None

  return 'http://img.youtube.com/vi/%s/0.jpg' % m.group(2)

def makeThumbnail(text):
  url = None
  try:
    url = findImage(text)
    if url is None:
      return None
    return generateThumbnail(url)
  except:
    logging.info('error decoding: %s' % (url or text))
    return None

def generateThumbnail(url):
  logging.info('generating thumbnail: %s' % url)
  thumbWidth, thumbHeight = THUMB_SIZE

  result = urlfetch.fetch(url)
  img = images.Image(result.content)

  w, h = img.width, img.height

  aspect = float(w) / h
  thumbAspect = float(thumbWidth) / thumbHeight

  if aspect > thumbAspect:
    # Too wide, so crop on the sides.
    normalizedCrop = (w - h * thumbAspect) / (2.0 * w)
    img.crop(normalizedCrop, 0., 1. - normalizedCrop, 1. )
  elif aspect < thumbAspect:
    # Too tall, so crop out the bottom.
    normalizedCrop = (h - w / thumbAspect) / h
    img.crop(0., 0., 1., 1. - normalizedCrop)

  img.resize(thumbWidth, thumbHeight)

  # Chose JPEG encoding because informal experiments showed it generated
  # the best size to quality ratio for thumbnail images.
  nimg = img.execute_transforms(output_encoding=images.JPEG)
  logging.info('  finished thumbnail: %s' % url)

  return nimg

class OAuthHandler(webapp.RequestHandler):

  @login_required
  def get(self):
    user = users.get_current_user()
    flow = pickle.loads(memcache.get(user.user_id()))
    if flow:
      prefs = UserData.get_or_insert(user.user_id())
      prefs.credentials = flow.step2_exchange(self.request.params)
      prefs.put()
      self.redirect('/update/user')
    else:
      pass


def main():
  application = webapp.WSGIApplication(
      [
      ('/data/(.*)', DataHandler),

      # This is called periodically from cron.yaml.
      ('/update/allFeeds', AllFeedsCollector),
      ('/update/feed', FeedCollector),
      ('/update/user', UserLoginHandler),
      ('/update/defaultFeeds', SetDefaultFeeds),
      ('/update/testFeeds', SetTestFeeds),
      ('/update/html', UpdateHtml),
      ('/update/upload', UploadFeed),
      ('/oauth2callback', OAuthHandler),

      ('/', TopHandler),
      ('/(.*)', MainHandler),
      ],
      debug=True)
  webapp.util.run_wsgi_app(application)

if __name__ == '__main__':
  main()
