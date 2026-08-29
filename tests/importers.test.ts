import test from 'node:test'
import assert from 'node:assert/strict'
import { parseCsvObjects, validateBatch } from '../src/importers/index.ts'
import { fingerprint, preparePost } from '../src/lib/postProcessing.ts'
import { classify, extractMetadata } from '../src/classifiers/rules.ts'

test('CSV supports quoted commas and escaped quotes',()=>assert.deepEqual(parseCsvObjects('originalText,accountId\n"Hello, ""world""",a')[0],{originalText:'Hello, "world"',accountId:'a'}))
test('CSV supports CRLF and multiline quoted fields',()=>assert.equal(parseCsvObjects('originalText,accountId\r\n"line one\nline two",a\r\n')[0].originalText,'line one\nline two'))
test('invalid CSV-derived rows are rejected independently',()=>assert.equal(validateBatch([{originalText:'',accountId:'a'},{originalText:'ok',accountId:'a'}]).rejected.length,1))
test('invalid JSON-style records are rejected independently',()=>assert.equal(validateBatch([null,{originalText:'ok',accountId:'a'}]).valid.length,1))
test('duplicate fingerprints are deterministic',()=>assert.equal(fingerprint({originalText:' A  post ',accountId:'a'}),fingerprint({originalText:'A post',accountId:'a'})))
test('classifier confidence rises for matching terms',()=>assert.ok(classify('jobs employment economy').confidence>classify('hello').confidence))
test('manual classification overrides automatic classification',()=>assert.deepEqual(preparePost({originalText:'jobs economy',accountId:'a'},'Healthcare').category,'Healthcare'))
test('possible claim detection identifies numerical language',()=>assert.equal(extractMetadata('Funding increased by 20%').containsClaim,true))
import { adminGateState, parseBrowseFilters } from '../src/lib/filters.ts'
test('URL filter parsing rejects malformed values',()=>assert.deepEqual(parseBrowseFilters('?page=-2&from=soon&claim=maybe'),{page:1,search:undefined,account:undefined,category:undefined,from:undefined,to:undefined,claim:undefined}))
test('admin gate denies users absent from archive_admins',()=>{assert.equal(adminGateState('user',null),'denied');assert.equal(adminGateState('user','user'),'admin');assert.equal(adminGateState(null,null),'login')})
