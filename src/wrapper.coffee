root = exports ? this

go   = require './getopt.js'
fs   = require 'fs'

requirejs = require './r.js'
requirejs.config({ baseUrl: __dirname })
todo = requirejs './todo'

db = {}

system = {
    # debugging/logging utility function
    db: (msg, tag) ->
        if not tag? then return console.log msg
        for tagRe in (db.tags ? []) when tagRe.test tag
            return console.log msg

    exit: (code) ->
        process.exit code
}
system.db.tags  = [/tag/]

ui = {
    echo: console.log

    ask: (prompt) ->
        process.stdout.write prompt

        process.stdin.resume()
        fs = require 'fs'
        response = fs.readSync process.stdin.fd, 1024, 0, 'utf8'
        process.stdin.pause()

        # TODO: add multi-line support

        return response[0].trim()
}

# Synchronous methods that match more closely with twFile
filesystem = {
    # Cygwin uses different paths than (Windows) node.js
    _convertCygPath: (filePath) ->
        filePath = filePath.replace /^\/cygdrive\/(.)/, '$1:'

    lastFilePath: ''

    load: (filePath) ->
        result = null;

        filePath = this._convertCygPath filePath

        db 'LOAD: ' + filePath, 'fs'

        try
            result = fs.readFileSync filePath, 'UTF8'
        catch e then return

        db 'LOAD: ' + result, 'fs'

        @lastFilePath = filePath
        return result

    save: (filePath, content) ->
        filePath = this._convertCygPath filePath

        db 'SAVE: ' + filePath, 'fs'

        try
            fs.writeFileSync filePath, content, 'UTF8'
        catch e then return
        return true

    append: (filePath, appendContent) ->

        filePath = this._convertCygPath filePath

        db 'APPEND: ' + filePath, 'fs'

        content = this.load filePath
        db 'APPEND: '+ content, 'fs'
        if content?
            content += appendContent + '\n'
            if this.save filePath, content
                return content

        return
}

db = system.db
db 'tag', 'TEST DB'

root.run = () ->
    # Strip the first argument, which is specific to node.js.
    argv = process.argv[2..]

    env = {}
    for e of process.env
        env[e] = process.env[e]

    env.HOME ?= env.USERPROFILE
    env.PWD ?= process.cwd()

    if require.main is module
        env.HOME = argv.shift()

    todo.init env, filesystem, ui, system
    exitCode = todo.run argv
    process.exit exitCode

if require.main is module
    root.run()

