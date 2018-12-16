#! /bin/bash

# Extent parameters
LOCNAME=demo
LONMIN=99.9
LONMAX=101.2
LATMIN=13.4
LATMAX=14.5
RES=0.0043119132
RESMET=480

# Model setting
MODEL_YEAR_1=2005
MODEL_YEAR_2=2009
MODEL_YEAR_3=2015

# Prediction setting
PRED_START=$MODEL_YEAR_3
PRED_END=2030
PRED_OUTPUT_YEAR="2020 2025 2030"

# Urban Growth
CRITICAL_LOW=0.97 
CRITICAL_HIGH=1.3 
BOOM=1.01 
BUST=0.09
ROAD_GRAV_SENSITIVITY=0.1
SLOPE_SENSITIVITY=0.1 

# Do not touch below
Bin/mkdir.exe -p Input/$LOCNAME
Bin/mkdir.exe -p Output/${LOCNAME}_pre Output/${LOCNAME}_test Output/${LOCNAME}

XMIN=$(echo $LONMIN $LATMIN | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe -f 1)
YMIN=$(echo $LONMIN $LATMIN | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 2)
XMAX=$(echo $LONMAX $LATMAX | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 1)
YMAX=$(echo $LONMAX $LATMAX | proj +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs | Bin/cut.exe  -f 2)
#:<<'#EOF'

WARPOPTS="-te $LONMIN $LATMIN $LONMAX $LATMAX -tr $RES $RES -ot Byte -r mode -overwrite -co compress=deflate"
for YEAR in $MODEL_YEAR_1 $MODEL_YEAR_2 $MODEL_YEAR_3; do
	Bin/rm.exe -f Src/$LOCNAME.urban.$YEAR.warp.tif Src/$LOCNAME.roads.$YEAR.tif Src/$LOCNAME.landuse.$YEAR.warp.tif Src/$LOCNAME.excluded.warp.tif
# Urban
	python Bin/gdal_calc.py --calc="where(A==4, 255, 0)" --outfile=Src/$LOCNAME.urban.$YEAR.tif -A Src/LC$YEAR.tif --overwrite
	gdalwarp $WARPOPTS Src/$LOCNAME.urban.$YEAR.tif Src/$LOCNAME.urban.$YEAR.warp.tif
	gdal_translate -of GIF Src/$LOCNAME.urban.$YEAR.warp.tif Input/$LOCNAME/$LOCNAME.urban.$YEAR.gif

# Road
	gdal_rasterize -burn 255 -init 0 -ot Byte -tr $RES $RES -te $LONMIN $LATMIN $LONMAX $LATMAX -co COMPRESS=Deflate Src/ne_10m_roads.shp Src/$LOCNAME.roads.$YEAR.tif
	gdal_translate -of GIF Src/$LOCNAME.roads.$YEAR.tif Input/$LOCNAME/$LOCNAME.roads.$YEAR.gif

# Land use
	gdalwarp $WARPOPTS Src//LC$YEAR.tif Src/$LOCNAME.landuse.$YEAR.warp.tif
	gdal_translate -of GIF Src/$LOCNAME.landuse.$YEAR.warp.tif Input/$LOCNAME/$LOCNAME.landuse.$YEAR.gif

done

# Excluded
	python Bin/gdal_calc.py --calc="where(logical_or(A==1,A==0), 100, 1)" --outfile=Src/$LOCNAME.excluded.tif -A Src/LC${MODEL_YEAR_3}.tif --overwrite
	gdalwarp $WARPOPTS Src/$LOCNAME.excluded.tif Src/$LOCNAME.excluded.warp.tif
	gdal_translate -of GIF Src/$LOCNAME.excluded.warp.tif Input/$LOCNAME/$LOCNAME.excluded.gif

