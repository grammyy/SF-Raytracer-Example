--@name Raytrace test
--@author Elias

if SERVER then
    local src=chip():isWeldedTo()
    
    if src then
        src:linkComponent(chip())
    end
else
    local scale=5
    local fov=120 --2
    local data={}
    local thread
    
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
                            
                            local env
                            
                            if Trace.Entity:isValid() then
                                local mats=Trace.Entity:getMaterials()
                                local ent=Trace.Entity:getColor()
                                
                                color=color-(color-ent)/15
                                
                                if string.find(Trace.Entity:getMaterial(),"glass") then
                                    color=render.traceSurfaceColor(Trace.HitPos,Trace.HitPos+(Trace.HitNormal)*8000)
                                end
                                
                                for i,mat in pairs(mats) do
                                    if string.find(mat,"glass") then
                                        color=render.traceSurfaceColor(Trace.HitPos,Trace.HitPos+(Trace.HitNormal)*8000)
                                    end
                                end
                            end

                            render.setColor(color)
                            render.drawRectFast(x*scale,y*scale,scale,scale)
                        
                            if quotaAverage()>quotaMax()*0.9 then
                                coroutine.yield()
                            end
                        end
                    end
                end)
            end

            if coroutine.status(thread)=="suspended" and quotaAverage()<quotaMax()*0.95 then
                coroutine.resume(thread)
            end
            
            if coroutine.status(thread)=="dead" then
                data.loaded=false
                thread=nil
            end
        end
    end)
end