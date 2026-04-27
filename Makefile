.PHONY: app debug clean

app:
	bash scripts/build-app.sh

debug:
	CONFIGURATION=debug bash scripts/build-app.sh

clean:
	rm -rf .build build
