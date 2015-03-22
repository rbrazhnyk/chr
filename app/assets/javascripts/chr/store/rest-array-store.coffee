# -----------------------------------------------------------------------------
# Author: Alexander Kravets <alex@slatestudio.com>,
#         Slate Studio (http://www.slatestudio.com)
#
# Coding Guide:
#   https://github.com/thoughtbot/guides/tree/master/style/coffeescript
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REST ARRAY STORE
# -----------------------------------------------------------------------------
class @RestArrayStore extends ArrayStore
  # initial store configuration
  _initialize_database: ->
    @dataFetchLock = false
    @ajaxConfig = {}


  # generate rest url for resource
  _resource_url: (type, id) ->
    objectPath = if id then "/#{ id }" else ''
    "#{ @config.path }#{ objectPath }"


  # do requests to database api
  _ajax: (type, id, data, success, error) ->
    options = $.extend @ajaxConfig,
      url:  @_resource_url(type, id)
      type: type
      data: data
      success: (data, textStatus, jqXHR) =>
        @dataFetchLock = false
        success?(data)
      error: (jqXHR, textStatus, errorThrown ) =>
        @dataFetchLock = false
        error?(jqXHR.responseJSON)

    @dataFetchLock = true
    $.ajax options


  # reset all data and load it again
  reset: ->
    @_reset_data()
    @load()


  # load a single object, this is used in view when
  # store has not required item
  loadObject: (id, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'GET', id, {}, ((data) =>
      callbacks.onSuccess(data)
    ), callbacks.onError


  # load objects from database, when finished
  # trigger 'objects_added' event
  load: (callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'GET', null, {}, ((data) =>
      if data.length > 0
        for o in data
          @_add_data_object(o)

      callbacks.onSuccess(data)

      $(this).trigger('objects_added', { objects: data })
    ) callbacks.onError


  # add new object
  push: (serializedFormObject, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'POST', null, obj, ((data) =>
      @_add_data_object(data)
      callbacks.onSuccess(data)
    ), callbacks.onError


  # update objects attributes
  update: (id, serializedFormObject, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    obj = @_parse_form_object(serializedFormObject)

    @_ajax 'PUT', id, obj, ((data) =>
      @_update_data_object(id, data)
      callbacks.onSuccess(data)
    ), callbacks.onError


  # delete object
  remove: (id, callbacks={}) ->
    callbacks.onSuccess ?= $.noop
    callbacks.onError   ?= $.noop

    @_ajax 'DELETE', id, {}, ( =>
      @_remove_data_object(id)
      callbacks.onSuccess()
    ), callbacks.onError



