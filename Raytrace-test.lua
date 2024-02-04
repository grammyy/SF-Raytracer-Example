--@name Raytrace example
--@author Elias

if SERVER then
    local src=chip():isWeldedTo()
    
    if src then
        src:linkComponent(chip())
    end
else
    local max=0.9
    local scale=4
    local fov=160
    local data={}
    local thread
    version=1.7
    repo="https://raw.githubusercontent.com/grammyy/SF-Raytracer-Example/main/version"
    
    http.get("https://raw.githubusercontent.com/grammyy/SF-linker/main/linker.lua",function(data)
        loadstring(data)()
        
        load({
            "https://raw.githubusercontent.com/grammyy/SF-linker/main/public%20libs/version%20changelog.lua"
        })
    end)
    
    render.createRenderTarget("trace")
    
    hook.add("render","",function()
        if !data.src then
            data.screen=render.getScreenEntity()
            data.src=render.getScreenInfo(data.screen)
        end
        
        render.setRenderTargetTexture("trace")
        render.drawTexturedRect(0,0,1024,1024)
        
        if !data.loaded then
            render.selectRenderTarget("trace")
            
            if !thread then
                thread=coroutine.create(function()
                    for y=0,512/scale do
                        for x=0,(1024/data.src.RatioX)/scale do
                            local offset=(-data.screen:getRight()*(x-((512/data.src.RatioX)/(scale*2)))+data.screen:getForward()*(y-(512/(scale*2))))*(scale/3)/(2.5/fov)
                            local Trace=trace.line(data.screen:getPos(),data.screen:getPos()+offset-data.screen:getUp()*8000,data.screen,nil,nil,false)
                            local color=render.traceSurfaceColor(data.screen:getPos(),data.screen:getPos()+offset-data.screen:getUp()*8000)
                            
                            if Trace.Entity:isValid() then
                                local mats=Trace.Entity:getMaterials()
                                local ent=Trace.Entity:getColor()
                                
                                ent[1]=math.max(ent[1]/255,.25)
                                ent[2]=math.max(ent[2]/255,.25)
                                ent[3]=math.max(ent[3]/255,.25)
                                
                                color=Color((color[1]*ent[1])*.95,(color[2]*ent[2])*.95,(color[3]*ent[3])*.95)
                                
                                if string.find(Trace.Entity:getMaterial(),"glass") then
                                    color=render.traceSurfaceColor(Trace.HitPos,Trace.HitPos+(Trace.HitNormal)*8000)
                                end
                                
                                for i,mat in pairs(mats) do
                                    if string.find(mat,"glass") then
                                        color=render.traceSurfaceColor(Trace.HitPos,Trace.HitPos+(Trace.HitNormal)*8000)
                                    end
                                end
                            end

                            if !Trace.Hit or Trace.HitSky then
                                local sun,_=game.getSunInfo()
                                
                                local sky=Color(math.lerp(Trace.Normal[3],255,117),math.lerp(Trace.Normal[3],255,185),math.lerp(Trace.Normal[3],255,238))
                                
                                local test=Trace.Normal:dot(sun)
                                
                                if test>.9975 then
                                    local res=(test-.9975)*500
                                    color=Color(math.lerp(res,sky[1],255),math.lerp(res,sky[2],255),math.lerp(res,sky[3],255))
                                else
                                    color=sky
                                end
                            end

                            render.setColor(color)
                            render.drawRectFast(x*scale,y*scale,scale,scale)
                        
                            if quotaAverage()>0.006*max then
                                coroutine.yield()
                            end
                        end
                    end
                end)
            end

            if coroutine.status(thread)=="suspended" and quotaAverage()<0.06*0.95 then
                coroutine.resume(thread)
            end
            
            if coroutine.status(thread)=="dead" then
                data.loaded=false
                thread=nil
            end
        end
    end)
end