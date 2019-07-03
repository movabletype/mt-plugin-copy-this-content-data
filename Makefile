zip:
	cd .. && zip -r mt-plugin-copy-this-content-data/mt-plugin-copy-this-content-data.zip mt-plugin-copy-this-content-data -x *.git* */t/* */.travis.yml */Makefile

clean:
	rm mt-plugin-copy-this-content-data.zip