# Slope and hilshade
Bin/rm.exe -f Src/SRTM.3857.tif Src/$LOCNAME.slope.tif Src/$LOCNAME.slope.4326.tif Src/$LOCNAME.hillshade.tif Src/$LOCNAME.hillshade.4326.tif
	gdalwarp -te $XMIN $YMIN $XMAX $YMAX -tr $RESMET $RESMET -r average -t_srs EPSG:3857 Src/SRTM/srtm.vrt Src/SRTM.3857.tif
	gdaldem slope Src/SRTM.3857.tif Src/$LOCNAME.slope.tif -p -co compress=deflate
	gdalwarp $WARPOPTS -r average -t_srs EPSG:4326 -overwrite Src/$LOCNAME.slope.tif Src/$LOCNAME.slope.4326.tif
	gdal_translate -of GIF Src/$LOCNAME.slope.4326.tif Input/$LOCNAME/$LOCNAME.slope.gif

	gdaldem hillshade Src/SRTM.3857.tif Src/$LOCNAME.hillshade.tif -co compress=deflate
	gdalwarp $WARPOPTS -r average -t_srs EPSG:4326 -overwrite Src/$LOCNAME.hillshade.tif Src/$LOCNAME.hillshade.4326.tif
	gdal_translate -of GIF Src/$LOCNAME.hillshade.4326.tif Input/$LOCNAME/$LOCNAME.hillshade.gif


#EOF
cd Scenarios
for SCENARIO in calibrate predict test; do
	../Bin/sed.exe -e "s/_MODEL_YEAR_1/${MODEL_YEAR_1}/g; s/_MODEL_YEAR_2/${MODEL_YEAR_2}/g;  s/_MODEL_YEAR_3/${MODEL_YEAR_3}/g; s/LOCNAME/${LOCNAME}/g; s/_PRED_START/${PRED_START}/g; s/_PRED_END/${PRED_END}/g; s/_CRITICAL_LOW/${CRITICAL_LOW}/g; s/_CRITICAL_HIGH/${CRITICAL_HIGH}/g; s/_BOOM/${BOOM}/g; s/_BUST/${BUST}/g; s/_ROAD_GRAV_SENSITIVITY/${ROAD_GRAV_SENSITIVITY}/g; s/_SLOPE_SENSITIVITY/${SLOPE_SENSITIVITY}/g;" scenario.template_$SCENARIO > scenario.${LOCNAME}_$SCENARIO
	../Bin/grow.exe $SCENARIO scenario.${LOCNAME}_$SCENARIO
done

cd ../Src
for YEAR in $MODEL_YEAR_1 $MODEL_YEAR_2 $MODEL_YEAR_3; do
	gdal_sieve.bat -q -st 4 ${LOCNAME}.landuse.$YEAR.warp.tif ${LOCNAME}_landuse.$YEAR.tif
	../Bin/rm.exe ${LOCNAME}_landuse.$YEAR.sqlite
	gdal_polygonize.bat -f SQLite ${LOCNAME}_landuse.$YEAR.tif ${LOCNAME}_landuse.$YEAR.sqlite
	echo "ALTER TABLE out ADD COLUMN lulc char(2); UPDATE out SET lulc = dn;" | sqlite3 ${LOCNAME}_landuse.$YEAR.sqlite
done

cd ../Output/${LOCNAME}_pre
for YEAR in $PRED_OUTPUT_YEAR ; do
	gdal_translate -a_srs EPSG:4326 -co compress=deflate -a_ullr $LONMIN $LATMAX $LONMAX $LATMIN ${LOCNAME}_land_n_urban.$YEAR.gif ${LOCNAME}_land_n_urban.$YEAR.org.tif
	gdal_sieve.bat -q -st 4 ${LOCNAME}_land_n_urban.$YEAR.org.tif ${LOCNAME}_land_n_urban.$YEAR.tif
	../../Bin/rm.exe ${LOCNAME}_land_n_urban.$YEAR.sqlite
	gdal_polygonize.bat -f SQLite ${LOCNAME}_land_n_urban.$YEAR.tif ${LOCNAME}_land_n_urban.$YEAR.sqlite
	echo "ALTER TABLE out ADD COLUMN lulc char(2); UPDATE out SET lulc = dn;" | sqlite3 ${LOCNAME}_land_n_urban.$YEAR.sqlite
done
