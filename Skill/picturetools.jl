
"""
    getSlideShows(path)

Parse all dirs at "path" and return a list of Dicts
with all slideshows.
Dicts have entries.
- :file     path
- :filetype dir, etc
- :label    name
- :year     int
- :keywords String[]
"""
function getSlideShows(path)

    dirs = kodiGetPictureFiles(path)

    # filter only dirs:
    #
    slideShows = []
    for d in dirs
        if haskey(d, :filetype)
            if d[:filetype] == "directory"

                # parse keywords:
                #
                if haskey(d, :label)
                    (year, keywords) = parsePhotoDir(d[:label])
                end
                if year != nothing && keywords != nothing
                    s = deepcopy(d)
                    s[:year] = year
                    s[:keywords] = keywords
                    push!(slideShows, s)
                end
            end
        end
    end
    return slideShows
end


function parsePhotoDir(name)

    year = nothing
    keywords = nothing
    kw = split(name, "-")
    if length(kw) > 1 && occursin(r"^[0-9]{4}$", kw[1])
        year = tryparse(Int, kw[1])
        keywords = kw[2:end]

        keywords = [replace(x, "_"=> " ") for x in keywords]
    end

    if year != nothing && keywords != nothing
        println("PhotoDir: $name; year: $year; kw: $keywords")
    end
    return (year, keywords)
end



function matchSlideShows(slideShows, year, keywords)

    matched = []
    for s in slideShows

        match = true

        if year != nothing && year != s[:year]
            match = false
        end

        ##TODO: uppercase!
        if keywords != nothing
            for kw in keywords
                if !(lowercase(kw) in lowercase.(s[:keywords]))
                    match = false
                end
            end
        end

        if match
            push!(matched, deepcopy(s))
        end
    end

    return matched
    end
