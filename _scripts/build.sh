#!/usr/bin/env bash

set -e

# Build Dir
if [ -n "${TRAVIS+x}" ]; then
  echo "** Executing in Travis CI environment";
  export BUILD_DIR=$TRAVIS_BUILD_DIR
 else
   if [ -n "${WOC_BUILD_DIR+x}" ]; then
     echo "** Executing in local environment; build dir set to $WOC_BUILD_DIR";
     export BUILD_DIR=$WOC_BUILD_DIR
   else
     echo "** Executing in local environment; build dir set to `pwd`"
     export BUILD_DIR=`pwd`
   fi
fi

export PATH=~/.local/bin:/opt/ghc/7.10.2/bin:~/.cabal/bin:/tmp/texlive/bin/x86_64-linux:$PATH

# Inkscape Modules Location
if [ "$(uname)" == "Darwin" ]; then
  export PYTHONPATH=/usr/local/lib/python:~/.local/lib/python2.7/site-packages:/Applications/Inkscape.app/Contents/Resources/share/inkscape/extensions:$PYTHONPATH
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  export PYTHONPATH=/usr/local/lib/python:~/.local/lib/python2.7/site-packages:/usr/share/inkscape/extensions/:$PYTHONPATH
fi

#### Init dirs and needed files
mkdir -p $BUILD_DIR/build
mkdir -p $BUILD_DIR/pdf

cp $BUILD_DIR/*.{md,jpg,png} $BUILD_DIR/build/ || true


### English
export WOC_DECK_LOCALE=en
Rscript --no-save --no-restore $BUILD_DIR/R/decks.preparation.R

# Remove _BACK from columns
if [ "$(uname)" == "Darwin" ]; then
  sed -i '' 's/_BACK//g' $BUILD_DIR/build/woc.goo.deck.en.csv
  sed -i '' 's/_BACK//g' $BUILD_DIR/build/woc.research.deck.en.csv
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  sed -i 's/_BACK//g' $BUILD_DIR/build/woc.goo.deck.en.csv
  sed -i 's/_BACK//g' $BUILD_DIR/build/woc.research.deck.en.csv
fi

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.deck.en.csv -p $BUILD_DIR/build $BUILD_DIR/woc.deck.svg > $BUILD_DIR/build/woc.deck.en.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.deck.en.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.deck.en.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.goo.deck.en.csv -p $BUILD_DIR/build $BUILD_DIR/woc.greatoldones.svg > $BUILD_DIR/build/woc.greatoldones.en.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.greatoldones.en.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.greatoldones.en.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.research.deck.en.csv -p $BUILD_DIR/build $BUILD_DIR/woc.research.svg > $BUILD_DIR/build/woc.research.en.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.research.en.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.research.en.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

### Italian
# This is not going to work without sudo, which is not available on container-based Travis CI
#sudo locale-gen "it_IT.UTF-8"

export WOC_DECK_LOCALE=it
Rscript --no-save --no-restore $BUILD_DIR/R/decks.preparation.R

# Remove _BACK from columns
if [ "$(uname)" == "Darwin" ]; then
  sed -i '' 's/_BACK//g' $BUILD_DIR/build/woc.goo.deck.it.csv
  sed -i '' 's/_BACK//g' $BUILD_DIR/build/woc.research.deck.it.csv
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  sed -i 's/_BACK//g' $BUILD_DIR/build/woc.goo.deck.it.csv
  sed -i 's/_BACK//g' $BUILD_DIR/build/woc.research.deck.it.csv
fi

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.deck.it.csv -p $BUILD_DIR/build $BUILD_DIR/woc.deck.svg > $BUILD_DIR/build/woc.deck.it.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.deck.it.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.deck.it.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.goo.deck.it.csv -p $BUILD_DIR/build $BUILD_DIR/woc.greatoldones.svg > $BUILD_DIR/build/woc.greatoldones.it.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.greatoldones.it.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.greatoldones.it.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

python $BUILD_DIR/countersheet.py -r 30 -n deck -d $BUILD_DIR/build/woc.research.deck.it.csv -p $BUILD_DIR/build $BUILD_DIR/woc.research.svg > $BUILD_DIR/build/woc.research.it.svg
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$BUILD_DIR/pdf/woc.research.it.pdf $BUILD_DIR/build/*.pdf
cp $BUILD_DIR/build/woc.research.it.svg $BUILD_DIR/pdf
rm $BUILD_DIR/build/*.pdf

# Build rules PDF
# Due to pandoc not resizing images for some reason and I'm not motivated in debugging it, I'm going to resize images by myself
echo "Image processing for markdown renderings..."

cd $BUILD_DIR/build

shopt -s nullglob
for i in icon.*.jpg icon.*.JPG icon.*.png icon.*.PNG; do

      identify $i

      filename=$(basename "$i")
      extension="${filename##*.}"
      filename="${filename%.*}"

      convert $i                                \
        -filter Lanczos                         \
        -colorspace sRGB                        \
        -units PixelsPerInch                    \
        -density 120                            \
        -write mpr:main                         \
        +delete                                 \
        mpr:main -resize '32x32>'  -write ${filename}-32px.${extension} +delete \
        mpr:main -resize '24x24>'  -write ${filename}-24px.${extension} +delete \
        mpr:main -resize '16x16>'  -write ${filename}-16px.${extension} +delete \
        mpr:main -resize '12x12>'         ${filename}-12px.${extension}
done

cp $BUILD_DIR/build/woc.rules.en.md $BUILD_DIR/build/woc.rules.en.resized.md

sed -i 's/\.png){height="12" width="12"}/-12px\.png)/g' $BUILD_DIR/build/woc.rules.en.resized.md
sed -i 's/\.png){height="16" width="16"}/-16px\.png)/g' $BUILD_DIR/build/woc.rules.en.resized.md
sed -i 's/\.png){height="24" width="24"}/-24px\.png)/g' $BUILD_DIR/build/woc.rules.en.resized.md
sed -i 's/\.png){height="32" width="32"}/-32px\.png)/g' $BUILD_DIR/build/woc.rules.en.resized.md

pandoc $BUILD_DIR/build/woc.rules.en.resized.md -o $BUILD_DIR/pdf/woc.rules.en.pdf --latex-engine=xelatex

# Clean up
rm $BUILD_DIR/build/*.*
