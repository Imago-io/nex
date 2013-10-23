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
      url: if Nex.debug then "http://#{Nex.tenant}.imagoapp.com/api/v2/getxsrf" else "/api/v2/getxsrf"
    ).success( (data) ->
      xhr.setRequestHeader("Nex-Xsrf", data)
    ).error( =>
      @el.addClass('error')
    )

  formToJson: (form) ->
    array = $(form).serializeArray()
    obj   = {}

    for elem in array
      obj[elem.name] = elem.value or= ''

    return JSON.stringify(obj)

  send: (e) =>
    e.preventDefault()

    for field in $('input,textarea')
      @validate field

    return unless @form[0].checkValidity()

    settings =
      beforeSend: @getxsrf
      data: @formToJson(@form)
      url: if Nex.debug then "http://#{Nex.tenant}.imagoapp.com/api/v2/contact" else "/api/v2/contact"
      method: 'POST'

    settings = $.extend({}, @defaults, settings)

    $.ajax(settings)
      .success( (e) =>
        @el.addClass('success')
      )
      .error( (e) -> console.log("error with form", e) )



module.exports = Nex.Contact
