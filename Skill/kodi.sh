#!/bin/bash -xv
#
# curl JSON to KODI for API remote control
#
IP=$1
PORT=$2
TEMPLATES=$3
CMD=$4
DIR="$(dirname $0)"

if [[ $# -gt 4 ]] ; then
  PARAM=$5
fi
if [[ $# -gt 5 ]] ; then
  PARAM2="$6"
fi

#cd /tmp
JSON="kodidata.json"

case "$CMD" in
  shutdown)
    cp "${TEMPLATES}/shutdown.json" $JSON
    ;;
  exit)
    cp "${TEMPLATES}/exit.json" $JSON
    ;;
  launch)
    nohup ${DIR}/runKodi.sh &
    exit
    ;;
  getVolume)
  cp "${TEMPLATES}/getvolume.json" $JSON
  ;;
  getTVshows)
    cp "${TEMPLATES}/gettvshows.json" $JSON
    ;;
  getMovies)
    cp "${TEMPLATES}/getmovies.json" $JSON
    ;;
  getEpisodes)
    TEMPLATE="${TEMPLATES}/getepisodes.json"
    cat $TEMPLATE | sed "s/TV_SHOW_ID/$PARAM/g" > $JSON
    ;;
  getEpisodeDetails)
    TEMPLATE="${TEMPLATES}/getepisodedetails.json"
    cat $TEMPLATE | sed "s/EPISODE_ID/$PARAM/g" > $JSON
    ;;
  getRecordings)
    TEMPLATE="${TEMPLATES}/getrecfiles.json"
    cat $TEMPLATE | sed "s+REC_DIRECTORY+$PARAM+g" > $JSON
    ;;
  getPictureFiles)
    TEMPLATE="${TEMPLATES}/getpicturefiles.json"
    cat $TEMPLATE | sed "s+PATH_PICTURES+$PARAM+g" > $JSON
    ;;
  playListClear)
    cp "${TEMPLATES}/playlistclear.json" $JSON
    ;;
  playListAddFile)
    TEMPLATE="${TEMPLATES}/playlistaddfile.json"
    cat $TEMPLATE | sed "s+FILE_PATH+$PARAM+g" > $JSON
    ;;
  playListPlay)
    cp "${TEMPLATES}/playlistplay.json" $JSON
    ;;
  playEpisode)
    TEMPLATE="${TEMPLATES}/playepisode.json"
    cat $TEMPLATE | sed "s/EPISODE_ID/$PARAM/g" > $JSON
    ;;
  playMovie)
    TEMPLATE="${TEMPLATES}/playmovie.json"
    cat $TEMPLATE | sed "s/MOVIE_ID/$PARAM/g" > $JSON
    ;;
  playRec)
    TEMPLATE="${TEMPLATES}/playrec.json"
    cat $TEMPLATE | sed "s+FILE_PATH+$PARAM+g" > $JSON
    ;;
  playPictures)
    TEMPLATE="${TEMPLATES}/playpictures.json"
    cat $TEMPLATE | sed "s+FILE_PATH+$PARAM+g" > $JSON
    ;;
  openHomeWindow)
    cp "${TEMPLATES}/windowopenhome.json" $JSON
    ;;
  openMovieWindow)
    cp "${TEMPLATES}/windowopenmovies.json" $JSON
    ;;
  openTVShowWindow)
    cp "${TEMPLATES}/windowopentvshows.json" $JSON
    ;;
  openPictureWindow)
    TEMPLATE="${TEMPLATES}/windowopenpictures.json"
    cat $TEMPLATE | sed "s+PICTURES_PATH+$PARAM+g" > $JSON
    ;;
  openTVShowWindowName)
    TEMPLATE="${TEMPLATES}/windowopentvshowname.json"
    cat $TEMPLATE | sed "s/TV_SHOW_ID/$PARAM/g" > $JSON
    ;;
  openOTRWindow)
    cp "${TEMPLATES}/windowopenotr.json" $JSON
    ;;
  openFilesWindow)
    TEMPLATE="${TEMPLATES}/windowopenfiles.json"
    cat $TEMPLATE | sed "s/FILES_TYPE/$PARAM/g" \
                  | sed "s*FILES_DIR*$PARAM2*g"> $JSON
    ;;
  toggleMute)
    cp "${TEMPLATES}/togglemute.json" $JSON
    ;;
  *)
    echo "Command \"$CMD\" is not supported!"
    echo " "
    exit 1
    ;;
esac

cat $JSON
rm kodi.result kodiresult.json

curl ${IP}:${PORT}/jsonrpc --data @${JSON} \
     --header 'content-type: application/json;' \
     -o kodiresult.json

RESULT=$?
echo "KODIresult: $(cat kodiresult.json)"

# evaluate curl result:
if [[ $RESULT -eq 0 ]] ; then
  echo "OK"                                         > kodi.status
  echo ""                                          >> kodi.status
  echo "KODI answered to REST interface at $(date)"  >> kodi.status
else
  echo "Problem"                                    > kodi.status
  echo ""                                          >> kodi.status
  echo "cURL finished with a non-zero error at $(date)"  >> kodi.status
fi

cat kodi.status
exit 0
# eof.
