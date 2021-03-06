_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Article = require '../../../../../models/article'
Backbone = require 'backbone'
fixtures = require '../../../../../../test/helpers/fixtures'
{ fabricate } = require 'antigravity'
{ resolve } = require 'path'

describe 'EditAdmin', ->

  beforeEach (done) ->
    benv.setup =>
      tmpl = resolve __dirname, '../index.jade'
      benv.render tmpl, _.extend(fixtures().locals,
        article: @article = new Article fixtures().article
      ), =>
        benv.expose $: require('jquery')
        Backbone.$ = $
        sinon.stub Backbone, 'sync'
        EditAdmin = benv.requireWithJadeify '../index',
          ['featuredListTemplate']
        EditAdmin::setupAuthorAutocomplete = sinon.stub()
        EditAdmin::setupFairAutocomplete = sinon.stub()
        EditAdmin::setupPartnerAutocomplete = sinon.stub()
        EditAdmin::setupAuctionAutocomplete = sinon.stub()
        EditAdmin::setupVerticalAutocomplete = sinon.stub()
        EditAdmin::setupShowsAutocomplete = sinon.stub()
        EditAdmin::setupBiographyAutocomplete = sinon.stub()
        EditAdmin::setupSlug = sinon.stub()
        EditAdmin::setupPublishDate = sinon.stub()
        @view = new EditAdmin el: $('#edit-admin'), article: @article
        done()

  afterEach ->
    benv.teardown(false)
    Backbone.sync.restore()

  describe '#onOpen', ->

    it 'fetches featured and mentioned articles', ->
      @view.article.fetchFeatured = sinon.stub()
      @view.article.fetchMentioned = sinon.stub()
      @view.onOpen()
      @view.article.fetchFeatured.called.should.be.ok
      @view.article.fetchMentioned.called.should.be.ok

  describe '#renderFeatured', ->

    it 'renders the featured artists', ->
      artist = fabricate('artist')
      artist.name = 'Andy Foobar'
      @view.article.featuredArtists.set [artist]
      @view.renderFeatured()
      @view.$el.html().should.containEql 'Andy Foobar'

    it 'renders primary featured', ->
      artist = fabricate('artist')
      artist.name = 'Andy Moobar'
      @view.article.featuredPrimaryArtists.set [artist]
      @view.renderFeatured()
      @view.$el.html().should.containEql 'Andy Moobar'

  describe '#featureFromInput', ->

    it 'adds a featured artist from a url put in an input', ->
      @view.article.featuredArtists.add = sinon.stub()
      @view.featureFromInput('Artists')(
        currentTarget: $ "<input value='/andy-warhol' />"
      )
      Backbone.sync.args[0][1].id.should.equal 'andy-warhol'

  describe '#featureMentioned', ->

    it 'adds a featured article on clicking a mention', ->
      @view.article.featuredArtists.set { id: 'foo', artist: {} }
      @view.article.mentionedArtists.set { id: 'bar', artist: {} }
      @view.featureMentioned('Artists')(
        currentTarget: $ "<input data-id='bar' />"
      )
      (@view.article.featuredArtists.get('bar')?).should.be.ok

  describe '#onAuthorSelect', ->

    it 'changes the author', ->
      global.confirm = -> true
      @view.onAuthorSelect {}, { id: 'foo' }
      @view.article.get('author_id').should.equal 'foo'
      delete global.confirm

