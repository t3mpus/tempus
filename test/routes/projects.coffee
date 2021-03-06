request = require 'request'
async = require 'async'
should = require 'should'
_ = require 'underscore'
uuid = require 'uuid'

startApp = require './../start_app'
base = require './../base'
optionsBase = require './../options'
user_test_helper = require './user_test_helper'

validProject = (p)->
  p.should.have.property 'name'
  p.should.have.property 'id'
  p.should.have.property 'createdDate'

testProjects = [ {name: 'p1'}, {name: 'p2'} ]

testUser = undefined
projectsCreated = []

options = (u)->
  optionsBase u or testUser

createProject = (project, callback)->
  ops = options()
  ops.body = project
  request.post (base '/projects'), ops, (e,r,b)->
    r.statusCode.should.be.equal 200
    validProject b
    projectsCreated.push b
    callback()

deleteProject = (project, callback)->
  ops = options()
  request.del (base "/projects/#{project.id}"), ops, (e,r,b)->
    r.statusCode.should.be.equal 200
    callback()

describe 'Projects', ->
  before (done) ->
    startApp ->
      user_test_helper.makeUser (user)->
        testUser = user
        testProjects = _.map testProjects, (p)->
          p.createdDate = new Date()
          return p
        async.each testProjects, createProject, done

  after (done) ->
    async.each projectsCreated, deleteProject, ->
      request.del (base "/users/#{testUser.id}"), options(), (e,r,b)->
        r.statusCode.should.be.equal 200
        done()

  it 'should get all projects', (done)->
    request (base '/projects'), options(), (e,r,b)->
      r.statusCode.should.be.equal 200
      _.each b, validProject
      done()

  it 'should get all projects individually', (done)->
    request (base '/projects'), options(), (e,r,b)->
      iterator = (p, cb)->
        request (base "/projects/#{p.id}"), options(), (e,r,b)->
          r.statusCode.should.be.equal 200
          validProject b
          cb()
      async.each b, iterator, done

  it 'should delete projects', (done)->
    ops = options()
    ops.body =
      name: 'deleted-project'
      createdDate: new Date()
    request.post (base '/projects'), ops, (e,r,b)->
      r.statusCode.should.be.equal 200
      id = b.id
      validProject b
      request.del (base "/projects/#{id}"), options(), (e,r,b)->
        r.statusCode.should.be.equal 200
        request (base "/projects/#{id}"), options(), (e,r,b)->
          r.statusCode.should.be.equal 404
          done()

  it 'cannot delete a bad id project', (done)->
    request.del (base "/projects/#{Number.MAX_VALUE}"), options(), (e,r,b)->
      r.statusCode.should.be.equal 404
      done()


