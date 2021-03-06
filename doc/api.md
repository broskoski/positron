# Positron's Private API

Positron uses MongoDB + Express to serve a private JSON API which the /client app consumes. The app serving this API can be found under /api. This will serve as the poor man's app & API documentation.

## Architecture

Positron's API architecture is very thin. Endpoints are split into sub-express apps under /api/apps. These apps represent a resouce and contain routes (like Rails controllers) that do auth/session/routing/etc. for a resource. Apps also contain a model that handles validation/persistence/busines logic/etc. of a resource. Unlike typical ActiveRecord/object-oriented models, these models are just libraries of database transcations that operate on vanilla data objects (using [mongojs](https://github.com/mafintosh/mongojs))—otherwise known as the [Transcation Script pattern](http://martinfowler.com/eaaCatalog/transactionScript.html). As the model logic grows it's encouraged to break apart the library into it's individual parts (e.g. model/domain.coffee, model/validation.coffee, model/persistence.coffee etc.). A root `index.coffee` app glues together the sub apps & api-wide middleware found under `/lib`.

## Authentication

Positron uses Gravity to do authentication so all endpoints require a valid Artsy `X-Access-Token` header. Positron will use this to flatten, merge, and cache user data from Arty's API for easy client consumption.

## The `me` param

You may pass `me` in place of your user id, e.g. `/articles?author_id=me` to get your own articles. Positron reserves `me` as a keyword to look up your user based on the `X-Access-Token` header.

## Endpoints

Positron's API is a [pragmatic REST API](https://blog.apigee.com/detail/api_design_a_new_model_for_pragmatic_rest). It speaks only JSON, and uses plural resources with POST/GET/PUT/DELETE verbs for CRUD. Endpoints that don't map so easily to CRUD on a resource are designed as root-level GET requests such as /sync_to_post?article_id=. Accepted endpoints include:

### Articles

GET /articles

**params**
published: Always pass `true` for logged out users
author_id: Query articles by their author
artist_id: Query articles by an artist they're featured to
artwork_id: Query articles by an artwork they're featured to
vertical_id: Query articles by verticals
fair_ids: Query articles by a fair they're featured to
show_id: Query articles by a show they're featured to
partner_id: Query articles by the partner profile they're featured on
auction_id: Query articles by an auction they're featured to
tier: Query articles by their tier
featured: Query articles by if they're featured to Magazine

GET /articles/:id
POST /articles
PUT /articles/:id
DELETE /articles/:id
GET /sync_to_post?article_id=

### Users

**params**
access_token: Gravity access token for auth

GET /users/:id

### Verticals

GET /verticals

**params**
featured: Query verticals by featured

POST /verticals
GET /verticals/:id
PUT /verticals/:id
DELETE /verticals/:id