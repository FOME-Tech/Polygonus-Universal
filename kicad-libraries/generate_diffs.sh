#####################################################################################
#                                 generate_diffs.sh                                 #
#                                    08/13/2020                                     #
#                             Written By David Holdeman                             #
#   Checks for changed .kicad_pcb files, generates visual diffs, and uploads them   #
#                                      to FTP.                                      #
#####################################################################################
# The FTP location this uploads to is /diffs/plot_<name of kicad_pcb file, without the extension>
# In that directory are subdirectorys containing generated SVGs, as well as a 'web' subdirectory,
# which contains index.html. Open that in a web browser and you get a nice visual diff of each layer.
#!/bin/bash

function gendiffs() {
  if [ -f "$(dirname "$1")/version.txt" ] && [ $(git rev-list -1 $(git rev-parse HEAD) "$(dirname "$1")/version.txt") = $(git rev-parse HEAD) ]; then
   OLDHASH=$(git rev-list -2 $(git rev-parse HEAD) "$1" | tail -n1 | head -c7)
    ../KiCad-Diff/kidiff_linux.py -w -s Git -b $OLDHASH -a $(git rev-parse --short HEAD) -d :0 $1
    if [ -d $(dirname "$1")/plots ] && [ -n "$RUSEFI_FTP_SERVER" ]; then
      lftp -u "$RUSEFI_DOXYGEN_FTP_USER","$RUSEFI_DOXYGEN_FTP_PASS" "$RUSEFI_FTP_SERVER" -e \
        "mirror -Re $(dirname "$1")/plots/ /diffs/plots_$(basename "$1" .kicad_pcb)_release; exit"
    fi
  fi
  ../KiCad-Diff/kidiff_linux.py -w -s Git -b $(git rev-parse --short HEAD~1) -a $(git rev-parse --short HEAD) -d :0 $1
  if [ -d $(dirname "$1")/plots ] && [ -n "$RUSEFI_FTP_SERVER" ]; then
    lftp -u "$RUSEFI_DOXYGEN_FTP_USER","$RUSEFI_DOXYGEN_FTP_PASS" "$RUSEFI_FTP_SERVER" -e \
      "mirror -Re $(dirname "$1")/plots/ /diffs/plots_$(basename "$1" .kicad_pcb); exit"
  fi
}
export -f gendiffs

find . -name "*.kicad_pcb" -exec bash -c 'gendiffs "$0"' {} \;
