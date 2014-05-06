Nex  = @Nex or require('nex')

isBlank = Spine.isBlank

class Nex.Contact extends Spine.Controller
  className:
    'contact'

  events:
    'tap .send' : 'send'
    'keyup'     : 'onkeyup'

  elements:
    'form' : 'form'

  defaults:
    dataType : 'json'
    processData: false
    headers  : {'X-Requested-With': 'XMLHttpRequest'}

  logPrefix: '(App) Contact: '

  constructor: ->
    super

    @defaultFields = ['email', 'message', 'subscribe']

  onkeyup: (e) ->
    @validate(e.target)

  validate: (el) ->
    field = $(el).parent()
    if el.checkValidity()
      field.removeClass('error')
    else
      field.addClass('error')

  getxsrf: (xhr, settings) =>
    $.ajax(
      type: 'GET'
      async: false
      url: if (Nex.data is 'online' and Nex.debug) then "http://#{Nex.tenant}.imagoapp.com/api/v2/getxsrf" else "/api/v2/getxsrf"
    ).success( (data) ->
      xhr.setRequestHeader("Nex-Xsrf", data)
    ).error( =>
      @el.addClass('error')
    )

  formToJson: (form) ->
    array = $(form).serializeArray()
    obj   = {}

    message = ''
    for elem in array
      if elem.name not in @defaultFields
        message += "#{Nex.Utils.titleCase(elem.name)}: #{elem.value}<br><br>"
      obj[elem.name] = elem.value or= ''

    obj.message = message + @replaceNewLines(obj.message)

    return JSON.stringify(obj)

  replaceNewLines: (msg) ->
    msg.replace(/(\r\n\r\n|\r\n|\n|\r)/gm, "<br>")

  send: (e) =>
    e.preventDefault()
    for field in $('input,textarea,select')
      @validate field

    return unless @form[0].checkValidity()

    settings =
      beforeSend: @getxsrf
      data: @formToJson(@form)
      url: if (Nex.data is 'online' and Nex.debug) then "http://#{Nex.tenant}.imagoapp.com/api/v2/contact" else "/api/v2/contact"
      method: 'POST'

    settings = $.extend({}, @defaults, settings)

    $.ajax(settings)
      .success( (e) =>
        @el.addClass('success')
      )
      .error( (e) -> console.log("error with form", e) )

  onKeyup: (e) =>
    return unless @isActive()
    key = Nex.Utils.getKeyName(e)
    @[key]() if typeof @[key] is 'function'

module.exports = Nex.Contact
