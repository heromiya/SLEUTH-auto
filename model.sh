#! /bin/bash

# Extent parameters
export LOCNAME=demo
export LONMIN=99.9
export LONMAX=101.2
export LATMIN=13.4
export LATMAX=14.5
export RES=0.0043119132
export RESMET=480

# Model setting
export MODEL_YEAR_1=2005
export MODEL_YEAR_2=2009
export MODEL_YEAR_3=2015
export MODEL_YEAR_4=2017

# Prediction setting
export PRED_START=$MODEL_YEAR_1
export PRED_END=2030
export PRED_OUTPUT_YEAR="2020 2025 2030"

# Urban Growth
export CRITICAL_LOW=0.97 
export CRITICAL_HIGH=1.3 
export BOOM=1.01 
export BUST=0.09
export ROAD_GRAV_SENSITIVITY=0.1
export SLOPE_SENSITIVITY=0.1 

# Do not touch below
Bin/mkdir.exe -p Input/$LOCNAME
Bin/mkdir.exe -p Output/${LOCNAME}_pre Output/${LOCNAME}_test Output/${LOCNAME}

export XMIN=$(echo $LONMIN $LATMIN | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe -f 1)
export YMIN=$(echo $LONMIN $LATMIN | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 2)
export XMAX=$(echo $LONMAX $LATMAX | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 1)
export YMAX=$(echo $LONMAX $LATMAX | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 2)

export WARPOPTS="-t_srs EPSG:4326 -te $LONMIN $LATMIN $LONMAX $LATMAX -tr $RES $RES -ot Byte -r mode -overwrite -co COMPRESS=Deflate"
for YEAR in $MODEL_YEAR_1 $MODEL_YEAR_2 $MODEL_YEAR_3 $MODEL_YEAR_4; do
	export YEAR
	Bin/rm.exe -f Src/$LOCNAME.urban.$YEAR.warp.tif Src/$LOCNAME.roads.$YEAR.tif Src/$LOCNAME.landuse.$YEAR.warp.tif Src/$LOCNAME.excluded.warp.tif
	Bin/make Input/$LOCNAME/$LOCNAME.urban.$YEAR.gif Input/$LOCNAME/$LOCNAME.roads.$YEAR.gif Input/$LOCNAME/$LOCNAME.landuse.$YEAR.gif
done

Bin/rm.exe -f Src/SRTM.3857.tif Src/$LOCNAME.slope.tif Src/$LOCNAME.slope.4326.tif Src/$LOCNAME.hillshade.tif Src/$LOCNAME.hillshade.4326.tif
Bin/make Input/$LOCNAME/$LOCNAME.excluded.gif Input/$LOCNAME/$LOCNAME.slope.gif Input/$LOCNAME/$LOCNAME.hillshade.gif

cd Scenarios
for SCENARIO in calibrate predict; do
	export SCENARIO
	../Bin/make -f ../Makefile scenario.${LOCNAME}_$SCENARIO
	../Bin/grow.exe $SCENARIO scenario.${LOCNAME}_$SCENARIO
done

cd ../Src
for YEAR in $MODEL_YEAR_1 $MODEL_YEAR_2 $MODEL_YEAR_3 $MODEL_YEAR_4; do
	gdal_sieve.bat -q -st 4 ${LOCNAME}.landuse.$YEAR.warp.tif ${LOCNAME}_landuse.$YEAR.tif
	../Bin/rm.exe ${LOCNAME}_landuse.$YEAR.sqlite
	gdal_polygonize.bat -f SQLite ${LOCNAME}_landuse.$YEAR.tif ${LOCNAME}_landuse.$YEAR.sqlite
	echo "ALTER TABLE out ADD COLUMN lulc char(2); UPDATE out SET lulc = dn;" | sqlite3 ${LOCNAME}_landuse.$YEAR.sqlite
done

cd ../Output/${LOCNAME}_pre
for YEAR in $PRED_OUTPUT_YEAR ; do
	gdal_translate -a_srs EPSG:4326 -co compress=deflate -a_ullr $LONMIN $LATMAX $LONMAX $LATMIN ${LOCNAME}_land_n_urban.$YEAR.gif ${LOCNAME}_land_n_urban.$YEAR.org.tif
	gdal_sieve.bat -q -st 4 ${LOCNAME}_land_n_urban.$YEAR.org.tif ${LOCNAME}_land_n_urban.$YEAR.tif
done
