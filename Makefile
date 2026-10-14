default: clean export/web_release.zip

trim-whitespace:
	find -name '*.gd' | xargs -d'\n' sed -Ei 's/[ 	]+$$//'

export/web_release.zip: export/web/index.html
	zip --junk-paths -r $@ export/web/*

export/web/index.html:
	mkdir -p export/web
	godot --headless --export-release "Web" $@

clean:
	rm -rf export/web
	rm -f export/web_release.zip

TODO.md:
	sed -i '/# See Also/q' $@
	#find -not -path './$@'  -name '*.md' | awk -F '/' '{printf "[%s/%s](%s)\n\n",$$(NF-1), $$NF, $$0 }' >> $@
	grep -RIP '#(TODO|WARN|FIX|BM)' . | sed -E 's/\t+//' | awk -F: '{f=$$1;$$1="";printf "[`%s`](%s)\n\n", $$0, f}' >> $@

build: export/web/index.html

.PHONY: .docs
.docs:
	mkdir -p .docs
	godot --headless --doctool .docs

.PHONY: TODO.md clean build
