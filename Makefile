all: deploy

clean:
	rm -rf __site

develop:
	julia --project

deploy:
	julia --project -e 'using Xranklin; build(prefix="SIIP-Tutorial")'
