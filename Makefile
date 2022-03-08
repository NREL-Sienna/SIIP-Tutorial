all: deploy

clean:
	rm -rf __site

develop:
	julia --project -e 'using Xranklin; serve()'

deploy:
	julia --project -e 'using Xranklin; build(prefix="SIIP-Tutorial")'
