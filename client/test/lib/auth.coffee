sinon = require 'sinon'
rewire = require 'rewire'
auth = rewire '../../lib/setup/auth'

describe 'auth middleware', ->

  beforeEach ->
    @req =
      logout: sinon.stub()
    @res =
      redirect: sinon.stub()
    @next = sinon.stub()
    for fn in ['requireLogin', 'logout']
      @[fn] = auth.__get__ fn

  describe 'requireLogin', ->

    it 'redirects to login without a user', ->
      @requireLogin @req, @res, @next
      @res.redirect.args[0][0].should.equal '/login'

  describe 'logout', ->

    it 'destroys the api & client session', ->
      @req.user = destroy: sinon.stub()
      @logout @req, @res, @next
      @req.user.destroy.called.should.be.ok
      @req.logout.called.should.be.ok
      @res.redirect.called.should.be.ok