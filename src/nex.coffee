Nex = @Nex = {}

Nex.Widgets = Nex.Widgets or {}

Nex.debug = window.location.host.indexOf(':') > 0
Nex.data  = 'online'
Nex.client or= 'public'

Nex.log =

  logPrefix: '(Nex.log) '

  log: (args...) ->
    return unless Nex.debug
    if @logPrefix then args.unshift(@logPrefix)
    console?.log?(args...)
    this


module?.exports = Nex