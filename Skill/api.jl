#
# API function goes here, to be called by the
# skill-actions:
#

function kodiOn()

    tvOn()
    sleep(1)

    # kodi grabs the hdmi/AV input:
    #
    Snips.setGPIO(Snips.getConfig(INI_GPIO), :on)
end


function kodiOff()

     kodiCmd("off")
     sleep(3)
     Snips.setGPIO(Snips.getConfig(INI_GPIO), :off)
 end

function tvON()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["susi", "wait20", "TV"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end



function tvOFF()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["TV", "standby"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end
