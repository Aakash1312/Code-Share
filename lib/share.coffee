ShareView = require './share-view'
http = require 'http'
path = require 'path'
{CompositeDisposable, TextBuffer} = require 'atom'
portfinder = require('portfinder')
module.exports = Share =
  shareView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    IPEditor = new TextBuffer
    PortEditor = new TextBuffer
    @shareView = new ShareView(this, IPEditor, PortEditor)
    @modalPanel = atom.workspace.addBottomPanel(item: @shareView, visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'share:toggle': => @toggle()
      'core:cancel': => @hide()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @shareView.destroy()

  serialize: ->
    shareViewState: @shareView.serialize()

  send: (ip, port) ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      if editor.buffer.file
        fileName = path.basename(editor.buffer.file.path)
      else
        fileName = ""
      post_options = {
          host: ip,
          port: port,
          method: 'POST',
          headers: {
              'Content-Type': 'text/html',
              'filename': fileName
          }
      };

      post_req = http.request(post_options, (res) ->
        return
      )
      post_req.write(editor.getText());
      post_req.end();

  receive: (view) ->
    portfinder.getPort (err, port) ->
      view.PortN['0'].innerHTML = port
      server = http.createServer((request, response) ->
        body = ''
        request.on 'data', (data) ->
          body += data
          if body.length > 1e6
            request.connection.destroy()
          return
        request.on 'end', ->
          atom.workspace.open().then (editor)->
            editor.setText(body)
          return
        response.writeHead 200
        # response.end()
        return
      )
      server.listen port
      return

  toggle: ->
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  hide: ->
    if @modalPanel.isVisible()
      @modalPanel.hide()
