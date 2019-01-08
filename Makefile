Src/$(LOCNAME).urban.$(YEAR).tif: Src/LC$(YEAR).tif
	python Bin/gdal_calc.py --calc="where(A==4, 255, 0)" --outfile=$@ -A $< --overwrite
Src/$(LOCNAME).urban.$(YEAR).warp.tif: Src/$(LOCNAME).urban.$(YEAR).tif
	gdalwarp $(WARPOPTS) $< $@
Input/$(LOCNAME)/$(LOCNAME).urban.$(YEAR).gif: Src/$(LOCNAME).urban.$(YEAR).warp.tif
	gdal_translate -of GIF $< $@

Src/$(LOCNAME).roads.$(YEAR).tif : Src/ne_10m_roads.shp
	gdal_rasterize -burn 255 -init 0 -ot Byte -tr $(RES) $(RES) -te $(LONMIN) $(LATMIN) $(LONMAX) $(LATMAX) -co COMPRESS=Deflate $< $@
Input/$(LOCNAME)/$(LOCNAME).roads.$(YEAR).gif: Src/$(LOCNAME).roads.$(YEAR).tif
	gdal_translate -of GIF $< $@

Src/$(LOCNAME).landuse.$(YEAR).warp.tif: Src/LC$(YEAR).tif
	gdalwarp $(WARPOPTS) $< $@
Input/$(LOCNAME)/$(LOCNAME).landuse.$(YEAR).gif: Src/$(LOCNAME).landuse.$(YEAR).warp.tif
	gdal_translate -of GIF $< $@

Src/$(LOCNAME).excluded.tif: Src/LC$(MODEL_YEAR_1).tif
	python Bin/gdal_calc.py --calc="where(logical_or(A==1,A==0), 100, 1)" --outfile=$@ -A $< --overwrite
Src/$(LOCNAME).excluded.warp.tif: Src/$(LOCNAME).excluded.tif
	gdalwarp $(WARPOPTS) $< $@
Input/$(LOCNAME)/$(LOCNAME).excluded.gif: Src/$(LOCNAME).excluded.warp.tif
	gdal_translate -of GIF $< $@

Src/SRTM.3857.tif: Src/SRTM/srtm.vrt
	gdalwarp -te $(XMIN) $(YMIN) $(XMAX) $(YMAX) -tr $(RESMET) $(RESMET) -r average -t_srs EPSG:3857 $< $@
Src/$(LOCNAME).slope.tif: Src/SRTM.3857.tif
	gdaldem slope $< $@ -p -co compress=deflate
Src/$(LOCNAME).slope.4326.tif: Src/$(LOCNAME).slope.tif
	gdalwarp $(WARPOPTS) -r average -t_srs EPSG:4326 -overwrite $< $@
Input/$(LOCNAME)/$(LOCNAME).slope.gif: Src/$(LOCNAME).slope.4326.tif
	gdal_translate -of GIF $< $@

Src/$(LOCNAME).hillshade.tif: Src/SRTM.3857.tif
	gdaldem hillshade $< $@ -co compress=deflate
Src/$(LOCNAME).hillshade.4326.tif: Src/$(LOCNAME).hillshade.tif
	gdalwarp $(WARPOPTS) -r average -t_srs EPSG:4326 -overwrite $< $@
Input/$(LOCNAME)/$(LOCNAME).hillshade.gif: Src/$(LOCNAME).hillshade.4326.tif
	gdal_translate -of GIF $< $@

scenario.$(LOCNAME)_$(SCENARIO): scenario.template_$(SCENARIO)
	../Bin/sed.exe -e \
	"s/_MODEL_YEAR_1/$(MODEL_YEAR_1)/g; \
	s/_MODEL_YEAR_2/$(MODEL_YEAR_2)/g; \
	s/_MODEL_YEAR_3/$(MODEL_YEAR_3)/g; \
	s/_MODEL_YEAR_4/$(MODEL_YEAR_4)/g; \
	s/LOCNAME/$(LOCNAME)/g; \
	s/_PRED_START/$(PRED_START)/g; \
	s/_PRED_END/$(PRED_END)/g; \
	s/_CRITICAL_LOW/$(CRITICAL_LOW)/g; \
	s/_CRITICAL_HIGH/$(CRITICAL_HIGH)/g; \
	s/_BOOM/$(BOOM)/g; \
	s/_BUST/$(BUST)/g; \
	s/_ROAD_GRAV_SENSITIVITY/$(ROAD_GRAV_SENSITIVITY)/g; \
	s/_SLOPE_SENSITIVITY/$(SLOPE_SENSITIVITY)/g;" \
	$< > $@
