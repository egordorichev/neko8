local editors = {}

function editors.init()
  editors.opened = false
  editors.code = require "editors.code"

  editors.modes = {
    editors.code
  }

  editors.current = editors.modes[1]

  for e in api.all(editors.modes) do
    e.init()
  end
end

function editors.open()
  if editors.opened then
    return
  end

  editors.opened = true
  editors.current.open()
end

function editors.close()
  if not editors.opened then
    return
  end

  editors.opened = false
  editors.current.close()
  api.cls()
end

function editors.toggle()
  if editors.opened then
    editors.close()
  else
    editors.open()
  end
end

function editors.drawUI()
  api.rectfill(
    0, 0, config.canvas.width,
    6, config.editors.ui.bg
  )

  api.rectfill(
    0, config.canvas.height - 7,
    config.canvas.width,
    config.canvas.height,
    config.editors.ui.bg
  )
end

return editors