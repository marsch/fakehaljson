hal = require 'hal'
Faker = require 'faker-ext'
uuid = require 'node-uuid'
fs = require 'fs'

faker = new Faker()

class HALResource
  path: '/'
  id: '1'

  getResource: (propertyList = []) ->
    properties = {}
    for property in propertyList
      properties[property] = @[property]

    new hal.Resource properties, @getSelfUrl()

  getSelfUrl: () ->
    "#{@path}/#{@id}"

class NoteBook extends HALResource
  path: '/notebooks'
  notegroups: []

class Outline extends HALResource
  path: '/outline'
  bullets: []

  setBullets: (bullets) ->
    @bullets  = bullets

  getBullets: () ->
    @bullets

  getResource: (propertyList) ->
    resource = super
    # embed bullets
    bulletResources = []
    for bullet in @bullets
      bulletResources.push bullet.getResource(['id','name','color','order'])
    resource.embed('bullets', bulletResources)

class Bullet extends HALResource
  id: null
  notecard: null
  name: ''
  color: ''
  order: 1
  bullets: ''
  path: '/bullets'

  constructor: () ->
    @id = uuid.v4()

  getId: () ->
    @id

  setName: (name) ->
    if !@getNotecard()
      return @name = name

    @getNotecard().setName name

  getName: () ->
    if !@getNotecard()
      return @name
    @getNotecard().getName()

  setNotecard: (card) ->
    @notecard = card

  getNotecard: () ->
    @notecard

  setOrder: (num) ->
    @order = num

  getOrder: () ->
    @order

  setBullets: (bullets) ->
    @bullets = bullets

  getBullets: () ->
    @bullets

  setColor: (color) ->
    @color = color

  getColor: () ->
    @color

  getResource: () ->
    resource = super
    # embed bullets
    if @getBullets().length > 0
      bulletResources = []
      for bullet in @bullets
        bulletResources.push bullet.getResource(['id','name','color','order'])
      resource.embed('bullets', bulletResources)

    if @getNotecard()
      resource.embed('notecard', @getNotecard().getResource(['id', 'name', 'color', 'order']), false)
    resource


class NoteCard extends HALResource
  id: null
  name: ''
  color: ''
  order: 1
  path: '/notecards'

  constructor: () ->
    @id = uuid.v4()

  getId: () ->
    @id

  setName: (name) ->
    return @name = name

  getName: () ->
    return @name

  setOrder: (num) ->
    @order = num

  getOrder: () ->
    @order

  setColor: (color) ->
    @color = color

  getColor: () ->
    @color


class NoteCardGroup
  notecards: []


class FakeGenerator
  maxListLength: 10
  maxDepth: 2

  generateOutline: () ->
    outline = new Outline()
    outline.setBullets @generateBulletList()
    outline

  generateBulletList: (depth = 0) =>
    console.log 'depth', depth
    return [] if depth == @maxDepth
    depth = depth + 1

    list = []
    length = faker.Helpers.randomNumber @maxListLength, 0

    for x in [0..length]
      hasNotecard = faker.random.boolean()
      hasBullets = faker.random.boolean()
      order = x + 1
      list.push @generateBullet hasNotecard, hasBullets, order, depth

    list

  generateNoteCard: () ->
    card = new NoteCard()
    card.setName faker.Text.headline()
    card.setColor faker.Internet.color(0,0,0)
    card

  generateBullet: (hasNotecard, hasBullets, order, depth) ->
    bullet = new Bullet()
    bullet.setName faker.Text.headline()
    bullet.setOrder order
    bullet.setColor faker.Internet.color(0,0,0)
    if hasNotecard
      bullet.setNotecard @generateNoteCard()
    if hasBullets
      bullet.setBullets @generateBulletList(depth)

    bullet



gen = new FakeGenerator()

outline = gen.generateOutline()
outlineJson = outline.getResource().toJSON()

console.log(outline.getResource().toJSON())

fs.writeFileSync 'fake.json', JSON.stringify(outlineJson, undefined, 4), 'UTF-8'
