module Feature.StructureSpec where

import Test.Hspec hiding (pendingWith)
import Test.Hspec.Wai
import Test.Hspec.Wai.JSON
import Network.HTTP.Types

import SpecHelper

import Network.Wai (Application)
import Network.Wai.Test (SResponse(simpleHeaders))

spec :: SpecWith Application
spec = do

  describe "OpenAPI" $ do
    it "root path returns a valid openapi spec" $
      validateOpenApiResponse [("Accept", "application/openapi+json")]

    it "should respond to openapi request on none root path with 415" $
      request methodGet "/items"
              (acceptHdrs "application/openapi+json") ""
        `shouldRespondWith` 415

  describe "Table info" $ do
    it "The structure of complex views is correctly detected" $
      request methodOptions "/filtered_tasks" [] "" `shouldRespondWith`
      [json|
      {
        "pkey": [
          "myId"
        ],
        "columns": [
          {
            "references": null,
            "default": null,
            "precision": 32,
            "updatable": true,
            "schema": "test",
            "name": "myId",
            "type": "integer",
            "maxLen": null,
            "enum": [],
            "nullable": true,
            "position": 1
          },
          {
            "references": null,
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "name",
            "type": "text",
            "maxLen": null,
            "enum": [],
            "nullable": true,
            "position": 2
          },
          {
            "references": {
              "schema": "test",
              "column": "id",
              "table": "projects"
            },
            "default": null,
            "precision": 32,
            "updatable": true,
            "schema": "test",
            "name": "projectID",
            "type": "integer",
            "maxLen": null,
            "enum": [],
            "nullable": true,
            "position": 3
          }
        ]
      }
      |]

    it "is available with OPTIONS verb" $
      request methodOptions "/menagerie" [] "" `shouldRespondWith`
      [json|
      {
        "pkey":["integer"],
        "columns":[
          {
            "default": null,
            "precision": 32,
            "updatable": true,
            "schema": "test",
            "name": "integer",
            "type": "integer",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "position": 1,
            "references": null,
            "default": null
          }, {
            "default": null,
            "precision": 53,
            "updatable": true,
            "schema": "test",
            "name": "double",
            "type": "double precision",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "references": null,
            "position": 2
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "varchar",
            "type": "character varying",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "position": 3,
            "references": null,
            "default": null
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "boolean",
            "type": "boolean",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "references": null,
            "position": 4
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "date",
            "type": "date",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "references": null,
            "position": 5
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "money",
            "type": "money",
            "maxLen": null,
            "enum": [],
            "nullable": false,
            "position": 6,
            "references": null,
            "default": null
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "enum",
            "type": "test.enum_menagerie_type",
            "maxLen": null,
            "enum": [
              "foo",
              "bar"
            ],
            "nullable": false,
            "position": 7,
            "references": null,
            "default": null
          }
        ]
      }
      |]

    it "it includes primary and foreign keys for views" $
      request methodOptions "/projects_view" [] "" `shouldRespondWith`
      [json|
      {
         "pkey":[
            "id"
         ],
         "columns":[
          {
            "references":null,
            "default":null,
            "precision":32,
            "updatable":true,
            "schema":"test",
            "name":"id",
            "type":"integer",
            "maxLen":null,
            "enum":[],
            "nullable":true,
            "position":1
          },
          {
            "references":null,
            "default":null,
            "precision":null,
            "updatable":true,
            "schema":"test",
            "name":"name",
            "type":"text",
            "maxLen":null,
            "enum":[],
            "nullable":true,
            "position":2
          },
          {
            "references": {
              "schema":"test",
              "column":"id",
              "table":"clients"
            },
            "default":null,
            "precision":32,
            "updatable":true,
            "schema":"test",
            "name":"client_id",
            "type":"integer",
            "maxLen":null,
            "enum":[],
            "nullable":true,
            "position":3
          }
        ]
      }
      |]

    it "includes foreign key data" $
      request methodOptions "/has_fk" [] ""
        `shouldRespondWith` [json|
      {
        "pkey": ["id"],
        "columns":[
          {
            "default": "nextval('test.has_fk_id_seq'::regclass)",
            "precision": 64,
            "updatable": true,
            "schema": "test",
            "name": "id",
            "type": "bigint",
            "maxLen": null,
            "nullable": false,
            "position": 1,
            "enum": [],
            "references": null
          }, {
            "default": null,
            "precision": 32,
            "updatable": true,
            "schema": "test",
            "name": "auto_inc_fk",
            "type": "integer",
            "maxLen": null,
            "nullable": true,
            "position": 2,
            "enum": [],
            "references": {"schema":"test", "table": "auto_incrementing_pk", "column": "id"}
          }, {
            "default": null,
            "precision": null,
            "updatable": true,
            "schema": "test",
            "name": "simple_fk",
            "type": "character varying",
            "maxLen": 255,
            "nullable": true,
            "position": 3,
            "enum": [],
            "references": {"schema":"test", "table": "simple_pk", "column": "k"}
          }
        ]
      }
      |]

    it "includes all information on views for renamed columns, and raises relations to correct schema" $
      request methodOptions "/articleStars" [] ""
        `shouldRespondWith` [json|
          {
            "pkey": [
              "articleId",
              "userId"
            ],
            "columns": [
              {
                "references": {
                  "schema": "test",
                  "column": "id",
                  "table": "articles"
                },
                "default": null,
                "precision": 32,
                "updatable": true,
                "schema": "test",
                "name": "articleId",
                "type": "integer",
                "maxLen": null,
                "enum": [],
                "nullable": true,
                "position": 1
              },
              {
                "references": {
                  "schema": "test",
                  "column": "id",
                  "table": "users"
                },
                "default": null,
                "precision": 32,
                "updatable": true,
                "schema": "test",
                "name": "userId",
                "type": "integer",
                "maxLen": null,
                "enum": [],
                "nullable": true,
                "position": 2
              },
              {
                "references": null,
                "default": null,
                "precision": null,
                "updatable": true,
                "schema": "test",
                "name": "createdAt",
                "type": "timestamp without time zone",
                "maxLen": null,
                "enum": [],
                "nullable": true,
                "position": 3
              }
            ]
          }
        |]

    it "errors for non existant tables" $
      request methodOptions "/dne" [] "" `shouldRespondWith` 404

  describe "Allow header" $ do

    it "includes read/write verbs for writeable table" $ do
      r <- request methodOptions "/items" [] ""
      liftIO $
        simpleHeaders r `shouldSatisfy`
          matchHeader "Allow" "GET,POST,PATCH,DELETE"

    it "includes read verbs for read-only table" $ do
      r <- request methodOptions "/has_count_column" [] ""
      liftIO $
        simpleHeaders r `shouldSatisfy`
          matchHeader "Allow" "GET"
