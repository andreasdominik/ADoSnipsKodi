

"""
    switchOnOffActions(topic, payload)

Switch on KODI with GPIO
"""
function switchOnOffActions(topic, payload)

    # log:
    #
    println("[ADoSnipsKodi]: action switchOnOffActions() started.")

    # ignore, if not responsible (other device):
    #
    device = Snips.extractSlotValue(payload, SLOT_DEVICE)
    if device == nothing || !( device in ["KODI"])
        return false
    end


    # ROOMs are not yet supported -> only ONE Fire  in assistent possible.
    #
    # room = Snips.extractSlotValue(payload, SLOT_ROOM)
    # if room == nothing
    #     room = Snips.getSiteId()
    # end

    onOrOff = Snips.extractSlotValue(payload, SLOT_ON_OFF)
    if onOrOff == nothing || !(onOrOff in ["ON", "OFF"])
        Snips.publishEndSession(:dunno)
        return true
    end

    println(">>> $onOrOff, $device")

    # check ini vals:
    #
    if !Snips.isConfigValid(INI_IP) ||
       !Snips.isConfigValid(INI_PORT, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_GPIO, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_TV)

       Snips.publishEndSession(:noip)
       return true
    end

    if onOrOff == "OFF"
        Snips.publishEndSession(:switchoff)
        kodiOff()
    else
        Snips.publishEndSession(:switchon)
        kodiOn()
    end
    return false
end
