request = require 'request'
async = require 'async'
should = require 'should'
_ = require 'underscore'
uuid = require 'uuid'

startApp = require './../start_app'
base = require './../base'
options = require './../options'
UserTestHelper = require './user_test_helper'

makeUser = (testUserEmail, status, cb)->
  ops = _.clone options
  ops.body =
    firstName: 'Test'
    lastName: 'User'
    email: testUserEmail
    password: 'keyboard cats'
  request.post (base '/users'), ops, (e,r,b)->
    r.statusCode.should.be.equal status
    UserTestHelper.validate b if r.statusCode is 200
    cb(b)

describe 'Users', ->
  before (done) ->
    startApp -> UserTestHelper.addUsers done

  it 'Get all Users', (done)->
    request (base '/users'), options, (e,r,b)->
      r.statusCode.should.be.equal 200
      b.should.have.property 'users'
      should.equal UserTestHelper.users.length <= b.users.length, yes
      _.each b.users, UserTestHelper.validate
      done()

  it 'Creates a new user', (done) ->
    ops = _.clone options
    ops.body =
      firstName: 'Will'
      lastName: 'Laurance'
      email: "w.laurance#{new Date().toString().replace(/[\W]/g, '')}@gmail.com"
      password: 'keyboard cats'
    request.post (base '/users'), ops, (e,r,b)->
      r.statusCode.should.be.equal 200
      UserTestHelper.validate b
      done()

  it 'cant get each user individually', (done)->
    request (base '/users'), options, (e,r,b)->
      iterator = (id, cb)->
        request (base "/users/#{id}"), options, (e,r,b)->
          r.statusCode.should.be.equal 200
          UserTestHelper.validate b
          cb()

      async.eachLimit _.map(b.users, (u)-> u.id), 100, iterator, done

  it 'cant have two users with the same email', (done)->
    t = "testUser#{uuid.v1()}@testuser.com"
    makeUser t, 200, -> makeUser t, 400, (error)->
      error.should.have.property 'error', 'user already exists'
      done()

  it 'can delete a user'
