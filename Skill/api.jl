#
# API function goes here, to be called by the
# skill-actions:
#
CURL = "/$(Snips.getAppDir())/Skill/kodi.sh"
TEMPLATES = "$(Snips.getAppDir())/Skill/Templates"

function kodiOn()

    # tvOn()
    # sleep(1)

    # kodi powers TV up and grabs the hdmi/AV input:
    #
    Snips.setGPIO(Snips.getConfig(INI_GPIO), :on)
    sleep(20)
    tvTVAV()
end


function kodiOff()

     kodiCmd("shutdown")
     sleep(10)
     Snips.setGPIO(Snips.getConfig(INI_GPIO), :off)

     tvOff()
 end

function tvTVAV()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["TV", "wait1", "AV", "return"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end
function tvOn()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["susi", "wait20", "TV"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end



function tvOff()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["TV", "standby"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end


#
# KODI commands:
#
#
"""
    kodiIsOn()

Return true if kodi result has OK printed in the first line
"""
function kodiIsOn()

    if runKodiCmd("getVolume", errorMsg = "")
        return strip(read(`head -1 kodi.status`, String)) == "OK"
    else
        return false
    end
end



#
# low-level:
#
#
"""
    runKodiCmd(cmd, args...)

Send a Command to Kodi (with optional args).
"""
function kodiCmd(cmd, args...; errorMsg = :error_kodicmd)

    ip = Snips.getConfig(INI_IP)
    port = Snips.getConfig(INI_PORT)

    curl = `$CURL $ip $port $TEMPLATES $cmd $args`
    println("Command: $cmd")
    return  Snips.tryrun(curl, errorMsg = errorMsg)
end
