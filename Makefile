.PHONY: app debug release clean

app:
	bash scripts/build-app.sh

debug:
	CONFIGURATION=debug bash scripts/build-app.sh

release:
	bash scripts/release-app.sh

clean:
	rm -rf .build build
