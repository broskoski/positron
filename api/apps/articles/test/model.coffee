_ = require 'underscore'
moment = require 'moment'
{ db, fabricate, empty, fixtures } = require '../../../test/helpers/db'
Article = require '../model'
{ ObjectId } = require 'mongojs'
express = require 'express'
fabricateGravity = require('antigravity').fabricate
gravity = require('antigravity').server
app = require('express')()
bodyParser = require 'body-parser'

describe 'Article', ->

  before (done) ->
    app.use '/__gravity', gravity
    @server = app.listen 5000, ->
      done()

  after ->
    @server.close()

  beforeEach (done) ->
    empty ->
      fabricate 'articles', _.times(10, -> {}), ->
        done()

  describe '#where', ->

    it 'can return all articles along with total and counts', (done) ->
      Article.where {}, (err, res) ->
        { total, count, results } = res
        total.should.equal 10
        count.should.equal 10
        results[0].title.should.equal 'Top Ten Booths'
        done()

    it 'can return articles by an author', (done) ->
      fabricate 'articles', {
        author_id: aid = ObjectId '4d8cd73191a5c50ce220002a'
        title: 'Hello Wurld'
      }, ->
        Article.where { author_id: aid.toString() }, (err, res) ->
          { total, count, results } = res
          total.should.equal 11
          count.should.equal 1
          results[0].title.should.equal 'Hello Wurld'
          done()

    it 'can return articles by published', (done) ->
      fabricate 'articles', _.times(3, -> { published: false, title: 'Moo baz' }), ->
        Article.where { published: false }, (err, { total, count, results }) ->
          total.should.equal 13
          count.should.equal 3
          results[0].title.should.equal 'Moo baz'
          done()

    it 'errors for bad queries', (done) ->
      Article.where { foo: 'bar' }, (err) ->
        err.message.should.containEql '"foo" is not allowed'
        done()

    it 'can change skip and limit', (done) ->
      fabricate 'articles', [
        { title: 'Hello Wurld' }
        { title: 'Foo Baz' }
      ], ->
        Article.where { offset: 1, limit: 3 }, (err, { results }) ->
          results[0].title.should.equal 'Hello Wurld'
          done()

    it 'sorts by -updated_at by default', (done) ->
      fabricate 'articles', [
        { title: 'Hello Wurld', updated_at: moment().add(1, 'days').format() }
      ], ->
        Article.where {}, (err, { results }) ->
          results[0].title.should.equal 'Hello Wurld'
          done()

    it 'can find articles featured to an artist', (done) ->
      fabricate 'articles', [
        {
          title: 'Foo'
          featured_artist_ids: [ObjectId('4dc98d149a96300001003033')]
        }
        {
          title: 'Bar'
          primary_featured_artist_ids: [ObjectId('4dc98d149a96300001003033')]
        }
        {
          title: 'Baz'
          featured_artist_ids: [ObjectId('4dc98d149a96300001003033'), 'abc']
          primary_featured_artist_ids: [ObjectId('4dc98d149a96300001003033')]
        }
      ], ->
        Article.where(
          { artist_id: '4dc98d149a96300001003033' }
          (err, { results }) ->
            _.pluck(results, 'title').sort().join('').should.equal 'BarBazFoo'
            done()
        )

    it 'can find articles featured to an artwork', (done) ->
      fabricate 'articles', [
        {
          title: 'Foo'
          featured_artwork_ids: [ObjectId('4dc98d149a96300001003033')]
        }
        {
          title: 'Baz'
          featured_artwork_ids: [ObjectId('4dc98d149a96300001003033'), 'abc']
        }
      ], ->
        Article.where(
          { artwork_id: '4dc98d149a96300001003033' }
          (err, { results }) ->
            _.pluck(results, 'title').sort().join('').should.equal 'BazFoo'
            done()
        )

    it 'can find articles sorted by an attr', (done) ->
      db.articles.drop ->
        fabricate 'articles', [
          { title: 'C' }, { title: 'A' }, { title: 'B' }
        ], ->
          Article.where(
            { sort: '-title' }
            (err, { results }) ->
              _.pluck(results, 'title').sort().join('').should.containEql 'ABC'
              done()
          )

    it 'can find articles added to multiple fairs', (done) ->
      fabricate 'articles', [
        { title: 'C', fair_id: ObjectId('4dc98d149a96300001003033') }
        { title: 'A', fair_id: ObjectId('4dc98d149a96300001003033')  }
        { title: 'B', fair_id: ObjectId('4dc98d149a96300001003032')  }
      ], ->
        Article.where(
          { fair_ids: ['4dc98d149a96300001003033', '4dc98d149a96300001003032'] }
          (err, { results }) ->
            _.pluck(results, 'title').sort().join('').should.equal 'ABC'
            done()
        )

    it 'can find articles added to a partner', (done) ->
      fabricate 'articles', [
        { title: 'Foo', partner_ids: [ObjectId('4dc98d149a96300001003033')] }
        { title: 'Bar', partner_ids: [ObjectId('4dc98d149a96300001003033')] }
        { title: 'Baz', partner_ids: [ObjectId('4dc98d149a96300001003031')] }
      ], ->
        Article.where(
          { partner_id: '4dc98d149a96300001003033' }
          (err, { results }) ->
            _.pluck(results, 'title').sort().join('').should.equal 'BarFoo'
            done()
        )

    it 'can find articles by query', (done) ->
      fabricate 'articles', [
        { thumbnail_title: 'Foo' }
        { thumbnail_title: 'Bar' }
        { thumbnail_title: 'Baz' }
      ], ->
        Article.where(
          { q: 'fo' }
          (err, { results }) ->
            results[0].thumbnail_title.should.equal 'Foo'
            done()
        )

  describe '#find', ->

    it 'finds an article by an id string', (done) ->
      fabricate 'articles', { _id: ObjectId('5086df098523e60002000018') }, ->
        Article.find '5086df098523e60002000018', (err, article) ->
          article._id.toString().should.equal '5086df098523e60002000018'
          done()

    it 'can lookup an article by slug', (done) ->
      fabricate 'articles', {
        _id: ObjectId('5086df098523e60002000018')
        slugs: ['foo-bar']
      }, ->
        Article.find 'foo-bar', (err, article) ->
          article._id.toString().should.equal '5086df098523e60002000018'
          done()

  describe '#save', ->

    it 'saves valid article input data', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
      }, 'foo', (err, article) ->
        article.title.should.equal 'Top Ten Shows'
        db.articles.count (err, count) ->
          count.should.equal 11
          done()

    it 'requires an author', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
      }, 'foo', (err, article) ->
        err.message.should.containEql '"author_id" is required'
        done()

    it 'adds an updated_at as a date', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
      }, 'foo', (err, article) ->
        article.updated_at.should.be.an.instanceOf(Date)
        moment(article.updated_at).format('YYYY').should.equal moment().format('YYYY')
        done()

    it 'includes the id for a new article', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
      }, 'foo', (err, article) ->
        return done err if err
        (article._id?).should.be.ok
        done()

    it 'adds a slug based off the title', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
      }, 'foo', (err, article) ->
        return done err if err
        article.slugs[0].should.equal 'craig-spaeth-top-ten-shows'
        done()

    it 'adds a slug based off a user and title', (done) ->
      fabricate 'users', { name: 'Molly'}, (err, @user) ->
        Article.save {
          title: 'Foo Baz'
          author_id: @user._id
        }, 'foo', (err, article) ->
          return done err if err
          article.slugs[0].should.equal 'molly-foo-baz'
          done()

    it 'saves slug history to support old slugs', (done) ->
      fabricate 'users', { name: 'Molly'}, (err, @user) ->
        Article.save {
          title: 'Foo Baz'
          author_id: @user._id
        }, 'foo', (err, article) =>
          return done err if err
          Article.save {
            id: article._id.toString()
            title: 'Foo Bar Baz'
            author_id: @user._id
          }, 'foo', (err, article) ->
            return done err if err
            article.slugs.join('').should.equal 'molly-foo-bazmolly-foo-bar-baz'
            Article.find article.slugs[0], (err, article) ->
              article.title.should.equal 'Foo Bar Baz'
              done()

    it 'changes the slug if admin updates it', (done) ->
      fabricate 'users', { name: 'Molly'}, (err, @user) ->
        Article.save {
          title: 'Foo Baz'
          author_id: @user._id
        }, 'foo', (err, article) =>
          return done err if err
          Article.save {
            id: article._id.toString()
            slug: 'foo-changed'
            title: 'A Different Title'
            author_id: @user._id
          }, 'foo', (err, article) ->
            return done err if err
            article.slugs[1].should.equal 'foo-changed'
            Article.find article.slugs[0], (err, article) ->
              article.title.should.equal 'A Different Title'
              done()

    it 'saves published_at when the article is published', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
        published: true
      }, 'foo', (err, article) ->
        article.published_at.should.be.an.instanceOf(Date)
        moment(article.published_at).format('YYYY').should
          .equal moment().format('YYYY')
        done()

    it 'updates published_at when admin changes it', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
        published: true
      }, 'foo', (err, article) =>
        return done err if err
        Article.save {
          id: article._id.toString()
          author_id: '5086df098523e60002000018'
          published_at: moment().add(1, 'year').toDate()
        }, 'foo', (err, updatedArticle) ->
          return done err if err
          updatedArticle.published_at.should.be.an.instanceOf(Date)
          moment(updatedArticle.published_at).format('YYYY').should
            .equal moment().add(1, 'year').format('YYYY')
          done()

    it 'denormalizes the author into the article on publish', (done) ->
      fabricate 'users', {
        _id: ObjectId('5086df098523e60002000018')
        name: 'Molly'
        profile_handle: 'molly'
      }, (err, @user) ->
        Article.save {
          title: 'Top Ten Shows'
          thumbnail_title: 'Ten Shows'
          author_id: '5086df098523e60002000018'
          published: true
        }, 'foo', (err, article) ->
          article.author.name.should.equal 'Molly'
          article.author.profile_handle.should.equal 'molly'
          done()

    it 'doesnt save a fair unless explictly set', (done) ->
      Article.save {
        title: 'Top Ten Shows'
        thumbnail_title: 'Ten Shows'
        author_id: '5086df098523e60002000018'
        fair_id: null
        published: true
      }, 'foo', (err, article) ->
        (article.fair_id?).should.not.be.ok
        done()

  describe "#destroy", ->

    it 'removes an article', (done) ->
      fabricate 'articles', { _id: ObjectId('5086df098523e60002000018') }, ->
        Article.destroy '5086df098523e60002000018', (err) ->
          db.articles.count (err, count) ->
            count.should.equal 10
            done()

  describe '#present', ->

    it 'converts _id to id', ->
      data = Article.present _.extend fixtures().articles, _id: 'foo'
      (data._id?).should.not.be.ok
      data.id.should.equal 'foo'

  describe '#presentCollection', ->

    it 'shows a total/count/results hash for arrays of articles', ->
      data = Article.presentCollection
        total: 10
        count: 1
        results: [_.extend fixtures().articles, _id: 'baz']
      data.results[0].id.should.equal 'baz'
