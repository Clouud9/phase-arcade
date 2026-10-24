build: export/web_release.zip export/phaseware_windows.zip export/phaseware_linux.zip

TITLE = phaseware

export/web/index.html:
	mkdir -p export/web
	godot --headless --export-release "Web" $@
export/web_release.zip: export/web/index.html
	zip --junk-paths -r $@ export/web/*

export/windows/$(TITLE).exe:
	mkdir -p export/windows
	godot --headless --export-release "Windows Desktop" $@
export/phaseware_windows.zip: export/windows/$(TITLE).exe
	zip --junk-paths -r $@ export/windows/*

export/linux/$(TITLE):
	mkdir -p export/linux
	godot --headless --export-release "Linux" $@
export/phaseware_linux.zip: export/linux/$(TITLE)
	zip --junk-paths -r $@ export/linux/*

clean:
	rm -rf export/*

trim-whitespace:
	find -name '*.gd' | xargs -d '\n' sed -Ei 's/[ 	]+$$//'

# Regenerates .docs/ from the installed engine. Godot erases the old docs itself.
# .PHONY because .docs is a real directory: without it this would run only once.
.docs:
	mkdir -p .docs
	godot --headless --doctool .docs

.PHONY: clean build build-windows build-linux trim-whitespace downscale-textures .docs
