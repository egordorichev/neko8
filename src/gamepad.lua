-- PibePlayer's GamePad Interface
-- by @PibePlayer

--[[How to use:
    
    Buttons:
    
    (1: Exit Button - 2: Up - 3: Down - 4: Left - 5: Right
     6: X - 7: Z)
    
    Practical Use:

    gamepad=require "gamepad"
    g=gamepad:new()    --initialization
    g:update()         --updates itself
    g:draw()           --draws the buttons
    g.b[n].ispressed   --gets pressed state of button n
    g.b[n].isnewpress  --gets if pressed state of button n is new
    g.b[n]:keeppressed --keeps a button pressed until :release()
    g.b[n]:keepreleased--keeps a button released until :release()
    g.b[n]:release     --releases a :keeppressed/:keepreleased button
--]]

gamepad={}
gamepad.__index=gamepad

gamepad.exiting = false

gamepad.button={}
gamepad.button.__index=gamepad.button

function gamepad.button:new(x,y,spr,key)
 tbtn={}
 setmetatable(tbtn,gamepad.button)
 tbtn.x=x
 tbtn.y=y
 tbtn.key=key
 tbtn.spr=spr or 0
 tbtn.keep=0
 tbtn.oldpress=false
 tbtn.ispressed=false
 tbtn.isnewpress=false
 return tbtn
end

function gamepad.button:pressed(x,y,rb,lb)
 if (lb and x>=self.x and x<=self.x+16 and
     y>=self.y and y<=self.y+16) or self.keep==1 or (self.key~=nil and api.key(self.key) or false) and self.keep~=2 then
  return true
 end
 return false
end

function gamepad.button:keeppressed()
 self.keep=1
end

function gamepad.button:keepreleased()
 self.keep=2
end

function gamepad.button:release()
 self.keep=0
end

function gamepad.button:update()
 self.oldpress=self.ispressed
 self.ispressed=self:pressed(api.mstat())
 self.isnewpress= self.ispressed and not self.oldpress
end

function gamepad.button:draw()
 if self.ispressed then
  api.sspr(self.spr*8,32,8,8,self.x,self.y+2,16,16)
  return
 end
 api.sspr(self.spr*8,24,8,8,self.x,self.y,16,16)
end

function gamepad:new()
 tg={}
 setmetatable(tg,gamepad)
 
 tg.b={gamepad.button:new(15,10,7,"q"),
   gamepad.button:new(30,75,0,"up"),gamepad.button:new(30,105,1,"down"),
   gamepad.button:new(15,90,2,"left"),gamepad.button:new(45,90,3,"right"),
   
   gamepad.button:new(150,105,4,"x"),gamepad.button:new(165,90,5,"z")}
 
 return tg
end

function gamepad:update()
 if self.b[1].ispressed then
  gamepad.exiting = true
 end
 
 for k,v in pairs(self.b) do
  self.b[k]:update()
 end
end

function gamepad:draw()
 for k,v in pairs(self.b) do
  self.b[k]:draw()
 end
end

return gamepad