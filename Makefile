all: deploy

clean:
	rm -rf __site

deploy:
	julia --project -e 'using Xranklin; build(prefix="SIIP-Tutorial")'
