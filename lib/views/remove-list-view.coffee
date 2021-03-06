{$, $$, EditorView} = require 'atom-space-pen-views'

git = require '../git'
OutputView = require './output-view'
notifier = require '../notifier'
SelectListMultipleView = require './select-list-multiple-view'

module.exports =
class SelectStageFilesView extends SelectListMultipleView

  initialize: (@repo, items) ->
    super
    @show()
    @setItems items
    @focusFilterEditor()

  addButtons: ->
    viewButton = $$ ->
      @div class: 'buttons', =>
        @span class: 'pull-left', =>
          @button class: 'btn btn-error inline-block-tight btn-cancel-button', 'Cancel'
        @span class: 'pull-right', =>
          @button class: 'btn btn-success inline-block-tight btn-remove-button', 'Remove'
    viewButton.appendTo(this)

    @on 'click', 'button', ({target}) =>
      if $(target).hasClass('btn-remove-button')
        @complete() if window.confirm 'Are you sure?'
      @cancel() if $(target).hasClass('btn-cancel-button')

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @storeFocusedElement()

  cancelled: ->
    @hide()

  hide: ->
    @panel?.destroy()

  viewForItem: (item, matchedStr) ->
    $$ ->
      @li =>
        if matchedStr? then @raw(matchedStr) else @span item

  completed: (items) ->
    files = (item for item in items when item isnt '')
    @cancel()
    currentFile = @repo.relativize atom.workspace.getActiveTextEditor()?.getPath()

    editor = atom.workspace.getActiveTextEditor()
    atom.views.getView(editor).remove() if currentFile in files
    git.cmd
      args: ['rm', '-f'].concat(files)
      cwd: @repo.getWorkingDirectory()
      stdout: (data) ->
        notifier.addSuccess "Removed #{prettify data}"
        @repo.destroy() if @repo?.destroyable

  # cut off rm '' around the filenames.
  prettify = (data) ->
    data = data.match(/rm ('.*')/g)
    if data?.length >= 1
      for file, i in data
        data[i] = ' ' + file.match(/rm '(.*)'/)[1]
